#!/bin/bash
# Mattermost Health Check Script
# Verifies service health and database connectivity

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Configuration
MATTERMOST_URL="http://localhost:8065"
MAX_RETRIES=3
RETRY_DELAY=5

# Function to check Mattermost API
check_api() {
    local url="$MATTERMOST_URL/api/v4/system/ping"
    
    if curl -f -s --connect-timeout 10 "$url" >/dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

# Function to check database connectivity
check_database() {
    local url="$MATTERMOST_URL/api/v4/database/ping"
    
    if curl -f -s --connect-timeout 10 "$url" >/dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

# Function to check disk space
check_disk_space() {
    local data_dir="/mattermost/data"
    local logs_dir="/var/log/mattermost"
    
    # Check if data directory has at least 1GB free space
    local data_space
    data_space=$(df "$data_dir" | awk 'NR==2 {print $4}')
    
    if [ "$data_space" -lt 1048576 ]; then  # 1GB in KB
        echo -e "${YELLOW}Warning: Low disk space in data directory${NC}" >&2
        return 1
    fi
    
    # Check if logs directory has at least 100MB free space
    local logs_space
    logs_space=$(df "$logs_dir" | awk 'NR==2 {print $4}')
    
    if [ "$logs_space" -lt 102400 ]; then  # 100MB in KB
        echo -e "${YELLOW}Warning: Low disk space in logs directory${NC}" >&2
        return 1
    fi
    
    return 0
}

# Function to check memory usage
check_memory() {
    local mem_usage
    mem_usage=$(ps aux | grep mattermost | grep -v grep | awk '{sum+=$4} END {print sum}')
    
    if [ -z "$mem_usage" ]; then
        echo -e "${RED}Mattermost process not found${NC}" >&2
        return 1
    fi
    
    # Warning if using more than 80% memory
    if (( $(echo "$mem_usage > 80" | bc -l) )); then
        echo -e "${YELLOW}Warning: High memory usage: ${mem_usage}%${NC}" >&2
        return 1
    fi
    
    return 0
}

# Main health check function
main() {
    local retries=0
    local api_ok=false
    local db_ok=false
    local disk_ok=true
    local memory_ok=true
    
    echo -e "${YELLOW}🏥 Performing Mattermost health check...${NC}"
    
    # Check API with retries
    while [ $retries -lt $MAX_RETRIES ]; do
        if check_api; then
            api_ok=true
            break
        else
            retries=$((retries + 1))
            if [ $retries -lt $MAX_RETRIES ]; then
                echo -e "${YELLOW}API check failed, retrying in ${RETRY_DELAY}s... (${retries}/${MAX_RETRIES})${NC}"
                sleep $RETRY_DELAY
            fi
        fi
    done
    
    # Check database
    if check_database; then
        db_ok=true
    fi
    
    # Check disk space
    if ! check_disk_space; then
        disk_ok=false
    fi
    
    # Check memory usage
    if ! check_memory; then
        memory_ok=false
    fi
    
    # Report results
    echo -e "${BLUE}Health Check Results:${NC}"
    
    if [ "$api_ok" = true ]; then
        echo -e "  ${GREEN}✅ API: Healthy${NC}"
    else
        echo -e "  ${RED}❌ API: Unhealthy${NC}"
    fi
    
    if [ "$db_ok" = true ]; then
        echo -e "  ${GREEN}✅ Database: Connected${NC}"
    else
        echo -e "  ${RED}❌ Database: Disconnected${NC}"
    fi
    
    if [ "$disk_ok" = true ]; then
        echo -e "  ${GREEN}✅ Disk Space: Sufficient${NC}"
    else
        echo -e "  ${YELLOW}⚠️  Disk Space: Low${NC}"
    fi
    
    if [ "$memory_ok" = true ]; then
        echo -e "  ${GREEN}✅ Memory: Normal${NC}"
    else
        echo -e "  ${YELLOW}⚠️  Memory: High Usage${NC}"
    fi
    
    # Exit with appropriate code
    if [ "$api_ok" = true ] && [ "$db_ok" = true ]; then
        echo -e "${GREEN}🏥 Overall Health: HEALTHY${NC}"
        exit 0
    else
        echo -e "${RED}🏥 Overall Health: UNHEALTHY${NC}"
        exit 1
    fi
}

# Run health check
main "$@"
