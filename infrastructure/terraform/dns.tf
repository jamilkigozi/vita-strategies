# Terraform DNS Configuration
# Purpose: Manage Cloudflare DNS records for subdomains
# Dependencies: main.tf (external IP), variables.tf (domain config)

# ============================================================================
# CLOUDFLARE ZONE DATA
# ============================================================================

# Get the Cloudflare zone for vitastrategies.com
data "cloudflare_zone" "main" {
  name = var.domain_name
}

# ============================================================================
# DNS RECORDS FOR SUBDOMAINS
# ============================================================================

# Main domain A record (WordPress)
resource "cloudflare_record" "main" {
  zone_id = data.cloudflare_zone.main.id
  name    = var.domain_name
  value   = google_compute_address.main.address
  type    = "A"
  proxied = true  # Enable Cloudflare proxy for SSL and performance
}

# Subdomain A records for microservices
resource "cloudflare_record" "subdomains" {
  for_each = var.subdomain_services
  
  zone_id = data.cloudflare_zone.main.id
  name    = "${each.value}.${var.domain_name}"
  value   = google_compute_address.main.address
  type    = "A"
  proxied = true  # Enable Cloudflare proxy
}

# ============================================================================
# SSL CERTIFICATE SETTINGS
# ============================================================================

# Configure SSL settings for the domain
resource "cloudflare_zone_settings_override" "ssl_settings" {
  zone_id = data.cloudflare_zone.main.id
  
  settings {
    ssl = "full"  # Full SSL encryption
    always_use_https = "on"
    automatic_https_rewrites = "on"
    universal_ssl = "on"
  }
}

# ============================================================================
# BUILD STATUS
# ============================================================================
# ✅ COMPLETE: DNS records for main domain and all subdomains
# ✅ COMPLETE: SSL settings configured
# 🚀 READY: DNS will point to compute instance external IP
