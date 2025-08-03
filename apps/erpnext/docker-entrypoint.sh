#!/bin/bash
set -euo pipefail

# ERPNext Production Entrypoint Script
# Handles initialization, migrations, and service startup

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
        "DB_HOST"
        "DB_NAME" 
        "DB_USER"
        "DB_PASSWORD"
        "SITE_NAME"
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

# Wait for database connectivity
wait_for_database() {
    log_info "Waiting for database connectivity..."
    
    local max_attempts=30
    local attempt=1
    
    while [[ $attempt -le $max_attempts ]]; do
        if mysqladmin ping -h"$DB_HOST" -P"$DB_PORT" -u"$DB_USER" -p"$DB_PASSWORD" --silent >/dev/null 2>&1; then
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
    redis_host=$(echo "$REDIS_CACHE" | sed 's/redis:\/\/\([^:]*\).*/\1/')
    local redis_port
    redis_port=$(echo "$REDIS_CACHE" | sed 's/.*:\([0-9]*\).*/\1/')
    
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

# Generate secure encryption key
generate_encryption_key() {
    if [[ -z "${ENCRYPTION_KEY:-}" ]]; then
        log_info "Generating encryption key..."
        ENCRYPTION_KEY=$(python3 -c "import secrets; print(secrets.token_urlsafe(32))")
        export ENCRYPTION_KEY
        log_success "Encryption key generated"
    fi
}

# Create common site configuration
create_site_config() {
    log_info "Creating site configuration..."
    
    local config_file="/home/frappe/frappe-bench/sites/common_site_config.json"
    
    cat > "$config_file" << EOF
{
  "db_host": "$DB_HOST",
  "db_port": $DB_PORT,
  "redis_cache": "$REDIS_CACHE",
  "redis_queue": "$REDIS_QUEUE",
  "redis_socketio": "$REDIS_SOCKETIO",
  "encryption_key": "$ENCRYPTION_KEY",
  "developer_mode": $DEVELOPER_MODE,
  "disable_website_cache": false,
  "file_watcher_port": 6787,
  "frappe_user": "frappe",
  "rebase_on_pull": false,
  "serve_default_site": true,
  "shallow_clone": true,
  "skip_frappe_schema_check": false,
  "use_redis_auth": false,
  "webserver_port": 8000,
  "socketio_port": 9000,
  "auto_update": false,
  "restart_supervisor_on_update": false,
  "restart_systemd_on_update": false,
  "serve_default_site": true,
  "logging": 1,
  "log_level": "INFO",
  "backup_path": "/home/frappe/frappe-bench/sites/backups",
  "backup_with_files": true
}
EOF

    chmod 600 "$config_file"
    log_success "Site configuration created"
}

# Initialize ERPNext site
initialize_site() {
    log_info "Initializing ERPNext site..."
    
    local site_dir="/home/frappe/frappe-bench/sites/$SITE_NAME"
    
    if [[ ! -d "$site_dir" ]]; then
        log_info "Creating new ERPNext site: $SITE_NAME"
        
        # Create new site
        bench new-site "$SITE_NAME" \
            --db-name "$DB_NAME" \
            --db-user "$DB_USER" \
            --db-password "$DB_PASSWORD" \
            --admin-password "${ADMIN_PASSWORD:-admin123}" \
            --install-app erpnext \
            --force
            
        log_success "ERPNext site created successfully"
    else
        log_info "Site already exists, checking for updates..."
        
        # Set current site
        bench use "$SITE_NAME"
        
        # Run migrations if auto-migrate is enabled
        if [[ "${AUTO_MIGRATE:-0}" == "1" ]]; then
            log_info "Running database migrations..."
            bench migrate --skip-failing
            log_success "Database migrations completed"
        fi
    fi
}

# Configure email settings
configure_email() {
    if [[ -n "${MAIL_SERVER:-}" ]]; then
        log_info "Configuring email settings..."
        
        bench --site "$SITE_NAME" set-config mail_server "$MAIL_SERVER"
        bench --site "$SITE_NAME" set-config mail_port "$MAIL_PORT"
        bench --site "$SITE_NAME" set-config use_tls "$MAIL_USE_TLS"
        
        if [[ -n "${MAIL_USERNAME:-}" ]]; then
            bench --site "$SITE_NAME" set-config mail_username "$MAIL_USERNAME"
        fi
        
        if [[ -n "${MAIL_PASSWORD:-}" ]]; then
            bench --site "$SITE_NAME" set-config mail_password "$MAIL_PASSWORD"
        fi
        
        log_success "Email configuration completed"
    fi
}

# Set up HTTPS enforcement
configure_https() {
    if [[ "${FORCE_HTTPS:-0}" == "1" ]]; then
        log_info "Configuring HTTPS enforcement..."
        
        bench --site "$SITE_NAME" set-config force_https 1
        bench --site "$SITE_NAME" set-config session_cookie_secure 1
        bench --site "$SITE_NAME" set-config csrf_cookie_secure 1
        
        log_success "HTTPS enforcement configured"
    fi
}

# Configure backup schedule
configure_backup() {
    if [[ -n "${BACKUP_SCHEDULE:-}" ]]; then
        log_info "Configuring automated backups..."
        
        # Create backup script
        cat > /home/frappe/backup_script.sh << 'EOF'
#!/bin/bash
set -euo pipefail

# Run ERPNext backup
cd /home/frappe/frappe-bench
bench --site all backup --with-files

# Optional: Upload to cloud storage
# gsutil cp sites/*/backups/*.sql.gz gs://vita-backup-storage/erpnext/
# gsutil cp sites/*/backups/*.tar gs://vita-backup-storage/erpnext/

echo "Backup completed successfully at $(date)"
EOF

        chmod +x /home/frappe/backup_script.sh
        
        # Add cron job
        (crontab -l 2>/dev/null; echo "$BACKUP_SCHEDULE /home/frappe/backup_script.sh >> /var/log/erpnext/backup.log 2>&1") | crontab -
        
        log_success "Backup schedule configured"
    fi
}

# Start supervisord for process management
start_services() {
    log_info "Starting ERPNext services..."
    
    # Create supervisor configuration
    cat > /etc/supervisor/conf.d/erpnext.conf << EOF
[supervisord]
nodaemon=true
user=root
logfile=/var/log/erpnext/supervisord.log
pidfile=/var/run/supervisord.pid

[program:erpnext-web]
command=/home/frappe/frappe-bench/env/bin/gunicorn -b 0.0.0.0:8000 -w 4 --timeout 120 --max-requests 5000 --max-requests-jitter 500 frappe.app:application --preload
directory=/home/frappe/frappe-bench
user=frappe
autostart=true
autorestart=true
redirect_stderr=true
stdout_logfile=/var/log/erpnext/web.log
stdout_logfile_maxbytes=50MB
stdout_logfile_backups=5

[program:erpnext-worker-default]
command=/home/frappe/frappe-bench/env/bin/python -m frappe.utils.bench worker --queue default
directory=/home/frappe/frappe-bench
user=frappe
autostart=true
autorestart=true
redirect_stderr=true
stdout_logfile=/var/log/erpnext/worker-default.log
stdout_logfile_maxbytes=50MB
stdout_logfile_backups=5

[program:erpnext-worker-long]
command=/home/frappe/frappe-bench/env/bin/python -m frappe.utils.bench worker --queue long
directory=/home/frappe/frappe-bench
user=frappe
autostart=true
autorestart=true
redirect_stderr=true
stdout_logfile=/var/log/erpnext/worker-long.log
stdout_logfile_maxbytes=50MB
stdout_logfile_backups=5

[program:erpnext-worker-short]
command=/home/frappe/frappe-bench/env/bin/python -m frappe.utils.bench worker --queue short
directory=/home/frappe/frappe-bench
user=frappe
autostart=true
autorestart=true
redirect_stderr=true
stdout_logfile=/var/log/erpnext/worker-short.log
stdout_logfile_maxbytes=50MB
stdout_logfile_backups=5

[program:erpnext-schedule]
command=/home/frappe/frappe-bench/env/bin/python -m frappe.utils.bench schedule
directory=/home/frappe/frappe-bench
user=frappe
autostart=true
autorestart=true
redirect_stderr=true
stdout_logfile=/var/log/erpnext/schedule.log
stdout_logfile_maxbytes=50MB
stdout_logfile_backups=5

[program:redis-server]
command=redis-server --appendonly yes --dir /home/frappe/redis-data
user=frappe
autostart=true
autorestart=true
redirect_stderr=true
stdout_logfile=/var/log/erpnext/redis.log
stdout_logfile_maxbytes=50MB
stdout_logfile_backups=5
EOF

    log_success "Supervisor configuration created"
}

# Create log directories
setup_logging() {
    log_info "Setting up logging directories..."
    
    mkdir -p /var/log/erpnext
    mkdir -p /home/frappe/redis-data
    
    chown -R frappe:frappe /var/log/erpnext
    chown -R frappe:frappe /home/frappe/redis-data
    
    log_success "Logging setup completed"
}

# Main execution flow
main() {
    log_info "Starting ERPNext container initialization..."
    
    # Validate environment
    validate_environment
    
    # Set up logging
    setup_logging
    
    # Wait for dependencies
    wait_for_database
    wait_for_redis
    
    # Generate encryption key
    generate_encryption_key
    
    # Create configuration
    create_site_config
    
    # Initialize site
    initialize_site
    
    # Configure services
    configure_email
    configure_https
    configure_backup
    
    # Prepare services
    start_services
    
    log_success "ERPNext initialization completed successfully"
    log_info "Starting ERPNext services..."
    
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
