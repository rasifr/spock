
## Table of Contents
- [Automatic Replication of DDL](features.md#)
- [Basic Configuration and Usage](README.md#basic-configuration-and-usage)
- [Advanced Configuration Options](docs/guc_settings.md)
- [Spock Functions](docs/spock_functions.md)
- [Limitations](docs/limitations.md)
- [FAQ](docs/FAQ.md)
- [Release Notes](docs/spock_release_notes.md)

# Spock Feature Overview

The Spock extension is designed to support the following use cases:

* Asynchronous multi-active replication with conflict resolution
* Upgrades between major versions
* Full database replication
* Selective replication of sets of tables using replication sets
* Selective replication of table rows at either publisher or subscriber side (row_filter)
* Selective replication of partitioned tables
* Selective replication of table columns at publisher side
* Data gather/merge from multiple upstream servers

Note that:
* Spock works on a per-database level instead of a whole server level like physical streaming replication.
* One provider may feed multiple subscribers without incurring additional disk write overhead
* One subscriber can merge changes from several origins and detect conflict between changes with automatic and configurable conflict resolution (some, but not all aspects required for multi-master).
* Cascading replication is implemented in the form of changeset forwarding.


## Automatic Replication of DDL
The spock extension can now automatically replicate DDL statements. To enable this feature, set the following parameters to `on`: `spock.enable_ddl_replication`, `spock.include_ddl_repset`, and `spock.allow_ddl_from_functions`. We recommend you set these to `on` only when the database schema matches exactly on all nodes- either when all databases have no objects, or when all databases have exactly the same objects and all tables are added to replication sets.

`spock.enable_ddl_replication` enables replication of ddl statements through the default replication set. Some DDL statements are intentionally not replicated (ie. CREATE DATABASE), and some are replicated but could cause issues in two ways. Some DDL statements could lead to inconsistent data (ie. CREATE TABLE... AS...) since the DDL statement is replicated before the table is added to the replication set. Some DDL statements are replicated, but are potentially an issue in a 3+ node cluster (ie. DROP TABLE).

`spock.include_ddl_repset` enables spock to automatically add tables to replication sets at the time they are created on each node. Tables with Primary Keys will be added to the default replication set, and tables without Primary Keys will be added to the default_insert_only replication set. Altering a table to add or remove a Primary Key will make the correct adjustment to which replication set the table is part of. Setting a table to unlogged will remove it from replication. Detaching a partition will not remove it from replication.

`spock.allow_ddl_from_functions` enables spock to automatically replicate DDL statements that are called within functions to also be automatically replicated. This can be turned off if these functions are expected to run on every node.When this is set to off statements replicated from functions adhere to the same rule previously described for 'include_ddl_repset.' If a table possesses a defined primary key, it will be added into the 'default' replication set; alternatively, they will be added to the 'default_insert_only' replication set.

During the auto replication process, spock generates messages that provide information about the execution. Here are the descriptions for each message:
- "DDL statement replicated."
This message is a INFO level message. It is displayed whenever a DDL statement is successfully replicated. To include these messages in the server log files, the configuration must have "log_min_messages=INFO" set.
- "DDL statement replicated, but could be unsafe."
This message serves as a warning. It is generated when certain DDL statements, though successfully replicated, are deemed potentially unsafe. For example, statements like "CREATE TABLE... AS..." will trigger this warning.
- "This DDL statement will not be replicated."
This warning message is generated when auto replication is active, but the specific DDL is either unsupported or intentionally excluded from replication.4- "table 'test' was added to 'default' replication set." This is a LOG message providing information about the replication set used for a given table when 'spock.include_ddl_repset' is set.


## Replication of Partitioned Tables

You can use Spock to replicate partitioned tables; by default, when adding a partitioned table to a replication set, it will include all of its current partitions. If you add partitions later, you will need to use the `partition_add` function to add them to your replication sets. The DDL for the partitioned table and partitions must be present on the subscriber nodes (like a non-partitioned table).

When you remove a partitioned table from a replication set, by default, the partitions of the table will also be removed.

Replication of partitioned tables is a bit different from normal tables. When doing initial synchronization, we query the partitioned table (or parent) to get all the rows for synchronization purposes and don't synchronize the individual partitions. After the initial sync of data, the normal operations resume and the partitions start replicating like normal tables.

If you add individual partitions to the replication set, they will be replicated like regular tables (to the table of the same name as the partition on the subscriber). This has performance advantages when partitioning definition is the same on both provider and subscriber, as the partitioning logic does not have to be executed.

**Note:** There is an exception to individual partition replication: individual partitions won't sync up the existing data. It's equivalent to setting `synchronize_data = false`.

When partitions are replicated through a partitioned table, the exception is the `TRUNCATE` command which always replicates with the list of affected tables or partitions.

Additionally, `row_filter` can also be used with partitioned tables, as well as with individual partitions.




## Conflict-Free Delta-Apply Columns (Conflict Avoidance)

Conflicts can arise if a node is subscribed to multiple providers, or when local writes happen on a subscriber. The spock extension automatically detects and acts to remediate conflict depending on settings of your configuration parameters.

Logical Multi-Master replication can get itself into trouble on running sums (such as a YTD balance).  Unlike other solutions, we do NOT have a special data type for this.   Any numeric data type will work with the spock extension (including numeric, float, double precision, int4, int8, etc).

Suppose that a running bank account sum contains a balance of `$1,000`.   Two transactions "conflict" because they overlap with each from two different multi-master nodes.   Transaction A is a `$1,000` withdrawal from the account.  Transaction B is also a `$1,000` withdrawal from the account.  The correct balance is `$-1,000`.  Our Delta-Apply algorithm fixes this problem and highly conflicting workloads with this scenario (like a tpc-c like benchmark) now run correctly at lightning speeds.

This feature is powerful *and* simple in its implementation; when an update occurs on a 'log_old_value' column:

  - First, the old value for that column is captured to the WAL files.
  - Second, the new value comes in the transaction to be applied to a subscriber.
  - Before the new value overwrites the old value, a delta value is created from the above two steps and is correctly applied.

Note that on a conflicting transaction, the delta column will be correctly calculated and applied.  The conflict resolution strategy applies to non-delta columns (normally last-update-wins).  As a special safety-valve feature, if you ever need to re-set a `log_old_value` column you can temporarily alter the column to `log_old_value` is `false`.

### Conflict Configuration options

You can configure some aspects of Spock using configuration options in either `postgresql.conf` or via `ALTER SYSTEM SET`.

- `spock.conflict_resolution`
  Sets the resolution method for any detected conflicts between local data
  and incoming changes.

  Possible values:
  - `error` - the replication will stop on error if conflict is detected and
    manual action is needed for resolving
  - `apply_remote` - always apply the change that's conflicting with local
    data
  - `keep_local` - keep the local version of the data and ignore the
     conflicting change that is coming from the remote node
  - `last_update_wins` - the version of data with newest commit timestamp
     will be kept (this can be either local or remote version)

  For conflict resolution, the `track_commit_timestamp` PostgreSQL setting 
  is always enabled.

- `spock.conflict_log_level`
  Sets the log level for reporting detected conflicts when the
  `spock.conflict_resolution` is set to anything else than `error`.

  Main use for this setting is to suppress logging of conflicts.

  Possible values are same as for `log_min_messages` PostgreSQL setting.

  The default is `LOG`.


## Using Batch Inserts

Using batch inserts improves replication performance for transactions that perform multiple
inserts into a single table. Spock switches to batch mode when a transaction does 
more than five `INSERT`s.

- `spock.batch_inserts`
  Tells Spock to use batch insert mechanism if possible. Batch mechanism
  uses PostgreSQL internal batch insert mode which is also used by `COPY`
  command.

You can only use batch mode if there are no `INSTEAD OF INSERT` and `BEFORE INSERT` 
triggers on the table and when there are no defaults with volatile expressions for 
columns of the table. Also the batch mode will only work when `spock.conflict_resolution` 
is set to `error`. The default value of `spock.conflict_resolution` is `true`.


### Creating subscriber nodes with base backups

In addition to the SQL-level node and subscription creation, Spock also
supports creating a subscriber node by cloning the provider with `pg_basebackup` and
starting it up as a Spock subscriber. Use the `spock_create_subscriber` tool
(located in the `bin` directory of your installation) to register the node.

#### Synopsis:

  `spock_create_subscriber [OPTION]...`

**Options**

Specify the following options as needed.

| Option   | Description
|----------|-------------
| `-D`, `--pgdata=DIRECTORY` | `data` directory to be used for new node. This can be either empty/non-existing directory, or directory populated using the `pg_basebackup -X stream` command.
| `--databases`              |  optional list of databases to replicate
| `-n`, `--subscriber-name=NAME` | name of the newly created subscriber
| `--subscriber-dsn=CONNSTR` | connection string to the newly created subscriber
| `--provider-dsn=CONNSTR` | connection string to the provider
| `--replication-sets=SETS` | comma separated list of replication set names
| `--apply-delay=DELAY` | apply delay in seconds (by default 0)
| `--drop-slot-if-exists` | drop replication slot of conflicting name
| `-s`, `--stop` | stop the server once the initialization is done
| `-v` | increase logging verbosity
| `--extra-basebackup-args` | Additional arguments to pass to `pg_basebackup`. Safe options: `-T`, `-c`, `--xlogdir`/`--waldir`


**Overriding the location of Configuration files**

You can use the following options to override the location of the configuration files.

| Option   | Description
|----------|-------------
|`--hba-conf` | path to the new pg_hba.conf
| `--postgresql-conf` | path to the new postgresql.conf
| `--recovery-conf` | path to the template recovery configuration

Unlike `spock.sub_create`'s data sync options, this clone ignores
replication sets and copies all tables on all databases. However, it's often
much faster, especially over high-bandwidth links.


## Filtering

### Row Filtering

Spock allows row based filtering both on provider side and the subscriber
side.

#### Row Filtering on Provider

On the provider the row filtering can be done by specifying `row_filter`
parameter for the `spock.repset_add_table` function. The
`row_filter` is normal PostgreSQL expression which has the same limitations
on what's allowed as the `CHECK` constraint.

Simple `row_filter` would look something like `row_filter := 'id > 0'` which
would ensure that only rows where values of `id` column is bigger than zero
will be replicated.

It's allowed to use volatile function inside `row_filter` but caution must
be exercised with regard to writes as any expression which will do writes
will throw error and stop replication.

It's also worth noting that the `row_filter` is running inside the replication
session so session specific expressions such as `CURRENT_USER` will have
values of the replication session and not the session which did the writes.

#### Row Filtering on Subscriber

On the subscriber the row based filtering can be implemented using standard
`BEFORE TRIGGER` mechanism.

It is required to mark any such triggers as either `ENABLE REPLICA` or
`ENABLE ALWAYS` otherwise they will not be executed by the replication
process.


## Automatically Assigning Tables to Replication Sets

Auto DDL is a great alternative to using a trigger to manage replication sets, but if you do need to dynamically modify replication rules, column or row filters, or partition filters, this trigger might be useful. This trigger does not replicate the DDL statements across nodes, but automatically adds newly created tables to a replication set on the node on which the trigger fires.


Before using the trigger, you should modify this trigger to account for all flavors of `CREATE TABLE` statements you might run. Since the trigger executes in a transaction, if the code in the trigger fails, the transaction is rolled back, including any `CREATE TABLE` statements that caused the trigger to fire. This means that statements like `CREATE UNLOGGED TABLE` will fail if the trigger fails.

Please note that you must ensure that automatic replication of DDL commands is disabled.  You can use the following commands on the PSQL command line to disable Auto DDL functionality:

```sql
ALTER SYSTEM SET spock.enable_ddl_replication=off;
ALTER SYSTEM SET spock.include_ddl_repset=off;
ALTER SYSTEM SET spock.allow_ddl_from_functions=off;
SELECT pg_reload_conf(); 
```

You can use the event trigger facility can be used to describe rules which define replication sets for newly created tables. For example:

```sql
    CREATE OR REPLACE FUNCTION spock_assign_repset()
    RETURNS event_trigger AS $$
    DECLARE obj record;
    BEGIN
        FOR obj IN SELECT * FROM pg_event_trigger_ddl_commands()
        LOOP
            IF obj.object_type = 'table' THEN
                IF obj.schema_name = 'config' THEN
                    PERFORM spock.repset_add_table('configuration', obj.objid);
                ELSIF NOT obj.in_extension THEN
                    PERFORM spock.repset_add_table('default', obj.objid);
                END IF;
            END IF;
        END LOOP;
    END;
    $$ LANGUAGE plpgsql;

    CREATE EVENT TRIGGER spock_assign_repset_trg
        ON ddl_command_end
        WHEN TAG IN ('CREATE TABLE', 'CREATE TABLE AS')
        EXECUTE PROCEDURE spock_assign_repset();
```

The code snippet shown above puts all new tables created in the `config` schema into
a replication set named `configuration`, and all other new tables which are not created
by extensions will go into the `default` replication set.


## Snowflake Sequences
[Snowflake](https://github.com/pgEdge/snowflake-sequences) is a PostgreSQL extension that provides an int8 and sequence based unique ID solution to optionally replace the PostgreSQL built-in bigserial data type. This extension allows Snowflake IDs that are unique within one sequence across multiple PostgreSQL instances in a distributed cluster.
