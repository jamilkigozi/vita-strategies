#!/bin/bash
set -euo pipefail

# Health check script for Grafana Monitoring Platform
# Performs comprehensive health validation of Grafana service

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
GRAFANA_URL="http://localhost:3000"
HEALTH_ENDPOINT="/api/health"
TIMEOUT=10
MAX_RETRIES=3

# Health check functions
check_grafana_service() {
    local endpoint="$GRAFANA_URL$HEALTH_ENDPOINT"
    
    # Check if Grafana API responds
    if curl -f -s --max-time $TIMEOUT "$endpoint" > /dev/null 2>&1; then
        echo -e "${GREEN}✓${NC} Grafana service is responding"
        return 0
    else
        echo -e "${RED}✗${NC} Grafana service is not responding"
        return 1
    fi
}

check_database_connectivity() {
    # Check database connection through Grafana API
    local db_check_endpoint="$GRAFANA_URL/api/admin/stats"
    local auth="admin:${GF_SECURITY_ADMIN_PASSWORD:-changeme}"
    
    if curl -f -s --max-time $TIMEOUT -u "$auth" "$db_check_endpoint" > /dev/null 2>&1; then
        echo -e "${GREEN}✓${NC} Database connectivity is healthy"
        return 0
    else
        echo -e "${RED}✗${NC} Database connectivity issue detected"
        return 1
    fi
}

check_memory_usage() {
    # Check memory usage of Grafana process
    local memory_usage
    memory_usage=$(ps -o pid,ppid,cmd,%mem --sort=-%mem | grep grafana-server | grep -v grep | awk '{print $4}' | head -1)
    
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
    # Check disk space for Grafana data directory
    local data_dir="/var/lib/grafana"
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
    # Check if Grafana process is running
    if pgrep -f "grafana-server" > /dev/null; then
        local pid
        pid=$(pgrep -f "grafana-server")
        echo -e "${GREEN}✓${NC} Grafana process is running (PID: $pid)"
        return 0
    else
        echo -e "${RED}✗${NC} Grafana process is not running"
        return 1
    fi
}

check_log_errors() {
    # Check for recent errors in Grafana logs
    local log_file="/var/log/grafana/grafana.log"
    local error_count=0
    
    if [[ -f "$log_file" ]]; then
        # Count errors in the last 5 minutes
        error_count=$(grep -c "level=error" "$log_file" 2>/dev/null | tail -100 | wc -l || echo "0")
        
        if [[ "$error_count" -gt 5 ]]; then
            echo -e "${YELLOW}⚠${NC} Recent errors detected in logs: $error_count errors"
            return 1
        else
            echo -e "${GREEN}✓${NC} No significant errors in recent logs"
            return 0
        fi
    else
        echo -e "${YELLOW}⚠${NC} Log file not found: $log_file"
        return 1
    fi
}

check_plugin_status() {
    # Check if critical plugins are loaded
    local plugins_endpoint="$GRAFANA_URL/api/plugins"
    local auth="admin:${GF_SECURITY_ADMIN_PASSWORD:-changeme}"
    
    if curl -f -s --max-time $TIMEOUT -u "$auth" "$plugins_endpoint" > /dev/null 2>&1; then
        echo -e "${GREEN}✓${NC} Plugins are accessible"
        return 0
    else
        echo -e "${YELLOW}⚠${NC} Plugin status could not be verified"
        return 1
    fi
}

check_session_store() {
    # Check session store connectivity
    if [[ "${GF_SESSION_PROVIDER:-}" == "redis" ]]; then
        # Extract Redis connection details
        local redis_config="${GF_SESSION_PROVIDER_CONFIG:-addr=redis:6379}"
        local redis_addr=$(echo "$redis_config" | grep -o 'addr=[^,]*' | cut -d'=' -f2)
        local redis_host="${redis_addr%%:*}"
        local redis_port="${redis_addr##*:}"
        
        if nc -z "$redis_host" "$redis_port" 2>/dev/null; then
            echo -e "${GREEN}✓${NC} Redis session store is accessible"
            return 0
        else
            echo -e "${RED}✗${NC} Redis session store is not accessible"
            return 1
        fi
    else
        echo -e "${GREEN}✓${NC} Using database sessions (no external store check needed)"
        return 0
    fi
}

# Main health check function
perform_health_check() {
    local checks_passed=0
    local total_checks=8
    local exit_code=0
    
    echo "=== Grafana Health Check ==="
    echo "Timestamp: $(date '+%Y-%m-%d %H:%M:%S')"
    echo ""
    
    # Perform all health checks
    if check_grafana_service; then ((checks_passed++)); else exit_code=1; fi
    if check_database_connectivity; then ((checks_passed++)); else exit_code=1; fi
    if check_memory_usage; then ((checks_passed++)); else exit_code=1; fi
    if check_disk_space; then ((checks_passed++)); else exit_code=1; fi
    if check_process_status; then ((checks_passed++)); else exit_code=1; fi
    if check_log_errors; then ((checks_passed++)); else exit_code=1; fi
    if check_plugin_status; then ((checks_passed++)); else exit_code=1; fi
    if check_session_store; then ((checks_passed++)); else exit_code=1; fi
    
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
    if curl -f -s --max-time 5 "$GRAFANA_URL$HEALTH_ENDPOINT" > /dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

# Enhanced logging for health check results
log_health_check() {
    local log_file="/var/log/grafana/health-check.log"
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
