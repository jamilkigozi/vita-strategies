# ERPNext Configuration for GCP Deployment

## Overview
ERPNext deployment configuration for Google Cloud Platform using Cloud SQL (MySQL), Memorystore (Redis), and GKE.

## Architecture
- **Database**: Cloud SQL MySQL 8.0 with read replicas
- **Cache**: Memorystore Redis for caching and queue management  
- **Storage**: Cloud Storage for file attachments and backups
- **Compute**: GKE with horizontal pod autoscaling
- **Security**: IAM service accounts with least privilege access

## Configuration Files
- `kubernetes/` - Kubernetes manifests for GKE deployment
- `database/` - Database initialization and migration scripts
- `config/` - ERPNext site configuration templates
- `security/` - IAM policies and service account configurations

## Environment Variables
All sensitive configurations are managed via Google Secret Manager:
- Database credentials
- Redis connection strings
- SMTP configuration
- Encryption keys
- API tokens

## Deployment Process
1. Database setup via Cloud SQL
2. Redis cluster via Memorystore
3. Kubernetes deployment to GKE
4. Site creation and configuration
5. DNS and SSL setup via Cloudflare

## Monitoring
- Cloud Monitoring for infrastructure metrics
- Application Performance Monitoring for ERPNext
- Custom dashboards in Grafana
- Alerting via Cloud Monitoring and Slack
