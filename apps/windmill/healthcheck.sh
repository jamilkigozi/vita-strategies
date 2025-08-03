#!/bin/bash
# Windmill Health Check Script
# Comprehensive health monitoring for workflow automation platform

set -euo pipefail

# Configuration
readonly HEALTH_CHECK_URL="http://localhost:8000/api/version"
readonly WORKER_HEALTH_URL="http://localhost:8000/api/w/admin/workers"
readonly METRICS_URL="http://localhost:8001/metrics"
readonly DB_CHECK_TIMEOUT=5
readonly REDIS_CHECK_TIMEOUT=3
readonly DISK_THRESHOLD=85
readonly MEMORY_THRESHOLD=85
readonly LOG_FILE="/var/log/windmill/healthcheck.log"

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

# Check Windmill server
check_windmill_server() {
    log_health "INFO" "Checking Windmill server..."
    
    local response_code
    if response_code=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 "$HEALTH_CHECK_URL" 2>/dev/null); then
        if [[ "$response_code" == "200" ]]; then
            log_health "INFO" "Windmill server is healthy (HTTP $response_code)"
            return 0
        else
            log_health "ERROR" "Windmill server returned HTTP $response_code"
            return 1
        fi
    else
        log_health "ERROR" "Windmill server is not responding"
        return 1
    fi
}

# Check worker processes
check_workers() {
    log_health "INFO" "Checking Windmill workers..."
    
    local worker_response
    if worker_response=$(curl -s --max-time 10 "$WORKER_HEALTH_URL" 2>/dev/null); then
        local worker_count
        worker_count=$(echo "$worker_response" | jq -r '. | length' 2>/dev/null || echo "0")
        
        if [[ "$worker_count" -gt 0 ]]; then
            log_health "INFO" "Windmill workers are healthy ($worker_count active)"
            return 0
        else
            log_health "ERROR" "No active Windmill workers found"
            return 1
        fi
    else
        log_health "ERROR" "Unable to check worker status"
        return 1
    fi
}

# Check database connectivity
check_database() {
    log_health "INFO" "Checking database connectivity..."
    
    if [[ -z "${DATABASE_URL:-}" ]]; then
        log_health "WARN" "DATABASE_URL not configured, skipping database check"
        return 0
    fi
    
    # Extract database connection details
    if [[ "$DATABASE_URL" =~ postgresql://([^:]+):([^@]+)@([^:]+):([0-9]+)/(.+) ]]; then
        local db_user="${BASH_REMATCH[1]}"
        local db_password="${BASH_REMATCH[2]}"
        local db_host="${BASH_REMATCH[3]}"
        local db_port="${BASH_REMATCH[4]}"
        local db_name="${BASH_REMATCH[5]}"
        
        if timeout "$DB_CHECK_TIMEOUT" PGPASSWORD="$db_password" pg_isready \
            -h "$db_host" -p "$db_port" -U "$db_user" -d "$db_name" >/dev/null 2>&1; then
            log_health "INFO" "Database connectivity is healthy"
            return 0
        else
            log_health "ERROR" "Database connectivity failed"
            return 1
        fi
    else
        log_health "ERROR" "Invalid DATABASE_URL format"
        return 1
    fi
}

# Check Redis connectivity
check_redis() {
    log_health "INFO" "Checking Redis connectivity..."
    
    local redis_url="${REDIS_URL:-redis://localhost:6379}"
    local redis_host
    local redis_port
    
    # Extract host and port from Redis URL
    redis_host=$(echo "$redis_url" | sed 's/redis:\/\/\([^:]*\).*/\1/')
    redis_port=$(echo "$redis_url" | sed 's/.*:\([0-9]*\).*/\1/')
    
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
    disk_usage=$(df /opt/windmill | awk 'NR==2 {print $5}' | sed 's/%//')
    
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
        "windmill.*server"
        "windmill.*worker"
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

# Check workflow execution capacity
check_workflow_capacity() {
    log_health "INFO" "Checking workflow execution capacity..."
    
    # Check if metrics endpoint is available
    if curl -s --max-time 5 "$METRICS_URL" >/dev/null 2>&1; then
        local queue_length
        queue_length=$(curl -s --max-time 5 "$METRICS_URL" | grep "windmill_queue_length" | awk '{print $2}' | head -1 || echo "0")
        
        if [[ "$queue_length" -lt 100 ]]; then
            log_health "INFO" "Workflow queue is healthy ($queue_length jobs queued)"
            return 0
        else
            log_health "WARN" "Workflow queue is growing ($queue_length jobs queued)"
            return 1
        fi
    else
        log_health "WARN" "Metrics endpoint not available, skipping queue check"
        return 0
    fi
}

# Check file system permissions
check_permissions() {
    log_health "INFO" "Checking file system permissions..."
    
    local critical_paths=(
        "/opt/windmill"
        "/var/log/windmill"
        "/opt/windmill/data"
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
    
    local log_dir="/var/log/windmill"
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

# Check workflow execution history
check_execution_history() {
    log_health "INFO" "Checking recent workflow executions..."
    
    # This would typically query the database for recent job executions
    # For now, we'll just check if the database connection works
    if check_database >/dev/null 2>&1; then
        log_health "INFO" "Workflow execution history is accessible"
        return 0
    else
        log_health "ERROR" "Cannot access workflow execution history"
        return 1
    fi
}

# Generate health report
generate_health_report() {
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local uptime=$(uptime | awk '{print $3,$4}' | sed 's/,//')
    local load_avg=$(uptime | awk -F'load average:' '{print $2}')
    
    cat << EOF

=====================================
Windmill Health Check Report
=====================================
Timestamp: $timestamp
Uptime: $uptime
Load Average: $load_avg
Container: $(hostname)
Workers: ${NUM_WORKERS:-4}
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
        "check_windmill_server"
        "check_workers"
        "check_database"
        "check_redis"
        "check_disk_space"
        "check_memory"
        "check_processes"
        "check_workflow_capacity"
        "check_permissions"
        "check_log_sizes"
        "check_execution_history"
    )
    
    local failed_checks=()
    
    # Run all health checks
    for check in "${health_checks[@]}"; do
        if ! "$check"; then
            failed_checks+=("$check")
        fi
    done
    
    # Determine overall health status
    if [[ ${#failed_checks[@]} -eq 0 ]]; then
        log_health "INFO" "All health checks passed - Windmill is healthy"
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
