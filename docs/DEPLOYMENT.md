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
   cp terraform.tfvars.example terraform.tfvars
   # Edit terraform.tfvars with your configuration
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

2. **Clone the repository**
    ```bash
    git clone https://github.com/your-repo/vita-strategies.git /opt/vita-strategies
    ```

3. **Configure Environment Variables**
   ```bash
   cd /opt/vita-strategies/docker
   cp .env.template .env
   # Edit .env with your secrets
   ```

4. **Deploy Docker Stack**
   ```bash
   ./deploy.sh
   ```

5. **Verify Services**
   ```bash
   docker-compose ps
   # All services should show "up" status
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
sudo docker exec postgres pg_isready
sudo docker exec mariadb mysqladmin ping
```

### Monitoring Setup
- Access Grafana: `https://monitoring.vitastrategies.com`
- Import dashboards for each service
- Configure alerting rules
- Test notification channels

## 🔄 Update Procedures

### Application Updates
```bash
# Pull latest changes
cd /opt/vita-strategies
git pull

# Pull latest images
cd /opt/vita-strategies/docker
docker-compose pull

# Restart services
./deploy.sh
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
./scripts/backup.sh

# Run service-specific migrations
docker exec [service-container] [migration-command]
```

## 🆘 Rollback Procedures

### Application Rollback
```bash
# Rollback to previous commit
cd /opt/vita-strategies
git checkout <commit-hash>

# Redeploy
cd /opt/vita-strategies/docker
./deploy.sh
```

### Infrastructure Rollback
```bash
cd infrastructure/terraform
terraform plan -destroy
terraform apply
```

### Database Restore
```bash
./scripts/restore.sh [backup-date]
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