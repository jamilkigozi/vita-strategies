# Vita Strategies - Simplified GCP Deployment

## Overview
Cost-effective, single-developer cloud platform deployed on Google Cloud Platform using a single Compute Engine VM with Docker Compose. Ideal for solo entrepreneurs and small businesses.

## Simple Architecture
- **Compute**: Single GCP Compute Engine VM (e2-standard-4: 4 vCPUs, 16GB RAM)
- **Database**: Cloud SQL MySQL (ERPNext) + PostgreSQL (other services) 
- **Cache**: Redis container on the VM
- **Storage**: VM persistent disk + Cloud SQL backups
- **Networking**: Simple VPC with firewall rules
- **CDN & Security**: Cloudflare for global performance and protection
- **Reverse Proxy**: Nginx container handling all routing

## Cost-Effective Setup
- **Monthly Cost**: ~$150-200/month (vs $500+ for Kubernetes)
- **No Kubernetes overhead**: Simple Docker Compose management
- **Managed databases**: Cloud SQL handles backups and maintenance
- **Single VM**: Easy to manage, monitor, and troubleshoot

## Service Portfolio
- **ERPNext**: Core ERP system at `erp.vitastrategies.com`
- **Windmill**: Workflow automation at `workflows.vitastrategies.com`
- **Keycloak**: Identity & Access Management at `auth.vitastrategies.com`
- **Metabase**: Business Intelligence at `analytics.vitastrategies.com`
- **Appsmith**: Low-code development at `apps.vitastrategies.com`
- **Mattermost**: Team collaboration at `chat.vitastrategies.com`
- **Grafana**: Monitoring dashboard at `monitoring.vitastrategies.com`

## Repository Structure
```
vita-strategies/
├── applications/              # Application configurations
│   ├── erpnext/              # ERPNext ERP system configs
│   ├── windmill/             # Workflow automation
│   ├── keycloak/             # Identity management
│   └── ... (other services)
├── gcp-infrastructure/        # Google Cloud infrastructure
│   ├── terraform/            # Infrastructure as Code
│   ├── docker-compose/       # Single VM Docker setup
│   ├── startup-scripts/      # VM initialization scripts
│   ├── cloudflare/           # CDN and security
│   └── monitoring/           # Observability
├── data-platform/            # Data management
│   ├── schemas/              # Database schemas
│   ├── migrations/           # Database migrations
│   └── backups/              # Backup configurations
├── security/                 # Security configurations
│   ├── iam/                  # GCP IAM policies
│   ├── secrets/              # Secret management
│   └── certificates/         # SSL/TLS certificates
└── ci-cd/                    # Simple deployment
    ├── workflows/            # GitHub Actions
    └── scripts/              # Deployment scripts
```

## Quick Deployment (Solo Developer Friendly)
```bash
# 1. Set up GCP infrastructure (single VM + databases)
cd gcp-infrastructure/terraform
terraform init
terraform plan
terraform apply

# 2. SSH into the VM and deploy applications
gcloud compute ssh vita-strategies-server
cd /opt/vita-strategies
sudo docker-compose up -d

# 3. Configure Cloudflare DNS
cd gcp-infrastructure/cloudflare/terraform
terraform apply
```

## Prerequisites (Minimal)
- Google Cloud account with billing enabled
- Terraform installed locally
- Cloudflare account
- Domain ownership for vitastrategies.com
- Basic Docker knowledge

## Solo Developer Benefits
- ✅ **Simple Management**: One VM to rule them all
- ✅ **Cost Effective**: ~$150/month vs $500+ for enterprise setups
- ✅ **Easy Debugging**: SSH into one machine, check logs
- ✅ **Quick Scaling**: Resize VM as business grows
- ✅ **Backup Strategy**: Automated Cloud SQL backups
- ✅ **SSL/Security**: Cloudflare handles DDoS and SSL
- ✅ **Monitoring**: Simple container monitoring

## Performance Expectations
- **Concurrent Users**: 50-100 active users
- **Storage**: 100GB SSD (expandable)
- **Memory**: 16GB RAM (upgradeable to 64GB)
- **CPU**: 4 vCPUs (upgradeable to 32 vCPUs)
- **Uptime**: 99.9% with Cloud SQL managed databases

## Scaling Path
1. **Start**: Single VM with all services
2. **Growth**: Upgrade VM specs (vertical scaling)
3. **Expansion**: Move to multiple VMs with load balancer
4. **Enterprise**: Migrate to Kubernetes when team grows

## Deployment Commands
```bash
# Deploy infrastructure
terraform -chdir=gcp-infrastructure/terraform apply

# Check VM status
gcloud compute instances describe vita-strategies-server

# Deploy applications
gcloud compute ssh vita-strategies-server --command="cd /opt/vita-strategies && sudo docker-compose up -d"

# View logs
gcloud compute ssh vita-strategies-server --command="cd /opt/vita-strategies && sudo docker-compose logs -f"
```

**Perfect for solo entrepreneurs who want enterprise features without enterprise complexity!**