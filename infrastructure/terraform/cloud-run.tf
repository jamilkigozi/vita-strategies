# Cloud Run Services Configuration
# Purpose: Deploy all microservices to Cloud Run
# Dependencies: database.tf, storage.tf, security.tf

# ============================================================================
# CLOUD RUN SERVICES
# ============================================================================

# WordPress
resource "google_cloud_run_service" "wordpress" {
  name     = "${var.project_name}-wordpress"
  location = var.region

  template {
    spec {
      containers {
        image = "gcr.io/${var.project_id}/wordpress:latest"
        
        env {
          name  = "WORDPRESS_DB_HOST"
          value = google_sql_database_instance.mysql_primary.private_ip_address
        }
        env {
          name  = "WORDPRESS_DB_NAME"
          value = "wordpress"
        }
        env {
          name  = "WORDPRESS_DB_USER"
          value = "wordpress"
        }
        env {
          name = "WORDPRESS_DB_PASSWORD"
          value_from {
            secret_key_ref {
              name = google_secret_manager_secret_version.db_passwords["wordpress"].secret
              key  = "latest"
            }
          }
        }

        volume_mounts {
          name       = "wordpress-storage"
          mount_path = "/var/www/html/wp-content"
        }
      }

      volumes {
        name = "wordpress-storage"
        gcs {
          bucket = "vita-strategies-wordpress-production"
        }
      }

      service_account_name = google_service_account.cloud_run_sa.email
    }

    metadata {
      annotations = {
        "autoscaling.knative.dev/maxScale" = "10"
        "run.googleapis.com/cloudsql-instances" = google_sql_database_instance.mysql_primary.connection_name
      }
    }
  }

  traffic {
    percent         = 100
    latest_revision = true
  }
}

# ERPNext
resource "google_cloud_run_service" "erpnext" {
  name     = "${var.project_name}-erpnext"
  location = var.region

  template {
    spec {
      containers {
        image = "gcr.io/${var.project_id}/erpnext:latest"
        
        env {
          name  = "MARIADB_HOST"
          value = google_sql_database_instance.mariadb_erp.private_ip_address
        }
        env {
          name  = "MARIADB_DATABASE"
          value = "erpnext"
        }
        env {
          name  = "MARIADB_USER"
          value = "erpnext"
        }
        env {
          name = "MARIADB_PASSWORD"
          value_from {
            secret_key_ref {
              name = google_secret_manager_secret_version.db_passwords["erpnext"].secret
              key  = "latest"
            }
          }
        }

        volume_mounts {
          name       = "erpnext-storage"
          mount_path = "/home/frappe/frappe-bench/sites"
        }
      }

      volumes {
        name = "erpnext-storage"
        gcs {
          bucket = "vita-strategies-erpnext-production"
        }
      }

      service_account_name = google_service_account.cloud_run_sa.email
    }

    metadata {
      annotations = {
        "autoscaling.knative.dev/maxScale" = "5"
        "run.googleapis.com/cloudsql-instances" = google_sql_database_instance.mariadb_erp.connection_name
      }
    }
  }

  traffic {
    percent         = 100
    latest_revision = true
  }
}

# Mattermost
resource "google_cloud_run_service" "mattermost" {
  name     = "${var.project_name}-mattermost"
  location = var.region

  template {
    spec {
      containers {
        image = "gcr.io/${var.project_id}/mattermost:latest"
        
        env {
          name  = "MM_SQLSETTINGS_DRIVERNAME"
          value = "postgres"
        }
        env {
          name  = "MM_SQLSETTINGS_DATASOURCE"
          value = "postgres://mattermost:${var.database_passwords["mattermost"]}@${google_sql_database_instance.postgresql_primary.private_ip_address}:5432/mattermost?sslmode=disable"
        }
        env {
          name  = "MM_SERVICESETTINGS_SITEURL"
          value = "https://chat.vitastrategies.com"
        }

        volume_mounts {
          name       = "mattermost-storage"
          mount_path = "/mattermost/data"
        }
      }

      volumes {
        name = "mattermost-storage"
        gcs {
          bucket = "vita-strategies-mattermost-production"
        }
      }

      service_account_name = google_service_account.cloud_run_sa.email
    }

    metadata {
      annotations = {
        "autoscaling.knative.dev/maxScale" = "10"
        "run.googleapis.com/cloudsql-instances" = google_sql_database_instance.postgresql_primary.connection_name
      }
    }
  }

  traffic {
    percent         = 100
    latest_revision = true
  }
}

# Windmill
resource "google_cloud_run_service" "windmill" {
  name     = "${var.project_name}-windmill"
  location = var.region

  template {
    spec {
      containers {
        image = "gcr.io/${var.project_id}/windmill:latest"
        
        env {
          name  = "DATABASE_URL"
          value = "postgresql://windmill:${var.database_passwords["windmill"]}@${google_sql_database_instance.postgresql_primary.private_ip_address}:5432/windmill"
        }

        volume_mounts {
          name       = "windmill-storage"
          mount_path = "/tmp/windmill"
        }
      }

      volumes {
        name = "windmill-storage"
        gcs {
          bucket = "vita-strategies-workflows-production"
        }
      }

      service_account_name = google_service_account.cloud_run_sa.email
    }

    metadata {
      annotations = {
        "autoscaling.knative.dev/maxScale" = "20"
        "run.googleapis.com/cloudsql-instances" = google_sql_database_instance.postgresql_primary.connection_name
      }
    }
  }

  traffic {
    percent         = 100
    latest_revision = true
  }
}

# Metabase
resource "google_cloud_run_service" "metabase" {
  name     = "${var.project_name}-metabase"
  location = var.region

  template {
    spec {
      containers {
        image = "gcr.io/${var.project_id}/metabase:latest"
        
        env {
          name  = "MB_DB_TYPE"
          value = "postgres"
        }
        env {
          name  = "MB_DB_HOST"
          value = google_sql_database_instance.postgresql_primary.private_ip_address
        }
        env {
          name  = "MB_DB_DBNAME"
          value = "metabase"
        }
        env {
          name  = "MB_DB_USER"
          value = "metabase"
        }
        env {
          name = "MB_DB_PASS"
          value_from {
            secret_key_ref {
              name = google_secret_manager_secret_version.db_passwords["metabase"].secret
              key  = "latest"
            }
          }
        }

        volume_mounts {
          name       = "metabase-storage"
          mount_path = "/metabase-data"
        }
      }

      volumes {
        name = "metabase-storage"
        gcs {
          bucket = "vita-strategies-analytics-production"
        }
      }

      service_account_name = google_service_account.cloud_run_sa.email
    }

    metadata {
      annotations = {
        "autoscaling.knative.dev/maxScale" = "5"
        "run.googleapis.com/cloudsql-instances" = google_sql_database_instance.postgresql_primary.connection_name
      }
    }
  }

  traffic {
    percent         = 100
    latest_revision = true
  }
}

# Grafana
resource "google_cloud_run_service" "grafana" {
  name     = "${var.project_name}-grafana"
  location = var.region

  template {
    spec {
      containers {
        image = "gcr.io/${var.project_id}/grafana:latest"
        
        env {
          name  = "GF_DATABASE_TYPE"
          value = "postgres"
        }
        env {
          name  = "GF_DATABASE_HOST"
          value = "${google_sql_database_instance.postgresql_primary.private_ip_address}:5432"
        }
        env {
          name  = "GF_DATABASE_NAME"
          value = "grafana"
        }
        env {
          name  = "GF_DATABASE_USER"
          value = "grafana"
        }
        env {
          name = "GF_DATABASE_PASSWORD"
          value_from {
            secret_key_ref {
              name = google_secret_manager_secret_version.db_passwords["grafana"].secret
              key  = "latest"
            }
          }
        }
        env {
          name  = "GF_SERVER_ROOT_URL"
          value = "https://monitoring.vitastrategies.com"
        }

        volume_mounts {
          name       = "grafana-storage"
          mount_path = "/var/lib/grafana"
        }
      }

      volumes {
        name = "grafana-storage"
        gcs {
          bucket = "vita-strategies-monitoring-production"
        }
      }

      service_account_name = google_service_account.cloud_run_sa.email
    }

    metadata {
      annotations = {
        "autoscaling.knative.dev/maxScale" = "3"
        "run.googleapis.com/cloudsql-instances" = google_sql_database_instance.postgresql_primary.connection_name
      }
    }
  }

  traffic {
    percent         = 100
    latest_revision = true
  }
}

# Keycloak
resource "google_cloud_run_service" "keycloak" {
  name     = "${var.project_name}-keycloak"
  location = var.region

  template {
    spec {
      containers {
        image = "gcr.io/${var.project_id}/keycloak:latest"
        
        env {
          name  = "KC_DB"
          value = "postgres"
        }
        env {
          name  = "KC_DB_URL"
          value = "jdbc:postgresql://${google_sql_database_instance.postgresql_primary.private_ip_address}:5432/keycloak"
        }
        env {
          name  = "KC_DB_USERNAME"
          value = "keycloak"
        }
        env {
          name = "KC_DB_PASSWORD"
          value_from {
            secret_key_ref {
              name = google_secret_manager_secret_version.db_passwords["keycloak"].secret
              key  = "latest"
            }
          }
        }
        env {
          name  = "KC_HOSTNAME"
          value = "auth.vitastrategies.com"
        }
        env {
          name = "KEYCLOAK_ADMIN"
          value_from {
            secret_key_ref {
              name = google_secret_manager_secret_version.keycloak_admin.secret
              key  = "latest"
            }
          }
        }
        env {
          name = "KEYCLOAK_ADMIN_PASSWORD"
          value_from {
            secret_key_ref {
              name = google_secret_manager_secret_version.keycloak_admin_password.secret
              key  = "latest"
            }
          }
        }

        volume_mounts {
          name       = "keycloak-storage"
          mount_path = "/opt/keycloak/data"
        }
      }

      volumes {
        name = "keycloak-storage"
        gcs {
          bucket = "vita-strategies-auth-production"
        }
      }

      service_account_name = google_service_account.cloud_run_sa.email
    }

    metadata {
      annotations = {
        "autoscaling.knative.dev/maxScale" = "5"
        "run.googleapis.com/cloudsql-instances" = google_sql_database_instance.postgresql_primary.connection_name
      }
    }
  }

  traffic {
    percent         = 100
    latest_revision = true
  }
}

# ============================================================================
# IAM POLICIES FOR CLOUD RUN
# ============================================================================

# Allow public access to services
resource "google_cloud_run_service_iam_member" "public_access" {
  for_each = toset([
    google_cloud_run_service.wordpress.name,
    google_cloud_run_service.erpnext.name,
    google_cloud_run_service.mattermost.name,
    google_cloud_run_service.windmill.name,
    google_cloud_run_service.metabase.name,
    google_cloud_run_service.grafana.name,
    google_cloud_run_service.keycloak.name
  ])

  service  = each.value
  location = var.region
  role     = "roles/run.invoker"
  member   = "allUsers"
}