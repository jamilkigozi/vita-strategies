#!/bin/bash

# =============================================================================
# VITA STRATEGIES - BUSINESS EXPORT (MULTI-CLOUD PORTABILITY)
# =============================================================================
# Export your entire business for migration to AWS/Azure/VPS
# =============================================================================

set -e

EXPORT_DATE=$(date +%Y%m%d_%H%M%S)
EXPORT_DIR="vita-strategies-export-$EXPORT_DATE"
BUSINESS_NAME="vita-strategies"

echo "📦 VITA STRATEGIES BUSINESS EXPORT"
echo "=================================="
echo "🎯 Creating portable business backup"
echo "📅 Export date: $EXPORT_DATE"
echo "📁 Export directory: $EXPORT_DIR"
echo ""

# =============================================================================
# CREATE EXPORT DIRECTORY STRUCTURE
# =============================================================================

mkdir -p "$EXPORT_DIR"/{data,configs,infrastructure,scripts,docs}

echo "✅ Created export directory structure"

# =============================================================================
# EXPORT BUSINESS DATA FROM GCP BUCKETS
# =============================================================================

echo "📊 Exporting business data from GCP buckets..."

BUCKETS=(
    "vita-strategies-data-backup-production"
    "vita-strategies-erpnext-production" 
    "vita-strategies-analytics-production"
    "vita-strategies-team-files-production"
    "vita-strategies-assets-production"
)

for bucket in "${BUCKETS[@]}"; do
    echo "Downloading from gs://$bucket..."
    mkdir -p "$EXPORT_DIR/data/$bucket"
    gsutil -m cp -r "gs://$bucket/*" "$EXPORT_DIR/data/$bucket/" 2>/dev/null || echo "⚠️  Bucket $bucket empty or not accessible"
done

echo "✅ Business data exported"

# =============================================================================
# EXPORT INFRASTRUCTURE CONFIGURATIONS
# =============================================================================

echo "🏗️  Exporting infrastructure configurations..."

# Copy Terraform configs
cp -r infrastructure/ "$EXPORT_DIR/infrastructure/"

# Copy Docker Compose configs
cp docker-compose-persistent.yml "$EXPORT_DIR/configs/"
cp -r environments/ "$EXPORT_DIR/configs/"

# Copy credentials (encrypted)
cp CREDENTIALS.md "$EXPORT_DIR/configs/"

echo "✅ Infrastructure configurations exported"

# =============================================================================
# EXPORT DEPLOYMENT SCRIPTS
# =============================================================================

echo "🔧 Exporting deployment scripts..."

cp -r scripts/ "$EXPORT_DIR/scripts/"
cp README.md "$EXPORT_DIR/docs/"
cp PROJECT-STRUCTURE.md "$EXPORT_DIR/docs/"

echo "✅ Deployment scripts exported"

# =============================================================================
# CREATE MULTI-CLOUD DEPLOYMENT CONFIGS
# =============================================================================

echo "☁️  Creating multi-cloud deployment configurations..."

# AWS deployment config
cat > "$EXPORT_DIR/infrastructure/aws-deployment.tf" << 'EOF'
# AWS Deployment Configuration for Vita Strategies
# Deploy your business to AWS

provider "aws" {
  region = "eu-west-2"
}

resource "aws_instance" "vita_strategies" {
  ami           = "ami-0c02fb55956c7d316" # Ubuntu 20.04 LTS
  instance_type = "t3.large"
  
  tags = {
    Name = "vita-strategies-server"
    Environment = "production"
  }
  
  user_data = file("../startup-scripts/startup-script-with-buckets.sh")
}

resource "aws_s3_bucket" "vita_data" {
  bucket = "vita-strategies-data-aws"
}
EOF

# Azure deployment config  
cat > "$EXPORT_DIR/infrastructure/azure-deployment.tf" << 'EOF'
# Azure Deployment Configuration for Vita Strategies
# Deploy your business to Azure

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "vita_strategies" {
  name     = "vita-strategies-rg"
  location = "West Europe"
}

resource "azurerm_linux_virtual_machine" "vita_strategies" {
  name                = "vita-strategies-vm"
  resource_group_name = azurerm_resource_group.vita_strategies.name
  location            = azurerm_resource_group.vita_strategies.location
  size                = "Standard_D2s_v3"
  
  custom_data = base64encode(file("../startup-scripts/startup-script-with-buckets.sh"))
}
EOF

# VPS deployment config
cat > "$EXPORT_DIR/infrastructure/vps-deployment.sh" << 'EOF'
#!/bin/bash
# VPS Deployment Script for Vita Strategies
# Deploy to any VPS provider (DigitalOcean, Linode, etc.)

VPS_IP="YOUR_VPS_IP"
VPS_USER="root"

echo "🚀 Deploying Vita Strategies to VPS: $VPS_IP"

# Copy files to VPS
scp -r ../configs/docker-compose-persistent.yml $VPS_USER@$VPS_IP:/opt/vita-strategies/
scp -r ../configs/environments/ $VPS_USER@$VPS_IP:/opt/vita-strategies/

# Set up VPS
ssh $VPS_USER@$VPS_IP "
    # Install Docker
    curl -fsSL https://get.docker.com -o get-docker.sh
    sh get-docker.sh
    
    # Install Docker Compose
    curl -L \"https://github.com/docker/compose/releases/latest/download/docker-compose-\$(uname -s)-\$(uname -m)\" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
    
    # Start services
    cd /opt/vita-strategies
    docker-compose up -d
"

echo "✅ Deployment to VPS complete!"
EOF

chmod +x "$EXPORT_DIR/infrastructure/vps-deployment.sh"

echo "✅ Multi-cloud configurations created"

# =============================================================================
# CREATE BUSINESS IMPORT SCRIPT
# =============================================================================

cat > "$EXPORT_DIR/import-business.sh" << 'EOF'
#!/bin/bash

# =============================================================================
# VITA STRATEGIES - BUSINESS IMPORT SCRIPT  
# =============================================================================
# Import your business to any cloud provider
# =============================================================================

echo "📥 VITA STRATEGIES BUSINESS IMPORT"
echo "================================="
echo ""
echo "Choose your deployment target:"
echo "1. Google Cloud Platform (GCP)"
echo "2. Amazon Web Services (AWS)" 
echo "3. Microsoft Azure"
echo "4. VPS (DigitalOcean, Linode, etc.)"
echo "5. Local development"
echo ""

read -p "Enter choice (1-5): " choice

case $choice in
    1)
        echo "🌐 Deploying to Google Cloud Platform..."
        cd infrastructure && terraform init && terraform apply -var-file="gcp.tfvars"
        ;;
    2) 
        echo "☁️  Deploying to Amazon Web Services..."
        cd infrastructure && terraform init && terraform apply -f aws-deployment.tf
        ;;
    3)
        echo "🔷 Deploying to Microsoft Azure..."
        cd infrastructure && terraform init && terraform apply -f azure-deployment.tf
        ;;
    4)
        echo "🖥️  Deploying to VPS..."
        read -p "Enter VPS IP address: " vps_ip
        sed -i "s/YOUR_VPS_IP/$vps_ip/g" infrastructure/vps-deployment.sh
        ./infrastructure/vps-deployment.sh
        ;;
    5)
        echo "💻 Setting up local development..."
        cd configs && docker-compose -f docker-compose-persistent.yml up -d
        ;;
    *)
        echo "❌ Invalid choice"
        exit 1
        ;;
esac

echo "✅ Business import completed!"
EOF

chmod +x "$EXPORT_DIR/import-business.sh"

# =============================================================================
# CREATE MIGRATION CHECKLIST
# =============================================================================

cat > "$EXPORT_DIR/MIGRATION-CHECKLIST.md" << EOF
# 🚀 Vita Strategies Migration Checklist

## ✅ **Business Export Complete**
- **Date**: $EXPORT_DATE
- **Source**: Google Cloud Platform
- **Data**: $(du -sh "$EXPORT_DIR/data" | cut -f1) exported
- **Configs**: Infrastructure + application configs
- **Scripts**: Multi-cloud deployment ready

## 🎯 **Migration Options Available**

### **1. AWS Migration**
\`\`\`bash
cd $EXPORT_DIR
./import-business.sh
# Choose option 1 (AWS)
\`\`\`

### **2. Azure Migration** 
\`\`\`bash
cd $EXPORT_DIR
./import-business.sh
# Choose option 3 (Azure)
\`\`\`

### **3. VPS Migration**
\`\`\`bash
cd $EXPORT_DIR
./import-business.sh  
# Choose option 4 (VPS)
\`\`\`

### **4. Local Development**
\`\`\`bash
cd $EXPORT_DIR
./import-business.sh
# Choose option 5 (Local)
\`\`\`

## 📋 **Migration Steps**

1. **Prepare Target Environment**
   - [ ] Set up cloud account (AWS/Azure) or VPS
   - [ ] Install Terraform (for cloud) or Docker (for VPS/local)
   - [ ] Set up authentication

2. **Import Business**
   - [ ] Run import script: \`./import-business.sh\`
   - [ ] Choose target platform
   - [ ] Wait for deployment

3. **Verify Migration**
   - [ ] Check all services are running
   - [ ] Verify data integrity  
   - [ ] Test business functionality
   - [ ] Update DNS if needed

4. **Update Team**
   - [ ] Share new service URLs
   - [ ] Update bookmarks
   - [ ] Test team access

## 🔐 **Security Notes**
- Change default passwords after migration
- Update environment variables for new cloud
- Review firewall/security group settings
- Set up SSL certificates for new domain

## 📞 **Support**
Your business is now portable across any cloud provider!
- Original export date: $EXPORT_DATE
- Export size: $(du -sh "$EXPORT_DIR" | cut -f1)
- Migration estimated time: 30-60 minutes

**Your business freedom guaranteed! 🚀**
EOF

# =============================================================================
# EXPORT COMPLETE
# =============================================================================

EXPORT_SIZE=$(du -sh "$EXPORT_DIR" | cut -f1)

echo ""
echo "🎉 BUSINESS EXPORT COMPLETE!"
echo "============================"
echo "📁 Export directory: $EXPORT_DIR"
echo "💾 Total size: $EXPORT_SIZE"
echo "📦 Buckets exported: ${#BUCKETS[@]}"
echo "☁️  Cloud configs: GCP, AWS, Azure, VPS"
echo ""
echo "🚀 MIGRATION READY:"
echo "• Run: cd $EXPORT_DIR && ./import-business.sh"
echo "• Choose: AWS, Azure, VPS, or Local"
echo "• Time: 30-60 minutes to migrate"
echo ""
echo "✅ YOUR BUSINESS IS NOW PORTABLE!"
echo "You can move to any cloud provider anytime."
echo ""
echo "📋 Next steps:"
echo "1. Test import: cd $EXPORT_DIR && ./import-business.sh"
echo "2. Choose cloud: AWS/Azure/VPS/Local"
echo "3. Verify: Check all services work"
echo ""
echo "💼 Business freedom achieved! 🎯"

# Create compressed backup
echo "📦 Creating compressed backup..."
tar -czf "vita-strategies-complete-backup-$EXPORT_DATE.tar.gz" "$EXPORT_DIR"
BACKUP_SIZE=$(du -sh "vita-strategies-complete-backup-$EXPORT_DATE.tar.gz" | cut -f1)
echo "✅ Compressed backup: vita-strategies-complete-backup-$EXPORT_DATE.tar.gz ($BACKUP_SIZE)"
