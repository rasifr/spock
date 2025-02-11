## NAME

`spock.repset-add-table()`

## SYNOPSIS

`spock.repset-add-table (REPLICATION_SET TABLE DB <flags>)`
 
## DESCRIPTION

Add a table or tables to a replication set. 

## EXAMPLE

`spock.repset-add-table (demo_repset 'public.*' demo)`
 
## POSITIONAL ARGUMENTS
    REPLICATION_SET
        The replication set name. Example: demo_repset
    TABLE
        The name of the table(s) to add. To add all tables matching a pattern use single quotes and * as a wildcard. Examples: *, mytable, public.*
    DB
        The name of the database. Example: demo
 
## FLAGS
    -s, --synchronize_data=SYNCHRONIZE_DATA
        Synchronized table data on all related subscribers.
    
    -c, --columns=COLUMNS
        list of columns to replicate. Example: my_id, col_1, col_2
    
    -r, --row_filter=ROW_FILTER
        Row filtering expression. Example: my_id = 1001
    
    -i, --include_partitions=INCLUDE_PARTITIONS
        include all partitions in replication.
    
  **WARNING: Use caution when synchronizing data with a valid row filter.**

Using `sync_data=true` with a valid `row_filter` is usually a one-time operation for a table. Executing it again with a modified `row_filter` won't synchronize data to subscriber. You may need to call `spock.alter_sub_resync_table()` to fix it.
