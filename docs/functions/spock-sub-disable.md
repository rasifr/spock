## NAME 

`spock.sub-disable ()`

## SYNOPSIS

`spock.sub-disable (SUBSCRIPTION_NAME DB <flags>)`
 
## DESCRIPTION
    Disable a subscription by putting it on hold and disconnect from provider. 

## EXAMPLE

`spock sub-disable sub_n2n1 demo`
 
## POSITIONAL ARGUMENTS
    SUBSCRIPTION_NAME
        The name of the subscription. Example: sub_n2n1
    DB
        The name of the database. Example: demo
 
## FLAGS
    -i, --immediate=IMMEDIATE
        Tells Spock when to stop the subscription. If set to `true`, the subscription is stopped immediately; if set to `false` (the default), it will be only stopped at the end of current transaction.
    
