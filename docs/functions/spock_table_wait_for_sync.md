## NAME

`spock.table-wait-for-sync()`

## SYNOPSIS

`spock.table-wait-for-sync (SUBSCRIPTION_NAME RELATION DB)`
 
## DESCRIPTION
    
Pause until a table finishes synchronizing. 

## EXAMPLE

`spock.table-wait-for-sync (sub_n2n1 mytable demo)`
 
## POSITIONAL ARGUMENTS
    SUBSCRIPTION_NAME
        The name of the subscription. Example: sub_n2n1
    RELATION
        The name of a table. Example: mytable
    DB
        The name of the database. Example: demo
