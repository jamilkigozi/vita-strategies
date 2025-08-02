#!/bin/bash
set -e

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
    -- Create databases for all services
    CREATE DATABASE windmill;
    CREATE DATABASE keycloak;
    CREATE DATABASE metabase;
    CREATE DATABASE mattermost;
    CREATE DATABASE grafana;
    
    -- Grant permissions
    GRANT ALL PRIVILEGES ON DATABASE windmill TO postgres;
    GRANT ALL PRIVILEGES ON DATABASE keycloak TO postgres;
    GRANT ALL PRIVILEGES ON DATABASE metabase TO postgres;
    GRANT ALL PRIVILEGES ON DATABASE mattermost TO postgres;
    GRANT ALL PRIVILEGES ON DATABASE grafana TO postgres;
EOSQL
