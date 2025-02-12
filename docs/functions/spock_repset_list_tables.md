## NAME

`spock.repset-list-tables ()`

## SYNOPSIS

`spock.repset-list-tables (SCHEMA DB)`
 
## DESCRIPTION

List all tables in all replication sets. 

## EXAMPLE

`spock.repset-list-tables ('*' demo)`
 
## POSITIONAL ARGUMENTS
    SCHEMA
        The name of the schema to list tables from. To list tables matching a pattern use single quotes and * as a wildcard. Examples: *, mytable, my*
    DB
        The name of the database. Example: demo
