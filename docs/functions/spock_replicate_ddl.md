## NAME

`spock.replicate-ddl ()`

## SYNOPSIS

`spock.replicate-ddl (REPLICATION_SETS SQL_COMMAND DB)`
 
## DESCRIPTION

Execute the `command` locally before then sending the specified command to the replication queue for execution on subscribers which are subscribed to one of the specified `repsets`.
 
## POSITIONAL ARGUMENTS
    REPLICATION_SETS
        One or more replication sets to replicate the ddl command to. Example: demo_repset, demo_repset,default
    SQL_COMMAND
        The SQL command to replicate. Use schema and object name. Example: "CREATE TABLE public.mytable (a INT PRIMARY KEY, b INT)"
    DB
        The name of the database. Example: demo
