SELECT * FROM spock_regress_variables()
\gset

\c :subscriber_dsn
GRANT ALL ON SCHEMA public TO nonsuper;
SELECT E'\'' || current_database() || E'\'' AS subdb;
\gset

\c :provider_dsn

SELECT * FROM spock.repset_create('delay');

\c :subscriber_dsn

CREATE or REPLACE function int2interval (x integer) returns interval as
$$ select $1*'1 sec'::interval $$
language sql;

SELECT * FROM spock.sub_create(
    subscription_name := 'test_subscription_delay',
    provider_dsn := (SELECT provider_dsn FROM spock_regress_variables()) || ' user=super',
	replication_sets := '{delay}',
	forward_origins := '{}',
	synchronize_structure := false,
	synchronize_data := false,
	apply_delay := int2interval(2) -- 2 seconds
);

BEGIN;
SET LOCAL statement_timeout = '30s';
SELECT spock.sub_wait_for_sync('test_subscription_delay');
COMMIT;

SELECT sync_kind, sync_subid, sync_nspname, sync_relname, sync_status IN ('y', 'r') FROM spock.local_sync_status ORDER BY 2,3,4;

SELECT status FROM spock.sub_show_status() WHERE subscription_name = 'test_subscription_delay';

-- Make sure we see the slot and active connection
\c :provider_dsn
SELECT plugin, slot_type, database, active FROM pg_replication_slots;
SELECT count(*) FROM pg_stat_replication;

CREATE TABLE public.timestamps (
        id text primary key,
        ts timestamptz
);

SELECT spock.replicate_ddl($$
    CREATE TABLE public.basic_dml1 (
        id serial primary key,
        other integer,
        data text,
        something interval
    );
$$);
-- clear old applies, from any previous tests etc.
SELECT spock.wait_slot_confirm_lsn(NULL, NULL);

INSERT INTO timestamps VALUES ('ts1', CURRENT_TIMESTAMP);

SELECT * FROM spock.repset_add_table('delay', 'basic_dml1');

SELECT spock.wait_slot_confirm_lsn(NULL, NULL);

INSERT INTO timestamps VALUES ('ts2', CURRENT_TIMESTAMP);

INSERT INTO basic_dml1(other, data, something)
VALUES (5, 'foo', '1 minute'::interval),
       (4, 'bar', '12 weeks'::interval),
       (3, 'baz', '2 years 1 hour'::interval),
       (2, 'qux', '8 months 2 days'::interval),
       (1, NULL, NULL);

SELECT spock.wait_slot_confirm_lsn(NULL, NULL);

INSERT INTO timestamps VALUES ('ts3', CURRENT_TIMESTAMP);

SELECT round (EXTRACT(EPOCH FROM (SELECT ts from timestamps where id = 'ts2')) -
       EXTRACT(EPOCH FROM (SELECT ts from timestamps where id = 'ts1'))) :: integer >= 2 as ddl_replication_delayed;
SELECT round (EXTRACT(EPOCH FROM (SELECT ts from timestamps where id = 'ts3')) -
       EXTRACT(EPOCH FROM (SELECT ts from timestamps where id = 'ts2'))) :: integer >= 2 as inserts_replication_delayed;

\c :subscriber_dsn

SELECT * FROM basic_dml1;

SELECT spock.sub_drop('test_subscription_delay');

\c :provider_dsn
\set VERBOSITY terse
SELECT * FROM spock.repset_drop('delay');
DROP TABLE public.timestamps CASCADE;
SELECT spock.replicate_ddl($$
    DROP TABLE public.basic_dml1 CASCADE;
$$);
