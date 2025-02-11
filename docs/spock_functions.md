## Spock Functions

The following functions are included in the `spock` extension:

| Command  | Description |
|----------|----------------| 
| **Node Management Functions** | |
| [node-add-interface](functions/spock-node-add-interface.md) | Add a new node interface.
| [node-alter-location](doc/spock-node-alter-location.md) | Set location details for a spock node.
| [node-create](doc/spock-node-create.md) | Define a node for spock.
| [node-drop](doc/spock-node-drop.md) | Remove a spock node.
| [node-drop-interface](doc/spock-node-drop-interface.md) | Delete a node interface.
| [node-list](doc/spock-node-list.md) | Display a table listing the current nodes.
| **Replication Set Management Functions** | |
| [repset-add-partition](doc/spock-repset-add-partition.md) | Add a partition to a replication set.
| [repset-add-seq](doc/spock-repset-add-seq.md) | Add a sequence to a replication set.
| [repset-add-table](doc/spock-repset-add-table.md) | Add table(s) to replication set.
| [repset-alter](doc/spock-repset-alter.md) | Modify a replication set.
| [repset-create](doc/spock-repset-create.md) | Define a replication set.
| [repset-drop](doc/spock-repset-drop.md) | Remove a replication set.
| [repset-list-tables](doc/spock-repset-list-tables.md) | List tables in replication sets.
| [repset-remove-partition](doc/spock-repset-remove-partition.md) | Remove a partition from the replication set that the parent table is a part of.
| [repset-remove-seq](doc/spock-repset-remove-seq.md) | Remove a sequence from a replication set.
| [repset-remove-table](doc/spock-repset-remove-table.md) | Remove table from replication set.
| **Subscription Management Functions** | |
| [sub-add-repset](doc/spock-sub-add-repset.md) | Add a replication set to a subscription.
| [sub-alter-interface](doc/spock-sub-alter-interface.md) | Modify an interface to a subscription.
| [sub-create](doc/spock-sub-create.md) | Create a subscription.
| [sub-disable](doc/spock-sub-disable.md) | Put a subscription on hold and disconnect from provider.
| [sub-drop](doc/spock-sub-drop.md) | Delete a subscription.
| [sub-enable](doc/spock-sub-enable.md) | Make a subscription live.
| [sub-remove-repset](doc/spock-sub-remove-repset.md) | Drop a replication set from a subscription.
| [sub-resync-table](doc/spock-sub-resync-table.md) | Resynchronize a table.
| [sub-show-status](doc/spock-sub-show-status.md) | Display the status of the subcription.
| [sub-show-table](doc/spock-sub-show-table.md) | Show subscription tables.
| [sub-wait-for-sync](doc/spock-sub-wait-for-sync.md) | Pause until the subscription is synchronized.
| **Miscellaneous Management Functions** | |
| [table-wait-for-sync](doc/spock-table-wait-for-sync.md) | Pause until a table finishes synchronizing.
| [replicate-ddl](doc/spock-replicate-ddl.md) | Enable DDL replication.
| [sequence-convert](doc/spock-sequence-convert.md) | Convert sequence(s) to snowflake sequences. 
| [set-readonly](doc/spock-set-readonly.md) | Turn PostgreSQL read-only mode 'on' or 'off'.
| [health-check](doc/spock-health-check.md) | Check to see if the PostgreSQL instance is accepting connections.
| [metrics-check](doc/spock-metrics-check.md) | Retrieve advanced database and operating system metrics.

