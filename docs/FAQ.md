# Frequently Asked Questions

### Using a column filter

* What happens if I set up a column filter on a table with OIDS? Can I filter on xmin?
 - For a table with OIDs, column filter works fine. No, we cannot filter on system columns
like oid or xmin.

* What happens if a column being filtered on is dropped?
 - Currently in spock replication, you can drop even a primary key on the provider.
If a column being filtered on is dropped on the provider, it is removed from the column
filter too. Use `spock.repset_show_table()` to confirm this behavior.
 Columns on each subscriber remain as defined, which is correct and expected. In this state,
the subscriber replicates INSERTs, but does not replicate UPDATEs and DELETEs.

* If we add a column, does it automatically get included?
 - If you add a column to the provider, it is not automatically added to the column filter.

### The row filter

* Can we create `row_filter` on table with OIDS? Can we filter on xmin?
 - Yes, `row_filter` works fine for table with OIDs. No, we cannot filter on system columns like xmin.

* What types of function can we execute in a `row_filter`? Can we use a volatile sampling
function, for example?
 - We can execute immutable, stable and volatile functions in a `row_filter`. Caution must
be exercised with regard to writes as any expression which will do writes will throw error and stop replication.
   Volatile sampling function in `row_filter`: This would not work in practice as it would
not get correct snapshot of the data in live system. Theoretically with static data, it works.

* Can we test a JSONB datatype that includes some form of attribute filtering?
 - Yes, `row_filter` on attributes of JSONB datatype works fine.

### The apply delay

* Does `apply_delay` include TimeZone changes, for example Daylight Savings Time? There is a
similar mechanism in physical replication - `recovery_min_apply_delay`. However, if we set some
interval, during the daylight savings times, we might get that interval + the time change in
practice (ie instead of 1h delay you can get 2h delay because of that). This may lead to
stopping and starting the database service twice per year.
 - Yes, `apply_delay` include TimeZone changes, for example Daylight Savings Time. Value of
`apply_delay` stays the same in practice, if daylight savings time switch happens after
subscription was created.
However, we do not recommend running heavy workloads during switching time as spock
replication needs some time ( ~ 5 minutes) to recover fine.
