# Vita Strategies - Microservices Platform

## 🚀 Current Status
**Docker microservices deployment in progress** - ERPNext partially working with CSS/JS loading issues. See latest commit for detailed status.

## 📁 Repository Structure

### Core Applications
- `/apps/` - Individual application configurations
  - `erpnext/` - Business management system
  - `windmill/` - Workflow automation
  - `metabase/` - Business intelligence
  - `mattermost/` - Team communication
  - `grafana/` - Monitoring dashboard

### Infrastructure
- `/infrastructure/` - Terraform and deployment scripts
  - `terraform/` - GCP infrastructure as code
  - `docker/` - Docker configurations
- `/docker/` - Docker Compose files and configurations
- `/scripts/` - Deployment and management scripts

### Configuration
- `/config/` - Environment and application configs
- `/nginx/` - Nginx reverse proxy configurations
- `/postgres/` - Database initialization scripts

## 🔧 Quick Start

1. **Clone Repository**
   ```bash
   git clone https://github.com/jamilkigozi/vita-strategies.git
   cd vita-strategies
   ```

2. **Review Latest Status**
   - Check `BUILD-PROGRESS.md` for deployment status
   - See `DEPLOYMENT-STATUS.md` for current issues
   - Review `CREDENTIAL_AUDIT.md` for security status

## 🎯 Current Deployment Issues
- Container persistence problems when IDE updates
- ERPNext CSS/JavaScript loading inconsistently
- Static asset serving through nginx needs optimization
- Production readiness requires professional DevOps consultation

## 📞 Professional Consultation Needed
This repository contains a partially working microservices deployment that requires professional DevOps expertise for production stability.

**Key Issues**: Container persistence, static asset serving, configuration drift
**Repository**: `https://github.com/jamilkigozi/vita-strategies`
**Latest Commit**: `43c726c` with detailed progress notes

---
*Last Updated: August 4, 2025*
