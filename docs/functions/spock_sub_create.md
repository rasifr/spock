## NAME

`spock.sub_create()`

## SYNOPSIS

`spock.sub_create (subscription_name name, provider_dsn text, repsets text[], sync_structure boolean,
  sync_data boolean, forward_origins text[], apply_delay interval)`
 
## DESCRIPTION

Creates a subscription from current node to the provider node. The command does not wait for completion before returning to the caller.

## EXAMPLE 

`spock.sub_create ('sub_n2n1', 'host=10.1.2.5 port=5432 user=rocky dbname=demo')`
 
## ARGUMENTS
    `subscription_name` 
        The name of the subscription. Each subscription in a cluster must have a unique name.  The name is used as `application_name` by the replication connection. This means that the name is visible in the `pg_stat_replication` monitoring view. 
    `provider_dsn` 
        The connection string to a provider.
    `repsets`
        An array of replication sets to subscribe to; these must already exist, default is `{default,default_insert_only,ddl_sql}`.
    `sync_structure`
        Specifies if Spock should synchronize the structure from provider to the subscriber; the default is `false`.
    `sync_data` 
        Specifies if Spock should synchronize data from provider to the subscriber, the default is `true`.
    `forward_origins`
        An array of origin names to forward; currently the only supported values are an empty array (meaning don't forward any changes that didn't originate on provider node, useful for two-way replication between the nodes), or `{all}` which means replicate all changes no matter what is their origin. The default is `{all}`.
    `apply_delay`
        How much to delay replication; the default is `0` seconds.
    `force_text_transfer`
        Force the provider to replicate all columns using a text representation (which is slower, but may be used to change the type of a replicated column on the subscriber). The default is `false`.
