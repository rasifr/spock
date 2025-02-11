## SYNOPSIS
`spock repset-create SET_NAME DB <flags>`
 
## DESCRIPTION

Create a replication set. 

## Example

`spock repset-create demo_repset demo`
 
## POSITIONAL ARGUMENTS
    SET_NAME
        The name of the replication set. Example: demo_repset
    DB
        The name of the database. Example: demo
 
## FLAGS
    --replicate_insert=REPLICATE_INSERT
        For tables in this replication set, set to `true` to replicate inserts; the default is `true`.
    
    --replicate_update=REPLICATE_UPDATE
        For tables in this replication set, set to `true` to replicate updates; the default is `true`.
    
    --replicate_delete=REPLICATE_DELETE
        For tables in this replication set, set to `true` to replicate deletes; the default is `true`.
    
    --replicate_truncate=REPLICATE_TRUNCATE
        For tables in this replication set, set to `true` to replicate truncate; the default is `true`.
    
