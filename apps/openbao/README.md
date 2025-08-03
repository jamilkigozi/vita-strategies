# OpenBao - Open-Source Secrets Management Platform

## 🔐 Overview

OpenBao is a powerful, open-source secrets management platform that provides secure storage, access control, and dynamic secrets generation for modern applications. This containerized deployment provides a production-ready OpenBao instance with enterprise-grade security, high availability, and comprehensive integration capabilities.

## 🚀 Key Features

### Secrets Management
- **Static Secrets Storage** - Secure key-value storage with versioning and rollback
- **Dynamic Secrets** - Generate database credentials, API keys, and certificates on-demand
- **Encryption as a Service** - Encrypt/decrypt data without storing encryption keys
- **Secret Leasing** - Automatic secret rotation and expiration policies
- **Audit Logging** - Complete access and operation audit trails
- **Transit Secrets** - Encryption and signing without exposing keys
- **PKI Management** - Certificate authority and certificate lifecycle management

### Authentication & Authorization
- **Multi-auth Methods** - Username/password, LDAP, JWT, Kubernetes, cloud providers
- **Fine-grained Policies** - Path-based access control with conditions
- **Identity Groups** - Role-based access control with group inheritance
- **MFA Support** - Multi-factor authentication for sensitive operations
- **Token Management** - Token lifecycle, renewal, and revocation
- **External Identity** - Integration with external identity providers
- **Namespace Support** - Multi-tenancy with isolated environments

### Enterprise Features
- **High Availability** - Active-passive clustering with automatic failover
- **Disaster Recovery** - Cross-region replication and backup strategies
- **Performance Standby** - Read-only replicas for scaling read operations
- **Enterprise Replication** - Multi-datacenter secret synchronization
- **Seal/Unseal** - Secure initialization and master key management
- **Auto-unseal** - Cloud KMS integration for automatic unsealing
- **HSM Support** - Hardware security module integration

### Integration Capabilities
- **Database Secrets** - Dynamic credentials for PostgreSQL, MySQL, MongoDB
- **Cloud Secrets** - AWS, GCP, Azure credentials and permissions
- **API Integration** - RESTful API with comprehensive SDK support
- **Kubernetes Integration** - CSI driver and operator for K8s deployments
- **CI/CD Integration** - GitHub Actions, GitLab CI, Jenkins plugins
- **Application Integration** - SDKs for Python, Go, Java, .NET, Node.js
- **Monitoring Integration** - Prometheus metrics and logging integrations

## 🔧 Technical Architecture

### Core Components
- **OpenBao Server** - Main secrets management engine with API
- **Storage Backend** - PostgreSQL for persistent secret storage
- **Seal Configuration** - Auto-unseal with Google Cloud KMS
- **Audit Device** - File-based audit logging with rotation
- **Agent Mode** - Optional agent for caching and auto-auth
- **UI Interface** - Web-based management console

### Security Features
- **Zero-Trust Architecture** - All requests authenticated and authorized
- **End-to-End Encryption** - Secrets encrypted at rest and in transit
- **Perfect Forward Secrecy** - Key rotation and forward secrecy
- **Secure Communication** - TLS 1.3 for all API communications
- **Principle of Least Privilege** - Minimal access permissions by default
- **Defense in Depth** - Multiple security layers and controls
- **Compliance Ready** - SOC 2, FIPS 140-2, Common Criteria support

### Performance Optimizations
- **In-Memory Caching** - Frequently accessed secrets cached securely
- **Connection Pooling** - Efficient database connection management
- **Batch Operations** - Bulk secret operations for performance
- **Compression** - Response compression for large payloads
- **CDN Integration** - Static asset delivery via Cloudflare
- **Horizontal Scaling** - Multiple server instances with load balancing

## 📊 Integration Points

### Database Integration
- **Primary Storage:** `vita_openbao_db` (PostgreSQL on Cloud SQL)
- **Connection:** Secure private IP with SSL enforcement
- **High Availability:** Multi-zone deployment with automatic failover
- **Backup Strategy:** Encrypted daily backups with point-in-time recovery
- **Performance:** Optimized for high-frequency read/write operations

### Storage Integration
- **Backup Storage:** `vita-openbao-storage` GCS bucket for backups
- **Audit Logs:** `vita-audit-storage` for long-term audit retention
- **PKI Storage:** Certificate and key material secure storage
- **Policy Storage:** Access control policies and configurations

### Cloud Integration
- **Auto-Unseal:** Google Cloud KMS for secure master key management
- **Secret Engines:** GCP, AWS, Azure dynamic credential generation
- **Identity Integration:** Google Cloud IAM, Azure AD, AWS IAM
- **Monitoring:** Cloud Operations integration for metrics and logs

### Application Integration
- **WordPress Integration:** Database credentials and API keys
- **Mattermost Integration:** LDAP passwords and webhook secrets
- **ERPNext Integration:** Database credentials and encryption keys
- **Windmill Integration:** API tokens and service account keys
- **Nginx Integration:** TLS certificates and private keys

## 🌐 Access & URLs

### Production URLs
- **Main Interface:** https://vault.vitastrategies.com
- **API Endpoint:** https://vault.vitastrategies.com/v1
- **Health Check:** https://vault.vitastrategies.com/v1/sys/health
- **Metrics:** https://vault.vitastrategies.com/v1/sys/metrics

### Development URLs
- **Local Development:** http://localhost:8200
- **API Testing:** http://localhost:8200/v1
- **Local UI:** http://localhost:8200/ui

## 🔑 Initial Configuration

### Root Token Setup
- **Initial Root Token:** Generated during initialization
- **Root Token Rotation:** Automated rotation every 90 days
- **Emergency Access:** Break-glass procedures documented
- **Backup Tokens:** Secure offline storage of recovery keys

### Default Policies
- **Admin Policy:** Full administrative access
- **Read-Only Policy:** Read access to non-sensitive paths
- **Application Policies:** Service-specific access controls
- **Emergency Policy:** Limited break-glass access

### Secret Engines
- **KV v2:** Versioned key-value secrets storage
- **Database:** Dynamic database credential generation
- **PKI:** Certificate authority and certificate management
- **Transit:** Encryption and signing operations
- **Identity:** External identity provider integration
- **Cloud Engines:** AWS, GCP, Azure credential generation

## 🚀 Deployment Options

### Production Deployment (Recommended)
```bash
# Deploy with main infrastructure
cd /Users/millz./vita-strategies/infrastructure/terraform
terraform apply

# Start OpenBao service
cd ../docker
docker-compose up -d openbao
```

### Standalone Development
```bash
# Run OpenBao independently for development
cd /Users/millz./vita-strategies/apps/openbao
docker-compose up -d

# Access at http://localhost:8200
# Initialize with recovery keys
```

### High Availability Deployment
```bash
# Deploy clustered OpenBao with automatic failover
cd /Users/millz./vita-strategies/infrastructure/docker
docker-compose up -d openbao-cluster

# Verify cluster status and leader election
```

## 📋 Initial Setup Checklist

### Pre-deployment
- [ ] Verify PostgreSQL Cloud SQL instance is running
- [ ] Confirm Google Cloud KMS key is created
- [ ] Check DNS configuration for vault.vitastrategies.com
- [ ] Validate SSL certificates are available
- [ ] Configure firewall rules for OpenBao ports

### Post-deployment
- [ ] Initialize OpenBao cluster
- [ ] Configure auto-unseal with Google Cloud KMS
- [ ] Set up audit logging
- [ ] Create initial policies and roles
- [ ] Configure secret engines (KV, Database, PKI)
- [ ] Set up authentication methods
- [ ] Test secret retrieval and policy enforcement
- [ ] Configure backup and disaster recovery

## 🔧 Secret Engine Configuration

### Key-Value Secrets (KV v2)
```bash
# Enable KV v2 engine
openbao secrets enable -version=2 kv

# Create application secrets
openbao kv put kv/wordpress db_password="secure_password"
openbao kv put kv/mattermost api_key="secret_api_key"
openbao kv put kv/erpnext encryption_key="encryption_secret"
```

### Database Engine
```bash
# Enable database engine
openbao secrets enable database

# Configure PostgreSQL connection
openbao write database/config/postgresql \
    plugin_name=postgresql-database-plugin \
    connection_url="postgresql://{{username}}:{{password}}@db:5432/postgres" \
    allowed_roles="readonly,readwrite"

# Create role for read-only access
openbao write database/roles/readonly \
    db_name=postgresql \
    creation_statements="CREATE ROLE \"{{name}}\" WITH LOGIN PASSWORD '{{password}}' VALID UNTIL '{{expiration}}'; GRANT SELECT ON ALL TABLES IN SCHEMA public TO \"{{name}}\";" \
    default_ttl="1h" \
    max_ttl="24h"
```

### PKI Engine
```bash
# Enable PKI engine
openbao secrets enable pki

# Configure CA certificate
openbao write pki/root/generate/internal \
    common_name="Vita Strategies Root CA" \
    ttl=87600h

# Configure certificate role
openbao write pki/roles/vitastrategies-dot-com \
    allowed_domains="vitastrategies.com" \
    allow_subdomains=true \
    max_ttl="72h"
```

## 👥 Authentication Methods

### Username/Password
```bash
# Enable userpass auth
openbao auth enable userpass

# Create admin user
openbao write auth/userpass/users/admin \
    password="secure_admin_password" \
    policies="admin"

# Create application users
openbao write auth/userpass/users/wordpress \
    password="wordpress_password" \
    policies="wordpress-policy"
```

### JWT/OIDC (Keycloak Integration)
```bash
# Enable JWT auth for Keycloak integration
openbao auth enable jwt

# Configure Keycloak OIDC
openbao write auth/jwt/config \
    oidc_discovery_url="https://auth.vitastrategies.com/realms/vita-strategies" \
    oidc_client_id="openbao" \
    oidc_client_secret="keycloak_client_secret"

# Create role for authenticated users
openbao write auth/jwt/role/authenticated \
    bound_audiences="openbao" \
    user_claim="sub" \
    role_type="jwt" \
    policies="authenticated-policy" \
    ttl=1h
```

### Kubernetes Service Account
```bash
# Enable Kubernetes auth (for future K8s deployment)
openbao auth enable kubernetes

# Configure Kubernetes auth
openbao write auth/kubernetes/config \
    token_reviewer_jwt="<service_account_jwt>" \
    kubernetes_host="https://kubernetes.default.svc:443" \
    kubernetes_ca_cert="<ca_cert>"
```

## 📊 Monitoring & Observability

### Health Monitoring
- **Health Endpoints** - Cluster health and individual node status
- **Performance Metrics** - Request latency, throughput, and error rates
- **Resource Monitoring** - CPU, memory, and storage utilization
- **Audit Analysis** - Access patterns and security events
- **Backup Verification** - Automated backup testing and validation

### Integration with Monitoring Stack
- **Prometheus Metrics** - Detailed operational metrics
- **Grafana Dashboards** - Visual monitoring and alerting
- **Log Aggregation** - Centralized logging with ELK stack
- **Alert Manager** - Automated incident response
- **Status Page** - Public status and incident communication

### Security Monitoring
- **Failed Authentication** - Suspicious login attempts
- **Policy Violations** - Unauthorized access attempts
- **Unusual Patterns** - Anomaly detection and alerting
- **Compliance Reporting** - SOC 2 and audit trail reports
- **Incident Response** - Automated security response workflows

## 🔐 Security Best Practices

### Access Control
- **Principle of Least Privilege** - Minimal required permissions
- **Regular Access Reviews** - Quarterly permission audits
- **MFA Enforcement** - Multi-factor authentication for all admin access
- **IP Restrictions** - Network-based access controls
- **Time-based Access** - Temporary elevated permissions

### Key Management
- **Regular Rotation** - Automated key and credential rotation
- **Secure Generation** - Cryptographically secure random generation
- **Separation of Duties** - Multiple approvals for sensitive operations
- **Offline Storage** - Air-gapped backup of critical keys
- **Hardware Security** - HSM integration for high-value keys

### Operational Security
- **Immutable Audit Logs** - Tamper-proof audit trail
- **Encrypted Communication** - TLS 1.3 for all communications
- **Regular Penetration Testing** - Third-party security assessments
- **Vulnerability Management** - Automated scanning and patching
- **Incident Response Plan** - Documented security incident procedures

## 🔄 Backup & Disaster Recovery

### Backup Strategy
- **Automated Daily Backups** - Encrypted snapshots to GCS
- **Cross-Region Replication** - Geographic distribution for resilience
- **Point-in-Time Recovery** - Recovery to any point in the last 30 days
- **Incremental Backups** - Efficient storage utilization
- **Backup Testing** - Automated restore testing monthly

### Disaster Recovery
- **RTO Target:** 4 hours (Recovery Time Objective)
- **RPO Target:** 1 hour (Recovery Point Objective)
- **Hot Standby:** Secondary region with real-time replication
- **Automated Failover** - Health-check based automatic switching
- **Communication Plan** - Stakeholder notification procedures

### Business Continuity
- **Service Dependencies** - Documented dependency mapping
- **Degraded Mode Operation** - Critical function preservation
- **Manual Override Procedures** - Emergency access protocols
- **Recovery Validation** - Post-incident system verification
- **Lessons Learned** - Post-incident improvement process

## 📞 Support & Documentation

### Official Resources
- **Documentation:** https://openbao.org/docs
- **Community Forum:** https://discuss.openbao.org
- **GitHub Repository:** https://github.com/openbao/openbao

### Internal Support
- **Technical Documentation** - Complete setup and operation guides
- **Runbooks** - Step-by-step operational procedures
- **Troubleshooting Guides** - Common issues and solutions
- **API Integration Examples** - Code samples for all supported languages
- **Policy Templates** - Pre-configured security policies
- **Training Materials** - User and administrator training content

### Emergency Procedures
- **Break-Glass Access** - Emergency access procedures
- **Key Recovery** - Master key recovery from escrow
- **Incident Response** - Security incident handling
- **Escalation Procedures** - Contact information and escalation paths
- **Communication Templates** - Pre-approved incident communications

---

**OpenBao provides the critical security foundation for Vita Strategies, ensuring that all secrets, credentials, and sensitive data across WordPress, Mattermost, ERPNext, Windmill, and future services are managed with enterprise-grade security, compliance, and operational excellence.**
