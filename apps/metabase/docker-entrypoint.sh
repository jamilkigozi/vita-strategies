#!/bin/bash
set -e

# Metabase Production Initialization Script
# Comprehensive startup script for business intelligence platform

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log() {
    echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')] Metabase Init:${NC} $1"
}

warn() {
    echo -e "${YELLOW}[$(date '+%Y-%m-%d %H:%M:%S')] Metabase Warning:${NC} $1"
}

error() {
    echo -e "${RED}[$(date '+%Y-%m-%d %H:%M:%S')] Metabase Error:${NC} $1"
}

info() {
    echo -e "${BLUE}[$(date '+%Y-%m-%d %H:%M:%S')] Metabase Info:${NC} $1"
}

# Function to check if Metabase is running
check_metabase_status() {
    local retries=0
    local max_retries=60  # Increased for Metabase startup time
    
    while [ $retries -lt $max_retries ]; do
        if curl -sf http://127.0.0.1:3000/api/health > /dev/null 2>&1; then
            return 0
        fi
        retries=$((retries + 1))
        sleep 5
    done
    return 1
}

# Function to wait for database
wait_for_database() {
    log "Waiting for PostgreSQL database to be ready..."
    
    local db_host=${MB_DB_HOST:-postgres}
    local db_port=${MB_DB_PORT:-5432}
    local db_name=${MB_DB_DBNAME:-metabase}
    local db_user=${MB_DB_USER:-metabase_user}
    
    if [ -z "$MB_DB_PASS" ]; then
        error "MB_DB_PASS environment variable is required"
        exit 1
    fi
    
    local retries=0
    local max_retries=30
    
    while [ $retries -lt $max_retries ]; do
        if PGPASSWORD="$MB_DB_PASS" psql -h "$db_host" -p "$db_port" -U "$db_user" -d "$db_name" -c "SELECT 1;" > /dev/null 2>&1; then
            log "PostgreSQL database is ready!"
            return 0
        fi
        retries=$((retries + 1))
        info "Waiting for database... ($retries/$max_retries)"
        sleep 2
    done
    
    error "Database not available after $max_retries attempts"
    return 1
}

# Function to setup directories
setup_directories() {
    log "Setting up Metabase directories..."
    
    # Ensure all required directories exist
    mkdir -p /opt/metabase/data
    mkdir -p /opt/metabase/logs
    mkdir -p /opt/metabase/plugins
    mkdir -p /opt/metabase/backup
    mkdir -p /opt/metabase/exports
    mkdir -p /var/log/metabase
    
    # Set proper permissions
    chmod 755 /opt/metabase/data
    chmod 755 /opt/metabase/logs
    chmod 755 /opt/metabase/plugins
    chmod 700 /opt/metabase/backup
    chmod 755 /opt/metabase/exports
    chmod 755 /var/log/metabase
    
    log "Directory setup complete"
}

# Function to configure database connection
configure_database() {
    log "Configuring database connection..."
    
    local db_host=${MB_DB_HOST:-postgres}
    local db_port=${MB_DB_PORT:-5432}
    local db_name=${MB_DB_DBNAME:-metabase}
    
    # Construct the full database URI if not provided
    if [ -z "$MB_DB_CONNECTION_URI" ]; then
        export MB_DB_CONNECTION_URI="postgres://${MB_DB_USER}:${MB_DB_PASS}@${db_host}:${db_port}/${db_name}?ssl=false"
        log "Database URI configured for PostgreSQL"
    fi
    
    # Verify database type is set correctly
    export MB_DB_TYPE="postgres"
    
    log "Database configuration complete"
}

# Function to setup encryption
setup_encryption() {
    log "Setting up encryption configuration..."
    
    if [ -z "$MB_ENCRYPTION_SECRET_KEY" ]; then
        warn "MB_ENCRYPTION_SECRET_KEY not set, generating random key"
        export MB_ENCRYPTION_SECRET_KEY=$(openssl rand -hex 32)
        warn "Generated encryption key: $MB_ENCRYPTION_SECRET_KEY"
        warn "IMPORTANT: Save this key securely for future deployments!"
    fi
    
    log "Encryption configuration complete"
}

# Function to setup admin user
setup_admin_user() {
    log "Setting up Metabase admin configuration..."
    
    if [ -z "$MB_ADMIN_EMAIL" ]; then
        warn "MB_ADMIN_EMAIL not set, admin will need to be configured via UI"
        return 0
    fi
    
    log "Admin email configured: $MB_ADMIN_EMAIL"
}

# Function to configure SAML/SSO
setup_saml_sso() {
    log "Configuring SAML/SSO integration..."
    
    if [ "$MB_SAML_ENABLED" = "true" ]; then
        if [ -z "$MB_SAML_IDENTITY_PROVIDER_URI" ]; then
            error "SAML enabled but MB_SAML_IDENTITY_PROVIDER_URI not set"
            exit 1
        fi
        
        log "SAML SSO enabled with provider: $MB_SAML_IDENTITY_PROVIDER_URI"
        
        # Set default SAML attributes if not configured
        export MB_SAML_ATTRIBUTE_EMAIL=${MB_SAML_ATTRIBUTE_EMAIL:-"email"}
        export MB_SAML_ATTRIBUTE_FIRSTNAME=${MB_SAML_ATTRIBUTE_FIRSTNAME:-"given_name"}
        export MB_SAML_ATTRIBUTE_LASTNAME=${MB_SAML_ATTRIBUTE_LASTNAME:-"family_name"}
        
        log "SAML attributes configured"
    else
        info "SAML SSO not enabled"
    fi
}

# Function to configure email settings
setup_email() {
    log "Configuring email settings..."
    
    if [ -n "$MB_EMAIL_SMTP_HOST" ]; then
        log "Email SMTP configured: $MB_EMAIL_SMTP_HOST:$MB_EMAIL_SMTP_PORT"
        
        # Set default values if not provided
        export MB_EMAIL_SMTP_SECURITY=${MB_EMAIL_SMTP_SECURITY:-"tls"}
        export MB_EMAIL_FROM_NAME=${MB_EMAIL_FROM_NAME:-"Vita Strategies Analytics"}
        
        if [ -z "$MB_EMAIL_FROM_ADDRESS" ]; then
            export MB_EMAIL_FROM_ADDRESS=${MB_ADMIN_EMAIL:-"analytics@vitastrategies.com"}
        fi
        
        log "Email configuration complete"
    else
        info "Email not configured, reports will not be sent via email"
    fi
}

# Function to setup plugins
setup_plugins() {
    log "Setting up Metabase plugins..."
    
    # Create plugins directory if it doesn't exist
    mkdir -p /opt/metabase/plugins
    
    # Check for existing plugins
    if [ "$(ls -A /opt/metabase/plugins)" ]; then
        log "Found existing plugins:"
        ls -la /opt/metabase/plugins/
    else
        info "No plugins found in plugins directory"
    fi
    
    # Set plugins directory environment variable
    export MB_PLUGINS_DIR="/opt/metabase/plugins"
    
    log "Plugin setup complete"
}

# Function to configure caching
setup_caching() {
    log "Configuring query caching..."
    
    # Enable query caching for performance
    export MB_ENABLE_QUERY_CACHING=${MB_ENABLE_QUERY_CACHING:-"true"}
    export MB_QUERY_CACHING_MAX_KB=${MB_QUERY_CACHING_MAX_KB:-"2000"}
    export MB_QUERY_CACHING_TTL_RATIO=${MB_QUERY_CACHING_TTL_RATIO:-"10"}
    export MB_QP_CACHE_BACKEND=${MB_QP_CACHE_BACKEND:-"db"}
    
    log "Caching configuration: Enabled=${MB_ENABLE_QUERY_CACHING}, Max KB=${MB_QUERY_CACHING_MAX_KB}"
}

# Function to configure performance settings
optimize_performance() {
    log "Optimizing performance settings..."
    
    # Calculate optimal memory settings based on container limits
    local available_memory=$(cat /sys/fs/cgroup/memory/memory.limit_in_bytes 2>/dev/null || echo "4294967296")
    local memory_mb=$((available_memory / 1024 / 1024))
    
    # Set heap size to 75% of available memory, with min 1GB and max 4GB
    local heap_size=$((memory_mb * 75 / 100))
    if [ $heap_size -lt 1024 ]; then
        heap_size=1024
    elif [ $heap_size -gt 4096 ]; then
        heap_size=4096
    fi
    
    # Optimize JVM options for Metabase
    export JAVA_OPTS="-server \
        -Xms1g \
        -Xmx${heap_size}m \
        -XX:+UseG1GC \
        -XX:MaxGCPauseMillis=200 \
        -XX:ParallelGCThreads=4 \
        -XX:+DisableExplicitGC \
        -XX:+UseStringDeduplication \
        -XX:+OptimizeStringConcat \
        -XX:+UseCompressedOops \
        -XX:+UseCompressedClassPointers \
        -Djava.awt.headless=true \
        -Djava.net.preferIPv4Stack=true \
        -Dfile.encoding=UTF-8 \
        -Duser.timezone=UTC \
        -Dlogback.configurationFile=/opt/metabase/logback.xml"
    
    # Set connection pool settings
    export MB_APPLICATION_DB_MAX_CONNECTION_POOL_SIZE=${MB_APPLICATION_DB_MAX_CONNECTION_POOL_SIZE:-"15"}
    export MB_DB_MAX_CONNECTION_POOL_SIZE=${MB_DB_MAX_CONNECTION_POOL_SIZE:-"15"}
    
    log "Performance optimized: Heap size ${heap_size}MB, Connection pool size ${MB_APPLICATION_DB_MAX_CONNECTION_POOL_SIZE}"
}

# Function to setup logging
setup_logging() {
    log "Configuring logging..."
    
    # Set log level and file
    export MB_LOG_LEVEL=${MB_LOG_LEVEL:-"INFO"}
    export MB_LOG_FILE=${MB_LOG_FILE:-"/var/log/metabase/metabase.log"}
    export MB_COLORIZE_LOGS="false"
    export MB_EMOJI_IN_LOGS="false"
    
    # Create log file if it doesn't exist
    touch "$MB_LOG_FILE"
    
    log "Logging configured: Level=${MB_LOG_LEVEL}, File=${MB_LOG_FILE}"
}

# Function to start background services
start_background_services() {
    log "Starting background services..."
    
    # Start log rotation
    if command -v logrotate >/dev/null 2>&1; then
        (while true; do
            logrotate /etc/logrotate.d/metabase
            sleep 3600  # Run every hour
        done) &
        log "Log rotation service started"
    fi
    
    # Start backup service if configured
    if [ -f "/opt/metabase/backup.sh" ] && [ -n "$BACKUP_ENABLED" ]; then
        (while true; do
            /opt/metabase/backup.sh
            sleep 86400  # Run daily
        done) &
        log "Backup service started"
    fi
    
    log "Background services started"
}

# Function to run database migration
run_database_migration() {
    log "Checking database migration requirements..."
    
    # Metabase handles migrations automatically during startup
    # This function is for future custom migration scripts
    
    if [ -d "/opt/metabase/scripts/migrations" ]; then
        log "Custom migration scripts found, executing..."
        for script in /opt/metabase/scripts/migrations/*.sh; do
            if [ -f "$script" ]; then
                log "Running migration script: $(basename "$script")"
                bash "$script"
            fi
        done
    fi
    
    log "Database migration check complete"
}

# Function to setup initial configuration
setup_initial_configuration() {
    log "Setting up initial Metabase configuration..."
    
    # Wait for Metabase to be fully ready
    local retries=0
    local max_retries=30
    
    while [ $retries -lt $max_retries ]; do
        if curl -sf http://127.0.0.1:3000/api/health > /dev/null 2>&1; then
            break
        fi
        retries=$((retries + 1))
        info "Waiting for Metabase to be ready... ($retries/$max_retries)"
        sleep 10
    done
    
    if [ $retries -eq $max_retries ]; then
        error "Metabase failed to start properly"
        return 1
    fi
    
    # Run initial configuration scripts
    if [ -d "/opt/metabase/scripts/setup" ]; then
        for script in /opt/metabase/scripts/setup/*.sh; do
            if [ -f "$script" ]; then
                log "Running setup script: $(basename "$script")"
                bash "$script" &
            fi
        done
    fi
    
    log "Initial configuration setup complete"
}

# Function to verify setup
verify_setup() {
    log "Verifying Metabase setup..."
    
    # Check if Metabase is responding
    if curl -sf http://127.0.0.1:3000/api/health > /dev/null 2>&1; then
        log "Metabase health check passed"
    else
        error "Metabase health check failed"
        return 1
    fi
    
    # Check database connectivity
    if curl -sf http://127.0.0.1:3000/api/database > /dev/null 2>&1; then
        log "Database connectivity verified"
    else
        warn "Database connectivity check failed (may be normal for initial setup)"
    fi
    
    log "Setup verification complete"
}

# Main initialization function
main() {
    log "Starting Metabase initialization..."
    
    # Setup environment
    setup_directories
    configure_database
    setup_encryption
    setup_admin_user
    
    # Configure services
    setup_saml_sso
    setup_email
    setup_plugins
    setup_caching
    optimize_performance
    setup_logging
    
    # Wait for dependencies
    wait_for_database
    
    # Database and initial setup
    run_database_migration
    
    # Start background services
    start_background_services
    
    log "Metabase initialization complete!"
    log "Starting Metabase server..."
    
    # Set the main process to run Metabase
    exec java $JAVA_OPTS -jar /opt/metabase/metabase.jar "$@"
}

# Handle script arguments
if [ "$1" = "setup" ]; then
    # Run setup only
    setup_initial_configuration
elif [ -z "$1" ] || [ "$1" = "java" ]; then
    # Run initialization and start Metabase
    main "$@"
else
    # Pass through other commands
    log "Executing command: $*"
    exec "$@"
fi
