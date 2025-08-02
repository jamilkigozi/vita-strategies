#!/bin/bash

# =============================================================================
# VITA STRATEGIES - PLATFORM DEPLOYMENT SCRIPT
# =============================================================================
# Deploys the complete 8-service platform to GCP or local environment
# Supports both development and production deployments
# =============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
ENVIRONMENT="${1:-development}"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() {
    echo -e "${BLUE}[$(date +'%H:%M:%S')] $1${NC}"
}

success() {
    echo -e "${GREEN}✅ $1${NC}"
}

error() {
    echo -e "${RED}❌ $1${NC}"
}

warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

echo -e "${BLUE}"
echo "🚀 VITA STRATEGIES - PLATFORM DEPLOYMENT"
echo "Environment: $ENVIRONMENT"
echo "Project Root: $PROJECT_ROOT"
echo "============================================="
echo -e "${NC}"

# =============================================================================
# ENVIRONMENT CONFIGURATION
# =============================================================================

if [[ "$ENVIRONMENT" == "production" ]]; then
    VM_NAME="vita-strategies-server"
    ZONE="europe-west2-a"
    PROJECT="vita-strategies"
    COMPOSE_FILE="applications/docker-compose-complete.yml"
    
    log "Production deployment to GCP VM: $VM_NAME"
    
    # Check if gcloud is available
    if ! command -v gcloud &> /dev/null; then
        error "Google Cloud SDK not found. Please install and authenticate first."
        exit 1
    fi
    
elif [[ "$ENVIRONMENT" == "development" ]]; then
    COMPOSE_FILE="applications/docker-compose-complete.yml"
    
    log "Local development deployment"
    
    # Check if Docker is available
    if ! command -v docker &> /dev/null; then
        error "Docker not found. Please install Docker first."
        exit 1
    fi
    
    if ! command -v docker-compose &> /dev/null; then
        error "Docker Compose not found. Please install Docker Compose first."
        exit 1
    fi
    
else
    error "Unknown environment: $ENVIRONMENT. Use 'development' or 'production'"
    exit 1
fi

# =============================================================================
# DEVELOPMENT DEPLOYMENT
# =============================================================================

if [[ "$ENVIRONMENT" == "development" ]]; then
    log "Starting local development environment..."
    
    cd "$PROJECT_ROOT"
    
    # Stop any running services
    log "Stopping any existing services..."
    docker-compose -f "$COMPOSE_FILE" down --remove-orphans 2>/dev/null || true
    
    # Pull latest images
    log "Pulling latest Docker images..."
    docker-compose -f "$COMPOSE_FILE" pull
    
    # Start services
    log "Starting all services..."
    docker-compose -f "$COMPOSE_FILE" up -d
    
    # Wait for services to be ready
    log "Waiting for services to initialize..."
    sleep 30
    
    # Check service status
    log "Checking service status..."
    docker-compose -f "$COMPOSE_FILE" ps
    
    success "Development environment deployed successfully!"
    echo ""
    echo "🌐 Your services are available at:"
    echo "  - ERPNext: http://localhost:8000"
    echo "  - Keycloak: http://localhost:8180"
    echo "  - Windmill: http://localhost:8080"
    echo "  - Mattermost: http://localhost:8065"
    echo "  - Metabase: http://localhost:3000"
    echo "  - Grafana: http://localhost:3001"
    echo "  - Appsmith: http://localhost:8081"
    echo "  - Openbao: http://localhost:8200"
    echo ""
    echo "📋 Default credentials are in CREDENTIALS.md"
    echo ""
    echo "🔧 Useful commands:"
    echo "  - View logs: docker-compose -f $COMPOSE_FILE logs [service-name]"
    echo "  - Stop all: docker-compose -f $COMPOSE_FILE down"
    echo "  - Restart service: docker-compose -f $COMPOSE_FILE restart [service-name]"
    
    exit 0
fi

# =============================================================================
# PRODUCTION DEPLOYMENT
# =============================================================================

if [[ "$ENVIRONMENT" == "production" ]]; then
    log "Deploying to production GCP environment..."
    
    # Files to upload
    FILES_TO_UPLOAD=(
        "$COMPOSE_FILE"
        ".env.production"
        "nginx/nginx.conf"
        "applications/nginx-complete.conf"
        "postgres/init/01-init-databases.sh"
    )
    
    log "Creating remote directories..."
    gcloud compute ssh "$VM_NAME" --zone="$ZONE" --project="$PROJECT" --command="mkdir -p ~/nginx/ssl ~/postgres/init ~/applications" || {
        error "Failed to create remote directories. Check VM is running and accessible."
        exit 1
    }
    
    log "Uploading configuration files..."
    
    # Upload main docker-compose file
    gcloud compute scp "$PROJECT_ROOT/$COMPOSE_FILE" "$VM_NAME:~/docker-compose.yml" --zone="$ZONE" --project="$PROJECT"
    
    # Upload environment file if it exists
    if [[ -f "$PROJECT_ROOT/.env.production" ]]; then
        gcloud compute scp "$PROJECT_ROOT/.env.production" "$VM_NAME:~/.env" --zone="$ZONE" --project="$PROJECT"
    fi
    
    # Upload nginx configuration if it exists
    if [[ -f "$PROJECT_ROOT/nginx/nginx.conf" ]]; then
        gcloud compute scp "$PROJECT_ROOT/nginx/nginx.conf" "$VM_NAME:~/nginx/nginx.conf" --zone="$ZONE" --project="$PROJECT"
    fi
    
    # Upload postgres init script if it exists
    if [[ -f "$PROJECT_ROOT/postgres/init/01-init-databases.sh" ]]; then
        gcloud compute scp "$PROJECT_ROOT/postgres/init/01-init-databases.sh" "$VM_NAME:~/postgres/init/01-init-databases.sh" --zone="$ZONE" --project="$PROJECT"
        gcloud compute ssh "$VM_NAME" --zone="$ZONE" --project="$PROJECT" --command="chmod +x ~/postgres/init/01-init-databases.sh"
    fi
    
    log "Installing Docker and Docker Compose on server..."
    gcloud compute ssh "$VM_NAME" --zone="$ZONE" --project="$PROJECT" --command="
        # Update system
        sudo apt-get update -qq
        
        # Install Docker if not present
        if ! command -v docker &> /dev/null; then
            curl -fsSL https://get.docker.com -o get-docker.sh
            sudo sh get-docker.sh
            sudo usermod -aG docker \$USER
            rm get-docker.sh
        fi
        
        # Install Docker Compose if not present
        if ! command -v docker-compose &> /dev/null; then
            sudo curl -L \"https://github.com/docker/compose/releases/latest/download/docker-compose-\$(uname -s)-\$(uname -m)\" -o /usr/local/bin/docker-compose
            sudo chmod +x /usr/local/bin/docker-compose
        fi
        
        # Start Docker service
        sudo systemctl enable docker
        sudo systemctl start docker
        
        echo '✅ Docker and Docker Compose ready'
    "
    
    log "Setting up SSL certificates..."
    if [[ -f "$PROJECT_ROOT/setup-cloudflare-ssl.sh" ]]; then
        "$PROJECT_ROOT/setup-cloudflare-ssl.sh"
        
        # Upload SSL certificates if they exist
        if [[ -f "$PROJECT_ROOT/nginx/ssl/vitastrategies.com.crt" ]]; then
            gcloud compute scp "$PROJECT_ROOT/nginx/ssl/vitastrategies.com.crt" "$VM_NAME:~/nginx/ssl/vitastrategies.com.crt" --zone="$ZONE" --project="$PROJECT"
            gcloud compute scp "$PROJECT_ROOT/nginx/ssl/vitastrategies.com.key" "$VM_NAME:~/nginx/ssl/vitastrategies.com.key" --zone="$ZONE" --project="$PROJECT"
            success "SSL certificates uploaded"
        fi
    fi
    
    log "Starting services on production server..."
    gcloud compute ssh "$VM_NAME" --zone="$ZONE" --project="$PROJECT" --command="
        # Stop any existing services
        docker-compose down --remove-orphans 2>/dev/null || true
        
        # Pull latest images
        docker-compose pull
        
        # Start services in detached mode
        docker-compose up -d
        
        # Wait for services to be ready
        echo 'Waiting for services to start...'
        sleep 30
        
        # Show service status
        docker-compose ps
        
        echo '✅ All services started on production!'
    "
    
    success "Production deployment completed successfully!"
    echo ""
    echo "🌐 Your services are now available at:"
    echo "  - ERPNext: https://erp.vitastrategies.com"
    echo "  - Keycloak: https://auth.vitastrategies.com"
    echo "  - Windmill: https://workflows.vitastrategies.com"
    echo "  - Mattermost: https://chat.vitastrategies.com"
    echo "  - Metabase: https://analytics.vitastrategies.com"
    echo "  - Grafana: https://monitoring.vitastrategies.com"
    echo "  - Appsmith: https://apps.vitastrategies.com"
    echo "  - Openbao: https://vault.vitastrategies.com"
    echo ""
    echo "⚠️  Important next steps:"
    echo "1. Configure DNS records in Cloudflare (see DNS_CONFIGURATION.md)"
    echo "2. Update admin passwords after first login"
    echo "3. Configure each service according to your needs"
    echo ""
    echo "🔧 Management commands:"
    echo "  - Check status: gcloud compute ssh $VM_NAME --zone=$ZONE --command='docker-compose ps'"
    echo "  - View logs: gcloud compute ssh $VM_NAME --zone=$ZONE --command='docker-compose logs [service-name]'"
    echo "  - Restart: gcloud compute ssh $VM_NAME --zone=$ZONE --command='docker-compose restart [service-name]'"
    
    exit 0
fi