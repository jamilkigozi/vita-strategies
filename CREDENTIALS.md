# Credentials Management - Vita Strategies Platform

⚠️ **SECURITY WARNING**: This file contains default credentials. Change ALL passwords before production deployment.

## Service Credentials

### Database Passwords
```bash
# MariaDB (ERPNext)
MYSQL_ROOT_PASSWORD=vita_secure_2024
MYSQL_USER=erpnext
MYSQL_PASSWORD=vita_secure_2024

# PostgreSQL (Windmill)
POSTGRES_USER=windmill
POSTGRES_PASSWORD=windmill_pass

# PostgreSQL (Mattermost)
POSTGRES_USER=mattermost
POSTGRES_PASSWORD=mattermost_pass
```

### Application Credentials

#### Grafana
- **Username**: admin
- **Default Password**: vita_admin_2024
- **Change Password**: First login will prompt for new password

#### ERPNext
- **Setup Required**: Admin account created during first-time setup wizard
- **Access**: http://erp.vita-strategies.com

#### Windmill
- **Setup Required**: Admin account created on first access
- **Access**: http://windmill.vita-strategies.com

#### Metabase
- **Setup Required**: Admin account created on first access
- **Access**: http://analytics.vita-strategies.com

#### Mattermost
- **Setup Required**: Admin account created on first access
- **Access**: http://chat.vita-strategies.com

## Environment Variables

### Required Environment Variables (.env file)
```bash
# Domain Configuration
DOMAIN=vita-strategies.com
ERP_DOMAIN=erp.vita-strategies.com
WINDMILL_DOMAIN=windmill.vita-strategies.com
ANALYTICS_DOMAIN=analytics.vita-strategies.com
MONITORING_DOMAIN=monitoring.vita-strategies.com
CHAT_DOMAIN=chat.vita-strategies.com

# Database Passwords
MYSQL_ROOT_PASSWORD=vita_secure_2024
MYSQL_PASSWORD=vita_secure_2024
WINDMILL_DB_PASSWORD=windmill_pass
MATTERMOST_DB_PASSWORD=mattermost_pass

# Application Secrets
GRAFANA_ADMIN_PASSWORD=vita_admin_2024
SECRET_KEY=your-secret-key-here-32-chars-minimum

# SSL Configuration
SSL_CERT_PATH=/etc/nginx/ssl
ENABLE_SSL=false

# Email Configuration (Optional)
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USER=your-email@gmail.com
SMTP_PASSWORD=your-app-password
```

## Security Recommendations

### Immediate Actions Required

1. **Change Default Passwords**
```bash
# Generate secure passwords
openssl rand -base64 32

# Update .env file with new passwords
nano .env

# Restart services
docker-compose down
docker-compose up -d
```

2. **Secure Database Access**
```bash
# ERPNext Database
docker-compose exec erpnext-db mysql -u root -p
> ALTER USER 'root'@'%' IDENTIFIED BY 'NEW_SECURE_PASSWORD';
> ALTER USER 'erpnext'@'%' IDENTIFIED BY 'NEW_SECURE_PASSWORD';
> FLUSH PRIVILEGES;

# Update site_config.json
docker-compose exec erpnext nano /home/frappe/frappe-bench/sites/site1.local/site_config.json
```

3. **Enable SSL/TLS**
```bash
# Generate SSL certificates
sudo certbot certonly --standalone -d erp.vita-strategies.com
sudo certbot certonly --standalone -d windmill.vita-strategies.com
sudo certbot certonly --standalone -d analytics.vita-strategies.com
sudo certbot certonly --standalone -d monitoring.vita-strategies.com
sudo certbot certonly --standalone -d chat.vita-strategies.com

# Copy certificates
mkdir -p ./ssl
sudo cp /etc/letsencrypt/live/*/fullchain.pem ./ssl/
sudo cp /etc/letsencrypt/live/*/privkey.pem ./ssl/

# Update nginx configuration
nano nginx.conf
# Uncomment SSL sections and update certificate paths
```

### Secrets Management

#### For Development
- Use `.env` file with secure passwords
- Never commit `.env` to version control
- Use `.env.example` as template

#### For Production
- Use Docker Secrets or Kubernetes Secrets
- Implement HashiCorp Vault or similar
- Use environment-specific configurations
- Enable audit logging

### Password Policy

#### Requirements
- Minimum 16 characters
- Mix of uppercase, lowercase, numbers, symbols
- No dictionary words
- Unique per service
- Regular rotation (90 days)

#### Generation
```bash
# Generate secure password
openssl rand -base64 24

# Generate with special characters
openssl rand -base64 32 | tr -d "=+/" | cut -c1-25

# Using pwgen
pwgen -s -B 32 1
```

## Access Control

### Service Access Matrix
```
Service     Port    Internal    External    Auth Required
ERPNext     8000    ✅          ✅          ✅
Windmill    8000    ✅          ✅          ✅
Metabase    3000    ✅          ✅          ✅
Grafana     3000    ✅          ✅          ✅
Mattermost  8065    ✅          ✅          ✅
MariaDB     3306    ✅          ❌          ✅
PostgreSQL  5432    ✅          ❌          ✅
Redis       6379    ✅          ❌          ❌
```

### Network Security
- Services communicate via internal Docker network
- Database ports not exposed externally
- Nginx handles all external traffic
- SSL termination at proxy level

## Backup Credentials

### Database Backup Commands
```bash
# ERPNext/MariaDB
docker-compose exec erpnext-db mysqldump -u root -p erpnext > backup_erpnext_$(date +%Y%m%d).sql

# Windmill/PostgreSQL
docker-compose exec windmill-db pg_dump -U windmill windmill > backup_windmill_$(date +%Y%m%d).sql

# Mattermost/PostgreSQL
docker-compose exec mattermost-db pg_dump -U mattermost mattermost > backup_mattermost_$(date +%Y%m%d).sql
```

### Automated Backup Script
```bash
#!/bin/bash
# Create encrypted backups
BACKUP_DIR="/var/backups/vita-strategies"
DATE=$(date +%Y%m%d_%H%M%S)

# Create backup directory
mkdir -p $BACKUP_DIR

# Backup and encrypt
docker-compose exec erpnext-db mysqldump -u root -p$MYSQL_ROOT_PASSWORD erpnext | \
  gpg --cipher-algo AES256 --compress-algo 1 --s2k-mode 3 \
      --s2k-digest-algo SHA512 --s2k-count 65536 --force-mdc \
      --symmetric --output $BACKUP_DIR/erpnext_$DATE.sql.gpg

# Clean old backups (keep 30 days)
find $BACKUP_DIR -name "*.gpg" -mtime +30 -delete
```

## Monitoring & Alerting

### Credential Monitoring
- Monitor failed login attempts
- Alert on password changes
- Track privileged access
- Log all administrative actions

### Grafana Dashboards
- Database connection monitoring
- Failed authentication tracking
- Service health monitoring
- Resource usage alerts

## Compliance Notes

### Data Protection
- Passwords encrypted at rest
- Database connections encrypted
- Backup encryption enabled
- Access logging implemented

### Audit Requirements
- All credential changes logged
- Regular security reviews
- Penetration testing
- Compliance reporting

## Emergency Procedures

### Compromised Credentials
1. Immediately change affected passwords
2. Restart affected services
3. Review access logs
4. Notify security team
5. Document incident

### Lost Admin Access
1. Use database direct access
2. Reset passwords via SQL
3. Restart services
4. Update documentation
5. Implement prevention measures

## Support Contacts

- **System Administrator**: admin@vita-strategies.com
- **Security Team**: security@vita-strategies.com
- **Emergency**: +1-XXX-XXX-XXXX

---

**Last Updated**: August 4, 2025
**Next Review**: November 4, 2025
**Classification**: CONFIDENTIAL