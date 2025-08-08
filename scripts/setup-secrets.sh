#!/bin/bash
# Check existing Google Secret Manager secrets
set -e

echo "🔍 Checking existing secrets..."

# Check if secret exists (case insensitive)
secret_exists() {
    gcloud secrets describe "$1" >/dev/null 2>&1 || \
    gcloud secrets describe "${1,,}" >/dev/null 2>&1 || \
    gcloud secrets describe "${1^^}" >/dev/null 2>&1
}

# Required secrets
REQUIRED_SECRETS=(
    "vita-db-password"
    "vita-redis-password"
    "SSH_PUBLIC_KEY"
    "ADMIN_IP"
    "wordpress-db-password"
    "erpnext-db-password"
    "mattermost-db-password"
    "metabase-db-password"
    "grafana-db-password"
    "keycloak-db-password"
    "windmill-db-password"
    "keycloak-admin-password"
    "grafana-admin-password"
    "appsmith-encryption-password"
    "appsmith-encryption-salt"
    "mongo-root-password"
)

# Check existing secrets
echo "📋 Existing secrets:"
for secret in "${REQUIRED_SECRETS[@]}"; do
    if secret_exists "$secret"; then
        echo "  ✅ $secret (found)"
    elif secret_exists "${secret,,}"; then
        echo "  ✅ $secret (found as ${secret,,})"
    elif secret_exists "${secret^^}"; then
        echo "  ✅ $secret (found as ${secret^^})"
    else
        echo "  ❌ $secret (missing)"
    fi
done

echo "✅ Secret check complete. Deployment will use existing secrets."