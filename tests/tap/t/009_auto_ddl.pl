use strict;
use warnings;
use Test::More;
use lib '.';
use SpockTest qw(
  create_cluster destroy_cluster system_or_bail command_ok get_test_config scalar_query psql_or_bail
);

sub wait_until {
  my ($timeout_s, $probe) = @_;
  my $deadline = time() + $timeout_s;
  while (time() < $deadline) {
    return 1 if $probe->();
    select(undef, undef, undef, 0.20); # 200ms
  }
  return 0;
}

# 1) create 2-node cluster (provider n1, subscriber n2) with Spock
create_cluster(2, 'Create a 2-node cluster');

# DSN for provider
my $conf = get_test_config();
my $host = $conf->{host};
my $pg_bin = $conf->{pg_bin};
my $ports = $conf->{node_ports};
my $datadirs = $conf->{node_datadirs};
my $dbname = $conf->{db_name};
my $user   = $conf->{db_user};

my $prov_port = $ports->[0];
my $sub_port  = $ports->[1];

my $prov_dsn_1 = "host=$host port=$ports->[0] dbname=$dbname user=$user";
my $prov_dsn_2 = "host=$host port=$ports->[1] dbname=$dbname user=$user";

# Create subscriptions on both nodes to each other
psql_or_bail(1, "SELECT spock.sub_create('test_sub_n1', '$prov_dsn_2')");
psql_or_bail(1, "SELECT nspname, relname, set_name FROM spock.tables");

# Create schema, table and function on provider (node 1)
psql_or_bail(1, "CREATE SCHEMA hollywood
    CREATE TABLE films (title text, release date, awards text[])
    CREATE TABLE shorts (title text, release date, awards text[]);");

psql_or_bail(1, "CREATE TABLE test1 (id int primary key, name text)");

psql_or_bail(1, "CREATE FUNCTION auto_ddl_test() RETURNS void AS \$\$
BEGIN
    EXECUTE 'CREATE TABLE test2 (id int primary key, name text)';
    EXECUTE 'CREATE TABLE test3 (id int primary key, name text)';
END;
\$\$ LANGUAGE plpgsql;");
psql_or_bail(1, "SELECT auto_ddl_test()");
psql_or_bail(1, "INSERT INTO test1 VALUES (1, 'one'), (2, 'two')");
my $syncevent = scalar_query(1, "SELECT spock.sync_event()");
$syncevent = "'$syncevent'";
diag("syncevent =======> $syncevent");
ok(wait_until(30, sub {
  scalar_query(2, "SELECT status FROM spock.sub_show_status('test_sub_n2')") eq 'replicating'
}), 'subscription is replicating');

# Wait for sync event to be processed on subscriber (node 2)
psql_or_bail(2, "CALL spock.wait_for_sync_event(true, 'n1', $syncevent)");

diag(psql_or_bail(2, "SELECT * FROM spock.tables"));
diag(psql_or_bail(2, "SELECT * FROM spock.progress"));
diag(psql_or_bail(2, "SELECT * FROM spock.queue"));
# Check schema, table and function appear on subscriber (node 2)
ok(scalar_query(2, "SELECT count(*) FROM spock.tables where nspname = 'hollywood' AND set_name IS NOT NULL") eq '2',
	'schema tables exists on n2');

ok(scalar_query(2, "SELECT count(*) FROM spock.tables where relname = 'test1' AND set_name IS NOT NULL") eq '1',
	'table test1 exists on n2');

ok(scalar_query(2, "SELECT count(*) FROM spock.tables where (relname = 'test2' or relname = 'test3') AND set_name IS NOT NULL") eq '2',
	'function tables exists on n2');

# Cleanup
diag(psql_or_bail(2, "SELECT * from spock.node"));
psql_or_bail(1, "SELECT spock.sub_drop('test_sub_n1')");
destroy_cluster('Destroy 2-node cluster');
done_testing();
