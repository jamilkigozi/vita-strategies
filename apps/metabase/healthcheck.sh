#!/bin/bash

# Metabase Health Check Script
# Comprehensive monitoring for business intelligence platform

# Exit codes
HEALTH_OK=0
HEALTH_WARNING=1
HEALTH_CRITICAL=2

# Configuration
METABASE_URL=${MB_SITE_URL:-"http://127.0.0.1:3000"}
TIMEOUT=${HEALTH_CHECK_TIMEOUT:-15}
CRITICAL_THRESHOLD=${CRITICAL_THRESHOLD:-90}
WARNING_THRESHOLD=${WARNING_THRESHOLD:-75}

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

# 1. Check Metabase service availability
check_service_availability() {
    if curl -sf --connect-timeout $TIMEOUT "http://127.0.0.1:3000/api/health" >/dev/null 2>&1; then
        echo "[OK] Metabase service is responding"
        update_status $HEALTH_OK
        return $HEALTH_OK
    else
        echo "[CRITICAL] Metabase service is not responding"
        update_status $HEALTH_CRITICAL
        return $HEALTH_CRITICAL
    fi
}

# 2. Check database connectivity
check_database_connectivity() {
    local db_host=${MB_DB_HOST:-postgres}
    local db_port=${MB_DB_PORT:-5432}
    
    if nc -z -w$TIMEOUT "$db_host" "$db_port" 2>/dev/null; then
        echo "[OK] Database connectivity successful"
        update_status $HEALTH_OK
        return $HEALTH_OK
    else
        echo "[CRITICAL] Database is not reachable"
        update_status $HEALTH_CRITICAL
        return $HEALTH_CRITICAL
    fi
}

# 3. Check memory usage
check_memory_usage() {
    if command -v free >/dev/null 2>&1; then
        local mem_usage=$(free | awk 'NR==2{printf "%.0f", $3*100/$2}')
        
        if [ "$mem_usage" -ge "$CRITICAL_THRESHOLD" ]; then
            echo "[CRITICAL] Memory usage critical: ${mem_usage}%"
            update_status $HEALTH_CRITICAL
            return $HEALTH_CRITICAL
        elif [ "$mem_usage" -ge "$WARNING_THRESHOLD" ]; then
            echo "[WARNING] Memory usage high: ${mem_usage}%"
            update_status $HEALTH_WARNING
            return $HEALTH_WARNING
        else
            echo "[OK] Memory usage normal: ${mem_usage}%"
            update_status $HEALTH_OK
            return $HEALTH_OK
        fi
    else
        echo "[INFO] Memory check not available"
        return $HEALTH_OK
    fi
}

# 4. Check disk usage
check_disk_usage() {
    local usage=$(df /opt/metabase | awk 'NR==2 {print int($5)}')
    
    if [ -z "$usage" ]; then
        echo "[WARNING] Cannot determine disk usage"
        update_status $HEALTH_WARNING
        return $HEALTH_WARNING
    fi
    
    if [ "$usage" -ge "$CRITICAL_THRESHOLD" ]; then
        echo "[CRITICAL] Disk usage critical: ${usage}%"
        update_status $HEALTH_CRITICAL
        return $HEALTH_CRITICAL
    elif [ "$usage" -ge "$WARNING_THRESHOLD" ]; then
        echo "[WARNING] Disk usage high: ${usage}%"
        update_status $HEALTH_WARNING
        return $HEALTH_WARNING
    else
        echo "[OK] Disk usage normal: ${usage}%"
        update_status $HEALTH_OK
        return $HEALTH_OK
    fi
}

# 5. Check Java process
check_java_process() {
    if pgrep -f "metabase.jar" >/dev/null 2>&1; then
        echo "[OK] Metabase process is running"
        update_status $HEALTH_OK
        return $HEALTH_OK
    else
        echo "[CRITICAL] Metabase process is not running"
        update_status $HEALTH_CRITICAL
        return $HEALTH_CRITICAL
    fi
}

# Main health check function
main() {
    echo "Metabase Health Check - $(date)"
    echo "================================"
    
    # Run all health checks
    check_service_availability
    check_database_connectivity
    check_memory_usage
    check_disk_usage
    check_java_process
    
    # Summary
    echo "================================"
    echo "Health Check Summary:"
    echo "Checks passed: $CHECKS_PASSED/$CHECKS_TOTAL"
    
    case $OVERALL_STATUS in
        $HEALTH_OK)
            echo "[OK] Overall status: HEALTHY"
            ;;
        $HEALTH_WARNING)
            echo "[WARNING] Overall status: WARNING"
            ;;
        $HEALTH_CRITICAL)
            echo "[CRITICAL] Overall status: CRITICAL"
            ;;
    esac
    
    exit $OVERALL_STATUS
}

# Run health check
main "$@"
