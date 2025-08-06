#!/bin/bash
# VITA STRATEGIES - DEPLOYMENT VALIDATION SCRIPT
# Purpose: Validate all configurations before GCP deployment

set -e

echo "🔍 VITA STRATEGIES - DEPLOYMENT VALIDATION"
echo "=========================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Validation counters
ERRORS=0
WARNINGS=0
PASSED=0

# Function to print status
print_status() {
    if [ $1 -eq 0 ]; then
        echo -e "${GREEN}✅ $2${NC}"
        ((PASSED++))
    else
        echo -e "${RED}❌ $2${NC}"
        ((ERRORS++))
    fi
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
    ((WARNINGS++))
}

echo ""
echo "1️⃣  SECURITY VALIDATION"
echo "------------------------"

# Check for hardcoded credentials
echo "Checking for hardcoded credentials..."
if grep -r "WFcBUZM0zXBEMqx5Vb7_KGqGCAxw4PBL9p5JVvBa" infrastructure/terraform/ 2>/dev/null; then
    print_status 1 "Cloudflare API token found in code"
else
    print_status 0 "No hardcoded Cloudflare API token"
fi

if grep -r "mattermost_secure_password_123" infrastructure/terraform/ 2>/dev/null; then
    print_status 1 "Database passwords found in code"
else
    print_status 0 "No hardcoded database passwords"
fi

# Check terraform.tfvars exists
if [ -f "infrastructure/terraform/terraform.tfvars" ]; then
    print_status 0 "terraform.tfvars file exists"
else
    print_status 1 "terraform.tfvars file missing"
fi

# Check .gitignore
if grep -q "terraform.tfvars" .gitignore 2>/dev/null; then
    print_status 0 "terraform.tfvars in .gitignore"
else
    print_warning "Add terraform.tfvars to .gitignore"
fi

echo ""
echo "2️⃣  TERRAFORM CONFIGURATION"
echo "---------------------------"

# Check if terraform is installed
if command -v terraform &> /dev/null; then
    print_status 0 "Terraform is installed"
    terraform_version=$(terraform version -json | jq -r '.terraform_version')
    echo "   Version: $terraform_version"
else
    print_status 1 "Terraform is not installed"
fi

# Validate terraform configuration
cd infrastructure/terraform
if terraform init -backend=false &>/dev/null; then
    print_status 0 "Terraform init successful"
else
    print_status 1 "Terraform init failed"
fi

if terraform validate &>/dev/null; then
    print_status 0 "Terraform configuration valid"
else
    print_status 1 "Terraform configuration invalid"
    terraform validate
fi

cd ../..

echo ""
echo "3️⃣  GCP REQUIREMENTS"
echo "--------------------"

# Check for gcloud
if command -v gcloud &> /dev/null; then
    print_status 0 "Google Cloud SDK is installed"
    gcloud_version=$(gcloud version --format="value(core)")
    echo "   Version: $gcloud_version"
else
    print_status 1 "Google Cloud SDK is not installed"
fi

# Check for project configuration
if [ -f "$HOME/.config/gcloud/configurations/config_default" ]; then
    print_status 0 "Google Cloud SDK configured"
else
    print_warning "Google Cloud SDK not configured"
fi

echo ""
echo "4️⃣  DOCKER CONFIGURATION"
echo "------------------------"

# Check docker
if command -v docker &> /dev/null; then
    print_status 0 "Docker is installed"
    docker_version=$(docker --version | cut -d' ' -f3 | cut -d',' -f1)
    echo "   Version: $docker_version"
else
    print_status 1 "Docker is not installed"
fi

# Check docker-compose
if command -v docker-compose &> /dev/null; then
    print_status 0 "Docker Compose is installed"
else
    print_status 1 "Docker Compose is not installed"
fi

echo ""
echo "5️⃣  FILE PERMISSIONS"
echo "-------------------"

# Check script permissions
for script in scripts/*.sh; do
    if [ -x "$script" ]; then
        print_status 0 "$script is executable"
    else
        print_status 1 "$script is not executable"
        chmod +x "$script"
    fi
done

echo ""
echo "6️⃣  CONFIGURATION FILES"
echo "----------------------"

# Check required files exist
required_files=(
    "infrastructure/terraform/main.tf"
    "infrastructure/terraform/variables.tf"
    "infrastructure/terraform/security.tf"
    "infrastructure/terraform/startup-script.sh"
    "scripts/generate-passwords.sh"
    "scripts/health-check.sh"
    "scripts/validate-deployment.sh"
)

for file in "${required_files[@]}"; do
    if [ -f "$file" ]; then
        print_status 0 "$file exists"
    else
        print_status 1 "$file missing"
    fi
done

echo ""
echo "7️⃣  SECURITY SCAN"
echo "-----------------"

# Check for common security issues
echo "Scanning for security issues..."

# Check for exposed ports
if grep -r "0.0.0.0/0" infrastructure/terraform/ | grep -v "allow_http_https" | grep -v "example" &>/dev/null; then
    print_warning "Found potentially insecure firewall rules"
else
    print_status 0 "Firewall rules appear secure"
fi

# Check for encryption
if grep -r "encryption" infrastructure/terraform/ &>/dev/null; then
    print_status 0 "Encryption configured"
else
    print_warning "Encryption not explicitly configured"
fi

echo ""
echo "8️⃣  DEPLOYMENT READINESS"
echo "-----------------------"

# Check if all variables are defined
if grep -q "your-" infrastructure/terraform/terraform.tfvars 2>/dev/null; then
    print_status 1 "Configuration contains placeholder values"
else
    print_status 0 "Configuration appears complete"
fi

echo ""
echo "📊 VALIDATION SUMMARY"
echo "====================="
echo -e "✅ Passed: ${GREEN}$PASSED${NC}"
echo -e "⚠️  Warnings: ${YELLOW}$WARNINGS${NC}"
echo -e "❌ Errors: ${RED}$ERRORS${NC}"

if [ $ERRORS -eq 0 ]; then
    echo ""
    echo -e "${GREEN}🚀 DEPLOYMENT READY!${NC}"
    echo "Your infrastructure is ready for deployment to GCP"
    echo ""
    echo "Next steps:"
    echo "1. Review and update terraform.tfvars with your values"
    echo "2. Run: ./scripts/generate-passwords.sh"
    echo "3. Run: cd infrastructure/terraform && terraform init && terraform plan"
    echo "4. Run: terraform apply"
else
    echo ""
    echo -e "${RED}❌ DEPLOYMENT NOT READY${NC}"
    echo "Please fix the errors above before proceeding"
    exit 1
fi