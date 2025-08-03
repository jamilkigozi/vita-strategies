#!/bin/bash
set -euo pipefail

# Docker entrypoint script for Grafana Monitoring Platform
# This script handles initialization, configuration, and startup

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')] [GRAFANA-INIT]${NC} $1"
}

error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] [GRAFANA-ERROR]${NC} $1" >&2
}

warn() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] [GRAFANA-WARN]${NC} $1"
}

success() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] [GRAFANA-SUCCESS]${NC} $1"
}

# Function to check if a service is ready
wait_for_service() {
    local host=$1
    local port=$2
    local service_name=$3
    local max_attempts=30
    local attempt=1

    log "Waiting for $service_name to be ready at $host:$port..."
    
    while [ $attempt -le $max_attempts ]; do
        if nc -z "$host" "$port" 2>/dev/null; then
            success "$service_name is ready!"
            return 0
        fi
        
        log "Attempt $attempt/$max_attempts: $service_name not ready, waiting 5 seconds..."
        sleep 5
        ((attempt++))
    done
    
    error "$service_name is not ready after $max_attempts attempts"
    return 1
}

# Function to validate environment variables
validate_environment() {
    log "Validating environment variables..."
    
    local required_vars=(
        "GF_DATABASE_HOST"
        "GF_DATABASE_NAME"
        "GF_DATABASE_USER"
        "GF_DATABASE_PASSWORD"
        "GF_SECURITY_SECRET_KEY"
        "GF_SECURITY_ADMIN_PASSWORD"
    )
    
    local missing_vars=()
    
    for var in "${required_vars[@]}"; do
        if [[ -z "${!var:-}" ]]; then
            missing_vars+=("$var")
        fi
    done
    
    if [[ ${#missing_vars[@]} -gt 0 ]]; then
        error "Missing required environment variables:"
        printf ' - %s\n' "${missing_vars[@]}"
        exit 1
    fi
    
    success "Environment validation passed"
}

# Function to initialize database
initialize_database() {
    log "Checking database connectivity..."
    
    # Extract database connection details
    local db_host="${GF_DATABASE_HOST%%:*}"
    local db_port="${GF_DATABASE_HOST##*:}"
    if [[ "$db_port" == "$db_host" ]]; then
        db_port="5432"
    fi
    
    # Wait for database to be ready
    if ! wait_for_service "$db_host" "$db_port" "PostgreSQL"; then
        error "Database is not accessible"
        exit 1
    fi
    
    # Test database connection
    log "Testing database connection..."
    if PGPASSWORD="$GF_DATABASE_PASSWORD" psql -h "$db_host" -p "$db_port" -U "$GF_DATABASE_USER" -d "$GF_DATABASE_NAME" -c "SELECT 1;" > /dev/null 2>&1; then
        success "Database connection successful"
    else
        error "Failed to connect to database"
        exit 1
    fi
}

# Function to initialize Redis session store
initialize_redis() {
    if [[ "${GF_SESSION_PROVIDER:-}" == "redis" ]]; then
        log "Checking Redis connectivity..."
        
        # Extract Redis connection details
        local redis_config="${GF_SESSION_PROVIDER_CONFIG:-addr=redis:6379}"
        local redis_addr=$(echo "$redis_config" | grep -o 'addr=[^,]*' | cut -d'=' -f2)
        local redis_host="${redis_addr%%:*}"
        local redis_port="${redis_addr##*:}"
        
        if [[ "$redis_port" == "$redis_host" ]]; then
            redis_port="6379"
        fi
        
        # Wait for Redis to be ready
        if wait_for_service "$redis_host" "$redis_port" "Redis"; then
            success "Redis session store ready"
        else
            warn "Redis not available, falling back to database sessions"
            export GF_SESSION_PROVIDER="postgres"
        fi
    fi
}

# Function to setup SAML/SSO configuration
setup_sso() {
    if [[ "${GF_AUTH_SAML_ENABLED:-false}" == "true" ]]; then
        log "Configuring SAML SSO..."
        
        # Check required SAML variables
        if [[ -z "${KEYCLOAK_URL:-}" ]] || [[ -z "${KEYCLOAK_REALM:-}" ]]; then
            warn "SAML enabled but Keycloak configuration missing, disabling SAML"
            export GF_AUTH_SAML_ENABLED=false
            return
        fi
        
        # Set SAML configuration
        export GF_AUTH_SAML_METADATA_URL="${KEYCLOAK_URL}/realms/${KEYCLOAK_REALM}/protocol/saml/descriptor"
        export GF_AUTH_SAML_ASSERTION_CONSUMER_URL="${GF_SERVER_ROOT_URL}/login/saml"
        export GF_AUTH_SAML_SINGLE_LOGOUT_URL="${GF_SERVER_ROOT_URL}/logout"
        
        success "SAML SSO configuration completed"
    fi
}

# Function to setup SMTP configuration
setup_smtp() {
    if [[ "${GF_SMTP_ENABLED:-false}" == "true" ]]; then
        log "Configuring SMTP..."
        
        if [[ -z "${GF_SMTP_HOST:-}" ]] || [[ -z "${GF_SMTP_USER:-}" ]]; then
            warn "SMTP enabled but configuration incomplete, disabling SMTP"
            export GF_SMTP_ENABLED=false
            return
        fi
        
        success "SMTP configuration completed"
    fi
}

# Function to setup alerting
setup_alerting() {
    log "Configuring alerting..."
    
    # Create alerting directory
    mkdir -p /var/lib/grafana/alerting
    
    # Setup default notification channels if they don't exist
    local notification_config="/etc/grafana/provisioning/notifiers/default.yaml"
    if [[ ! -f "$notification_config" ]]; then
        cat > "$notification_config" << EOF
notifiers:
  - name: email-alerts
    type: email
    uid: email-alerts
    org_id: 1
    is_default: true
    send_reminder: true
    settings:
      addresses: "${GF_SMTP_FROM_ADDRESS:-admin@vitastrategies.com}"
      subject: "[Grafana Alert] {{ .CommonLabels.alertname }}"
      body: |
        Alert: {{ .CommonLabels.alertname }}
        Summary: {{ .CommonAnnotations.summary }}
        Description: {{ .CommonAnnotations.description }}
        
        Status: {{ .Status }}
        Severity: {{ .CommonLabels.severity }}
        
        Time: {{ .FiringTime }}
EOF
    fi
    
    success "Alerting configuration completed"
}

# Function to setup dashboards
setup_dashboards() {
    log "Setting up dashboards..."
    
    # Create dashboard directories
    mkdir -p /var/lib/grafana/dashboards/{infrastructure,applications,business,security}
    
    # Set permissions
    chown -R grafana:grafana /var/lib/grafana/dashboards
    
    success "Dashboard setup completed"
}

# Function to setup logging
setup_logging() {
    log "Configuring logging..."
    
    # Create log directory
    mkdir -p /var/log/grafana
    chown grafana:grafana /var/log/grafana
    
    # Setup log rotation
    if [[ -f /etc/logrotate.d/grafana ]]; then
        log "Log rotation already configured"
    else
        cat > /etc/logrotate.d/grafana << EOF
/var/log/grafana/*.log {
    daily
    rotate 30
    compress
    delaycompress
    missingok
    notifempty
    create 0644 grafana grafana
    postrotate
        if [ -f /var/run/grafana-server.pid ]; then
            kill -HUP \$(cat /var/run/grafana-server.pid) 2>/dev/null || true
        fi
    endscript
}
EOF
    fi
    
    success "Logging configuration completed"
}

# Function to setup monitoring
setup_monitoring() {
    log "Setting up monitoring..."
    
    # Enable metrics endpoint
    export GF_METRICS_ENABLED=true
    export GF_METRICS_BASIC_AUTH_USERNAME="${GF_METRICS_USERNAME:-metrics}"
    export GF_METRICS_BASIC_AUTH_PASSWORD="${GF_METRICS_PASSWORD:-$(openssl rand -base64 32)}"
    
    # Setup health check endpoint
    export GF_FEATURE_TOGGLES_ENABLE="publicDashboards"
    
    success "Monitoring setup completed"
}

# Function to apply security hardening
apply_security_hardening() {
    log "Applying security hardening..."
    
    # Set secure defaults
    export GF_SECURITY_DISABLE_GRAVATAR=true
    export GF_SECURITY_COOKIE_SECURE=true
    export GF_SECURITY_COOKIE_SAMESITE=strict
    export GF_SECURITY_CONTENT_TYPE_PROTECTION=true
    export GF_SECURITY_X_CONTENT_TYPE_OPTIONS=nosniff
    export GF_SECURITY_X_XSS_PROTECTION=true
    
    # Disable unnecessary features
    export GF_ANALYTICS_REPORTING_ENABLED=false
    export GF_ANALYTICS_CHECK_FOR_UPDATES=false
    export GF_SNAPSHOTS_EXTERNAL_ENABLED=false
    
    # Set session security
    export GF_SESSION_COOKIE_SECURE=true
    export GF_SESSION_COOKIE_SAMESITE=strict
    
    success "Security hardening applied"
}

# Function to run database migrations
run_migrations() {
    log "Running database migrations..."
    
    # Run Grafana database migrations
    if grafana-cli admin migrate all --homepath=/usr/share/grafana > /dev/null 2>&1; then
        success "Database migrations completed"
    else
        warn "Database migrations may have failed, continuing..."
    fi
}

# Function to install additional plugins
install_plugins() {
    if [[ -n "${GF_INSTALL_PLUGINS:-}" ]]; then
        log "Installing additional plugins: $GF_INSTALL_PLUGINS"
        
        IFS=',' read -ra PLUGINS <<< "$GF_INSTALL_PLUGINS"
        for plugin in "${PLUGINS[@]}"; do
            log "Installing plugin: $plugin"
            if grafana-cli plugins install "$plugin"; then
                success "Plugin $plugin installed"
            else
                warn "Failed to install plugin: $plugin"
            fi
        done
    fi
}

# Function to setup backup
setup_backup() {
    log "Setting up backup configuration..."
    
    # Create backup directory
    mkdir -p /var/lib/grafana/backups
    chown grafana:grafana /var/lib/grafana/backups
    
    # Setup backup script
    if [[ -f /opt/grafana/scripts/backup.sh ]]; then
        chmod +x /opt/grafana/scripts/backup.sh
        
        # Setup cron job for daily backups
        echo "0 2 * * * /opt/grafana/scripts/backup.sh" | crontab -u grafana -
        success "Backup configuration completed"
    fi
}

# Function to perform health check
health_check() {
    log "Performing initial health check..."
    
    # Wait a moment for Grafana to start
    sleep 10
    
    # Check if Grafana is responding
    if curl -f -s "http://localhost:3000/api/health" > /dev/null; then
        success "Grafana health check passed"
        return 0
    else
        warn "Grafana health check failed"
        return 1
    fi
}

# Function to print startup information
print_startup_info() {
    log "=== Grafana Monitoring Platform ==="
    log "Version: $(grafana-server --version)"
    log "Admin URL: ${GF_SERVER_ROOT_URL:-http://localhost:3000}"
    log "Admin User: ${GF_SECURITY_ADMIN_USER:-admin}"
    log "Database: ${GF_DATABASE_TYPE:-postgres}://${GF_DATABASE_HOST:-localhost}/${GF_DATABASE_NAME:-grafana}"
    log "Session Store: ${GF_SESSION_PROVIDER:-database}"
    log "SAML Enabled: ${GF_AUTH_SAML_ENABLED:-false}"
    log "SMTP Enabled: ${GF_SMTP_ENABLED:-false}"
    log "Alerting Enabled: ${GF_ALERTING_ENABLED:-true}"
    log "==================================="
}

# Main initialization function
main() {
    log "Starting Grafana initialization..."
    
    # Validate environment
    validate_environment
    
    # Initialize external services
    initialize_database
    initialize_redis
    
    # Setup Grafana components
    setup_sso
    setup_smtp
    setup_alerting
    setup_dashboards
    setup_logging
    setup_monitoring
    setup_backup
    
    # Apply security hardening
    apply_security_hardening
    
    # Install additional plugins
    install_plugins
    
    # Run database migrations
    run_migrations
    
    # Print startup information
    print_startup_info
    
    success "Grafana initialization completed successfully!"
    
    # Start Grafana
    log "Starting Grafana server..."
    exec "$@"
}

# Error handling
trap 'error "Initialization failed on line $LINENO"' ERR

# Run main function with all arguments
main "$@"
