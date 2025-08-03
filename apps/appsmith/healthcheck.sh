#!/bin/bash
set -euo pipefail

# Health check script for Appsmith Internal Tools Platform
# Performs comprehensive health validation of Appsmith service

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
APPSMITH_URL="http://localhost"
HEALTH_ENDPOINT="/api/v1/health"
TIMEOUT=10
MAX_RETRIES=3

# Health check functions
check_appsmith_service() {
    local endpoint="$APPSMITH_URL$HEALTH_ENDPOINT"
    
    # Check if Appsmith API responds
    if curl -f -s --max-time $TIMEOUT "$endpoint" > /dev/null 2>&1; then
        echo -e "${GREEN}✓${NC} Appsmith service is responding"
        return 0
    else
        echo -e "${RED}✗${NC} Appsmith service is not responding"
        return 1
    fi
}

check_database_connectivity() {
    # Check database connection through Appsmith API
    local db_check_endpoint="$APPSMITH_URL/api/v1/applications"
    
    if curl -f -s --max-time $TIMEOUT "$db_check_endpoint" > /dev/null 2>&1; then
        echo -e "${GREEN}✓${NC} Database connectivity is healthy"
        return 0
    else
        echo -e "${RED}✗${NC} Database connectivity issue detected"
        return 1
    fi
}

check_memory_usage() {
    # Check memory usage of Appsmith process
    local memory_usage
    memory_usage=$(ps -o pid,ppid,cmd,%mem --sort=-%mem | grep -E "(appsmith|java)" | grep -v grep | awk '{print $4}' | head -1)
    
    if [[ -n "$memory_usage" ]]; then
        local memory_threshold=80
        if (( $(echo "$memory_usage > $memory_threshold" | bc -l) )); then
            echo -e "${YELLOW}⚠${NC} High memory usage: ${memory_usage}%"
            return 1
        else
            echo -e "${GREEN}✓${NC} Memory usage is healthy: ${memory_usage}%"
            return 0
        fi
    else
        echo -e "${RED}✗${NC} Cannot determine memory usage"
        return 1
    fi
}

check_disk_space() {
    # Check disk space for Appsmith data directory
    local data_dir="/appsmith-stacks"
    local disk_usage
    disk_usage=$(df "$data_dir" | awk 'NR==2 {print $(NF-1)}' | sed 's/%//')
    
    local disk_threshold=85
    if [[ "$disk_usage" -gt "$disk_threshold" ]]; then
        echo -e "${YELLOW}⚠${NC} High disk usage: ${disk_usage}%"
        return 1
    else
        echo -e "${GREEN}✓${NC} Disk space is healthy: ${disk_usage}% used"
        return 0
    fi
}

check_process_status() {
    # Check if Appsmith processes are running
    local processes=("supervisord" "nginx" "appsmith")
    local all_running=true
    
    for process in "${processes[@]}"; do
        if pgrep -f "$process" > /dev/null; then
            local pid
            pid=$(pgrep -f "$process" | head -1)
            echo -e "${GREEN}✓${NC} $process is running (PID: $pid)"
        else
            echo -e "${RED}✗${NC} $process is not running"
            all_running=false
        fi
    done
    
    if $all_running; then
        return 0
    else
        return 1
    fi
}

check_log_errors() {
    # Check for recent errors in Appsmith logs
    local log_files=(
        "/var/log/appsmith/application.log"
        "/var/log/appsmith/error.log"
    )
    local error_count=0
    
    for log_file in "${log_files[@]}"; do
        if [[ -f "$log_file" ]]; then
            # Count errors in the last 100 lines
            local file_errors
            file_errors=$(tail -100 "$log_file" 2>/dev/null | grep -i "error\|exception\|fatal" | wc -l || echo "0")
            error_count=$((error_count + file_errors))
        fi
    done
    
    if [[ "$error_count" -gt 5 ]]; then
        echo -e "${YELLOW}⚠${NC} Recent errors detected in logs: $error_count errors"
        return 1
    else
        echo -e "${GREEN}✓${NC} No significant errors in recent logs"
        return 0
    fi
}

check_redis_connectivity() {
    # Check Redis connectivity if configured
    if [[ -n "${APPSMITH_REDIS_URL:-}" ]]; then
        # Extract Redis connection details
        local redis_url="${APPSMITH_REDIS_URL}"
        local redis_host=$(echo "$redis_url" | sed 's|redis://||' | cut -d':' -f1)
        local redis_port=$(echo "$redis_url" | sed 's|redis://||' | cut -d':' -f2)
        
        if [[ "$redis_port" == "$redis_host" ]]; then
            redis_port="6379"
        fi
        
        if redis-cli -h "$redis_host" -p "$redis_port" ping > /dev/null 2>&1; then
            echo -e "${GREEN}✓${NC} Redis cache is accessible"
            return 0
        else
            echo -e "${RED}✗${NC} Redis cache is not accessible"
            return 1
        fi
    else
        echo -e "${GREEN}✓${NC} Redis not configured (using default session storage)"
        return 0
    fi
}

check_ssl_certificate() {
    # Check SSL certificate if HTTPS is enabled
    if [[ -n "${APPSMITH_CUSTOM_DOMAIN:-}" ]] && [[ "${APPSMITH_FORCE_SSL:-false}" == "true" ]]; then
        local domain="${APPSMITH_CUSTOM_DOMAIN}"
        
        # Check certificate expiration
        if command -v openssl > /dev/null; then
            local cert_info
            cert_info=$(echo | timeout 5 openssl s_client -servername "$domain" -connect "$domain:443" 2>/dev/null | openssl x509 -noout -dates 2>/dev/null)
            
            if [[ -n "$cert_info" ]]; then
                local expiry_date
                expiry_date=$(echo "$cert_info" | grep "notAfter" | cut -d'=' -f2)
                local expiry_timestamp
                expiry_timestamp=$(date -d "$expiry_date" +%s 2>/dev/null || echo "0")
                local current_timestamp
                current_timestamp=$(date +%s)
                local days_until_expiry
                days_until_expiry=$(( (expiry_timestamp - current_timestamp) / 86400 ))
                
                if [[ "$days_until_expiry" -lt 30 ]]; then
                    echo -e "${YELLOW}⚠${NC} SSL certificate expires in $days_until_expiry days"
                    return 1
                else
                    echo -e "${GREEN}✓${NC} SSL certificate is valid ($days_until_expiry days remaining)"
                    return 0
                fi
            else
                echo -e "${RED}✗${NC} Could not verify SSL certificate"
                return 1
            fi
        else
            echo -e "${YELLOW}⚠${NC} OpenSSL not available for certificate check"
            return 1
        fi
    else
        echo -e "${GREEN}✓${NC} SSL not configured or disabled"
        return 0
    fi
}

check_application_count() {
    # Check if applications can be loaded
    local apps_endpoint="$APPSMITH_URL/api/v1/applications"
    
    if curl -f -s --max-time $TIMEOUT "$apps_endpoint" > /dev/null 2>&1; then
        echo -e "${GREEN}✓${NC} Applications endpoint is accessible"
        return 0
    else
        echo -e "${RED}✗${NC} Applications endpoint is not accessible"
        return 1
    fi
}

# Main health check function
perform_health_check() {
    local checks_passed=0
    local total_checks=9
    local exit_code=0
    
    echo "=== Appsmith Health Check ==="
    echo "Timestamp: $(date '+%Y-%m-%d %H:%M:%S')"
    echo ""
    
    # Perform all health checks
    if check_appsmith_service; then ((checks_passed++)); else exit_code=1; fi
    if check_database_connectivity; then ((checks_passed++)); else exit_code=1; fi
    if check_memory_usage; then ((checks_passed++)); else exit_code=1; fi
    if check_disk_space; then ((checks_passed++)); else exit_code=1; fi
    if check_process_status; then ((checks_passed++)); else exit_code=1; fi
    if check_log_errors; then ((checks_passed++)); else exit_code=1; fi
    if check_redis_connectivity; then ((checks_passed++)); else exit_code=1; fi
    if check_ssl_certificate; then ((checks_passed++)); else exit_code=1; fi
    if check_application_count; then ((checks_passed++)); else exit_code=1; fi
    
    echo ""
    echo "=== Health Check Summary ==="
    
    if [[ $checks_passed -eq $total_checks ]]; then
        echo -e "${GREEN}✓ All health checks passed ($checks_passed/$total_checks)${NC}"
        echo "Status: HEALTHY"
    elif [[ $checks_passed -ge $((total_checks * 75 / 100)) ]]; then
        echo -e "${YELLOW}⚠ Some health checks failed ($checks_passed/$total_checks)${NC}"
        echo "Status: DEGRADED"
        exit_code=1
    else
        echo -e "${RED}✗ Multiple health checks failed ($checks_passed/$total_checks)${NC}"
        echo "Status: UNHEALTHY"
        exit_code=2
    fi
    
    echo "=========================="
    return $exit_code
}

# Quick health check for Docker health check
quick_health_check() {
    # Basic service check for Docker health check
    if curl -f -s --max-time 5 "$APPSMITH_URL$HEALTH_ENDPOINT" > /dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

# Enhanced logging for health check results
log_health_check() {
    local log_file="/var/log/appsmith/health-check.log"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    # Create log directory if it doesn't exist
    mkdir -p "$(dirname "$log_file")"
    
    # Perform health check and capture output
    local health_output
    health_output=$(perform_health_check 2>&1)
    local health_exit_code=$?
    
    # Log the results
    {
        echo "[$timestamp] Health check performed"
        echo "$health_output"
        echo "[$timestamp] Health check exit code: $health_exit_code"
        echo "----------------------------------------"
    } >> "$log_file"
    
    return $health_exit_code
}

# Main script logic
main() {
    case "${1:-full}" in
        "quick")
            # Quick health check for Docker
            quick_health_check
            ;;
        "log")
            # Health check with logging
            log_health_check
            ;;
        "full"|*)
            # Full health check
            perform_health_check
            ;;
    esac
}

# Error handling
trap 'echo -e "${RED}Health check script failed${NC}"' ERR

# Run main function
main "$@"
