#!/bin/bash
# VITA STRATEGIES - Fetch Secrets from GCP Secret Manager
set -e

# --- Configuration ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
ENV_FILE="$PROJECT_ROOT/.env"
PROJECT_ID=${1:-$(gcloud config get-value project)}

# --- Colors ---
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

# --- Helper Functions ---
log() { echo -e "${GREEN}[INFO] $1${NC}"; }
error() { echo -e "${RED}[ERROR] $1${NC}"; exit 1; }

# --- Main Logic ---
if [ -z "$PROJECT_ID" ]; then
    error "GCP Project ID is not set. Please provide it as an argument or set it via 'gcloud config set project [PROJECT_ID]'."
fi

log "Fetching secrets for project: $PROJECT_ID"
# Clear the .env file if it exists
> "$ENV_FILE"

# List of secrets to fetch. The format is "SECRET_NAME_IN_GCP:VARIABLE_NAME_IN_DOTENV"
declare -a secrets=(
    "postgres-password:POSTGRES_PASSWORD"
    "mariadb-root-password:MYSQL_ROOT_PASSWORD"
    "wordpress-db-password:WORDPRESS_DB_PASSWORD"
    "erpnext-db-password:ERPNEXT_DB_PASSWORD"
    "mattermost-db-password:MATTERMOST_DB_PASSWORD"
    "metabase-db-password:METABASE_DB_PASSWORD"
    "grafana-db-password:GRAFANA_DB_PASSWORD"
    "keycloak-db-password:KEYCLOAK_DB_PASSWORD"
    "appsmith-db-password:APPSMITH_DB_PASSWORD"
    "appsmith-encryption-password:APPSMITH_ENCRYPTION_PASSWORD"
    "appsmith-encryption-salt:APPSMITH_ENCRYPTION_SALT"
    "keycloak-admin-user:KEYCLOAK_ADMIN_USER"
    "keycloak-admin-password:KEYCLOAK_ADMIN_PASSWORD"
    "redis-password:REDIS_PASSWORD"
    "windmill-db-password:WINDMILL_DB_PASSWORD"
)

for secret_map in "${secrets[@]}"; do
    secret_name="${secret_map%%:*}"
    env_var_name="${secret_map##*:}"
    
    log "Fetching secret: $secret_name..."
    secret_value=$(gcloud secrets versions access latest --secret="$secret_name" --project="$PROJECT_ID")
    
    if [ -n "$secret_value" ]; then
        echo "$env_var_name=\"$secret_value\"" >> "$ENV_FILE"
        log "  - ✅ Stored as $env_var_name"
    else
        error "Failed to fetch secret: $secret_name. Please ensure it exists and you have permissions."
    fi
done

log "🎉 Successfully created .env file at $ENV_FILE"
