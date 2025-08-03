# Compute.tf Requirements Assessment

## 🔍 **Information Needed for compute.tf**

### ✅ **Already Have:**
- ✅ Machine type: e2-standard-4 (4 vCPUs, 16GB RAM)
- ✅ Region/Zone: europe-west2-c
- ✅ Boot image: Ubuntu 22.04 LTS
- ✅ Disk size: 50GB
- ✅ SSH key: Your ed25519 key
- ✅ Network: Existing vita-strategies-vpc
- ✅ Firewall: Security groups defined
- ✅ External IP: Static IP reservation

### ❓ **Need to Clarify:**

#### **1. Startup Script Strategy**
For individual containers + bucket mounting, we need to decide:
- **Docker Installation:** Standard Docker CE or Docker with specific version?
- **Service Management:** systemd services or Docker restart policies?
- **Bucket Mounting:** gcsfuse for bucket mounting or docker volumes?

#### **2. Service User Configuration**
- **User Account:** Run services as root, docker user, or dedicated service user?
- **Permissions:** Service account access for bucket mounting?

#### **3. Data Persistence Strategy**
Since you want bucket mounting instead of local volumes:
- **gcsfuse:** Mount buckets as filesystem directories?
- **Backup Strategy:** Local cache + bucket sync, or direct bucket access?
- **Performance:** Cache locally and sync, or real-time bucket access?

#### **4. Container Deployment Method**
Since you want individual containers (not Docker Compose):
- **Docker Run Commands:** Individual docker run scripts?
- **Container Restart:** Docker restart policies or systemd services?
- **Service Discovery:** How containers communicate (bridge network, host network)?

### 🎯 **RECOMMENDED DEFAULTS** (if you want to proceed quickly):

#### **Startup Script:**
```bash
# Install Docker CE (latest stable)
# Install gcsfuse for bucket mounting  
# Create service user 'appuser'
# Mount buckets to /mnt/buckets/
# Install systemd service files for each microservice
```

#### **Bucket Mounting Strategy:**
```bash
# Mount each bucket to specific directory:
/mnt/vita-strategies-erpnext-production     → ERPNext data
/mnt/vita-strategies-analytics-production   → Metabase data
/mnt/vita-strategies-wordpress-production   → WordPress data
/mnt/vita-strategies-assets-production      → Shared assets
/mnt/vita-strategies-data-backup-production → Backups
```

#### **Container Management:**
```bash
# Individual systemd services for each container
# Docker bridge network for internal communication
# Environment files for configuration
# Auto-restart on failure
```

## ❓ **QUESTIONS FOR YOU:**

1. **Bucket Mounting:** Use gcsfuse (mount buckets as folders) or docker volume sync?

2. **Service Management:** Systemd services for containers or just Docker restart policies?

3. **User Security:** Run containers as dedicated 'appuser' or docker user?

4. **Container Network:** Bridge network (containers talk to each other) or host network (simpler but less secure)?

## 🚀 **OR USE RECOMMENDED DEFAULTS?**

If you want to proceed with best practices, I can use the recommended defaults above and build compute.tf now. You can always adjust later.

**Should I:**
- A) **Proceed with recommended defaults** (gcsfuse + systemd + bridge network)
- B) **Answer the 4 questions first** for custom configuration
