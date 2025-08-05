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
