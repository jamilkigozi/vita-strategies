#!/bin/bash
set -e

# VITA STRATEGIES COMPLETE DEPLOYMENT SCRIPT
# This script handles the complete deployment of all applications

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

error() {
    echo -e "${RED}[ERROR] $1${NC}"
}

warning() {
    echo -e "${YELLOW}[WARNING] $1${NC}"
}

# Check if running as root
if [[ $EUID -eq 0 ]]; then
   error "This script should not be run as root"
   exit 1
fi

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    error "Docker is not installed. Please install Docker first."
    exit 1
fi

# Check if Docker Compose is installed
if ! command -v docker-compose &> /dev/null; then
    error "Docker Compose is not installed. Please install Docker Compose first."
    exit 1
fi

# Create necessary directories
log "Creating necessary directories..."
sudo mkdir -p /mnt/buckets/{wordpress,erpnext,mattermost,analytics,monitoring,auth,appsmith,vault}

# Set proper permissions
log "Setting directory permissions..."
sudo chown -R $USER:$USER /mnt/buckets/

# Create environment file from example
if [ ! -f .env ]; then
    log "Creating .env file from example..."
    cp .env.example .env
    warning "Please review and update the .env file with your actual values"
fi

# Create database initialization scripts
log "Setting up database initialization..."
chmod +x postgres/init/01-init-databases.sh

# Pull latest images
log "Pulling latest Docker images..."
docker-compose pull

# Start database services first
log "Starting database services..."
docker-compose up -d postgres mariadb

# Wait for databases to be ready
log "Waiting for databases to be ready..."
sleep 30

# Check database health
log "Checking database health..."
docker-compose exec postgres pg_isready -U postgres
docker-compose exec mariadb mysqladmin ping -h localhost -u root -p$MARIADB_ROOT_PASSWORD

# Start all services
log "Starting all services..."
docker-compose up -d

# Wait for services to start
log "Waiting for services to start..."
sleep 60

# Check service health
log "Checking service health..."
docker-compose ps

# Display service URLs
log "Deployment complete! Services are available at:"
echo "  - WordPress: https://wordpress.vitastrategies.com"
echo "  - ERPNext: https://erp.vitastrategies.com"
echo "  - Mattermost: https://chat.vitastrategies.com"
echo "  - Metabase: https://analytics.vitastrategies.com"
echo "  - Grafana: https://monitoring.vitastrategies.com"
echo "  - Keycloak: https://auth.vitastrategies.com"
echo "  - Appsmith: https://apps.vitastrategies.com"
echo "  - OpenBao: https://vault.vitastrategies.com"

# Display logs command
log "To view logs, run: docker-compose logs -f [service-name]"
