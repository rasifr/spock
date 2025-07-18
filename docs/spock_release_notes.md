# Spock Release Notes

## v5.0 on July 15, 2025

* Spock functions and stored procedures now support node additions and major PostgreSQL version.  This means:
    * existing nodes are able to maintain full read and write capability while a new node is populated and added to the cluster.
    * You can perform PostgreSQL major version upgrades as a rolling upgrade by adding a new node with the new major PostgreSQL version, and then removing old nodes hosting the previous version. 
* Exception handling performance improvements are now managed with the spock.exception_replay_queue_size GUC.
* Previously, replication lag was estimated on the source node; this meant that if there were no transactions being replicated, the reported lag could continue to increase.  Lag tracking is now calculated at the target node, with improved accuracy.
* Spock 5.0 implements LSN Checkpointing with `spock.sync()` and `spock.wait_for_sync_event()`.  This feature allows you to identify a checkpoint in the source node WAL files, and watch for the LSN of the checkpoint on a replica node.  This allows you to guarantee that a DDL change, has replicated from the source node to all other nodes before publishing an update. 
* The `spockctrl` command line utility and sample workflows simplify the management of a Spock multi-master replication setup for PostgreSQL. `spockctrl` provides a convenient interface for:
    * node management
    * replication set management
    * subscription management
    * ad-hoc SQL execution
    * workflow automation
* Previously, replicated `DELETE` statements that attempted to delete a *missing* row were logged as exceptions.  Since the purpose of a `DELETE` statement is to remove a row, we no longer log these as exceptions. Instead these are now logged in the `Resolutions` table.
* `INSERT` conflicts resulting from a duplicate primary key or identity replica are now transformed into an `UPDATE` that updates all columns of the existing row, using Last-Write-Wins (LWW) logic.  The transaction is then logged in the node’s `Resolutions` table, as either: 
    * `keep local` if the local node’s `INSERT` has a later timestamp than the arriving `INSERT`
    * `apply remote` if the arriving `INSERT` from the remote node had a later timestamp
* In a cluster composed of distributed and physical replica nodes, Spock 5.0 improves performance by tracking the Log Sequence Numbers (LSNs) of transactions that have been applied locally but are still waiting for confirmation from physical replicas.  A final `COMMIT` confirmation is provided only after those LSNs are confirmed on the physical replica.
This provides a two-phase acknowledgment:
   * Once when the target node has received and applied the transaction.
   * Once when the physical replica confirms the commit.
* The `spock.check_all_uc_indexes` GUC is an experimental feature (`disabled` by default); use this feature at your own risk.  If this GUC is `enabled`, Spock will continue to check unique constraint indexes, after checking the primary key / replica identity index.  Only one conflict will be resolved, using Last-Write-Wins logic.  If a second conflict occurs, an exception is recorded in the `spock.exception_log` table.


## Version 4.1
* Hardening Parallel Slots for OLTP production use.
  - Commit Order
  - Skip LSN
  - Optionally stop replicating in an Error
* Enhancements to Automatic DDL replication

## Version 4.0

* Full re-work of paralell slots implementation to support mixed OLTP workloads
* Improved support for delta_apply columns to support various data types
* Improved regression test coverage
* Support for [Large Object LOgical Replication](https://github.com/pgedge/lolor)
* Support for pg17

Our current production version is v3.3 and includes the following enhancements over v3.2:

* Automatic replication of DDL statements

## Version 3.2 

* Support for pg14
* Support for [Snowflake Sequences](https://github.com/pgedge/snowflake)
* Support for setting a database to ReadOnly
* A couple small bug fixes from pgLogical
* Native support for Failover Slots via integrating pg_failover_slots extension
* Parallel slots support for insert only workloads

## Version 3.1

* Support for both pg15 *and* pg16
* Prelim testing for online upgrades between pg15 & pg16
* Regression testing improvements
* Improved support for in-region shadow nodes (in different AZ's)
* Improved and document support for replication and maintaining partitioned tables.


**Version 3.0 (Beta)** includes the following important enhancements beyond the BDR/pg_logical base:

* Support for pg15 (support for pg10 thru pg14 dropped)
* Support for Asynchronous Multi-Master Replication with conflict resolution
* Conflict-free delta-apply columns
* Replication of partitioned tables (to help support geo-sharding) 
* Making database clusters location aware (to help support geo-sharding)
* Better error handling for conflict resolution
* Better management & monitoring stats and integration
* A 'pii' table for making it easy for personally identifiable data to be kept in country
* Better support for minimizing system interuption during switch-over and failover
