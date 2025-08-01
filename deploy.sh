#!/bin/bash

# Vita Strategies Deployment Script
# Simple deployment for solo developers on GCP

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}🚀 Vita Strategies Deployment Script${NC}"
echo "================================================"

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check prerequisites
echo -e "${YELLOW}📋 Checking prerequisites...${NC}"

if ! command_exists terraform; then
    echo -e "${RED}❌ Terraform not found. Please install Terraform first.${NC}"
    exit 1
fi

if ! command_exists gcloud; then
    echo -e "${RED}❌ Google Cloud SDK not found. Please install gcloud first.${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Prerequisites check passed${NC}"

# Get configuration
read -p "Enter your GCP Project ID: " PROJECT_ID
read -p "Enter your domain name (e.g., vitastrategies.com): " DOMAIN_NAME
read -s -p "Enter MySQL password: " MYSQL_PASSWORD
echo
read -s -p "Enter PostgreSQL password: " POSTGRES_PASSWORD
echo

# Create terraform.tfvars
cat > gcp-infrastructure/terraform/terraform.tfvars << EOF
project_id = "$PROJECT_ID"
domain_name = "$DOMAIN_NAME"
mysql_password = "$MYSQL_PASSWORD"
postgres_password = "$POSTGRES_PASSWORD"
EOF

echo -e "${GREEN}✅ Configuration saved${NC}"

# Deploy infrastructure
echo -e "${YELLOW}🏗️  Deploying GCP infrastructure...${NC}"
cd gcp-infrastructure/terraform

terraform init
terraform plan
read -p "Do you want to apply these changes? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    terraform apply -auto-approve
    echo -e "${GREEN}✅ Infrastructure deployed successfully${NC}"
else
    echo -e "${YELLOW}⚠️  Infrastructure deployment cancelled${NC}"
    exit 1
fi

# Get VM IP
VM_IP=$(terraform output -raw vm_external_ip)
MYSQL_IP=$(terraform output -raw mysql_ip)
POSTGRES_IP=$(terraform output -raw postgres_ip)

echo -e "${GREEN}📋 Deployment Information:${NC}"
echo "VM IP: $VM_IP"
echo "MySQL IP: $MYSQL_IP"
echo "PostgreSQL IP: $POSTGRES_IP"

# Create environment file for VM
cat > ../docker-compose/.env << EOF
MYSQL_HOST=$MYSQL_IP
MYSQL_PASSWORD=$MYSQL_PASSWORD
POSTGRES_HOST=$POSTGRES_IP
POSTGRES_USER=postgres
POSTGRES_PASSWORD=$POSTGRES_PASSWORD
DOMAIN_NAME=$DOMAIN_NAME
KEYCLOAK_ADMIN_PASSWORD=admin123
APPSMITH_ENCRYPTION_PASSWORD=appsmith-encrypt-2024
APPSMITH_ENCRYPTION_SALT=appsmith-salt-2024
GRAFANA_ADMIN_PASSWORD=admin123
EOF

echo -e "${GREEN}✅ Environment file created${NC}"

# Copy files to VM
echo -e "${YELLOW}📁 Copying files to VM...${NC}"
gcloud compute scp --recurse ../docker-compose vita-strategies-server:/tmp/
gcloud compute ssh vita-strategies-server --command="sudo mv /tmp/docker-compose/* /opt/vita-strategies/ && sudo chown -R ubuntu:ubuntu /opt/vita-strategies"

# Deploy applications
echo -e "${YELLOW}🐳 Deploying applications...${NC}"
gcloud compute ssh vita-strategies-server --command="cd /opt/vita-strategies && sudo docker-compose up -d"

echo -e "${GREEN}🎉 Deployment completed successfully!${NC}"
echo ""
echo -e "${YELLOW}📌 Next Steps:${NC}"
echo "1. Configure your DNS to point to IP: $VM_IP"
echo "2. Set up Cloudflare (run: cd gcp-infrastructure/cloudflare/terraform && terraform apply)"
echo "3. Access your services:"
echo "   - ERPNext: http://erp.$DOMAIN_NAME"
echo "   - Windmill: http://workflows.$DOMAIN_NAME"
echo "   - Keycloak: http://auth.$DOMAIN_NAME"
echo "   - Metabase: http://analytics.$DOMAIN_NAME"
echo "   - Appsmith: http://apps.$DOMAIN_NAME"
echo "   - Mattermost: http://chat.$DOMAIN_NAME"
echo "   - Grafana: http://monitoring.$DOMAIN_NAME"
echo ""
echo -e "${YELLOW}🔧 Management Commands:${NC}"
echo "View logs: gcloud compute ssh vita-strategies-server --command='cd /opt/vita-strategies && sudo docker-compose logs -f'"
echo "Restart services: gcloud compute ssh vita-strategies-server --command='cd /opt/vita-strategies && sudo docker-compose restart'"
echo "Update services: gcloud compute ssh vita-strategies-server --command='cd /opt/vita-strategies && sudo docker-compose pull && sudo docker-compose up -d'"
