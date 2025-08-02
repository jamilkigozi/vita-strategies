# =============================================================================
# VITA STRATEGIES - COMPLETE TERRAFORM + STORAGE INFRASTRUCTURE
# =============================================================================

terraform {
  required_version = ">= 1.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}

# Variables
variable "project_id" {
  description = "GCP Project ID"
  type        = string
  default     = "mystical-slate-463221-j0"
}

variable "region" {
  description = "GCP Region"
  type        = string
  default     = "europe-west2"
}

variable "zone" {
  description = "GCP Zone"
  type        = string
  default     = "europe-west2-a"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "production"
}

# =============================================================================
# STORAGE BUCKETS FOR DATA PERSISTENCE & EASY ACCESS
# =============================================================================

# Main data backup bucket - Your "data safe"
resource "google_storage_bucket" "vita_data_backup" {
  name     = "vita-strategies-data-backup-${var.environment}"
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

  lifecycle_rule {
    condition {
      age = 7
    }
    action {
      type          = "SetStorageClass"
      storage_class = "COLDLINE"
    }
  }

  labels = {
    environment = var.environment
    purpose     = "data-backup"
  }
}

# ERPNext business data bucket - Customer/Invoice data
resource "google_storage_bucket" "erpnext_data" {
  name     = "vita-strategies-erpnext-${var.environment}"
  location = var.region

  uniform_bucket_level_access = true

  versioning {
    enabled = true
  }

  # 7 years retention for business compliance
  lifecycle_rule {
    condition {
      age = 2555
    }
    action {
      type = "Delete"
    }
  }

  labels = {
    environment = var.environment
    purpose     = "business-data"
  }
}

# Application assets bucket - Logos, themes, static files
resource "google_storage_bucket" "app_assets" {
  name     = "vita-strategies-assets-${var.environment}"
  location = var.region

  uniform_bucket_level_access = true

  # Public access for serving assets
  cors {
    origin          = ["https://vitastrategies.com", "https://*.vitastrategies.com"]
    method          = ["GET", "HEAD"]
    response_header = ["*"]
    max_age_seconds = 3600
  }

  labels = {
    environment = var.environment
    purpose     = "static-assets"
  }
}

# Analytics and reports bucket - Metabase exports, reports
resource "google_storage_bucket" "analytics_data" {
  name     = "vita-strategies-analytics-${var.environment}"
  location = var.region

  uniform_bucket_level_access = true

  versioning {
    enabled = true
  }

  labels = {
    environment = var.environment
    purpose     = "analytics"
  }
}

# Team files bucket - Mattermost uploads, shared documents
resource "google_storage_bucket" "team_files" {
  name     = "vita-strategies-team-files-${var.environment}"
  location = var.region

  uniform_bucket_level_access = true

  versioning {
    enabled = true
  }

  lifecycle_rule {
    condition {
      age = 365 # 1 year retention for team files
    }
    action {
      type = "Delete"
    }
  }

  labels = {
    environment = var.environment
    purpose     = "team-collaboration"
  }
}

# =============================================================================
# COMPUTE INFRASTRUCTURE
# =============================================================================

# Static IP address
resource "google_compute_address" "vita_static_ip" {
  name   = "vita-strategies-ip"
  region = var.region
}

# Additional data disk for Docker volumes
resource "google_compute_disk" "vita_data_disk" {
  name = "vita-strategies-data"
  type = "pd-ssd"
  zone = var.zone
  size = 200 # GB - dedicated for Docker volumes
}

# Main VM instance
resource "google_compute_instance" "vita_strategies_server" {
  name         = "vita-strategies-server"
  machine_type = "e2-standard-4"
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2204-lts"
      size  = 100 # GB
      type  = "pd-ssd"
    }
  }

  # Additional persistent disk for data
  attached_disk {
    source      = google_compute_disk.vita_data_disk.self_link
    device_name = "vita-data"
  }

  network_interface {
    network = "default"
    access_config {
      nat_ip = google_compute_address.vita_static_ip.address
    }
  }

  # Service account with bucket access
  service_account {
    email = google_service_account.vita_storage_sa.email
    scopes = [
      "https://www.googleapis.com/auth/cloud-platform",
      "https://www.googleapis.com/auth/storage.full_control"
    ]
  }

  metadata_startup_script = file("${path.module}/startup-script.sh")

  tags = ["vita-strategies", "docker", "web-server"]

  labels = {
    environment = var.environment
    purpose     = "application-server"
  }
}

# =============================================================================
# IAM & SERVICE ACCOUNTS
# =============================================================================

# Service account for bucket access
resource "google_service_account" "vita_storage_sa" {
  account_id   = "vita-storage-access"
  display_name = "Vita Strategies Storage Access"
  description  = "Service account for accessing storage buckets"
}

# Storage admin role
resource "google_project_iam_member" "storage_admin" {
  project = var.project_id
  role    = "roles/storage.admin"
  member  = "serviceAccount:${google_service_account.vita_storage_sa.email}"
}

# =============================================================================
# NETWORKING & SECURITY
# =============================================================================

# Firewall rule for web traffic
resource "google_compute_firewall" "vita_web_traffic" {
  name    = "vita-strategies-web"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["80", "443", "8000", "8080", "8180", "3000", "3001", "8081", "8065", "8200"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["vita-strategies"]
}

# Firewall rule for SSH
resource "google_compute_firewall" "vita_ssh" {
  name    = "vita-strategies-ssh"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["vita-strategies"]
}

# =============================================================================
# OUTPUTS
# =============================================================================

output "vm_external_ip" {
  description = "External IP of the VM"
  value       = google_compute_address.vita_static_ip.address
}

output "data_backup_bucket" {
  description = "Main data backup bucket"
  value       = google_storage_bucket.vita_data_backup.name
}

output "erpnext_bucket" {
  description = "ERPNext data bucket"
  value       = google_storage_bucket.erpnext_data.name
}

output "assets_bucket" {
  description = "Application assets bucket"
  value       = google_storage_bucket.app_assets.name
}

output "analytics_bucket" {
  description = "Analytics data bucket"
  value       = google_storage_bucket.analytics_data.name
}

output "team_files_bucket" {
  description = "Team files bucket"
  value       = google_storage_bucket.team_files.name
}

output "service_account_email" {
  description = "Service account for bucket access"
  value       = google_service_account.vita_storage_sa.email
}

output "bucket_urls" {
  description = "Direct URLs to access your buckets"
  value = {
    data_backup  = "https://console.cloud.google.com/storage/browser/${google_storage_bucket.vita_data_backup.name}"
    erpnext_data = "https://console.cloud.google.com/storage/browser/${google_storage_bucket.erpnext_data.name}"
    assets       = "https://console.cloud.google.com/storage/browser/${google_storage_bucket.app_assets.name}"
    analytics    = "https://console.cloud.google.com/storage/browser/${google_storage_bucket.analytics_data.name}"
    team_files   = "https://console.cloud.google.com/storage/browser/${google_storage_bucket.team_files.name}"
  }
}
