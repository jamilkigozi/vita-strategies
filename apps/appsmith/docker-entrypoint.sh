#!/bin/bash
set -euo pipefail

# Docker entrypoint script for Appsmith Internal Tools Platform
# This script handles initialization, configuration, and startup

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')] [APPSMITH-INIT]${NC} $1"
}

error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] [APPSMITH-ERROR]${NC} $1" >&2
}

warn() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] [APPSMITH-WARN]${NC} $1"
}

success() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] [APPSMITH-SUCCESS]${NC} $1"
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
        "APPSMITH_DB_HOST"
        "APPSMITH_DB_NAME"
        "APPSMITH_DB_USERNAME"
        "APPSMITH_DB_PASSWORD"
        "APPSMITH_ENCRYPTION_PASSWORD"
        "APPSMITH_ENCRYPTION_SALT"
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
    local db_host="${APPSMITH_DB_HOST}"
    local db_port="${APPSMITH_DB_PORT:-5432}"
    
    # Wait for database to be ready
    if ! wait_for_service "$db_host" "$db_port" "PostgreSQL"; then
        error "Database is not accessible"
        exit 1
    fi
    
    # Test database connection
    log "Testing database connection..."
    if PGPASSWORD="$APPSMITH_DB_PASSWORD" psql -h "$db_host" -p "$db_port" -U "$APPSMITH_DB_USERNAME" -d "$APPSMITH_DB_NAME" -c "SELECT 1;" > /dev/null 2>&1; then
        success "Database connection successful"
    else
        error "Failed to connect to database"
        exit 1
    fi
    
    # Create database if it doesn't exist
    log "Ensuring database exists..."
    if ! PGPASSWORD="$APPSMITH_DB_PASSWORD" psql -h "$db_host" -p "$db_port" -U "$APPSMITH_DB_USERNAME" -lqt | cut -d \| -f 1 | grep -qw "$APPSMITH_DB_NAME"; then
        log "Creating database $APPSMITH_DB_NAME..."
        PGPASSWORD="$APPSMITH_DB_PASSWORD" createdb -h "$db_host" -p "$db_port" -U "$APPSMITH_DB_USERNAME" "$APPSMITH_DB_NAME"
        success "Database created successfully"
    fi
}

# Function to initialize Redis cache
initialize_redis() {
    if [[ -n "${APPSMITH_REDIS_URL:-}" ]]; then
        log "Checking Redis connectivity..."
        
        # Extract Redis connection details
        local redis_url="${APPSMITH_REDIS_URL}"
        local redis_host=$(echo "$redis_url" | sed 's|redis://||' | cut -d':' -f1)
        local redis_port=$(echo "$redis_url" | sed 's|redis://||' | cut -d':' -f2)
        
        if [[ "$redis_port" == "$redis_host" ]]; then
            redis_port="6379"
        fi
        
        # Wait for Redis to be ready
        if wait_for_service "$redis_host" "$redis_port" "Redis"; then
            # Test Redis connection
            if redis-cli -h "$redis_host" -p "$redis_port" ping > /dev/null 2>&1; then
                success "Redis cache ready"
            else
                warn "Redis connection test failed, continuing without cache"
            fi
        else
            warn "Redis not available, continuing without cache"
        fi
    fi
}

# Function to setup SSO configuration
setup_sso() {
    if [[ "${APPSMITH_OAUTH2_OIDC_ENABLED:-false}" == "true" ]]; then
        log "Configuring OIDC SSO..."
        
        # Check required OIDC variables
        if [[ -z "${KEYCLOAK_URL:-}" ]] || [[ -z "${KEYCLOAK_REALM:-}" ]]; then
            warn "OIDC enabled but Keycloak configuration missing, disabling OIDC"
            export APPSMITH_OAUTH2_OIDC_ENABLED=false
            return
        fi
        
        # Set OIDC configuration
        export APPSMITH_OAUTH2_OIDC_ISSUER="${KEYCLOAK_URL}/realms/${KEYCLOAK_REALM}"
        export APPSMITH_OAUTH2_OIDC_AUTHORIZATION_URL="${KEYCLOAK_URL}/realms/${KEYCLOAK_REALM}/protocol/openid-connect/auth"
        export APPSMITH_OAUTH2_OIDC_TOKEN_URL="${KEYCLOAK_URL}/realms/${KEYCLOAK_REALM}/protocol/openid-connect/token"
        export APPSMITH_OAUTH2_OIDC_USER_INFO_URL="${KEYCLOAK_URL}/realms/${KEYCLOAK_REALM}/protocol/openid-connect/userinfo"
        export APPSMITH_OAUTH2_OIDC_JWK_SET_URL="${KEYCLOAK_URL}/realms/${KEYCLOAK_REALM}/protocol/openid-connect/certs"
        
        success "OIDC SSO configuration completed"
    fi
    
    if [[ "${APPSMITH_SAML_ENABLED:-false}" == "true" ]]; then
        log "Configuring SAML SSO..."
        
        # Check required SAML variables
        if [[ -z "${KEYCLOAK_URL:-}" ]] || [[ -z "${KEYCLOAK_REALM:-}" ]]; then
            warn "SAML enabled but Keycloak configuration missing, disabling SAML"
            export APPSMITH_SAML_ENABLED=false
            return
        fi
        
        # Set SAML configuration
        export APPSMITH_SAML_METADATA_URL="${KEYCLOAK_URL}/realms/${KEYCLOAK_REALM}/protocol/saml/descriptor"
        export APPSMITH_SAML_REDIRECT_URL="https://${APPSMITH_CUSTOM_DOMAIN}/login/saml"
        export APPSMITH_SAML_ENTITY_ID="appsmith"
        
        success "SAML SSO configuration completed"
    fi
}

# Function to setup SMTP configuration
setup_smtp() {
    if [[ "${APPSMITH_MAIL_ENABLED:-false}" == "true" ]]; then
        log "Configuring SMTP..."
        
        if [[ -z "${APPSMITH_MAIL_HOST:-}" ]] || [[ -z "${APPSMITH_MAIL_USERNAME:-}" ]]; then
            warn "SMTP enabled but configuration incomplete, disabling SMTP"
            export APPSMITH_MAIL_ENABLED=false
            return
        fi
        
        success "SMTP configuration completed"
    fi
}

# Function to setup application templates
setup_templates() {
    log "Setting up application templates..."
    
    # Create template directories
    mkdir -p /appsmith-stacks/templates/{admin,customer,analytics,workflow}
    
    # Copy templates if they exist
    if [[ -d /appsmith-stacks/templates && -f /opt/appsmith/scripts/init-templates.sh ]]; then
        chmod +x /opt/appsmith/scripts/init-templates.sh
        /opt/appsmith/scripts/init-templates.sh
    fi
    
    success "Application templates setup completed"
}

# Function to setup custom widgets
setup_widgets() {
    log "Setting up custom widgets..."
    
    # Create widget directory
    mkdir -p /appsmith-stacks/widgets/custom
    
    # Copy custom widgets if they exist
    if [[ -d /appsmith-stacks/widgets ]]; then
        chown -R appsmith:appsmith /appsmith-stacks/widgets
        success "Custom widgets setup completed"
    fi
}

# Function to setup logging
setup_logging() {
    log "Configuring logging..."
    
    # Create log directories
    mkdir -p /var/log/appsmith/{application,access,error,audit}
    chown -R appsmith:appsmith /var/log/appsmith
    
    # Setup log rotation
    if [[ -f /etc/logrotate.d/appsmith ]]; then
        log "Log rotation already configured"
    else
        cat > /etc/logrotate.d/appsmith << EOF
/var/log/appsmith/*.log {
    daily
    rotate 30
    compress
    delaycompress
    missingok
    notifempty
    create 0644 appsmith appsmith
    postrotate
        supervisorctl restart appsmith || true
    endscript
}
EOF
    fi
    
    success "Logging configuration completed"
}

# Function to setup monitoring
setup_monitoring() {
    log "Setting up monitoring..."
    
    # Create monitoring endpoints
    export APPSMITH_DISABLE_TELEMETRY=true
    export APPSMITH_HIDE_WATERMARK=true
    
    # Setup health check endpoint
    mkdir -p /appsmith-stacks/configuration/health
    
    success "Monitoring setup completed"
}

# Function to apply security hardening
apply_security_hardening() {
    log "Applying security hardening..."
    
    # Set secure defaults
    export APPSMITH_CONTENT_SECURITY_POLICY_ENABLED=true
    export APPSMITH_DISABLE_IFRAME_WIDGET_SANDBOX=false
    export APPSMITH_ALLOWED_FRAME_ANCESTORS="'self'"
    
    # Disable unnecessary features
    export APPSMITH_MARKETPLACE_ENABLED=false
    export APPSMITH_SEGMENT_KEY=""
    export APPSMITH_INTERCOM_APP_ID=""
    
    # Set encryption
    if [[ "${APPSMITH_ENCRYPTION_PASSWORD:-changeme}" == "changeme" ]]; then
        warn "Using default encryption password, please change in production"
    fi
    
    success "Security hardening applied"
}

# Function to setup backup
setup_backup() {
    log "Setting up backup configuration..."
    
    # Create backup directory
    mkdir -p /appsmith-stacks/backups
    chown appsmith:appsmith /appsmith-stacks/backups
    
    # Setup backup script
    if [[ -f /opt/appsmith/scripts/backup.sh ]]; then
        chmod +x /opt/appsmith/scripts/backup.sh
        
        # Setup cron job for daily backups if enabled
        if [[ "${APPSMITH_BACKUP_ENABLED:-true}" == "true" ]]; then
            echo "${APPSMITH_BACKUP_SCHEDULE:-0 2 * * *} /opt/appsmith/scripts/backup.sh" | crontab -u appsmith -
            success "Backup configuration completed"
        fi
    fi
}

# Function to initialize application data
initialize_application() {
    log "Initializing application data..."
    
    # Create application directories
    mkdir -p /appsmith-stacks/data/{applications,datasources,pages,actions}
    
    # Set proper permissions
    chown -R appsmith:appsmith /appsmith-stacks/data
    
    # Initialize default organization if needed
    export APPSMITH_SIGNUP_DISABLED=false
    export APPSMITH_SIGNUP_ALLOWED_DOMAINS="${APPSMITH_CUSTOM_DOMAIN}"
    
    success "Application initialization completed"
}

# Function to setup SSL/TLS
setup_ssl() {
    if [[ -n "${APPSMITH_CUSTOM_DOMAIN:-}" ]]; then
        log "Setting up SSL/TLS configuration..."
        
        # Enable SSL redirect
        export APPSMITH_FORCE_SSL=true
        
        success "SSL/TLS configuration completed"
    fi
}

# Function to perform health check
health_check() {
    log "Performing initial health check..."
    
    # Wait a moment for Appsmith to start
    sleep 15
    
    # Check if Appsmith is responding
    if curl -f -s "http://localhost/api/v1/health" > /dev/null; then
        success "Appsmith health check passed"
        return 0
    else
        warn "Appsmith health check failed"
        return 1
    fi
}

# Function to print startup information
print_startup_info() {
    log "=== Appsmith Internal Tools Platform ==="
    log "Version: $(cat /opt/appsmith/VERSION 2>/dev/null || echo 'Unknown')"
    log "Domain: ${APPSMITH_CUSTOM_DOMAIN:-localhost}"
    log "Database: postgres://${APPSMITH_DB_HOST}/${APPSMITH_DB_NAME}"
    log "Redis: ${APPSMITH_REDIS_URL:-disabled}"
    log "OIDC Enabled: ${APPSMITH_OAUTH2_OIDC_ENABLED:-false}"
    log "SAML Enabled: ${APPSMITH_SAML_ENABLED:-false}"
    log "SMTP Enabled: ${APPSMITH_MAIL_ENABLED:-false}"
    log "Backup Enabled: ${APPSMITH_BACKUP_ENABLED:-true}"
    log "========================================"
}

# Main initialization function
main() {
    log "Starting Appsmith initialization..."
    
    # Validate environment
    validate_environment
    
    # Initialize external services
    initialize_database
    initialize_redis
    
    # Setup Appsmith components
    setup_sso
    setup_smtp
    setup_templates
    setup_widgets
    setup_logging
    setup_monitoring
    setup_backup
    setup_ssl
    
    # Apply security hardening
    apply_security_hardening
    
    # Initialize application
    initialize_application
    
    # Print startup information
    print_startup_info
    
    success "Appsmith initialization completed successfully!"
    
    # Start Appsmith
    log "Starting Appsmith server..."
    exec "$@"
}

# Error handling
trap 'error "Initialization failed on line $LINENO"' ERR

# Run main function with all arguments
main "$@"
