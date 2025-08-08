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
  secret = "ADMIN_IP"
}

data "google_secret_manager_secret_version" "ssh_public_key" {
  secret = "SSH_PUBLIC_KEY"
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

# VPC Peering for Cloud SQL
resource "google_compute_global_address" "private_ip_address" {
  name          = "private-ip-address"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = google_compute_network.vpc.id
}

resource "google_service_networking_connection" "private_vpc_connection" {
  network                 = google_compute_network.vpc.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip_address.name]
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

# Firewall for application ports (Cloudflare access)
resource "google_compute_firewall" "app_ports" {
  name    = "${var.project_name}-app-ports"
  network = google_compute_network.vpc.name

  allow {
    protocol = "tcp"
    ports    = ["8001", "8002", "8003", "8004", "8005", "8006", "8007", "8008"]
  }

  source_ranges = ["173.245.48.0/20", "103.21.244.0/22", "103.22.200.0/22", "103.31.4.0/22", "141.101.64.0/18", "108.162.192.0/18", "190.93.240.0/20", "188.114.96.0/20", "197.234.240.0/22", "198.41.128.0/17", "162.158.0.0/15", "104.16.0.0/13", "104.24.0.0/14", "172.64.0.0/13", "131.0.72.0/22"]
  target_tags   = ["web-server"]
}

# Static IP Address
resource "google_compute_address" "main" {
  name = "${var.project_name}-static-ip"
}

# Service Account with least privilege
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

  metadata_startup_script = file("${path.module}/startup-script.sh")

  service_account {
    email = google_service_account.vm_service_account.email
    scopes = [
      "https://www.googleapis.com/auth/devstorage.read_write",
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring.write",
      "https://www.googleapis.com/auth/sqlservice.admin",
      "https://www.googleapis.com/auth/secretmanager.accessor"
    ]
  }

  labels = local.common_labels
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

# Cloud SQL Instances with private networking
resource "google_sql_database_instance" "postgresql_primary" {
  name                = "${var.project_name}-postgresql-primary"
  database_version    = "POSTGRES_15"
  region              = var.region
  deletion_protection = false

  depends_on = [google_service_networking_connection.private_vpc_connection]

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
      ipv4_enabled                                  = false
      private_network                               = google_compute_network.vpc.id
      enable_private_path_for_google_cloud_services = true
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
  deletion_protection = false

  depends_on = [google_service_networking_connection.private_vpc_connection]

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
      ipv4_enabled                                  = false
      private_network                               = google_compute_network.vpc.id
      enable_private_path_for_google_cloud_services = true
    }
  }
}

resource "google_sql_database_instance" "mariadb_erp" {
  name                = "${var.project_name}-mariadb-erp"
  database_version    = "MYSQL_8_0"
  region              = var.region
  deletion_protection = false

  depends_on = [google_service_networking_connection.private_vpc_connection]

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
      ipv4_enabled                                  = false
      private_network                               = google_compute_network.vpc.id
      enable_private_path_for_google_cloud_services = true
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
  password = "temp_password_${each.value}"
}

resource "google_sql_user" "mysql_users" {
  for_each = toset([
    "wordpress",
    "bookstack"
  ])

  name     = each.value
  instance = google_sql_database_instance.mysql_primary.name
  password = "temp_password_${each.value}"
}

resource "google_sql_user" "erpnext_user" {
  name     = "erpnext"
  instance = google_sql_database_instance.mariadb_erp.name
  password = "temp_password_erpnext"
}

# Outputs
output "vm_external_ip" {
  description = "External IP address of the main VM"
  value       = google_compute_address.main.address
}

output "vm_internal_ip" {
  description = "Internal IP address of the main VM"
  value       = google_compute_instance.main.network_interface[0].network_ip
}

output "postgresql_private_ip" {
  description = "PostgreSQL private IP"
  value       = google_sql_database_instance.postgresql_primary.private_ip_address
}

output "mysql_private_ip" {
  description = "MySQL private IP"
  value       = google_sql_database_instance.mysql_primary.private_ip_address
}

output "mariadb_private_ip" {
  description = "MariaDB private IP"
  value       = google_sql_database_instance.mariadb_erp.private_ip_address
}