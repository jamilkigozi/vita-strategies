#!/bin/bash
# Mattermost Docker Entrypoint
# Handles initialization, configuration, and startup

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${GREEN}🚀 Starting Mattermost Team Communication Platform...${NC}"

# Function to wait for database
wait_for_db() {
    echo -e "${YELLOW}📦 Waiting for PostgreSQL database connection...${NC}"
    
    local host="${POSTGRES_HOST:-localhost}"
    local port="${POSTGRES_PORT:-5432}"
    local user="${MM_SQLSETTINGS_DATASOURCE##*://}"
    user="${user%%:*}"
    local password="${MM_SQLSETTINGS_DATASOURCE#*://}"
    password="${password#*:}"
    password="${password%%@*}"
    local database="${MM_SQLSETTINGS_DATASOURCE##*/}"
    database="${database%%\?*}"
    
    until PGPASSWORD="$password" psql -h "$host" -U "$user" -d "$database" -c "SELECT 1" >/dev/null 2>&1; do
        echo -e "${YELLOW}⏳ Database not ready, waiting 5 seconds...${NC}"
        sleep 5
    done
    
    echo -e "${GREEN}✅ Database connection established${NC}"
}

# Function to generate encryption keys
generate_keys() {
    echo -e "${YELLOW}🔐 Generating encryption keys...${NC}"
    
    # Generate database encryption key if not set
    if [ ! -f "/mattermost/config/.encryption_key" ]; then
        openssl rand -hex 32 > /mattermost/config/.encryption_key
        echo -e "${GREEN}✅ Database encryption key generated${NC}"
    fi
    
    # Generate file salt if not set
    if [ ! -f "/mattermost/config/.file_salt" ]; then
        openssl rand -hex 32 > /mattermost/config/.file_salt
        echo -e "${GREEN}✅ File salt generated${NC}"
    fi
}

# Function to update configuration with environment variables
update_config() {
    echo -e "${YELLOW}⚙️ Updating Mattermost configuration...${NC}"
    
    local config_file="/mattermost/config/config.json"
    local temp_config="/tmp/config.json"
    
    # Read encryption key and salt
    local encryption_key
    local file_salt
    encryption_key=$(cat /mattermost/config/.encryption_key)
    file_salt=$(cat /mattermost/config/.file_salt)
    
    # Update database configuration
    if [ -n "${MM_SQLSETTINGS_DATASOURCE:-}" ]; then
        jq --arg datasource "$MM_SQLSETTINGS_DATASOURCE" \
           '.SqlSettings.DataSource = $datasource' \
           "$config_file" > "$temp_config"
        mv "$temp_config" "$config_file"
    fi
    
    # Update encryption key
    jq --arg key "$encryption_key" \
       '.SqlSettings.AtRestEncryptKey = $key' \
       "$config_file" > "$temp_config"
    mv "$temp_config" "$config_file"
    
    # Update file salt
    jq --arg salt "$file_salt" \
       '.FileSettings.PublicLinkSalt = $salt' \
       "$config_file" > "$temp_config"
    mv "$temp_config" "$config_file"
    
    # Update site URL
    if [ -n "${MM_SERVICESETTINGS_SITEURL:-}" ]; then
        jq --arg siteurl "$MM_SERVICESETTINGS_SITEURL" \
           '.ServiceSettings.SiteURL = $siteurl' \
           "$config_file" > "$temp_config"
        mv "$temp_config" "$config_file"
    fi
    
    # Update SMTP settings if provided
    if [ -n "${MM_EMAILSETTINGS_SMTPSERVER:-}" ]; then
        jq --arg server "$MM_EMAILSETTINGS_SMTPSERVER" \
           --arg port "${MM_EMAILSETTINGS_SMTPPORT:-587}" \
           --arg username "${MM_EMAILSETTINGS_SMTPUSERNAME:-}" \
           --arg password "${MM_EMAILSETTINGS_SMTPPASSWORD:-}" \
           '.EmailSettings.SMTPServer = $server |
            .EmailSettings.SMTPPort = $port |
            .EmailSettings.SMTPUsername = $username |
            .EmailSettings.SMTPPassword = $password' \
           "$config_file" > "$temp_config"
        mv "$temp_config" "$config_file"
    fi
    
    echo -e "${GREEN}✅ Configuration updated${NC}"
}

# Function to create required directories
create_directories() {
    echo -e "${YELLOW}📁 Creating required directories...${NC}"
    
    mkdir -p /mattermost/data
    mkdir -p /mattermost/logs
    mkdir -p /mattermost/plugins
    mkdir -p /mattermost/client/plugins
    mkdir -p /var/log/mattermost
    
    # Set proper permissions
    chown -R mattermost:mattermost /mattermost/data
    chown -R mattermost:mattermost /mattermost/logs
    chown -R mattermost:mattermost /mattermost/plugins
    chown -R mattermost:mattermost /var/log/mattermost
    
    echo -e "${GREEN}✅ Directories created${NC}"
}

# Function to run database migrations
run_migrations() {
    echo -e "${YELLOW}🔄 Running database migrations...${NC}"
    
    # Run Mattermost migrations
    /mattermost/bin/mattermost db migrate || {
        echo -e "${RED}❌ Database migration failed${NC}"
        exit 1
    }
    
    echo -e "${GREEN}✅ Database migrations completed${NC}"
}

# Function to configure plugins
configure_plugins() {
    echo -e "${YELLOW}🔌 Configuring plugins...${NC}"
    
    # Configure Jitsi plugin if enabled
    if [ "${ENABLE_JITSI_PLUGIN:-true}" = "true" ]; then
        echo -e "${BLUE}📹 Configuring Jitsi plugin for video calls...${NC}"
        # Plugin configuration will be handled by Mattermost after startup
    fi
    
    # Configure channel export plugin
    if [ "${ENABLE_EXPORT_PLUGIN:-true}" = "true" ]; then
        echo -e "${BLUE}📊 Configuring channel export plugin...${NC}"
        # Plugin configuration will be handled by Mattermost after startup
    fi
    
    echo -e "${GREEN}✅ Plugins configured${NC}"
}

# Function to set up log rotation
setup_logging() {
    echo -e "${YELLOW}📝 Setting up logging and rotation...${NC}"
    
    # Ensure log files exist
    touch /var/log/mattermost/mattermost.log
    touch /var/log/mattermost/audit.log
    touch /var/log/mattermost/notifications.log
    
    # Set permissions
    chown mattermost:mattermost /var/log/mattermost/*.log
    chmod 644 /var/log/mattermost/*.log
    
    echo -e "${GREEN}✅ Logging configured${NC}"
}

# Function to create admin user if needed
create_admin_user() {
    echo -e "${YELLOW}👤 Checking for admin user...${NC}"
    
    if [ -n "${MM_ADMIN_USERNAME:-}" ] && [ -n "${MM_ADMIN_PASSWORD:-}" ] && [ -n "${MM_ADMIN_EMAIL:-}" ]; then
        echo -e "${BLUE}Creating admin user...${NC}"
        
        # This will be handled after Mattermost starts
        cat > /tmp/create_admin.sh << EOF
#!/bin/bash
sleep 30  # Wait for Mattermost to fully start
/mattermost/bin/mattermost user create --email "${MM_ADMIN_EMAIL}" --username "${MM_ADMIN_USERNAME}" --password "${MM_ADMIN_PASSWORD}" --system_admin || true
EOF
        chmod +x /tmp/create_admin.sh
        /tmp/create_admin.sh &
    fi
    
    echo -e "${GREEN}✅ Admin user setup initiated${NC}"
}

# Function to optimize for production
optimize_production() {
    echo -e "${YELLOW}⚡ Optimizing for production...${NC}"
    
    # Set resource limits
    ulimit -n 65536  # Increase file descriptor limit
    
    # Configure memory settings
    export GOGC=80  # More aggressive garbage collection
    
    echo -e "${GREEN}✅ Production optimizations applied${NC}"
}

# Function to perform health check
health_check() {
    echo -e "${YELLOW}🏥 Performing initial health check...${NC}"
    
    # This will be used by the Docker health check
    # Check if Mattermost is responsive
    if curl -f http://localhost:8065/api/v4/system/ping >/dev/null 2>&1; then
        echo -e "${GREEN}✅ Health check passed${NC}"
        return 0
    else
        echo -e "${YELLOW}⏳ Service not ready yet${NC}"
        return 1
    fi
}

# Main initialization
main() {
    echo -e "${GREEN}🏗️ Vita Strategies Mattermost - Enterprise Team Communication${NC}"
    echo -e "${BLUE}📍 Service URL: ${MM_SERVICESETTINGS_SITEURL:-https://chat.vitastrategies.com}${NC}"
    
    # Create required directories
    create_directories
    
    # Generate encryption keys
    generate_keys
    
    # Wait for database
    wait_for_db
    
    # Update configuration
    update_config
    
    # Set up logging
    setup_logging
    
    # Run database migrations
    run_migrations
    
    # Configure plugins
    configure_plugins
    
    # Create admin user
    create_admin_user
    
    # Production optimizations
    optimize_production
    
    echo -e "${GREEN}🚀 Mattermost initialization complete!${NC}"
    echo -e "${GREEN}📍 Access your team communication at: ${MM_SERVICESETTINGS_SITEURL:-https://chat.vitastrategies.com}${NC}"
}

# Run initialization
main

# Execute the original command
exec "$@"
