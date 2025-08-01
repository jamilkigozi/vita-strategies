variable "cloudflare_api_token" {
  description = "Cloudflare API token for managing DNS and settings"
  type        = string
  sensitive   = true
}

variable "domain_name" {
  description = "Primary domain name for the platform"
  type        = string
  default     = "vitastrategies.com"
}

variable "gcp_load_balancer_ip" {
  description = "GCP Load Balancer external IP address"
  type        = string
}

variable "cloudflare_account_id" {
  description = "Cloudflare account ID"
  type        = string
  sensitive   = true
}
