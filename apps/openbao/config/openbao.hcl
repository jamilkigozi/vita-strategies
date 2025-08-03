# OpenBao Production Configuration
# Enterprise secrets management platform for Vita Strategies

# Storage backend - PostgreSQL for production persistence
storage "postgresql" {
  connection_url = "postgres://openbao_user:OPENBAO_DB_PASSWORD@postgres.c.vita-strategies.internal:5432/openbao?sslmode=require"
  table         = "openbao_data"
  
  # Connection pool settings
  max_idle_conns    = 5
  max_conns         = 50
  conn_max_lifetime = "1h"
  
  # High availability settings
  ha_enabled = "true"
  ha_table   = "openbao_ha_locks"
}

# High Availability clustering with integrated storage (Raft)
storage "raft" {
  path    = "/opt/openbao/data/raft"
  node_id = "NODE_ID_PLACEHOLDER"
  
  # Performance tuning
  performance_multiplier = 1
  
  # Automatic snapshots
  autopilot_reconcile_interval = "10s"
  autopilot_update_interval    = "2s"
  
  # Clustering configuration
  retry_join {
    leader_api_addr = "https://vault-1.vitastrategies.com:8200"
  }
  
  retry_join {
    leader_api_addr = "https://vault-2.vitastrategies.com:8200"
  }
  
  retry_join {
    leader_api_addr = "https://vault-3.vitastrategies.com:8200"
  }
}

# Auto-unseal with Google Cloud KMS
seal "gcpckms" {
  project     = "${GCP_PROJECT_ID}"
  region      = "europe-west2"
  key_ring    = "openbao-keyring"
  crypto_key  = "openbao-key"
  
  # Service account key for authentication
  credentials = "/opt/openbao/config/gcp-kms-key.json"
}

# Network listener configuration
listener "tcp" {
  address       = "0.0.0.0:8200"
  cluster_addr  = "0.0.0.0:8201"
  
  # TLS configuration for production
  tls_cert_file      = "/opt/openbao/config/tls.crt"
  tls_key_file       = "/opt/openbao/config/tls.key"
  tls_client_ca_file = "/opt/openbao/config/ca.crt"
  
  # TLS security settings
  tls_min_version         = "tls12"
  tls_cipher_suites       = "TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256,TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384,TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256,TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384"
  tls_prefer_server_cipher_suites = "true"
  tls_require_and_verify_client_cert = "false"
  
  # Performance and security headers
  tls_disable_client_certs = "false"
  
  # API settings
  api_addr      = "https://vault.vitastrategies.com:8200"
  cluster_addr  = "https://vault.vitastrategies.com:8201"
  
  # HTTP timeouts
  http_idle_timeout    = "5m"
  http_read_timeout    = "30s"
  http_write_timeout   = "30s"
  http_read_header_timeout = "10s"
}

# Additional listener for health checks (HTTP only)
listener "tcp" {
  address     = "127.0.0.1:8201"
  tls_disable = "true"
  
  # Restrict to health check endpoint only
  purpose = "health"
}

# Cache configuration
cache {
  # Enable caching for performance
  enabled = true
  
  # Cache size (in MB)
  size = "512MB"
  
  # Cache TTL settings
  default_lease_ttl = "24h"
  max_lease_ttl     = "768h"
}

# API configuration
api_addr     = "https://vault.vitastrategies.com:8200"
cluster_addr = "https://vault.vitastrategies.com:8201"
cluster_name = "vita-strategies"

# UI configuration
ui = true

# Logging configuration
log_level  = "INFO"
log_format = "json"
log_file   = "/var/log/openbao/openbao.log"

# Enable request logging
log_requests_level = "INFO"

# Disable memory lock for containers
disable_mlock = true

# Disable cache for sensitive operations
disable_cache = false

# Enable clustering
disable_clustering = false

# Performance settings
default_lease_ttl = "24h"
max_lease_ttl     = "768h"

# Enable performance standby for read scaling
disable_performance_standby = false

# Seal wrap configuration for additional security
disable_sealwrap = false

# Plugin directory
plugin_directory = "/opt/openbao/plugins"

# Entropy configuration for security
entropy "seal" {
  mode = "augmentation"
}

# Telemetry configuration for monitoring
telemetry {
  # Prometheus metrics
  prometheus_retention_time = "30s"
  disable_hostname          = false
  
  # StatsD configuration (if using external monitoring)
  statsd_address = ""
  
  # Circonus configuration (if using Circonus)
  circonus_api_token = ""
  
  # DogStatsD configuration (if using DataDog)
  dogstatsd_addr = ""
  dogstatsd_tags = ["service:openbao", "environment:production", "cluster:vita-strategies"]
  
  # Usage metrics
  usage_gauge_period = "5m"
  maximum_gauge_cardinality = 500
  
  # Lease metrics
  lease_metrics_epsilon = 1.0
  num_lease_metrics_buckets = 168
}

# Sentinel policies (Enterprise feature)
# sentinel {
#   additional_enabled_modules = []
# }

# License configuration (if using enterprise features)
# license_path = "/opt/openbao/config/license.txt"

# Raw storage encryption
# storage_encryption {
#   backend     = "transit"
#   mount_path  = "transit"
#   key_name    = "openbao-storage-key"
# }

# Experiment flags (for testing new features)
experiments = []

# PID file location
pid_file = "/opt/openbao/data/openbao.pid"

# Administrative configuration
# admin_namespace_path = "admin/"

# Activity log configuration
activity_log {
  enabled             = true
  default_report_months = 12
  retention_months    = 24
}

# Request rate limiting
request_limiter {
  # Enable rate limiting
  enabled = true
  
  # Requests per second per client IP
  rate = 100.0
  
  # Burst allowance
  burst = 200
  
  # Disable for specific paths
  exempt_paths = [
    "/v1/sys/health",
    "/v1/sys/metrics"
  ]
}

# Service registration for discovery
service_registration "consul" {
  address      = "consul.vitastrategies.com:8500"
  service      = "openbao"
  service_tags = "secure,secrets-management,production"
  
  # Health check configuration
  check_timeout = "5s"
  
  # Consul token if ACLs are enabled
  # token = "consul-token"
  
  # TLS configuration for Consul
  # tls_cert_file = "/opt/openbao/config/consul-client.crt"
  # tls_key_file  = "/opt/openbao/config/consul-client.key"
  # tls_ca_file   = "/opt/openbao/config/consul-ca.crt"
}

# Additional security headers
header {
  "Strict-Transport-Security" = ["max-age=31536000; includeSubDomains"]
  "X-Content-Type-Options"    = ["nosniff"]
  "X-Frame-Options"           = ["DENY"]
  "X-XSS-Protection"          = ["1; mode=block"]
  "Referrer-Policy"           = ["strict-origin-when-cross-origin"]
  "Content-Security-Policy"   = ["default-src 'self'; script-src 'self' 'unsafe-inline'; style-src 'self' 'unsafe-inline'"]
}

# Custom response headers for API
custom_response_headers {
  "default" = {
    "X-OpenBao-Cluster" = ["vita-strategies"]
    "X-Service-Name"    = ["OpenBao Secrets Management"]
  }
  
  "200" = {
    "X-Response-Time" = ["${response_time}ms"]
  }
}

# Replication configuration (Enterprise feature)
# replication {
#   performance {
#     primary_cluster_addr = "https://vault-primary.vitastrategies.com:8201"
#   }
#   
#   dr {
#     primary_cluster_addr = "https://vault-dr.vitastrategies.com:8201"
#   }
# }

# Transform configuration (Enterprise feature)
# transform {
#   # Enable format preserving encryption
#   enabled = true
# }

# MFA configuration
# mfa {
#   type = "totp"
#   config = {
#     issuer = "Vita Strategies OpenBao"
#   }
# }
