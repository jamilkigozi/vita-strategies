# Vita Strategies - Cloud-Native Microservices Platform

## 🚀 Overview
Production-ready microservices platform deployed on Google Cloud Platform with Cloud Run, Cloud SQL, and automated CI/CD.

## 📁 Repository Structure

```
vita-strategies/
├── apps/                    # Microservice applications
│   ├── erpnext/            # Business management system
│   ├── windmill/           # Workflow automation
│   ├── metabase/           # Business intelligence
│   ├── mattermost/         # Team communication
│   ├── grafana/            # Monitoring dashboard
│   ├── keycloak/           # Authentication service
│   ├── openbao/            # Secrets management
│   ├── appsmith/           # Low-code platform
│   └── wordpress/          # Website CMS
├── infrastructure/         # Infrastructure as Code
│   └── terraform/          # GCP infrastructure definitions
├── scripts/               # Deployment and management scripts
├── docs/                  # Documentation
└── cloudbuild.yaml        # CI/CD pipeline
```

## 🏗️ Architecture

- **Cloud Run**: Serverless container platform for all microservices
- **Cloud SQL**: Managed PostgreSQL and MySQL databases
- **Cloud Storage**: File storage with GCS buckets
- **Secret Manager**: Secure credential storage
- **Cloud Build**: Automated CI/CD pipeline

## 🚀 Quick Deployment

1. **Set up GCP Project**:
   ```bash
   gcloud config set project YOUR_PROJECT_ID
   ```

2. **Deploy Infrastructure**:
   ```bash
   cd infrastructure/terraform
   terraform init
   terraform apply
   ```

3. **Deploy Applications**:
   ```bash
   git push origin main  # Triggers Cloud Build
   ```

## 🔧 Configuration

All configuration is managed through:
- **Terraform variables** in `infrastructure/terraform/terraform.tfvars`
- **Secret Manager** for sensitive credentials
- **Environment variables** in Cloud Run services

## 📊 Services

| Service | URL | Purpose |
|---------|-----|---------|
| WordPress | `vitastrategies.com` | Main website |
| ERPNext | `erp.vitastrategies.com` | Business management |
| Mattermost | `chat.vitastrategies.com` | Team communication |
| Windmill | `workflows.vitastrategies.com` | Workflow automation |
| Metabase | `analytics.vitastrategies.com` | Business intelligence |
| Grafana | `monitoring.vitastrategies.com` | System monitoring |
| Keycloak | `auth.vitastrategies.com` | Authentication |
| OpenBao | `vault.vitastrategies.com` | Secrets management |
| Appsmith | `apps.vitastrategies.com` | Low-code platform |

## 🔒 Security

- All services use HTTPS with automatic SSL certificates
- Secrets managed through Google Secret Manager
- Database access restricted to private networks
- Regular security scanning with automated updates

## 📚 Documentation

- [Quick Start Guide](docs/README.md)
- [Deployment Guide](docs/DEPLOYMENT.md)
- [DevOps Journey](docs/DEVOPS_JOURNEY.md)

## 🤝 Support

For technical support or questions, contact the development team.

---
*Cloud-native microservices platform built for scalability and security.*