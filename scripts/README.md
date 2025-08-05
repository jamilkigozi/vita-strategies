# Vita Strategies Deployment Scripts

This directory contains scripts for deploying, managing, and testing the Vita Strategies infrastructure.

## Safe Deployment Scripts

These scripts include safeguards to prevent accidental destruction of resources:

- **deploy-safe.sh**: Safely deploys or updates infrastructure using Terraform
  - Checks for existing deployments
  - Backs up Terraform state
  - Uses targeted updates to preserve existing resources
  - Shows warnings before potentially destructive operations

- **deploy-containers-safe.sh**: Safely deploys or updates containers
  - Checks for existing containers
  - Backs up database volumes
  - Updates services one by one
  - Performs health checks between updates

## Testing Scripts

- **test-safe-deployment.sh**: Tests the safeguards in the deployment scripts
  - Tests initialization marker detection
  - Tests container detection logic
  - Tests Terraform state backup logic
  - Verifies documentation exists

## Utility Scripts

- **cleanup-workspace.sh**: Cleans up the workspace by removing empty files, backup files, and log files
- **check-gcp-prerequisites.sh**: Checks if the GCP project exists and required APIs are enabled
- **deploy-to-gcloud.sh**: Deploys the infrastructure to Google Cloud Platform
- **deploy-complete.sh**: Handles the complete deployment of all applications
- **validate-deployment-ready.sh**: Validates all configurations before GCP deployment
- **health-check.sh**: Verifies all services are running correctly
- **generate-passwords.sh**: Generates secure passwords for services

## Usage

Always use the safe deployment scripts for deployment:

```bash
# For infrastructure deployment
./scripts/deploy-safe.sh

# For container deployment
./scripts/deploy-containers-safe.sh
```

Before deployment, ensure you have:
1. Updated all placeholder values in configuration files
2. Enabled required GCP APIs
3. Configured GCP credentials
4. Backed up any existing data

For detailed deployment instructions, refer to:
- **SAFE-DEPLOYMENT-GUIDE.md**: Comprehensive guide for safe deployment
- **REDEPLOYMENT-ISSUES-REPORT.md**: Report of identified issues and recommended fixes
- **REDEPLOYMENT-FIX-SUMMARY.md**: Summary of changes made to fix redeployment issues