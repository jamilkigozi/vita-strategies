# OpenBao Production Configuration
storage "postgresql" {
  connection_url = "${OPENBAO_DATABASE_URL}"
  table         = "openbao_data"
  ha_enabled    = "true"
  ha_table      = "openbao_ha_locks"
}

listener "tcp" {
  address       = "0.0.0.0:8200"
  tls_cert_file = "/opt/openbao/config/tls.crt"
  tls_key_file  = "/opt/openbao/config/tls.key"
  tls_min_version = "tls12"
}

api_addr     = "https://vault.vitastrategies.com:8200"
cluster_addr = "https://vault.vitastrategies.com:8201"
cluster_name = "vita-strategies"

ui = true
log_level = "INFO"
log_format = "json"

disable_mlock = true
default_lease_ttl = "24h"
max_lease_ttl = "768h"

telemetry {
  prometheus_retention_time = "30s"
  disable_hostname = false
}