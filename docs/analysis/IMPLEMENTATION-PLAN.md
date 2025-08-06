# Vita Strategies - High Priority Implementation Plan

## Focus Areas
This implementation plan addresses the two highest-priority issues mentioned in the README:
1. ERPNext CSS/JavaScript loading inconsistently
2. Container persistence problems when IDE updates

## 1. ERPNext CSS/JavaScript Loading Fix

### Root Cause Analysis
The current Nginx configuration proxies all requests, including static assets, to the ERPNext backend. This is inefficient and can lead to inconsistent loading of CSS/JS files due to:
- Backend processing overhead
- Potential race conditions in asset compilation
- Lack of proper caching directives

### Implementation Steps

#### 1.1 Update Nginx Configuration
Modify `/Users/millz./vita-strategies/nginx.conf` to serve static assets directly:

```nginx
# Current configuration (to be replaced)
location /assets/ {
    proxy_pass http://erpnext_backend;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
    expires 1y;
    add_header Cache-Control "public, immutable";
}

# New configuration
location /assets/ {
    alias /path/to/erpnext/assets/;  # Update with correct path
    expires 1y;
    add_header Cache-Control "public, immutable";
    add_header X-Content-Type-Options nosniff;
    try_files $uri =404;
}
```

#### 1.2 Update Docker Compose Configuration
Modify `/Users/millz./vita-strategies/docker-compose.yml` to mount ERPNext assets to Nginx:

```yaml
services:
  nginx:
    # Existing configuration...
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf:ro
      - ./ssl:/etc/nginx/ssl:ro
      # Add this line:
      - erpnext_sites:/var/www/html/erpnext:ro
```

#### 1.3 Add Asset Compilation Step
Add a build step in the CI/CD pipeline to ensure assets are compiled before deployment:

```yaml
# Add to cloudbuild.yaml
steps:
  # Existing steps...
  
  # Add ERPNext asset compilation
  - name: 'gcr.io/cloud-builders/docker'
    args: ['exec', 'erpnext', 'bench', 'build']
    id: 'compile-erpnext-assets'
    waitFor: ['build-erpnext']
```

## 2. Container Persistence Fix

### Root Cause Analysis
The current configuration doesn't properly handle container persistence when the IDE updates. This could be due to:
- Volume mounting issues
- Container restart policies
- Docker Compose configuration

### Implementation Steps

#### 2.1 Update Volume Configuration
Modify `/Users/millz./vita-strategies/docker-compose.yml` to use named volumes consistently:

```yaml
volumes:
  # Existing volumes...
  
  # Fix Mattermost DB volume (currently using anonymous volume)
  mattermost_db_data:  # Add this named volume
```

```yaml
services:
  # Update Mattermost DB service
  mattermost-db:
    # Existing configuration...
    volumes:
      # Replace this line:
      # - /var/lib/postgresql/data
      # With this:
      - mattermost_db_data:/var/lib/postgresql/data
```

#### 2.2 Add Restart Policy
Ensure all services have appropriate restart policies:

```yaml
services:
  # For each service, ensure this is set:
  restart: unless-stopped
```

#### 2.3 Create Docker Compose Override for Development
Create a new file `/Users/millz./vita-strategies/docker-compose.override.yml` for development-specific settings:

```yaml
version: '3.8'

services:
  # Development-specific overrides
  erpnext:
    volumes:
      # Add development-specific volume mounts
      - ./apps/erpnext/custom:/home/frappe/frappe-bench/apps/erpnext/erpnext/custom:ro
      
  # Add similar overrides for other services as needed
```

#### 2.4 Create Container Management Script
Create a helper script to manage containers during IDE updates:

```bash
#!/bin/bash
# /Users/millz./vita-strategies/scripts/manage-containers.sh

ACTION=$1

case $ACTION in
  "pause")
    echo "Pausing containers for IDE update..."
    docker-compose stop
    ;;
  "resume")
    echo "Resuming containers after IDE update..."
    docker-compose start
    ;;
  "restart")
    echo "Restarting containers..."
    docker-compose restart
    ;;
  *)
    echo "Usage: $0 {pause|resume|restart}"
    exit 1
    ;;
esac
```

Make the script executable:
```bash
chmod +x /Users/millz./vita-strategies/scripts/manage-containers.sh
```

## 3. Testing the Changes

### 3.1 ERPNext CSS/JS Loading Test
Create a simple test script to verify CSS/JS loading:

```bash
#!/bin/bash
# /Users/millz./vita-strategies/tests/integration/test-erpnext-assets.sh

echo "Testing ERPNext asset loading..."
curl -s -o /dev/null -w "%{http_code}" http://erp.vita-strategies.com/assets/css/desk.min.css
curl -s -o /dev/null -w "%{http_code}" http://erp.vita-strategies.com/assets/js/desk.min.js

# Add more comprehensive tests as needed
```

### 3.2 Container Persistence Test
Create a test script to verify container persistence:

```bash
#!/bin/bash
# /Users/millz./vita-strategies/tests/integration/test-container-persistence.sh

echo "Testing container persistence..."
./scripts/manage-containers.sh pause
sleep 5
./scripts/manage-containers.sh resume
sleep 10

# Check if all containers are running
CONTAINERS=$(docker-compose ps -q | wc -l)
RUNNING=$(docker-compose ps -q --filter status=running | wc -l)

if [ "$CONTAINERS" -eq "$RUNNING" ]; then
  echo "All containers successfully resumed"
  exit 0
else
  echo "Container persistence test failed"
  exit 1
fi
```

## 4. Implementation Timeline

1. **Day 1**: Update Nginx configuration and test ERPNext asset serving
2. **Day 2**: Implement container persistence fixes and create management script
3. **Day 3**: Create and run tests to verify both fixes
4. **Day 4**: Document changes and update README with new information

## 5. Rollback Plan

In case of issues, revert to the original configuration:

```bash
# Revert Nginx configuration
git checkout -- nginx.conf

# Revert Docker Compose changes
git checkout -- docker-compose.yml

# Restart services with original configuration
docker-compose down
docker-compose up -d
```