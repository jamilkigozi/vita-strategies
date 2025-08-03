#!/bin/bash

# Keycloak Health Check Script
# Comprehensive monitoring for identity and access management platform

# Exit codes
HEALTH_OK=0
HEALTH_WARNING=1
HEALTH_CRITICAL=2

# Configuration
KEYCLOAK_URL=${KC_HOSTNAME:-"http://127.0.0.1:8080"}
TIMEOUT=${HEALTH_CHECK_TIMEOUT:-15}
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

# 1. Check Keycloak service availability
check_service_availability() {
    log_info "Checking Keycloak service availability..."
    
    if curl -sf --connect-timeout $TIMEOUT "http://127.0.0.1:8080/health" >/dev/null 2>&1; then
        log_ok "Keycloak service is responding"
        update_status $HEALTH_OK
        return $HEALTH_OK
    else
        log_critical "Keycloak service is not responding"
        update_status $HEALTH_CRITICAL
        return $HEALTH_CRITICAL
    fi
}

# 2. Check Keycloak readiness
check_readiness() {
    log_info "Checking Keycloak readiness..."
    
    local ready_response
    if ready_response=$(curl -sf --connect-timeout $TIMEOUT "http://127.0.0.1:8080/health/ready" 2>/dev/null); then
        local status=$(echo "$ready_response" | jq -r '.status // "DOWN"' 2>/dev/null || echo "DOWN")
        
        if [ "$status" = "UP" ]; then
            log_ok "Keycloak is ready"
            update_status $HEALTH_OK
            return $HEALTH_OK
        else
            log_critical "Keycloak is not ready: $status"
            update_status $HEALTH_CRITICAL
            return $HEALTH_CRITICAL
        fi
    else
        log_critical "Cannot retrieve Keycloak readiness status"
        update_status $HEALTH_CRITICAL
        return $HEALTH_CRITICAL
    fi
}

# 3. Check Keycloak liveness
check_liveness() {
    log_info "Checking Keycloak liveness..."
    
    local live_response
    if live_response=$(curl -sf --connect-timeout $TIMEOUT "http://127.0.0.1:8080/health/live" 2>/dev/null); then
        local status=$(echo "$live_response" | jq -r '.status // "DOWN"' 2>/dev/null || echo "DOWN")
        
        if [ "$status" = "UP" ]; then
            log_ok "Keycloak is live"
            update_status $HEALTH_OK
            return $HEALTH_OK
        else
            log_critical "Keycloak liveness check failed: $status"
            update_status $HEALTH_CRITICAL
            return $HEALTH_CRITICAL
        fi
    else
        log_critical "Cannot retrieve Keycloak liveness status"
        update_status $HEALTH_CRITICAL
        return $HEALTH_CRITICAL
    fi
}

# 4. Check database connectivity
check_database_connectivity() {
    log_info "Checking database connectivity..."
    
    local db_host=${KC_DB_URL_HOST:-postgres}
    local db_port=${KC_DB_URL_PORT:-5432}
    local db_name=${KC_DB_URL_DATABASE:-keycloak}
    local db_user=${KC_DB_USERNAME:-keycloak_user}
    
    if [ -z "$KC_DB_PASSWORD" ]; then
        log_warning "KC_DB_PASSWORD not set, skipping database connectivity check"
        update_status $HEALTH_WARNING
        return $HEALTH_WARNING
    fi
    
    if nc -z -w$TIMEOUT "$db_host" "$db_port" 2>/dev/null; then
        # Test actual database connection
        if PGPASSWORD="$KC_DB_PASSWORD" psql -h "$db_host" -p "$db_port" -U "$db_user" -d "$db_name" -c "SELECT 1;" >/dev/null 2>&1; then
            log_ok "Database connectivity successful"
            update_status $HEALTH_OK
            return $HEALTH_OK
        else
            log_critical "Database connection failed (authentication/permissions)"
            update_status $HEALTH_CRITICAL
            return $HEALTH_CRITICAL
        fi
    else
        log_critical "Database is not reachable"
        update_status $HEALTH_CRITICAL
        return $HEALTH_CRITICAL
    fi
}

# 5. Check realms accessibility
check_realms() {
    log_info "Checking realms accessibility..."
    
    # Check master realm
    if curl -sf --connect-timeout $TIMEOUT "http://127.0.0.1:8080/realms/master" >/dev/null 2>&1; then
        log_ok "Master realm is accessible"
        update_status $HEALTH_OK
        return $HEALTH_OK
    else
        log_critical "Master realm is not accessible"
        update_status $HEALTH_CRITICAL
        return $HEALTH_CRITICAL
    fi
}

# 6. Check admin console availability
check_admin_console() {
    log_info "Checking admin console availability..."
    
    if curl -sf --connect-timeout $TIMEOUT "http://127.0.0.1:8080/admin/" >/dev/null 2>&1; then
        log_ok "Admin console is accessible"
        update_status $HEALTH_OK
        return $HEALTH_OK
    else
        log_warning "Admin console is not accessible"
        update_status $HEALTH_WARNING
        return $HEALTH_WARNING
    fi
}

# 7. Check disk usage
check_disk_usage() {
    log_info "Checking disk usage..."
    
    local usage=$(df /opt/keycloak | awk 'NR==2 {print int($5)}')
    
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

# 8. Check memory usage
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

# 9. Check JVM heap usage
check_jvm_heap() {
    log_info "Checking JVM heap usage..."
    
    # Get JVM metrics from Keycloak metrics endpoint
    local metrics_response
    if metrics_response=$(curl -sf --connect-timeout $TIMEOUT "http://127.0.0.1:9000/metrics" 2>/dev/null); then
        local heap_used=$(echo "$metrics_response" | grep "jvm_memory_used_bytes.*heap" | head -1 | awk '{print $2}')
        local heap_max=$(echo "$metrics_response" | grep "jvm_memory_max_bytes.*heap" | head -1 | awk '{print $2}')
        
        if [ -n "$heap_used" ] && [ -n "$heap_max" ] && [ "$heap_max" -gt 0 ]; then
            local heap_usage=$((heap_used * 100 / heap_max))
            
            if [ "$heap_usage" -ge "$CRITICAL_THRESHOLD" ]; then
                log_critical "JVM heap usage critical: ${heap_usage}%"
                update_status $HEALTH_CRITICAL
                return $HEALTH_CRITICAL
            elif [ "$heap_usage" -ge "$WARNING_THRESHOLD" ]; then
                log_warning "JVM heap usage high: ${heap_usage}%"
                update_status $HEALTH_WARNING
                return $HEALTH_WARNING
            else
                log_ok "JVM heap usage normal: ${heap_usage}%"
                update_status $HEALTH_OK
                return $HEALTH_OK
            fi
        else
            log_info "JVM heap metrics not available"
            return $HEALTH_OK
        fi
    else
        log_info "JVM metrics endpoint not accessible"
        return $HEALTH_OK
    fi
}

# 10. Check Keycloak process
check_process() {
    log_info "Checking Keycloak process..."
    
    if pgrep -f "org.keycloak.quarkus._private.Main" >/dev/null 2>&1; then
        log_ok "Keycloak process is running"
        update_status $HEALTH_OK
        return $HEALTH_OK
    else
        log_critical "Keycloak process is not running"
        update_status $HEALTH_CRITICAL
        return $HEALTH_CRITICAL
    fi
}

# 11. Check clustering status (if clustered)
check_clustering() {
    log_info "Checking clustering status..."
    
    # Check if clustering is enabled
    if [ "$KC_CACHE" = "ispn" ]; then
        # Try to get cluster information from metrics
        local metrics_response
        if metrics_response=$(curl -sf --connect-timeout $TIMEOUT "http://127.0.0.1:9000/metrics" 2>/dev/null); then
            local cluster_members=$(echo "$metrics_response" | grep "vendor_cache_manager_cluster_size" | awk '{print $2}')
            
            if [ -n "$cluster_members" ] && [ "$cluster_members" -gt 0 ]; then
                log_ok "Cluster active with $cluster_members members"
                update_status $HEALTH_OK
                return $HEALTH_OK
            else
                log_warning "Clustering enabled but no cluster information available"
                update_status $HEALTH_WARNING
                return $HEALTH_WARNING
            fi
        else
            log_info "Clustering metrics not available"
            return $HEALTH_OK
        fi
    else
        log_info "Clustering not enabled"
        return $HEALTH_OK
    fi
}

# 12. Check certificate validity (if HTTPS enabled)
check_certificates() {
    log_info "Checking TLS certificates..."
    
    if [ ! -f "$KC_HTTPS_CERTIFICATE_FILE" ]; then
        log_info "HTTPS not configured, skipping certificate check"
        return $HEALTH_OK
    fi
    
    if command -v openssl >/dev/null 2>&1; then
        local cert_expiry=$(openssl x509 -in "$KC_HTTPS_CERTIFICATE_FILE" -noout -enddate 2>/dev/null | cut -d= -f2)
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

# 13. Check log file sizes
check_log_sizes() {
    log_info "Checking log file sizes..."
    
    local log_files=("/var/log/keycloak/keycloak.log" "/opt/keycloak/logs/keycloak.log")
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

# 14. Check vault integration (if configured)
check_vault_integration() {
    log_info "Checking vault integration..."
    
    if [ -z "$KC_SPI_VAULT_HASHICORP_VAULT_URL" ]; then
        log_info "Vault integration not configured"
        return $HEALTH_OK
    fi
    
    if curl -sf --connect-timeout $TIMEOUT "$KC_SPI_VAULT_HASHICORP_VAULT_URL/v1/sys/health" >/dev/null 2>&1; then
        log_ok "Vault integration working"
        update_status $HEALTH_OK
        return $HEALTH_OK
    else
        log_warning "Vault not reachable"
        update_status $HEALTH_WARNING
        return $HEALTH_WARNING
    fi
}

# Main health check function
main() {
    echo "Keycloak Health Check - $(date)"
    echo "===================================="
    
    # Run all health checks
    check_service_availability
    check_readiness
    check_liveness
    check_database_connectivity
    check_realms
    check_admin_console
    check_disk_usage
    check_memory_usage
    check_jvm_heap
    check_process
    check_clustering
    check_certificates
    check_log_sizes
    check_vault_integration
    
    # Summary
    echo "===================================="
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
