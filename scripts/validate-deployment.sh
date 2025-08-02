#!/bin/bash

# =============================================================================
# VITA STRATEGIES - DEPLOYMENT VALIDATION SCRIPT
# =============================================================================
# Validates that all services are running correctly
# =============================================================================

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

ENVIRONMENT=${1:-production}

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

check_service() {
    local service_name=$1
    local url=$2
    local expected_status=${3:-200}
    
    log "Checking $service_name..."
    
    if curl -s -o /dev/null -w "%{http_code}" "$url" | grep -q "$expected_status"; then
        success "$service_name is responding correctly"
        return 0
    else
        error "$service_name is not responding (URL: $url)"
        return 1
    fi
}

check_docker_services() {
    log "Checking Docker services..."
    
    if ! docker-compose -f applications/docker-compose-complete.yml ps | grep -q "Up"; then
        error "No Docker services are running"
        return 1
    fi
    
    local services=("erpnext" "keycloak" "windmill" "mattermost" "metabase" "grafana" "appsmith" "openbao" "postgres")
    local failed_services=()
    
    for service in "${services[@]}"; do
        if docker-compose -f applications/docker-compose-complete.yml ps | grep "$service" | grep -q "Up"; then
            success "$service container is running"
        else
            error "$service container is not running"
            failed_services+=("$service")
        fi
    done
    
    if [ ${#failed_services[@]} -eq 0 ]; then
        success "All Docker services are running"
        return 0
    else
        error "Failed services: ${failed_services[*]}"
        return 1
    fi
}

check_production_services() {
    log "Checking production service URLs..."
    
    local all_passed=true
    
    check_service "ERPNext" "https://erp.vitastrategies.com" || all_passed=false
    check_service "Keycloak" "https://auth.vitastrategies.com" || all_passed=false
    check_service "Windmill" "https://workflows.vitastrategies.com" || all_passed=false
    check_service "Mattermost" "https://chat.vitastrategies.com" || all_passed=false
    check_service "Metabase" "https://analytics.vitastrategies.com" || all_passed=false
    check_service "Grafana" "https://monitoring.vitastrategies.com" || all_passed=false
    check_service "Appsmith" "https://apps.vitastrategies.com" || all_passed=false
    check_service "Openbao" "https://vault.vitastrategies.com" || all_passed=false
    
    if $all_passed; then
        success "All production services are accessible"
    else
        error "Some production services are not accessible"
    fi
}

check_development_services() {
    log "Checking development service ports..."
    
    local all_passed=true
    
    check_service "ERPNext" "http://localhost:8000" || all_passed=false
    check_service "Keycloak" "http://localhost:8180" || all_passed=false
    check_service "Windmill" "http://localhost:8080" || all_passed=false
    check_service "Mattermost" "http://localhost:8065" || all_passed=false
    check_service "Metabase" "http://localhost:3000" || all_passed=false
    check_service "Grafana" "http://localhost:3001" || all_passed=false
    check_service "Appsmith" "http://localhost:8081" || all_passed=false
    check_service "Openbao" "http://localhost:8200" || all_passed=false
    
    if $all_passed; then
        success "All development services are accessible"
    else
        error "Some development services are not accessible"
    fi
}

check_dns_records() {
    log "Checking DNS records..."
    
    local domains=("erp" "auth" "workflows" "chat" "analytics" "monitoring" "apps" "vault")
    local all_passed=true
    
    for domain in "${domains[@]}"; do
        if nslookup "${domain}.vitastrategies.com" > /dev/null 2>&1; then
            success "DNS for ${domain}.vitastrategies.com is working"
        else
            error "DNS for ${domain}.vitastrategies.com is not working"
            all_passed=false
        fi
    done
    
    if $all_passed; then
        success "All DNS records are properly configured"
    else
        warning "Some DNS records may need time to propagate"
    fi
}

show_service_status() {
    echo ""
    log "=== SERVICE STATUS SUMMARY ==="
    
    if [[ "$ENVIRONMENT" == "production" ]]; then
        echo "🌐 Production URLs:"
        echo "  ERPNext: https://erp.vitastrategies.com"
        echo "  Keycloak: https://auth.vitastrategies.com"
        echo "  Windmill: https://workflows.vitastrategies.com"
        echo "  Mattermost: https://chat.vitastrategies.com"
        echo "  Metabase: https://analytics.vitastrategies.com"
        echo "  Grafana: https://monitoring.vitastrategies.com"
        echo "  Appsmith: https://apps.vitastrategies.com"
        echo "  Openbao: https://vault.vitastrategies.com"
    else
        echo "🖥️  Local Development URLs:"
        echo "  ERPNext: http://localhost:8000"
        echo "  Keycloak: http://localhost:8180"
        echo "  Windmill: http://localhost:8080"
        echo "  Mattermost: http://localhost:8065"
        echo "  Metabase: http://localhost:3000"
        echo "  Grafana: http://localhost:3001"
        echo "  Appsmith: http://localhost:8081"
        echo "  Openbao: http://localhost:8200"
    fi
    
    echo ""
    echo "📋 Credentials: Check CREDENTIALS.md for login details"
}

main() {
    echo -e "${BLUE}"
    echo "🔍 VITA STRATEGIES - DEPLOYMENT VALIDATION"
    echo "Environment: $ENVIRONMENT"
    echo -e "${NC}"
    
    # Check Docker services first
    check_docker_services
    
    # Wait a moment for services to fully start
    log "Waiting 30 seconds for services to fully initialize..."
    sleep 30
    
    # Check service accessibility
    if [[ "$ENVIRONMENT" == "production" ]]; then
        check_dns_records
        check_production_services
    else
        check_development_services
    fi
    
    show_service_status
    
    echo ""
    success "🎉 Validation completed!"
    echo ""
    warning "💡 Next Steps:"
    echo "1. Configure first-time setups for Metabase and Appsmith"
    echo "2. Set up authentication flows in Keycloak"
    echo "3. Create your first workflows in Windmill"
    echo "4. Invite team members to Mattermost"
}

main "$@"
