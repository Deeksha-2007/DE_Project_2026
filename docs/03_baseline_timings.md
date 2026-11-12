# Phase 3: Baseline Query Timings

**Database:** `dream11_db` · **Schema:** `dream11` · **PostgreSQL version:** local install  
**Method:** `EXPLAIN (ANALYZE, BUFFERS)` · **3 runs per query** · **Average reported**  
**No indexes added** — this is the untuned baseline, as required.  
**Write queries (W01–W05)** were run inside `BEGIN; … ROLLBACK;` — data unchanged.  
**Raw plans:** `benchmarks/results/baseline/R01.txt` … `W05.txt`  
**Summary CSV:** `benchmarks/results/baseline/summary.csv`

---

## Timing Table (all 30 queries)

| SQL Query | Type | Run 1 (ms) | Run 2 (ms) | Run 3 (ms) | Average (ms) |
|-----------|------|----------:|----------:|----------:|-------------:|
| R01: Lobby: upcoming matches with number of contests and total prize money | READ | 0.798 | 0.480 | 0.480 | 0.586 |
| R02: Create team screen: player pool of match 207 with credits and % picked | READ | 60.862 | 57.947 | 58.233 | 59.014 |
| R03: "My teams": user 1006's teams for match 130 with captain and VC names | READ | 2.702 | 2.408 | 2.662 | 2.591 |
| R04: Contest list for match 207: spots left, biggest prize first | READ | 0.431 | 0.390 | 0.396 | 0.406 |
| R05: Leaderboard: contest 2185 ranked by team points | READ | 1.051 | 0.804 | 0.818 | 0.891 |
| R06: Fair play: teams breaking rules (not 11 players, over 100 credits, >7 from one side) | READ | 93.769 | 93.191 | 93.971 | 93.644 |
| R07: Team preview: player points in user 1006's first team for match 130 (captain 2×, VC 1.5×) | READ | 2.648 | 2.352 | 2.547 | 2.516 |
| R08: Match insights: most-picked captains for match 207 | READ | 2.573 | 2.486 | 2.480 | 2.513 |
| R09: Wallet: user 1006's transactions with running balance | READ | 7.702 | 7.816 | 7.670 | 7.729 |
| R10: Payouts: withdrawals pending more than 24 hours (checked 30 Jun 2026 23:59) | READ | 8.724 | 14.590 | 9.393 | 10.902 |
| R11: Compliance: users from banned states who joined paid contests in 2026 | READ | 25.806 | 24.553 | 25.481 | 25.280 |
| R12: Stats hub: top players by average fantasy points in IPL 2026 (≥5 matches) | READ | 1.828 | 1.813 | 1.738 | 1.793 |
| R13: Finance audit: paid contest entries with no entry-fee debit in wallet | READ | 29.791 | 29.239 | 30.104 | 29.711 |
| R14: Product analytics: average fill rate per contest type for completed 2026 matches | READ | 18.867 | 18.777 | 19.414 | 19.019 |
| R15: Leaderboards: top 20 users by winnings in 2026 | READ | 43.475 | 44.724 | 46.666 | 44.955 |
| R16: Player search (ILIKE '%sharma%') | READ | 0.239 | 0.239 | 0.243 | 0.240 |
| R17: Fair play: users with more than one team in the same contest | READ | 27.553 | 29.181 | 26.534 | 27.756 |
| R18: Tax compliance: users without verified KYC who won more than ₹1,000 | READ | 19.295 | 18.979 | 18.713 | 18.996 |
| R19: Selection report: in how many teams was each IPL player picked (all time) | READ | 4187.890 | 4241.986 | 4115.276 | 4181.717 |
| R20: Finance: successful deposits per day and running total, June 2026 | READ | 9.333 | 10.255 | 9.044 | 9.544 |
| R21: Engagement: users' head-to-head win rate (at least 3 H2H contests) | READ | 10.775 | 10.715 | 10.379 | 10.623 |
| R22: Support console: wallet transactions page 2001 (OFFSET 50000, 25 per page) | READ | 47.434 | 46.518 | 50.705 | 48.219 |
| R23: Login with mobile number | READ | 0.063 | 0.052 | 0.051 | 0.055 |
| R24: Player form: last 5 fantasy scores of every Chennai Super Kings player | READ | 1.064 | 1.043 | 1.037 | 1.048 |
| R25: Refund audit: paid entries in abandoned matches never refunded | READ | 17.370 | 17.554 | 20.283 | 18.402 |
| W01: Create team: user 1006 saves team T9 for match 207 | WRITE | 0.941 | 0.838 | 0.900 | 0.893 |
| W02: Join contest: user 1006's newest team for match 207 joins the mega contest | WRITE | 0.743 | 0.639 | 0.734 | 0.705 |
| W03: Wallet: debit the entry fee for the most recent contest entry | WRITE | 0.747 | 0.780 | 0.791 | 0.773 |
| W04: Points engine: recompute total points of every team for match 183 | WRITE | 13.470 | 11.258 | 11.119 | 11.949 |
| W05: Payouts: approve all withdrawals pending more than 24 hours | WRITE | 10.049 | 9.654 | 10.410 | 10.038 |
| **Total (sum of all 30 averages)** | | | | | **4687.457** |

---

## Per-Query Analysis: Scan Type and Explanation

### R01 — Lobby: upcoming matches (avg: 0.586 ms) ✅ Fast
**Scan type:** Seq Scan on `contests`, `matches`, `teams`  
**Why fast:** Only 212 matches and 18 teams — tiny tables. Sequential scans on small tables are cheaper than index lookups. The `status = 'UPCOMING'` filter is applied after the scan; with few rows, this is not a bottleneck.

---

### R02 — Player pool for match 207 (avg: 59.014 ms) ⚠️ Slow
**Scan type:** Seq Scan on `user_teams` (39,975 rows), Index Only Scan on `user_team_players`, Seq Scan on `matches`, `players`, `teams`  
**Why slow:** The correlated subquery `(SELECT count(*) FROM user_teams WHERE match_id = 207)` and the aggregation over `user_team_players` (439,925 rows joined to `user_teams`) requires scanning all 39,975 user teams to find those for match 207. No index on `user_teams(match_id)` forces a full table scan.

---

### R03 — My teams for user 1006, match 130 (avg: 2.591 ms) ✅ Acceptable
**Scan type:** Seq Scan on `user_teams`, Seq Scan on `players`  
**Why acceptable:** Filters on two columns (`user_id=1006` and `match_id=130`), both lack an index. With 39,975 rows in `user_teams`, the full scan is fast enough on the seed data but will degrade with more users.

---

### R04 — Contest list for match 207 (avg: 0.406 ms) ✅ Fast
**Scan type:** Seq Scan on `contests` (2,544 rows), Index Scan on `contest_entries` via unique constraint  
**Why fast:** `contests` is a small table (2,544 rows). The index scan on `contest_entries` via `uq_contest_user_team` is efficient for the aggregation.

---

### R05 — Leaderboard for contest 2185 (avg: 0.891 ms) ✅ Fast
**Scan type:** Index Only Scan on `contest_entries` (via `uq_contest_user_team`), Index Scan on `user_teams_pkey`, Index Scan on `users_pkey`  
**Why fast:** The `contest_id = 2185` lookup uses the existing unique constraint index efficiently. All joins go through primary keys — the fastest path.

---

### R06 — Fair play rule check for match 183 (avg: 93.644 ms) 🔴 Slowest read
**Scan type:** Seq Scan on `user_teams`, Index Only Scan on `user_team_players`, Seq Scan on `players`  
**Why slow:** This query uses a `CROSS JOIN LATERAL` subquery that runs once **per row per player** in every team for match 183. For each of the ~11 players in each team, it re-counts how many players from the same side are in that team. This is O(teams × players × lateral) — extremely expensive. Even with ~188 teams for match 183, each team runs the lateral subquery 11 times.

---

### R07 — Team preview for user 1006, match 130, team T1 (avg: 2.516 ms) ✅ Acceptable
**Scan type:** Seq Scan on `user_teams`, Index Only Scan on `user_team_players`, Index Scan on `players_pkey`, Index Scan on `pk_player_match_stats`  
**Why acceptable:** Narrows to a single team (T1 for user 1006, match 130). Only 11 rows fetched from `user_team_players`. The join to `player_match_stats` uses the primary key index efficiently.

---

### R08 — Most-picked captains for match 207 (avg: 2.513 ms) ✅ Acceptable
**Scan type:** Seq Scan on `user_teams` (39,975 rows), Seq Scan on `players` (450 rows)  
**Why acceptable:** Needs all teams for match 207. Without an index on `user_teams(match_id)`, it scans all 39,975 rows. With 450 players, the join is fast.

---

### R09 — Wallet running balance for user 1006 (avg: 7.729 ms) ⚠️ Slow
**Scan type:** Seq Scan on `wallet_transactions` (118,343 rows)  
**Why slow:** No index on `wallet_transactions(user_id)`. The query must scan all 118,343 transactions to find those belonging to user 1006 and status = 'SUCCESS'. The window function (`SUM OVER`) then processes the filtered rows in order.

---

### R10 — Pending withdrawals over 24 hours (avg: 10.902 ms) ⚠️ Slow
**Scan type:** Seq Scan on `wallet_transactions` (118,343 rows)  
**Why slow:** No index on `(txn_type, status, created_at)`. PostgreSQL must scan the entire 118k-row `wallet_transactions` table, then filter for `txn_type='WITHDRAWAL'`, `status='PENDING'`, and `created_at < cutoff`. A partial index on pending withdrawals would eliminate almost all this work.

---

### R11 — Compliance: banned-state users in paid contests 2026 (avg: 25.280 ms) ⚠️ Slow
**Scan type:** Seq Scan on `contest_entries` (42,746 rows), `user_teams` (39,975 rows), `users` (50,000 rows), `contests` (2,544 rows)  
**Why slow:** Four-way join across large tables with no index on `users(state_code)`, `contest_entries(joined_at)`, or `user_teams(user_id)`. Every table is fully scanned to find the small subset of banned-state users.

---

### R12 — Top players by average fantasy points in IPL 2026 (avg: 1.793 ms) ✅ Fast
**Scan type:** Seq Scan on `player_match_stats` (4,444 rows), `matches` (212 rows), `players` (450 rows), `teams` (18 rows)  
**Why fast:** `player_match_stats` has only 4,444 rows — small enough that a sequential scan is efficient. The filter on `tournament = 'IPL 2026'` via the `matches` join reduces the working set quickly.

---

### R13 — Finance audit: paid entries with no wallet debit (avg: 29.711 ms) ⚠️ Slow
**Scan type:** Seq Scan on `contest_entries` (42,746 rows), Seq Scan on `wallet_transactions` (118,343 rows), Seq Scan on `contests`  
**Why slow:** The `NOT IN (SELECT reference_entry_id FROM wallet_transactions)` subquery is a known NULL trap and performance problem. It scans all 118,343 wallet transactions to build a list of reference entry IDs. The outer query then checks every paid contest entry against this list. Additionally, `NOT IN` with NULLs present in `reference_entry_id` returns no rows at all — this is the **wrong-result bug** to investigate in Phase 4.

---

### R14 — Fill rate per contest type for completed 2026 matches (avg: 19.019 ms) ⚠️ Slow
**Scan type:** Seq Scan on `contests` (2,544 rows), Seq Scan on `matches` (212 rows), Index Scan on `contest_entries` via `uq_contest_user_team`  
**Why slow:** `EXTRACT(YEAR FROM m.starts_at) = 2026` applies a function to the column, making the filter non-sargable (can't use an index even if one existed on `starts_at`). Full scan of contests and matches required.

---

### R15 — Top 20 users by winnings in 2026 (avg: 44.955 ms) ⚠️ Slow
**Scan type:** Seq Scan on `contest_entries` (42,746 rows), `user_teams` (39,975 rows), `users` (50,000 rows)  
**Why slow:** Three large table joins with no indexes on `contest_entries(joined_at)` or `user_teams(user_id)`. All 42,746 contest entries are scanned to filter those from 2026, then joined to both `user_teams` and `users`.

---

### R16 — Player search ILIKE '%sharma%' (avg: 0.240 ms) ✅ Fast (small table)
**Scan type:** Seq Scan on `players` (450 rows), Seq Scan on `teams` (18 rows)  
**Why fast:** `players` has only 450 rows — a full sequential scan is instantaneous. The `ILIKE '%sharma%'` with leading wildcard cannot use a B-tree index anyway; on a larger table this would need a GIN trigram index.

---

### R17 — Fair play: users with multiple teams in same contest (avg: 27.756 ms) ⚠️ Slow
**Scan type:** Seq Scan on `contest_entries` (42,746 rows), Seq Scan on `user_teams` (39,975 rows)  
**Why slow:** No index on `user_teams(user_team_id)` for the join (beyond the PK which is used implicitly). Both tables are scanned in full; the grouping and `HAVING count(*) > 1` are applied after.

---

### R18 — Tax compliance: unverified KYC users with >₹1,000 winnings (avg: 18.996 ms) ⚠️ Slow
**Scan type:** Seq Scan on `wallet_transactions` (118,343 rows), Seq Scan on `users` (50,000 rows)  
**Why slow:** No index on `wallet_transactions(user_id, txn_type, status)`. All 118,343 wallet rows are scanned to find `WINNINGS` + `SUCCESS` rows, then joined to `users` to filter on `kyc_status`.

---

### R19 — Selection report: IPL players ranked by times picked (avg: 4181.717 ms) 🔴 Intentionally slow
**Scan type:** Seq Scan on `players` (450 rows), Seq Scan on `teams` (18 rows), Seq Scan on `user_team_players` (439,925 rows)  
**Why slow:** This is the **intentionally slow query** noted in the assignment. For each IPL franchise player (all 450 × FRANCHISE filter), it runs a correlated subquery `(SELECT count(*) FROM user_team_players WHERE player_id = p.player_id)`. That subquery scans all 439,925 rows of `user_team_players` once **per player**. With ~300+ franchise players, this results in ~300 sequential scans of a 440k-row table — extremely expensive. An index on `user_team_players(player_id)` will dramatically fix this in Phase 4.

---

### R20 — Deposits per day and running total, June 2026 (avg: 9.544 ms) ⚠️ Moderate
**Scan type:** Seq Scan on `wallet_transactions` (118,343 rows)  
**Why moderate:** `created_at::date BETWEEN '2026-06-01' AND '2026-06-30'` casts the timestamp to a date — this is a non-sargable expression, preventing index use. Full table scan required. A partial index or expression index on `created_at::date` would help.

---

### R21 — Head-to-head win rate (avg: 10.623 ms) ⚠️ Moderate
**Scan type:** Seq Scan on `user_teams`, Seq Scan on `contest_entries`, Seq Scan on `contests`  
**Why moderate:** No index on `contests(contest_type)`. All contests must be scanned to find `HEAD_TO_HEAD` ones. Then joined with `contest_entries` and `user_teams`.

---

### R22 — Support console OFFSET 50000 (avg: 48.219 ms) ⚠️ Slow
**Scan type:** Seq Scan on `wallet_transactions` (118,343 rows)  
**Why slow:** `OFFSET 50000` forces PostgreSQL to fetch and discard 50,000 rows before returning the 25 needed. As the offset grows, so does the cost. This is the classic offset-pagination anti-pattern — keyset pagination would eliminate this problem.

---

### R23 — Login by mobile number (avg: 0.055 ms) ✅ Very fast
**Scan type:** Index Scan using `users_phone_key` on `users`  
**Why fast:** A UNIQUE constraint on `users(phone)` auto-creates a B-tree index. The lookup goes straight to the single row — this is an index point-lookup, the fastest possible scan.

---

### R24 — Last 5 CSK player fantasy scores (avg: 1.048 ms) ✅ Fast
**Scan type:** Seq Scan on `player_match_stats` (4,444 rows), `players` (450 rows), `teams` (18 rows), `matches` (212 rows)  
**Why fast:** All four tables are small. The window function `ROW_NUMBER() OVER (PARTITION BY player_id ORDER BY starts_at DESC)` applied to 4,444 rows is fast.

---

### R25 — Refund audit: abandoned match entries never refunded (avg: 18.402 ms) ⚠️ Slow
**Scan type:** Seq Scan on `wallet_transactions` (118,343 rows), `contest_entries` (42,746 rows), `user_teams` (39,975 rows), `matches` (212 rows), `contests` (2,544 rows)  
**Why slow:** The `NOT EXISTS` subquery checks `wallet_transactions` for a matching refund for each contest entry. Five-table join with no index on `wallet_transactions(reference_entry_id, txn_type)`. The `matches(status='ABANDONED')` filter has no index either.

---

### W01 — Create team: insert user_teams row (avg: 0.893 ms) ✅ Fast
**Scan type:** Seq Scan on `matches` (212 rows)  
**Why fast:** Inserts a single row; the `FROM matches WHERE match_id=207` lookup scans 212 rows trivially. FK constraint checks use primary key indexes.

---

### W02 — Join contest: insert contest_entries row (avg: 0.705 ms) ✅ Fast
**Scan type:** Index Scan on `user_teams_pkey`, Seq Scan on `contests`  
**Why fast:** Single-row insert. The subquery `max(user_team_id)` uses the PK index. `ON CONFLICT DO NOTHING` uses the unique constraint index.

---

### W03 — Wallet debit: insert wallet_transactions row (avg: 0.773 ms) ✅ Fast
**Scan type:** Index Only Scan and Index Scan on `contest_entries_pkey`, Index Scan on `contests_pkey`, Index Scan on `user_teams_pkey`  
**Why fast:** Single-row insert via `max(entry_id)` lookup. All lookups use primary key indexes.

---

### W04 — Points engine: recompute total_points for match 183 (avg: 11.949 ms) ⚠️ Moderate
**Scan type:** Seq Scan on `user_teams`, Index Only Scan on `user_team_players`, Index Scan on `pk_player_match_stats`  
**Why moderate:** Must scan all `user_teams` to find those for `match_id=183`, then join to `user_team_players` and `player_match_stats` for each. Without an index on `user_teams(match_id)`, it scans all 39,975 teams. The update touches all teams for that match.

---

### W05 — Payouts: approve pending withdrawals over 24 hours (avg: 10.038 ms) ⚠️ Moderate
**Scan type:** Seq Scan on `wallet_transactions` (118,343 rows)  
**Why moderate:** No index on `(txn_type, status, created_at)`. Must scan all 118,343 rows to find `WITHDRAWAL` + `PENDING` + old enough. A partial index on pending withdrawals would reduce this to milliseconds.

---

## Summary Observations

| Category | Queries | Avg time range |
|----------|---------|----------------|
| Very fast (< 1 ms) | R01, R04, R16, R23, W01, W02, W03 | 0.055 – 0.893 ms |
| Fast (1–5 ms) | R03, R05, R07, R08, R12, R24 | 0.891 – 2.591 ms |
| Moderate (5–30 ms) | R09, R10, R13, R14, R17, R18, R20, R21, R25, W04, W05 | 7.7 – 29.7 ms |
| Slow (30–100 ms) | R02, R06, R11, R15, R22 | 25.3 – 93.6 ms |
| Very slow (> 100 ms) | R19 | **4181.7 ms** |

**Key bottlenecks identified for Phase 4:**
1. **R19** (4181 ms) — correlated subquery scanning 440k rows per player → needs index on `user_team_players(player_id)`
2. **R06** (93 ms) — CROSS JOIN LATERAL re-scans `user_team_players` per player per team → needs query rewrite + index
3. **R02** (59 ms) — no index on `user_teams(match_id)` → needs composite index
4. **R22** (48 ms) — OFFSET 50000 anti-pattern → keyset pagination rewrite
5. **R15** (45 ms) — multi-table join with no indexes on join/filter columns
6. **R13** (29 ms) — `NOT IN` with NULLs = wrong result + slow → rewrite to `NOT EXISTS`
