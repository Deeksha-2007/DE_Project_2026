# CP3 – Database Query Optimization Report

## 1. Introduction

The objective of CP3 was to improve the performance of the Dream11 database workload using indexes and optimized SQL queries.

The project contains 25 read queries (R01–R25) and 5 write queries (W01–W05).

The optimization was performed using PostgreSQL and tested on the same database dataset.

## 2. Optimization Techniques Used

### A. Indexing

A total of 15 additional indexes were created to improve query performance.

The indexes cover frequently used columns such as:

- `match_id` in `user_teams`
- `player_id` in `user_team_players`
- `user_id`, `status` and `created_at` in `wallet_transactions`
- `joined_at` and `user_team_id` in `contest_entries`
- `state_code` in `users`
- `contest_type` and `match_id` in `contests`

Partial indexes and covering indexes were also used for specific wallet transaction queries.

### B. Query Optimization

The following queries received significant SQL changes:

- **R02:** Used pre-aggregation to reduce unnecessary joins and repeated calculations.
- **R06:** Used pre-aggregation to calculate team and player counts more efficiently.
- **R13:** Replaced `NOT IN` with `NOT EXISTS` to avoid incorrect behavior when the subquery contains NULL values.
- **R14:** Replaced year extraction with a timestamp range condition.
- **R19:** Used a CTE to aggregate player selections once instead of repeatedly calculating them.
- **R20:** Replaced date casting in the filter with a timestamp range.
- **R22:** Used cursor-based pagination with a timestamp and transaction ID.

## 3. Benchmark Methodology

- Each query was executed 3 times.
- `EXPLAIN (ANALYZE, BUFFERS)` was used to collect execution plans and timings.
- Average execution time was used for comparison.
- Write queries were executed inside transactions and rolled back to avoid permanent changes to the data.
- Baseline and optimized results were saved separately.

## 4. Read Query Performance Comparison

| Query | Baseline (ms) | Optimized (ms) |
|---|---:|---:|
| R01 | 0.586 | 0.234 |
| R02 | 59.014 | 2.590 |
| R03 | 2.591 | 0.116 |
| R04 | 0.406 | 0.206 |
| R05 | 0.891 | 0.897 |
| R06 | 93.644 | 5.156 |
| R07 | 2.516 | 0.153 |
| R08 | 2.513 | 0.598 |
| R09 | 7.729 | 0.127 |
| R10 | 10.902 | 0.063 |
| R11 | 25.280 | 19.450 |
| R12 | 1.793 | 3.683 |
| R13 | 29.711 | 31.497 |
| R14 | 19.019 | 27.770 |
| R15 | 44.955 | 44.792 |
| R16 | 0.240 | 0.373 |
| R17 | 27.756 | 26.243 |
| R18 | 18.996 | 10.007 |
| R19 | 4181.717 | 39.702 |
| R20 | 9.544 | 0.800 |
| R21 | 10.623 | 10.339 |
| R22 | 48.219 | 4.936 |
| R23 | 0.055 | 0.047 |
| R24 | 1.048 | 0.931 |
| R25 | 18.402 | 2.251 |

### Key Observations

- R19 showed the largest improvement, reducing average execution time from approximately 4182 ms to 40 ms.
- R02 improved from 59.014 ms to 2.590 ms.
- R06 improved from 93.644 ms to 5.156 ms.
- R10 improved from 10.902 ms to 0.063 ms.
- R22 improved from 48.219 ms to 4.936 ms.
- Some queries, including R12, R13, R14 and R16, became slower. This shows that indexing and query rewriting do not improve every workload equally.

## 5. Write Query Performance Comparison

| Query | Baseline (ms) | Optimized (ms) |
|---|---:|---:|
| W01 | 0.893 | 0.955 |
| W02 | 0.705 | 0.535 |
| W03 | 0.773 | 1.110 |
| W04 | 11.949 | 12.325 |
| W05 | 10.038 | 1.729 |

### Write Performance Observations

Indexes can introduce additional work during insert, update and delete operations because PostgreSQL must maintain the indexes.

W03 and W04 became slightly slower after indexing. W05 improved significantly, likely because the partial index on pending withdrawals helped the query.

Therefore, indexes should be selected based on both read and write performance.

## 6. Index Storage

A total of 15 additional indexes were created.

The measured total storage used by these indexes was approximately **17 MB**.

The largest indexes were:

| Index | Size |
|---|---:|
| idx_wallet_user_status | 4624 kB |
| idx_wallet_created_txn | 3664 kB |
| idx_utp_player_id | 3136 kB |
| idx_successful_deposits | 1368 kB |
| idx_wallet_entry_fee_reference | 952 kB |

The indexes improve access to frequently searched and filtered columns, but they also increase storage requirements.

## 7. Correctness and Schema Notes

R13 was changed from `NOT IN` to `NOT EXISTS`. This addresses the NULL behavior of `NOT IN`, where a NULL returned by the subquery can cause the condition to evaluate as unknown.

The `contest_entries.winnings` column was also given a default value of 0. This allows new contest entries to be inserted without explicitly providing winnings, while preserving the NOT NULL constraint.

The original workload file `queries/workload_30.sql` was not modified.

## 8. Conclusion

The optimization improved the performance of several important read queries, especially R02, R06, R10, R19, R20 and R22.

R19 showed a particularly large improvement because repeated calculations were replaced with a single aggregation.

However, some queries became slower, and additional indexes require storage and maintenance during writes.

Overall, the results show that proper indexing, pre-aggregation, timestamp range filtering and efficient pagination can significantly improve database query performance. The best optimization should always be selected after measuring the actual workload.