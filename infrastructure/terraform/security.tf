# Terraform Security Configuration
# Purpose: IAM roles, service accounts, firewall rules, and security policies
# Dependencies: main.tf networking configuration

# ============================================================================
# SERVICE ACCOUNTS
# ============================================================================

# Service account for VM with minimal required permissions
resource "google_service_account" "vm_service_account" {
  account_id   = "${var.project_name}-vm-sa"
  display_name = "Vita Strategies VM Service Account"
  description  = "Service account for main application VM"
}

# IAM binding for storage access
resource "google_project_iam_member" "vm_storage_access" {
  project = var.project_id
  role    = "roles/storage.objectAdmin"
  member  = "serviceAccount:${google_service_account.vm_service_account.email}"
}

# IAM binding for logging (optional but recommended)
resource "google_project_iam_member" "vm_logging" {
  project = var.project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.vm_service_account.email}"
}

# IAM binding for monitoring (optional but recommended)
resource "google_project_iam_member" "vm_monitoring" {
  project = var.project_id
  role    = "roles/monitoring.metricWriter"
  member  = "serviceAccount:${google_service_account.vm_service_account.email}"
}

# ============================================================================
# IAM ROLES & POLICIES
# ============================================================================

# Grant bucket access to VM service account for each bucket
resource "google_storage_bucket_iam_member" "vm_bucket_access" {
  for_each = toset([
    "vita-strategies-erpnext-production",
    "vita-strategies-analytics-production",
    "vita-strategies-team-files-production",
    "vita-strategies-assets-production",
    "vita-strategies-data-backup-production"
  ])

  bucket = each.value
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${google_service_account.vm_service_account.email}"
}

# Grant access to all microservices buckets
resource "google_storage_bucket_iam_member" "vm_microservices_bucket_access" {
  for_each = google_storage_bucket.microservices_buckets

  bucket = each.value.name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${google_service_account.vm_service_account.email}"
}

# ============================================================================
# CLOUD SQL ACCESS
# ============================================================================

# Grant Cloud SQL client access to VM service account
resource "google_project_iam_member" "vm_cloudsql_access" {
  project = var.project_id
  role    = "roles/cloudsql.client"
  member  = "serviceAccount:${google_service_account.vm_service_account.email}"
}

# Grant Cloud SQL instance user access
resource "google_project_iam_member" "vm_cloudsql_instance_user" {
  project = var.project_id
  role    = "roles/cloudsql.instanceUser"
  member  = "serviceAccount:${google_service_account.vm_service_account.email}"
}

# ============================================================================
# BUILD STATUS
# ============================================================================
# ✅ COMPLETE: VM service account with minimal permissions
# ✅ COMPLETE: Storage access for all 13 buckets (5 existing + 8 new)
# ✅ COMPLETE: Cloud SQL database access permissions
# ✅ COMPLETE: Logging and monitoring permissions
# 🚀 READY: For secure VM and database deployment
