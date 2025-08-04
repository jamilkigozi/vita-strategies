#!/bin/bash
set -e

echo "🚀 Starting Vita Strategies Microservices Deployment"
echo "============================================="

# Navigate to the docker directory
cd /opt/vita/docker

# Generate secure environment file
echo "📝 Generating secure environment variables..."
cat > .env << EOF
# Generated on $(date)
# Database Passwords - Secure random passwords
WORDPRESS_DB_PASSWORD=wp_$(openssl rand -hex 24)
ERPNEXT_DB_PASSWORD=erp_$(openssl rand -hex 24)
MATTERMOST_DB_PASSWORD=mm_$(openssl rand -hex 24)
WINDMILL_DB_PASSWORD=wm_$(openssl rand -hex 24)
BOOKSTACK_DB_PASSWORD=bs_$(openssl rand -hex 24)
GRAFANA_DB_PASSWORD=gf_$(openssl rand -hex 24)
METABASE_DB_PASSWORD=mb_$(openssl rand -hex 24)
KEYCLOAK_DB_PASSWORD=kc_$(openssl rand -hex 24)

# Admin Passwords
KEYCLOAK_ADMIN_PASSWORD=admin_$(openssl rand -hex 24)

# Application Settings
ENVIRONMENT=production
DOMAIN=vitastrategies.com
EOF

# Secure the environment file
chmod 600 .env

echo "✅ Environment file created with secure passwords"

# Create Docker network if it doesn't exist
echo "🌐 Creating Docker network..."
docker network create vita-network 2>/dev/null || echo "Network already exists"

# Deploy core services first (WordPress, ERPNext)
echo "🏗️  Deploying core services..."
docker-compose up -d wordpress erpnext

echo "⏳ Waiting for core services to initialize..."
sleep 30

# Deploy communication services
echo "💬 Deploying communication services..."
docker-compose up -d mattermost

echo "⏳ Waiting for communication services..."
sleep 20

# Deploy documentation and workflows
echo "📚 Deploying documentation and workflow services..."
docker-compose up -d bookstack windmill

echo "⏳ Waiting for documentation services..."
sleep 20

# Deploy monitoring and analytics
echo "📊 Deploying monitoring and analytics..."
docker-compose up -d grafana metabase

echo "⏳ Waiting for monitoring services..."
sleep 20

# Deploy authentication and security
echo "🔐 Deploying authentication and security services..."
docker-compose up -d keycloak openbao

echo "⏳ Waiting for security services..."
sleep 20

# Deploy low-code platform
echo "🎨 Deploying low-code platform..."
docker-compose up -d appsmith

echo "⏳ Final service initialization..."
sleep 30

echo ""
echo "🎉 Deployment Complete!"
echo "===================="
echo ""
echo "🌐 Service URLs:"
echo "WordPress:   http://34.142.16.226 (https://vitastrategies.com)"
echo "ERPNext:     http://34.142.16.226:8000 (https://erp.vitastrategies.com)"
echo "Mattermost:  http://34.142.16.226:8065 (https://chat.vitastrategies.com)"
echo "Windmill:    http://34.142.16.226:8080 (https://workflows.vitastrategies.com)"
echo "BookStack:   http://34.142.16.226:8081 (https://docs.vitastrategies.com)"
echo "Grafana:     http://34.142.16.226:3000 (https://monitoring.vitastrategies.com)"
echo "Metabase:    http://34.142.16.226:3001 (https://analytics.vitastrategies.com)"
echo "Keycloak:    http://34.142.16.226:8082 (https://auth.vitastrategies.com)"
echo "OpenBao:     http://34.142.16.226:8200 (https://vault.vitastrategies.com)"
echo "Appsmith:    http://34.142.16.226:8083 (https://apps.vitastrategies.com)"
echo ""
echo "🔑 Admin Credentials:"
echo "Check /opt/vita/docker/.env for database passwords"
echo "Keycloak admin password is in the .env file"
echo ""
echo "📝 Next Steps:"
echo "1. Configure DNS to point domains to 34.142.16.226"
echo "2. Set up SSL certificates (Let's Encrypt recommended)"
echo "3. Configure reverse proxy (nginx/traefik)"
echo "4. Update database user passwords in Cloud SQL"
echo ""
echo "🏥 Health Check:"
docker-compose ps
