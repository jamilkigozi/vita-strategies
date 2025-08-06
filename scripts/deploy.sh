#!/bin/bash
# VITA STRATEGIES - UNIFIED DEPLOYMENT SCRIPT
set -e

# --- Configuration ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
COMPOSE_FILE="$PROJECT_ROOT/docker-compose.yml"
ENV_FILE="$PROJECT_ROOT/.env"
DEPLOYMENT_MODE=${1:-"safe"}

# --- Colors ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# --- Helper Functions ---
log() { echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"; }
error() { echo -e "${RED}[ERROR] $1${NC}"; exit 1; }
warning() { echo -e "${YELLOW}[WARNING] $1${NC}"; }

usage() {
    echo "Usage: $0 [safe|fresh]"
    echo "  safe  - Deploys services, preserving existing data (default)."
    echo "  fresh - Deletes all existing data and performs a fresh deployment."
    exit 1
}

# --- Main Functions ---
check_prerequisites() {
    log "Verifying prerequisites..."
    command -v docker >/dev/null 2>&1 || error "Docker is not installed. Please install it to continue."
    command -v docker-compose >/dev/null 2>&1 || error "Docker Compose is not installed. Please install it to continue."
    command -v gcloud >/dev/null 2>&1 || error "Google Cloud SDK is not installed. Please install it to continue."
    [ -f "$COMPOSE_FILE" ] || error "Master docker-compose.yml not found at $COMPOSE_FILE."
    log "✅ Prerequisites check passed."
}

setup_environment() {
    log "Setting up environment..."
    log "Fetching secrets from GCP Secret Manager..."
    if [ -f "$SCRIPT_DIR/fetch_secrets.sh" ]; then
        bash "$SCRIPT_DIR/fetch_secrets.sh" || error "Failed to fetch secrets."
    else
        error "Secret fetching script not found. Please ensure 'scripts/fetch_secrets.sh' exists."
    fi
    # Source the .env file to make variables available to this script
    set -o allexport; source "$ENV_FILE"; set +o allexport
}

deploy_applications() {
    log "Deploying applications in '$DEPLOYMENT_MODE' mode..."
    if [ "$DEPLOYMENT_MODE" = "fresh" ]; then
        log "Performing a fresh deployment. All existing data will be wiped."
        docker-compose -f "$COMPOSE_FILE" down -v --remove-orphans
    fi
    
    log "Bringing up services..."
    docker-compose -f "$COMPOSE_FILE" up -d --remove-orphans
    log "✅ Applications deployed."
}

health_check() {
    log "Performing health checks..."
    sleep 45 # Give services time to initialize
    
    services_to_check=(
        "postgres:5432"
        "mariadb:3306"
        "redis:6379"
        "traefik:80"
        "wordpress:80"
        "erpnext:8000"
        "mattermost:8065"
        "grafana:3000"
        "metabase:3000"
        "keycloak:8080"
        "appsmith:80"
        "windmill:8000"
    )
    
    all_healthy=true
    for service_info in "${services_to_check[@]}"; do
        service_name="${service_info%%:*}"
        service_port="${service_info##*:}"
        
        log "Checking $service_name..."
        if docker-compose exec "$service_name" nc -z localhost "$service_port" >/dev/null 2>&1; then
            log "  - ✅ $service_name is healthy."
        else
            warning "  - ❌ $service_name health check failed."
            all_healthy=false
        fi
    done

    if [ "$all_healthy" = false ]; then
        warning "One or more services failed the health check. Please inspect the logs."
    else
        log "✅ All services passed health checks."
    fi
}

display_results() {
    log "Deployment complete! Your services should be available at their respective domains."
    echo "  - Traefik Dashboard: http://traefik.vitastrategies.com"
    echo "  - WordPress: https://vitastrategies.com, https://www.vitastrategies.com"
    echo "  - ERPNext: https://erp.vitastrategies.com"
    echo "  - Mattermost: https://chat.vitastrategies.com"
    echo "  - Grafana: https://monitoring.vitastrategies.com"
    echo "  - Metabase: https://analytics.vitastrategies.com"
    echo "  - Keycloak: https://auth.vitastrategies.com"
    echo "  - Appsmith: https://apps.vitastrategies.com"
    echo "  - Windmill: https://flows.vitastrategies.com"
    echo
    log "To view logs for a specific service, run: docker-compose -f $COMPOSE_FILE logs -f [service-name]"
    log "To see the status of all services, run: docker-compose -f $COMPOSE_FILE ps"
}

# --- Main Execution ---
main() {
    if [[ "$DEPLOYMENT_MODE" != "safe" && "$DEPLOYMENT_MODE" != "fresh" ]]; then
        usage
    fi
    
    log "🚀 Starting Vita Strategies Unified Deployment (Mode: $DEPLOYMENT_MODE)"
    
    check_prerequisites
    setup_environment
    deploy_applications
    health_check
    display_results
    
    log "🎉 Deployment script finished!"
}

main "$@"
