#!/bin/bash
# WordPress Docker Entrypoint
# Handles initialization, security, and startup

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}🚀 Starting WordPress container...${NC}"

# Function to wait for database
wait_for_db() {
    echo -e "${YELLOW}📦 Waiting for database connection...${NC}"
    
    until mysql -h"$WORDPRESS_DB_HOST" -u"$WORDPRESS_DB_USER" -p"$WORDPRESS_DB_PASSWORD" -e "SELECT 1" >/dev/null 2>&1; do
        echo -e "${YELLOW}⏳ Database not ready, waiting 5 seconds...${NC}"
        sleep 5
    done
    
    echo -e "${GREEN}✅ Database connection established${NC}"
}

# Function to install WordPress if not already installed
install_wordpress() {
    if ! $(wp core is-installed --allow-root --path=/var/www/html 2>/dev/null); then
        echo -e "${YELLOW}📥 Installing WordPress...${NC}"
        
        wp core install \
            --url="${WP_HOME:-https://vitastrategies.com}" \
            --title="${WP_TITLE:-Vita Strategies}" \
            --admin_user="${WP_ADMIN_USER:-admin}" \
            --admin_password="${WP_ADMIN_PASSWORD:-admin123}" \
            --admin_email="${WP_ADMIN_EMAIL:-admin@vitastrategies.com}" \
            --allow-root \
            --path=/var/www/html
        
        echo -e "${GREEN}✅ WordPress installed successfully${NC}"
    else
        echo -e "${GREEN}✅ WordPress already installed${NC}"
    fi
}

# Function to activate essential plugins
activate_plugins() {
    echo -e "${YELLOW}🔌 Activating essential plugins...${NC}"
    
    wp plugin activate \
        wordfence \
        redis-cache \
        wordpress-seo \
        updraftplus \
        --allow-root \
        --path=/var/www/html 2>/dev/null || true
    
    echo -e "${GREEN}✅ Plugins activated${NC}"
}

# Function to configure Redis cache
configure_redis() {
    echo -e "${YELLOW}⚡ Configuring Redis cache...${NC}"
    
    # Enable Redis object cache
    wp redis enable --allow-root --path=/var/www/html 2>/dev/null || true
    
    echo -e "${GREEN}✅ Redis cache configured${NC}"
}

# Function to set up proper permissions
setup_permissions() {
    echo -e "${YELLOW}🔒 Setting up file permissions...${NC}"
    
    # WordPress core files - read only
    find /var/www/html -type f -name "*.php" -not -path "*/wp-content/*" -exec chmod 644 {} \;
    
    # wp-config.php - restricted
    chmod 600 /var/www/html/wp-config.php
    
    # wp-content - writable
    chmod -R 755 /var/www/html/wp-content
    chown -R www-data:www-data /var/www/html/wp-content
    
    # Uploads directory
    chmod 755 /var/www/html/wp-content/uploads
    
    echo -e "${GREEN}✅ Permissions configured${NC}"
}

# Function to create required directories
create_directories() {
    echo -e "${YELLOW}📁 Creating required directories...${NC}"
    
    mkdir -p /var/www/html/wp-content/uploads
    mkdir -p /var/www/html/wp-content/cache
    mkdir -p /var/www/html/wp-content/backups
    mkdir -p /var/log/php
    
    chown -R www-data:www-data /var/www/html/wp-content
    
    echo -e "${GREEN}✅ Directories created${NC}"
}

# Function to configure WordPress settings
configure_wordpress() {
    echo -e "${YELLOW}⚙️ Configuring WordPress settings...${NC}"
    
    # Set timezone
    wp option update timezone_string "UTC" --allow-root --path=/var/www/html 2>/dev/null || true
    
    # Set permalink structure
    wp rewrite structure '/%postname%/' --allow-root --path=/var/www/html 2>/dev/null || true
    
    # Update site URLs
    wp option update home "${WP_HOME:-https://vitastrategies.com}" --allow-root --path=/var/www/html 2>/dev/null || true
    wp option update siteurl "${WP_SITEURL:-https://vitastrategies.com}" --allow-root --path=/var/www/html 2>/dev/null || true
    
    # Activate default theme
    wp theme activate astra --allow-root --path=/var/www/html 2>/dev/null || true
    
    echo -e "${GREEN}✅ WordPress configured${NC}"
}

# Main initialization
main() {
    echo -e "${GREEN}🏗️ Vita Strategies WordPress - Production Ready${NC}"
    
    # Create required directories
    create_directories
    
    # Wait for database
    wait_for_db
    
    # Install WordPress if needed
    install_wordpress
    
    # Configure WordPress
    configure_wordpress
    
    # Activate plugins
    activate_plugins
    
    # Configure Redis
    configure_redis
    
    # Set permissions
    setup_permissions
    
    echo -e "${GREEN}🚀 WordPress initialization complete!${NC}"
    echo -e "${GREEN}📍 Site available at: ${WP_HOME:-https://vitastrategies.com}${NC}"
}

# Run initialization
main

# Execute the original command
exec "$@"
