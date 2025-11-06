-- schema.sql (fixed: no %d in format)
CREATE EXTENSION IF NOT EXISTS pg_trgm; -- optional

-- Drop old table if present (safe)
DROP TABLE IF EXISTS trades CASCADE;

-- Master partitioned table (no PRIMARY KEY here)
CREATE TABLE trades (
    trade_id bigserial,
    symbol text NOT NULL,
    trade_ts timestamptz NOT NULL,
    price numeric(12,4) NOT NULL,
    qty integer NOT NULL,
    side smallint NOT NULL,
    exchange text
) PARTITION BY RANGE (trade_ts);

-- Create daily partitions for the last 8 days and per-partition indexes
DO
$$
DECLARE
    i integer;
    start_date date := current_date - 7;
    part_name text;
    frm text;
    to_ text;
BEGIN
    FOR i IN 0..7 LOOP
        part_name := 'trades_p' || i;          -- build name with concatenation
        frm := (start_date + i)::text;
        to_ := (start_date + i + 1)::text;

        -- create partition table
        EXECUTE format(
            'CREATE TABLE IF NOT EXISTS %I PARTITION OF trades FOR VALUES FROM (%L) TO (%L);',
            part_name, frm, to_);

        -- create useful indexes on each partition
        EXECUTE format('CREATE INDEX IF NOT EXISTS %I_symbol_ts ON %I (symbol, trade_ts);',
                       part_name || '_idx', part_name);
        EXECUTE format('CREATE INDEX IF NOT EXISTS %I_ts_brin ON %I USING BRIN (trade_ts);',
                       part_name || '_brin', part_name);
    END LOOP;
END
$$;

-- Global (master) indexes (these are propagated to partitions in modern Postgres)
CREATE INDEX IF NOT EXISTS idx_trades_symbol_ts ON trades (symbol, trade_ts);
CREATE INDEX IF NOT EXISTS idx_trades_ts_brin ON trades USING BRIN (trade_ts);

-- Optional: covering index (uncomment if you want to test)
-- CREATE INDEX IF NOT EXISTS idx_trades_symbol_ts_cover ON trades (symbol, trade_ts) INCLUDE (price, qty);
