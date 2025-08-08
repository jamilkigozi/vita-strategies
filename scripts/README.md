# Scripts Directory

This directory contains deployment and maintenance scripts for the Vita Strategies platform.

## Available Scripts

### `deploy-cloudshell.sh`
**Primary deployment script** - Deploy the entire platform via Google Cloud Shell.

```bash
bash scripts/deploy-cloudshell.sh
```

**What it does:**
- Initializes Terraform
- Deploys GCP infrastructure (VM, databases, networking)
- Outputs VM external IP for Cloudflare tunnel configuration
- Applications auto-deploy via VM startup script

### `workspace-cleanup.sh`
**Maintenance script** - Remove redundant files and clean up the workspace.

```bash
bash scripts/workspace-cleanup.sh
```

**What it removes:**
- Redundant Docker Compose files
- Broken/unused Terraform files
- Old deployment scripts
- Empty directories
- Backup files

## Deployment Process

1. **Open Cloud Shell** in your GCP console
2. **Clone repository**: `git clone https://github.com/jamilkigozi/vita-strategies.git`
3. **Navigate**: `cd vita-strategies`
4. **Deploy**: `bash scripts/deploy-cloudshell.sh`
5. **Configure Cloudflare tunnel** with the provided VM IP

## Infrastructure Management

All infrastructure is managed through Terraform in the `infrastructure/terraform/` directory:

- `main.tf`: Core infrastructure definitions
- `variables.tf`: Variable declarations
- `terraform.tfvars`: Configuration values
- `startup-script.sh`: VM initialization script

## Application Management

Applications are managed through Docker Compose:

- `docker-compose.cloudflare.yml`: Main application orchestration file
- Applications auto-start on VM boot via startup script
- Logs accessible via `docker-compose logs`

## Security

- All secrets stored in Google Secret Manager
- No hardcoded credentials in repository
- Private networking for databases
- Cloudflare-restricted firewall rules