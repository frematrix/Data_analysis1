-- 1. Create table ‘table_to_delete’ and fill it with the following query:

CREATE TABLE table_to_delete AS
SELECT 'veeeeeeery_long_string' || x AS col
FROM generate_series(1,(10^7)::int) x; -- generate_series() creates 10^7 rows of sequential numbers from 1 to 10000000 (10^7)
               
-- 2. Lookup how much space this table consumes with the following query:
-- Answer: 575 MB of occupied space

SELECT *, pg_size_pretty(total_bytes) AS total,
          pg_size_pretty(index_bytes) AS INDEX,
          pg_size_pretty(toast_bytes) AS toast,
          pg_size_pretty(table_bytes) AS TABLE
FROM (SELECT *, total_bytes-index_bytes-COALESCE(toast_bytes,0) AS table_bytes
      FROM (SELECT c.oid,nspname AS table_schema,
                relname AS TABLE_NAME,
                c.reltuples AS row_estimate,
                pg_total_relation_size(c.oid) AS total_bytes,
                pg_indexes_size(c.oid) AS index_bytes,
                pg_total_relation_size(reltoastrelid) AS toast_bytes
          	FROM pg_class c
          	LEFT JOIN pg_namespace n ON n.oid = c.relnamespace
          	WHERE relkind = 'r'
          	) a
) a
WHERE table_name LIKE '%table_to_delete%';

-- 3. Issue the following DELETE operation on ‘table_to_delete’:

DELETE FROM table_to_delete
WHERE REPLACE(col, 'veeeeeeery_long_string','')::int % 3 = 0; -- removes 1/3 of all ROWS

-- a) Note how much time it takes to perform this DELETE statement;
-- Answer: Deleting 333,333 rows took 36 seconds because DELETE command is scanning table row by row.

-- b) Lookup how much space this table consumes after previous DELETE;
-- Answer: 575 MB of occupied space - the same size because of dead rows which occupy the table

--  c) Perform the following command (if you're using DBeaver, press Ctrl+Shift+O to observe server output (VACUUM results)): 
-- Answer: It took 18 seconds and VACUUM FULL command returns space occupied by dead rows and their indexes.

VACUUM FULL VERBOSE table_to_delete;
-- vacuuming "public.table_to_delete"
-- "public.table_to_delete": found 0 removable, 6666667 nonremovable row versions in 73536 pages

-- d) Check space consumption of the table once again and make conclusions;
-- Answer: 383 MB of occupied space

-- e) Recreate ‘table_to_delete’ table;
DROP TABLE table_to_delete;

CREATE TABLE table_to_delete AS
SELECT 'veeeeeeery_long_string' || x AS col
FROM generate_series(1,(10^7)::int) x;

-- 4. Issue the following TRUNCATE operation:

TRUNCATE table_to_delete;

-- a) Note how much time it takes to perform this TRUNCATE statement.
-- Answer: it took 0 seconds because removes all rows without scanning and counting them

-- b) Compare with previous results and make conclusion.
-- Answer: DELETE TABLE and TRUNCATE table results are same but TRUNCATE command is faster, it doesn't lock the table during the delete operation.

-- c) Check space consumption of the table once again and make conclusions;
-- 0 MB, the table is clear, there's no dead tupple, index. TRUNCATE returns the disk space, it's no need to use the VACUUM operation like in case of DELETE.

-- 5. Hand over your investigation's results to your trainer.
-- I wrote in comment line - below the task description - the results of the queries and my experiences of each task.