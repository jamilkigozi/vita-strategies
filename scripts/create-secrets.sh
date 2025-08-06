#!/bin/bash
# VITA STRATEGIES - Create Google Secret Manager Secrets
# One-time setup script for creating secrets in Google Secret Manager

set -e

echo "🔐 VITA STRATEGIES - Creating Google Secret Manager Secrets"
echo "========================================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Check if gcloud is installed and authenticated
if ! command -v gcloud &> /dev/null; then
    echo "Error: gcloud CLI is not installed"
    exit 1
fi

# Get project ID
PROJECT_ID=$(gcloud config get-value project)
if [ -z "$PROJECT_ID" ]; then
    echo "Error: Could not determine GCP project ID"
    echo "Please run: gcloud config set project [YOUR_PROJECT_ID]"
    exit 1
fi

echo "Using project: $PROJECT_ID"

# List of secrets to create
declare -A SECRETS=(
    ["POSTGRES_PASSWORD"]="Secure password for PostgreSQL database"
    ["MYSQL_PASSWORD"]="Secure password for MySQL database"
    ["KEYCLOAK_ADMIN_PASSWORD"]="Admin password for Keycloak"
    ["ERP_NEXT_PASSWORD"]="Password for ERPNext database"
    ["MATTERMOST_PASSWORD"]="Password for Mattermost database"
    ["WORDPRESS_PASSWORD"]="Password for WordPress database"
    ["APPSMITH_PASSWORD"]="Password for Appsmith database"
    ["GRAFANA_PASSWORD"]="Password for Grafana database"
    ["METABASE_PASSWORD"]="Password for Metabase database"
)

# Function to generate secure password
generate_password() {
    openssl rand -base64 32 | tr -d /=+ | cut -c -25
}

# Create secrets
for SECRET_NAME in "${!SECRETS[@]}"; do
    DESCRIPTION="${SECRETS[$SECRET_NAME]}"
    
    echo "Creating secret: $SECRET_NAME"
    
    # Check if secret already exists
    if gcloud secrets describe "$SECRET_NAME" --project="$PROJECT_ID" &>/dev/null; then
        echo -e "${YELLOW}⚠️  Secret $SECRET_NAME already exists${NC}"
        continue
    fi
    
    # Generate password
    PASSWORD=$(generate_password)
    
    # Create secret
    echo "$PASSWORD" | gcloud secrets create "$SECRET_NAME" \
        --data-file=- \
        --project="$PROJECT_ID" \
        --replication-policy="automatic" \
        --description="$DESCRIPTION"
    
    echo -e "${GREEN}✅ Created secret: $SECRET_NAME${NC}"
done

echo -e "${GREEN}🎉 All secrets created successfully!${NC}"
