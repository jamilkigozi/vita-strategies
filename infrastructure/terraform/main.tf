terraform {
  required_version = ">= 1.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
  backend "local" {
    path = "terraform.tfstate"
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}

# Data sources for fetching secrets from Google Secret Manager
data "google_secret_manager_secret_version" "admin_ip" {
  secret = "admin-ip"
}

data "google_secret_manager_secret_version" "ssh_public_key" {
  secret = "ssh-public-key"
}

data "google_secret_manager_secret_version" "cloudflare_api_token" {
  secret = "cloudflare-api-token"
}

data "google_secret_manager_secret_version" "db_passwords" {
  for_each = toset([
    "mattermost",
    "windmill",
    "metabase",
    "grafana",
    "openbao",
    "keycloak",
    "wordpress",
    "bookstack",
    "erpnext"
  ])
  secret = "${each.value}-db-password"
}

data "google_secret_manager_secret_version" "keycloak_admin_user" {
  secret = "keycloak-admin-user"
}

data "google_secret_manager_secret_version" "keycloak_admin_password" {
  secret = "keycloak-admin-password"
}

data "google_secret_manager_secret_version" "user_ip" {
  secret = "user-ip"
}

locals {
  common_labels = {
    project     = var.project_name
    environment = var.environment
  }
}

# VPC Network
resource "google_compute_network" "vpc" {
  name                    = "${var.project_name}-vpc"
  auto_create_subnetworks = false
  routing_mode            = "REGIONAL"
}

# Subnet
resource "google_compute_subnetwork" "main" {
  name          = "${var.project_name}-subnet"
  ip_cidr_range = "10.0.0.0/24"
  region        = var.region
  network       = google_compute_network.vpc.id
}

# Firewall Rules
resource "google_compute_firewall" "allow_ssh" {
  name    = "${var.project_name}-allow-ssh"
  network = google_compute_network.vpc.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = [data.google_secret_manager_secret_version.admin_ip.secret_data]
  target_tags   = ["web-server"]
}

resource "google_compute_firewall" "allow_http_https" {
  name    = "${var.project_name}-allow-http-https"
  network = google_compute_network.vpc.name

  allow {
    protocol = "tcp"
    ports    = ["80", "443"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["web-server"]
}

# Static IP Address
resource "google_compute_address" "main" {
  name = "${var.project_name}-static-ip"
}

# Service Account
resource "google_service_account" "vm_service_account" {
  account_id   = "${var.project_name}-vm-sa"
  display_name = "Vita Strategies VM Service Account"
}

# Compute Instance
resource "google_compute_instance" "main" {
  name         = "${var.project_name}-vm-${var.environment}"
  machine_type = var.machine_type
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = var.boot_image
      size  = var.disk_size
      type  = "pd-standard"
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.main.id
    access_config {
      nat_ip = google_compute_address.main.address
    }
  }

  tags = ["web-server", "app-server", "ssh-access"]

  metadata = {
    ssh-keys = "appuser:${data.google_secret_manager_secret_version.ssh_public_key.secret_data}"
  }

  service_account {
    email = google_service_account.vm_service_account.email
    scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
  }

  metadata_startup_script = <<-EOF
    #!/bin/bash
    set -e

    # Log function
    log() {
      echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1" | tee -a /var/log/vita-startup.log
    }

    log "Starting Vita Strategies startup script"

    # Check if this is the first run
    FIRST_RUN=false
    if [ ! -f "/opt/vita-strategies/.initialized" ]; then
      FIRST_RUN=true
      log "First run detected - performing initial setup"
    else
      log "Existing installation detected - preserving data"
    fi

    # Update system
    log "Updating system packages"
    apt-get update
    apt-get upgrade -y

    # Install required packages
    if [ "$FIRST_RUN" = true ]; then
      log "Installing required packages"
      apt-get install -y \
          apt-transport-https \
          ca-certificates \
          curl \
          gnupg \
          lsb-release \
          software-properties-common
    fi

    # Install Docker CE if not already installed
    if ! command -v docker &> /dev/null; then
      log "Installing Docker CE"
      curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
      echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
      apt-get update
      apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
    else
      log "Docker already installed"
    fi

    # Install gcsfuse if not already installed
    if ! command -v gcsfuse &> /dev/null; then
      log "Installing gcsfuse"
      export GCSFUSE_REPO=gcsfuse-$(lsb_release -c -s)
      echo "deb https://packages.cloud.google.com/apt $GCSFUSE_REPO main" | tee /etc/apt/sources.list.d/gcsfuse.list
      curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
      apt-get update
      apt-get install -y gcsfuse
    else
      log "gcsfuse already installed"
    fi

    # Create dedicated app user if it doesn't exist
    if ! id -u appuser &>/dev/null; then
      log "Creating dedicated app user"
      useradd -m -s /bin/bash appuser
      usermod -aG docker appuser
    fi

    # Create bucket mount points if they don't exist
    log "Setting up bucket mount points"
    mkdir -p /mnt/buckets/erpnext
    mkdir -p /mnt/buckets/analytics
    mkdir -p /mnt/buckets/wordpress
    mkdir -p /mnt/buckets/assets
    mkdir -p /mnt/buckets/team-files
    mkdir -p /mnt/buckets/backups

    # Set ownership
    chown -R appuser:appuser /mnt/buckets

    # Create Docker bridge network if it doesn't exist
    docker network inspect vita-network >/dev/null 2>&1 || docker network create vita-network

    # Check if buckets are already mounted
    if ! mountpoint -q /mnt/buckets/erpnext; then
      log "Mounting GCS buckets"
      # Mount GCS buckets using gcsfuse
      gcsfuse --implicit-dirs vita-strategies-erpnext-production /mnt/buckets/erpnext
      gcsfuse --implicit-dirs vita-strategies-analytics-production /mnt/buckets/analytics
      gcsfuse --implicit-dirs vita-strategies-wordpress-production /mnt/buckets/wordpress
      gcsfuse --implicit-dirs vita-strategies-assets-production /mnt/buckets/assets
      gcsfuse --implicit-dirs vita-strategies-team-files-production /mnt/buckets/team-files
      gcsfuse --implicit-dirs vita-strategies-data-backup-production /mnt/buckets/backups
    else
      log "GCS buckets already mounted"
    fi

    # Enable and start Docker
    systemctl enable docker
    systemctl start docker

    # Mark as initialized
    touch /opt/vita-strategies/.initialized

    log "VM initialization completed successfully"
  EOF

  labels = local.common_labels

  lifecycle {
    ignore_changes = [
      metadata_startup_script,
    ]
  }
}

# Storage Buckets
resource "google_storage_bucket" "microservices_buckets" {
  for_each = toset([
    "vita-strategies-wordpress-production",
    "vita-strategies-mattermost-production",
    "vita-strategies-workflows-production",
    "vita-strategies-appsmith-production",
    "vita-strategies-monitoring-production",
    "vita-strategies-vault-production",
    "vita-strategies-auth-production",
    "vita-strategies-docs-production",
    "vita-strategies-erpnext-production",
    "vita-strategies-analytics-production",
    "vita-strategies-team-files-production",
    "vita-strategies-assets-production",
    "vita-strategies-data-backup-production"
  ])

  name     = each.value
  location = var.region

  uniform_bucket_level_access = true

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

  labels = local.common_labels
}

# Cloud SQL Instances
resource "google_sql_database_instance" "postgresql_primary" {
  name                = "${var.project_name}-postgresql-primary"
  database_version    = "POSTGRES_15"
  region              = var.region
  deletion_protection = true

  settings {
    tier = "db-g1-small"

    backup_configuration {
      enabled                        = true
      start_time                     = "03:00"
      location                       = var.region
      point_in_time_recovery_enabled = true
      backup_retention_settings {
        retained_backups = 7
      }
    }

    ip_configuration {
      ipv4_enabled    = false
      private_network = google_compute_network.vpc.id
    }

    database_flags {
      name  = "max_connections"
      value = "200"
    }
  }
}

resource "google_sql_database_instance" "mysql_primary" {
  name                = "${var.project_name}-mysql-primary"
  database_version    = "MYSQL_8_0"
  region              = var.region
  deletion_protection = true

  settings {
    tier = "db-g1-small"

    backup_configuration {
      enabled                        = true
      start_time                     = "04:00"
      location                       = var.region
      binary_log_enabled            = true
      backup_retention_settings {
        retained_backups = 7
      }
    }

    ip_configuration {
      ipv4_enabled    = false
      private_network = google_compute_network.vpc.id
    }
  }
}

resource "google_sql_database_instance" "mariadb_erp" {
  name                = "${var.project_name}-mariadb-erp"
  database_version    = "MYSQL_8_0"
  region              = var.region
  deletion_protection = true

  settings {
    tier = "db-g1-small"

    backup_configuration {
      enabled                        = true
      start_time                     = "05:00"
      location                       = var.region
      binary_log_enabled            = true
      backup_retention_settings {
        retained_backups = 7
      }
    }

    ip_configuration {
      ipv4_enabled    = false
      private_network = google_compute_network.vpc.id
    }
  }
}

# Databases
resource "google_sql_database" "postgresql_databases" {
  for_each = toset([
    "mattermost",
    "windmill",
    "metabase",
    "grafana",
    "openbao",
    "keycloak"
  ])

  name     = each.value
  instance = google_sql_database_instance.postgresql_primary.name
}

resource "google_sql_database" "mysql_databases" {
  for_each = toset([
    "wordpress",
    "bookstack"
  ])

  name     = each.value
  instance = google_sql_database_instance.mysql_primary.name
}

resource "google_sql_database" "erpnext_database" {
  name     = "erpnext"
  instance = google_sql_database_instance.mariadb_erp.name
}

# Database Users
resource "google_sql_user" "postgresql_users" {
  for_each = toset([
    "mattermost",
    "windmill",
    "metabase",
    "grafana",
    "openbao",
    "keycloak"
  ])

  name     = each.value
  instance = google_sql_database_instance.postgresql_primary.name
  password = var.database_passwords[each.value]
}

resource "google_sql_user" "mysql_users" {
  for_each = toset([
    "wordpress",
    "bookstack"
  ])

  name     = each.value
  instance = google_sql_database_instance.mysql_primary.name
  password = var.database_passwords[each.value]
}

resource "google_sql_user" "erpnext_user" {
  name     = "erpnext"
  instance = google_sql_database_instance.mariadb_erp.name
  password = data.google_secret_manager_secret_version.db_passwords["erpnext"].secret_data
}

# Secret Manager Secrets


# Outputs
output "vm_external_ip" {
  description = "External IP address of the main VM"
  value       = google_compute_address.main.address
}

output "vm_internal_ip" {
  description = "Internal IP address of the main VM"
  value       = google_compute_instance.main.network_interface[0].network_ip
}

output "vm_name" {
  description = "Name of the main VM instance"
  value       = google_compute_instance.main.name
}

output "vm_zone" {
  description = "Zone of the main VM instance"
  value       = google_compute_instance.main.zone
}

output "vpc_network_name" {
  description = "Name of the VPC network"
  value       = google_compute_network.vpc.name
}

output "subnet_name" {
  description = "Name of the compute subnet"
  value       = google_compute_subnetwork.main.name
}

output "subnet_cidr" {
  description = "CIDR block of the compute subnet"
  value       = google_compute_subnetwork.main.ip_cidr_range
}

output "storage_buckets" {
  description = "All storage buckets for microservices"
  value = {
    for bucket in google_storage_bucket.microservices_buckets :
    bucket.name => bucket.url
  }
}

output "database_connection_info" {
  description = "Database connection information"
  value = {
    postgresql = {
      instance_name   = google_sql_database_instance.postgresql_primary.name
      connection_name = google_sql_database_instance.postgresql_primary.connection_name
      private_ip      = google_sql_database_instance.postgresql_primary.settings[0].ip_configuration[0].private_network
      databases       = ["mattermost", "windmill", "metabase", "grafana", "openbao", "keycloak"]
    }
    mysql = {
      instance_name   = google_sql_database_instance.mysql_primary.name
      connection_name = google_sql_database_instance.mysql_primary.connection_name
      private_ip      = google_sql_database_instance.mysql_primary.settings[0].ip_configuration[0].private_network
      databases       = ["wordpress", "bookstack"]
    }
    mariadb = {
      instance_name   = google_sql_database_instance.mariadb_erp.name
      connection_name = google_sql_database_instance.mariadb_erp.connection_name
      private_ip      = google_sql_database_instance.mariadb_erp.settings[0].ip_configuration[0].private_network
      databases       = ["erpnext"]
    }
  }
  sensitive = true
}

output "ssh_command" {
  description = "SSH command to connect to the VM"
  value       = "ssh appuser@${google_compute_address.main.address}"
}

output "service_urls" {
  description = "URLs for all microservices"
  value = {
    wordpress  = "https://vitastrategies.com"
    erpnext    = "https://erp.vitastrategies.com"
    metabase   = "https://analytics.vitastrategies.com"
    grafana    = "https://monitoring.vitastrategies.com"
    appsmith   = "https://apps.vitastrategies.com"
    keycloak   = "https://auth.vitastrategies.com"
    mattermost = "https://chat.vitastrategies.com"
    windmill   = "https://workflows.vitastrategies.com"
    bookstack  = "https://docs.vitastrategies.com"
    openbao    = "https://vault.vitastrategies.com"
  }
}