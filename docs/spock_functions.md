## Spock Functions

The following functions are included in the `spock` extension:

| Command  | Description |
|----------|----------------| 
| **Node Management Functions** | |
| [node_add_interface](functions/spock_node_add_interface.md) | Add a new node interface.
| [node-alter-location](functions/spock-node-alter-location.md) | Set location details for a spock node.
| [node-create](functions/spock-node-create.md) | Define a node for spock.
| [node-drop](functions/spock-node-drop.md) | Remove a spock node.
| [node-drop-interface](functions/spock-node-drop-interface.md) | Delete a node interface.
| [node-list](functions/spock-node-list.md) | Display a table listing the current nodes.
| **Replication Set Management Functions** | |
| [repset-add-partition](functions/spock-repset-add-partition.md) | Add a partition to a replication set.
| [repset-add-seq](functions/spock-repset-add-seq.md) | Add a sequence to a replication set.
| [repset-add-table](functions/spock-repset-add-table.md) | Add table(s) to replication set.
| [repset-alter](functions/spock-repset-alter.md) | Modify a replication set.
| [repset-create](functions/spock-repset-create.md) | Define a replication set.
| [repset-drop](functions/spock-repset-drop.md) | Remove a replication set.
| [repset-list-tables](functions/spock-repset-list-tables.md) | List tables in replication sets.
| [repset-remove-partition](functions/spock-repset-remove-partition.md) | Remove a partition from the replication set that the parent table is a part of.
| [repset-remove-seq](functions/spock-repset-remove-seq.md) | Remove a sequence from a replication set.
| [repset-remove-table](functions/spock-repset-remove-table.md) | Remove table from replication set.
| **Subscription Management Functions** | |
| [sub-add-repset](functions/spock-sub-add-repset.md) | Add a replication set to a subscription.
| [sub-alter-interface](functions/spock-sub-alter-interface.md) | Modify an interface to a subscription.
| [sub-create](functions/spock-sub-create.md) | Create a subscription.
| [sub-disable](functions/spock-sub-disable.md) | Put a subscription on hold and disconnect from provider.
| [sub-drop](functions/spock-sub-drop.md) | Delete a subscription.
| [sub-enable](functions/spock-sub-enable.md) | Make a subscription live.
| [sub-remove-repset](functions/spock-sub-remove-repset.md) | Drop a replication set from a subscription.
| [sub-resync-table](functions/spock-sub-resync-table.md) | Resynchronize a table.
| [sub-show-status](functions/spock-sub-show-status.md) | Display the status of the subcription.
| [sub-show-table](functions/spock-sub-show-table.md) | Show subscription tables.
| [sub-wait-for-sync](functions/spock-sub-wait-for-sync.md) | Pause until the subscription is synchronized.
| **Miscellaneous Management Functions** | |
| [table-wait-for-sync](functions/spock-table-wait-for-sync.md) | Pause until a table finishes synchronizing.
| [replicate-ddl](functions/spock-replicate-ddl.md) | Enable DDL replication.
| [sequence-convert](functions/spock-sequence-convert.md) | Convert sequence(s) to snowflake sequences. 
| [set-readonly](functions/spock-set-readonly.md) | Turn PostgreSQL read-only mode 'on' or 'off'.
| [health-check](functions/spock-health-check.md) | Check to see if the PostgreSQL instance is accepting connections.
| [metrics-check](functions/spock-metrics-check.md) | Retrieve advanced database and operating system metrics.

