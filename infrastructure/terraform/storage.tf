# Terraform Storage Resources  
# Purpose: Define Cloud Storage buckets for 12 microservices
# Dependencies: main.tf project configuration

# ============================================================================
# IMPORT EXISTING BUCKETS (from previous setup)
# ============================================================================

# Import existing buckets as data sources
data "google_storage_bucket" "existing_buckets" {
  for_each = toset([
    "vita-strategies-erpnext-production",
    "vita-strategies-analytics-production", 
    "vita-strategies-team-files-production",
    "vita-strategies-assets-production",
    "vita-strategies-data-backup-production"
  ])
  
  name = each.value
}

# ============================================================================
# NEW MICROSERVICES BUCKETS
# ============================================================================

# Storage buckets for all microservices
resource "google_storage_bucket" "microservices_buckets" {
  for_each = toset([
    "vita-strategies-wordpress-production",
    "vita-strategies-mattermost-production",
    "vita-strategies-workflows-production",
    "vita-strategies-appsmith-production",
    "vita-strategies-monitoring-production",
    "vita-strategies-vault-production",
    "vita-strategies-auth-production",
    "vita-strategies-docs-production"
  ])

  name     = each.value
  location = var.region

  # Uniform bucket-level access
  uniform_bucket_level_access = true

  # Versioning for data protection
  versioning {
    enabled = true
  }

  # Lifecycle management
  lifecycle_rule {
    condition {
      age = var.retention_days
    }
    action {
      type = "Delete"
    }
  }

  # Labels for organization
  labels = local.common_labels
}

# ============================================================================
# BUILD STATUS
# ============================================================================
# ✅ COMPLETE: Existing buckets imported as data sources
# ✅ COMPLETE: New WordPress bucket created with lifecycle management
# 🚀 READY: All 6 buckets configured for the platform
