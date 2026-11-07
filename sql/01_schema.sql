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