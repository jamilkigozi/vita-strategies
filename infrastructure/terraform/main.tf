# Terraform Main Configuration
# Purpose: Core GCP infrastructure foundation
# Dependencies: GCP project with billing enabled
# Usage: terraform init && terraform plan && terraform apply

# ============================================================================
# PROVIDER CONFIGURATION
# ============================================================================

terraform {
  required_version = ">= 1.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 4.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}

provider "cloudflare" {
  email     = var.cloudflare_email
  api_token = var.cloudflare_api_token
}

# ============================================================================
# DATA SOURCES
# ============================================================================

data "google_project" "current" {
  project_id = var.project_id
}

# ============================================================================
# PROJECT & APIS  
# ============================================================================

# Enable required APIs for the project
resource "google_project_service" "apis" {
  for_each = toset([
    "compute.googleapis.com",
    "storage.googleapis.com",
    "iam.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "monitoring.googleapis.com",
    "logging.googleapis.com"
  ])

  project = var.project_id
  service = each.value

  disable_dependent_services = false
  disable_on_destroy         = false
}

# ============================================================================
# NETWORKING
# ============================================================================

# Use existing VPC network
data "google_compute_network" "existing_vpc" {
  name = "vita-strategies-vpc"
}

# Create subnet for compute instances in existing VPC
resource "google_compute_subnetwork" "main" {
  name          = "${var.project_name}-compute-subnet"
  ip_cidr_range = var.subnet_cidr
  region        = var.region
  network       = data.google_compute_network.existing_vpc.id

  # Enable private Google access
  private_ip_google_access = true
}

# Create external IP for the main VM
resource "google_compute_address" "main" {
  name   = "${var.project_name}-external-ip"
  region = var.region
}

# Firewall rule to allow HTTP/HTTPS traffic
resource "google_compute_firewall" "web" {
  name    = "${var.project_name}-allow-web"
  network = data.google_compute_network.existing_vpc.name

  allow {
    protocol = "tcp"
    ports    = ["80", "443"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["web-server"]
}

# Firewall rule to allow application ports
resource "google_compute_firewall" "apps" {
  name    = "${var.project_name}-allow-apps"
  network = data.google_compute_network.existing_vpc.name

  allow {
    protocol = "tcp"
    ports    = var.allowed_ports
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["app-server"]
}

# Firewall rule to allow SSH (restricted to admin IP)
resource "google_compute_firewall" "ssh" {
  name    = "${var.project_name}-allow-ssh"
  network = data.google_compute_network.existing_vpc.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = [var.admin_ip]
  target_tags   = ["ssh-access"]
}

# ============================================================================
# LOCALS & DATA SOURCES
# ============================================================================

locals {
  # Resource naming convention: vita-strategies-{resource-type}-{environment}
  common_labels = {
    project     = var.project_name
    environment = var.environment
    managed_by  = "terraform"
    created_at  = formatdate("YYYY-MM-DD", timestamp())
  }

  # Service ports mapping
  service_ports = {
    ssh        = "22"
    http       = "80"
    https      = "443"
    metabase   = "3000"
    grafana    = "3001"
    erpnext    = "8000"
    mattermost = "8065"
    windmill   = "8080"
    appsmith   = "8081"
    keycloak   = "8180"
    openbao    = "8200"
  }
}

# ============================================================================
# RESOURCE NAMING CONVENTION
# ============================================================================
# Format: vita-strategies-{resource-type}-{environment}
# Examples:
# ✅ vita-strategies-vm-production
# ✅ vita-strategies-bucket-backups-production  
# ✅ vita-strategies-network-production

# ============================================================================
# BUILD STATUS
# ============================================================================
# ✅ COMPLETE: Provider configuration
# ✅ COMPLETE: Project and API configurations  
# ✅ COMPLETE: Networking resources (VPC, subnet, firewall, external IP)
# ✅ COMPLETE: Security configurations (firewall rules)
# 🎯 READY: Move to compute.tf for VM configuration
