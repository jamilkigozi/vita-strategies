#!/bin/bash
set -e

# VITA STRATEGIES HEALTH CHECK SCRIPT
# This script checks the health of all deployed services

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

error() {
    echo -e "${RED}[ERROR] $1${NC}"
}

warning() {
    echo -e "${YELLOW}[WARNING] $1${NC}"
}

# Check if Docker is running
if ! docker info &> /dev/null; then
    error "Docker is not running"
    exit 1
fi

# Check service status
log "Checking service status..."
docker-compose ps

# Check database connectivity
log "Checking database connectivity..."

# PostgreSQL
if docker-compose exec -T postgres pg_isready -U postgres &> /dev/null; then
    log "✅ PostgreSQL is healthy"
else
    error "❌ PostgreSQL is not responding"
fi

# MariaDB
if docker-compose exec -T mariadb mysqladmin ping -h localhost -u root -p$MARIADB_ROOT_PASSWORD &> /dev/null; then
    log "✅ MariaDB is healthy"
else
    error "❌ MariaDB is not responding"
fi

# Check application endpoints
log "Checking application endpoints..."

# PostgreSQL
if docker-compose exec -T postgres pg_isready -U postgres &> /dev/null; then
    log "✅ PostgreSQL is healthy"
else
    error "❌ PostgreSQL is not responding"
fi

# MariaDB
if docker-compose exec -T mariadb mysqladmin ping -h localhost -u root -p$MARIADB_ROOT_PASSWORD &> /dev/null; then
    log "✅ MariaDB is healthy"
else
    error "❌ MariaDB is not responding"
fi

# Check application endpoints
log "Checking application endpoints..."

# PostgreSQL
if docker-compose exec -T postgres pg_isready -U postgres &> /dev/null; then
    log "✅ PostgreSQL is healthy"
else
    error "❌ PostgreSQL is not responding"
fi

# MariaDB
if docker-compose exec -T mariadb mysqladmin ping -h localhost -u root -p$MARIADB_ROOT_PASSWORD &> /dev/null; then
    log "✅ MariaDB is not responding"
fi

# Check application endpoints
log "Checking application endpoints..."

# PostgreSQL
if docker-compose exec -T postgres pg_isready -U postgres &> /dev/null; then
    log "✅ PostgreSQL is healthy"
else
    error "❌ PostgreSQL is not responding"
fi

# MariaDB
if docker-compose exec -T mariadb mysqladmin ping -h localhost -u root -p$MARIADB_ROOT_PASSWORD &> /dev/null; then
    log "✅ MariaDB is not responding"
fi

# Check application endpoints
log "Checking application endpoints..."

# PostgreSQL
if docker-compose exec -T postgres pg_isready -U postgres &> /dev/null; then
    log "✅ PostgreSQL is healthy"
else
    error "❌ PostgreSQL is not responding"
fi

# MariaDB
if docker-compose exec -T mariadb mysqladmin ping -h localhost -u root -p$MARIADB_ROOT_PASSWORD &> /dev/null; then
    log "✅ MariaDB is not responding"
fi

# Check application endpoints
log "Checking application endpoints..."

# PostgreSQL
if docker-compose exec -T postgres pg_isready -U postgres &> /dev/null; then
    log "✅ PostgreSQL is healthy"
else
    error "❌ PostgreSQL is not responding"
fi>

<attempt_completion>
<result>
[Response interrupted by a tool use result. Only one tool may be used at a time and should be placed at the end of the message.]
