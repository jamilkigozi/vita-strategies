variable "project_id" {
  description = "The GCP project ID"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "bucket_prefix" {
  description = "Prefix for bucket names"
  type        = string
}

variable "region" {
  description = "The GCP region"
  type        = string
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}

# Application storage bucket
resource "google_storage_bucket" "app_storage" {
  name     = "${var.bucket_prefix}-${var.environment}-app"
  location = var.region
  project  = var.project_id

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

  labels = var.tags
}

# Backup storage bucket
resource "google_storage_bucket" "backup_storage" {
  name     = "${var.bucket_prefix}-${var.environment}-backups"
  location = var.region
  project  = var.project_id

  uniform_bucket_level_access = true
  
  versioning {
    enabled = true
  }

  lifecycle_rule {
    condition {
      age = 90
    }
    action {
      type = "Delete"
    }
  }

  labels = var.tags
}

# Terraform state bucket (for remote state)
resource "google_storage_bucket" "terraform_state" {
  name     = "${var.bucket_prefix}-${var.environment}-terraform-state"
  location = var.region
  project  = var.project_id

  uniform_bucket_level_access = true
  
  versioning {
    enabled = true
  }

  # Prevent accidental deletion
  lifecycle {
    prevent_destroy = true
  }

  labels = var.tags
}
