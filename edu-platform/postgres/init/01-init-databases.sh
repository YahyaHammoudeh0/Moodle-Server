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

    -- Grafana database and user (optional service)
    CREATE USER grafana WITH PASSWORD '$POSTGRES_PASSWORD';
    CREATE DATABASE grafana OWNER grafana;
    GRANT ALL PRIVILEGES ON DATABASE grafana TO grafana;

    -- Gitea database and user (optional service)
    CREATE USER gitea WITH PASSWORD '$POSTGRES_PASSWORD';
    CREATE DATABASE gitea OWNER gitea;
    GRANT ALL PRIVILEGES ON DATABASE gitea TO gitea;

    -- n8n database and user (optional service)
    CREATE USER n8n WITH PASSWORD '$POSTGRES_PASSWORD';
    CREATE DATABASE n8n OWNER n8n;
    GRANT ALL PRIVILEGES ON DATABASE n8n TO n8n;
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
