# Google Cloud Platform Deployment Guide

## Production Deployment on GCP

### Prerequisites
- GCP account with billing enabled
- Docker and gcloud CLI installed
- Domain configured with Cloudflare

### 1. Infrastructure Setup

```bash
# Create project
gcloud projects create vita-strategies-prod --name="Vita Strategies Production"

# Enable required APIs
gcloud services enable compute.googleapis.com
gcloud services enable container.googleapis.com
gcloud services enable sqladmin.googleapis.com
gcloud services enable dns.googleapis.com

# Set project
gcloud config set project vita-strategies-prod
```

### 2. Compute Engine Instance

```bash
# Create VM instance
gcloud compute instances create vita-main \
  --zone=us-central1-a \
  --machine-type=e2-standard-4 \
  --image-family=ubuntu-2204-lts \
  --image-project=ubuntu-os-cloud \
  --boot-disk-size=100GB \
  --boot-disk-type=pd-ssd \
  --tags=http-server,https-server

# Configure firewall
gcloud compute firewall-rules create allow-vita-http \
  --allow tcp:80,tcp:443 \
  --source-ranges 0.0.0.0/0 \
  --target-tags http-server,https-server
```

### 3. Deploy Application

```bash
# SSH to instance
gcloud compute ssh vita-main --zone=us-central1-a

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER

# Clone and deploy
git clone https://github.com/jamilkigozi/vita-strategies.git
cd vita-strategies
docker-compose up -d
```

### 4. SSL Configuration

```bash
# Install Certbot
sudo apt install certbot python3-certbot-nginx -y

# Get SSL certificates
sudo certbot --nginx -d erp.vita-strategies.com
sudo certbot --nginx -d windmill.vita-strategies.com
sudo certbot --nginx -d analytics.vita-strategies.com
sudo certbot --nginx -d monitoring.vita-strategies.com
sudo certbot --nginx -d chat.vita-strategies.com
```

### 5. DNS Configuration

Point these A records to your GCP instance IP:
- erp.vita-strategies.com
- windmill.vita-strategies.com
- analytics.vita-strategies.com
- monitoring.vita-strategies.com
- chat.vita-strategies.com

### 6. Monitoring Setup

```bash
# Enable monitoring
gcloud compute instances add-metadata vita-main \
  --metadata enable-oslogin=TRUE \
  --zone=us-central1-a

# Install monitoring agent
curl -sSO https://dl.google.com/cloudagents/add-monitoring-agent-repo.sh
sudo bash add-monitoring-agent-repo.sh
sudo apt update
sudo apt install stackdriver-agent
```

### 7. Backup Strategy

```bash
# Create snapshot schedule
gcloud compute resource-policies create snapshot-schedule vita-daily \
  --max-retention-days=7 \
  --start-time=02:00 \
  --daily-schedule

# Apply to disk
gcloud compute disks add-resource-policies vita-main \
  --resource-policies=vita-daily \
  --zone=us-central1-a
```

### Cost Optimization
- Use preemptible instances for development
- Set up billing alerts
- Enable auto-scaling for high traffic
- Use Cloud SQL for managed databases in production