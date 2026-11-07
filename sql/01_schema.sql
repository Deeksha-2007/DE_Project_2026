-- Dream11 Fantasy Sports Database
-- Phase 2: Database Schema Design

CREATE SCHEMA IF NOT EXISTS dream11;

SET search_path TO dream11;

-- 1. Teams table
CREATE TABLE teams (
    team_id INTEGER PRIMARY KEY,
    team_name VARCHAR(100) NOT NULL,
    short_name VARCHAR(10) NOT NULL,
    team_type VARCHAR(20) NOT NULL,

    CONSTRAINT chk_team_type
        CHECK (team_type IN ('FRANCHISE', 'INTERNATIONAL'))
);

-- 2. Players table
CREATE TABLE players (
    player_id INTEGER PRIMARY KEY,
    full_name VARCHAR(100) NOT NULL,
    team_id INTEGER NOT NULL,
    role VARCHAR(10) NOT NULL,
    credits NUMERIC(4,1) NOT NULL,
    is_active BOOLEAN NOT NULL,

    CONSTRAINT fk_players_team
        FOREIGN KEY (team_id)
        REFERENCES teams(team_id)
        ON DELETE RESTRICT,

    CONSTRAINT chk_player_role
        CHECK (role IN ('AR', 'BAT', 'BOWL', 'WK')),

    CONSTRAINT chk_player_credits
        CHECK (credits > 0)
);

-- 3. Matches table
CREATE TABLE matches (
    match_id INTEGER PRIMARY KEY,
    tournament VARCHAR(100) NOT NULL,
    home_team_id INTEGER NOT NULL,
    away_team_id INTEGER NOT NULL,
    venue VARCHAR(150) NOT NULL,
    starts_at TIMESTAMPTZ NOT NULL,
    status VARCHAR(20) NOT NULL,

    CONSTRAINT fk_matches_home_team
        FOREIGN KEY (home_team_id)
        REFERENCES teams(team_id)
        ON DELETE RESTRICT,

    CONSTRAINT fk_matches_away_team
        FOREIGN KEY (away_team_id)
        REFERENCES teams(team_id)
        ON DELETE RESTRICT,

    CONSTRAINT chk_match_teams
        CHECK (home_team_id <> away_team_id),

    CONSTRAINT chk_match_status
        CHECK (status IN ('UPCOMING', 'LIVE', 'COMPLETED', 'ABANDONED'))
);

-- 4. Player match statistics table
CREATE TABLE player_match_stats (
    match_id INTEGER NOT NULL,
    player_id INTEGER NOT NULL,
    runs INTEGER NOT NULL,
    balls_faced INTEGER NOT NULL,
    fours INTEGER NOT NULL,
    sixes INTEGER NOT NULL,
    wickets INTEGER NOT NULL,
    catches INTEGER NOT NULL,
    fantasy_points NUMERIC(7,1) NOT NULL,

    CONSTRAINT pk_player_match_stats
        PRIMARY KEY (match_id, player_id),

    CONSTRAINT fk_stats_match
        FOREIGN KEY (match_id)
        REFERENCES matches(match_id)
        ON DELETE CASCADE,

    CONSTRAINT fk_stats_player
        FOREIGN KEY (player_id)
        REFERENCES players(player_id)
        ON DELETE CASCADE,

    CONSTRAINT chk_stats_nonnegative
        CHECK (
            runs >= 0 AND
            balls_faced >= 0 AND
            fours >= 0 AND
            sixes >= 0 AND
            wickets >= 0 AND
            catches >= 0
        )
);

-- 5. Users table
CREATE TABLE users (
    user_id INTEGER PRIMARY KEY,
    username VARCHAR(100) NOT NULL UNIQUE,
    phone VARCHAR(20) NOT NULL UNIQUE,
    email VARCHAR(255) UNIQUE,
    state_code CHAR(2) NOT NULL,
    kyc_status VARCHAR(20) NOT NULL,
    created_at TIMESTAMPTZ NOT NULL,

    CONSTRAINT chk_user_state_code
        CHECK (state_code IN (
            'AP', 'AS', 'BR', 'DL', 'GJ', 'HR',
            'KA', 'KL', 'MH', 'MP', 'OD', 'PB',
            'RJ', 'TG', 'TN', 'UP', 'WB'
        )),

    CONSTRAINT chk_user_kyc_status
        CHECK (kyc_status IN ('PENDING', 'REJECTED', 'VERIFIED'))
);

-- 6. User teams table
CREATE TABLE user_teams (
    user_team_id INTEGER PRIMARY KEY,
    user_id INTEGER NOT NULL,
    match_id INTEGER NOT NULL,
    team_label VARCHAR(100) NOT NULL,
    captain_id INTEGER NOT NULL,
    vice_captain_id INTEGER NOT NULL,
    total_points NUMERIC(7,1),
    created_at TIMESTAMPTZ NOT NULL,

    CONSTRAINT fk_user_teams_user
        FOREIGN KEY (user_id)
        REFERENCES users(user_id)
        ON DELETE CASCADE,

    CONSTRAINT fk_user_teams_match
        FOREIGN KEY (match_id)
        REFERENCES matches(match_id)
        ON DELETE RESTRICT,

    CONSTRAINT fk_user_teams_captain
        FOREIGN KEY (captain_id)
        REFERENCES players(player_id)
        ON DELETE RESTRICT,

    CONSTRAINT fk_user_teams_vice_captain
        FOREIGN KEY (vice_captain_id)
        REFERENCES players(player_id)
        ON DELETE RESTRICT,

    CONSTRAINT chk_different_captains
        CHECK (captain_id <> vice_captain_id),

    CONSTRAINT chk_user_team_points
        CHECK (total_points IS NULL OR total_points >= 0)
);

-- 7. User team players table
CREATE TABLE user_team_players (
    user_team_id INTEGER NOT NULL,
    player_id INTEGER NOT NULL,

    CONSTRAINT pk_user_team_players
        PRIMARY KEY (user_team_id, player_id),

    CONSTRAINT fk_team_players_user_team
        FOREIGN KEY (user_team_id)
        REFERENCES user_teams(user_team_id)
        ON DELETE CASCADE,

    CONSTRAINT fk_team_players_player
        FOREIGN KEY (player_id)
        REFERENCES players(player_id)
        ON DELETE RESTRICT
);

-- 8. Contests table
CREATE TABLE contests (
    contest_id INTEGER PRIMARY KEY,
    match_id INTEGER NOT NULL,
    contest_name VARCHAR(150) NOT NULL,
    contest_type VARCHAR(30) NOT NULL,
    entry_fee NUMERIC(10,2) NOT NULL,
    total_spots INTEGER NOT NULL,
    prize_pool NUMERIC(12,2) NOT NULL,
    is_guaranteed BOOLEAN NOT NULL,
    invite_code VARCHAR(50) UNIQUE,

    CONSTRAINT fk_contests_match
        FOREIGN KEY (match_id)
        REFERENCES matches(match_id)
        ON DELETE RESTRICT,

    CONSTRAINT chk_contest_type
        CHECK (contest_type IN (
            'HEAD_TO_HEAD', 'MEGA', 'PRIVATE', 'SMALL'
        )),

    CONSTRAINT chk_contest_entry_fee
        CHECK (entry_fee >= 0),

    CONSTRAINT chk_contest_total_spots
        CHECK (total_spots > 0),

    CONSTRAINT chk_contest_prize_pool
        CHECK (prize_pool >= 0)
);


-- 9. Contest entries table
CREATE TABLE contest_entries (
    entry_id INTEGER PRIMARY KEY,
    contest_id INTEGER NOT NULL,
    user_team_id INTEGER NOT NULL,
    joined_at TIMESTAMPTZ NOT NULL,
    final_rank INTEGER,
    winnings NUMERIC(12,2) NOT NULL,

    CONSTRAINT fk_entries_contest
        FOREIGN KEY (contest_id)
        REFERENCES contests(contest_id)
        ON DELETE CASCADE,

    CONSTRAINT fk_entries_user_team
        FOREIGN KEY (user_team_id)
        REFERENCES user_teams(user_team_id)
        ON DELETE CASCADE,

    CONSTRAINT uq_contest_user_team
        UNIQUE (contest_id, user_team_id),

    CONSTRAINT chk_entry_final_rank
        CHECK (final_rank IS NULL OR final_rank > 0),

    CONSTRAINT chk_entry_winnings
        CHECK (winnings >= 0)
);

-- 10. Wallet transactions table
CREATE TABLE wallet_transactions (
    txn_id INTEGER PRIMARY KEY,
    user_id INTEGER NOT NULL,
    txn_type VARCHAR(20) NOT NULL,
    amount NUMERIC(12,2) NOT NULL,
    reference_entry_id INTEGER,
    status VARCHAR(20) NOT NULL,
    created_at TIMESTAMPTZ NOT NULL,

    CONSTRAINT fk_wallet_user
        FOREIGN KEY (user_id)
        REFERENCES users(user_id)
        ON DELETE RESTRICT,

    CONSTRAINT fk_wallet_entry
        FOREIGN KEY (reference_entry_id)
        REFERENCES contest_entries(entry_id)
        ON DELETE SET NULL,

    CONSTRAINT chk_wallet_txn_type
        CHECK (txn_type IN (
            'BONUS', 'DEPOSIT', 'ENTRY_FEE',
            'REFUND', 'WINNINGS', 'WITHDRAWAL'
        )),

    CONSTRAINT chk_wallet_status
        CHECK (status IN ('FAILED', 'PENDING', 'SUCCESS')),

    CONSTRAINT chk_wallet_amount
        CHECK (amount > 0)
);