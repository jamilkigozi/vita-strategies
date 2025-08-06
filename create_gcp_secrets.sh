#!/bin/bash
# VITA STRATEGIES - Google Secret Manager Setup Script
# Creates all required secrets in Google Secret Manager

set -e

# Check if project ID is provided
if [ -z "$1" ]; then
    echo "Usage: $0 <GCP_PROJECT_ID>"
    echo "Example: $0 vita-strategies-2024"
    exit 1
fi

PROJECT_ID=$1

# Enable Secret Manager API
echo "Enabling Secret Manager API..."
gcloud services enable secretmanager.googleapis.com --project=$PROJECT_ID

# Create secrets function
create_secret() {
    local secret_name=$1
    local secret_value=$2
    
    echo "Creating secret: $secret_name"
    
    # Check if secret already exists
    if gcloud secrets describe $secret_name --project=$PROJECT_ID &>/dev/null; then
        echo "Secret $secret_name already exists, skipping..."
        return
    fi
    
    # Create the secret
    echo -n "$secret_value" | gcloud secrets create $secret_name \
        --data-file=- \
        --project=$PROJECT_ID
    
    echo "Secret $secret_name created successfully"
}

# Create all secrets
echo "Creating secrets in project: $PROJECT_ID"

# PostgreSQL
create_secret "POSTGRES_USER" "postgres_admin"
create_secret "POSTGRES_PASSWORD" "K9m#2pL$8vX@4nQ7bR!1wE6tY"

# MySQL
create_secret "MYSQL_ROOT_PASSWORD" "M@x7rT#9pL$2kF8vN!4qW1eR6"

# WordPress
create_secret "WORDPRESS_DB_USER" "wp_user"
create_secret "WORDPRESS_DB_PASSWORD" "Wp#9dB$7mK@2xL4vQ!8nF1rT5"

# ERPNext
create_secret "ERPNEXT_DB_USER" "erpnext_user"
create_secret "ERPNEXT_DB_PASSWORD" "Er#5pN$9xT@2kL7vM!4qW8eR1"

# Mattermost
create_secret "MATTERMOST_DB_USER" "mm_user"
create_secret "MATTERMOST_DB_PASSWORD" "Mm#3tT$8kL@5xN9vQ!2wE7rY4"

# BookStack
create_secret "BOOKSTACK_DB_USER" "bookstack_user"
create_secret "BOOKSTACK_DB_PASSWORD" "Bs#7kS$2mL@9xN4vQ!5wE8rT1"

# Metabase
create_secret "METABASE_DB_USER" "metabase_user"
create_secret "METABASE_DB_PASSWORD" "Mb#4tB$7kL@2xN9vQ!8wE5rY3"

# Grafana
create_secret "GRAFANA_DB_USER" "grafana_user"
create_secret "GRAFANA_DB_PASSWORD" "Gf#9aR$3kL@7xN2vQ!4wE8tY5"

# Keycloak
create_secret "KEYCLOAK_DB_USERNAME" "keycloak_db_user"
create_secret "KEYCLOAK_DB_PASSWORD" "Kc#5dB$9mL@3xN7vQ!2wE8rT4"
create_secret "KEYCLOAK_ADMIN_USER" "admin"
create_secret "KEYCLOAK_ADMIN_PASSWORD" "Kc#8mA$2nL@9xQ7vB!3wE5rT1"

# Appsmith
create_secret "APPSMITH_ENCRYPTION_PASSWORD" "As#7pE$3kL@9xN2vQ!4wE8rT5"
create_secret "APPSMITH_ENCRYPTION_SALT" "As#4mL$8kT@7xN9vQ!2wE5rY3"
create_secret "APPSMITH_DB_USER" "appsmith_user"
create_secret "APPSMITH_DB_PASSWORD" "As#9mD$4kL@7xN2vQ!5wE8rT1"

# Redis
create_secret "REDIS_PASSWORD" "Rd#7sI$2kL@9xN4vQ!8wE5rT3"

# MongoDB
create_secret "MONGO_ROOT_USER" "mongo_admin"
create_secret "MONGO_ROOT_PASSWORD" "Mg#8oN$3kL@9xN7vQ!2wE5rT4"

# MinIO
create_secret "MINIO_ACCESS_KEY" "Mn#4iO$7kL@2xN9vQ!8wE5rT3"
create_secret "MINIO_SECRET_KEY" "Mn#9sE$3kL@7xN2vQ!4wE8rT5"

# Shared credentials
create_secret "DB_PASSWORD" "Db#7sH$2kL@9xN4vQ!8wE5rT3"
create_secret "ADMIN_PASSWORD" "Ad#5mI$8kL@3xN7vQ!2wE9rT4"

# Grafana Metrics
create_secret "GRAFANA_METRICS_USER" "grafana_metrics"
create_secret "GRAFANA_METRICS_PASSWORD" "Gm#7tR$2kL@9xN4vQ!8wE5rT3"

# Keycloak Truststore
create_secret "KEYCLOAK_TRUSTSTORE_PASSWORD" "Kt#9sT$3kL@7xN2vQ!4wE8rT5"

# OpenBao
create_secret "OPENBAO_DB_USERNAME" "openbao_user"
create_secret "OPENBAO_DB_PASSWORD" "Ob#5dB$9kL@3xN7vQ!2wE8rT4"
create_secret "OPENBAO_ADMIN_USER" "openbao_admin"
create_secret "OPENBAO_ADMIN_PASSWORD" "Ob#8mA$2nL@9xQ7vB!3wE5rT1"

# Windmill
create_secret "WINDMILL_DB_USERNAME" "windmill_user"
create_secret "WINDMILL_DB_PASSWORD" "Wm#7dB$2kL@9xN4vQ!8wE5rT3"

echo "All secrets created successfully!"
echo "You can now use fetch_secrets.py to retrieve these secrets"
