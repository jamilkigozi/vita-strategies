# 🚀 Developer Onboarding - Vita Strategies Platform

Welcome to the Vita Strategies team! This guide will get you up and running with our professional business platform.

## 🎯 **What You're Joining**

### **Company**: Vita Strategies
**Industry**: Health & Social Care Consultancy  
**Platform**: 8-service enterprise business platform  
**Architecture**: Docker-based microservices on GCP  
**Your Role**: Platform development and team scaling support

### **Platform Overview**
You're working with a **production-ready business platform** that manages:
- Client relationships (ERPNext)
- Team authentication (Keycloak)
- Workflow automation (Windmill)
- Team communication (Mattermost)
- Business analytics (Metabase)
- System monitoring (Grafana)
- Internal apps (Appsmith)
- Secrets management (Openbao)

## 📋 **Day 1: Getting Started**

### **Step 1: Access & Credentials**
1. Get access to the Git repository: `vita-strategies`
2. Request access to `CREDENTIALS.md` (contains all service passwords)
3. Get GCP project access: `mystical-slate-463221-j0`
4. Domain access: `vitastrategies.com` (Cloudflare managed)

### **Step 2: Local Development Setup**
```bash
# Clone the repository
git clone https://github.com/jamilkigozi/vita-strategies.git
cd vita-strategies

# Quick development environment
./scripts/deploy-platform.sh development

# All services will be available at localhost:PORT
# Check the output for specific URLs and ports
```

### **Step 3: Understanding the Architecture**
```
Production Infrastructure:
├── GCP VM (34.39.85.103) - Single e2-standard-4 instance
├── Cloudflare - SSL termination and CDN
├── Docker Compose - Service orchestration
└── Nginx - Reverse proxy routing
```

## 🏗️ **Repository Structure (Industry Standard)**

```
vita-strategies/
├── applications/           # 🚀 Current working services
│   ├── docker-compose-complete.yml  # All 8 services
│   ├── nginx-complete.conf         # Reverse proxy config
│   └── docker-compose.yml          # Legacy (4 services)
├── infrastructure/        # 🏗️ Infrastructure as Code
│   ├── terraform/         # GCP resource definitions
│   └── startup-scripts/   # VM initialization
├── environments/          # 🌍 Environment-specific configs
│   ├── development/       # Local development
│   ├── staging/          # Future staging environment
│   └── production/       # Live production
├── scripts/              # 🛠️ Automation scripts
│   └── deploy-platform.sh # Main deployment script
├── docs/                 # 📚 Documentation
└── CREDENTIALS.md        # 🔐 Secure credential reference
```

## 🛠️ **Day 2-3: Understanding the Services**

### **Core Business Services**
| Service | Purpose | Your Focus |
|---------|---------|------------|
| **ERPNext** | Business management (CRM, accounts, inventory) | Client & financial data |
| **Keycloak** | Single sign-on authentication | User management & security |
| **Windmill** | Workflow automation | Business process automation |
| **Mattermost** | Team communication | Internal collaboration |

### **Development & Analytics Services**
| Service | Purpose | Your Focus |
|---------|---------|------------|
| **Metabase** | Business intelligence | Data insights & reporting |
| **Grafana** | System monitoring | Performance & health monitoring |
| **Appsmith** | Internal app builder | Custom business applications |
| **Openbao** | Secrets management | Security & credential storage |

## 🎯 **Week 1: First Tasks**

### **Monday**: Environment Familiarization
- [ ] Get all services running locally
- [ ] Log into each service using credentials from `CREDENTIALS.md`
- [ ] Understand the data flow between services

### **Tuesday**: Production Access
- [ ] Get GCP access and SSH to production VM
- [ ] Understand the production deployment process
- [ ] Review current service status and logs

### **Wednesday**: Code Deep Dive
- [ ] Review Docker Compose configurations
- [ ] Understand Nginx routing rules
- [ ] Study the deployment automation

### **Thursday**: First Contribution
- [ ] Identify a small improvement or documentation update
- [ ] Make your first pull request
- [ ] Get familiar with the Git workflow

### **Friday**: Planning & Feedback
- [ ] Meet with Jamil to discuss observations
- [ ] Plan upcoming features and improvements
- [ ] Set goals for the next sprint

## 🔧 **Common Development Tasks**

### **Starting Local Development**
```bash
# Start all services
./scripts/deploy-platform.sh development

# Check service status
docker-compose -f applications/docker-compose-complete.yml ps

# View logs for a specific service
docker-compose -f applications/docker-compose-complete.yml logs erpnext
```

### **Deploying to Production**
```bash
# Deploy to GCP (requires permissions)
./scripts/deploy-platform.sh production

# SSH to production server
gcloud compute ssh vita-strategies-server --zone=europe-west2-a
```

### **Troubleshooting**
```bash
# Check all container status
docker ps

# View logs for failing service
docker logs [container_name]

# Restart a specific service
docker-compose restart [service_name]
```

## 🔐 **Security Guidelines**

### **Credential Management**
- **Never commit passwords** to Git
- Use `CREDENTIALS.md` for reference (keep secure)
- Rotate API keys quarterly
- Enable 2FA on all services

### **Development Best Practices**
- Always work in feature branches
- Test locally before production deployment
- Use environment variables for configuration
- Follow Docker best practices

## 📈 **Growth Roadmap**

### **Phase 1 (Current)**: Service Stability
- Get all 8 services running reliably
- Implement proper monitoring and alerting
- Document all processes

### **Phase 2 (Next 3 months)**: Infrastructure as Code
- Migrate to full Terraform deployment
- Implement CI/CD pipelines
- Add automated testing

### **Phase 3 (6+ months)**: Scale for Team Growth
- Kubernetes migration planning
- Advanced security implementation
- Performance optimization

## 🤝 **Team Communication**

### **Daily Communication**
- **Mattermost**: https://chat.vitastrategies.com (team chat)
- **Email**: jamil.kigozi@hotmail.com (urgent issues)

### **Documentation**
- **Architecture**: `docs/ARCHITECTURE.md`
- **DevOps Journey**: `docs/DEVOPS_JOURNEY.md`
- **Troubleshooting**: `docs/TROUBLESHOOTING.md`

### **Code Reviews**
- All changes go through pull requests
- Focus on security, performance, and maintainability
- Document any architectural decisions

## 🎉 **What Makes This Special**

You're joining a **professional-grade platform** that's built with:
- ✅ Industry-standard file organization
- ✅ Proper environment separation
- ✅ Automated deployment scripts
- ✅ Comprehensive documentation
- ✅ Security-first approach
- ✅ Scalability planning

**This isn't just a startup project** - it's a properly architected business platform that's ready for team growth and scale.

---

**Welcome to the team! 🚀**

*Any questions? Reach out to Jamil immediately - he's committed to your success and wants you to be productive from day one.*
