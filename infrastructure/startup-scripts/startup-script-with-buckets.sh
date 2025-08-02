#!/bin/bash

# =============================================================================
# VITA STRATEGIES - VM STARTUP SCRIPT WITH BUCKET INTEGRATION
# =============================================================================
# Sets up Docker + automatic bucket syncing
# =============================================================================

set -e

echo "🚀 Starting Vita Strategies VM setup with bucket integration..."

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
    cron

# Install Docker
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# Install Docker Compose
curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Start and enable Docker
systemctl start docker
systemctl enable docker

# Add ubuntu user to docker group
usermod -aG docker ubuntu

# Install and configure Google Cloud SDK
curl https://sdk.cloud.google.com | bash
source /home/ubuntu/.bashrc

# Mount additional data disk
mkdir -p /opt/vita-data
if [ -b /dev/disk/by-id/google-vita-data ]; then
    # Format disk if not already formatted
    if ! blkid /dev/disk/by-id/google-vita-data; then
        mkfs.ext4 /dev/disk/by-id/google-vita-data
    fi
    
    # Mount disk
    mount /dev/disk/by-id/google-vita-data /opt/vita-data
    
    # Add to fstab for permanent mounting
    echo "/dev/disk/by-id/google-vita-data /opt/vita-data ext4 defaults 0 0" >> /etc/fstab
fi

# Create application directory structure
mkdir -p /opt/vita-data/{docker-volumes,backups,logs,assets}
mkdir -p /opt/vita-strategies
chown -R ubuntu:ubuntu /opt/vita-data /opt/vita-strategies

# =============================================================================
# BUCKET INTEGRATION SETUP
# =============================================================================

# Create bucket sync script
cat > /opt/vita-strategies/sync-buckets.sh << 'EOF'
#!/bin/bash

# Vita Strategies - Bucket Sync Script
# Syncs Docker volumes to GCS buckets for easy access

ENVIRONMENT="production"
DATE=$(date +%Y%m%d_%H%M%S)

echo "📦 Starting bucket sync at $(date)"

# Sync ERPNext data to bucket
echo "Syncing ERPNext data..."
if [ -d "/var/lib/docker/volumes/vita-strategies_erpnext_db_data/_data" ]; then
    tar -czf /opt/vita-data/backups/erpnext_db_${DATE}.tar.gz -C /var/lib/docker/volumes/vita-strategies_erpnext_db_data/_data .
    gsutil cp /opt/vita-data/backups/erpnext_db_${DATE}.tar.gz gs://vita-strategies-erpnext-${ENVIRONMENT}/database/
fi

if [ -d "/var/lib/docker/volumes/vita-strategies_erpnext_sites/_data" ]; then
    tar -czf /opt/vita-data/backups/erpnext_sites_${DATE}.tar.gz -C /var/lib/docker/volumes/vita-strategies_erpnext_sites/_data .
    gsutil cp /opt/vita-data/backups/erpnext_sites_${DATE}.tar.gz gs://vita-strategies-erpnext-${ENVIRONMENT}/sites/
fi

# Sync Metabase data
echo "Syncing Metabase analytics..."
if [ -d "/var/lib/docker/volumes/vita-strategies_metabase_data/_data" ]; then
    tar -czf /opt/vita-data/backups/metabase_${DATE}.tar.gz -C /var/lib/docker/volumes/vita-strategies_metabase_data/_data .
    gsutil cp /opt/vita-data/backups/metabase_${DATE}.tar.gz gs://vita-strategies-analytics-${ENVIRONMENT}/
fi

# Sync Grafana dashboards
echo "Syncing Grafana dashboards..."
if [ -d "/var/lib/docker/volumes/vita-strategies_grafana_data/_data" ]; then
    tar -czf /opt/vita-data/backups/grafana_${DATE}.tar.gz -C /var/lib/docker/volumes/vita-strategies_grafana_data/_data .
    gsutil cp /opt/vita-data/backups/grafana_${DATE}.tar.gz gs://vita-strategies-analytics-${ENVIRONMENT}/grafana/
fi

# Sync team files (Mattermost)
echo "Syncing team files..."
if [ -d "/var/lib/docker/volumes/vita-strategies_mattermost_data/_data" ]; then
    tar -czf /opt/vita-data/backups/mattermost_${DATE}.tar.gz -C /var/lib/docker/volumes/vita-strategies_mattermost_data/_data .
    gsutil cp /opt/vita-data/backups/mattermost_${DATE}.tar.gz gs://vita-strategies-team-files-${ENVIRONMENT}/
fi

# Clean up old local backups (keep last 3)
find /opt/vita-data/backups -name "*.tar.gz" -type f -mtime +3 -delete

echo "✅ Bucket sync completed at $(date)"
EOF

chmod +x /opt/vita-strategies/sync-buckets.sh

# =============================================================================
# AUTOMATED BUCKET SYNC SCHEDULE
# =============================================================================

# Create cron job for automated backups
cat > /tmp/vita-crontab << 'EOF'
# Vita Strategies Automated Backups
# Sync data to buckets every 4 hours
0 */4 * * * /opt/vita-strategies/sync-buckets.sh >> /opt/vita-data/logs/sync.log 2>&1

# Daily full backup at 2 AM
0 2 * * * /opt/vita-strategies/sync-buckets.sh >> /opt/vita-data/logs/daily-backup.log 2>&1
EOF

crontab -u ubuntu /tmp/vita-crontab

# =============================================================================
# BUCKET ACCESS HELPER SCRIPTS
# =============================================================================

# Create bucket access script for easy data management
cat > /opt/vita-strategies/bucket-access.sh << 'EOF'
#!/bin/bash

# Vita Strategies - Bucket Access Helper
# Quick commands to access your data in buckets

ENVIRONMENT="production"

case "$1" in
    "list-erpnext")
        echo "📊 ERPNext Data:"
        gsutil ls gs://vita-strategies-erpnext-${ENVIRONMENT}/
        ;;
    "list-analytics")
        echo "📈 Analytics Data:"
        gsutil ls gs://vita-strategies-analytics-${ENVIRONMENT}/
        ;;
    "list-team-files")
        echo "👥 Team Files:"
        gsutil ls gs://vita-strategies-team-files-${ENVIRONMENT}/
        ;;
    "download-erpnext")
        echo "Downloading latest ERPNext backup..."
        gsutil cp gs://vita-strategies-erpnext-${ENVIRONMENT}/database/* /opt/vita-data/downloads/
        ;;
    "browse")
        echo "🌐 Bucket URLs:"
        echo "ERPNext: https://console.cloud.google.com/storage/browser/vita-strategies-erpnext-${ENVIRONMENT}"
        echo "Analytics: https://console.cloud.google.com/storage/browser/vita-strategies-analytics-${ENVIRONMENT}"
        echo "Team Files: https://console.cloud.google.com/storage/browser/vita-strategies-team-files-${ENVIRONMENT}"
        echo "Assets: https://console.cloud.google.com/storage/browser/vita-strategies-assets-${ENVIRONMENT}"
        ;;
    *)
        echo "Vita Strategies Bucket Access"
        echo "Usage: $0 {list-erpnext|list-analytics|list-team-files|download-erpnext|browse}"
        ;;
esac
EOF

chmod +x /opt/vita-strategies/bucket-access.sh

# =============================================================================
# DOCKER COMPOSE SETUP
# =============================================================================

# Create environment file
cat > /opt/vita-strategies/.env << 'EOF'
# Vita Strategies Production Environment
ENVIRONMENT=production
DOMAIN=vitastrategies.com

# Database passwords
MYSQL_ROOT_PASSWORD=vita_secure_2024
POSTGRES_PASSWORD=VitaStrategies2024!PostgreSQL
REDIS_PASSWORD=VitaStrategies2024!Redis

# Service passwords (from CREDENTIALS.md)
GRAFANA_ADMIN_PASSWORD=VitaStrategies2024!Grafana
KEYCLOAK_ADMIN_PASSWORD=WQoMn2/jMqTXcH/b93Me1MRw7fEXnrfkGfwwfrwV5gI=
EOF

# Create Docker Compose service
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

echo "✅ VM setup completed with bucket integration!"
echo "📦 Buckets will sync every 4 hours automatically"
echo "🔧 Use /opt/vita-strategies/bucket-access.sh browse to see your data"
