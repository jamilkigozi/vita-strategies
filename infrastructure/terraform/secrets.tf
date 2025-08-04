# Secret Manager Configuration
# Purpose: Secure credential storage for all services
# Dependencies: main.tf project configuration

# ============================================================================
# SECRET MANAGER SECRETS
# ============================================================================

# Database passwords
resource "google_secret_manager_secret" "db_passwords" {
  for_each = toset([
    "wordpress", "erpnext", "mattermost", "windmill", 
    "metabase", "grafana", "keycloak", "bookstack"
  ])

  secret_id = "${each.value}-db-password"
  
  replication {
    automatic = true
  }
}

resource "google_secret_manager_secret_version" "db_passwords" {
  for_each = google_secret_manager_secret.db_passwords

  secret      = each.value.id
  secret_data = var.database_passwords[each.key]
}

# Keycloak admin credentials
resource "google_secret_manager_secret" "keycloak_admin" {
  secret_id = "keycloak-admin-user"
  
  replication {
    automatic = true
  }
}

resource "google_secret_manager_secret_version" "keycloak_admin" {
  secret      = google_secret_manager_secret.keycloak_admin.id
  secret_data = var.keycloak_admin_user
}

resource "google_secret_manager_secret" "keycloak_admin_password" {
  secret_id = "keycloak-admin-password"
  
  replication {
    automatic = true
  }
}

resource "google_secret_manager_secret_version" "keycloak_admin_password" {
  secret      = google_secret_manager_secret.keycloak_admin_password.id
  secret_data = var.keycloak_admin_password
}

# ============================================================================
# IAM ACCESS FOR CLOUD RUN
# ============================================================================

# Allow Cloud Run service account to access secrets
resource "google_secret_manager_secret_iam_member" "cloud_run_access" {
  for_each = merge(
    google_secret_manager_secret.db_passwords,
    {
      keycloak_admin = google_secret_manager_secret.keycloak_admin,
      keycloak_admin_password = google_secret_manager_secret.keycloak_admin_password
    }
  )

  secret_id = each.value.secret_id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.cloud_run_sa.email}"
}