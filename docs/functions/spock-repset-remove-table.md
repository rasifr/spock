## NAME

`spock.repset-remove-table ()`

## SYNOPSIS

`spock.repset-remove-table (REPLICATION_SET TABLE DB)`
 
## DESCRIPTION

Remove a table from a replication set. 

## EXAMPLE 

`spock.repset-remove-table (demo_repset public.mytable demo)`
 
## POSITIONAL ARGUMENTS
    REPLICATION_SET
        The replication set name. Example: demo_repset
    TABLE
        The name of the table to remove. Examples:  public.mytable
    DB
        The name of the database. Example: demo
