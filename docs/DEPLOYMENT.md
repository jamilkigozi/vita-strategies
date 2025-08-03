# Deployment Guide

Complete deployment procedures for the Vita Strategies microservices platform.

## 🏗️ Prerequisites

### Infrastructure Requirements
- **Google Cloud Platform** account with billing enabled
- **Terraform** v1.5+ installed locally
- **Docker** and **Docker Compose** installed
- **Domain** configured in Cloudflare (vitastrategies.com)

### Access Requirements
- GCP project owner permissions
- Cloudflare API token with zone edit permissions
- SSH key pair for VM access

## 🚀 Deployment Steps

### Phase 1: Infrastructure Deployment

1. **Configure Terraform Variables**
   ```bash
   cd infrastructure/terraform
   cp variables.tf.example variables.tf
   # Edit variables.tf with your configuration
   ```

2. **Initialize and Deploy Infrastructure**
   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

3. **Verify Infrastructure**
   ```bash
   terraform output
   # Note the VM external IP and database connection info
   ```

### Phase 2: Application Deployment

1. **Connect to VM**
   ```bash
   ssh -i ~/.ssh/vita-strategies appuser@[VM_EXTERNAL_IP]
   ```

2. **Deploy Docker Stack**
   ```bash
   cd /opt/vita-strategies
   sudo docker-compose up -d
   ```

3. **Verify Services**
   ```bash
   sudo docker-compose ps
   # All services should show "healthy" status
   ```

### Phase 3: Service Configuration

1. **Configure Keycloak (SSO)**
   - Access: `https://auth.vitastrategies.com`
   - Create admin user and configure realms
   - Set up client applications for each service

2. **Configure Nginx Routes**
   - Verify SSL certificates are active
   - Test all subdomain routing
   - Configure load balancing if needed

3. **Database Initialization**
   - Each service will auto-initialize its database
   - Run health checks to verify connectivity

## 🔍 Post-Deployment Verification

### Service Health Checks
```bash
# Check all services are running
curl -f https://vitastrategies.com
curl -f https://erp.vitastrategies.com
curl -f https://chat.vitastrategies.com
curl -f https://docs.vitastrategies.com
curl -f https://workflows.vitastrategies.com
curl -f https://apps.vitastrategies.com
curl -f https://analytics.vitastrategies.com
curl -f https://monitoring.vitastrategies.com
curl -f https://auth.vitastrategies.com
curl -f https://vault.vitastrategies.com
```

### Database Connectivity
```bash
# Test database connections
sudo docker exec postgres-primary pg_isready
sudo docker exec mysql-primary mysqladmin ping
sudo docker exec mariadb-erp mysqladmin ping
```

### Monitoring Setup
- Access Grafana: `https://monitoring.vitastrategies.com`
- Import dashboards for each service
- Configure alerting rules
- Test notification channels

## 🔄 Update Procedures

### Application Updates
```bash
# Pull latest images
sudo docker-compose pull

# Restart services with zero downtime
sudo docker-compose up -d --no-deps [service-name]
```

### Infrastructure Updates
```bash
cd infrastructure/terraform
terraform plan
terraform apply
```

### Database Migrations
```bash
# Backup before migrations
sudo ./scripts/backup.sh

# Run service-specific migrations
sudo docker exec [service-container] [migration-command]
```

## 🆘 Rollback Procedures

### Application Rollback
```bash
# Rollback to previous image version
sudo docker-compose down
sudo docker-compose up -d --force-recreate
```

### Infrastructure Rollback
```bash
cd infrastructure/terraform
terraform plan -destroy
terraform apply
```

### Database Restore
```bash
sudo ./scripts/restore.sh [backup-date]
```

## 📊 Monitoring & Maintenance

### Daily Checks
- [ ] All services healthy in Grafana
- [ ] No critical alerts active
- [ ] Backup jobs completed successfully
- [ ] SSL certificates valid

### Weekly Maintenance
- [ ] Update Docker images
- [ ] Review security logs
- [ ] Clean up old backups
- [ ] Performance optimization

### Monthly Tasks
- [ ] Security vulnerability scans
- [ ] Capacity planning review
- [ ] Disaster recovery testing
- [ ] Documentation updates

## 🔐 Security Considerations

### Access Control
- VM access restricted to specific IP addresses
- Database access limited to private network
- All services behind SSL termination
- Regular security patches applied

### Backup Strategy
- Daily automated database backups
- File system snapshots every 6 hours
- Off-site backup storage in Cloud Storage
- Monthly disaster recovery testing

### Monitoring & Alerting
- Real-time service health monitoring
- Security event logging and alerting
- Performance metrics and trending
- Automated incident response

---

*Deploy with confidence - comprehensive procedures for success! 🚀*
