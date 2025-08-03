#!/bin/bash
set -e

# Keycloak Production Initialization Script
# Comprehensive startup script for identity and access management platform

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log() {
    echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')] Keycloak Init:${NC} $1"
}

warn() {
    echo -e "${YELLOW}[$(date '+%Y-%m-%d %H:%M:%S')] Keycloak Warning:${NC} $1"
}

error() {
    echo -e "${RED}[$(date '+%Y-%m-%d %H:%M:%S')] Keycloak Error:${NC} $1"
}

info() {
    echo -e "${BLUE}[$(date '+%Y-%m-%d %H:%M:%S')] Keycloak Info:${NC} $1"
}

# Function to check if Keycloak is running
check_keycloak_status() {
    local retries=0
    local max_retries=60  # Increased for Keycloak startup time
    
    while [ $retries -lt $max_retries ]; do
        if curl -sf http://127.0.0.1:8080/health/ready > /dev/null 2>&1; then
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
    
    local db_host=${KC_DB_URL_HOST:-postgres}
    local db_port=${KC_DB_URL_PORT:-5432}
    local db_name=${KC_DB_URL_DATABASE:-keycloak}
    local db_user=${KC_DB_USERNAME:-keycloak_user}
    
    if [ -z "$KC_DB_PASSWORD" ]; then
        error "KC_DB_PASSWORD environment variable is required"
        exit 1
    fi
    
    local retries=0
    local max_retries=30
    
    while [ $retries -lt $max_retries ]; do
        if PGPASSWORD="$KC_DB_PASSWORD" psql -h "$db_host" -p "$db_port" -U "$db_user" -d "$db_name" -c "SELECT 1;" > /dev/null 2>&1; then
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

# Function to check vault integration
check_vault_integration() {
    log "Checking OpenBao/Vault integration..."
    
    if [ -z "$KC_SPI_VAULT_HASHICORP_VAULT_URL" ]; then
        info "Vault integration not configured, skipping"
        return 0
    fi
    
    local vault_url="$KC_SPI_VAULT_HASHICORP_VAULT_URL"
    
    if curl -sf --connect-timeout 10 "$vault_url/v1/sys/health" > /dev/null 2>&1; then
        log "Vault connectivity successful"
        return 0
    else
        warn "Vault not reachable, continuing without vault integration"
        return 0
    fi
}

# Function to setup directories
setup_directories() {
    log "Setting up Keycloak directories..."
    
    # Ensure all required directories exist
    mkdir -p /opt/keycloak/data/export
    mkdir -p /opt/keycloak/data/import
    mkdir -p /opt/keycloak/logs
    mkdir -p /opt/keycloak/backup
    mkdir -p /var/log/keycloak
    mkdir -p /opt/keycloak/themes/vita-strategies
    mkdir -p /opt/keycloak/providers
    
    # Set proper permissions
    chmod 755 /opt/keycloak/data
    chmod 755 /opt/keycloak/logs
    chmod 755 /opt/keycloak/backup
    chmod 755 /var/log/keycloak
    chmod 755 /opt/keycloak/themes
    chmod 755 /opt/keycloak/providers
    
    log "Directory setup complete"
}

# Function to configure database URL
configure_database_url() {
    log "Configuring database connection..."
    
    local db_host=${KC_DB_URL_HOST:-postgres}
    local db_port=${KC_DB_URL_PORT:-5432}
    local db_name=${KC_DB_URL_DATABASE:-keycloak}
    local db_schema=${KC_DB_SCHEMA:-public}
    
    # Construct the full database URL
    export KC_DB_URL="jdbc:postgresql://${db_host}:${db_port}/${db_name}?currentSchema=${db_schema}&ssl=false"
    
    log "Database URL configured: jdbc:postgresql://${db_host}:${db_port}/${db_name}"
}

# Function to setup admin user
setup_admin_user() {
    log "Setting up Keycloak admin user..."
    
    if [ -z "$KEYCLOAK_ADMIN" ]; then
        export KEYCLOAK_ADMIN="admin"
        warn "KEYCLOAK_ADMIN not set, using default: admin"
    fi
    
    if [ -z "$KEYCLOAK_ADMIN_PASSWORD" ]; then
        error "KEYCLOAK_ADMIN_PASSWORD environment variable is required"
        exit 1
    fi
    
    # Set bootstrap admin credentials
    export KC_BOOTSTRAP_ADMIN_USERNAME="$KEYCLOAK_ADMIN"
    export KC_BOOTSTRAP_ADMIN_PASSWORD="$KEYCLOAK_ADMIN_PASSWORD"
    
    log "Admin user configured: $KEYCLOAK_ADMIN"
}

# Function to import realm configurations
import_realm_data() {
    log "Checking for realm import data..."
    
    if [ -d "/opt/keycloak/data/import" ] && [ "$(ls -A /opt/keycloak/data/import)" ]; then
        log "Found realm import data, setting import flag"
        export KC_IMPORT_REALM=true
        
        # List import files
        info "Import files found:"
        ls -la /opt/keycloak/data/import/
    else
        info "No realm import data found, will start with empty configuration"
    fi
}

# Function to configure themes
setup_themes() {
    log "Setting up custom themes..."
    
    if [ -d "/opt/keycloak/themes/vita-strategies" ]; then
        # Copy custom theme files if they exist
        if [ "$(ls -A /opt/keycloak/themes/vita-strategies)" ]; then
            log "Custom Vita Strategies theme found"
            # Set theme as default for new realms
            export KC_SPI_THEME_DEFAULT=vita-strategies
        else
            info "No custom theme files found, using default Keycloak theme"
        fi
    fi
    
    # Ensure theme caching is enabled for performance
    export KC_SPI_THEME_CACHE_THEMES=true
    export KC_SPI_THEME_CACHE_TEMPLATES=true
    export KC_SPI_THEME_STATIC_MAX_AGE=2592000  # 30 days
}

# Function to configure clustering
setup_clustering() {
    log "Configuring clustering and caching..."
    
    # Check if running in Kubernetes
    if [ -n "$KUBERNETES_SERVICE_HOST" ]; then
        log "Kubernetes environment detected, configuring for K8s clustering"
        export KC_CACHE_STACK=kubernetes
        export JGROUPS_DISCOVERY_PROTOCOL=kubernetes.KUBE_PING
        export JGROUPS_DISCOVERY_PROPERTIES="namespace=${KC_NAMESPACE:-keycloak}"
    else
        log "Standalone environment detected, using default clustering"
        export KC_CACHE_STACK=tcp
    fi
    
    # Enable Infinispan caching
    export KC_CACHE=ispn
    
    info "Clustering configuration: Stack=${KC_CACHE_STACK}, Cache=${KC_CACHE}"
}

# Function to configure security settings
setup_security() {
    log "Configuring security settings..."
    
    # TLS configuration
    if [ -f "/opt/keycloak/conf/tls.crt" ] && [ -f "/opt/keycloak/conf/tls.key" ]; then
        log "TLS certificates found, enabling HTTPS"
        export KC_HTTPS_CERTIFICATE_FILE="/opt/keycloak/conf/tls.crt"
        export KC_HTTPS_CERTIFICATE_KEY_FILE="/opt/keycloak/conf/tls.key"
        export KC_HTTPS_PORT=8443
    else
        warn "TLS certificates not found, running in HTTP mode"
        export KC_HTTP_ENABLED=true
        export KC_HTTP_PORT=8080
    fi
    
    # Proxy configuration for reverse proxy deployment
    export KC_PROXY=edge
    export KC_PROXY_ADDRESS_FORWARDING=true
    
    # Hostname configuration
    if [ -n "$KC_HOSTNAME" ]; then
        log "Hostname configured: $KC_HOSTNAME"
        export KC_HOSTNAME_STRICT=false
        export KC_HOSTNAME_STRICT_HTTPS=false
    fi
    
    # Security headers and features
    export KC_FEATURES="token-exchange,admin-fine-grained-authz,recovery-codes,update-email"
    
    log "Security configuration complete"
}

# Function to setup monitoring
setup_monitoring() {
    log "Configuring monitoring and metrics..."
    
    # Enable health and metrics endpoints
    export KC_HEALTH_ENABLED=true
    export KC_METRICS_ENABLED=true
    
    # Configure logging
    export KC_LOG=console,file
    export KC_LOG_LEVEL=${KC_LOG_LEVEL:-INFO}
    export KC_LOG_FILE=/var/log/keycloak/keycloak.log
    export KC_LOG_FORMAT=json
    
    log "Monitoring configuration complete"
}

# Function to optimize JVM settings
optimize_jvm() {
    log "Optimizing JVM settings for production..."
    
    # Calculate optimal memory settings based on container limits
    local available_memory=$(cat /sys/fs/cgroup/memory/memory.limit_in_bytes 2>/dev/null || echo "2147483648")
    local memory_mb=$((available_memory / 1024 / 1024))
    
    # Set heap size to 75% of available memory, with min 512MB and max 2GB
    local heap_size=$((memory_mb * 75 / 100))
    if [ $heap_size -lt 512 ]; then
        heap_size=512
    elif [ $heap_size -gt 2048 ]; then
        heap_size=2048
    fi
    
    # Optimize JVM options for production
    export JAVA_OPTS="-server \
        -Xms512m \
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
        -Duser.timezone=UTC"
    
    log "JVM optimized: Heap size ${heap_size}MB"
}

# Function to run database migration if needed
run_database_migration() {
    log "Checking database migration requirements..."
    
    # Keycloak handles migrations automatically during startup
    # This function is for future custom migration scripts
    
    if [ -d "/opt/keycloak/scripts/migrations" ]; then
        log "Custom migration scripts found, executing..."
        for script in /opt/keycloak/scripts/migrations/*.sh; do
            if [ -f "$script" ]; then
                log "Running migration script: $(basename "$script")"
                bash "$script"
            fi
        done
    fi
    
    log "Database migration check complete"
}

# Function to start background services
start_background_services() {
    log "Starting background services..."
    
    # Start log rotation
    if command -v logrotate >/dev/null 2>&1; then
        (while true; do
            logrotate /etc/logrotate.d/keycloak
            sleep 3600  # Run every hour
        done) &
        log "Log rotation service started"
    fi
    
    # Start backup service if configured
    if [ -f "/opt/keycloak/backup.sh" ] && [ -n "$BACKUP_ENABLED" ]; then
        (while true; do
            /opt/keycloak/backup.sh
            sleep 86400  # Run daily
        done) &
        log "Backup service started"
    fi
    
    # Start metrics collection
    if [ -n "$METRICS_ENABLED" ]; then
        log "Metrics collection enabled"
    fi
    
    log "Background services started"
}

# Function to create initial realm and configuration
setup_initial_configuration() {
    log "Setting up initial Keycloak configuration..."
    
    # Wait for Keycloak to be fully ready
    local retries=0
    local max_retries=30
    
    while [ $retries -lt $max_retries ]; do
        if curl -sf http://127.0.0.1:8080/health/ready > /dev/null 2>&1; then
            break
        fi
        retries=$((retries + 1))
        info "Waiting for Keycloak to be ready... ($retries/$max_retries)"
        sleep 10
    done
    
    if [ $retries -eq $max_retries ]; then
        error "Keycloak failed to start properly"
        return 1
    fi
    
    # Run initial configuration scripts
    if [ -d "/opt/keycloak/scripts/setup" ]; then
        for script in /opt/keycloak/scripts/setup/*.sh; do
            if [ -f "$script" ]; then
                log "Running setup script: $(basename "$script")"
                bash "$script" &
            fi
        done
    fi
    
    log "Initial configuration setup complete"
}

# Main initialization function
main() {
    log "Starting Keycloak initialization..."
    
    # Setup environment
    setup_directories
    optimize_jvm
    configure_database_url
    setup_admin_user
    
    # Configure services
    setup_security
    setup_monitoring
    setup_clustering
    setup_themes
    
    # Wait for dependencies
    wait_for_database
    check_vault_integration
    
    # Database and realm setup
    run_database_migration
    import_realm_data
    
    # Start background services
    start_background_services
    
    log "Keycloak initialization complete!"
    log "Starting Keycloak server..."
    
    # Check if we should start in development mode
    if [ "$KC_DEV_MODE" = "true" ]; then
        log "Starting in development mode"
        exec /opt/keycloak/bin/kc.sh start-dev "$@"
    else
        log "Starting in production mode"
        
        # Build the server if not already optimized
        if [ ! -f "/opt/keycloak/.optimized" ]; then
            log "Building optimized Keycloak configuration..."
            /opt/keycloak/bin/kc.sh build
            touch /opt/keycloak/.optimized
        fi
        
        # Set initial configuration if this is first run
        if [ "$KC_IMPORT_REALM" = "true" ]; then
            # Start server with import
            exec /opt/keycloak/bin/kc.sh start --optimized --import-realm "$@"
        else
            # Start server normally  
            exec /opt/keycloak/bin/kc.sh start --optimized "$@"
        fi
    fi
}

# Handle script arguments
if [ "$1" = "start" ] || [ "$1" = "start-dev" ] || [ -z "$1" ]; then
    # Run initialization and start Keycloak
    main "$@"
else
    # Pass through other commands directly to Keycloak
    log "Executing Keycloak command: $*"
    exec /opt/keycloak/bin/kc.sh "$@"
fi
