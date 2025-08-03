#!/bin/bash
# ERPNext Health Check Script
# Comprehensive health monitoring for production deployment

set -euo pipefail

# Configuration
readonly HEALTH_CHECK_URL="http://localhost:8000/api/method/ping"
readonly DB_CHECK_TIMEOUT=5
readonly REDIS_CHECK_TIMEOUT=3
readonly DISK_THRESHOLD=90
readonly MEMORY_THRESHOLD=90
readonly LOG_FILE="/var/log/erpnext/healthcheck.log"

# Color codes for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly NC='\033[0m'

# Logging function
log_health() {
    local level="$1"
    shift
    local message="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    case "$level" in
        "INFO")  echo -e "${GREEN}[HEALTH-INFO]${NC} $timestamp - $message" | tee -a "$LOG_FILE" ;;
        "WARN")  echo -e "${YELLOW}[HEALTH-WARN]${NC} $timestamp - $message" | tee -a "$LOG_FILE" ;;
        "ERROR") echo -e "${RED}[HEALTH-ERROR]${NC} $timestamp - $message" | tee -a "$LOG_FILE" ;;
        *)       echo "[HEALTH] $timestamp - $message" | tee -a "$LOG_FILE" ;;
    esac
}

# Check ERPNext web application
check_web_application() {
    log_health "INFO" "Checking ERPNext web application..."
    
    local response_code
    if response_code=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 "$HEALTH_CHECK_URL" 2>/dev/null); then
        if [[ "$response_code" == "200" ]]; then
            log_health "INFO" "Web application is healthy (HTTP $response_code)"
            return 0
        else
            log_health "ERROR" "Web application returned HTTP $response_code"
            return 1
        fi
    else
        log_health "ERROR" "Web application is not responding"
        return 1
    fi
}

# Check database connectivity
check_database() {
    log_health "INFO" "Checking database connectivity..."
    
    if [[ -z "${DB_HOST:-}" ]] || [[ -z "${DB_USER:-}" ]] || [[ -z "${DB_PASSWORD:-}" ]]; then
        log_health "WARN" "Database credentials not configured, skipping database check"
        return 0
    fi
    
    if timeout "$DB_CHECK_TIMEOUT" mysqladmin ping \
        -h"$DB_HOST" \
        -P"${DB_PORT:-3306}" \
        -u"$DB_USER" \
        -p"$DB_PASSWORD" \
        --silent >/dev/null 2>&1; then
        log_health "INFO" "Database connectivity is healthy"
        return 0
    else
        log_health "ERROR" "Database connectivity failed"
        return 1
    fi
}

# Check Redis connectivity
check_redis() {
    log_health "INFO" "Checking Redis connectivity..."
    
    local redis_cache="${REDIS_CACHE:-redis://localhost:6379/0}"
    local redis_host
    local redis_port
    
    # Extract host and port from Redis URL
    redis_host=$(echo "$redis_cache" | sed 's/redis:\/\/\([^:]*\).*/\1/')
    redis_port=$(echo "$redis_cache" | sed 's/.*:\([0-9]*\).*/\1/')
    
    if timeout "$REDIS_CHECK_TIMEOUT" redis-cli \
        -h "$redis_host" \
        -p "$redis_port" \
        ping >/dev/null 2>&1; then
        log_health "INFO" "Redis connectivity is healthy"
        return 0
    else
        log_health "ERROR" "Redis connectivity failed"
        return 1
    fi
}

# Check disk space
check_disk_space() {
    log_health "INFO" "Checking disk space..."
    
    local disk_usage
    disk_usage=$(df /home/frappe | awk 'NR==2 {print $5}' | sed 's/%//')
    
    if [[ "$disk_usage" -lt "$DISK_THRESHOLD" ]]; then
        log_health "INFO" "Disk space is healthy ($disk_usage% used)"
        return 0
    else
        log_health "WARN" "Disk space is running low ($disk_usage% used, threshold: $DISK_THRESHOLD%)"
        return 1
    fi
}

# Check memory usage
check_memory() {
    log_health "INFO" "Checking memory usage..."
    
    local memory_usage
    memory_usage=$(free | awk 'NR==2{printf "%.0f", $3*100/$2}')
    
    if [[ "$memory_usage" -lt "$MEMORY_THRESHOLD" ]]; then
        log_health "INFO" "Memory usage is healthy ($memory_usage% used)"
        return 0
    else
        log_health "WARN" "Memory usage is high ($memory_usage% used, threshold: $MEMORY_THRESHOLD%)"
        return 1
    fi
}

# Check critical processes
check_processes() {
    log_health "INFO" "Checking critical processes..."
    
    local critical_processes=(
        "gunicorn"
        "python.*worker"
        "python.*schedule"
    )
    
    local failed_processes=()
    
    for process in "${critical_processes[@]}"; do
        if ! pgrep -f "$process" >/dev/null; then
            failed_processes+=("$process")
        fi
    done
    
    if [[ ${#failed_processes[@]} -eq 0 ]]; then
        log_health "INFO" "All critical processes are running"
        return 0
    else
        log_health "ERROR" "Critical processes not running: ${failed_processes[*]}"
        return 1
    fi
}

# Check file system permissions
check_permissions() {
    log_health "INFO" "Checking file system permissions..."
    
    local critical_paths=(
        "/home/frappe/frappe-bench/sites"
        "/var/log/erpnext"
        "/home/frappe/frappe-bench/sites/$SITE_NAME"
    )
    
    local permission_errors=()
    
    for path in "${critical_paths[@]}"; do
        if [[ -d "$path" ]]; then
            if [[ ! -r "$path" ]] || [[ ! -w "$path" ]]; then
                permission_errors+=("$path")
            fi
        fi
    done
    
    if [[ ${#permission_errors[@]} -eq 0 ]]; then
        log_health "INFO" "File system permissions are correct"
        return 0
    else
        log_health "ERROR" "Permission errors found: ${permission_errors[*]}"
        return 1
    fi
}

# Check log file sizes
check_log_sizes() {
    log_health "INFO" "Checking log file sizes..."
    
    local log_dir="/var/log/erpnext"
    local max_log_size=$((100 * 1024 * 1024)) # 100MB
    local large_logs=()
    
    if [[ -d "$log_dir" ]]; then
        while IFS= read -r -d '' log_file; do
            local file_size
            file_size=$(stat -f%z "$log_file" 2>/dev/null || stat -c%s "$log_file" 2>/dev/null || echo 0)
            
            if [[ "$file_size" -gt "$max_log_size" ]]; then
                large_logs+=("$(basename "$log_file")")
            fi
        done < <(find "$log_dir" -name "*.log" -print0 2>/dev/null || true)
    fi
    
    if [[ ${#large_logs[@]} -eq 0 ]]; then
        log_health "INFO" "Log file sizes are within limits"
        return 0
    else
        log_health "WARN" "Large log files detected: ${large_logs[*]}"
        return 1
    fi
}

# Check ERPNext site status
check_site_status() {
    log_health "INFO" "Checking ERPNext site status..."
    
    if [[ -z "${SITE_NAME:-}" ]]; then
        log_health "WARN" "SITE_NAME not configured, skipping site status check"
        return 0
    fi
    
    local site_path="/home/frappe/frappe-bench/sites/$SITE_NAME"
    
    if [[ ! -d "$site_path" ]]; then
        log_health "ERROR" "Site directory does not exist: $site_path"
        return 1
    fi
    
    if [[ ! -f "$site_path/site_config.json" ]]; then
        log_health "ERROR" "Site configuration file missing: $site_path/site_config.json"
        return 1
    fi
    
    log_health "INFO" "ERPNext site status is healthy"
    return 0
}

# Generate health report
generate_health_report() {
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local uptime=$(uptime | awk '{print $3,$4}' | sed 's/,//')
    local load_avg=$(uptime | awk -F'load average:' '{print $2}')
    
    cat << EOF

=====================================
ERPNext Health Check Report
=====================================
Timestamp: $timestamp
Uptime: $uptime
Load Average: $load_avg
Container: $(hostname)
Site: ${SITE_NAME:-"Not configured"}
=====================================

EOF
}

# Main health check execution
main() {
    # Create log directory if it doesn't exist
    mkdir -p "$(dirname "$LOG_FILE")"
    
    # Generate health report header
    generate_health_report | tee -a "$LOG_FILE"
    
    # Track overall health status
    local health_checks=(
        "check_web_application"
        "check_database" 
        "check_redis"
        "check_disk_space"
        "check_memory"
        "check_processes"
        "check_permissions"
        "check_log_sizes"
        "check_site_status"
    )
    
    local failed_checks=()
    local warning_checks=()
    
    # Run all health checks
    for check in "${health_checks[@]}"; do
        if ! "$check"; then
            failed_checks+=("$check")
        fi
    done
    
    # Determine overall health status
    if [[ ${#failed_checks[@]} -eq 0 ]]; then
        log_health "INFO" "All health checks passed - ERPNext is healthy"
        echo "HEALTHY" > /tmp/health_status
        exit 0
    else
        log_health "ERROR" "Health check failures: ${failed_checks[*]}"
        echo "UNHEALTHY" > /tmp/health_status
        exit 1
    fi
}

# Execute main function
main "$@"
