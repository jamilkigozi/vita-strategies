# Architecture Overview

## System Architecture

The Vita Strategies platform uses a cloud-native architecture optimized for security, scalability, and maintainability.

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   Cloudflare    │    │   Google Cloud   │    │   Applications  │
│                 │    │                  │    │                 │
│ ┌─────────────┐ │    │ ┌──────────────┐ │    │ ┌─────────────┐ │
│ │   Tunnel    │◄┼────┼►│ Compute VM   │◄┼────┼►│ WordPress   │ │
│ │             │ │    │ │              │ │    │ │ ERPNext     │ │
│ └─────────────┘ │    │ └──────────────┘ │    │ │ Mattermost  │ │
│                 │    │                  │    │ │ Grafana     │ │
│ ┌─────────────┐ │    │ ┌──────────────┐ │    │ │ Metabase    │ │
│ │     DNS     │ │    │ │  Cloud SQL   │ │    │ │ Keycloak    │ │
│ │             │ │    │ │ PostgreSQL   │ │    │ │ Appsmith    │ │
│ └─────────────┘ │    │ │ MySQL        │ │    │ │ Windmill    │ │
│                 │    │ │ MariaDB      │ │    │ └─────────────┘ │
└─────────────────┘    │ └──────────────┘ │    └─────────────────┘
                       │                  │
                       │ ┌──────────────┐ │
                       │ │ Secret Mgr   │ │
                       │ │              │ │
                       │ └──────────────┘ │
                       └──────────────────┘
```

## Core Components

### 1. Cloudflare Layer
- **Tunnel**: Secure connection without exposing public IPs
- **DNS**: Domain management and routing
- **CDN**: Content delivery and caching
- **Security**: DDoS protection and WAF

### 2. Google Cloud Platform
- **Compute Engine**: Single VM hosting all applications
- **Cloud SQL**: Managed database instances with private networking
- **Secret Manager**: Centralized credential storage
- **Cloud Storage**: File storage for applications
- **VPC**: Private networking with firewall rules

### 3. Application Layer
- **Docker Compose**: Container orchestration
- **Applications**: 8 business applications on dedicated ports
- **Databases**: Dedicated database per application
- **Shared Services**: Redis for caching, MongoDB for Appsmith

## Network Architecture

### Private Networking
- VPC: `10.0.0.0/24`
- Cloud SQL: Private IPs only
- VM: Internal communication via Docker network

### Port Mapping
- 8001: WordPress
- 8002: Metabase
- 8003: Appsmith
- 8004: Keycloak
- 8005: Mattermost
- 8006: ERPNext
- 8007: Windmill
- 8008: Grafana

### Security
- Cloudflare IP-restricted firewall rules
- No direct internet access to databases
- Service accounts with minimal permissions
- Encrypted secrets in Secret Manager

## Data Flow

1. **User Request** → Cloudflare DNS
2. **DNS Resolution** → Cloudflare Tunnel
3. **Tunnel** → GCP VM specific port
4. **Application** → Cloud SQL private IP
5. **Response** ← Through tunnel back to user

## Scalability Considerations

- **Horizontal**: Add more VMs behind load balancer
- **Vertical**: Increase VM and database instance sizes
- **Database**: Read replicas for high-traffic applications
- **Storage**: Auto-scaling Cloud Storage buckets

## Disaster Recovery

- **Database Backups**: Automated daily backups with 7-day retention
- **Infrastructure**: Terraform state for rapid rebuild
- **Application Data**: Persistent volumes on Cloud Storage
- **Secrets**: Replicated in Secret Manager