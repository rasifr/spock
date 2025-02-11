<<<<<<< HEAD
## NAME spock node-add-interface

## SYNOPSIS

`spock node-add-interface NODE_NAME INTERFACE_NAME DSN DB` 
=======
## NAME

`spock.node-add-interface()`

## SYNOPSIS

`spock node-add-interface (NODE_NAME INTERFACE_NAME DSN DB)` 
>>>>>>> f7af430 (Updating syntax in .md files)

## DESCRIPTION

Add an additional interface to a spock node. 
    
When a node is created, the interface is also created using the dsn specified in the create_node command, and with the same name as the node. This interface allows you to add alternative interfaces with different connection strings to an existing node.

## EXAMPLE 

`spock.node-add-interface (n1 n1_2 'host=10.1.2.5 user=pgedge dbname=demo' demo`)

## POSITIONAL ARGUMENTS
    NODE_NAME
        The name of the node. Should reference the node already created in this database. Example: n1
    INTERFACE_NAME
        The interface name to add to the node. The interface created by default matches the node name, add a new interface with a unique name. Example: n1_2
    DSN
        The additional connection string to the node. The user in this string should equal the OS user. This connection string should be reachable from outside and match the one used later in the sub-create command. Example: host=10.1.2.5 port= 5432 user=pgedge dbname=demo
    DB
        The name of the database. Example: demo
