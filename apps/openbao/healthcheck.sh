#!/bin/bash

# OpenBao Health Check Script
# Comprehensive monitoring for secrets management platform

# Exit codes
HEALTH_OK=0
HEALTH_WARNING=1
HEALTH_CRITICAL=2

# Configuration
OPENBAO_ADDR=${OPENBAO_ADDR:-"http://127.0.0.1:8200"}
TIMEOUT=${HEALTH_CHECK_TIMEOUT:-10}
CRITICAL_THRESHOLD=${CRITICAL_THRESHOLD:-90}
WARNING_THRESHOLD=${WARNING_THRESHOLD:-75}

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Logging functions
log_ok() {
    echo -e "${GREEN}[OK]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_critical() {
    echo -e "${RED}[CRITICAL]${NC} $1"
}

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

# Global status tracking
OVERALL_STATUS=$HEALTH_OK
CHECKS_PASSED=0
CHECKS_TOTAL=0

# Function to update overall status
update_status() {
    local check_status=$1
    CHECKS_TOTAL=$((CHECKS_TOTAL + 1))
    
    if [ $check_status -eq $HEALTH_OK ]; then
        CHECKS_PASSED=$((CHECKS_PASSED + 1))
    elif [ $check_status -eq $HEALTH_WARNING ] && [ $OVERALL_STATUS -eq $HEALTH_OK ]; then
        OVERALL_STATUS=$HEALTH_WARNING
    elif [ $check_status -eq $HEALTH_CRITICAL ]; then
        OVERALL_STATUS=$HEALTH_CRITICAL
    fi
}

# 1. Check OpenBao service availability
check_service_availability() {
    log_info "Checking OpenBao service availability..."
    
    if curl -sf --connect-timeout $TIMEOUT "$OPENBAO_ADDR/v1/sys/health" >/dev/null 2>&1; then
        log_ok "OpenBao service is responding"
        update_status $HEALTH_OK
        return $HEALTH_OK
    else
        log_critical "OpenBao service is not responding"
        update_status $HEALTH_CRITICAL
        return $HEALTH_CRITICAL
    fi
}

# 2. Check OpenBao status and seal state
check_seal_status() {
    log_info "Checking OpenBao seal status..."
    
    local status_response
    if status_response=$(curl -sf --connect-timeout $TIMEOUT "$OPENBAO_ADDR/v1/sys/health" 2>/dev/null); then
        local sealed=$(echo "$status_response" | jq -r '.sealed // true')
        local initialized=$(echo "$status_response" | jq -r '.initialized // false')
        
        if [ "$initialized" = "false" ]; then
            log_critical "OpenBao is not initialized"
            update_status $HEALTH_CRITICAL
            return $HEALTH_CRITICAL
        elif [ "$sealed" = "true" ]; then
            log_critical "OpenBao is sealed"
            update_status $HEALTH_CRITICAL
            return $HEALTH_CRITICAL
        else
            log_ok "OpenBao is unsealed and initialized"
            update_status $HEALTH_OK
            return $HEALTH_OK
        fi
    else
        log_critical "Cannot retrieve OpenBao status"
        update_status $HEALTH_CRITICAL
        return $HEALTH_CRITICAL
    fi
}

# 3. Check authentication methods
check_auth_methods() {
    log_info "Checking authentication methods..."
    
    if [ -z "$OPENBAO_TOKEN" ]; then
        # Try to get token from init file
        if [ -f "/opt/openbao/data/init.json" ]; then
            OPENBAO_TOKEN=$(jq -r '.root_token' /opt/openbao/data/init.json 2>/dev/null)
        fi
    fi
    
    if [ -z "$OPENBAO_TOKEN" ]; then
        log_warning "No token available, skipping auth method check"
        update_status $HEALTH_WARNING
        return $HEALTH_WARNING
    fi
    
    local auth_response
    if auth_response=$(curl -sf --connect-timeout $TIMEOUT \
        -H "X-Vault-Token: $OPENBAO_TOKEN" \
        "$OPENBAO_ADDR/v1/sys/auth" 2>/dev/null); then
        
        local auth_count=$(echo "$auth_response" | jq -r '. | length')
        if [ "$auth_count" -gt 0 ]; then
            log_ok "Authentication methods are available ($auth_count methods)"
            update_status $HEALTH_OK
            return $HEALTH_OK
        else
            log_warning "No authentication methods configured"
            update_status $HEALTH_WARNING
            return $HEALTH_WARNING
        fi
    else
        log_warning "Cannot check authentication methods"
        update_status $HEALTH_WARNING
        return $HEALTH_WARNING
    fi
}

# 4. Check secret engines
check_secret_engines() {
    log_info "Checking secret engines..."
    
    if [ -z "$OPENBAO_TOKEN" ]; then
        log_warning "No token available, skipping secret engine check"
        update_status $HEALTH_WARNING
        return $HEALTH_WARNING
    fi
    
    local secrets_response
    if secrets_response=$(curl -sf --connect-timeout $TIMEOUT \
        -H "X-Vault-Token: $OPENBAO_TOKEN" \
        "$OPENBAO_ADDR/v1/sys/mounts" 2>/dev/null); then
        
        local engines_count=$(echo "$secrets_response" | jq -r '. | length')
        if [ "$engines_count" -gt 0 ]; then
            log_ok "Secret engines are available ($engines_count engines)"
            update_status $HEALTH_OK
            return $HEALTH_OK
        else
            log_warning "No secret engines configured"
            update_status $HEALTH_WARNING
            return $HEALTH_WARNING
        fi
    else
        log_warning "Cannot check secret engines"
        update_status $HEALTH_WARNING
        return $HEALTH_WARNING
    fi
}

# 5. Check database connectivity
check_database_connectivity() {
    log_info "Checking database connectivity..."
    
    if [ -z "$POSTGRES_URL" ]; then
        log_info "POSTGRES_URL not set, skipping database check"
        return $HEALTH_OK
    fi
    
    # Extract connection details
    local db_host=$(echo $POSTGRES_URL | sed -n 's/.*@\([^:]*\):.*/\1/p')
    local db_port=$(echo $POSTGRES_URL | sed -n 's/.*:\([0-9]*\)\/.*/\1/p')
    
    if [ -z "$db_host" ] || [ -z "$db_port" ]; then
        log_warning "Cannot parse database connection details"
        update_status $HEALTH_WARNING
        return $HEALTH_WARNING
    fi
    
    if nc -z -w$TIMEOUT "$db_host" "$db_port" 2>/dev/null; then
        log_ok "Database connectivity successful"
        update_status $HEALTH_OK
        return $HEALTH_OK
    else
        log_critical "Database is not reachable"
        update_status $HEALTH_CRITICAL
        return $HEALTH_CRITICAL
    fi
}

# 6. Check disk usage
check_disk_usage() {
    log_info "Checking disk usage..."
    
    local usage=$(df /opt/openbao/data | awk 'NR==2 {print int($5)}')
    
    if [ -z "$usage" ]; then
        log_warning "Cannot determine disk usage"
        update_status $HEALTH_WARNING
        return $HEALTH_WARNING
    fi
    
    if [ "$usage" -ge "$CRITICAL_THRESHOLD" ]; then
        log_critical "Disk usage critical: ${usage}%"
        update_status $HEALTH_CRITICAL
        return $HEALTH_CRITICAL
    elif [ "$usage" -ge "$WARNING_THRESHOLD" ]; then
        log_warning "Disk usage high: ${usage}%"
        update_status $HEALTH_WARNING
        return $HEALTH_WARNING
    else
        log_ok "Disk usage normal: ${usage}%"
        update_status $HEALTH_OK
        return $HEALTH_OK
    fi
}

# 7. Check memory usage
check_memory_usage() {
    log_info "Checking memory usage..."
    
    if command -v free >/dev/null 2>&1; then
        local mem_usage=$(free | awk 'NR==2{printf "%.0f", $3*100/$2}')
        
        if [ "$mem_usage" -ge "$CRITICAL_THRESHOLD" ]; then
            log_critical "Memory usage critical: ${mem_usage}%"
            update_status $HEALTH_CRITICAL
            return $HEALTH_CRITICAL
        elif [ "$mem_usage" -ge "$WARNING_THRESHOLD" ]; then
            log_warning "Memory usage high: ${mem_usage}%"
            update_status $HEALTH_WARNING
            return $HEALTH_WARNING
        else
            log_ok "Memory usage normal: ${mem_usage}%"
            update_status $HEALTH_OK
            return $HEALTH_OK
        fi
    else
        log_info "Memory check not available"
        return $HEALTH_OK
    fi
}

# 8. Check OpenBao process
check_process() {
    log_info "Checking OpenBao process..."
    
    if pgrep -f "openbao server" >/dev/null 2>&1; then
        log_ok "OpenBao process is running"
        update_status $HEALTH_OK
        return $HEALTH_OK
    else
        log_critical "OpenBao process is not running"
        update_status $HEALTH_CRITICAL
        return $HEALTH_CRITICAL
    fi
}

# 9. Check audit logging
check_audit_logging() {
    log_info "Checking audit logging..."
    
    if [ -f "$OPENBAO_AUDIT_FILE" ]; then
        # Check if audit file is being written to (modified in last 5 minutes)
        local last_modified=$(stat -c %Y "$OPENBAO_AUDIT_FILE" 2>/dev/null || echo 0)
        local current_time=$(date +%s)
        local time_diff=$((current_time - last_modified))
        
        if [ $time_diff -lt 300 ]; then  # 5 minutes
            log_ok "Audit logging is active"
            update_status $HEALTH_OK
            return $HEALTH_OK
        else
            log_warning "Audit log not recently updated"
            update_status $HEALTH_WARNING
            return $HEALTH_WARNING
        fi
    else
        log_warning "Audit log file not found"
        update_status $HEALTH_WARNING
        return $HEALTH_WARNING
    fi
}

# 10. Check GCP KMS access (if configured)
check_gcp_kms() {
    log_info "Checking GCP KMS access..."
    
    if [ "$OPENBAO_SEAL_TYPE" != "gcpckms" ]; then
        log_info "GCP KMS not configured, skipping check"
        return $HEALTH_OK
    fi
    
    if [ -z "$GCP_KMS_PROJECT" ]; then
        log_warning "GCP_KMS_PROJECT not set"
        update_status $HEALTH_WARNING
        return $HEALTH_WARNING
    fi
    
    if [ ! -f "$GOOGLE_APPLICATION_CREDENTIALS" ]; then
        log_critical "GCP service account key file not found"
        update_status $HEALTH_CRITICAL
        return $HEALTH_CRITICAL
    fi
    
    log_ok "GCP KMS configuration appears valid"
    update_status $HEALTH_OK
    return $HEALTH_OK
}

# 11. Check certificate validity (if TLS enabled)
check_certificates() {
    log_info "Checking TLS certificates..."
    
    if [ ! -f "$OPENBAO_TLS_CERT_FILE" ]; then
        log_info "TLS not configured, skipping certificate check"
        return $HEALTH_OK
    fi
    
    if command -v openssl >/dev/null 2>&1; then
        local cert_expiry=$(openssl x509 -in "$OPENBAO_TLS_CERT_FILE" -noout -enddate 2>/dev/null | cut -d= -f2)
        local expiry_timestamp=$(date -d "$cert_expiry" +%s 2>/dev/null)
        local current_timestamp=$(date +%s)
        local days_until_expiry=$(( (expiry_timestamp - current_timestamp) / 86400 ))
        
        if [ $days_until_expiry -lt 0 ]; then
            log_critical "TLS certificate has expired"
            update_status $HEALTH_CRITICAL
            return $HEALTH_CRITICAL
        elif [ $days_until_expiry -lt 30 ]; then
            log_warning "TLS certificate expires in $days_until_expiry days"
            update_status $HEALTH_WARNING
            return $HEALTH_WARNING
        else
            log_ok "TLS certificate valid for $days_until_expiry days"
            update_status $HEALTH_OK
            return $HEALTH_OK
        fi
    else
        log_info "OpenSSL not available, skipping certificate validation"
        return $HEALTH_OK
    fi
}

# 12. Check log file sizes
check_log_sizes() {
    log_info "Checking log file sizes..."
    
    local log_files=("$OPENBAO_LOG_FILE" "$OPENBAO_AUDIT_FILE" "/var/log/openbao/openbao.log")
    local max_size_mb=100
    local warning_size_mb=50
    
    for log_file in "${log_files[@]}"; do
        if [ -f "$log_file" ]; then
            local size_mb=$(du -m "$log_file" | cut -f1)
            
            if [ "$size_mb" -gt "$max_size_mb" ]; then
                log_warning "Log file $log_file is large: ${size_mb}MB"
                update_status $HEALTH_WARNING
            fi
        fi
    done
    
    log_ok "Log file sizes within acceptable limits"
    update_status $HEALTH_OK
    return $HEALTH_OK
}

# Main health check function
main() {
    echo "OpenBao Health Check - $(date)"
    echo "=================================="
    
    # Run all health checks
    check_service_availability
    check_seal_status
    check_auth_methods
    check_secret_engines
    check_database_connectivity
    check_disk_usage
    check_memory_usage
    check_process
    check_audit_logging
    check_gcp_kms
    check_certificates
    check_log_sizes
    
    # Summary
    echo "=================================="
    echo "Health Check Summary:"
    echo "Checks passed: $CHECKS_PASSED/$CHECKS_TOTAL"
    
    case $OVERALL_STATUS in
        $HEALTH_OK)
            log_ok "Overall status: HEALTHY"
            ;;
        $HEALTH_WARNING)
            log_warning "Overall status: WARNING"
            ;;
        $HEALTH_CRITICAL)
            log_critical "Overall status: CRITICAL"
            ;;
    esac
    
    exit $OVERALL_STATUS
}

# Run health check
main "$@"
