# Vita Strategies - Complete Microservices Architecture

## 🏗️ Infrastructure Overview
**Platform:** Google Cloud Platform with Terraform
**Database:** Cloud SQL (PostgreSQL/MySQL) 
**Deployment:** Docker Containers with systemd services
**Domain:** vitastrategies.com with SSL via Cloudflare

## 🔧 Complete Microservices Stack (12 Services)

### 1. **Mattermost** - Team Communication
- **Subdomain:** `chat.vitastrategies.com`
- **Purpose:** Slack alternative for team messaging
- **Database:** PostgreSQL (Cloud SQL)
- **Container:** Official Mattermost Docker image
- **Storage Bucket:** `vita-strategies-mattermost-production`

### 2. **Windmill.dev** - Workflow Automation
- **Subdomain:** `workflows.vitastrategies.com`
- **Purpose:** Open-source workflow automation and data processing
- **Database:** PostgreSQL (Cloud SQL)
- **Container:** windmill-community/windmill
- **Storage Bucket:** `vita-strategies-workflows-production`

### 3. **Appsmith** - Low-Code Application Builder
- **Subdomain:** `apps.vitastrategies.com`
- **Purpose:** Internal tools and dashboard builder
- **Database:** MongoDB (Cloud SQL equivalent or separate container)
- **Container:** appsmith/appsmith-ce
- **Storage Bucket:** `vita-strategies-appsmith-production`

### 4. **Metabase** - Business Intelligence
- **Subdomain:** `analytics.vitastrategies.com`
- **Purpose:** Data visualization and business analytics
- **Database:** PostgreSQL (Cloud SQL)
- **Container:** metabase/metabase
- **Storage Bucket:** `vita-strategies-analytics-production` ✅

### 5. **Grafana** - Monitoring & Observability
- **Subdomain:** `monitoring.vitastrategies.com`
- **Purpose:** System monitoring, metrics, and alerting
- **Database:** PostgreSQL (Cloud SQL) + Prometheus
- **Container:** grafana/grafana
- **Storage Bucket:** `vita-strategies-monitoring-production`

### 6. **OpenBao** - Secrets Management
- **Subdomain:** `vault.vitastrategies.com`
- **Purpose:** HashiCorp Vault alternative for secrets management
- **Database:** PostgreSQL (Cloud SQL)
- **Container:** openbao/openbao
- **Storage Bucket:** `vita-strategies-vault-production`

### 7. **Keycloak** - Identity & Access Management
- **Subdomain:** `auth.vitastrategies.com`
- **Purpose:** Single Sign-On (SSO) and user management
- **Database:** PostgreSQL (Cloud SQL)
- **Container:** quay.io/keycloak/keycloak
- **Storage Bucket:** `vita-strategies-auth-production`

### 8. **WordPress** - Content Management
- **Subdomain:** `www.vitastrategies.com` / `vitastrategies.com`
- **Purpose:** Company website and blog
- **Database:** MySQL (Cloud SQL)
- **Container:** wordpress:latest with custom config
- **Storage Bucket:** `vita-strategies-wordpress-production` ✅

### 9. **ERPNext** - Enterprise Resource Planning
- **Subdomain:** `erp.vitastrategies.com`
- **Purpose:** Business management, CRM, accounting
- **Database:** MariaDB (Cloud SQL)
- **Container:** frappe/erpnext
- **Storage Bucket:** `vita-strategies-erpnext-production` ✅

### 10. **BookStack** - Documentation Platform
- **Subdomain:** `docs.vitastrategies.com`
- **Purpose:** Internal documentation and knowledge base
- **Database:** MySQL (Cloud SQL)
- **Container:** lscr.io/linuxserver/bookstack
- **Storage Bucket:** `vita-strategies-docs-production`

### 11. **Nginx** - Reverse Proxy & Load Balancer
- **Subdomain:** All subdomains route through this
- **Purpose:** SSL termination, load balancing, static file serving
- **Container:** nginx:alpine with custom configuration
- **Storage Bucket:** `vita-strategies-assets-production` ✅

### 12. **Backup Service** - Data Protection
- **Purpose:** Automated backups of all databases and file storage
- **Container:** Custom backup container with gcsfuse
- **Storage Bucket:** `vita-strategies-data-backup-production` ✅

## 🗄️ Database Architecture (Cloud SQL)

### Primary Databases:
1. **PostgreSQL Instance** - Primary database server
   - Mattermost database
   - Windmill database  
   - Metabase database
   - Grafana database
   - OpenBao database
   - Keycloak database

2. **MySQL Instance** - Secondary database server
   - WordPress database
   - BookStack database

3. **MariaDB Instance** - ERP database server
   - ERPNext database

### Appsmith Database:
- MongoDB (either Cloud SQL equivalent or containerized)

## 🔄 Current Build Status

### ✅ **COMPLETED:**
- Terraform infrastructure (7 files, 811 lines)
- 5 existing storage buckets
- Domain and SSL configuration
- VM compute configuration
- Security and IAM setup

### 🔨 **NEEDS BUILDING:**
- Cloud SQL database instances (3 instances)
- 7 additional storage buckets
- 12 Docker container configurations
- Nginx reverse proxy configuration
- Service discovery and load balancing
- Backup automation scripts
- Monitoring and alerting setup

## 📁 Required Project Structure
```
apps/
├── mattermost/
├── windmill/
├── appsmith/
├── metabase/
├── grafana/
├── openbao/
├── keycloak/
├── wordpress/
├── erpnext/
├── bookstack/
├── nginx/
└── backup-service/

infrastructure/
├── terraform/              # ✅ COMPLETE
├── cloud-sql/              # 🔨 NEEDED
├── docker/                 # 🔨 NEEDED
└── monitoring/             # 🔨 NEEDED
```

## 🚀 Next Building Phase
**Recommendation:** Start with Cloud SQL databases, then build containers one by one.

Ready to continue building! 🏗️
