#!/bin/bash
# Comprehensive Workspace Cleanup - Remove Redundant Files
set -e

echo "🧹 Starting comprehensive workspace cleanup..."

# Remove redundant Docker Compose files
echo "📦 Removing redundant Docker Compose files..."
rm -f docker-compose.yml
rm -f docker-compose.override.yml
rm -f docker-compose.yml.broken
rm -f build-only.yaml

# Remove empty nginx directory
echo "🌐 Removing empty nginx directory..."
rm -rf apps/nginx/

# Remove empty monitoring directory
echo "📊 Removing empty monitoring directory..."
rm -rf infrastructure/monitoring/

# Remove broken Terraform files
echo "🏗️ Removing broken Terraform files..."
rm -f infrastructure/terraform/main.tf.broken
rm -f infrastructure/terraform/security.tf

# Remove redundant scripts
echo "📜 Removing redundant deployment scripts..."
rm -f scripts/deploy.sh
rm -f scripts/deploy-to-vm.sh
rm -f scripts/setup-cloudflare.sh
rm -f scripts/check-gcp-prerequisites.sh
rm -f scripts/create-secrets.sh
rm -f scripts/deploy-cloudflare.sh
rm -f scripts/fetch_secrets.sh
rm -f scripts/fix-infrastructure.sh
rm -f scripts/generate-passwords.sh
rm -f scripts/get-db-ips.sh
rm -f scripts/health-check.sh
rm -f scripts/setup-secrets.sh
rm -f scripts/test-safe-deployment.sh
rm -f scripts/update-firewall-cloudflare.sh
rm -f scripts/validate-deployment-ready.sh
rm -f scripts/validate-deployment.sh

# Remove redundant documentation
echo "📚 Removing redundant documentation..."
rm -rf docs/analysis/

# Remove backup directory
echo "🗂️ Removing backup directory..."
rm -rf backup/

# Remove postgres init scripts (not needed with Cloud SQL)
echo "🗄️ Removing postgres init scripts..."
rm -rf postgres/

# Remove cloudflare directory (tunnel config handled differently)
echo "☁️ Removing cloudflare directory..."
rm -rf cloudflare/

# Remove redundant env files
echo "🔐 Removing redundant env files..."
rm -f .env.example

# Remove redundant Terraform files
echo "🏗️ Removing redundant Terraform files..."
rm -f infrastructure/terraform/terraform.tfvars.example
rm -f infrastructure/terraform/tfplan
rm -f infrastructure/terraform/tfplan.refresh

# Remove cleanup summary files
echo "📋 Removing cleanup summary files..."
rm -f CLEANUP-IMPLEMENTATION-SUMMARY.md

# Remove deepsource config (not needed)
echo "🔍 Removing deepsource config..."
rm -f .deepsource.toml

echo "✅ Workspace cleanup completed!"
echo ""
echo "Remaining structure:"
echo "- docker-compose.cloudflare.yml (main deployment file)"
echo "- infrastructure/terraform/ (infrastructure as code)"
echo "- scripts/deploy-cloudshell.sh (deployment script)"
echo "- scripts/cleanup-workspace.sh (this cleanup script)"
echo "- apps/ (application configurations)"
echo "- docs/ (essential documentation)"
echo "- .env, .env.template, .gitignore (configuration files)"