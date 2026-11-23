
-- Phase 4: Indexes for query optimization
SET search_path TO dream11;

-- Used when finding teams for a particular match
CREATE INDEX idx_user_teams_match_id
ON user_teams(match_id);

-- Used when finding a user's teams for a match
CREATE INDEX idx_user_teams_user_match
ON user_teams(user_id, match_id);

-- Helps when searching for a player in selected teams
CREATE INDEX idx_utp_player_id
ON user_team_players(player_id);

-- Wallet history of a particular user
CREATE INDEX idx_wallet_user_status
ON wallet_transactions(user_id, status, created_at);

-- Pending withdrawals
CREATE INDEX idx_pending_withdrawals
ON wallet_transactions(created_at)
WHERE txn_type = 'WITHDRAWAL'
AND status = 'PENDING';

-- Finding users from particular states
CREATE INDEX idx_users_state_code
ON users(state_code);

-- Contest entries filtered by joining date
CREATE INDEX idx_entries_joined_at
ON contest_entries(joined_at);

-- Finding entries using user team ID
CREATE INDEX idx_entries_user_team
ON contest_entries(user_team_id);

-- Finding contest types
CREATE INDEX idx_contests_type
ON contests(contest_type);

-- Finding contests for a particular match
CREATE INDEX idx_contests_match
ON contests(match_id);

-- Successful winnings for KYC checks
CREATE INDEX idx_successful_winnings
ON wallet_transactions(user_id)
INCLUDE (amount)
WHERE txn_type = 'WINNINGS'
AND status = 'SUCCESS';

-- Refund lookup for refund audit
CREATE INDEX idx_wallet_refund_reference
ON wallet_transactions(reference_entry_id)
WHERE txn_type = 'REFUND';

-- Entry fee lookup for finance audit
CREATE INDEX idx_wallet_entry_fee_reference
ON wallet_transactions(reference_entry_id)
WHERE txn_type = 'ENTRY_FEE';

-- Successful deposits in the selected date range
CREATE INDEX idx_successful_deposits
ON wallet_transactions(created_at)
INCLUDE (amount)
WHERE txn_type = 'DEPOSIT'
AND status = 'SUCCESS';

-- Helps the wallet transaction pagination query
CREATE INDEX idx_wallet_created_txn
ON wallet_transactions(created_at DESC, txn_id DESC);

-- Update planner statistics after creating indexes
ANALYZE;

-- R05: leaderboard reads team + user columns for every entry; covering index avoids heap visits
CREATE INDEX IF NOT EXISTS idx_user_teams_cover ON dream11.user_teams (user_team_id) INCLUDE (user_id, team_label, total_points);
CREATE INDEX IF NOT EXISTS idx_users_cover ON dream11.users (user_id) INCLUDE (username);
