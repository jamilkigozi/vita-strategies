# Infrastructure Scripts

Automation scripts for deployment, maintenance, and operations.

## 🚀 Deployment Scripts

### [deploy.sh](./deploy.sh)
Complete deployment automation script
- Infrastructure deployment via Terraform
- Application deployment via Docker Compose
- Health checks and verification
- Rollback on failure

### [update-services.sh](./update-services.sh)
Rolling update script for zero-downtime deployments
- Pull latest container images
- Update services one by one
- Health checks between updates
- Automatic rollback on failure

## 🔄 Maintenance Scripts

### [backup.sh](./backup.sh)
Comprehensive backup automation
- Database backups (PostgreSQL, MySQL, MariaDB)
- File system backups via gcsfuse
- Upload to Cloud Storage
- Cleanup old backups

### [health-check.sh](./health-check.sh)
System health monitoring script
- Service availability checks
- Database connectivity tests
- Resource usage monitoring
- Alert generation for failures

### [rollback.sh](./rollback.sh)
Emergency rollback procedures
- Service rollback to previous versions
- Database restore from backups
- Configuration restoration
- Service restart automation

## 🔧 Usage Examples

### Full Platform Deployment
```bash
sudo ./deploy.sh
```

### Update Single Service
```bash
sudo ./update-services.sh wordpress
```

### Manual Backup
```bash
sudo ./backup.sh
```

### Health Check
```bash
./health-check.sh --verbose
```

### Emergency Rollback
```bash
sudo ./rollback.sh --to-backup 2024-08-02
```

## 📊 Script Features

### Error Handling
- Comprehensive error checking
- Automatic cleanup on failure
- Detailed logging to `/var/log/vita-strategies/`
- Notification integration (Slack, email)

### Security
- Root privilege validation
- Secure credential handling
- Audit logging
- Permission verification

### Monitoring Integration
- Grafana metrics collection
- Prometheus custom metrics
- Alert manager integration
- Health check endpoints

---

*Automate everything - deploy with confidence! 🤖*
