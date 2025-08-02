#!/bin/bash

# Deployment script for Vita Strategies Platform
# This script deploys the complete platform to GCP

set -e

echo "🚀 Deploying Vita Strategies Platform to GCP..."

# Configuration
VM_NAME="vita-strategies-server"
ZONE="europe-west2-a"
PROJECT="vita-strategies"

# Files to upload
FILES_TO_UPLOAD=(
    "docker-compose.yml"
    ".env.production"
    "nginx/nginx.conf"
    "nginx/ssl/"
    "postgres/init/"
)

echo "📦 Uploading configuration files to server..."

# Create remote directories
gcloud compute ssh $VM_NAME --zone=$ZONE --project=$PROJECT --command="mkdir -p ~/nginx/ssl ~/postgres/init"

# Upload docker-compose file
gcloud compute scp docker-compose.yml $VM_NAME:~/docker-compose.yml --zone=$ZONE --project=$PROJECT

# Upload environment file
gcloud compute scp .env.production $VM_NAME:~/.env --zone=$ZONE --project=$PROJECT

# Upload nginx configuration
gcloud compute scp nginx/nginx.conf $VM_NAME:~/nginx/nginx.conf --zone=$ZONE --project=$PROJECT

# Upload postgres init script
gcloud compute scp postgres/init/01-init-databases.sh $VM_NAME:~/postgres/init/01-init-databases.sh --zone=$ZONE --project=$PROJECT

# Make postgres script executable
gcloud compute ssh $VM_NAME --zone=$ZONE --project=$PROJECT --command="chmod +x ~/postgres/init/01-init-databases.sh"

echo "🔧 Installing Docker and Docker Compose on server..."

# Install Docker and Docker Compose
gcloud compute ssh $VM_NAME --zone=$ZONE --project=$PROJECT --command="
    # Update system
    sudo apt-get update
    
    # Install Docker
    if ! command -v docker &> /dev/null; then
        curl -fsSL https://get.docker.com -o get-docker.sh
        sudo sh get-docker.sh
        sudo usermod -aG docker \$USER
        rm get-docker.sh
    fi
    
    # Install Docker Compose
    if ! command -v docker-compose &> /dev/null; then
        sudo curl -L \"https://github.com/docker/compose/releases/latest/download/docker-compose-\$(uname -s)-\$(uname -m)\" -o /usr/local/bin/docker-compose
        sudo chmod +x /usr/local/bin/docker-compose
    fi
    
    # Start Docker service
    sudo systemctl enable docker
    sudo systemctl start docker
    
    echo '✅ Docker and Docker Compose installed'
"

echo "🔒 Setting up SSL certificates..."

# Run SSL setup script on server
./setup-cloudflare-ssl.sh

# Upload SSL certificates to server
if [[ -f "nginx/ssl/vitastrategies.com.crt" ]]; then
    gcloud compute scp nginx/ssl/vitastrategies.com.crt $VM_NAME:~/nginx/ssl/vitastrategies.com.crt --zone=$ZONE --project=$PROJECT
    gcloud compute scp nginx/ssl/vitastrategies.com.key $VM_NAME:~/nginx/ssl/vitastrategies.com.key --zone=$ZONE --project=$PROJECT
    echo "✅ SSL certificates uploaded"
fi

echo "🐳 Starting services on server..."

# Start all services
gcloud compute ssh $VM_NAME --zone=$ZONE --project=$PROJECT --command="
    # Pull latest images
    docker-compose pull
    
    # Start services in detached mode
    docker-compose up -d
    
    # Wait for services to be ready
    echo 'Waiting for services to start...'
    sleep 30
    
    # Show service status
    docker-compose ps
    
    echo '✅ All services started!'
"

echo "🎉 Deployment completed!"
echo ""
echo "🌐 Your services are now available at:"
echo "  - https://vitastrategies.com (main site - redirects to ERP)"
echo "  - https://erp.vitastrategies.com (ERPNext)"
echo "  - https://windmill.vitastrategies.com (Windmill Automation)"
echo "  - https://auth.vitastrategies.com (Keycloak Authentication)"
echo "  - https://analytics.vitastrategies.com (Metabase Analytics)"
echo "  - https://apps.vitastrategies.com (Appsmith Low-code)"
echo "  - https://chat.vitastrategies.com (Mattermost Chat)"
echo "  - https://monitoring.vitastrategies.com (Grafana Monitoring)"
echo "  - https://vault.vitastrategies.com (HashiCorp Vault)"
echo ""
echo "🔑 Default admin credentials are in .env.production file"
echo "⚠️  Remember to:"
echo "  1. Configure Cloudflare SSL settings"
echo "  2. Update admin passwords after first login"
echo "  3. Configure each service according to your needs"
echo ""
echo "📊 To check service status:"
echo "  gcloud compute ssh $VM_NAME --zone=$ZONE --command='docker-compose ps'"
echo ""
echo "📝 To view service logs:"
echo "  gcloud compute ssh $VM_NAME --zone=$ZONE --command='docker-compose logs [service-name]'"
