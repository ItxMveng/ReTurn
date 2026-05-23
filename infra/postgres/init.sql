-- DocRetour — PostgreSQL initialization script
-- Executed once on first container start

CREATE EXTENSION IF NOT EXISTS postgis;
CREATE EXTENSION IF NOT EXISTS pgcrypto;
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

CREATE SCHEMA IF NOT EXISTS docretour;

-- Users table
CREATE TABLE IF NOT EXISTS docretour.users (
    id            UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    firebase_uid  VARCHAR(128) UNIQUE,
    phone_number  VARCHAR(100) UNIQUE NOT NULL,
    email         VARCHAR(254) UNIQUE,
    full_name     VARCHAR(100) NOT NULL DEFAULT '',
    date_of_birth DATE,
    national_id_number VARCHAR(50),
    gender        VARCHAR(20),
    city          VARCHAR(100),
    region        VARCHAR(100),
    address       VARCHAR(255),
    fcm_token     VARCHAR(512),
    is_active     BOOLEAN NOT NULL DEFAULT TRUE,
    is_verified   BOOLEAN NOT NULL DEFAULT FALSE,
    created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS ix_users_firebase_uid  ON docretour.users (firebase_uid);
CREATE INDEX IF NOT EXISTS ix_users_phone_number  ON docretour.users (phone_number);
CREATE INDEX IF NOT EXISTS ix_users_email         ON docretour.users (email);

DO $$
BEGIN
    RAISE NOTICE '✓ DocRetour schema initialized — PostGIS, pgcrypto, uuid-ossp ready.';
END
$$;
