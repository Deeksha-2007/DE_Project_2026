-- Phase 5: partitioned copy of wallet_transactions (RANGE by created_at, monthly).
-- Why RANGE on created_at: the ledger is append-mostly and queried by date
-- (R10, R20, R22, W05); old months can be archived or detached cheaply.
-- Primary-key rule: a PK/UNIQUE on a partitioned table must include the
-- partition column, so the key becomes (txn_id, created_at).
SET timezone = 'Asia/Kolkata';
DROP SCHEMA IF EXISTS dream11_part CASCADE;
CREATE SCHEMA dream11_part;

CREATE TABLE dream11_part.wallet_transactions
  (LIKE dream11.wallet_transactions INCLUDING DEFAULTS INCLUDING CONSTRAINTS)
  PARTITION BY RANGE (created_at);

ALTER TABLE dream11_part.wallet_transactions ADD PRIMARY KEY (txn_id, created_at);

DO $$
DECLARE d date := '2025-01-01';
BEGIN
  WHILE d < '2027-01-01' LOOP
    EXECUTE format(
      'CREATE TABLE dream11_part.wallet_txn_%s PARTITION OF dream11_part.wallet_transactions
       FOR VALUES FROM (%L) TO (%L)',
      to_char(d, 'YYYY_MM'), d::timestamptz, (d + interval '1 month')::date::timestamptz);
    d := (d + interval '1 month')::date;
  END LOOP;
END $$;

CREATE TABLE dream11_part.wallet_txn_default PARTITION OF dream11_part.wallet_transactions DEFAULT;

INSERT INTO dream11_part.wallet_transactions SELECT * FROM dream11.wallet_transactions;
CREATE INDEX ON dream11_part.wallet_transactions (user_id, created_at);
ANALYZE dream11_part.wallet_transactions;

-- Pruning demo: only wallet_txn_2026_06 should be scanned
EXPLAIN (ANALYZE, COSTS OFF)
SELECT * FROM dream11_part.wallet_transactions
WHERE created_at >= '2026-06-01 00:00:00+05:30' AND created_at < '2026-07-01 00:00:00+05:30'
  AND txn_type = 'DEPOSIT';

SELECT (SELECT count(*) FROM dream11.wallet_transactions)      AS original_rows,
       (SELECT count(*) FROM dream11_part.wallet_transactions) AS partitioned_rows;
