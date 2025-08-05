#!/bin/bash
set -e

# Create databases for all applications
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
    -- Create databases
    CREATE DATABASE mattermost;
    CREATE DATABASE metabase;
    CREATE DATABASE grafana;
    CREATE DATABASE keycloak;
    CREATE DATABASE appsmith;

    -- Create users and grant permissions
    CREATE USER mattermost WITH PASSWORD 'mattermost_secure_2024_london!';
    CREATE USER metabase WITH PASSWORD 'metabase_secure_2024_london!';
    CREATE USER grafana WITH PASSWORD 'grafana_secure_2024_london!';
    CREATE USER keycloak WITH PASSWORD 'keycloak_secure_2024_london!';
    CREATE USER appsmith WITH PASSWORD 'appsmith_secure_2024_london!';

    -- Grant permissions
    GRANT ALL PRIVILEGES ON DATABASE mattermost TO mattermost;
    GRANT ALL PRIVILEGES ON DATABASE metabase TO metabase;
    GRANT ALL PRIVILEGES ON DATABASE grafana TO grafana;
    GRANT ALL PRIVILEGES ON DATABASE keycloak TO keycloak;
    GRANT ALL PRIVILEGES ON DATABASE appsmith TO appsmith;
EOSQL

echo "PostgreSQL databases and users created successfully!"
