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