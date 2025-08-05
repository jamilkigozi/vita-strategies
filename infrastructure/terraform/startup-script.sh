#!/bin/bash
set -e

# Vita Strategies - GCP Startup Script
# This script runs on VM startup to configure the environment

# Update system
apt-get update && apt-get upgrade -y

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh
usermod -aG docker ubuntu

# Install Docker Compose
curl -L "https://github.com/docker/compose/releases/download/v2.20.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Install Google Cloud SDK
curl -sSL https://sdk.cloud.google.com | bash
exec -l $SHELL

# Install monitoring agent
curl -sSO https://dl.google.com/cloudagents/add-google-cloud-ops-agent-repo.sh
bash add-google-cloud-ops-agent-repo.sh --also-install

# Create directories
mkdir -p /opt/vita-strategies
mkdir -p /var/log/vita-strategies

# Set up environment
cat > /opt/vita-strategies/.env << 'ENV'
# GCP Configuration
PROJECT_ID=vita-strategies-2024
REGION=us-central1
ZONE=us-central1-a

# Database Configuration
DB_HOST=localhost
DB_PORT=5432
DB_NAME=vita_strategies
DB_USER=vita_user
DB_PASSWORD=secure_password

# Redis Configuration
REDIS_HOST=localhost
REDIS_PORT=6379

# SSL Configuration
SSL_CERT_PATH=/etc/ssl/certs/vita-strategies.crt
SSL_KEY_PATH=/etc/ssl/private/vita-strategies.key
ENV

# Install application
cd /opt/vita-strategies
git clone https://github.com/vita-strategies/vita-platform.git .
chmod +x scripts/*.sh

# Start services
./scripts/deploy-complete.sh

# Set up log rotation
cat > /etc/logrotate.d/vita-strategies << 'LOGROTATE'
/var/log/vita-strategies/*.log {
    daily
    rotate 30
    compress
    delaycompress
    missingok
    notifempty
    create 0644 ubuntu ubuntu
    postrotate
        systemctl reload nginx
    endscript
}
LOGROTATE

# Set up monitoring
systemctl enable google-cloud-ops-agent
systemctl start google-cloud-ops-agent

log "GCP startup script completed successfully"
