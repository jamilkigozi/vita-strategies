# 🔧 VITA STRATEGIES - INSTALLATION GUIDE

Quick setup guide for new team members and development environments.

## 🚀 Quick Start

### **For Business Operations**
```bash
# Deploy from GCP Cloud Shell
./scripts/deploy-from-gcp-cloudshell.sh
```

### **For Development**
```bash
# Local development setup
cp .env.example .env
docker-compose -f docker-compose-persistent.yml up -d
```

## 📦 Prerequisites

### **Required Tools**
- **Docker** & **Docker Compose**
- **Google Cloud SDK** (`gcloud`)
- **Terraform** (for infrastructure)

### **Install on macOS**
```bash
# Install Homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install required tools
brew install docker docker-compose google-cloud-sdk terraform
```

### **Install on Ubuntu/Debian**
```bash
# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh

# Install Google Cloud SDK
echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | sudo tee -a /etc/apt/sources.list.d/google-cloud-sdk.list
curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key --keyring /usr/share/keyrings/cloud.google.gpg add -
sudo apt-get update && sudo apt-get install google-cloud-cli

# Install Terraform
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install terraform
```

## 🔐 Authentication Setup

### **Google Cloud Authentication**
```bash
# Login to Google Cloud
gcloud auth login

# Set project
gcloud config set project mystical-slate-463221-j0

# Application default credentials
gcloud auth application-default login
```

### **Docker Authentication (if using private registries)**
```bash
gcloud auth configure-docker
```

## 🏗️ Project Setup

### **1. Clone Repository**
```bash
git clone https://github.com/jamilkigozi/vita-strategies.git
cd vita-strategies
```

### **2. Environment Configuration**
```bash
# Copy environment template
cp .env.example .env

# Edit with your settings
nano .env
```

### **3. Verify Setup**
```bash
# Run comprehensive scan
./scripts/comprehensive-scan.sh

# Should show 100/100 completion
```

## 🚀 Deployment Options

### **Production (GCP)**
```bash
./scripts/deploy-from-gcp-cloudshell.sh
```

### **Development (Local)**
```bash
docker-compose -f docker-compose-persistent.yml up -d
```

### **Multi-Cloud Export**
```bash
./scripts/export-business.sh
```

## 🔧 Troubleshooting

### **Docker Issues**
```bash
# Check Docker status
docker --version
docker-compose --version

# Start Docker (macOS)
open /Applications/Docker.app

# Start Docker (Linux)
sudo systemctl start docker
```

### **GCP Issues**
```bash
# Check authentication
gcloud auth list

# Check project
gcloud config get-value project

# Re-authenticate
gcloud auth login
```

### **Permission Issues**
```bash
# Fix script permissions
chmod +x scripts/*.sh

# Fix Docker permissions (Linux)
sudo usermod -aG docker $USER
# Log out and back in
```

## 📞 Support

**Common Issues:**
- Docker not running → Start Docker Desktop
- GCP auth failed → Run `gcloud auth login`
- Permission denied → Run `chmod +x scripts/*.sh`
- Port conflicts → Change ports in `.env` file

**Get Help:**
1. Run diagnostic: `./scripts/comprehensive-scan.sh`
2. Check logs: `docker-compose logs [service-name]`
3. Review: `CREDENTIALS.md` for login details

**Ready to deploy! 🚀**
