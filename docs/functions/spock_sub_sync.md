## NAME

`spock.sub-sync()`

## SYNOPSIS

`spock.sub-sync (subscription_name, truncate)`
 
## DESCRIPTION
    
Call this function to synchronize all unsynchronized tables in all sets in a single operation. Tables are copied and synchronized one by one. The command does not wait for completion before returning to the caller. Use `spock.wait_for_sub_sync` to wait for completion.

## POSITIONAL ARGUMENTS
    SUBSCRIPTION_NAME
        The name of the subscription. Example: sub_n2n1
    TRUNCATE
        Tell Spock if it should truncate tables before copying. If `true`, tables will be truncated before copy; the default is `false`.