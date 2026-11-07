-- Dream11 Fantasy Sports Database
-- Phase 2: Load CSV data into PostgreSQL

SET search_path TO dream11;

-- 1. Load teams
\copy dream11.teams (team_id, team_name, short_name, team_type) FROM 'seed_data/teams.csv' WITH (FORMAT csv, HEADER true);

-- 2. Load players
\copy dream11.players (player_id, full_name, team_id, role, credits, is_active) FROM 'seed_data/players.csv' WITH (FORMAT csv, HEADER true);

-- 3. Load matches
\copy dream11.matches (match_id, tournament, home_team_id, away_team_id, venue, starts_at, status) FROM 'seed_data/matches.csv' WITH (FORMAT csv, HEADER true);

-- 4. Load users
\copy dream11.users (user_id, username, phone, email, state_code, kyc_status, created_at) FROM 'seed_data/users.csv' WITH (FORMAT csv, HEADER true);

-- 5. Load player match statistics
\copy dream11.player_match_stats (match_id, player_id, runs, balls_faced, fours, sixes, wickets, catches, fantasy_points) FROM 'seed_data/player_match_stats.csv' WITH (FORMAT csv, HEADER true);

-- 6. Load user teams
\copy dream11.user_teams (user_team_id, user_id, match_id, team_label, captain_id, vice_captain_id, total_points, created_at) FROM 'seed_data/user_teams.csv' WITH (FORMAT csv, HEADER true);

-- 7. Load players selected in user teams
\copy dream11.user_team_players (user_team_id, player_id) FROM 'seed_data/user_team_players.csv' WITH (FORMAT csv, HEADER true);

-- 8. Load contests
\copy dream11.contests (contest_id, match_id, contest_name, contest_type, entry_fee, total_spots, prize_pool, is_guaranteed, invite_code) FROM 'seed_data/contests.csv' WITH (FORMAT csv, HEADER true);

-- 9. Load contest entries
\copy dream11.contest_entries (entry_id, contest_id, user_team_id, joined_at, final_rank, winnings) FROM 'seed_data/contest_entries.csv' WITH (FORMAT csv, HEADER true);

-- 10. Load wallet transactions
\copy dream11.wallet_transactions (txn_id, user_id, txn_type, amount, reference_entry_id, status, created_at) FROM 'seed_data/wallet_transactions.csv' WITH (FORMAT csv, HEADER true);

-- Update table statistics
ANALYZE;