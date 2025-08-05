#!/bin/bash
# VITA STRATEGIES - SAFE CONTAINER DEPLOYMENT SCRIPT
# Purpose: Deploy containers while preserving existing data

set -e

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
    exit 1
}

warning() {
    echo -e "${YELLOW}[WARNING] $1${NC}"
}

log "🐳 VITA STRATEGIES - SAFE CONTAINER DEPLOYMENT"
log "=============================================="

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    error "Docker is not installed. Please install Docker first."
fi

# Check if Docker Compose is installed
if ! command -v docker-compose &> /dev/null; then
    error "Docker Compose is not installed. Please install Docker Compose first."
fi

# Check if running as root
if [[ $EUID -eq 0 ]]; then
   error "This script should not be run as root"
fi

# Step 1: Check for existing containers
log "Checking for existing containers..."
EXISTING_CONTAINERS=$(docker ps -a --format "{{.Names}}" | grep -E 'postgres|mariadb|wordpress|erpnext|mattermost|metabase|grafana|keycloak|appsmith|openbao' | wc -l)

if [ "$EXISTING_CONTAINERS" -gt 0 ]; then
    warning "Found $EXISTING_CONTAINERS existing containers. Will preserve data."
    PRESERVE_DATA=true
else
    log "No existing containers found. Will perform fresh deployment."
    PRESERVE_DATA=false
fi

# Step 2: Backup existing volumes if they exist
if [ "$PRESERVE_DATA" = true ]; then
    log "Backing up existing volumes..."
    
    # Create backup directory
    BACKUP_DIR="./backups/$(date +%Y%m%d%H%M%S)"
    mkdir -p "$BACKUP_DIR"
    
    # Backup database data
    if docker volume inspect postgres_data &>/dev/null; then
        log "Backing up PostgreSQL data..."
        docker run --rm -v postgres_data:/source -v $(pwd)/$BACKUP_DIR:/backup alpine tar -czf /backup/postgres_data.tar.gz -C /source .
    fi
    
    if docker volume inspect mariadb_data &>/dev/null; then
        log "Backing up MariaDB data..."
        docker run --rm -v mariadb_data:/source -v $(pwd)/$BACKUP_DIR:/backup alpine tar -czf /backup/mariadb_data.tar.gz -C /source .
    fi
    
    log "Volumes backed up to $BACKUP_DIR"
fi

# Step 3: Create necessary directories
log "Creating necessary directories..."
sudo mkdir -p /mnt/buckets/{wordpress,erpnext,mattermost,analytics,monitoring,auth,appsmith,vault}

# Set proper permissions
log "Setting directory permissions..."
sudo chown -R $USER:$USER /mnt/buckets/

# Step 4: Create environment file if it doesn't exist
if [ ! -f .env ]; then
    log "Creating .env file from example..."
    cp .env.example .env
    warning "Please review and update the .env file with your actual values"
fi

# Step 5: Create database initialization scripts
log "Setting up database initialization..."
chmod +x postgres/init/01-init-databases.sh

# Step 6: Pull latest images
log "Pulling latest Docker images..."
docker-compose pull

# Step 7: Start database services first
if [ "$PRESERVE_DATA" = true ]; then
    log "Carefully updating database services..."
    # For existing deployments, update one by one
    for db_service in postgres mariadb; do
        if docker ps -q --filter "name=$db_service" | grep -q .; then
            log "Updating $db_service..."
            docker-compose up -d --no-deps $db_service
        else
            log "Starting $db_service..."
            docker-compose up -d $db_service
        fi
    done
else
    log "Starting database services..."
    docker-compose up -d postgres mariadb
fi

# Step 8: Wait for databases to be ready
log "Waiting for databases to be ready..."
sleep 30

# Step 9: Check database health
log "Checking database health..."
if ! docker-compose exec -T postgres pg_isready -U postgres; then
    error "PostgreSQL is not ready. Please check the logs."
fi

if ! docker-compose exec -T mariadb mysqladmin ping -h localhost -u root -p$MARIADB_ROOT_PASSWORD; then
    error "MariaDB is not ready. Please check the logs."
fi

# Step 10: Start or update remaining services
if [ "$PRESERVE_DATA" = true ]; then
    log "Carefully updating remaining services..."
    # Get list of services
    SERVICES=$(docker-compose config --services | grep -v "postgres\|mariadb")
    
    # Update each service one by one
    for service in $SERVICES; do
        log "Updating $service..."
        docker-compose up -d --no-deps $service
        sleep 5
    done
else
    log "Starting all services..."
    docker-compose up -d
fi

# Step 11: Wait for services to start
log "Waiting for services to start..."
sleep 60

# Step 12: Check service health
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