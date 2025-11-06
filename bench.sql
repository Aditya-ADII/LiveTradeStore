-- bench.sql
-- Run: psql -d livetrade -f bench.sql

-- Analyze first to give planner stats
ANALYZE trades;

-- Query 1: symbol volume and avg price in last 3 days
EXPLAIN ANALYZE
SELECT symbol, sum(qty) as total_qty, avg(price) as avg_price
FROM trades
WHERE symbol = 'AAPL'
  AND trade_ts >= now() - interval '3 days'
GROUP BY symbol;

-- Query 2: top 5 symbols by volume last 1 day
EXPLAIN ANALYZE
SELECT symbol, sum(qty) as vol
FROM trades
WHERE trade_ts >= now() - interval '1 day'
GROUP BY symbol
ORDER BY vol DESC
LIMIT 5;

-- Optional: full table scan example to compare
EXPLAIN ANALYZE
SELECT count(*) FROM trades WHERE trade_ts >= now() - interval '7 days';
