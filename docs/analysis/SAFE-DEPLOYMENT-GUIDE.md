# Vita Strategies Safe Deployment Guide

## Overview

This guide explains the changes made to the deployment process to prevent accidental destruction of existing resources. The previous deployment process had a flaw that caused it to destroy everything and recreate it from scratch, resulting in data loss.

## What Was Fixed

1. **Startup Script Improvements**
   - Added detection of existing installations
   - Prevented reinstallation of already installed packages
   - Added safeguards to preserve existing data
   - Created initialization marker to track first vs. subsequent runs

2. **Terraform Deployment Safeguards**
   - Created backup mechanism for Terraform state
   - Added targeted updates to avoid destroying unrelated resources
   - Implemented state refresh before planning changes
   - Added detection of potential resource destruction

3. **Container Deployment Safeguards**
   - Added detection of existing containers
   - Implemented volume backups before updates
   - Created service-by-service update process
   - Added health checks between service updates

## How to Deploy Safely

### Option 1: Safe Infrastructure Deployment

Use the new `deploy-safe.sh` script to deploy or update infrastructure:

```bash
chmod +x scripts/deploy-safe.sh
./scripts/deploy-safe.sh
```

This script will:
- Check for existing deployments
- Back up Terraform state
- Use targeted updates to preserve existing resources
- Show warnings before potentially destructive operations

### Option 2: Safe Container Deployment

Use the new `deploy-containers-safe.sh` script to deploy or update containers:

```bash
chmod +x scripts/deploy-containers-safe.sh
./scripts/deploy-containers-safe.sh
```

This script will:
- Check for existing containers
- Back up database volumes
- Update services one by one
- Perform health checks between updates

## Recovering From Previous Data Loss

If you've already lost data due to the previous deployment issue:

1. **Check for backups**:
   - Look for volume backups in the `./backups/` directory
   - Check for Terraform state backups in `infrastructure/terraform/backups/`

2. **Restore database volumes** (if backups exist):
   ```bash
   # Replace BACKUP_DATE with the actual backup date directory
   docker volume create postgres_data
   docker run --rm -v postgres_data:/target -v $(pwd)/backups/BACKUP_DATE:/backup alpine sh -c "cd /target && tar -xzf /backup/postgres_data.tar.gz"
   
   docker volume create mariadb_data
   docker run --rm -v mariadb_data:/target -v $(pwd)/backups/BACKUP_DATE:/backup alpine sh -c "cd /target && tar -xzf /backup/mariadb_data.tar.gz"
   ```

3. **Deploy with safe scripts**:
   ```bash
   ./scripts/deploy-safe.sh
   ./scripts/deploy-containers-safe.sh
   ```

## Best Practices for Future Deployments

1. **Always use the safe deployment scripts**
   - Never use the original deployment scripts
   - Always check for warnings during deployment

2. **Create regular backups**
   - Schedule regular backups of database volumes
   - Keep multiple Terraform state backups

3. **Test updates in staging first**
   - Create a staging environment for testing
   - Verify updates work correctly before applying to production

4. **Monitor deployments**
   - Watch logs during deployment
   - Verify all services are running after deployment

## Troubleshooting

If you encounter issues during deployment:

1. **Check logs**:
   ```bash
   docker-compose logs -f [service-name]
   ```

2. **Verify volumes**:
   ```bash
   docker volume ls
   ```

3. **Check container status**:
   ```bash
   docker-compose ps
   ```

4. **Restore from backup** if needed using the recovery steps above.

## Conclusion

These changes should prevent the accidental destruction of resources during deployment. Always use the safe deployment scripts and follow the best practices to ensure your data remains safe.

## Additional Documentation

For more information about redeployment, refer to these documents:

1. **REDEPLOYMENT-ISSUES-REPORT.md**: Detailed report of identified issues and recommended fixes for redeployment.
2. **REDEPLOYMENT-FIX-SUMMARY.md**: Summary of changes made to fix redeployment issues.

Before proceeding with redeployment, ensure you have completed all the tasks listed in these documents.