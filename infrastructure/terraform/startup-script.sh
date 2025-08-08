#!/bin/bash

# Vita Strategies VM Startup Script
set -e

# Install Docker and Docker Compose
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh
usermod -aG docker $(whoami)

# Install Docker Compose
curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Clone repository
cd /opt
git clone https://github.com/jamilkigozi/vita-strategies.git
cd vita-strategies

# Fetch secrets and create .env
gcloud secrets versions access latest --secret="vita-db-password" > /tmp/db_pass
gcloud secrets versions access latest --secret="vita-redis-password" > /tmp/redis_pass

cat > .env << EOF
# Database Configuration
POSTGRES_PASSWORD=$(cat /tmp/db_pass)
MYSQL_ROOT_PASSWORD=$(cat /tmp/db_pass)
MARIADB_ROOT_PASSWORD=$(cat /tmp/db_pass)
REDIS_PASSWORD=$(cat /tmp/redis_pass)

# Cloud SQL Configuration
DB_HOST=10.0.0.3
MYSQL_HOST=10.0.0.4
MARIADB_HOST=10.0.0.5
REDIS_HOST=10.0.0.6
EOF

# Clean up temp files
rm /tmp/db_pass /tmp/redis_pass

# Start services
docker-compose -f docker-compose.cloudflare.yml up -d

# Enable services to start on boot
systemctl enable docker