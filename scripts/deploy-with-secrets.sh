#!/bin/bash
# VITA STRATEGIES - SECURE GCP DEPLOYMENT SCRIPT
# Enhanced version with Google Secret Manager integration

set -e

echo "🚀 VITA STRATEGIES - SECURE GCP DEPLOYMENT"
echo "========================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_status() {
    if [ $1 -eq 0 ]; then
        echo -e "${GREEN}✅ $2${NC}"
    else
        echo -e "${RED}❌ $2${NC}"
        exit 1
    fi
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

# Ensure gcloud is authenticated
gcloud auth list --filter=status:ACTIVE --format="value(account)" | head -n 1 || {
    echo "Please authenticate with gcloud first"
    gcloud auth login
}

# Set project
PROJECT_ID=$(gcloud config get-value project)
echo "Using GCP Project: $PROJECT_ID"

# Make scripts executable
chmod +x scripts/*.sh

# Create secrets if they don't exist
echo "Setting up Google Secret Manager..."
if [ -f "fetch_secrets.py" ]; then
    python3 fetch_secrets.py > /tmp/secrets.env
    source /tmp/secrets.env
    print_status 0 "Secrets fetched from Google Secret Manager"
else
    print_warning "fetch_secrets.py not found, using local secrets"
fi

# Step 1: Generate secure passwords if needed
echo ""
echo "1️⃣  CHECKING PASSWORDS"
echo "---------------------"

if grep -q "generate-strong-password-here" infrastructure/terraform/terraform.tfvars; then
    echo "Generating secure passwords..."
    ./scripts/generate-passwords.sh
    print_status 0 "Passwords generated"
else
    print_status 0 "Passwords already configured"
fi

# Step 2: Initialize Terraform
echo ""
echo "2️⃣  INITIALIZING TERRAFORM"
echo "-------------------------"

cd infrastructure/terraform
if terraform init; then
    print_status 0 "Terraform initialized successfully"
else
    print_status 1 "Terraform initialization failed"
fi

# Step 3: Plan the deployment
echo ""
echo "3️⃣  PLANNING DEPLOYMENT"
echo "----------------------"

if terraform plan -out=tfplan; then
    print_status 0 "Terraform plan created successfully"
else
    print_status 1 "Terraform plan failed"
fi

# Step 4: Apply the Terraform configuration
echo ""
echo "4️⃣  DEPLOYING INFRASTRUCTURE"
echo "---------------------------"

echo -e "${YELLOW}⚠️  You are about to deploy infrastructure to Google Cloud Platform.${NC}"
echo -e "${YELLOW}⚠️  This will incur costs on your GCP account.${NC}"
read -p "Are you sure you want to proceed? (y/n): " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
    if terraform apply tfplan; then
        print_status 0 "Infrastructure deployed successfully"
    else
        print_status 1 "Infrastructure deployment failed"
    fi
else
    echo "Deployment cancelled by user."
    exit 0
fi

# Step 5: Output deployment information
echo ""
echo "5️⃣  DEPLOYMENT INFORMATION"
echo "-------------------------"

echo "Extracting deployment information..."
terraform output

# Return to the project root
cd ../..

# Step 6: Health check
echo ""
echo "6️⃣  HEALTH CHECK"
echo "----------------"

echo "Running health checks..."
./scripts/health-check.sh

echo ""
echo "🎉 SECURE DEPLOYMENT COMPLETE!"
echo "=============================="
echo ""
echo "Your Vita Strategies infrastructure has been successfully deployed to Google Cloud Platform."
echo ""
echo "Next steps:"
echo "1. Wait 5-10 minutes for all services to start"
echo "2. Access your services using the URLs provided above"
echo "3. Monitor logs with: gcloud compute ssh vita-vm --command='docker-compose logs -f'"
echo ""
echo "For any issues, check the logs or run: ./scripts/health-check.sh"
