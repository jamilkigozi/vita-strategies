# Fresh Deployment Plan - Vita Strategies Platform

## Pre-Deployment Checklist

### Infrastructure Requirements
- [ ] **Server Specifications**
  - Minimum: 16GB RAM, 8 CPU cores, 200GB SSD
  - Recommended: 32GB RAM, 16 CPU cores, 500GB SSD
  - Network: 1Gbps connection, static IP

- [ ] **Operating System**
  - Ubuntu 22.04 LTS (recommended)
  - Docker 24.0+ installed
  - Docker Compose 2.20+ installed

- [ ] **Domain Configuration**
  - DNS records configured for all subdomains
  - SSL certificates ready (Let's Encrypt or commercial)
  - Firewall rules configured (ports 80, 443, 22)

- [ ] **Security Preparation**
  - SSH key-based authentication configured
  - Non-root user with sudo privileges
  - Basic security hardening completed

## Deployment Steps

### Phase 1: Environment Preparation (30 minutes)

#### 1.1 System Updates
```bash
# Update system packages
sudo apt update && sudo apt upgrade -y

# Install required packages
sudo apt install -y curl wget git htop vim ufw fail2ban

# Configure firewall
sudo ufw allow ssh
sudo ufw allow http
sudo ufw allow https
sudo ufw --force enable
```

#### 1.2 Docker Installation
```bash
# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Add user to docker group
sudo usermod -aG docker $USER
newgrp docker

# Install Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Verify installation
docker --version
docker-compose --version
```

#### 1.3 System Optimization
```bash
# Increase file descriptor limits
echo "* soft nofile 65536" | sudo tee -a /etc/security/limits.conf
echo "* hard nofile 65536" | sudo tee -a /etc/security/limits.conf

# Configure swap (if needed)
sudo fallocate -l 4G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab

# Optimize kernel parameters
echo "vm.max_map_count=262144" | sudo tee -a /etc/sysctl.conf
sudo sysctl -p
```

### Phase 2: Application Deployment (45 minutes)

#### 2.1 Repository Setup
```bash
# Clone repository
git clone https://github.com/jamilkigozi/vita-strategies.git
cd vita-strategies

# Create production environment file
cp .env.example .env
```

#### 2.2 Configuration Customization
```bash
# Edit environment variables
nano .env

# Required changes:
# - Update all passwords
# - Set correct domain names
# - Configure email settings
# - Set timezone and locale
```

#### 2.3 SSL Certificate Setup
```bash
# Install Certbot
sudo apt install certbot -y

# Stop any running services on port 80/443
sudo systemctl stop apache2 nginx 2>/dev/null || true

# Generate certificates for all domains
domains=(
    "erp.yourdomain.com"
    "windmill.yourdomain.com"
    "analytics.yourdomain.com"
    "monitoring.yourdomain.com"
    "chat.yourdomain.com"
)

for domain in "${domains[@]}"; do
    sudo certbot certonly --standalone -d $domain --non-interactive --agree-tos --email admin@yourdomain.com
done

# Copy certificates to project directory
sudo mkdir -p ./ssl
for domain in "${domains[@]}"; do
    sudo cp /etc/letsencrypt/live/$domain/fullchain.pem ./ssl/${domain}_fullchain.pem
    sudo cp /etc/letsencrypt/live/$domain/privkey.pem ./ssl/${domain}_privkey.pem
done
sudo chown -R $USER:$USER ./ssl

# Generate DH parameters
openssl dhparam -out ./ssl/dhparam.pem 2048
```

#### 2.4 Service Deployment
```bash
# Create required directories
mkdir -p logs backups

# Deploy services
docker-compose up -d

# Verify deployment
docker-compose ps
docker-compose logs --tail=50
```

### Phase 3: Service Configuration (60 minutes)

#### 3.1 ERPNext Setup
```bash
# Wait for ERPNext to be ready
sleep 120

# Access ERPNext setup wizard
echo "1. Open http://erp.yourdomain.com"
echo "2. Complete setup wizard with:"
echo "   - Administrator email: admin@yourdomain.com"
echo "   - Password: [secure password]"
echo "   - Company name: Vita Strategies"
echo "   - Country: [your country]"
echo "   - Timezone: [your timezone]"

# Wait for user to complete setup
read -p "Press Enter after completing ERPNext setup..."
```

#### 3.2 Grafana Configuration
```bash
# Get Grafana admin password
echo "Grafana admin password: vita_admin_2024"
echo "1. Open http://monitoring.yourdomain.com"
echo "2. Login with admin/vita_admin_2024"
echo "3. Change password immediately"
echo "4. Import dashboards from monitoring/dashboards/"

# Wait for user to complete setup
read -p "Press Enter after completing Grafana setup..."
```

#### 3.3 Other Services Setup
```bash
echo "Complete setup for remaining services:"
echo "- Windmill: http://windmill.yourdomain.com"
echo "- Metabase: http://analytics.yourdomain.com"
echo "- Mattermost: http://chat.yourdomain.com"

# Wait for user to complete all setups
read -p "Press Enter after completing all service setups..."
```

### Phase 4: Backup and Monitoring Setup (30 minutes)

#### 4.1 Backup Configuration
```bash
# Create backup script
cat > backup-script.sh << 'EOF'
#!/bin/bash
BACKUP_DIR="/var/backups/vita-strategies"
DATE=$(date +%Y%m%d_%H%M%S)

mkdir -p $BACKUP_DIR

# Backup databases
docker-compose exec -T erpnext-db mysqldump -u root -p$MYSQL_ROOT_PASSWORD erpnext > $BACKUP_DIR/erpnext_$DATE.sql
docker-compose exec -T windmill-db pg_dump -U windmill windmill > $BACKUP_DIR/windmill_$DATE.sql
docker-compose exec -T mattermost-db pg_dump -U mattermost mattermost > $BACKUP_DIR/mattermost_$DATE.sql

# Backup application data
tar -czf $BACKUP_DIR/volumes_$DATE.tar.gz -C /var/lib/docker/volumes .

# Clean old backups (keep 30 days)
find $BACKUP_DIR -name "*.sql" -mtime +30 -delete
find $BACKUP_DIR -name "*.tar.gz" -mtime +30 -delete
EOF

chmod +x backup-script.sh

# Setup cron job for daily backups
(crontab -l 2>/dev/null; echo "0 2 * * * /home/$USER/vita-strategies/backup-script.sh") | crontab -
```

#### 4.2 Monitoring Setup
```bash
# Create health check script
cat > health-check.sh << 'EOF'
#!/bin/bash
services=("erpnext" "windmill" "metabase" "grafana" "mattermost" "nginx")

for service in "${services[@]}"; do
    if docker-compose ps | grep -q "${service}.*Up"; then
        echo "✅ $service is running"
    else
        echo "❌ $service is not running"
        # Restart the service
        docker-compose restart $service
    fi
done
EOF

chmod +x health-check.sh

# Setup cron job for health checks
(crontab -l 2>/dev/null; echo "*/5 * * * * /home/$USER/vita-strategies/health-check.sh") | crontab -
```

#### 4.3 SSL Certificate Auto-Renewal
```bash
# Setup auto-renewal
(crontab -l 2>/dev/null; echo "0 3 * * 0 sudo certbot renew --quiet && /home/$USER/vita-strategies/update-ssl.sh") | crontab -

# Create SSL update script
cat > update-ssl.sh << 'EOF'
#!/bin/bash
cd /home/$USER/vita-strategies

# Copy renewed certificates
domains=(
    "erp.yourdomain.com"
    "windmill.yourdomain.com"
    "analytics.yourdomain.com"
    "monitoring.yourdomain.com"
    "chat.yourdomain.com"
)

for domain in "${domains[@]}"; do
    if [ -f "/etc/letsencrypt/live/$domain/fullchain.pem" ]; then
        sudo cp /etc/letsencrypt/live/$domain/fullchain.pem ./ssl/${domain}_fullchain.pem
        sudo cp /etc/letsencrypt/live/$domain/privkey.pem ./ssl/${domain}_privkey.pem
    fi
done

sudo chown -R $USER:$USER ./ssl

# Reload nginx
docker-compose exec nginx nginx -s reload
EOF

chmod +x update-ssl.sh
```

## Post-Deployment Verification

### 5.1 Service Health Checks
```bash
# Check all services are running
docker-compose ps

# Verify external access
curl -I http://erp.yourdomain.com
curl -I http://windmill.yourdomain.com
curl -I http://analytics.yourdomain.com
curl -I http://monitoring.yourdomain.com
curl -I http://chat.yourdomain.com

# Check SSL certificates
openssl s_client -connect erp.yourdomain.com:443 -servername erp.yourdomain.com < /dev/null 2>/dev/null | openssl x509 -noout -dates
```

### 5.2 Performance Baseline
```bash
# Monitor resource usage
docker stats --no-stream

# Check disk usage
df -h
docker system df

# Memory usage
free -h
```

### 5.3 Security Verification
```bash
# Check open ports
sudo ss -tulpn

# Verify firewall status
sudo ufw status

# Check for security updates
sudo apt list --upgradable
```

## Rollback Plan

### In Case of Critical Issues
```bash
# Stop all services
docker-compose down

# Restore from backup (if needed)
# [Backup restoration commands]

# Start with minimal services
docker-compose up -d erpnext-db erpnext nginx

# Verify core functionality
curl -I http://erp.yourdomain.com

# Gradually add other services
docker-compose up -d windmill metabase grafana mattermost
```

## Support Information

### Key File Locations
- **Application**: `/home/$USER/vita-strategies/`
- **Backups**: `/var/backups/vita-strategies/`
- **SSL Certificates**: `/home/$USER/vita-strategies/ssl/`
- **Logs**: `docker-compose logs [service]`

### Important Commands
```bash
# View logs
docker-compose logs -f [service]

# Restart service
docker-compose restart [service]

# Update services
git pull && docker-compose pull && docker-compose up -d

# Emergency stop
docker-compose down
```

### Contact Information
- **System Administrator**: admin@yourdomain.com
- **Emergency Contact**: [phone number]
- **Documentation**: https://github.com/jamilkigozi/vita-strategies

---

**Deployment Checklist Status**
- [ ] Phase 1: Environment Preparation
- [ ] Phase 2: Application Deployment
- [ ] Phase 3: Service Configuration
- [ ] Phase 4: Backup and Monitoring Setup
- [ ] Phase 5: Post-Deployment Verification

**Estimated Total Time**: 2.5-3 hours
**Required Expertise Level**: Intermediate DevOps knowledge