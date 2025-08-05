#!/bin/bash
set -e

echo "🚀 Starting Vita Strategies Microservices Deployment"
echo "============================================="

# Navigate to the script's directory
cd "$(dirname "$0")"

# Check if .env file exists
if [ ! -f .env ]; then
    echo "❌ .env file not found. Please copy .env.template to .env and fill in your secrets."
    exit 1
fi

# Export environment variables
set -a
. ./.env
set +a

echo "✅ Environment variables loaded"

# Create Docker network if it doesn't exist
echo "🌐 Creating Docker network..."
docker network create vita-network --driver bridge 2>/dev/null || echo "Network already exists"

# Deploy all services
echo "🏗️  Deploying all services..."
docker-compose up -d

echo ""
echo "🎉 Deployment Complete!"
echo "===================="
echo ""
echo "🌐 Service URLs:"
echo "WordPress:   https://vitastrategies.com"
echo "ERPNext:     https://erp.vitastrategies.com"
echo "Mattermost:  https://chat.vitastrategies.com"
echo "Windmill:    https://workflows.vitastrategies.com"
echo "BookStack:   https://docs.vitastrategies.com"
echo "Grafana:     https://monitoring.vitastrategies.com"
echo "Metabase:    https://analytics.vitastrategies.com"
echo "Keycloak:    https://auth.vitastrategies.com"
echo "OpenBao:     https://vault.vitastrategies.com"
echo "Appsmith:    https://apps.vitastrategies.com"
echo ""
echo "🔑 Admin Credentials:"
echo "Check your .env file for passwords."

echo ""
echo "🏥 Health Check:"
docker-compose ps