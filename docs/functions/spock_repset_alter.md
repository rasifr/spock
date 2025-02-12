## NAME

`spock.repset-alter()`

## SYNOPSIS

`spock.repset-alter (SET_NAME DB <flags>)`
 
## DESCRIPTION

Alter a replication set. 

 ## EXAMPLE

`spock.repset-alter (demo_repset demo --replicate_truncate=False)`
 
## POSITIONAL ARGUMENTS
    SET_NAME
        The name of the replication set. Example: demo_repset
    DB
        The name of the database. Example: demo
 
## FLAGS
    --replicate_insert=REPLICATE_INSERT
        For tables in the specified replication set, replicate inserts.  The default is true.
    
    --replicate_update=REPLICATE_UPDATE
        For tables in the specified replication set, replicate updates.  The default is true.
    
    --replicate_delete=REPLICATE_DELETE
        For tables in the specified replication set, replicate deletes.  The default is true.
    
    --replicate_truncate=REPLICATE_TRUNCATE
        For tables in the specified replication set, replicate truncate.  The default is true.
    
