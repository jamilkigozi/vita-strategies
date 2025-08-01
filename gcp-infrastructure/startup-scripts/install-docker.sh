#!/bin/bash

# Vita Strategies Server Setup Script
# This script installs Docker, Docker Compose, and sets up the environment

set -e

echo "Starting Vita Strategies server setup..."

# Update system
apt-get update
apt-get upgrade -y

# Install essential packages
apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    unzip \
    git \
    nginx

# Install Docker
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io

# Install Docker Compose
curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Start and enable Docker
systemctl start docker
systemctl enable docker

# Add ubuntu user to docker group
usermod -aG docker ubuntu

# Install Google Cloud SDK
curl https://sdk.cloud.google.com | bash
exec -l $SHELL

# Create application directory
mkdir -p /opt/vita-strategies
chown ubuntu:ubuntu /opt/vita-strategies

# Create environment file
cat > /opt/vita-strategies/.env << 'EOF'
# This will be populated by deployment script
# Database connections will be configured automatically
EOF

# Set up log rotation
cat > /etc/logrotate.d/vita-strategies << 'EOF'
/opt/vita-strategies/logs/*.log {
    daily
    missingok
    rotate 30
    compress
    notifempty
    create 0644 ubuntu ubuntu
}
EOF

# Create systemd service for auto-start
cat > /etc/systemd/system/vita-strategies.service << 'EOF'
[Unit]
Description=Vita Strategies Platform
Requires=docker.service
After=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=/opt/vita-strategies
ExecStart=/usr/local/bin/docker-compose up -d
ExecStop=/usr/local/bin/docker-compose down
User=ubuntu
Group=ubuntu

[Install]
WantedBy=multi-user.target
EOF

systemctl enable vita-strategies.service

echo "Server setup completed successfully!"
echo "Docker version: $(docker --version)"
echo "Docker Compose version: $(docker-compose --version)"
