# Terraform Variables
# Purpose: Define all configurable parameters for infrastructure
# Usage: Set values in terraform.tfvars or via command line
# SECURITY NOTE: Never commit terraform.tfvars to version control

# ============================================================================
# PROJECT CONFIGURATION
# ============================================================================

variable "project_id" {
  description = "The GCP project ID"
  type        = string
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
  default     = "e2-standard-4"
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

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  description = "CIDR block for the public subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "private_subnet_cidr" {
  description = "CIDR block for the private subnet"
  type        = string
  default     = "10.0.2.0/24"
}

variable "database_subnet_cidr" {
  description = "CIDR block for the database subnet"
  type        = string
  default     = "10.0.3.0/24"
}

# ============================================================================
# STORAGE CONFIGURATION
# ============================================================================

variable "bucket_names" {
  description = "List of storage bucket names"
  type        = list(string)
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
  description = "Admin IP address for SSH access (CIDR format)"
  type        = string
}

variable "ssh_public_key" {
  description = "SSH public key for VM access"
  type        = string
}

variable "domain_name" {
  description = "Main domain name"
  type        = string
}

variable "cloudflare_email" {
  description = "Cloudflare account email"
  type        = string
}

variable "cloudflare_api_token" {
  description = "Cloudflare API token for DNS management"
  type        = string
  sensitive   = true
}

variable "subdomain_services" {
  description = "Mapping of services to subdomains"
  type        = map(string)
  default = {
    erpnext    = "erp"
    metabase   = "analytics"
    grafana    = "monitor"
    appsmith   = "apps"
    keycloak   = "auth"
    mattermost = "chat"
    windmill   = "workflows"
    wordpress  = "www"
    openbao    = "vault"
  }
}

variable "user_ip" {
  description = "User's public IP address for database access"
  type        = string
}



variable "keycloak_admin_user" {
  description = "Keycloak admin username"
  type        = string
  sensitive   = true
}

variable "keycloak_admin_password" {
  description = "Keycloak admin password"
  type        = string
  sensitive   = true
}

# ============================================================================
# DATABASE CONFIGURATION
# ============================================================================

variable "database_passwords" {
  description = "Map of database users to their passwords"
  type        = map(string)
  sensitive   = true
}

variable "db_version" {
  description = "PostgreSQL database version"
  type        = string
  default     = "POSTGRES_15"
}

variable "db_instance_type" {
  description = "Cloud SQL instance type"
  type        = string
  default     = "db-f1-micro"
}

variable "db_disk_size" {
  description = "Database disk size in GB"
  type        = number
  default     = 20
}

variable "db_backup_enabled" {
  description = "Enable automated database backups"
  type        = bool
  default     = true
}

variable "db_backup_start_time" {
  description = "Time when database backup starts (HH:MM format)"
  type        = string
  default     = "02:00"
}

# ============================================================================
# MONITORING & ALERTING
# ============================================================================

variable "enable_monitoring" {
  description = "Enable monitoring and alerting"
  type        = bool
  default     = true
}

variable "notification_email" {
  description = "Email for monitoring alerts"
  type        = string
  default     = ""
}

# ============================================================================
# ENCRYPTION CONFIGURATION
# ============================================================================

variable "enable_encryption" {
  description = "Enable encryption at rest for all services"
  type        = bool
  default     = true
}

variable "kms_key_rotation_period" {
  description = "KMS key rotation period in seconds"
  type        = string
  default     = "7776000s" # 90 days
}
