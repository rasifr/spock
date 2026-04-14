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
# Test 019: Stale socket fd after provider connection failure
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
#   When the provider connection dies, the COPY stream ends ("data stream
#   ended").  The apply worker catches it, aborts the current transaction,
#   and jumps back to stream_replay: to replay from the queue.  On re-entry
#   the TCP FIN from the server is already in the kernel receive buffer.
#   WaitLatchOrSocket immediately sees the EOF as WL_SOCKET_READABLE, then
#   PQconsumeInput detects the dead connection and sets status to
#   CONNECTION_BAD.  The PQstatus check fires a SECOND exception:
#
#       ERROR: "connection to other side has died"
#
#   with use_try_block=true.  Under TRANSDISCARD (the production default)
#   this hits the "error during exception handling" path:
#
#       LOG:  SPOCK sub_n1_n2: error during exception handling: ...
#       LOG:  SPOCK sub_n1_n2: exiting to allow worker restart
#       [PG_RE_THROW — worker crashes and is restarted by bgworker manager]
#
#   On Linux, if the fd was closed and reused, WaitLatchOrSocket may instead
#   throw epoll_ctl(EINVAL) or kevent(EBADF) before even reading the socket,
#   but the outcome is the same: a spurious "error during exception handling"
#   and a needless worker restart.
#
# Fix:
#   At stream_replay:, call PQconsumeInput to flush any buffered EOF from the
#   provider.  Then refresh fd = PQsocket(applyconn).  If the connection is
#   dead (CONNECTION_BAD or fd == PGINVALID_SOCKET), log and return cleanly.
#   The bgworker manager restarts the worker with a fresh connection without
#   logging a spurious error.
#
# Test plan:
#   1. 2-node cluster: n1 (provider) -> n2 (subscriber), subscription sub_n1_n2.
#   2. Override spock.exception_behaviour = transdiscard on n2 so the test
#      matches production behaviour (default is sub_disable in SpockTest.pm).
#   3. Verify baseline replication works.
#   4. Kill the walsender on n1 (terminate via pg_stat_replication).
#   5. PRIMARY CHECK: n2 log must NOT contain "error during exception handling"
#      — the cross-platform indicator that stream_replay: re-entered with a
#      dead connection.  On Linux this may also appear as epoll_ctl(EINVAL) or
#      kevent(EBADF); both are caught by the same secondary diag check.
#   6. Verify the apply worker reconnects and replication resumes.
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
# Override exception_behaviour to TRANSDISCARD on n2.
#
# SpockTest.pm sets spock.exception_behaviour=sub_disable in postgresql.conf.
# We override to transdiscard so the test matches the production default and
# observes the production symptom: "error during exception handling" + worker
# restart (not permanent subscription disable).
#
# ALTER SYSTEM writes to postgresql.auto.conf which takes precedence over
# postgresql.conf.  pg_reload_conf() sends SIGHUP to all backends; the apply
# worker picks up the new setting on its next ConfigReloadPending iteration.
# ---------------------------------------------------------------------------
psql_or_bail(2, "ALTER SYSTEM SET spock.exception_behaviour = 'transdiscard'");
psql_or_bail(2, "SELECT pg_reload_conf()");
sleep(1);

# ---------------------------------------------------------------------------
# Setup: table on both nodes, one-way subscription n1 -> n2.
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
is($before_count, '1', 'baseline row replicates n1->n2');

# ---------------------------------------------------------------------------
# Capture n2 log offset immediately before we trigger the connection failure.
# ---------------------------------------------------------------------------
my $log_offset = -s $pg_log_n2;
$log_offset = 0 unless defined $log_offset;

# ---------------------------------------------------------------------------
# Trigger: kill the walsender on n1 with SIGKILL.
#
# We use SIGKILL (not pg_terminate_backend/SIGTERM) deliberately.
#
# With SIGTERM, the walsender gets a chance to send a CopyDone message before
# dying.  The apply worker's first exception is then "data stream ended" and
# pqDropConnection has NOT yet been called — the socket fd is still open on
# the client side.  On stream_replay: re-entry WaitLatchOrSocket registers the
# still-valid fd; epoll_ctl succeeds and only the buffered EOF produces the
# second exception through the PQstatus check.
#
# With SIGKILL, the walsender dies immediately with no cleanup and no CopyDone.
# libpq reads a raw EOF (or RST), calls pqDropConnection which CLOSES conn->sock,
# and PQstatus flips to CONNECTION_BAD before the first exception fires:
#
#   "connection to other side has died"
#
# On stream_replay: re-entry the fd is already closed.  WaitLatchOrSocket calls
# epoll_ctl(EPOLL_CTL_ADD, closed_fd) which returns EBADF (closed) or EINVAL
# (if the fd number was reused for a non-pollable resource), triggering:
#
#   ERROR: epoll_ctl() failed: Bad file descriptor   (Linux)
#
# Note: SIGKILL on a PostgreSQL backend triggers crash recovery on n1; the
# postmaster restarts automatically and n1 comes back up within a few seconds.
# ---------------------------------------------------------------------------

my $walsender_pid = scalar_query(1,
    "SELECT pid FROM pg_stat_replication WHERE state = 'streaming' LIMIT 1");

diag("Walsender PID on n1: " . ($walsender_pid // 'none'));

my $signaled = 0;
if (defined $walsender_pid && $walsender_pid =~ /^\d+$/) {
    $signaled = kill 9, int($walsender_pid);
    diag("SIGKILL to walsender PID $walsender_pid: " . ($signaled ? "sent" : "failed - $!"));
}

if (!$signaled) {
    diag("WARNING: could not SIGKILL walsender — apply worker may not have been streaming yet");
}

# Give n2 time to detect the dead socket, enter stream_replay:, and hit the
# epoll_ctl error.  Also allows n1 time to complete crash recovery so the
# subscription can reconnect.  10 s covers both.
sleep(10);

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

# The initial exception must appear in the log — sanity check that the kill
# worked.  After the walsender dies the COPY stream ends, so the apply worker
# logs either "data stream ended" (EOF from clean walsender shutdown) or
# "connection to other side has died" (if libpq detects the TCP drop first).
my $initial_exception =
    ($new_log =~ /data stream ended|connection to other side has died/) ? 1 : 0;
ok($initial_exception, 'n2 log shows initial connection failure after walsender kill');

if (!$initial_exception) {
    diag("No initial exception found — walsender kill may not have been detected yet.");
}

# ---------------------------------------------------------------------------
# PRIMARY CROSS-PLATFORM BUG CHECK
#
# When the stale-fd bug is present, apply_work() re-enters stream_replay:
# with the dead connection.  The re-entry causes a second exception:
#
#   macOS: WaitLatchOrSocket sees the EOF immediately (WL_SOCKET_READABLE),
#          PQconsumeInput flips the status to CONNECTION_BAD, then
#          PQstatus==CONNECTION_BAD fires "connection to other side has died".
#
#   Linux: epoll_ctl(EINVAL) or kevent(EBADF) from the stale fd may fire
#          before the socket is even read, producing "epoll_ctl() failed" /
#          "kevent failed".
#
# Both cases are caught by PG_CATCH with use_try_block=true.  Under
# TRANSDISCARD (the production default, set above) this hits the
# "error during exception handling" path:
#
#   LOG: SPOCK sub_n1_n2: error during exception handling: <message>
#   LOG: SPOCK sub_n1_n2: exiting to allow worker restart
#   [PG_RE_THROW -> worker exits, bgworker manager restarts it]
#
# After the fix the worker exits cleanly at stream_replay: before reaching
# WaitLatchOrSocket, so no second exception and no "error during exception
# handling" log entry.
# ---------------------------------------------------------------------------

my $eeh = ($new_log =~ /error during exception handling/) ? 1 : 0;
my $wait_event_error =
    ($new_log =~ /epoll_ctl\(\) failed|kevent failed: Bad file descriptor/) ? 1 : 0;

ok(!$eeh,
    'no "error during exception handling" after connection failure (stale-fd bug)');

if ($eeh) {
    diag("BUG CONFIRMED: stream_replay: re-entered with dead connection");
    diag("  macOS: WL_SOCKET_READABLE from buffered EOF => PQstatus==BAD => 2nd exception");
    diag("  Linux: epoll_ctl(EINVAL)/kevent(EBADF) from stale fd => 2nd exception");
    diag("  Both:  use_try_block=true => 'error during exception handling' => PG_RE_THROW");
    diag("Fix: at stream_replay:, call PQconsumeInput and check PQstatus/fd before");
    diag("     entering WaitLatchOrSocket; exit cleanly if connection is dead.");
}

# Linux-specific OS-level assertion.
#
# With SIGKILL, pqDropConnection closes conn->sock before stream_replay: is
# entered.  WaitLatchOrSocket then calls epoll_ctl(EPOLL_CTL_ADD, closed_fd)
# which returns EBADF (fd just closed) or EINVAL (fd reused as non-pollable),
# raising ERROR "epoll_ctl() failed: <reason>".
#
# On macOS, kevent() with nevents=0 silently ignores bad fds (returns 0 not
# -1), so this message never appears there; the bug is caught via $eeh above.
SKIP: {
    skip 'epoll_ctl error is Linux-specific (macOS kevent silently ignores bad fds)', 1
        unless $^O eq 'linux';
    ok($wait_event_error,
        'Linux: epoll_ctl error from closed fd detected in stream_replay: path');
    if (!$wait_event_error) {
        diag("epoll_ctl error not seen — fd may not have been closed before stream_replay");
        diag("re-entry (first exception was 'data stream ended', not 'connection to other");
        diag("side has died', meaning pqDropConnection had not yet run)");
    }
}

# ---------------------------------------------------------------------------
# Recovery: with TRANSDISCARD the subscription stays enabled; the bgworker
# manager restarts the apply worker automatically.  Verify the worker
# reconnects and replication resumes.
# ---------------------------------------------------------------------------

ok(wait_for_sub_status(2, 'sub_n1_n2', 'replicating', 30),
    'sub_n1_n2 returns to replicating state after reconnect');

psql_or_bail(1, "INSERT INTO test_stale_fd (val) VALUES ('after_reconnect')");
sleep(5);

my $after_count = scalar_query(2, "SELECT count(*) FROM test_stale_fd");
cmp_ok($after_count, '>=', '2', 'post-reconnect row replicates n1->n2');

# ---------------------------------------------------------------------------
# Cleanup
# ---------------------------------------------------------------------------

system_maybe("$pg_bin/psql", '-h', $host, '-p', $p2, '-U', $db_user, '-d', $dbname,
    '-c', "SELECT spock.sub_drop('sub_n1_n2')");

destroy_cluster('Destroy cluster after stale-fd epoll_ctl regression test');

done_testing();
