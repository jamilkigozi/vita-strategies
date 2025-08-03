#!/bin/bash
set -e

# OpenBao Production Initialization Script
# Comprehensive startup script for secrets management platform

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')] OpenBao Init:${NC} $1"
}

warn() {
    echo -e "${YELLOW}[$(date '+%Y-%m-%d %H:%M:%S')] OpenBao Warning:${NC} $1"
}

error() {
    echo -e "${RED}[$(date '+%Y-%m-%d %H:%M:%S')] OpenBao Error:${NC} $1"
}

info() {
    echo -e "${BLUE}[$(date '+%Y-%m-%d %H:%M:%S')] OpenBao Info:${NC} $1"
}

# Function to check if OpenBao is running
check_openbao_status() {
    local retries=0
    local max_retries=30
    
    while [ $retries -lt $max_retries ]; do
        if curl -sf http://127.0.0.1:8200/v1/sys/health > /dev/null 2>&1; then
            return 0
        fi
        retries=$((retries + 1))
        sleep 2
    done
    return 1
}

# Function to wait for database
wait_for_database() {
    log "Waiting for PostgreSQL database to be ready..."
    
    if [ -z "$POSTGRES_URL" ]; then
        warn "POSTGRES_URL not set, skipping database wait"
        return 0
    fi
    
    # Extract connection details from URL
    local db_host=$(echo $POSTGRES_URL | sed -n 's/.*@\([^:]*\):.*/\1/p')
    local db_port=$(echo $POSTGRES_URL | sed -n 's/.*:\([0-9]*\)\/.*/\1/p')
    
    if [ -z "$db_host" ] || [ -z "$db_port" ]; then
        warn "Could not parse database connection details from POSTGRES_URL"
        return 1
    fi
    
    local retries=0
    local max_retries=30
    
    while [ $retries -lt $max_retries ]; do
        if nc -z $db_host $db_port; then
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

# Function to check GCP KMS access
check_gcp_kms() {
    log "Checking GCP KMS access..."
    
    if [ -z "$GCP_KMS_PROJECT" ]; then
        warn "GCP_KMS_PROJECT not set, skipping KMS check"
        return 0
    fi
    
    if [ ! -f "$GOOGLE_APPLICATION_CREDENTIALS" ]; then
        error "GCP service account key file not found: $GOOGLE_APPLICATION_CREDENTIALS"
        return 1
    fi
    
    # Test GCP authentication
    if command -v gcloud >/dev/null 2>&1; then
        if gcloud auth activate-service-account --key-file="$GOOGLE_APPLICATION_CREDENTIALS" --quiet; then
            log "GCP authentication successful"
            return 0
        else
            error "GCP authentication failed"
            return 1
        fi
    else
        warn "gcloud CLI not available, skipping KMS validation"
        return 0
    fi
}

# Function to validate configuration
validate_config() {
    log "Validating OpenBao configuration..."
    
    if [ ! -f "$OPENBAO_CONFIG_PATH" ]; then
        error "OpenBao configuration file not found: $OPENBAO_CONFIG_PATH"
        return 1
    fi
    
    # Check if openbao binary can validate config
    if openbao server -config="$OPENBAO_CONFIG_PATH" -test-config; then
        log "Configuration validation successful"
        return 0
    else
        error "Configuration validation failed"
        return 1
    fi
}

# Function to setup directories
setup_directories() {
    log "Setting up OpenBao directories..."
    
    # Ensure all required directories exist
    mkdir -p /opt/openbao/data
    mkdir -p /opt/openbao/logs
    mkdir -p /opt/openbao/audit
    mkdir -p /opt/openbao/backup
    mkdir -p /var/log/openbao
    
    # Set proper permissions
    chmod 700 /opt/openbao/data
    chmod 755 /opt/openbao/logs
    chmod 700 /opt/openbao/audit
    chmod 700 /opt/openbao/backup
    chmod 755 /var/log/openbao
    
    log "Directory setup complete"
}

# Function to initialize OpenBao
initialize_openbao() {
    log "Checking OpenBao initialization status..."
    
    # Check if already initialized
    if openbao status > /dev/null 2>&1; then
        local init_status=$(openbao status -format=json | jq -r '.initialized')
        if [ "$init_status" = "true" ]; then
            log "OpenBao is already initialized"
            return 0
        fi
    fi
    
    log "Initializing OpenBao..."
    
    # Initialize with appropriate key shares
    local init_output
    if init_output=$(openbao operator init \
        -key-shares=5 \
        -key-threshold=3 \
        -recovery-shares=5 \
        -recovery-threshold=3 \
        -format=json); then
        
        # Save initialization data securely
        echo "$init_output" > /opt/openbao/data/init.json
        chmod 600 /opt/openbao/data/init.json
        
        # Extract root token and unseal keys
        local root_token=$(echo "$init_output" | jq -r '.root_token')
        local unseal_keys=$(echo "$init_output" | jq -r '.unseal_keys_b64[]')
        
        log "OpenBao initialization successful"
        log "Root token and unseal keys saved to /opt/openbao/data/init.json"
        warn "IMPORTANT: Backup the initialization data securely!"
        
        # Auto-unseal if using GCP KMS
        if [ "$OPENBAO_SEAL_TYPE" = "gcpckms" ]; then
            log "Using GCP KMS auto-unseal, no manual unsealing required"
        else
            # Unseal with first 3 keys for development
            local key_count=0
            echo "$unseal_keys" | while read -r key && [ $key_count -lt 3 ]; do
                openbao operator unseal "$key"
                key_count=$((key_count + 1))
            done
            log "OpenBao unsealed successfully"
        fi
        
        return 0
    else
        error "OpenBao initialization failed"
        return 1
    fi
}

# Function to setup authentication methods
setup_auth_methods() {
    log "Setting up authentication methods..."
    
    # Check if we have a root token
    local root_token=""
    if [ -f "/opt/openbao/data/init.json" ]; then
        root_token=$(jq -r '.root_token' /opt/openbao/data/init.json)
    fi
    
    if [ -z "$root_token" ]; then
        warn "No root token available, skipping auth method setup"
        return 0
    fi
    
    export OPENBAO_TOKEN="$root_token"
    
    # Enable userpass auth method
    if ! openbao auth list | grep -q "userpass"; then
        log "Enabling userpass authentication..."
        openbao auth enable userpass
    fi
    
    # Enable JWT/OIDC auth method for service integration
    if ! openbao auth list | grep -q "jwt"; then
        log "Enabling JWT authentication..."
        openbao auth enable jwt
    fi
    
    # Enable Kubernetes auth method if in k8s environment
    if [ -n "$KUBERNETES_SERVICE_HOST" ]; then
        if ! openbao auth list | grep -q "kubernetes"; then
            log "Enabling Kubernetes authentication..."
            openbao auth enable kubernetes
        fi
    fi
    
    log "Authentication methods setup complete"
}

# Function to setup secret engines
setup_secret_engines() {
    log "Setting up secret engines..."
    
    # Check if we have a root token
    local root_token=""
    if [ -f "/opt/openbao/data/init.json" ]; then
        root_token=$(jq -r '.root_token' /opt/openbao/data/init.json)
    fi
    
    if [ -z "$root_token" ]; then
        warn "No root token available, skipping secret engine setup"
        return 0
    fi
    
    export OPENBAO_TOKEN="$root_token"
    
    # Enable KV v2 secret engine for application secrets
    if ! openbao secrets list | grep -q "secret/"; then
        log "Enabling KV v2 secret engine..."
        openbao secrets enable -path=secret kv-v2
    fi
    
    # Enable database secret engine for dynamic credentials
    if ! openbao secrets list | grep -q "database/"; then
        log "Enabling database secret engine..."
        openbao secrets enable database
    fi
    
    # Enable PKI secret engine for certificates
    if ! openbao secrets list | grep -q "pki/"; then
        log "Enabling PKI secret engine..."
        openbao secrets enable pki
        openbao secrets tune -max-lease-ttl=8760h pki
    fi
    
    # Enable transit secret engine for encryption
    if ! openbao secrets list | grep -q "transit/"; then
        log "Enabling transit secret engine..."
        openbao secrets enable transit
    fi
    
    log "Secret engines setup complete"
}

# Function to configure database connections
configure_database_connections() {
    log "Configuring database connections..."
    
    if [ -z "$POSTGRES_URL" ]; then
        warn "POSTGRES_URL not set, skipping database configuration"
        return 0
    fi
    
    # Check if we have a root token
    local root_token=""
    if [ -f "/opt/openbao/data/init.json" ]; then
        root_token=$(jq -r '.root_token' /opt/openbao/data/init.json)
    fi
    
    if [ -z "$root_token" ]; then
        warn "No root token available, skipping database configuration"
        return 0
    fi
    
    export OPENBAO_TOKEN="$root_token"
    
    # Configure PostgreSQL connection
    log "Configuring PostgreSQL connection..."
    openbao write database/config/postgresql \
        plugin_name=postgresql-database-plugin \
        connection_url="$POSTGRES_URL" \
        allowed_roles="readonly,readwrite"
    
    # Create database roles
    log "Creating database roles..."
    openbao write database/roles/readonly \
        db_name=postgresql \
        creation_statements="CREATE ROLE \"{{name}}\" WITH LOGIN PASSWORD '{{password}}' VALID UNTIL '{{expiration}}'; GRANT SELECT ON ALL TABLES IN SCHEMA public TO \"{{name}}\";" \
        default_ttl="1h" \
        max_ttl="24h"
    
    openbao write database/roles/readwrite \
        db_name=postgresql \
        creation_statements="CREATE ROLE \"{{name}}\" WITH LOGIN PASSWORD '{{password}}' VALID UNTIL '{{expiration}}'; GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO \"{{name}}\";" \
        default_ttl="1h" \
        max_ttl="24h"
    
    log "Database configuration complete"
}

# Function to apply policies
apply_policies() {
    log "Applying OpenBao policies..."
    
    # Check if we have a root token
    local root_token=""
    if [ -f "/opt/openbao/data/init.json" ]; then
        root_token=$(jq -r '.root_token' /opt/openbao/data/init.json)
    fi
    
    if [ -z "$root_token" ]; then
        warn "No root token available, skipping policy application"
        return 0
    fi
    
    export OPENBAO_TOKEN="$root_token"
    
    # Apply policies from files
    for policy_file in /opt/openbao/policies/*.hcl; do
        if [ -f "$policy_file" ]; then
            local policy_name=$(basename "$policy_file" .hcl)
            log "Applying policy: $policy_name"
            openbao policy write "$policy_name" "$policy_file"
        fi
    done
    
    log "Policy application complete"
}

# Function to setup audit logging
setup_audit_logging() {
    log "Setting up audit logging..."
    
    # Check if we have a root token
    local root_token=""
    if [ -f "/opt/openbao/data/init.json" ]; then
        root_token=$(jq -r '.root_token' /opt/openbao/data/init.json)
    fi
    
    if [ -z "$root_token" ]; then
        warn "No root token available, skipping audit setup"
        return 0
    fi
    
    export OPENBAO_TOKEN="$root_token"
    
    # Enable file audit device
    if ! openbao audit list | grep -q "file/"; then
        log "Enabling file audit device..."
        openbao audit enable file file_path="$OPENBAO_AUDIT_FILE"
    fi
    
    log "Audit logging setup complete"
}

# Function to create initial admin user
create_admin_user() {
    log "Creating initial admin user..."
    
    # Check if we have a root token
    local root_token=""
    if [ -f "/opt/openbao/data/init.json" ]; then
        root_token=$(jq -r '.root_token' /opt/openbao/data/init.json)
    fi
    
    if [ -z "$root_token" ]; then
        warn "No root token available, skipping admin user creation"
        return 0
    fi
    
    export OPENBAO_TOKEN="$root_token"
    
    # Create admin user if credentials are provided
    if [ -n "$OPENBAO_ADMIN_USER" ] && [ -n "$OPENBAO_ADMIN_PASSWORD" ]; then
        log "Creating admin user: $OPENBAO_ADMIN_USER"
        openbao write auth/userpass/users/"$OPENBAO_ADMIN_USER" \
            password="$OPENBAO_ADMIN_PASSWORD" \
            policies="admin"
        log "Admin user created successfully"
    else
        warn "OPENBAO_ADMIN_USER or OPENBAO_ADMIN_PASSWORD not set, skipping admin user creation"
    fi
}

# Function to start background services
start_background_services() {
    log "Starting background services..."
    
    # Start log rotation
    if command -v logrotate >/dev/null 2>&1; then
        (while true; do
            logrotate /etc/logrotate.d/openbao
            sleep 3600  # Run every hour
        done) &
        log "Log rotation service started"
    fi
    
    # Start backup service if configured
    if [ -f "/opt/openbao/backup.sh" ]; then
        (while true; do
            /opt/openbao/backup.sh
            sleep 86400  # Run daily
        done) &
        log "Backup service started"
    fi
    
    log "Background services started"
}

# Main initialization function
main() {
    log "Starting OpenBao initialization..."
    
    # Validate environment
    setup_directories
    
    # Wait for dependencies
    wait_for_database
    check_gcp_kms
    
    # Validate configuration
    validate_config
    
    # Start OpenBao server in background
    log "Starting OpenBao server..."
    openbao server -config="$OPENBAO_CONFIG_PATH" > "$OPENBAO_LOG_FILE" 2>&1 &
    local server_pid=$!
    
    # Wait for server to start
    if check_openbao_status; then
        log "OpenBao server started successfully (PID: $server_pid)"
    else
        error "OpenBao server failed to start"
        exit 1
    fi
    
    # Initialize and configure OpenBao
    initialize_openbao
    setup_auth_methods
    setup_secret_engines
    configure_database_connections
    apply_policies
    setup_audit_logging
    create_admin_user
    
    # Start background services
    start_background_services
    
    log "OpenBao initialization complete!"
    log "OpenBao is running at: $OPENBAO_ADDR"
    log "Health check endpoint: $OPENBAO_ADDR/v1/sys/health"
    
    # Keep the script running if this is the main process
    if [ $$ -eq 1 ]; then
        wait $server_pid
    fi
}

# Run main function
main "$@"
