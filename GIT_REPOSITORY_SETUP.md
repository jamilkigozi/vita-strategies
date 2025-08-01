# Git Repository Setup Guide - Vita Strategies

## 🎯 Repository Strategy

We'll set up **dual remote repositories** for maximum flexibility:
- **GitHub** (primary) - For open source visibility and collaboration
- **GitLab** (secondary) - For CI/CD pipelines and private backups

## 📋 Prerequisites Checklist

Before we start, ensure you have:
- [ ] GitHub account (github.com)
- [ ] GitLab account (gitlab.com)
- [ ] SSH keys configured for both platforms
- [ ] Git configured with your email and name

## 🔧 Step 1: Git Configuration

```bash
# Configure Git globally (if not already done)
git config --global user.name "Your Name"
git config --global user.email "jamil.kigozi@hotmail.com"
git config --global init.defaultBranch main
git config --global core.autocrlf input
```

## 🔑 Step 2: SSH Key Setup

### Generate SSH Key (if you don't have one)
```bash
# Generate new SSH key
ssh-keygen -t ed25519 -C "jamil.kigozi@hotmail.com" -f ~/.ssh/id_ed25519_vita

# Start SSH agent and add key
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519_vita

# Copy public key to clipboard
cat ~/.ssh/id_ed25519_vita.pub | pbcopy
```

### Add SSH Key to Platforms
1. **GitHub**: Settings → SSH and GPG keys → New SSH key
2. **GitLab**: User Settings → SSH Keys → Add key

## 🚀 Step 3: Initialize Local Repository

```bash
# Initialize git repository
git init

# Create .gitignore file
cat > .gitignore << 'EOF'
# Environment files
.env
.env.local
.env.*.local

# OS files
.DS_Store
Thumbs.db

# IDE files
.vscode/settings.json
.idea/
*.swp
*.swo

# Dependencies
node_modules/
__pycache__/
*.pyc

# Build outputs
dist/
build/
*.log

# Terraform
*.tfstate
*.tfstate.*
.terraform/
.terraform.lock.hcl

# Docker
docker-compose.override.yml

# Secrets
secrets/
*.pem
*.key
*.crt

# Temporary files
tmp/
temp/
EOF

# Create initial commit
git add .
git commit -m "🚀 Initial commit: Vita Strategies platform structure

- Complete GCP infrastructure with Terraform
- Docker Compose setup for 7 applications
- ERPNext, Windmill, Keycloak, Metabase, Appsmith, Mattermost, Grafana
- Cloudflare integration for CDN and security
- Single VM deployment architecture for solo development
- Comprehensive documentation and deployment automation"
```

## 📱 Step 4: Create GitHub Repository

### Option A: Using GitHub CLI (Recommended)
```bash
# Install GitHub CLI if not installed
brew install gh

# Authenticate with GitHub
gh auth login

# Create repository
gh repo create vita-strategies \
  --public \
  --description "🚀 Complete business platform: ERPNext + 6 microservices on GCP with Terraform, Docker Compose, and Cloudflare integration. Solo developer optimized." \
  --homepage "https://vita-strategies.com" \
  --add-readme=false

# Add GitHub as remote
git remote add github https://github.com/$(gh api user --jq .login)/vita-strategies.git
```

### Option B: Manual GitHub Setup
1. Go to https://github.com/new
2. Repository name: `vita-strategies`
3. Description: "🚀 Complete business platform: ERPNext + 6 microservices on GCP"
4. Set to **Public**
5. Don't initialize with README (we have our own)
6. Create repository
7. Add remote: `git remote add github git@github.com:YOUR_USERNAME/vita-strategies.git`

## 🦊 Step 5: Create GitLab Repository

### Option A: Using GitLab CLI
```bash
# Install glab CLI
brew install glab

# Authenticate with GitLab
glab auth login

# Create repository
glab repo create vita-strategies \
  --public \
  --description "🚀 Complete business platform: ERPNext + 6 microservices on GCP with Terraform, Docker Compose, and Cloudflare integration"

# Add GitLab as remote
git remote add gitlab git@gitlab.com:$(glab api user --jq .username)/vita-strategies.git
```

### Option B: Manual GitLab Setup
1. Go to https://gitlab.com/projects/new
2. Project name: `vita-strategies`
3. Project description: "🚀 Complete business platform: ERPNext + 6 microservices on GCP"
4. Visibility: **Public**
5. Don't initialize with README
6. Create project
7. Add remote: `git remote add gitlab git@gitlab.com:YOUR_USERNAME/vita-strategies.git`

## 📤 Step 6: Push to Both Repositories

```bash
# Verify remotes are set up
git remote -v

# Push to GitHub (primary)
git push -u github main

# Push to GitLab (secondary)
git push -u gitlab main

# Set GitHub as default upstream
git branch --set-upstream-to=github/main main
```

## 🔄 Step 7: Set Up Branch Protection and CI/CD

### GitHub Branch Protection
```bash
# Using GitHub CLI
gh api repos/:owner/:repo/branches/main/protection \
  --method PUT \
  --field required_status_checks='{"strict":true,"contexts":[]}' \
  --field enforce_admins=true \
  --field required_pull_request_reviews='{"required_approving_review_count":1}' \
  --field restrictions=null
```

### GitLab CI/CD Pipeline
Create `.gitlab-ci.yml`:
```yaml
stages:
  - validate
  - plan
  - deploy

variables:
  TERRAFORM_VERSION: "1.5.0"

terraform-validate:
  stage: validate
  image: hashicorp/terraform:$TERRAFORM_VERSION
  script:
    - cd gcp-infrastructure/terraform
    - terraform init -backend=false
    - terraform validate
  only:
    - merge_requests
    - main

terraform-plan:
  stage: plan
  image: hashicorp/terraform:$TERRAFORM_VERSION
  script:
    - cd gcp-infrastructure/terraform
    - terraform init
    - terraform plan
  only:
    - merge_requests
    - main

deploy-production:
  stage: deploy
  image: google/cloud-sdk:alpine
  script:
    - ./deploy.sh
  only:
    - main
  when: manual
```

## 🏷️ Step 8: Create Release Tags

```bash
# Create initial release
git tag -a v1.0.0 -m "🎉 Release v1.0.0: Initial platform deployment

Features:
- Complete GCP infrastructure setup
- 7 containerized applications
- Single VM deployment architecture
- Terraform automation
- Cloudflare integration
- Solo developer optimized"

# Push tags to both remotes
git push github --tags
git push gitlab --tags
```

## 📝 Step 9: Repository Configuration

### GitHub Repository Settings
- **Topics**: `gcp`, `terraform`, `docker-compose`, `erpnext`, `cloudflare`, `solo-developer`
- **Website**: https://vita-strategies.com
- **License**: Choose appropriate license (MIT recommended for open source)
- **Security**: Enable Dependabot alerts
- **Actions**: Enable GitHub Actions for CI/CD

### GitLab Repository Settings
- **Topics**: `gcp`, `terraform`, `docker-compose`, `erpnext`, `cloudflare`
- **CI/CD**: Enable Auto DevOps
- **Container Registry**: Enable for Docker images
- **Pages**: Enable for documentation hosting

## 🔒 Step 10: Security Setup

```bash
# Create security policy
mkdir -p .github
cat > .github/SECURITY.md << 'EOF'
# Security Policy

## Reporting Security Vulnerabilities

If you discover a security vulnerability, please send an email to jamil.kigozi@hotmail.com.

Do not create public GitHub issues for security vulnerabilities.

## Supported Versions

| Version | Supported          |
| ------- | ------------------ |
| 1.x.x   | :white_check_mark: |

EOF

# Add to git
git add .github/SECURITY.md
git commit -m "🔒 Add security policy"
git push github main
git push gitlab main
```

## ✅ Verification Checklist

After setup, verify:
- [ ] Local repository initialized with proper .gitignore
- [ ] GitHub repository created and accessible
- [ ] GitLab repository created and accessible
- [ ] SSH keys working for both platforms
- [ ] Initial commit pushed to both repositories
- [ ] Branch protection enabled on GitHub
- [ ] CI/CD pipeline configured on GitLab
- [ ] Repository topics and descriptions set
- [ ] Security policy in place

## 🚀 Next Steps

1. **Test the deployment**: Run `./deploy.sh` to deploy to GCP
2. **Set up monitoring**: Configure alerting for infrastructure
3. **Documentation**: Keep README.md updated with deployment status
4. **Collaboration**: Invite team members if needed
5. **Backup strategy**: Regular repository mirrors and infrastructure backups

---
*Setup completed on: August 1, 2025*
*Repository strategy: Dual remote (GitHub primary, GitLab secondary)*
*Architecture: Solo developer optimized platform*
