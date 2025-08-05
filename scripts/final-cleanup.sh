#!/bin/bash
set -e

# VITA STRATEGIES - FINAL CLEANUP SCRIPT
# Removes redundant files, updates configurations, and ensures GCP compatibility

echo "🔍 Starting final cleanup for GCP deployment..."

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

warning() {
    echo -e "${YELLOW}[WARNING] $1${NC}"
}

error() {
    echo -e "${RED}[ERROR] $1${NC}"
}

# Clean up old/deprecated files
log "🧹 Cleaning up deprecated files..."

# Remove old backup files (older than 30 days)
find . -name "*.bak" -mtime +30 -delete 2>/dev/null || true
find . -name "*.backup" -mtime +30 -delete 2>/dev/null || true
find . -name "*.old" -mtime +30 -delete 2>/dev/null || true
find . -name "*.tmp" -mtime +7 -delete 2>/dev/null || true

# Remove IDE files
find . -name ".idea" -type d -exec rm -rf {} + 2>/dev/null || true
find . -name "*.iml" -delete 2>/dev/null || true
find . -name ".vscode" -type d -exec rm -rf {} + 2>/dev/null || true

# Clean up log files
find . -name "*.log" -mtime +7 -delete 2>/dev/null || true

# Update GCP-specific configurations
log "🔄 Updating GCP configurations..."

# Update Terraform variables for GCP
cat > infrastructure/terraform/terraform.tfvars << 'EOF'
# GCP Configuration
project_id = "vita-strategies-2024"
region = "us-central1"
zone = "us-central1-a"

# Instance Configuration
instance_type = "e2-standard-4"
disk_size = 100
disk_type = "pd-ssd"

# Network Configuration
vpc_name = "vita-vpc"
subnet_name = "vita-subnet"
firewall_name = "vita-firewall"

# Database Configuration
db_instance_type = "db-f1-micro"
db_disk_size = 100
db_version = "POSTGRES_15"

# Storage Configuration
bucket_name = "vita-strategies-storage"
backup_bucket_name = "vita-strategies-backup"

# SSL Configuration
ssl_cert_name = "vita-ssl-cert"
domain_name = "vita-strategies.com"
EOF

# Update main Terraform configuration for GCP
cat > infrastructure/terraform/main.tf << 'EOF'
terraform {
  required_version = ">= 1.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 4.0"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "~> 4.0"
    }
  }
  backend "gcs" {
    bucket = "vita-terraform-state"
    prefix = "vita-strategies"
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}

# Enable required APIs
resource "google_project_service" "compute_api" {
  service = "compute.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "sql_api" {
  service = "sqladmin.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "storage_api" {
  service = "storage.googleapis.com"
  disable_on_destroy = false
}

# VPC Network
resource "google_compute_network" "vpc" {
  name                    = var.vpc_name
  auto_create_subnetworks = false
  routing_mode            = "REGIONAL"
}

# Subnet
resource "google_compute_subnetwork" "subnet" {
  name          = var.subnet_name
  ip_cidr_range = "10.0.0.0/24"
  region        = var.region
  network       = google_compute_network.vpc.id
}

# Firewall Rules
resource "google_compute_firewall" "allow_http" {
  name    = "${var.firewall_name}-http"
  network = google_compute_network.vpc.name

  allow {
    protocol = "tcp"
    ports    = ["80", "443"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["web-server"]
}

# Compute Instance
resource "google_compute_instance" "web_server" {
  name         = "vita-web-server"
  machine_type = var.instance_type
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = "ubuntu-2004-focal-v20220810"
      size  = var.disk_size
      type  = var.disk_type
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.subnet.id
    access_config {
      // Ephemeral IP
    }
  }

  tags = ["web-server", "http-server", "https-server"]

  metadata_startup_script = file("${path.module}/startup-script.sh")

  service_account {
    email  = google_service_account.vita_sa.email
    scopes = ["cloud-platform"]
  }
}

# Cloud SQL Instance
resource "google_sql_database_instance" "postgres" {
  name             = "vita-postgres-instance"
  database_version = var.db_version
  region           = var.region
  settings {
    tier              = var.db_instance_type
    disk_size         = var.db_disk_size
    disk_type         = "PD_SSD"
    availability_type = "ZONAL"

    backup_configuration {
      enabled                        = true
      start_time                     = "02:00"
      point_in_time_recovery_enabled = true
      transaction_log_retention_days = 7
    }

    ip_configuration {
      ipv4_enabled    = true
      private_network = google_compute_network.vpc.id
    }
  }
}

# Storage Bucket
resource "google_storage_bucket" "storage" {
  name          = var.bucket_name
  location      = var.region
  force_destroy = false

  versioning {
    enabled = true
  }

  lifecycle_rule {
    condition {
      age = 30
    }
    action {
      type = "Delete"
    }
  }
}

# Service Account
resource "google_service_account" "vita_sa" {
  account_id   = "vita-service-account"
  display_name = "Vita Strategies Service Account"
}

# IAM Bindings
resource "google_project_iam_member" "storage_admin" {
  project = var.project_id
  role    = "roles/storage.admin"
  member  = "serviceAccount:${google_service_account.vita_sa.email}"
}

# SSL Certificate
resource "google_compute_managed_ssl_certificate" "ssl_cert" {
  name = var.ssl_cert_name

  managed {
    domains = [var.domain_name]
  }
}

# DNS Zone
resource "google_dns_managed_zone" "dns_zone" {
  name     = "vita-dns-zone"
  dns_name = "${var.domain_name}."
}

# DNS Records
resource "google_dns_record_set" "a_record" {
  name         = google_dns_managed_zone.dns_zone.dns_name
  managed_zone = google_dns_managed_zone.dns_zone.name
  type         = "A"
  ttl          = 300
  rrdatas      = [google_compute_instance.web_server.network_interface[0].access_config[0].nat_ip]
}
EOF

# Create updated startup script for GCP
cat > infrastructure/terraform/startup-script.sh << 'EOF'
#!/bin/bash
set -e

# Vita Strategies - GCP Startup Script
# This script runs on VM startup to configure the environment

# Update system
apt-get update && apt-get upgrade -y

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh
usermod -aG docker ubuntu

# Install Docker Compose
curl -L "https://github.com/docker/compose/releases/download/v2.20.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Install Google Cloud SDK
curl -sSL https://sdk.cloud.google.com | bash
exec -l $SHELL

# Install monitoring agent
curl -sSO https://dl.google.com/cloudagents/add-google-cloud-ops-agent-repo.sh
bash add-google-cloud-ops-agent-repo.sh --also-install

# Create directories
mkdir -p /opt/vita-strategies
mkdir -p /var/log/vita-strategies

# Set up environment
cat > /opt/vita-strategies/.env << 'ENV'
# GCP Configuration
PROJECT_ID=vita-strategies-2024
REGION=us-central1
ZONE=us-central1-a

# Database Configuration
DB_HOST=localhost
DB_PORT=5432
DB_NAME=vita_strategies
DB_USER=vita_user
DB_PASSWORD=secure_password

# Redis Configuration
REDIS_HOST=localhost
REDIS_PORT=6379

# SSL Configuration
SSL_CERT_PATH=/etc/ssl/certs/vita-strategies.crt
SSL_KEY_PATH=/etc/ssl/private/vita-strategies.key
ENV

# Install application
cd /opt/vita-strategies
git clone https://github.com/vita-strategies/vita-platform.git .
chmod +x scripts/*.sh

# Start services
./scripts/deploy-complete.sh

# Set up log rotation
cat > /etc/logrotate.d/vita-strategies << 'LOGROTATE'
/var/log/vita-strategies/*.log {
    daily
    rotate 30
    compress
    delaycompress
    missingok
    notifempty
    create 0644 ubuntu ubuntu
    postrotate
        systemctl reload nginx
    endscript
}
LOGROTATE

# Set up monitoring
systemctl enable google-cloud-ops-agent
systemctl start google-cloud-ops-agent

log "GCP startup script completed successfully"
EOF

# Make scripts executable
chmod +x infrastructure/terraform/startup-script.sh

# Clean up old configuration files
log "🧹 Removing deprecated configuration files..."

# Remove old Docker Compose files
rm -f docker-compose.yml.backup 2>/dev/null || true
rm -f docker-compose.yml.old 2>/dev/null || true

# Remove old Terraform state files
rm -f terraform.tfstate.backup 2>/dev/null || true
rm -f terraform.tfstate.old 2>/dev/null || true

# Remove old environment files
rm -f .env.backup 2>/dev/null || true
rm -f .env.old 2>/dev/null || true

# Update .gitignore for GCP
cat > .gitignore << 'EOF'
# Terraform
*.tfstate
*.tfstate.*
.terraform/
terraform.tfvars

# IDE
.idea/
.vscode/
*.swp
*.swo

# OS
.DS_Store
Thumbs.db

# Logs
*.log
logs/

# Environment
.env
.env.local

# Backup files
*.bak
*.backup
*.old
*.tmp

# Node modules
node_modules/

# Python
__pycache__/
*.pyc
*.pyo

# Docker
.dockerignore

# Secrets
secrets/
*.pem
*.key
*.crt

# GCP
.gcp/
gcp-credentials.json
EOF

log "✅ Final cleanup completed successfully!"
log "✅ All GCP Terraform configurations are updated"
log "✅ All deprecated files have been removed"
log "✅ All backup and monitoring configurations are in place"
