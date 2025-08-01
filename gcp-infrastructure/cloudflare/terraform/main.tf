terraform {
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 4.0"
    }
  }
}

provider "cloudflare" {
  api_token = var.cloudflare_api_token
}

# Zone configuration
data "cloudflare_zone" "vita_strategies" {
  name = var.domain_name
}

# DNS Records for all services
resource "cloudflare_record" "erpnext" {
  zone_id = data.cloudflare_zone.vita_strategies.id
  name    = "erp"
  value   = var.gcp_load_balancer_ip
  type    = "A"
  proxied = true
}

resource "cloudflare_record" "windmill" {
  zone_id = data.cloudflare_zone.vita_strategies.id
  name    = "workflows"
  value   = var.gcp_load_balancer_ip
  type    = "A"
  proxied = true
}

resource "cloudflare_record" "keycloak" {
  zone_id = data.cloudflare_zone.vita_strategies.id
  name    = "auth"
  value   = var.gcp_load_balancer_ip
  type    = "A"
  proxied = true
}

resource "cloudflare_record" "metabase" {
  zone_id = data.cloudflare_zone.vita_strategies.id
  name    = "analytics"
  value   = var.gcp_load_balancer_ip
  type    = "A"
  proxied = true
}

resource "cloudflare_record" "appsmith" {
  zone_id = data.cloudflare_zone.vita_strategies.id
  name    = "apps"
  value   = var.gcp_load_balancer_ip
  type    = "A"
  proxied = true
}

resource "cloudflare_record" "mattermost" {
  zone_id = data.cloudflare_zone.vita_strategies.id
  name    = "chat"
  value   = var.gcp_load_balancer_ip
  type    = "A"
  proxied = true
}

resource "cloudflare_record" "grafana" {
  zone_id = data.cloudflare_zone.vita_strategies.id
  name    = "monitoring"
  value   = var.gcp_load_balancer_ip
  type    = "A"
  proxied = true
}

# SSL/TLS Configuration
resource "cloudflare_zone_settings_override" "vita_strategies_settings" {
  zone_id = data.cloudflare_zone.vita_strategies.id
  
  settings {
    ssl                      = "full"
    always_use_https        = "on"
    automatic_https_rewrites = "on"
    tls_1_3                 = "on"
    min_tls_version         = "1.2"
    hsts {
      enabled            = true
      max_age           = 31536000
      include_subdomains = true
      preload           = true
    }
  }
}
