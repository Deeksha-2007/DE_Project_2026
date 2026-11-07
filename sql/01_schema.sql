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