#!/bin/bash
# VITA STRATEGIES - SAFE DEPLOYMENT SCRIPT
# Purpose: Deploy infrastructure while preserving existing resources

set -e

echo "🛡️  VITA STRATEGIES - SAFE DEPLOYMENT"
echo "====================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print status
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

# Step 1: Check for existing deployment
echo ""
echo "1️⃣  CHECKING EXISTING DEPLOYMENT"
echo "-------------------------------"

# Check if terraform state exists
if [ -f "infrastructure/terraform/terraform.tfstate" ]; then
    print_warning "Existing Terraform state found. Will preserve existing resources."
    EXISTING_DEPLOYMENT=true
else
    echo "No existing deployment found. Will perform fresh deployment."
    EXISTING_DEPLOYMENT=false
fi

# Step 2: Backup existing state if it exists
if [ "$EXISTING_DEPLOYMENT" = true ]; then
    echo ""
    echo "2️⃣  BACKING UP EXISTING STATE"
    echo "---------------------------"
    
    BACKUP_DIR="infrastructure/terraform/backups"
    BACKUP_FILE="$BACKUP_DIR/terraform.tfstate.$(date +%Y%m%d%H%M%S).backup"
    
    mkdir -p "$BACKUP_DIR"
    cp infrastructure/terraform/terraform.tfstate "$BACKUP_FILE"
    print_status $? "Terraform state backed up to $BACKUP_FILE"
fi

# Step 3: Initialize Terraform
echo ""
echo "3️⃣  INITIALIZING TERRAFORM"
echo "-------------------------"

cd infrastructure/terraform
if terraform init; then
    print_status 0 "Terraform initialized successfully"
else
    print_status 1 "Terraform initialization failed"
fi

# Step 4: Plan the deployment with safeguards
echo ""
echo "4️⃣  PLANNING DEPLOYMENT"
echo "----------------------"

# Use -refresh-only first to update state without planning changes
if [ "$EXISTING_DEPLOYMENT" = true ]; then
    echo "Refreshing state to detect any drift..."
    terraform plan -refresh-only -out=tfplan.refresh
    
    # Check for resource destruction
    DESTROY_COUNT=$(terraform show -json tfplan.refresh | grep -c '"destroy": true')
    if [ "$DESTROY_COUNT" -gt 0 ]; then
        print_warning "Detected $DESTROY_COUNT resources that would be destroyed!"
        print_warning "This could result in data loss. Proceeding with caution."
    fi
fi

# Create plan with target-specific approach if existing deployment
if [ "$EXISTING_DEPLOYMENT" = true ]; then
    echo "Creating targeted plan to preserve existing resources..."
    
    # Only target resources that need updating
    # This is safer than applying to everything
    terraform plan -out=tfplan -target=google_compute_instance.main
else
    # For fresh deployment, plan everything
    terraform plan -out=tfplan
fi

print_status $? "Terraform plan created successfully"

# Step 5: Review the plan
echo ""
echo "5️⃣  REVIEWING DEPLOYMENT PLAN"
echo "----------------------------"

terraform show tfplan

echo ""
if [ "$EXISTING_DEPLOYMENT" = true ]; then
    print_warning "You are about to update an existing deployment."
    print_warning "This operation will attempt to preserve your data, but backups are recommended."
else
    echo "You are about to perform a fresh deployment."
fi

# Step 6: Apply the Terraform configuration
echo ""
echo "6️⃣  DEPLOYING INFRASTRUCTURE"
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

# Step 7: Output deployment information
echo ""
echo "7️⃣  DEPLOYMENT INFORMATION"
echo "-------------------------"

echo "Extracting deployment information..."
terraform output

# Return to the project root
cd ../..

echo ""
echo "🎉 DEPLOYMENT COMPLETE!"
echo "======================"
echo ""
echo "Your Vita Strategies infrastructure has been successfully deployed to Google Cloud Platform."
echo ""
echo "Next steps:"
echo "1. Wait a few minutes for all services to start"
echo "2. Run: ./scripts/health-check.sh to verify all services are running"
echo "3. Access your services using the URLs provided above"
echo ""
echo "For any issues, check the logs using: gcloud compute ssh vita-vm --command='docker-compose logs -f'"