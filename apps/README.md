# Applications

This directory contains all microservice applications for the Vita Strategies platform.

## 🏗️ Microservices Architecture

Each application is containerized with Docker and includes:
- **Dockerfile** - Container build configuration
- **docker-compose.yml** - Service orchestration
- **README.md** - Service-specific documentation
- **Configuration files** - Application settings

## 📦 Application Stack

### Web & Content Management
- **[wordpress/](./wordpress/)** - Company website and blog
- **[bookstack/](./bookstack/)** - Documentation and knowledge base

### Business Applications
- **[erpnext/](./erpnext/)** - Enterprise resource planning
- **[metabase/](./metabase/)** - Business intelligence and analytics

### Team Collaboration
- **[mattermost/](./mattermost/)** - Team messaging and communication
- **[appsmith/](./appsmith/)** - Low-code application builder

### Development & Automation
- **[windmill/](./windmill/)** - Workflow automation platform

### Security & Identity
- **[keycloak/](./keycloak/)** - Single Sign-On and identity management
- **[openbao/](./openbao/)** - Secrets management (HashiCorp Vault alternative)

### Monitoring & Operations
- **[grafana/](./grafana/)** - System monitoring and alerting

### Infrastructure Services
- **[nginx/](./nginx/)** - Reverse proxy and load balancer
- **[backup-service/](./backup-service/)** - Automated backup and recovery

## 🔧 Service Dependencies

### Database Connections
- **PostgreSQL:** mattermost, windmill, metabase, grafana, openbao, keycloak
- **MySQL:** wordpress, bookstack
- **MariaDB:** erpnext

### Storage Integration
- Each service has dedicated Cloud Storage bucket
- Shared assets bucket for static files
- Automated backup to dedicated backup bucket

### Authentication Flow
1. **Keycloak** - Central identity provider
2. **OpenBao** - Secrets and credentials management
3. **Service Integration** - SSO across all applications

## 🚀 Deployment Order

**Recommended deployment sequence:**

1. **nginx** - Reverse proxy foundation
2. **keycloak** - Identity management first
3. **openbao** - Secrets management
4. **wordpress** - Public-facing website
5. **erpnext** - Core business application
6. **mattermost** - Team communication
7. **bookstack** - Documentation platform
8. **metabase** - Business intelligence
9. **grafana** - Monitoring and alerting
10. **windmill** - Workflow automation
11. **appsmith** - Internal tools
12. **backup-service** - Data protection

## 🔍 Service Health Monitoring

### Health Check Endpoints
- Most services expose `/health` or `/status` endpoints
- Nginx configured with upstream health checks
- Grafana dashboards monitor all service metrics

### Service Discovery
- Docker Compose networking for internal communication
- Nginx upstream configuration for load balancing
- Consistent naming conventions across services

## 📊 Resource Requirements

### Minimum VM Specifications
- **CPU:** 4 vCPUs (e2-standard-4)
- **Memory:** 16 GB RAM
- **Storage:** 100 GB persistent disk
- **Network:** 1 Gbps

### Container Resource Allocation
```yaml
# Example resource limits per service
wordpress: 512MB RAM, 0.5 CPU
erpnext: 2GB RAM, 1 CPU
mattermost: 1GB RAM, 0.5 CPU
keycloak: 1GB RAM, 0.5 CPU
grafana: 512MB RAM, 0.5 CPU
```

## 🔐 Security Configuration

### Container Security
- Non-root user execution
- Read-only file systems where possible
- Minimal base images (Alpine Linux)
- Regular security updates

### Network Security
- Internal Docker network isolation
- HTTPS termination at Nginx
- Database access via private network only
- No direct external access to application containers

### Data Protection
- Encrypted data at rest (Cloud SQL)
- SSL/TLS encryption in transit
- Regular automated backups
- Access logging and monitoring

---

*12 microservices - one powerful platform! 🚀*
