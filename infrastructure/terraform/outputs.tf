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
    grafana    = "https://monitor.${var.domain_name}"
    appsmith   = "https://apps.${var.domain_name}"
    keycloak   = "https://auth.${var.domain_name}"
    mattermost = "https://chat.${var.domain_name}"
    windmill   = "https://workflows.${var.domain_name}"
  }
}

# ============================================================================
# BUILD STATUS
# ============================================================================
# ✅ COMPLETE: All infrastructure outputs defined
# ✅ COMPLETE: Connection information ready
# ✅ COMPLETE: Service URLs configured
# 🚀 READY: For terraform deployment
