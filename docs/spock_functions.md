## Spock Functions

The following functions are included in the `spock` extension:

| Command  | Description |
|----------|-------------| 
| **Node Management Functions** | |
| [node_add_interface](functions/spock_node_add_interface.md) | Add a new node interface.
| [node_alter_location](functions/spock_node_alter_location.md) | Set location details for a spock node.
| [node_create](functions/spock_node_create.md) | Define a node for spock.
| [node_drop](functions/spock_node_drop.md) | Remove a spock node.
| [node_drop_interface](functions/spock_node_drop_interface.md) | Delete a node interface.
| [node_list](functions/spock_node_list.md) | Display a table listing the current nodes.
| **Replication Set Management Functions** | |
| [repset_add_partition](functions/spock_repset_add_partition.md) | Add a partition to a replication set.
| [repset_add_seq](functions/spock_repset_add_seq.md) | Add a sequence to a replication set.
| [repset_add_table](functions/spock_repset_add_table.md) | Add table(s) to replication set.
| [repset_alter](functions/spock_repset_alter.md) | Modify a replication set.
| [repset_create](functions/spock_repset_create.md) | Define a replication set.
| [repset_drop](functions/spock_repset_drop.md) | Remove a replication set.
| [repset_list_tables](functions/spock_repset_list_tables.md) | List tables in replication sets.
| [repset_remove_partition](functions/spock_repset_remove_partition.md) | Remove a partition from the replication set that the parent table is a part of.
| [repset_remove_seq](functions/spock_repset_remove_seq.md) | Remove a sequence from a replication set.
| [repset_remove_table](functions/spock_repset_remove_table.md) | Remove table from replication set.
| **Subscription Management Functions** | |
| [sub_add_repset](functions/spock_sub_add_repset.md) | Add a replication set to a subscription.
| [sub_alter_interface](functions/spock_sub_alter_interface.md) | Modify an interface to a subscription.
| [sub_create](functions/spock_sub_create.md) | Create a subscription.
| [sub_disable](functions/spock_sub_disable.md) | Put a subscription on hold and disconnect from provider.
| [sub_drop](functions/spock_sub_drop.md) | Delete a subscription.
| [sub_enable](functions/spock_sub_enable.md) | Make a subscription live.
| [sub_remove_repset](functions/spock_sub_remove_repset.md) | Drop a replication set from a subscription.
| [sub_resync_table](functions/spock_sub_resync_table.md) | Resynchronize a table.
| [sub_show_status](functions/spock_sub_show_status.md) | Display the status of the subcription.
| [sub_show_table](functions/spock_sub_show_table.md) | Show subscription tables.
| [sub_wait_for_sync](functions/spock_sub_wait_for_sync.md) | Pause until the subscription is synchronized.
| **Miscellaneous Management Functions** | |
| [table_wait_for_sync](functions/spock_table_wait_for_sync.md) | Pause until a table finishes synchronizing.
| [replicate_ddl](functions/spock_replicate_ddl.md) | Enable DDL replication.
| [sequence_convert](functions/spock_sequence_convert.md) | Convert sequence(s) to snowflake sequences. 
| [set_readonly](functions/spock_set_readonly.md) | Turn PostgreSQL read_only mode 'on' or 'off'.
| [health_check](functions/spock_health_check.md) | Check to see if the PostgreSQL instance is accepting connections.
| [metrics_check](functions/spock_metrics_check.md) | Retrieve advanced database and operating system metrics.

