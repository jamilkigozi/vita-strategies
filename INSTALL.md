# Installation Guide - Vita Strategies Platform

## System Requirements

### Minimum Requirements
- **OS**: Ubuntu 20.04+, CentOS 8+, or macOS 10.15+
- **RAM**: 8GB minimum, 16GB recommended
- **Storage**: 50GB free space
- **Network**: Reliable internet connection

### Recommended Production Requirements
- **OS**: Ubuntu 22.04 LTS
- **RAM**: 32GB+
- **Storage**: 200GB+ SSD
- **CPU**: 8+ cores
- **Network**: 1Gbps connection

## Prerequisites Installation

### 1. Docker & Docker Compose
```bash
# Ubuntu/Debian
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER

# Install Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Verify installation
docker --version
docker-compose --version
```

### 2. Git
```bash
# Ubuntu/Debian
sudo apt update && sudo apt install git -y

# CentOS/RHEL
sudo yum install git -y

# Verify
git --version
```

## Platform Installation

### 1. Clone Repository
```bash
git clone https://github.com/jamilkigozi/vita-strategies.git
cd vita-strategies
```

### 2. Environment Setup
```bash
# Copy environment template
cp .env.example .env

# Edit configuration (see CONFIGURATION.md for details)
nano .env
```

### 3. DNS Configuration (Production)
Add these DNS records to your domain:
```
A     erp.yourdomain.com         -> YOUR_SERVER_IP
A     windmill.yourdomain.com    -> YOUR_SERVER_IP
A     analytics.yourdomain.com   -> YOUR_SERVER_IP
A     monitoring.yourdomain.com  -> YOUR_SERVER_IP
A     chat.yourdomain.com        -> YOUR_SERVER_IP
```

### 4. SSL Certificates (Production)
```bash
# Install Certbot
sudo apt install certbot -y

# Generate certificates
sudo certbot certonly --standalone -d erp.yourdomain.com
sudo certbot certonly --standalone -d windmill.yourdomain.com
sudo certbot certonly --standalone -d analytics.yourdomain.com
sudo certbot certonly --standalone -d monitoring.yourdomain.com
sudo certbot certonly --standalone -d chat.yourdomain.com

# Copy certificates
sudo mkdir -p ./ssl
sudo cp /etc/letsencrypt/live/*/fullchain.pem ./ssl/
sudo cp /etc/letsencrypt/live/*/privkey.pem ./ssl/
sudo chown -R $USER:$USER ./ssl
```

### 5. Deploy Services
```bash
# Development deployment
docker-compose up -d

# Production deployment with persistent volumes
docker-compose -f docker-compose-persistent.yml up -d

# Verify deployment
docker-compose ps
```

### 6. Initial Configuration

#### ERPNext Setup
1. Open http://erp.yourdomain.com
2. Complete setup wizard
3. Create administrator account
4. Configure company settings

#### Grafana Setup
1. Open http://monitoring.yourdomain.com
2. Login with admin/vita_admin_2024
3. Change default password
4. Import dashboards from `monitoring/dashboards/`

#### Windmill Setup
1. Open http://windmill.yourdomain.com
2. Create admin account
3. Import workflows from `automation/workflows/`

## Troubleshooting

### Common Issues

**Services not starting:**
```bash
# Check logs
docker-compose logs [service-name]

# Check system resources
docker stats
df -h
free -h
```

**Port conflicts:**
```bash
# Check port usage
sudo netstat -tulpn | grep :80
sudo netstat -tulpn | grep :443

# Stop conflicting services
sudo systemctl stop apache2
sudo systemctl stop nginx
```

**Permission issues:**
```bash
# Fix Docker permissions
sudo usermod -aG docker $USER
newgrp docker

# Fix file permissions
sudo chown -R $USER:$USER ./
```

### Performance Optimization

**For Production:**
1. Increase Docker memory limits
2. Configure swap space
3. Optimize database settings
4. Enable log rotation
5. Set up monitoring alerts

## Backup & Restore

### Backup
```bash
# Backup all data
./scripts/backup.sh

# Backup specific service
docker-compose exec erpnext-db mysqldump -u root -p erpnext > backup.sql
```

### Restore
```bash
# Restore from backup
./scripts/restore.sh backup_file.tar.gz
```

## Updates

### Update Platform
```bash
# Pull latest changes
git pull origin main

# Update containers
docker-compose pull
docker-compose up -d

# Clean old images
docker image prune -f
```

## Support

- **Documentation**: See `/docs` directory
- **Issues**: GitHub Issues
- **Community**: Mattermost chat
- **Professional Support**: Contact admin

## Security Checklist

- [ ] Change all default passwords
- [ ] Configure firewall rules
- [ ] Enable SSL certificates
- [ ] Set up backup encryption
- [ ] Configure log monitoring
- [ ] Enable 2FA where possible
- [ ] Regular security updates