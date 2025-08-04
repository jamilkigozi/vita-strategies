#!/bin/bash
set -e

echo "🔐 Generating secure database passwords..."

# Generate secure passwords
WORDPRESS_DB_PASSWORD=$(openssl rand -base64 32)
BOOKSTACK_DB_PASSWORD=$(openssl rand -base64 32)
ERPNEXT_DB_PASSWORD=$(openssl rand -base64 32)
MATTERMOST_DB_PASSWORD=$(openssl rand -base64 32)
WINDMILL_DB_PASSWORD=$(openssl rand -base64 32)
METABASE_DB_PASSWORD=$(openssl rand -base64 32)
GRAFANA_DB_PASSWORD=$(openssl rand -base64 32)
OPENBAO_DB_PASSWORD=$(openssl rand -base64 32)
KEYCLOAK_DB_PASSWORD=$(openssl rand -base64 32)
KEYCLOAK_ADMIN_PASSWORD=$(openssl rand -base64 32)

# Create environment file for Docker deployment
cat > /Users/millz./vita-strategies/docker/.env << EOF
# Generated on $(date)
# Secure Database Passwords
WORDPRESS_DB_PASSWORD=${WORDPRESS_DB_PASSWORD}
BOOKSTACK_DB_PASSWORD=${BOOKSTACK_DB_PASSWORD}
ERPNEXT_DB_PASSWORD=${ERPNEXT_DB_PASSWORD}
MATTERMOST_DB_PASSWORD=${MATTERMOST_DB_PASSWORD}
WINDMILL_DB_PASSWORD=${WINDMILL_DB_PASSWORD}
METABASE_DB_PASSWORD=${METABASE_DB_PASSWORD}
GRAFANA_DB_PASSWORD=${GRAFANA_DB_PASSWORD}
OPENBAO_DB_PASSWORD=${OPENBAO_DB_PASSWORD}
KEYCLOAK_DB_PASSWORD=${KEYCLOAK_DB_PASSWORD}

# Admin Passwords
KEYCLOAK_ADMIN_PASSWORD=${KEYCLOAK_ADMIN_PASSWORD}

# Application Settings
ENVIRONMENT=production
DOMAIN=vitastrategies.com
EXTERNAL_IP=34.142.16.226
EOF

# Secure the environment file
chmod 600 /Users/millz./vita-strategies/docker/.env

echo "✅ Secure passwords generated and saved to docker/.env"

# Output Cloud SQL commands for setting passwords
echo ""
echo "🗄️  Database User Password Update Commands:"
echo "============================================="
echo ""
echo "# MySQL/MariaDB Users:"
echo "gcloud sql users set-password wordpress --host=% --instance=vita-strategies-mysql-primary --password='${WORDPRESS_DB_PASSWORD}'"
echo "gcloud sql users set-password bookstack --host=% --instance=vita-strategies-mysql-primary --password='${BOOKSTACK_DB_PASSWORD}'"
echo "gcloud sql users set-password erpnext --host=% --instance=vita-strategies-mariadb-erp --password='${ERPNEXT_DB_PASSWORD}'"
echo ""
echo "# PostgreSQL Users:"
echo "gcloud sql users set-password mattermost --instance=vita-strategies-postgresql-primary --password='${MATTERMOST_DB_PASSWORD}'"
echo "gcloud sql users set-password windmill --instance=vita-strategies-postgresql-primary --password='${WINDMILL_DB_PASSWORD}'"
echo "gcloud sql users set-password metabase --instance=vita-strategies-postgresql-primary --password='${METABASE_DB_PASSWORD}'"
echo "gcloud sql users set-password grafana --instance=vita-strategies-postgresql-primary --password='${GRAFANA_DB_PASSWORD}'"
echo "gcloud sql users set-password openbao --instance=vita-strategies-postgresql-primary --password='${OPENBAO_DB_PASSWORD}'"
echo "gcloud sql users set-password keycloak --instance=vita-strategies-postgresql-primary --password='${KEYCLOAK_DB_PASSWORD}'"
echo ""
echo "Save these commands and run them to update database passwords!"
