# Security Implementation Plan for Vita Strategies

## Overview
This document provides a detailed implementation plan to address critical security issues identified during the workspace audit. These security concerns must be addressed before deployment to production.

## Critical Security Issues

### 1. Hardcoded Credentials in Terraform Variables
**Issue**: Sensitive credentials are hardcoded in `infrastructure/terraform/variables.tf`, including:
- Database passwords
- Cloudflare API token
- Keycloak admin credentials

### 2. Insecure Network Configuration
**Issue**: Several network security issues were identified:
- SSH access allowed from anywhere (`0.0.0.0/0`)
- All Cloud Run services deployed with `--allow-unauthenticated`
- VM service account has excessive permissions

### 3. Docker Security Issues
**Issue**: Docker configurations have several security weaknesses:
- Using `latest` tags instead of pinned versions
- No user specification (running as root)
- No security scanning in CI/CD pipeline

### 4. Missing SSL/TLS Configuration
**Issue**: SSL/TLS configuration is incomplete:
- Empty `ssl-params.conf` file
- No SSL certificate management implementation

## Implementation Plan

### 1. Secure Credential Management

#### 1.1 Move Credentials to Secret Manager
```bash
# Create secrets in Secret Manager
gcloud secrets create cloudflare-api-token --replication-policy="automatic"
gcloud secrets create keycloak-admin-password --replication-policy="automatic"

# For each database password
for service in mattermost windmill metabase grafana openbao keycloak wordpress bookstack erpnext appsmith; do
  gcloud secrets create ${service}-db-password --replication-policy="automatic"
done

# Set secret values (do not store these commands in history)
echo "your-secure-token" | gcloud secrets versions add cloudflare-api-token --data-file=-
echo "your-secure-password" | gcloud secrets versions add keycloak-admin-password --data-file=-

# Generate and set random passwords for databases
for service in mattermost windmill metabase grafana openbao keycloak wordpress bookstack erpnext appsmith; do
  openssl rand -base64 16 | gcloud secrets versions add ${service}-db-password --data-file=-
done
```

#### 1.2 Update Terraform to Use Secret Manager
Modify `infrastructure/terraform/variables.tf`:

```hcl
# Replace hardcoded credentials with references to Secret Manager
variable "cloudflare_api_token" {
  description = "Cloudflare API token for DNS management"
  type        = string
  sensitive   = true
  # Remove default value
}

variable "database_passwords" {
  description = "Database passwords for each service"
  type        = map(string)
  sensitive   = true
  # Remove default values
}

variable "keycloak_admin_password" {
  description = "Keycloak admin password"
  type        = string
  sensitive   = true
  # Remove default value
}
```

Add Secret Manager data sources to `infrastructure/terraform/main.tf`:

```hcl
data "google_secret_manager_secret_version" "cloudflare_api_token" {
  secret = "cloudflare-api-token"
}

data "google_secret_manager_secret_version" "keycloak_admin_password" {
  secret = "keycloak-admin-password"
}

locals {
  database_passwords = {
    mattermost = data.google_secret_manager_secret_version.mattermost_db_password.secret_data,
    windmill   = data.google_secret_manager_secret_version.windmill_db_password.secret_data,
    metabase   = data.google_secret_manager_secret_version.metabase_db_password.secret_data,
    grafana    = data.google_secret_manager_secret_version.grafana_db_password.secret_data,
    openbao    = data.google_secret_manager_secret_version.openbao_db_password.secret_data,
    keycloak   = data.google_secret_manager_secret_version.keycloak_db_password.secret_data,
    wordpress  = data.google_secret_manager_secret_version.wordpress_db_password.secret_data,
    bookstack  = data.google_secret_manager_secret_version.bookstack_db_password.secret_data,
    erpnext    = data.google_secret_manager_secret_version.erpnext_db_password.secret_data,
    appsmith   = data.google_secret_manager_secret_version.appsmith_db_password.secret_data,
  }
}
```

### 2. Secure Network Configuration

#### 2.1 Restrict SSH Access
Modify `infrastructure/terraform/variables.tf`:

```hcl
variable "admin_ip" {
  description = "Admin IP address for SSH access (CIDR format)"
  type        = string
  # Remove default value of "0.0.0.0/0"
}
```

Add firewall rule in `infrastructure/terraform/security.tf`:

```hcl
resource "google_compute_firewall" "ssh_access" {
  name    = "${var.project_name}-ssh-access"
  network = google_compute_network.main.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = [var.admin_ip]
  target_tags   = ["ssh-access"]
}
```

#### 2.2 Secure Cloud Run Services
Modify `cloudbuild.yaml` to remove `--allow-unauthenticated` and add proper IAM bindings:

```yaml
# Example for one service (repeat for all services)
- name: 'gcr.io/cloud-builders/gcloud'
  args: [
    'run', 'deploy', 'vita-strategies-wordpress',
    '--image', 'gcr.io/$PROJECT_ID/wordpress:latest',
    '--region', 'europe-west2',
    '--platform', 'managed',
    # Remove '--allow-unauthenticated'
  ]
```

Add IAM bindings for authenticated access:

```bash
# Add this to a deployment script
gcloud run services add-iam-policy-binding vita-strategies-wordpress \
  --member="allUsers" \
  --role="roles/run.invoker" \
  --region=europe-west2
```

#### 2.3 Implement Least Privilege for Service Accounts
Modify `infrastructure/terraform/compute.tf`:

```hcl
# Replace broad scope
service_account {
  email = google_service_account.vm_service_account.email
  scopes = [
    # Replace "https://www.googleapis.com/auth/cloud-platform" with specific scopes
    "https://www.googleapis.com/auth/compute",
    "https://www.googleapis.com/auth/devstorage.read_write",
    "https://www.googleapis.com/auth/logging.write",
    "https://www.googleapis.com/auth/monitoring.write",
    "https://www.googleapis.com/auth/sqlservice.admin"
  ]
}
```

### 3. Docker Security Improvements

#### 3.1 Pin Docker Image Versions
Update all Dockerfiles to use specific versions:

```dockerfile
# Example for Keycloak (apps/keycloak/Dockerfile)
# Replace:
# FROM quay.io/keycloak/keycloak:latest
# With:
FROM quay.io/keycloak/keycloak:22.0.1
```

Repeat for all Dockerfiles in the project.

#### 3.2 Add Non-Root User Configuration
Add user configuration to Dockerfiles:

```dockerfile
# Example for Keycloak (apps/keycloak/Dockerfile)
FROM quay.io/keycloak/keycloak:22.0.1

# Add user configuration
USER 1000

EXPOSE 8080
```

#### 3.3 Add Security Scanning to CI/CD
Add security scanning to `cloudbuild.yaml`:

```yaml
# Add after build steps
- name: 'gcr.io/cloud-builders/docker'
  args: ['pull', 'aquasec/trivy:latest']
  id: 'pull-trivy'

# Example for one image (repeat for all images)
- name: 'gcr.io/cloud-builders/docker'
  args: ['run', '--rm', '-v', '/workspace:/workspace', 'aquasec/trivy:latest', 'image', '--severity', 'HIGH,CRITICAL', 'gcr.io/$PROJECT_ID/wordpress:latest']
  id: 'scan-wordpress'
  waitFor: ['build-wordpress']
```

### 4. SSL/TLS Configuration

#### 4.1 Create SSL Parameters Configuration
Create proper content for `infrastructure/docker/nginx/ssl-params.conf`:

```nginx
# SSL parameters configuration
ssl_protocols TLSv1.2 TLSv1.3;
ssl_prefer_server_ciphers on;
ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384;
ssl_session_timeout 1d;
ssl_session_cache shared:SSL:10m;
ssl_session_tickets off;
ssl_stapling on;
ssl_stapling_verify on;

# HSTS (comment out if testing with self-signed certs)
add_header Strict-Transport-Security "max-age=63072000; includeSubDomains; preload";

# Additional security headers
add_header X-Content-Type-Options nosniff;
add_header X-Frame-Options SAMEORIGIN;
add_header X-XSS-Protection "1; mode=block";
add_header Content-Security-Policy "default-src 'self'; script-src 'self' 'unsafe-inline' 'unsafe-eval'; img-src 'self' data:; style-src 'self' 'unsafe-inline'; font-src 'self'; connect-src 'self'";
```

#### 4.2 Implement Let's Encrypt Certificate Management
Create a script for certificate management:

```bash
#!/bin/bash
# scripts/manage-certificates.sh

# Install certbot if not present
if ! command -v certbot &> /dev/null; then
  apt-get update
  apt-get install -y certbot python3-certbot-nginx
fi

# Get certificates for all domains
certbot --nginx \
  -d vitastrategies.com \
  -d www.vitastrategies.com \
  -d erp.vitastrategies.com \
  -d chat.vitastrategies.com \
  -d workflows.vitastrategies.com \
  -d analytics.vitastrategies.com \
  -d monitoring.vitastrategies.com \
  -d auth.vitastrategies.com \
  -d vault.vitastrategies.com \
  -d apps.vitastrategies.com \
  --non-interactive \
  --agree-tos \
  --email admin@vitastrategies.com

# Set up auto-renewal
echo "0 0,12 * * * root certbot renew --quiet" > /etc/cron.d/certbot-renew
```

Make the script executable:
```bash
chmod +x scripts/manage-certificates.sh
```

## Testing Plan

### 1. Credential Security Testing
```bash
# Verify Secret Manager secrets exist
gcloud secrets list

# Test secret access from VM
gcloud compute ssh vita-strategies-vm-production --command="curl -H 'Metadata-Flavor: Google' 'http://metadata.google.internal/computeMetadata/v1/instance/service-accounts/default/token'"
```

### 2. Network Security Testing
```bash
# Test SSH access restriction
# Should fail from unauthorized IP:
ssh appuser@[VM_EXTERNAL_IP]

# Test Cloud Run authentication
# Should require authentication:
curl -i https://vita-strategies-wordpress-[hash].a.run.app
```

### 3. Docker Security Testing
```bash
# Run Trivy locally on images
docker pull aquasec/trivy:latest
docker run --rm -v /var/run/docker.sock:/var/run/docker.sock aquasec/trivy:latest image gcr.io/[PROJECT_ID]/wordpress:latest
```

### 4. SSL/TLS Testing
```bash
# Test SSL configuration
curl -I https://vitastrategies.com

# Verify SSL with external tool
# Use SSL Labs: https://www.ssllabs.com/ssltest/analyze.html?d=vitastrategies.com
```

## Implementation Timeline

1. **Day 1**: Set up Secret Manager and move credentials
2. **Day 2**: Update Terraform configurations and network security
3. **Day 3**: Update Docker configurations and add security scanning
4. **Day 4**: Implement SSL/TLS configuration and certificate management
5. **Day 5**: Test all security improvements and document changes

## Rollback Plan

In case of issues, revert to the original configuration:

```bash
# Revert Terraform changes
git checkout -- infrastructure/terraform/

# Revert Docker changes
git checkout -- apps/*/Dockerfile

# Revert cloudbuild.yaml changes
git checkout -- cloudbuild.yaml

# Revert SSL configuration
git checkout -- infrastructure/docker/nginx/ssl-params.conf
```

## Conclusion

Implementing this security plan will address the critical security issues identified during the workspace audit. These changes are essential before deploying the Vita Strategies platform to production. After implementing these security improvements, a follow-up security audit should be conducted to verify that all issues have been properly addressed.