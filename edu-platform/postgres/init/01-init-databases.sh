#!/bin/bash
set -e

# Create users and databases for edu-platform services

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
    -- Moodle database and user
    CREATE USER moodle WITH PASSWORD '$POSTGRES_PASSWORD';
    CREATE DATABASE moodle_db OWNER moodle;
    GRANT ALL PRIVILEGES ON DATABASE moodle_db TO moodle;

    -- JupyterHub database and user
    CREATE USER jupyterhub WITH PASSWORD '$POSTGRES_PASSWORD';
    CREATE DATABASE jupyterhub_db OWNER jupyterhub;
    GRANT ALL PRIVILEGES ON DATABASE jupyterhub_db TO jupyterhub;
EOSQL

# Enable required extensions for Moodle
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "moodle_db" <<-EOSQL
    CREATE EXTENSION IF NOT EXISTS pg_trgm;
EOSQL

# Enable required extensions for JupyterHub
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "jupyterhub_db" <<-EOSQL
    CREATE EXTENSION IF NOT EXISTS pg_trgm;
EOSQL

echo "Databases initialized successfully!"
