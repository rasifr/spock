## NAME

`spock.sub-add-repset()`

## SYNOPSIS

`spock.sub-add-repset (SUBSCRIPTION_NAME REPLICATION_SET DB)`
 
## DESCRIPTION

Adds one replication set into a subscriber. Does not synchronize, only activates consumption of events.

## EXAMPLE

`spock.sub-add-repset (sub_n2n1 demo_repset demo)`
 
## POSITIONAL ARGUMENTS
    SUBSCRIPTION_NAME
        The name of the subscription. Example: sub_n2n1
    REPLICATION_SET
        Name of a replication set. Example: demo_repset
    DB
        The name of the database. Example: demo
