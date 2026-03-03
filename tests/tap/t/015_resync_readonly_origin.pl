use strict;
use warnings;
use Test::More;
use lib '.';
use SpockTest qw(create_cluster cross_wire destroy_cluster system_or_bail command_ok get_test_config scalar_query psql_or_bail system_maybe);

# =============================================================================
# Test: 015_resync_readonly_origin.pl - Resync Readonly Check (SPOC-440)
# =============================================================================
# This test verifies that spock.sub_resync_table() with truncate=true checks
# if the origin is in read-only mode BEFORE truncating, preventing data loss.
#
# Bug scenario (SPOC-440):
# - User calls spock.sub_resync_table('sub', 'schema.table', true)
# - Old behavior: Truncate local table immediately, then sync worker tries COPY
# - If origin is in read-only mode (spock.readonly = 'all'), COPY TO fails
#   but the table was already truncated, causing permanent data loss
# - New behavior: Check spock.readonly on origin first; error out immediately
#
# Test approach:
# - Set spock.readonly = 'all' on the provider to simulate read-only mode
# - Call sub_resync_table with truncate=true
# - Verify function returns error immediately and data is preserved

# Create a 2-node cluster and cross-wire
create_cluster(2, 'Create 2-node cluster for resync readonly check test');
cross_wire(2, ['n1', 'n2'], 'Cross-wire n1 and n2');

# Get cluster configuration
my $config = get_test_config();
my $node_ports = $config->{node_ports};
my $pg_bin = $config->{pg_bin};
my $dbname = $config->{db_name};

# Subscription name: n2 subscribing to n1
my $sub_name = 'sub_n2_n1';

# Create a test table on n1 (will replicate via DDL to n2)
psql_or_bail(1,
    "CREATE TABLE test_resync (
        id SERIAL PRIMARY KEY,
        name VARCHAR(50),
        value INTEGER
    )"
);

# Wait for DDL replication and table sync
system_or_bail 'sleep', '5';

# Insert data on n1
psql_or_bail(1, "INSERT INTO test_resync (name, value) VALUES ('test1', 100)");
psql_or_bail(1, "INSERT INTO test_resync (name, value) VALUES ('test2', 200)");
psql_or_bail(1, "INSERT INTO test_resync (name, value) VALUES ('test3', 300)");

# Wait for replication
system_or_bail 'sleep', '3';

# Verify data replicated to n2
my $count_subscriber = scalar_query(2, "SELECT COUNT(*) FROM test_resync");
is($count_subscriber, '3', 'Subscriber has 3 rows (replication working)');

# Set provider (n1) to read-only mode using spock.readonly GUC
psql_or_bail(1, "ALTER SYSTEM SET spock.readonly = 'all'");
psql_or_bail(1, "SELECT pg_reload_conf()");
system_or_bail 'sleep', '2';

# Verify provider is in read-only mode
my $readonly_status = scalar_query(1, "SHOW spock.readonly");
is($readonly_status, 'all', 'Provider is in read-only mode (spock.readonly = all)');

# Try to resync with truncate=true while provider is read-only
# This should fail immediately with an error about readonly mode
my $resync_result = `$pg_bin/psql -p $node_ports->[1] -d $dbname -t -c "SELECT spock.sub_resync_table('$sub_name', 'public.test_resync', true)" 2>&1`;

# Check that the error message mentions readonly
like($resync_result, qr/read-only mode|readonly/i, 'Resync with truncate fails with readonly error');

# CRITICAL TEST: Data must NOT be truncated when origin is read-only
# The check happens in sub_resync_table BEFORE any truncate occurs.
my $count_after_resync = scalar_query(2, "SELECT COUNT(*) FROM test_resync");
is($count_after_resync, '3', 'CRITICAL: Data preserved when origin is read-only (readonly check prevents truncate)');

# Reset provider to writable before cleanup
psql_or_bail(1, "ALTER SYSTEM RESET spock.readonly");
psql_or_bail(1, "SELECT pg_reload_conf()");
system_or_bail 'sleep', '2';

# Verify provider is writable again
my $readonly_off = scalar_query(1, "SHOW spock.readonly");
is($readonly_off, 'off', 'Provider is writable again (spock.readonly = off)');

# Add a 4th row on provider (use repair_mode to bypass replication)
psql_or_bail(1, "BEGIN; SELECT spock.repair_mode(true); INSERT INTO test_resync (name, value) VALUES ('test4', 400); COMMIT;");

# Verify provider has 4 rows
my $provider_count = scalar_query(1, "SELECT COUNT(*) FROM test_resync");
is($provider_count, '4', 'Provider has 4 rows');

# Subscriber still has 3 rows (the 4th row was inserted with repair_mode)
my $sub_count_before = scalar_query(2, "SELECT COUNT(*) FROM test_resync");
is($sub_count_before, '3', 'Subscriber still has 3 rows (4th row not replicated due to repair_mode)');

# Now resync with truncate=true should succeed since provider is writable
my $resync_ok = `$pg_bin/psql -p $node_ports->[1] -d $dbname -t -c "SELECT spock.sub_resync_table('$sub_name', 'public.test_resync', true)" 2>&1`;
like($resync_ok, qr/t/, 'Resync with truncate succeeds when origin is writable');

# Wait for sync to complete
system_or_bail 'sleep', '10';

# Verify subscriber now has 4 rows after resync
my $final_count = scalar_query(2, "SELECT COUNT(*) FROM test_resync");
is($final_count, '4', 'Subscriber has 4 rows after successful resync with truncate');

# Destroy cluster
destroy_cluster('Destroy 2-node resync readonly check test cluster');
done_testing();
