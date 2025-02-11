## NAME

`spock.sub-enable()`

## SYNOPSIS

`spock.sub-enable (SUBSCRIPTION_NAME DB <flags>)`

## DESCRIPTION

Enable a subscription. 

## Example

`spock sub-enable (sub_n2n1 demo)`
 
## POSITIONAL ARGUMENTS
    SUBSCRIPTION_NAME
        The name of the subscription. Example: sub_n2n1
    DB
        The name of the database. Example: demo
 
## FLAGS
    -i, --immediate=IMMEDIATE
        tells Spock when to stop the subscription. If set to `true`, the subscription is stopped immediately; if set to `false` (the default), it will be only stopped at the end of current transaction.
    
