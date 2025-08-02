#!/bin/bash

# =============================================================================
# VITA STRATEGIES - DEVELOPMENT HELPER
# =============================================================================
# Quick commands for development workflow
# =============================================================================

set -e

show_help() {
    echo "🛠️  VITA STRATEGIES DEVELOPMENT HELPER"
    echo "====================================="
    echo ""
    echo "Usage: $0 [command]"
    echo ""
    echo "Commands:"
    echo "  start       Start development environment"
    echo "  stop        Stop development environment"
    echo "  restart     Restart all services"
    echo "  logs        Show service logs"
    echo "  status      Show service status"
    echo "  clean       Clean up containers and volumes"
    echo "  backup      Create development backup"
    echo "  test        Run development tests"
    echo "  deploy      Deploy to production"
    echo "  help        Show this help"
    echo ""
}

start_dev() {
    echo "🚀 Starting development environment..."
    
    # Use development environment
    export ENV_FILE="environments/development/.env"
    
    # Start services
    docker-compose -f docker-compose-persistent.yml --env-file="$ENV_FILE" up -d
    
    echo "✅ Development environment started!"
    echo ""
    echo "🔗 Access URLs:"
    echo "• ERPNext: http://localhost:8000"
    echo "• Metabase: http://localhost:3000"
    echo "• Grafana: http://localhost:3001"
    echo "• Appsmith: http://localhost:8080"
    echo "• Keycloak: http://localhost:8090"
    echo "• Mattermost: http://localhost:8065"
    echo ""
    echo "📋 Check status: $0 status"
}

stop_dev() {
    echo "🛑 Stopping development environment..."
    docker-compose -f docker-compose-persistent.yml down
    echo "✅ Development environment stopped!"
}

restart_dev() {
    echo "🔄 Restarting development environment..."
    stop_dev
    sleep 2
    start_dev
}

show_logs() {
    service=${1:-""}
    if [[ -n "$service" ]]; then
        echo "📋 Showing logs for $service..."
        docker-compose -f docker-compose-persistent.yml logs -f "$service"
    else
        echo "📋 Showing all service logs..."
        docker-compose -f docker-compose-persistent.yml logs -f
    fi
}

show_status() {
    echo "📊 Development Environment Status"
    echo "================================="
    echo ""
    
    # Check if Docker is running
    if ! docker info &> /dev/null; then
        echo "❌ Docker is not running!"
        echo "💡 Start Docker Desktop and try again"
        return 1
    fi
    
    # Show container status
    echo "🐳 Container Status:"
    docker-compose -f docker-compose-persistent.yml ps
    echo ""
    
    # Show system resources
    echo "💻 System Resources:"
    docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}"
    echo ""
    
    # Show volumes
    echo "💾 Data Volumes:"
    docker volume ls | grep vita-strategies | head -5
    echo ""
    
    # Show port mappings
    echo "🔗 Port Mappings:"
    docker-compose -f docker-compose-persistent.yml ps --format "table {{.Name}}\t{{.Ports}}"
}

clean_dev() {
    echo "🧹 Cleaning development environment..."
    
    read -p "⚠️  This will remove all containers and volumes. Continue? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "❌ Cleanup cancelled"
        return 1
    fi
    
    # Stop and remove containers
    docker-compose -f docker-compose-persistent.yml down -v
    
    # Remove vita-strategies containers
    docker container prune -f --filter "label=com.docker.compose.project=vita-strategies"
    
    # Remove vita-strategies volumes
    docker volume ls -q | grep vita-strategies | xargs -r docker volume rm
    
    echo "✅ Development environment cleaned!"
}

backup_dev() {
    echo "💾 Creating development backup..."
    
    backup_dir="dev-backups/backup-$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$backup_dir"
    
    # Export containers
    echo "Exporting container data..."
    docker-compose -f docker-compose-persistent.yml exec -T postgres-shared pg_dumpall -U postgres > "$backup_dir/postgres-backup.sql"
    docker-compose -f docker-compose-persistent.yml exec -T erpnext-db mysqldump -u root -p'vita_secure_2024' --all-databases > "$backup_dir/mysql-backup.sql"
    
    # Copy configs
    cp -r environments/ "$backup_dir/"
    cp docker-compose-persistent.yml "$backup_dir/"
    
    echo "✅ Development backup created: $backup_dir"
}

test_dev() {
    echo "🧪 Running development tests..."
    
    # Test service connectivity
    services=("erpnext:8000" "metabase:3000" "grafana:3001" "appsmith:8080")
    
    for service_info in "${services[@]}"; do
        IFS=':' read -r service port <<< "$service_info"
        echo "Testing $service on port $port..."
        
        if curl -s -o /dev/null -w "%{http_code}" "http://localhost:$port" | grep -q "200\|302\|401"; then
            echo "   ✅ $service is responding"
        else
            echo "   ❌ $service is not responding"
        fi
    done
    
    echo ""
    echo "📊 Test Summary:"
    echo "• Container status: $(docker-compose -f docker-compose-persistent.yml ps --quiet | wc -l | tr -d ' ') containers running"
    echo "• Volume count: $(docker volume ls -q | grep vita-strategies | wc -l | tr -d ' ') volumes"
    echo "• Network status: $(docker network ls | grep vita-strategies | wc -l | tr -d ' ') networks"
}

deploy_prod() {
    echo "🚀 Deploying to production..."
    
    read -p "🤔 Deploy to production? This will affect live services. (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "❌ Production deployment cancelled"
        return 1
    fi
    
    # Run production deployment
    ./scripts/deploy-from-gcp-cloudshell.sh
}

# Main command handling
case "${1:-help}" in
    "start")
        start_dev
        ;;
    "stop")
        stop_dev
        ;;
    "restart")
        restart_dev
        ;;
    "logs")
        show_logs "$2"
        ;;
    "status")
        show_status
        ;;
    "clean")
        clean_dev
        ;;
    "backup")
        backup_dev
        ;;
    "test")
        test_dev
        ;;
    "deploy")
        deploy_prod
        ;;
    "help"|*)
        show_help
        ;;
esac
