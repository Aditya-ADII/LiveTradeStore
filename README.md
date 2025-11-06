# LiveTradeStore

Demo project: a partitioned PostgreSQL time-series store for trade data with fast bulk ingest and query optimization.

## What it demonstrates
- Time-based partitioning (daily) for partition pruning.
- Indexing strategies: B-Tree (`symbol, trade_ts`), BRIN on `trade_ts`, and a covering index (`INCLUDE`).
- Fast bulk ingest with `COPY` from CSV in a single transaction.
- Query benchmarking using `EXPLAIN ANALYZE`.

## Problem statement (one line)
Store and query high-rate trade/time-series data so analytical queries (volume, average price, top symbols) are fast while ingest remains efficient.

## Solution summary (one sentence)
Use a partitioned PostgreSQL table (time-based) + appropriate indexes; bulk-load rows with `COPY`; benchmark queries with `EXPLAIN ANALYZE`; add covering indexes if needed.

## Why each component is used (short)
- **Partitioning by time:** prunes data ranges so queries touching recent days scan fewer pages → faster queries.
- **B-Tree on (symbol, trade_ts):** ideal for equality (`symbol = ...`) + range (`trade_ts >= ...`) filters.
- **BRIN on trade_ts:** lightweight index for ordered append-only time series; reduces I/O for large ranges.
- **Covering index (`INCLUDE`):** allows aggregate queries to hit the index only (no heap fetch).
- **COPY in a single transaction:** fastest safe bulk ingest for Postgres.
- **EXPLAIN ANALYZE:** evidence — shows actual planner choices and timings.

## Quick start (local)

1. **Install Postgres (13+) and Python 3.10+.**

2. **Create the database and run schema**
   ```bash
   # create DB if needed (run as a user with CREATE DATABASE permission)
   psql -d postgres -c "CREATE DATABASE livetrade;"
   # then run schema
   psql -d livetrade -f schema.sql

   ## 📊 Example Output Screenshots

All screenshots are located in the `img/` folder.

![Query Plan](<img/Screenshot 2025-11-06 132110.png>)
![Execution Graph](<img/Screenshot 2025-11-06 132122.png>)
![Latency View](<img/Screenshot 2025-11-06 132133.png>)
![Partition Summary](<img/Screenshot 2025-11-06 132146.png>)
