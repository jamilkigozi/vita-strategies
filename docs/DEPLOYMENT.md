# Deployment Guide

## Overview

The Vita Strategies platform uses a Cloudflare-optimized deployment strategy with Google Cloud Platform infrastructure.

## Architecture Components

- **GCP Compute Engine**: Single VM hosting all applications
- **Cloud SQL**: Managed PostgreSQL, MySQL, and MariaDB instances
- **Cloudflare Tunnel**: Secure connection without public IP exposure
- **Docker Compose**: Container orchestration
- **Terraform**: Infrastructure as Code

## Deployment Process

### 1. Cloud Shell Deployment

```bash
# Open Cloud Shell in GCP Console
git clone https://github.com/jamilkigozi/vita-strategies.git
cd vita-strategies
bash scripts/deploy-cloudshell.sh
```

### 2. Cloudflare Tunnel Configuration

After deployment, configure Cloudflare tunnel with the provided VM IP:

- WordPress: `https://VM_IP:8001`
- Metabase: `https://VM_IP:8002`
- Appsmith: `https://VM_IP:8003`
- Keycloak: `https://VM_IP:8004`
- Mattermost: `https://VM_IP:8005`
- ERPNext: `https://VM_IP:8006`
- Windmill: `https://VM_IP:8007`
- Grafana: `https://VM_IP:8008`

## Infrastructure Details

### Database Configuration
- PostgreSQL: Mattermost, Windmill, Metabase, Grafana, Keycloak
- MySQL: WordPress
- MariaDB: ERPNext

### Security Features
- Private networking for databases
- Cloudflare IP-restricted firewall rules
- Google Secret Manager for credentials
- Least privilege service accounts

### Monitoring
- Application logs via Docker Compose
- Infrastructure monitoring via Grafana
- Database monitoring via Cloud SQL insights

## Troubleshooting

### Check Service Status
```bash
docker-compose -f docker-compose.cloudflare.yml ps
```

### View Service Logs
```bash
docker-compose -f docker-compose.cloudflare.yml logs -f [service-name]
```

### Restart Services
```bash
docker-compose -f docker-compose.cloudflare.yml restart [service-name]
```