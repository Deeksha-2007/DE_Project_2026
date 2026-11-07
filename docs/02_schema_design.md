# Dream11 Fantasy Sports Database – Schema Design

## 1. Introduction

This document describes the relational database schema designed for the Dream11 Fantasy Sports application.

The database is implemented using PostgreSQL 17 and contains 10 tables. It stores information about cricket teams, players, matches, users, fantasy teams, contests, contest entries, player statistics, and wallet transactions.

The main objectives of this database design are:

- To organize the application data into structured relational tables.
- To maintain data accuracy using primary keys, foreign keys, and constraints.
- To avoid unnecessary data duplication.
- To support the application's operational and analytical requirements.
- To maintain relationships between users, their fantasy teams, matches, and contests.

## 2. Database Overview

The database uses the schema name `dream11`.

The following 10 tables have been created:

| No. | Table Name | Purpose |
|---|---|---|
| 1 | `teams` | Stores cricket team information. |
| 2 | `players` | Stores player details and their associated cricket teams. |
| 3 | `matches` | Stores match details, participating teams, venue, and schedule. |
| 4 | `player_match_stats` | Stores individual player performance statistics for each match. |
| 5 | `users` | Stores registered user information and KYC status. |
| 6 | `user_teams` | Stores fantasy teams created by users for matches. |
| 7 | `user_team_players` | Stores the players selected in each fantasy team. |
| 8 | `contests` | Stores contest details, entry fees, spots, and prize pools. |
| 9 | `contest_entries` | Stores users' fantasy team entries into contests and their results. |
| 10 | `wallet_transactions` | Stores deposits, withdrawals, entry fees, refunds, and winnings. |

### 2.1 Database Implementation

- **DBMS:** PostgreSQL
- **Version:** 17.11
- **Database name:** `dream11_db`
- **Schema name:** `dream11`
- **Total tables:** 10
- **Total records loaded:** 698,657

All 10 tables were successfully created, and the CSV seed data was loaded into the corresponding tables.

## 3. Primary Keys and Foreign Keys

Primary keys uniquely identify each record in a table. Foreign keys connect related tables and maintain referential integrity.

| Table | Primary Key | Foreign Keys |
|---|---|---|
| teams | `team_id` | None |
| players | `player_id` | `team_id` → teams |
| matches | `match_id` | `home_team_id` → teams, `away_team_id` → teams |
| player_match_stats | `(match_id, player_id)` | `match_id` → matches, `player_id` → players |
| users | `user_id` | None |
| user_teams | `user_team_id` | `user_id` → users, `match_id` → matches, `captain_id` → players, `vice_captain_id` → players |
| user_team_players | `(user_team_id, player_id)` | `user_team_id` → user_teams, `player_id` → players |
| contests | `contest_id` | `match_id` → matches |
| contest_entries | `entry_id` | `contest_id` → contests, `user_team_id` → user_teams |
| wallet_transactions | `txn_id` | `user_id` → users, `reference_entry_id` → contest_entries |

### 3.1 Composite Primary Keys

Two tables use composite primary keys:

- `player_match_stats`: `(match_id, player_id)` ensures that a player's statistics are recorded only once for a particular match.
- `user_team_players`: `(user_team_id, player_id)` prevents the same player from being added more than once to a fantasy team.

### 3.2 Additional Unique Constraints

The following columns have UNIQUE constraints:

- `users.username`
- `users.phone`
- `users.email`
- `contests.invite_code`
- `(contest_entries.contest_id, contest_entries.user_team_id)`

These constraints prevent duplicate usernames, phone numbers, non-NULL email addresses, invite codes, and duplicate entries of the same fantasy team in a contest.

## 4. Relationships and Cardinalities

The database contains the following relationships:

| Parent Table | Child Table | Relationship | Cardinality |
|---|---|---|---|
| teams | players | A team has players. | One-to-Many |
| teams | matches | A team can participate in many matches. | One-to-Many |
| matches | player_match_stats | A match has player statistics. | One-to-Many |
| players | player_match_stats | A player can have statistics in many matches. | One-to-Many |
| users | user_teams | A user can create multiple fantasy teams. | One-to-Many |
| matches | user_teams | A match can have multiple fantasy teams. | One-to-Many |
| user_teams | user_team_players | A fantasy team contains selected players. | One-to-Many |
| players | user_team_players | A player can be selected in multiple fantasy teams. | One-to-Many |
| matches | contests | A match can have multiple contests. | One-to-Many |
| contests | contest_entries | A contest can have multiple entries. | One-to-Many |
| user_teams | contest_entries | A fantasy team can enter multiple contests. | One-to-Many |
| users | wallet_transactions | A user can have multiple wallet transactions. | One-to-Many |
| contest_entries | wallet_transactions | An entry can be referenced by multiple wallet transactions. | One-to-Many |

**Additional relationships:**

- `matches.home_team_id` and `matches.away_team_id` both reference `teams.team_id`.
- `user_teams.captain_id` and `user_teams.vice_captain_id` both reference `players.player_id`.

The `user_team_players` table acts as a bridge between `user_teams` and `players`, resolving their many-to-many relationship.

## 5. Data Types and Constraints

PostgreSQL data types were selected according to the nature of the information stored in each column.

### 5.1 Data Type Selection

| Data Type | Usage | Reason |
|---|---|---|
| INTEGER | IDs, runs, wickets, counts | Stores whole numbers. |
| VARCHAR(n) | Names, roles, status, venue | Stores variable-length text with a maximum length. |
| CHAR(2) | State codes | Stores fixed-length two-character codes. |
| NUMERIC(4,1) | Player credits | Stores decimal values accurately. |
| NUMERIC(7,1) | Fantasy points | Stores decimal fantasy scores. |
| NUMERIC(10,2) | Entry fees | Stores monetary values accurately. |
| NUMERIC(12,2) | Prize pools, winnings, wallet amounts | Stores larger monetary values accurately. |
| BOOLEAN | Active status and guaranteed contests | Stores TRUE or FALSE values. |
| TIMESTAMPTZ | Match and transaction timestamps | Stores date and time with time-zone awareness. |

### 5.2 NULL and NOT NULL Decisions

Columns that require a value are declared `NOT NULL`.

Some columns are allowed to contain NULL because their values may not be available or applicable.

| Table.Column | NULL Allowed? | Reason |
|---|---|---|
| users.email | Yes | Email is optional in the supplied dataset. |
| contests.invite_code | Yes | Public contests may not require an invite code. |
| user_teams.total_points | Yes | Points may not be calculated yet. |
| contest_entries.final_rank | Yes | Rank may not be available before contest completion. |
| wallet_transactions.reference_entry_id | Yes | Some transactions are not linked to a contest entry. |

All other columns are defined as NOT NULL.

### 5.3 CHECK Constraints

CHECK constraints ensure that values follow valid business rules.

The database contains 19 named CHECK constraints:

| No. | Constraint | Rule |
|---|---|---|
| 1 | `chk_team_type` | Team type must be FRANCHISE or INTERNATIONAL. |
| 2 | `chk_player_role` | Player role must be AR, BAT, BOWL, or WK. |
| 3 | `chk_player_credits` | Player credits must be greater than zero. |
| 4 | `chk_match_teams` | Home and away teams must be different. |
| 5 | `chk_match_status` | Match status must be valid. |
| 6 | `chk_stats_nonnegative` | Player statistics cannot be negative. |
| 7 | `chk_user_state_code` | State code must belong to the allowed list. |
| 8 | `chk_user_kyc_status` | KYC status must be PENDING, REJECTED, or VERIFIED. |
| 9 | `chk_different_captains` | Captain and vice-captain must be different. |
| 10 | `chk_user_team_points` | Total points must be NULL or non-negative. |
| 11 | `chk_contest_type` | Contest type must be valid. |
| 12 | `chk_contest_entry_fee` | Entry fee cannot be negative. |
| 13 | `chk_contest_total_spots` | Total spots must be greater than zero. |
| 14 | `chk_contest_prize_pool` | Prize pool cannot be negative. |
| 15 | `chk_entry_final_rank` | Final rank must be NULL or positive. |
| 16 | `chk_entry_winnings` | Winnings cannot be negative. |
| 17 | `chk_wallet_txn_type` | Transaction type must belong to the allowed list. |
| 18 | `chk_wallet_status` | Transaction status must be FAILED, PENDING, or SUCCESS. |
| 19 | `chk_wallet_amount` | Transaction amount must be greater than zero. |

The schema therefore satisfies the project requirement of at least 12 CHECK constraints.

### 5.4 Referential Actions

Foreign keys use different ON DELETE actions according to the relationship:

- **CASCADE:** Used where child records depend on the parent record, such as user teams belonging to users.
- **RESTRICT:** Prevents deletion of referenced records where deletion could affect important application data.
- **SET NULL:** Used for wallet transaction references so that a transaction can remain even if its referenced contest entry is deleted.

These actions help maintain referential integrity.

## 6. Functional Dependencies and Normalization

### 6.1 Functional Dependencies

A functional dependency describes how one attribute (or a group of attributes) determines other attributes in a table.

In this database, the primary keys determine the remaining non-key attributes.

| Table | Functional Dependencies |
|---|---|
| teams | `team_id → team_name, short_name, team_type` |
| players | `player_id → full_name, team_id, role, credits, is_active` |
| matches | `match_id → tournament, home_team_id, away_team_id, venue, starts_at, status` |
| player_match_stats | `(match_id, player_id) → runs, balls_faced, fours, sixes, wickets, catches, fantasy_points` |
| users | `user_id → username, phone, email, state_code, kyc_status, created_at` |
| user_teams | `user_team_id → user_id, match_id, team_label, captain_id, vice_captain_id, total_points, created_at` |
| user_team_players | `(user_team_id, player_id)` is the composite key. There are no other non-key attributes. |
| contests | `contest_id → match_id, contest_name, contest_type, entry_fee, total_spots, prize_pool, is_guaranteed, invite_code` |
| contest_entries | `entry_id → contest_id, user_team_id, joined_at, final_rank, winnings` |
| wallet_transactions | `txn_id → user_id, txn_type, amount, reference_entry_id, status, created_at` |

Additional candidate keys exist because of UNIQUE constraints:

- `users.username`
- `users.phone`
- `users.email` (for non-NULL values)
- `contests.invite_code` (for non-NULL values)
- `(contest_entries.contest_id, contest_entries.user_team_id)`

### 6.2 First Normal Form (1NF)

A relation is in First Normal Form when:

- Every column contains atomic (single) values.
- There are no repeating groups.
- Each row can be uniquely identified.

**Application in our database:**

All 10 tables satisfy 1NF. For example, player details are stored in individual columns instead of storing multiple player details inside one column.

The `user_team_players` table stores each selected player as a separate row.

### 6.3 Second Normal Form (2NF)

A relation is in Second Normal Form when:

- It is already in 1NF.
- Every non-key attribute depends on the whole candidate key, not just a part of it.

**Application in our database:**

All 10 tables satisfy 2NF.

The tables `player_match_stats` and `user_team_players` use composite primary keys.

In `player_match_stats`, the performance statistics depend on both `match_id` and `player_id`, not on either attribute individually.

The `user_team_players` table contains only its composite key columns, so it has no partial dependency.

The remaining tables use single-column primary keys, so partial dependency on part of a composite primary key does not arise.

### 6.4 Third Normal Form (3NF)

A relation is in Third Normal Form when:

- It is already in 2NF.
- Non-key attributes do not depend transitively on a candidate key through another non-key attribute.

**Application in our database:**

All 10 tables are designed to satisfy 3NF.

For example:

- Team details are stored in `teams`, not repeated in `players`.
- Player details are stored in `players`, not repeated in every fantasy team.
- User information is stored in `users`, not repeated in `user_teams`.
- Contest details are stored in `contests`, not repeated in every contest entry.
- Wallet transaction details are stored separately in `wallet_transactions`.

Foreign keys are used to connect these tables instead of duplicating the complete information.

### 6.5 Boyce-Codd Normal Form (BCNF)

A relation is in BCNF when every determinant of a non-trivial functional dependency is a superkey.

**Application in our database:**

The tables are designed to satisfy BCNF under the functional dependencies identified above.

The primary keys and additional candidate keys determine the other attributes in their respective tables.

For example:

- `team_id` determines the team details.
- `player_id` determines the player details.
- `match_id` determines the match details.
- `entry_id` determines the contest entry details.

The composite keys in `player_match_stats` and `user_team_players` also uniquely identify their respective records.

### 6.6 Normalization Summary

| Table | 1NF | 2NF | 3NF | BCNF |
|---|---|---|---|---|
| teams | Yes | Yes | Yes | Yes |
| players | Yes | Yes | Yes | Yes |
| matches | Yes | Yes | Yes | Yes |
| player_match_stats | Yes | Yes | Yes | Yes |
| users | Yes | Yes | Yes | Yes |
| user_teams | Yes | Yes | Yes | Yes |
| user_team_players | Yes | Yes | Yes | Yes |
| contests | Yes | Yes | Yes | Yes |
| contest_entries | Yes | Yes | Yes | Yes |
| wallet_transactions | Yes | Yes | Yes | Yes |

The database is normalized to BCNF based on the identified functional dependencies and candidate keys. This reduces unnecessary duplication and helps maintain data consistency.

## 7. Derived and Redundant Columns

Some columns in the database store values that can be calculated from other information. These are called derived or redundant columns.

Our database contains three important examples:

### 7.1 `player_match_stats.fantasy_points`

- **Table:** `player_match_stats`
- **Derived from:** Runs, balls faced, fours, sixes, wickets, catches, and fantasy scoring rules.
- **Reason for retaining:** Fantasy points are frequently required for player rankings, leaderboards, and performance reports.
- **Benefit:** Storing the calculated points avoids repeatedly calculating them from individual statistics.
- **Trade-off:** If player statistics or scoring rules change, fantasy points must also be recalculated.

### 7.2 `user_teams.total_points`

- **Table:** `user_teams`
- **Derived from:** Fantasy points of selected players, including captain and vice-captain multipliers.
- **Reason for retaining:** Total points are frequently needed to display user team scores and contest leaderboards.
- **Benefit:** Storing the total makes leaderboard queries faster and reduces repeated calculations.
- **Trade-off:** The stored total must be updated whenever the underlying player scores change.

### 7.3 `contests.prize_pool`

- **Table:** `contests`
- **Potentially related to:** Entry fees, contest participation, number of spots, and prize distribution rules.
- **Reason for retaining:** The prize pool is an important contest attribute that users need to see before joining a contest.
- **Benefit:** Storing it allows the application to display the advertised prize pool directly without recalculating it every time.
- **Trade-off:** The stored prize pool must remain consistent with the actual contest rules and financial records.

### 7.4 Final Decision

All three columns have been retained in the database.

Although they contain calculated or potentially derivable information, they improve query performance and make

## 8. Database Loading and Verification

### 8.1 Loading the CSV Data

The database was populated using the CSV files provided in the project seed data. The data was loaded through the `sql/02_load_data.sql` script using PostgreSQL's `\copy` command.

Tables were loaded in parent-before-child order to satisfy foreign-key dependencies. After loading, the `ANALYZE` command was executed to update PostgreSQL table statistics.

All 10 CSV files were loaded successfully without errors.

### 8.2 Row Count Verification

The following table shows the number of records loaded into each database table.

| Table Name | Records Loaded |
|---|---:|
| teams | 18 |
| players | 450 |
| matches | 212 |
| player_match_stats | 4,444 |
| users | 50,000 |
| user_teams | 39,975 |
| user_team_players | 439,925 |
| contests | 2,544 |
| contest_entries | 42,746 |
| wallet_transactions | 118,343 |
| **Total** | **698,657** |

The total number of records loaded across all 10 tables is **698,657**.

### 8.3 Integrity Verification

After loading the data, integrity checks were performed to verify that the records satisfy the database relationships and important business rules.

The following checks returned zero invalid records:

| Validation Check | Invalid Records |
|---|---:|
| Players with invalid team IDs | 0 |
| Matches with invalid home team IDs | 0 |
| Matches with invalid away team IDs | 0 |
| Matches with identical home and away teams | 0 |
| Player statistics with invalid match IDs | 0 |
| Player statistics with invalid player IDs | 0 |
| User teams with invalid user IDs | 0 |
| User teams with invalid match IDs | 0 |
| User teams with invalid captain IDs | 0 |
| User teams with invalid vice-captain IDs | 0 |
| User teams with identical captain and vice-captain | 0 |
| Selected players with invalid user team IDs | 0 |
| Selected players with invalid player IDs | 0 |
| Contests with invalid match IDs | 0 |
| Contest entries with invalid contest IDs | 0 |
| Contest entries with invalid user team IDs | 0 |
| Wallet transactions with invalid user IDs | 0 |
| Wallet transactions with invalid contest entry references | 0 |

The results confirm that the loaded records satisfy the checked foreign-key relationships and business rules.

### 8.4 Constraint Verification

The database schema contains:

- 10 tables.
- Primary keys on all tables.
- Foreign-key constraints to maintain relationships.
- Composite primary keys on `player_match_stats` and `user_team_players`.
- UNIQUE constraints to prevent duplicate values and entries.
- 19 named CHECK constraints to enforce valid values and business rules.

The CSV data was successfully loaded while all these constraints were active. This confirms that the loaded records satisfy the defined database constraints.

## 9. Workload Analysis and Design Considerations

The project workload contains 30 SQL queries:

- 25 read queries (R01–R25).
- 5 write queries (W01–W05).

The read queries cover user activity, player performance, match information, contest participation, wallet transactions and financial reporting. The write queries cover operational activities such as creating teams, joining contests and recording wallet transactions.

### 9.1 Important Observation: R13 Financial Audit Query

During workload analysis, an issue was identified in query R13, which checks paid contest entries without corresponding wallet debit