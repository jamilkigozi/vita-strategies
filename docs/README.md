# Documentation

This directory contains comprehensive documentation for the Vita Strategies microservices platform.

## 📚 Documentation Structure

### Core Documentation
- **[ARCHITECTURE.md](./ARCHITECTURE.md)** - System architecture and design decisions
- **[DEPLOYMENT.md](./DEPLOYMENT.md)** - Deployment procedures and requirements
- **[API-DOCUMENTATION.md](./API-DOCUMENTATION.md)** - API endpoints and integration guides
- **[SECURITY.md](./SECURITY.md)** - Security policies and best practices
- **[TROUBLESHOOTING.md](./TROUBLESHOOTING.md)** - Common issues and solutions

## 🏗️ Platform Overview

**Infrastructure:** Google Cloud Platform with Terraform
**Microservices:** 12 containerized applications
**Databases:** 3 Cloud SQL instances (PostgreSQL, MySQL, MariaDB)
**Domain:** vitastrategies.com with SSL via Cloudflare
**Deployment:** Docker containers with systemd services

## 🔧 Microservices Stack

1. **WordPress** - Company website (`vitastrategies.com`)
2. **ERPNext** - Business management (`erp.vitastrategies.com`)
3. **Mattermost** - Team communication (`chat.vitastrategies.com`)
4. **BookStack** - Documentation platform (`docs.vitastrategies.com`)
5. **Windmill** - Workflow automation (`workflows.vitastrategies.com`)
6. **Appsmith** - Low-code apps (`apps.vitastrategies.com`)
7. **Metabase** - Business intelligence (`analytics.vitastrategies.com`)
8. **Grafana** - System monitoring (`monitoring.vitastrategies.com`)
9. **Keycloak** - Identity management (`auth.vitastrategies.com`)
10. **OpenBao** - Secrets management (`vault.vitastrategies.com`)
11. **Nginx** - Reverse proxy and load balancer
12. **Backup Service** - Automated data protection

## 🚀 Quick Start

1. **Infrastructure Deployment**
   ```bash
   cd infrastructure/terraform
   terraform init && terraform apply
   ```

2. **Application Deployment**
   ```bash
   cd infrastructure/docker
   docker-compose up -d
   ```

3. **Service Access**
   - All services available via HTTPS with automatic SSL
   - Single Sign-On through Keycloak
   - Monitoring via Grafana dashboard

## 📞 Support

For technical issues, deployment questions, or platform support:
- Check [TROUBLESHOOTING.md](./TROUBLESHOOTING.md) first
- Review service-specific documentation in `/apps/[service]/README.md`
- Monitor system health at `monitoring.vitastrategies.com`

---

*Complete platform documentation - build with confidence! 🏗️*
