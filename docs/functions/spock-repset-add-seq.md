## NAME

`spock.repset-add-seq ()`

## SYNOPSIS

`spock.repset-add-seq (REPLICATION_SET SEQUENCE DB <flags>)`
 
## DESCRIPTION
    Add a sequence to a replication set.
 
## POSITIONAL ARGUMENTS
    REPLICATION_SET
        The name of an existing replication set.
    SEQUENCE
        The name or OID of the sequence to be added to the set.
    DB
        The name of the database.

## FLAGS
    -s, --synchronize_data=SYNCHRONIZE_DATA
        Instructs Spock to synchronize the table data on all nodes which are subscribed to the given replication set when set to `true`. The default is `false`.
    
    -p, --pg=PG
    
    
