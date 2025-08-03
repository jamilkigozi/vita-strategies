# Terraform Database Resources (Cloud SQL)
# Purpose: Database instances for all microservices
# Dependencies: main.tf networking, security.tf service accounts

# ============================================================================
# CLOUD SQL INSTANCES
# ============================================================================

# PostgreSQL instance for multiple microservices
resource "google_sql_database_instance" "postgresql_primary" {
  name                = "${var.project_name}-postgresql-primary"
  database_version    = "POSTGRES_15"
  region              = var.region
  deletion_protection = false # Set to true in production

  settings {
    tier = "db-g1-small" # Start small, can scale up

    backup_configuration {
      enabled                        = true
      start_time                     = "03:00"
      location                       = var.region
      point_in_time_recovery_enabled = true
      backup_retention_settings {
        retained_backups = 7
      }
    }

    ip_configuration {
      ipv4_enabled    = false  # Private access only - no public IP
      private_network = data.google_compute_network.existing_vpc.id
      # No authorized_networks needed - internal GCP access only
    }

    database_flags {
      name  = "max_connections"
      value = "200"
    }
  }
}

# MySQL instance for WordPress and BookStack
resource "google_sql_database_instance" "mysql_primary" {
  name                = "${var.project_name}-mysql-primary"
  database_version    = "MYSQL_8_0"
  region              = var.region
  deletion_protection = false # Set to true in production

  settings {
    tier = "db-g1-small"

    backup_configuration {
      enabled                        = true
      start_time                     = "04:00"
      location                       = var.region
      point_in_time_recovery_enabled = true
      backup_retention_settings {
        retained_backups = 7
      }
    }

    ip_configuration {
      ipv4_enabled    = false  # Private access only - no public IP
      private_network = data.google_compute_network.existing_vpc.id
      # No authorized_networks needed - internal GCP access only
    }
  }
}

# MariaDB instance for ERPNext
resource "google_sql_database_instance" "mariadb_erp" {
  name                = "${var.project_name}-mariadb-erp"
  database_version    = "MYSQL_8_0" # Using MySQL 8.0 as MariaDB equivalent
  region              = var.region
  deletion_protection = false # Set to true in production

  settings {
    tier = "db-g1-small"

    backup_configuration {
      enabled                        = true
      start_time                     = "05:00"
      location                       = var.region
      point_in_time_recovery_enabled = true
      backup_retention_settings {
        retained_backups = 7
      }
    }

    ip_configuration {
      ipv4_enabled    = false  # Private access only - no public IP
      private_network = data.google_compute_network.existing_vpc.id
      # No authorized_networks needed - internal GCP access only
    }
  }
}

# ============================================================================
# DATABASES
# ============================================================================

# PostgreSQL databases
resource "google_sql_database" "postgresql_databases" {
  for_each = toset([
    "mattermost",
    "windmill",
    "metabase",
    "grafana",
    "openbao",
    "keycloak"
  ])

  name     = each.value
  instance = google_sql_database_instance.postgresql_primary.name
}

# MySQL databases
resource "google_sql_database" "mysql_databases" {
  for_each = toset([
    "wordpress",
    "bookstack"
  ])

  name     = each.value
  instance = google_sql_database_instance.mysql_primary.name
}

# ERPNext database
resource "google_sql_database" "erpnext_database" {
  name     = "erpnext"
  instance = google_sql_database_instance.mariadb_erp.name
}

# ============================================================================
# DATABASE USERS
# ============================================================================

# PostgreSQL users for each service
resource "google_sql_user" "postgresql_users" {
  for_each = toset([
    "mattermost",
    "windmill",
    "metabase",
    "grafana",
    "openbao",
    "keycloak"
  ])

  name     = each.value
  instance = google_sql_database_instance.postgresql_primary.name
  password = var.database_passwords[each.value]
}

# MySQL users
resource "google_sql_user" "mysql_users" {
  for_each = toset([
    "wordpress",
    "bookstack"
  ])

  name     = each.value
  instance = google_sql_database_instance.mysql_primary.name
  password = var.database_passwords[each.value]
}

# ERPNext user
resource "google_sql_user" "erpnext_user" {
  name     = "erpnext"
  instance = google_sql_database_instance.mariadb_erp.name
  password = var.database_passwords["erpnext"]
}

# ============================================================================
# BUILD STATUS
# ============================================================================
# ✅ COMPLETE: 3 Cloud SQL instances (PostgreSQL, MySQL, MariaDB)
# ✅ COMPLETE: 9 databases across all instances
# ✅ COMPLETE: Database users with secure passwords
# 🚀 READY: Database infrastructure for all 12 microservices
