# 🏗️ VITA STRATEGIES PLATFORM ARCHITECTURE

## 🌐 OVERALL SYSTEM DIAGRAM
```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           🌍 CLOUDFLARE GLOBAL CDN                          │
│                     (DNS, SSL, WAF, DDoS Protection)                        │
└─────────────────────────┬───────────────────────────────────────────────────┘
                          │
┌─────────────────────────▼───────────────────────────────────────────────────┐
│                        ☁️  GOOGLE CLOUD PLATFORM                            │
│                                                                             │
│  ┌─────────────────────────────────────────────────────────────────────┐    │
│  │                    🖥️  COMPUTE ENGINE VM                            │    │
│  │                  (e2-standard-4: 4 vCPUs, 16GB RAM)                 │    │
│  │                                                                     │    │
│  │  ┌─────────────────────────────────────────────────────────────┐    │    │
│  │  │                   🐳 DOCKER COMPOSE                        │    │    │
│  │  │                                                           │    │    │
│  │  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐       │    │    │
│  │  │  │    NGINX    │  │   ERPNEXT   │  │  WINDMILL   │       │    │    │
│  │  │  │ Reverse     │  │     ERP     │  │  Workflow   │       │    │    │
│  │  │  │   Proxy     │  │   System    │  │ Automation  │       │    │    │
│  │  │  └─────────────┘  └─────────────┘  └─────────────┘       │    │    │
│  │  │                                                           │    │    │
│  │  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐       │    │    │
│  │  │  │  KEYCLOAK   │  │   METABASE  │  │  APPSMITH   │       │    │    │
│  │  │  │   Identity  │  │  Business   │  │  Low-Code   │       │    │    │
│  │  │  │ Management  │  │ Intelligence │  │  Platform   │       │    │    │
│  │  │  └─────────────┘  └─────────────┘  └─────────────┘       │    │    │
│  │  │                                                           │    │    │
│  │  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐       │    │    │
│  │  │  │ MATTERMOST  │  │   GRAFANA   │  │    REDIS    │       │    │    │
│  │  │  │    Team     │  │ Monitoring  │  │   Cache &   │       │    │    │
│  │  │  │    Chat     │  │ Dashboard   │  │    Queue    │       │    │    │
│  │  │  └─────────────┘  └─────────────┘  └─────────────┘       │    │    │
│  │  └─────────────────────────────────────────────────────────────┘    │    │
│  └─────────────────────────────────────────────────────────────────────┘    │
│                                                                             │
│  ┌─────────────────────┐              ┌─────────────────────┐              │
│  │   📊 CLOUD SQL      │              │   📊 CLOUD SQL      │              │
│  │      MySQL          │              │    PostgreSQL       │              │
│  │   (ERPNext DB)      │              │  (Other Services)   │              │
│  │   - Automated       │              │   - Automated       │              │
│  │     Backups         │              │     Backups         │              │
│  │   - Read Replicas   │              │   - Read Replicas   │              │
│  └─────────────────────┘              └─────────────────────┘              │
└─────────────────────────────────────────────────────────────────────────────┘
```

## 🎯 SERVICE ROUTING DIAGRAM
```
Internet Traffic
        │
        ▼
   🌐 Cloudflare CDN
   (Global Edge Cache)
        │
        ▼
   🔒 Cloudflare Security
   (WAF, DDoS, SSL)
        │
        ▼
   📡 DNS Resolution
        │
        ├─── erp.vitastrategies.com ────────────────┐
        ├─── workflows.vitastrategies.com ──────────┤
        ├─── auth.vitastrategies.com ───────────────┤
        ├─── analytics.vitastrategies.com ──────────┤
        ├─── apps.vitastrategies.com ───────────────┤
        ├─── chat.vitastrategies.com ───────────────┤
        └─── monitoring.vitastrategies.com ─────────┤
                                                   │
                                                   ▼
                                           🖥️ GCP Compute VM
                                                   │
                                                   ▼
                                              🐳 Nginx Proxy
                                                   │
        ┌──────────────┬──────────────┬──────────────┼──────────────┬──────────────┬──────────────┐
        ▼              ▼              ▼              ▼              ▼              ▼              ▼
   📊 ERPNext     🔄 Windmill    🔐 Keycloak   📈 Metabase   🔧 Appsmith   💬 Mattermost  📊 Grafana
   (Port 8080)    (Port 8000)   (Port 8080)   (Port 3000)   (Port 80)     (Port 8065)   (Port 3000)
```

## 💰 COST BREAKDOWN (Monthly)
```
┌─────────────────────────────────────────────────────────────┐
│                     💵 MONTHLY COSTS                        │
├─────────────────────────────────────────────────────────────┤
│ Compute Engine VM (e2-standard-4)           │ ~$120/month   │
│ Cloud SQL MySQL (db-f1-micro)              │ ~$15/month    │
│ Cloud SQL PostgreSQL (db-f1-micro)         │ ~$15/month    │
│ Persistent Disk (100GB SSD)                │ ~$10/month    │
│ Network Egress                             │ ~$5/month     │
│ Cloudflare Pro Plan                        │ $20/month     │
├─────────────────────────────────────────────────────────────┤
│ TOTAL ESTIMATED COST                       │ ~$185/month   │
└─────────────────────────────────────────────────────────────┘
```

## 📁 REPOSITORY STRUCTURE DIAGRAM
```
vita-strategies/
├── 📋 README.md (Updated Architecture Guide)
├── 🚀 deploy.sh (One-Click Deployment Script)
├── ⚙️  .env.prod (GCP Production Configuration)
│
├── 🏗️  gcp-infrastructure/
│   ├── terraform/ (Infrastructure as Code)
│   │   ├── main.tf (Single VM + Cloud SQL)
│   │   ├── variables.tf (Configuration Variables)
│   │   └── outputs.tf (IP Addresses & Endpoints)
│   ├── docker-compose/ (Application Stack)
│   │   ├── docker-compose.yml (All 7 Services)
│   │   ├── .env (Runtime Environment)
│   │   └── nginx/nginx.conf (Reverse Proxy Config)
│   ├── startup-scripts/ (VM Initialization)
│   │   └── install-docker.sh (Docker Setup Script)
│   └── cloudflare/ (CDN & Security)
│       └── terraform/ (DNS & WAF Configuration)
│
├── 🔧 applications/ (Service Configurations)
│   ├── erpnext/ (Core ERP System)
│   ├── windmill/ (Workflow Automation)
│   ├── keycloak/ (Identity Management)
│   ├── metabase/ (Business Intelligence)
│   ├── appsmith/ (Low-Code Platform)
│   ├── mattermost/ (Team Collaboration)
│   └── grafana/ (Monitoring Dashboard)
│
├── 📊 data-platform/ (Data Management)
│   ├── schemas/ (Database Schemas)
│   ├── migrations/ (Database Migrations)
│   ├── analytics/ (Business Analytics)
│   └── backups/ (Backup Configurations)
│
├── 🔒 security/ (Security Configuration)
│   ├── iam/ (GCP IAM Policies)
│   ├── secrets/ (Secret Management)
│   ├── certificates/ (SSL/TLS Certificates)
│   └── policies/ (Security Policies)
│
└── 🚀 ci-cd/ (DevOps Automation)
    ├── workflows/ (GitHub Actions)
    ├── scripts/ (Deployment Scripts)
    └── templates/ (Reusable Templates)
```

## 🎯 DATA FLOW DIAGRAM
```
┌─────────────────────────────────────────────────────────────────────────────┐
│                            📊 DATA FLOWS                                    │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  User Request → Cloudflare → GCP VM → Nginx → Application                  │
│                     ↓           ↓        ↓         ↓                       │
│                   Cache    Load Balance  Route   Process                    │
│                                                      ↓                      │
│                              Database ←─────────────┘                       │
│                                 ↓                                           │
│                              Response                                       │
│                                 ↓                                           │
│                         Cache & Return                                     │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

## 🔄 DEPLOYMENT FLOW
```
Developer → GitHub → Local Machine → GCP
    │         │          │            │
    │         │          │            ▼
    │         │          │      ┌─────────────┐
    │         │          │      │ Terraform   │
    │         │          │      │ Creates VM  │
    │         │          │      │ & Databases │
    │         │          │      └─────────────┘
    │         │          │            │
    │         │          │            ▼
    │         │          │      ┌─────────────┐
    │         │          │      │Docker Setup │
    │         │          │      │   Script    │
    │         │          │      │  Installs   │
    │         │          │      └─────────────┘
    │         │          │            │
    │         │          │            ▼
    │         │          │      ┌─────────────┐
    │         │          └─────▶│Docker       │
    │         │                 │Compose      │
    │         │                 │Deployment   │
    │         │                 └─────────────┘
    │         │                       │
    │         │                       ▼
    │         │                 ┌─────────────┐
    │         └────────────────▶│ Cloudflare  │
    │                           │    DNS      │
    │                           │ & Security  │
    │                           └─────────────┘
    │                                 │
    │                                 ▼
    └─────────────────────────┐ ┌─────────────┐
                              │ │   LIVE      │
                              └▶│ PLATFORM    │
                                └─────────────┘
```
