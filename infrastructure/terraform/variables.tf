# Terraform Variables
# Purpose: Define all configurable parameters for infrastructure
# Usage: Set values in terraform.tfvars or via command line

# ============================================================================
# PROJECT CONFIGURATION
# ============================================================================

variable "project_id" {
  description = "The GCP project ID"
  type        = string
  default     = "vita-strategies"
}

variable "project_name" {
  description = "The project name for resource naming"
  type        = string
  default     = "vita-strategies"
}

variable "region" {
  description = "The GCP region for resources"
  type        = string
  default     = "europe-west2"
}

variable "zone" {
  description = "The GCP zone for compute instances"
  type        = string
  default     = "europe-west2-c"
}

variable "environment" {
  description = "Environment (dev/staging/production)"
  type        = string
  default     = "production"
}

# ============================================================================
# COMPUTE CONFIGURATION
# ============================================================================

variable "machine_type" {
  description = "GCP machine type for the main VM"
  type        = string
  default     = "e2-standard-4"  # 4 vCPUs, 16GB RAM
}

variable "disk_size" {
  description = "Boot disk size in GB"
  type        = number
  default     = 50
}

variable "boot_image" {
  description = "Boot disk image"
  type        = string
  default     = "ubuntu-os-cloud/ubuntu-2204-lts"
}

# ============================================================================
# NETWORKING CONFIGURATION  
# ============================================================================

variable "subnet_cidr" {
  description = "CIDR block for the main subnet"
  type        = string
  default     = "10.0.0.0/24"
}

variable "allowed_ports" {
  description = "List of ports to allow in firewall"
  type        = list(string)
  default     = ["22", "80", "443", "3000", "3001", "8000", "8065", "8080", "8081", "8180", "8200"]
}

# ============================================================================
# STORAGE CONFIGURATION
# ============================================================================

variable "bucket_names" {
  description = "List of storage bucket names"
  type        = list(string)
  default     = [
    "vita-strategies-erpnext-production",
    "vita-strategies-analytics-production", 
    "vita-strategies-team-files-production",
    "vita-strategies-assets-production",
    "vita-strategies-data-backup-production",
    "vita-strategies-wordpress-production"
  ]
}

variable "storage_class" {
  description = "Storage class for buckets"
  type        = string
  default     = "STANDARD"
}

variable "retention_days" {
  description = "Retention policy in days"
  type        = number
  default     = 30
}

# ============================================================================
# SECURITY CONFIGURATION
# ============================================================================

variable "admin_ip" {
  description = "Admin IP address for SSH access"
  type        = string
  default     = "109.152.108.104/32"
}

variable "ssh_public_key" {
  description = "SSH public key for VM access"
  type        = string
  default     = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIG9lA16xDJFBbLY8m9Luc4dLFWH5XhOJPXZfqjrDHbt2"
}

variable "domain_name" {
  description = "Main domain name"
  type        = string
  default     = "vitastrategies.com"
}

variable "cloudflare_email" {
  description = "Cloudflare account email"
  type        = string
  default     = "jamil.kigozi@hotmail.com"
}

variable "cloudflare_api_token" {
  description = "Cloudflare API token for DNS management"
  type        = string
  default     = "WFcBUZM0zXBEMqx5Vb7_KGqGCAxw4PBL9p5JVvBa"
  sensitive   = true
}

variable "subdomain_services" {
  description = "Mapping of services to subdomains"
  type        = map(string)
  default     = {
    erpnext    = "erp"
    metabase   = "analytics" 
    grafana    = "monitor"
    appsmith   = "apps"
    keycloak   = "auth"
    mattermost = "chat"
    windmill   = "workflows"
  }
}

# ============================================================================
# BUILD STATUS
# ============================================================================
# ✅ COMPLETE: All variables defined and configured
# 🚀 READY: For main.tf configuration
