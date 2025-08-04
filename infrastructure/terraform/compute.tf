# Terraform Compute Resources
# Purpose: Define VM instances and compute configurations
# Dependencies: main.tf networking and security

# ============================================================================
# STARTUP SCRIPT FOR VM INITIALIZATION
# ============================================================================

locals {
  startup_script = <<-EOF
#!/bin/bash
set -e

# Update system
apt-get update
apt-get upgrade -y

# Install required packages
apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    software-properties-common

# Install Docker CE
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# Install gcsfuse for bucket mounting
export GCSFUSE_REPO=gcsfuse-$(lsb_release -c -s)
echo "deb https://packages.cloud.google.com/apt $GCSFUSE_REPO main" | tee /etc/apt/sources.list.d/gcsfuse.list
curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
apt-get update
apt-get install -y gcsfuse

# Create dedicated app user
useradd -m -s /bin/bash appuser
usermod -aG docker appuser

# Create bucket mount points
mkdir -p /mnt/buckets/erpnext
mkdir -p /mnt/buckets/analytics
mkdir -p /mnt/buckets/wordpress
mkdir -p /mnt/buckets/assets
mkdir -p /mnt/buckets/team-files
mkdir -p /mnt/buckets/backups

# Set ownership
chown -R appuser:appuser /mnt/buckets

# Create Docker bridge network
docker network create vita-network || true

# Mount GCS buckets using gcsfuse
gcsfuse vita-strategies-erpnext-production /mnt/buckets/erpnext
gcsfuse vita-strategies-analytics-production /mnt/buckets/analytics
gcsfuse vita-strategies-wordpress-production /mnt/buckets/wordpress
gcsfuse vita-strategies-assets-production /mnt/buckets/assets
gcsfuse vita-strategies-team-files-production /mnt/buckets/team-files
gcsfuse vita-strategies-data-backup-production /mnt/buckets/backups

# Create systemd service template
cat > /etc/systemd/system/vita-service@.service << 'SYSTEMD_EOF'
[Unit]
Description=Vita Strategies %i Service
Requires=docker.service
After=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/usr/bin/docker run -d \
    --name %i \
    --network vita-network \
    --restart unless-stopped \
    --user appuser \
    -v /mnt/buckets/%i:/data \
    --env-file /opt/vita/%i.env \
    %i:latest
ExecStop=/usr/bin/docker stop %i
ExecStopPost=/usr/bin/docker rm %i
User=appuser
Group=appuser

[Install]
WantedBy=multi-user.target
SYSTEMD_EOF

# Create environment files directory
mkdir -p /opt/vita
chown appuser:appuser /opt/vita

# Enable and start Docker
systemctl enable docker
systemctl start docker

# Log completion
echo "$(date): VM initialization completed" >> /var/log/vita-startup.log

EOF
}

# ============================================================================
# MAIN COMPUTE INSTANCE
# ============================================================================

resource "google_compute_instance" "main" {
  name         = "${var.project_name}-vm-${var.environment}"
  machine_type = var.machine_type
  zone         = var.zone

  # Configure boot disk
  boot_disk {
    initialize_params {
      image = var.boot_image
      size  = var.disk_size
      type  = "pd-standard"
    }
  }

  # Network configuration
  network_interface {
    subnetwork = google_compute_subnetwork.main.id
    access_config {
      nat_ip = google_compute_address.main.address
    }
  }

  # Security and access
  tags = ["web-server", "app-server", "ssh-access"]

  # SSH key configuration
  metadata = {
    ssh-keys = "appuser:${var.ssh_public_key}"
  }

  # Service account for GCS access
  service_account {
    email = google_service_account.vm_service_account.email
    scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
  }

  # Startup script
  metadata_startup_script = local.startup_script

  # Labels for organization
  labels = local.common_labels

  # Lifecycle management
  lifecycle {
    ignore_changes = [
      metadata_startup_script,
    ]
  }

  depends_on = [
    google_compute_subnetwork.main,
    google_service_account.vm_service_account
  ]
}

# ============================================================================
# BUILD STATUS
# ============================================================================
# ✅ COMPLETE: VM instance with professional configuration
# ✅ COMPLETE: gcsfuse bucket mounting
# ✅ COMPLETE: systemd service template
# ✅ COMPLETE: dedicated appuser security
# ✅ COMPLETE: Docker bridge network
# 🚀 READY: For service deployment
