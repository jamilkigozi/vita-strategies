#!/bin/bash
set -e

# Vita Strategies - GCP Startup Script (Safe Version)
# This script runs on VM startup to configure the environment
# Modified to preserve existing data and containers

# Log function
log() {
  echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1" | tee -a /var/log/vita-startup.log
}

log "Starting Vita Strategies safe startup script"

# Check if this is the first run
FIRST_RUN=false
if [ ! -f "/opt/vita-strategies/.initialized" ]; then
  FIRST_RUN=true
  log "First run detected - performing initial setup"
else
  log "Existing installation detected - preserving data"
fi

# Update system
log "Updating system packages"
apt-get update && apt-get upgrade -y

# Install Docker if not already installed
if ! command -v docker &> /dev/null; then
  log "Installing Docker"
  curl -fsSL https://get.docker.com -o get-docker.sh
  sh get-docker.sh
  usermod -aG docker ubuntu
else
  log "Docker already installed"
fi

# Install Docker Compose if not already installed
if ! command -v docker-compose &> /dev/null; then
  log "Installing Docker Compose"
  curl -L "https://github.com/docker/compose/releases/download/v2.20.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
  chmod +x /usr/local/bin/docker-compose
else
  log "Docker Compose already installed"
fi

# Install Google Cloud SDK if not already installed
if ! command -v gcloud &> /dev/null; then
  log "Installing Google Cloud SDK"
  curl -sSL https://sdk.cloud.google.com | bash
  exec -l $SHELL
else
  log "Google Cloud SDK already installed"
fi

# Install monitoring agent if not already installed
if [ ! -f "/etc/systemd/system/google-cloud-ops-agent.service" ]; then
  log "Installing Google Cloud Ops Agent"
  curl -sSO https://dl.google.com/cloudagents/add-google-cloud-ops-agent-repo.sh
  bash add-google-cloud-ops-agent-repo.sh --also-install
else
  log "Google Cloud Ops Agent already installed"
fi

# Create directories if they don't exist
log "Setting up directories"
mkdir -p /opt/vita-strategies
mkdir -p /var/log/vita-strategies

# Create data directories if they don't exist
if [ "$FIRST_RUN" = true ]; then
  log "Creating data directories"
  mkdir -p /mnt/buckets/{wordpress,erpnext,mattermost,analytics,monitoring,auth,appsmith,vault}
  chown -R ubuntu:ubuntu /mnt/buckets/
fi

# Set up environment if it doesn't exist
if [ ! -f "/opt/vita-strategies/.env" ] || [ "$FIRST_RUN" = true ]; then
  log "Setting up environment file"
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
fi

# Install or update application code
if [ "$FIRST_RUN" = true ]; then
  log "Installing application code"
  cd /opt/vita-strategies
  git clone https://github.com/vita-strategies/vita-platform.git .
  chmod +x scripts/*.sh
else
  log "Updating application code without overwriting configuration"
  cd /opt/vita-strategies
  
  # Backup existing configuration files
  log "Backing up existing configuration files"
  mkdir -p /opt/vita-strategies/backup
  cp docker-compose.yml /opt/vita-strategies/backup/ 2>/dev/null || true
  cp docker-compose.override.yml /opt/vita-strategies/backup/ 2>/dev/null || true
  cp .env /opt/vita-strategies/backup/ 2>/dev/null || true
  
  # Pull latest code but don't overwrite existing files
  log "Pulling latest code"
  git fetch
  git checkout -f main
  git reset --hard origin/main
  
  # Restore configuration files
  log "Restoring configuration files"
  cp /opt/vita-strategies/backup/docker-compose.yml . 2>/dev/null || true
  cp /opt/vita-strategies/backup/docker-compose.override.yml . 2>/dev/null || true
  cp /opt/vita-strategies/backup/.env . 2>/dev/null || true
fi

# Check if containers are already running
RUNNING_CONTAINERS=$(docker ps -q | wc -l)
if [ "$RUNNING_CONTAINERS" -gt 0 ] && [ "$FIRST_RUN" = false ]; then
  log "Containers are already running. Performing gentle update..."
  
  # Pull latest images without disrupting running containers
  log "Pulling latest images"
  cd /opt/vita-strategies
  docker-compose pull
  
  # Update containers one by one to minimize downtime
  log "Updating containers one by one"
  for service in $(docker-compose config --services); do
    log "Updating service: $service"
    docker-compose up -d --no-deps $service
    sleep 5
  done
else
  # Start services using the safe deployment script
  log "Starting services"
  cd /opt/vita-strategies
  ./scripts/deploy-complete.sh
fi

# Set up log rotation if not already configured
if [ ! -f "/etc/logrotate.d/vita-strategies" ] || [ "$FIRST_RUN" = true ]; then
  log "Setting up log rotation"
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
fi

# Set up monitoring
log "Ensuring monitoring is enabled"
systemctl enable google-cloud-ops-agent
systemctl start google-cloud-ops-agent

# Mark as initialized
touch /opt/vita-strategies/.initialized

log "GCP startup script completed successfully"