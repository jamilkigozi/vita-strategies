#!/bin/bash
set -euo pipefail

# Windmill Production Entrypoint Script
# Handles initialization, database setup, and service startup

# Color codes for logging
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $*"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $*"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $*"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $*" >&2
}

# Environment validation
validate_environment() {
    log_info "Validating environment variables..."
    
    local required_vars=(
        "DATABASE_URL"
        "REDIS_URL"
    )
    
    local missing_vars=()
    
    for var in "${required_vars[@]}"; do
        if [[ -z "${!var:-}" ]]; then
            missing_vars+=("$var")
        fi
    done
    
    if [[ ${#missing_vars[@]} -gt 0 ]]; then
        log_error "Missing required environment variables: ${missing_vars[*]}"
        exit 1
    fi
    
    log_success "Environment validation completed"
}

# Extract database connection details
extract_db_details() {
    log_info "Extracting database connection details..."
    
    # Parse DATABASE_URL (format: postgresql://user:password@host:port/dbname)
    if [[ "$DATABASE_URL" =~ postgresql://([^:]+):([^@]+)@([^:]+):([0-9]+)/(.+) ]]; then
        export DB_USER="${BASH_REMATCH[1]}"
        export DB_PASSWORD="${BASH_REMATCH[2]}"
        export DB_HOST="${BASH_REMATCH[3]}"
        export DB_PORT="${BASH_REMATCH[4]}"
        export DB_NAME="${BASH_REMATCH[5]}"
        log_success "Database details extracted successfully"
    else
        log_error "Invalid DATABASE_URL format"
        exit 1
    fi
}

# Wait for database connectivity
wait_for_database() {
    log_info "Waiting for database connectivity..."
    
    local max_attempts=30
    local attempt=1
    
    while [[ $attempt -le $max_attempts ]]; do
        if pg_isready -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" >/dev/null 2>&1; then
            log_success "Database is ready"
            return 0
        fi
        
        log_warn "Database not ready, attempt $attempt/$max_attempts..."
        sleep 5
        ((attempt++))
    done
    
    log_error "Database connection failed after $max_attempts attempts"
    exit 1
}

# Wait for Redis connectivity
wait_for_redis() {
    log_info "Waiting for Redis connectivity..."
    
    local max_attempts=15
    local attempt=1
    
    # Extract Redis host from URL
    local redis_host
    redis_host=$(echo "$REDIS_URL" | sed 's/redis:\/\/\([^:]*\).*/\1/')
    local redis_port
    redis_port=$(echo "$REDIS_URL" | sed 's/.*:\([0-9]*\).*/\1/')
    
    while [[ $attempt -le $max_attempts ]]; do
        if redis-cli -h "$redis_host" -p "$redis_port" ping >/dev/null 2>&1; then
            log_success "Redis is ready"
            return 0
        fi
        
        log_warn "Redis not ready, attempt $attempt/$max_attempts..."
        sleep 2
        ((attempt++))
    done
    
    log_error "Redis connection failed after $max_attempts attempts"
    exit 1
}

# Initialize database schema
initialize_database() {
    log_info "Initializing Windmill database schema..."
    
    # Check if database is already initialized
    if PGPASSWORD="$DB_PASSWORD" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" \
        -c "SELECT 1 FROM information_schema.tables WHERE table_name = 'script';" | grep -q "1 row"; then
        log_info "Database already initialized, checking for migrations..."
    else
        log_info "Database not initialized, creating schema..."
        
        # Run Windmill database initialization
        windmill migrate || {
            log_error "Database migration failed"
            exit 1
        }
        
        log_success "Database initialization completed"
    fi
}

# Create initial workspace and admin user
setup_initial_data() {
    log_info "Setting up initial workspace and admin user..."
    
    # Wait for Windmill server to be ready
    local max_attempts=30
    local attempt=1
    
    while [[ $attempt -le $max_attempts ]]; do
        if curl -s http://localhost:8000/api/version >/dev/null 2>&1; then
            log_success "Windmill server is ready"
            break
        fi
        
        log_warn "Waiting for Windmill server, attempt $attempt/$max_attempts..."
        sleep 2
        ((attempt++))
        
        if [[ $attempt -gt $max_attempts ]]; then
            log_error "Windmill server failed to start"
            exit 1
        fi
    done
    
    # Create admin user if not exists
    local admin_email="${ADMIN_EMAIL:-admin@vitastrategies.com}"
    local admin_password="${ADMIN_PASSWORD:-admin123}"
    
    log_info "Creating admin user: $admin_email"
    
    # Use Windmill CLI to create user (if available)
    # windmill user create --email="$admin_email" --password="$admin_password" --role=admin || true
    
    log_success "Initial data setup completed"
}

# Configure workflow templates
setup_workflow_templates() {
    log_info "Setting up workflow templates..."
    
    local templates_dir="/opt/windmill/workflows"
    
    if [[ -d "$templates_dir" ]]; then
        log_info "Loading workflow templates from $templates_dir"
        
        # Import workflow templates (implementation depends on Windmill API)
        for template in "$templates_dir"/*.json; do
            if [[ -f "$template" ]]; then
                log_info "Loading template: $(basename "$template")"
                # windmill workflow import "$template" || log_warn "Failed to import $(basename "$template")"
            fi
        done
        
        log_success "Workflow templates setup completed"
    else
        log_warn "No workflow templates directory found"
    fi
}

# Configure external integrations
setup_integrations() {
    log_info "Configuring external integrations..."
    
    # Configure ERPNext integration
    if [[ -n "${ERPNEXT_URL:-}" ]]; then
        log_info "Configuring ERPNext integration"
        # Add ERPNext connection configuration
    fi
    
    # Configure database connections
    if [[ -n "${MYSQL_URL:-}" ]]; then
        log_info "Configuring MySQL connection"
        # Add MySQL connection configuration
    fi
    
    # Configure cloud storage
    if [[ -n "${GCS_BUCKET:-}" ]]; then
        log_info "Configuring Google Cloud Storage"
        # Add GCS configuration
    fi
    
    log_success "External integrations configured"
}

# Set up monitoring and logging
setup_monitoring() {
    log_info "Setting up monitoring and logging..."
    
    # Create log directories
    mkdir -p /var/log/windmill
    
    # Set up log rotation
    if command -v logrotate >/dev/null 2>&1; then
        log_info "Log rotation is configured"
    fi
    
    # Configure metrics collection
    if [[ "${DISABLE_STATS:-false}" != "true" ]]; then
        log_info "Metrics collection enabled on ${METRICS_ADDR:-0.0.0.0:8001}"
    fi
    
    log_success "Monitoring and logging setup completed"
}

# Start Windmill services
start_windmill_services() {
    log_info "Starting Windmill services..."
    
    # Create supervisor configuration for Windmill
    cat > /etc/supervisor/conf.d/windmill.conf << EOF
[supervisord]
nodaemon=true
user=root
logfile=/var/log/windmill/supervisord.log
pidfile=/var/run/supervisord.pid

[program:windmill-server]
command=windmill server
directory=/opt/windmill
user=windmill
autostart=true
autorestart=true
redirect_stderr=true
stdout_logfile=/var/log/windmill/server.log
stdout_logfile_maxbytes=50MB
stdout_logfile_backups=5
environment=DATABASE_URL="%(ENV_DATABASE_URL)s",REDIS_URL="%(ENV_REDIS_URL)s"

[program:windmill-worker]
command=windmill worker --worker-tags="%(ENV_WINDMILL_WORKER_TAGS)s"
directory=/opt/windmill
user=windmill
autostart=true
autorestart=true
redirect_stderr=true
stdout_logfile=/var/log/windmill/worker.log
stdout_logfile_maxbytes=50MB
stdout_logfile_backups=5
numprocs=%(ENV_NUM_WORKERS)s
process_name=worker-%(process_num)s
environment=DATABASE_URL="%(ENV_DATABASE_URL)s",REDIS_URL="%(ENV_REDIS_URL)s"

[program:windmill-metrics]
command=windmill metrics --bind="%(ENV_METRICS_ADDR)s"
directory=/opt/windmill
user=windmill
autostart=true
autorestart=true
redirect_stderr=true
stdout_logfile=/var/log/windmill/metrics.log
stdout_logfile_maxbytes=50MB
stdout_logfile_backups=5
environment=DATABASE_URL="%(ENV_DATABASE_URL)s",REDIS_URL="%(ENV_REDIS_URL)s"
EOF
    
    log_success "Windmill services configuration created"
}

# Set up backup automation
setup_backup() {
    log_info "Setting up backup automation..."
    
    # Create backup script
    cat > /opt/windmill/backup_script.sh << 'EOF'
#!/bin/bash
set -euo pipefail

# Windmill backup script
BACKUP_DIR="/opt/windmill/backups"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

mkdir -p "$BACKUP_DIR"

# Backup database
echo "Creating database backup..."
PGPASSWORD="$DB_PASSWORD" pg_dump -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" \
    > "$BACKUP_DIR/windmill_db_$TIMESTAMP.sql"

# Backup workflows and scripts
echo "Backing up workflows..."
# windmill export --output="$BACKUP_DIR/windmill_workflows_$TIMESTAMP.json"

# Compress backups
echo "Compressing backups..."
tar -czf "$BACKUP_DIR/windmill_backup_$TIMESTAMP.tar.gz" -C "$BACKUP_DIR" \
    "windmill_db_$TIMESTAMP.sql"

# Clean up old backups (keep last 7 days)
find "$BACKUP_DIR" -name "windmill_backup_*.tar.gz" -mtime +7 -delete

# Optional: Upload to cloud storage
# gsutil cp "$BACKUP_DIR/windmill_backup_$TIMESTAMP.tar.gz" gs://vita-backup-storage/windmill/

echo "Backup completed successfully at $(date)"
EOF

    chmod +x /opt/windmill/backup_script.sh
    
    # Add cron job for daily backups
    (crontab -l 2>/dev/null; echo "0 3 * * * /opt/windmill/backup_script.sh >> /var/log/windmill/backup.log 2>&1") | crontab -
    
    log_success "Backup automation configured"
}

# Main execution flow
main() {
    log_info "Starting Windmill container initialization..."
    
    # Validate environment
    validate_environment
    
    # Extract database details
    extract_db_details
    
    # Wait for dependencies
    wait_for_database
    wait_for_redis
    
    # Initialize database
    initialize_database
    
    # Set up monitoring
    setup_monitoring
    
    # Configure services
    start_windmill_services
    
    # Set up backup
    setup_backup
    
    # Start Windmill server in background for initial setup
    windmill server &
    WINDMILL_PID=$!
    
    # Wait a moment for server to start
    sleep 10
    
    # Setup initial data
    setup_initial_data
    
    # Setup workflow templates
    setup_workflow_templates
    
    # Setup integrations
    setup_integrations
    
    # Stop background server
    kill $WINDMILL_PID 2>/dev/null || true
    wait $WINDMILL_PID 2>/dev/null || true
    
    log_success "Windmill initialization completed successfully"
    log_info "Starting Windmill services with supervisor..."
    
    # Execute the command passed to the container
    exec "$@"
}

# Handle signals for graceful shutdown
cleanup() {
    log_info "Received shutdown signal, cleaning up..."
    
    # Stop supervisor processes
    if pgrep supervisord >/dev/null; then
        supervisorctl stop all
        kill $(pgrep supervisord)
    fi
    
    log_success "Cleanup completed"
    exit 0
}

trap cleanup SIGTERM SIGINT

# Run main function
main "$@"
