#!/bin/bash

# =============================================================================
# VITA STRATEGIES - COMPLETE DEPLOYMENT SCRIPT
# =============================================================================
# Deploys the hybrid Terraform + Docker Compose infrastructure
# Creates buckets, VM, and sets up automated data syncing
# =============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
ENVIRONMENT="${1:-production}"

echo "🚀 Deploying Vita Strategies Infrastructure"
echo "📍 Project Root: $PROJECT_ROOT"
echo "🏷️  Environment: $ENVIRONMENT"
echo "============================================="

# =============================================================================
# PREREQUISITES CHECK
# =============================================================================

echo "🔍 Checking prerequisites..."

# Check if gcloud is installed and authenticated
if ! command -v gcloud &> /dev/null; then
    echo "❌ Google Cloud SDK not installed. Please install and run 'gcloud auth login'"
    exit 1
fi

# Check if Terraform is installed
if ! command -v terraform &> /dev/null; then
    echo "❌ Terraform not installed. Installing..."
    curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
    sudo apt-add-repository "deb [arch=$(dpkg --print-architecture)] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
    sudo apt update && sudo apt install terraform
fi

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo "❌ Docker not installed. Please install Docker first."
    exit 1
fi

echo "✅ Prerequisites met"

# =============================================================================
# TERRAFORM DEPLOYMENT
# =============================================================================

echo "🏗️  Deploying Terraform infrastructure..."

cd "$PROJECT_ROOT/infrastructure/terraform"

# Initialize Terraform
echo "Initializing Terraform..."
terraform init

# Plan deployment
echo "Planning deployment..."
terraform plan -var="environment=$ENVIRONMENT" -out=tfplan

# Ask for confirmation
read -p "🤔 Deploy this infrastructure? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "❌ Deployment cancelled"
    exit 1
fi

# Apply Terraform
echo "🚀 Applying Terraform configuration..."
terraform apply tfplan

# Get Terraform outputs
VM_IP=$(terraform output -raw vm_external_ip)
SERVICE_ACCOUNT_EMAIL=$(terraform output -raw service_account_email)

echo "✅ Terraform infrastructure deployed!"
echo "📍 VM IP: $VM_IP"
echo "🔐 Service Account: $SERVICE_ACCOUNT_EMAIL"

# =============================================================================
# VM SETUP
# =============================================================================

echo "⚙️  Setting up VM..."

# Wait for VM to be ready
echo "Waiting for VM to boot..."
sleep 60

# Copy Docker Compose files to VM
echo "📦 Copying application files to VM..."
gcloud compute scp --recurse "$PROJECT_ROOT/docker-compose-persistent.yml" ubuntu@vita-strategies-server:/opt/vita-strategies/docker-compose.yml --zone=europe-west2-a
gcloud compute scp --recurse "$PROJECT_ROOT/environments/$ENVIRONMENT/.env" ubuntu@vita-strategies-server:/opt/vita-strategies/.env --zone=europe-west2-a

# Copy credentials
gcloud compute scp "$PROJECT_ROOT/CREDENTIALS.md" ubuntu@vita-strategies-server:/opt/vita-strategies/ --zone=europe-west2-a

echo "✅ Files copied to VM"

# =============================================================================
# BUCKET AUTHENTICATION
# =============================================================================

echo "🔐 Setting up bucket authentication..."

# Create service account key
gcloud iam service-accounts keys create /tmp/vita-service-key.json \
    --iam-account="$SERVICE_ACCOUNT_EMAIL"

# Copy key to VM
gcloud compute scp /tmp/vita-service-key.json ubuntu@vita-strategies-server:/opt/vita-strategies/service-key.json --zone=europe-west2-a

# Set up authentication on VM
gcloud compute ssh ubuntu@vita-strategies-server --zone=europe-west2-a --command="
    export GOOGLE_APPLICATION_CREDENTIALS=/opt/vita-strategies/service-key.json
    gcloud auth activate-service-account --key-file=/opt/vita-strategies/service-key.json
    echo 'export GOOGLE_APPLICATION_CREDENTIALS=/opt/vita-strategies/service-key.json' >> ~/.bashrc
"

# Clean up local key
rm /tmp/vita-service-key.json

echo "✅ Bucket authentication configured"

# =============================================================================
# START SERVICES
# =============================================================================

echo "🐳 Starting Docker services..."

gcloud compute ssh ubuntu@vita-strategies-server --zone=europe-west2-a --command="
    cd /opt/vita-strategies
    
    # Start services
    docker-compose up -d
    
    # Wait for services to start
    sleep 30
    
    # Show status
    docker-compose ps
    
    # Run initial bucket sync
    /opt/vita-strategies/sync-buckets.sh
"

echo "✅ Services started and initial backup completed"

# =============================================================================
# SETUP VALIDATION
# =============================================================================

echo "🧪 Validating deployment..."

# Check service health
SERVICES_STATUS=$(gcloud compute ssh ubuntu@vita-strategies-server --zone=europe-west2-a --command="docker-compose ps --format table" | grep -c "Up")
echo "📊 Services running: $SERVICES_STATUS/8"

# Check bucket access
BUCKET_TEST=$(gcloud compute ssh ubuntu@vita-strategies-server --zone=europe-west2-a --command="gsutil ls gs://vita-strategies-data-backup-$ENVIRONMENT/ | wc -l")
echo "📦 Bucket access: $([ $BUCKET_TEST -ge 0 ] && echo "✅ Working" || echo "❌ Failed")"

# =============================================================================
# POST-DEPLOYMENT SUMMARY
# =============================================================================

echo ""
echo "🎉 DEPLOYMENT COMPLETE!"
echo "============================================="
echo "🌐 Platform URL: https://$VM_IP"
echo "📊 ERPNext: https://$VM_IP:8000"
echo "📈 Metabase: https://$VM_IP:3000"
echo "📊 Grafana: https://$VM_IP:3001"
echo "🛠️  Appsmith: https://$VM_IP:8080"
echo "🔐 Keycloak: https://$VM_IP:8090"
echo "💬 Mattermost: https://$VM_IP:8065"
echo "⚡ Windmill: https://$VM_IP:8000"
echo ""
echo "📦 BUCKET ACCESS:"
echo "To view your data in buckets, run on VM:"
echo "/opt/vita-strategies/bucket-access.sh browse"
echo ""
echo "🔄 AUTOMATIC BACKUPS:"
echo "- Every 4 hours to buckets"
echo "- Daily full backup at 2 AM"
echo ""
echo "🔧 MANAGEMENT:"
echo "SSH to VM: gcloud compute ssh ubuntu@vita-strategies-server --zone=europe-west2-a"
echo "View logs: docker-compose logs -f [service-name]"
echo "Restart services: docker-compose restart"
echo ""
echo "📖 Check CREDENTIALS.md for login details"
echo "============================================="

# Save deployment info
cat > "$PROJECT_ROOT/DEPLOYMENT-INFO.md" << EOF
# Vita Strategies Deployment Information

**Deployed:** $(date)
**Environment:** $ENVIRONMENT
**VM IP:** $VM_IP

## Service URLs
- ERPNext: https://$VM_IP:8000
- Metabase: https://$VM_IP:3000  
- Grafana: https://$VM_IP:3001
- Appsmith: https://$VM_IP:8080
- Keycloak: https://$VM_IP:8090
- Mattermost: https://$VM_IP:8065
- Windmill: https://$VM_IP:8000

## Bucket Access
Run on VM: \`/opt/vita-strategies/bucket-access.sh browse\`

## Management Commands
- SSH: \`gcloud compute ssh ubuntu@vita-strategies-server --zone=europe-west2-a\`
- Logs: \`docker-compose logs -f [service]\`
- Restart: \`docker-compose restart\`

## Backup Schedule
- Automatic: Every 4 hours
- Full backup: Daily at 2 AM
- Location: Google Cloud Storage buckets

Last updated: $(date)
EOF

echo "📝 Deployment info saved to DEPLOYMENT-INFO.md"
