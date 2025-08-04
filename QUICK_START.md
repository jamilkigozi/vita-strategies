# Quick Start Guide

## Prerequisites
- Google Cloud Platform account with billing enabled
- `gcloud` CLI installed and configured
- Terraform installed

## 1. Initial Setup

```bash
# Clone repository
git clone https://github.com/jamilkigozi/vita-strategies.git
cd vita-strategies

# Set your GCP project
export PROJECT_ID="your-gcp-project-id"
gcloud config set project $PROJECT_ID
```

## 2. Deploy Infrastructure

```bash
cd infrastructure/terraform

# Initialize Terraform
terraform init

# Review and apply infrastructure
terraform plan
terraform apply
```

## 3. Set Up CI/CD

```bash
# Create Cloud Build trigger
gcloud builds triggers create github \
  --repo-name=vita-strategies \
  --repo-owner=jamilkigozi \
  --branch-pattern=main \
  --build-config=cloudbuild.yaml
```

## 4. Deploy Services

```bash
# Push to trigger deployment
git push origin main
```

## 5. Access Services

After deployment, services will be available at:
- Main site: `https://vitastrategies.com`
- ERP: `https://erp.vitastrategies.com`
- Chat: `https://chat.vitastrategies.com`

## Troubleshooting

Check Cloud Build logs:
```bash
gcloud builds list --limit=5
gcloud builds log BUILD_ID
```

Check service status:
```bash
gcloud run services list
```