## SYNOPSIS
`./pgedge spock node-drop NODE_NAME DB`
 
## DESCRIPTION
    Drop a spock node. 

## Example 
`spock node-drop n1 demo`
 
## POSITIONAL ARGUMENTS
    NODE_NAME
        The name of the node. Example: n1
    DB
        The name of the database. Example: demo
    IFEXISTS
        `ifexists` specifies the Spock extension behavior with regards to error messages. If `true`, an error is not thrown when the specified node does not exist. The default is `false`.
