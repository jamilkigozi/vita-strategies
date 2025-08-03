# Terraform Outputs
# Purpose: Export important resource information for use by other components
# Usage: Access via terraform output command or remote state

# ============================================================================
# COMPUTE OUTPUTS
# ============================================================================

output "vm_external_ip" {
  description = "External IP address of the main VM"
  value       = google_compute_address.main.address
}

output "vm_internal_ip" {
  description = "Internal IP address of the main VM"
  value       = google_compute_instance.main.network_interface[0].network_ip
}

output "vm_name" {
  description = "Name of the main VM instance"
  value       = google_compute_instance.main.name
}

output "vm_zone" {
  description = "Zone of the main VM instance"
  value       = google_compute_instance.main.zone
}

# ============================================================================
# NETWORKING OUTPUTS
# ============================================================================

output "vpc_network_name" {
  description = "Name of the VPC network"
  value       = data.google_compute_network.existing_vpc.name
}

output "subnet_name" {
  description = "Name of the compute subnet"
  value       = google_compute_subnetwork.main.name
}

output "subnet_cidr" {
  description = "CIDR block of the compute subnet"
  value       = google_compute_subnetwork.main.ip_cidr_range
}

# ============================================================================
# STORAGE OUTPUTS
# ============================================================================

output "existing_buckets" {
  description = "List of existing storage buckets"
  value = [
    "vita-strategies-erpnext-production",
    "vita-strategies-analytics-production",
    "vita-strategies-team-files-production",
    "vita-strategies-assets-production",
    "vita-strategies-data-backup-production"
  ]
}

output "wordpress_bucket_name" {
  description = "Name of the WordPress storage bucket"
  value       = google_storage_bucket.wordpress.name
}

output "wordpress_bucket_url" {
  description = "URL of the WordPress storage bucket"
  value       = google_storage_bucket.wordpress.url
}

# ============================================================================
# SECURITY OUTPUTS
# ============================================================================

output "vm_service_account_email" {
  description = "Email of the VM service account"
  value       = google_service_account.vm_service_account.email
}

# ============================================================================
# CONNECTION INFORMATION
# ============================================================================

output "ssh_command" {
  description = "SSH command to connect to the VM"
  value       = "ssh appuser@${google_compute_address.main.address}"
}

output "service_urls" {
  description = "URLs for all microservices"
  value = {
    wordpress  = "https://${var.domain_name}"
    erpnext    = "https://erp.${var.domain_name}"
    metabase   = "https://analytics.${var.domain_name}"
    grafana    = "https://monitoring.${var.domain_name}"
    appsmith   = "https://apps.${var.domain_name}"
    keycloak   = "https://auth.${var.domain_name}"
    mattermost = "https://chat.${var.domain_name}"
    windmill   = "https://workflows.${var.domain_name}"
    bookstack  = "https://docs.${var.domain_name}"
    openbao    = "https://vault.${var.domain_name}"
  }
}

# ============================================================================
# DATABASE CONNECTION INFO
# ============================================================================

output "database_connection_info" {
  description = "Database connection information"
  value = {
    postgresql = {
      instance_name   = google_sql_database_instance.postgresql_primary.name
      connection_name = google_sql_database_instance.postgresql_primary.connection_name
      private_ip      = google_sql_database_instance.postgresql_primary.private_ip_address
      databases       = ["mattermost", "windmill", "metabase", "grafana", "openbao", "keycloak"]
    }
    mysql = {
      instance_name   = google_sql_database_instance.mysql_primary.name
      connection_name = google_sql_database_instance.mysql_primary.connection_name
      private_ip      = google_sql_database_instance.mysql_primary.private_ip_address
      databases       = ["wordpress", "bookstack"]
    }
    mariadb = {
      instance_name   = google_sql_database_instance.mariadb_erp.name
      connection_name = google_sql_database_instance.mariadb_erp.connection_name
      private_ip      = google_sql_database_instance.mariadb_erp.private_ip_address
      databases       = ["erpnext"]
    }
  }
  sensitive = true
}

output "storage_buckets" {
  description = "All storage buckets for microservices"
  value = merge(
    {
      for bucket in data.google_storage_bucket.existing_buckets :
      bucket.name => bucket.url
    },
    {
      for bucket in google_storage_bucket.microservices_buckets :
      bucket.name => bucket.url
    }
  )
}

# ============================================================================
# BUILD STATUS
# ============================================================================
# ✅ COMPLETE: All infrastructure outputs defined
# ✅ COMPLETE: Database connection information added
# ✅ COMPLETE: Storage bucket URLs included
# ✅ COMPLETE: Service URLs for all 10 microservices
# 🚀 READY: For terraform deployment
