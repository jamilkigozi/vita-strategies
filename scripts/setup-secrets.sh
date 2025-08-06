#!/bin/bash
# VITA STRATEGIES - Setup Google Secret Manager Secrets
set -e

PROJECT_ID=${1:-$(gcloud config get-value project)}
if [ -z "$PROJECT_ID" ]; then
    echo "Error: Please provide project ID or set default project"
    exit 1
fi

echo "🔐 Setting up secrets for project: $PROJECT_ID"

# Enable Secret Manager API
gcloud services enable secretmanager.googleapis.com --project=$PROJECT_ID

# Generate secure passwords
generate_password() {
    openssl rand -base64 32 | tr -d /=+ | cut -c -25
}

# Create secrets with generated passwords
secrets=(
    "postgres-password"
    "mariadb-root-password"
    "wordpress-db-password"
    "erpnext-db-password"
    "mattermost-db-password"
    "metabase-db-password"
    "grafana-db-password"
    "keycloak-db-password"
    "appsmith-db-password"
    "appsmith-encryption-password"
    "appsmith-encryption-salt"
    "keycloak-admin-password"
    "openbao-root-token"
    "grafana-admin-password"
    "metabase-admin-password"
    "redis-password"
)

for secret in "${secrets[@]}"; do
    if gcloud secrets describe "$secret" --project="$PROJECT_ID" &>/dev/null; then
        echo "⚠️  Secret $secret already exists"
    else
        password=$(generate_password)
        echo "$password" | gcloud secrets create "$secret" \
            --data-file=- \
            --project="$PROJECT_ID" \
            --replication-policy="automatic"
        echo "✅ Created secret: $secret"
    fi
done

echo "🎉 All secrets created successfully!"
echo "Run: source .env.secure to use secure environment"