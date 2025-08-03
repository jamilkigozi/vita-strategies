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

# Grant access to new WordPress bucket
resource "google_storage_bucket_iam_member" "vm_wordpress_bucket_access" {
  bucket = google_storage_bucket.wordpress.name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${google_service_account.vm_service_account.email}"
}

# ============================================================================
# FIREWALL RULES
# ============================================================================
# TODO: Allow HTTP/HTTPS traffic (ports 80, 443)
# TODO: Allow specific application ports (8000, 3000, 8081, etc.)
# TODO: Allow SSH access (port 22) from specific IPs
# TODO: Deny all other traffic by default

# ============================================================================
# SSL CERTIFICATES
# ============================================================================
# TODO: Create managed SSL certificates for domains
# TODO: Set up certificate auto-renewal
# TODO: Configure HTTPS redirects

# ============================================================================
# SECRETS MANAGEMENT
# ============================================================================
# TODO: Set up Secret Manager for sensitive data
# TODO: Store database passwords securely
# TODO: Store API keys and tokens

# ============================================================================
# BUILD STATUS
# ============================================================================
# ⏳ NEXT: Create service accounts and basic IAM
# 📋 TODO: Add firewall rules
# 📋 TODO: Configure SSL certificates
# 📋 TODO: Set up secrets management
