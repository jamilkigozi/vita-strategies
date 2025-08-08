#!/bin/bash

# Vita Strategies - Cloud Shell Deployment
set -e

echo "🚀 Starting Vita Strategies deployment via Cloud Shell..."

# Check existing secrets
echo "🔍 Checking secrets..."
bash scripts/setup-secrets.sh

# Ensure we're in the right directory
cd /home/$(whoami)/vita-strategies

# Set GCP project
PROJECT_ID=$(gcloud config get-value project)
echo "📋 Using GCP Project: $PROJECT_ID"

# Initialize Terraform
echo "🔧 Initializing Terraform..."
cd infrastructure/terraform
terraform init

# Apply infrastructure
echo "🏗️ Deploying infrastructure..."
terraform apply -auto-approve

# Get VM external IP
VM_IP=$(terraform output -raw vm_external_ip)
echo "🌐 VM External IP: $VM_IP"

# Deploy applications via startup script
echo "📦 Applications will be deployed via VM startup script"
echo "✅ Deployment complete!"
echo ""
echo "Next steps:"
echo "1. Configure Cloudflare tunnel with VM IP: $VM_IP"
echo "2. Set up DNS records in Cloudflare"
echo "3. Applications will be available on ports 8001-8008"