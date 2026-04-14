use strict;
use warnings;
use Test::More;
use lib '.';
use SpockTest qw(
    create_cluster destroy_cluster
    system_maybe
    get_test_config scalar_query psql_or_bail
    wait_for_sub_status
);

# =============================================================================
# Test 019: Stale socket fd after provider connection failure — epoll_ctl EINVAL
# =============================================================================
#
# Bug (present in both v5_STABLE and main):
#
#   In apply_work(), the socket fd is captured once before stream_replay:
#
#       applyconn = streamConn;
#       fd = PQsocket(applyconn);   // set once here
#       ...
#   stream_replay:
#       ...
#       WaitLatchOrSocket(..., fd, ...)  // fd is never refreshed on re-entry
#
#   When the provider connection dies, libpq closes the socket internally
#   (pqDropConnection sets conn->sock = -1).  The apply worker catches
#   "connection to other side has died", aborts the current transaction,
#   and jumps back to stream_replay: to replay from the queue.  But fd
#   still holds the old, now-closed socket number.  The very first call to
#   WaitLatchOrSocket() on re-entry passes that stale fd to epoll_ctl
#   (Linux) or kevent (macOS).  The OS rejects it:
#
#       ERROR:  epoll_ctl() failed: Invalid argument     (Linux)
#       ERROR:  kevent failed: Bad file descriptor       (macOS)
#
#   That error is caught with use_try_block=true and re-thrown, causing
#   the apply worker to exit immediately with a spurious OS error instead
#   of reconnecting cleanly.
#
# Fix:
#   Add  fd = PQsocket(applyconn);  right after the stream_replay: label.
#   When the connection is dead, PQsocket() returns PGINVALID_SOCKET (-1),
#   which WaitLatchOrSocket() treats as "no socket — wait on latch only",
#   so the worker can drain the replay queue and exit cleanly without
#   touching epoll/kqueue.
#
# Test plan:
#   1. 2-node cluster: n1 (provider) → n2 (subscriber), subscription sub_n1_n2.
#   2. Verify baseline replication works.
#   3. Kill the walsender on n1 (terminate via pg_stat_replication), which
#      drops the apply worker's connection on n2 without stopping n1.
#   4. Check n2 log — must NOT contain a wait-event error
#      (epoll_ctl EINVAL on Linux / kevent EBADF on macOS).
#   5. Verify the apply worker reconnects and replication resumes.
# =============================================================================

create_cluster(2, 'Create 2-node cluster for stale-fd epoll_ctl regression test');

my $config      = get_test_config();
my $node_ports  = $config->{node_ports};
my $host        = $config->{host};
my $dbname      = $config->{db_name};
my $db_user     = $config->{db_user};
my $db_password = $config->{db_password};
my $pg_bin      = $config->{pg_bin};
my $log_dir     = $config->{log_dir};

my $p1 = $node_ports->[0];   # n1 — provider
my $p2 = $node_ports->[1];   # n2 — subscriber

my $conn_n1 = "host=$host dbname=$dbname port=$p1 user=$db_user password=$db_password";

# PG log for n2 (the subscriber — where the apply worker runs and where the
# bug manifests).
my $pg_log_n2 = "$log_dir/00${p2}.log";

# ---------------------------------------------------------------------------
# Setup: table on both nodes, one-way subscription n1 → n2.
# ---------------------------------------------------------------------------

psql_or_bail(1, "CREATE TABLE test_stale_fd (id SERIAL PRIMARY KEY, val TEXT)");
psql_or_bail(2, "CREATE TABLE test_stale_fd (id SERIAL PRIMARY KEY, val TEXT)");

psql_or_bail(2,
    "SELECT spock.sub_create('sub_n1_n2', '$conn_n1', " .
    "ARRAY['default', 'default_insert_only', 'ddl_sql'], false, false)");

ok(wait_for_sub_status(2, 'sub_n1_n2', 'replicating', 30),
    'sub_n1_n2 reaches replicating state');

# Baseline: verify replication is live before triggering the bug.
psql_or_bail(1, "INSERT INTO test_stale_fd (val) VALUES ('before_kill')");
sleep(3);

my $before_count = scalar_query(2, "SELECT count(*) FROM test_stale_fd");
is($before_count, '1', 'baseline row replicates n1→n2');

# ---------------------------------------------------------------------------
# Capture n2 log offset immediately before we trigger the connection failure.
# ---------------------------------------------------------------------------
my $log_offset = -s $pg_log_n2;
$log_offset = 0 unless defined $log_offset;

# ---------------------------------------------------------------------------
# Trigger: kill the walsender on n1 serving n2's subscription.
#
# Using pg_terminate_backend on pg_stat_replication kills the walsender
# cleanly at the OS level — n1 keeps running, only the replication
# connection is dropped.  The apply worker on n2 sees an EOF and throws
# "connection to other side has died".
# ---------------------------------------------------------------------------

my $killed = scalar_query(1,
    "SELECT count(pg_terminate_backend(pid)) " .
    "FROM pg_stat_replication " .
    "WHERE state = 'streaming'");

diag("Walsenders terminated on n1: $killed");

if (!defined $killed || $killed == 0) {
    diag("WARNING: no streaming walsender found — apply worker may not have been active yet");
}

# Give n2 time to detect the dead socket, enter the exception path,
# and attempt the stream_replay: retry.  The stale-fd error (if present)
# appears within milliseconds of the initial exception, so 5 s is ample.
sleep(5);

# ---------------------------------------------------------------------------
# Read new log entries on n2 since the offset.
# ---------------------------------------------------------------------------
my $new_log = '';
if (open(my $lf, '<', $pg_log_n2)) {
    seek($lf, $log_offset, 0);
    local $/;
    $new_log = <$lf> // '';
    close($lf);
}

# The initial exception must appear — that is always expected regardless of
# the bug being present or not.
my $conn_died = ($new_log =~ /connection to other side has died/) ? 1 : 0;
ok($conn_died, 'n2 log shows "connection to other side has died" after walsender kill');

if (!$conn_died && defined $killed && $killed == 0) {
    diag("No walsender was killed and no connection-death message found.");
    diag("This may indicate the apply worker was not yet streaming when we checked.");
}

# The bug: after catching the initial exception, the apply worker jumps back
# to stream_replay: with a stale (closed) fd and immediately hits a
# wait-event error on the OS epoll/kqueue level:
#
#   Linux: epoll_ctl() failed: Invalid argument
#   macOS: kevent failed: Bad file descriptor
#
# After the fix, neither message should appear.
my $wait_event_error =
    ($new_log =~ /epoll_ctl\(\) failed|kevent failed: Bad file descriptor/) ? 1 : 0;

ok(!$wait_event_error,
    'no wait-event error (epoll_ctl EINVAL / kevent EBADF) after connection failure');

if ($wait_event_error) {
    diag("BUG CONFIRMED: stale fd caused a wait-event error in the stream_replay: path");
    diag("Root cause: fd is not refreshed after jumping to stream_replay:");
    diag("  fd = PQsocket(applyconn) is set once before stream_replay:");
    diag("  After connection death PQsocket() returns -1 but fd still holds the old value.");
    diag("Fix: add  fd = PQsocket(applyconn);  right after the stream_replay: label.");
} else {
    diag("Clean reconnect — no spurious wait-event error in stream_replay: path");
}

# ---------------------------------------------------------------------------
# Recovery: the apply worker must restart and replication must resume.
# Whether or not the bug is present, the bgworker infrastructure restarts
# the apply worker automatically; this verifies the reconnect succeeds.
# ---------------------------------------------------------------------------

ok(wait_for_sub_status(2, 'sub_n1_n2', 'replicating', 30),
    'sub_n1_n2 returns to replicating state after reconnect');

psql_or_bail(1, "INSERT INTO test_stale_fd (val) VALUES ('after_reconnect')");
sleep(5);

my $after_count = scalar_query(2, "SELECT count(*) FROM test_stale_fd");
cmp_ok($after_count, '>=', '2', 'post-reconnect row replicates n1→n2');

# ---------------------------------------------------------------------------
# Cleanup
# ---------------------------------------------------------------------------

system_maybe("$pg_bin/psql", '-h', $host, '-p', $p2, '-U', $db_user, '-d', $dbname,
    '-c', "SELECT spock.sub_drop('sub_n1_n2')");

destroy_cluster('Destroy cluster after stale-fd epoll_ctl regression test');

done_testing();
