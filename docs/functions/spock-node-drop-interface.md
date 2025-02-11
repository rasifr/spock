## NAME

`spock.node-drop-interface()`

## SYNOPSIS

`spock.node-drop-interface (NODE_NAME INTERFACE_NAME DB)`
 
## DESCRIPTION

Drop an interface from a spock node. 

## EXAMPLE

`spock.node-drop-interface (n1 n1_2 demo)`
 
## POSITIONAL ARGUMENTS
    NODE_NAME
        The name of the node. Example: n1
    INTERFACE_NAME
        The interface name (the named DSN created with `spock node-add-interface`) to remove from the node. Example: n1_2
    DB
        The name of the database. Example: demo
