# 🌐 DNS Configuration for Vita Strategies Platform

## Overview
This document outlines the DNS configuration required for the Vita Strategies business platform. All DNS records are managed through Cloudflare.

## 🎯 **CRITICAL: YOU NEED TO SET UP THESE DNS RECORDS**

### **Required Cloudflare DNS Records**

**Log into Cloudflare Dashboard → vitastrategies.com → DNS → Records**

| Type | Name | Content | Proxy Status | TTL |
|------|------|---------|--------------|-----|
| A | erp | 34.39.85.103 | 🟠 Proxied | Auto |
| A | auth | 34.39.85.103 | 🟠 Proxied | Auto |
| A | workflows | 34.39.85.103 | 🟠 Proxied | Auto |
| A | chat | 34.39.85.103 | 🟠 Proxied | Auto |
| A | analytics | 34.39.85.103 | 🟠 Proxied | Auto |
| A | monitoring | 34.39.85.103 | 🟠 Proxied | Auto |
| A | apps | 34.39.85.103 | 🟠 Proxied | Auto |
| A | vault | 34.39.85.103 | 🟠 Proxied | Auto |

### **Service Mapping**
- **erp.vitastrategies.com** → ERPNext (Business Management)
- **auth.vitastrategies.com** → Keycloak (Authentication)
- **workflows.vitastrategies.com** → Windmill (Workflow Automation)
- **chat.vitastrategies.com** → Mattermost (Team Communication)
- **analytics.vitastrategies.com** → Metabase (Business Analytics)
- **monitoring.vitastrategies.com** → Grafana (System Monitoring)
- **apps.vitastrategies.com** → Appsmith (App Development)
- **vault.vitastrategies.com** → Openbao (Secrets Management)

## 🔧 **Setup Instructions for Jamil**

### **Step 1: Access Cloudflare**
1. Go to [dash.cloudflare.com](https://dash.cloudflare.com)
2. Login with: jamil.kigozi@hotmail.com
3. Select the `vitastrategies.com` domain

### **Step 2: Add DNS Records**
1. Click "DNS" in the left sidebar
2. Click "Add record" for each service above
3. Set Proxy status to "Proxied" (🟠 orange cloud)
4. Save each record

### **Step 3: SSL Configuration**
1. Go to SSL/TLS → Overview
2. Set encryption mode to "Flexible"
3. Enable "Always Use HTTPS"
4. Enable "Automatic HTTPS Rewrites"

### **Step 4: Security Settings**
1. Go to Security → Settings
2. Set Security Level to "Medium"
3. Enable "Browser Integrity Check"
4. Configure Bot Fight Mode

## ✅ **Verification Commands**

After setting up DNS records, verify they work:

```bash
# Test DNS resolution
nslookup erp.vitastrategies.com
nslookup auth.vitastrategies.com
nslookup workflows.vitastrategies.com
nslookup chat.vitastrategies.com
nslookup analytics.vitastrategies.com
nslookup monitoring.vitastrategies.com
nslookup apps.vitastrategies.com
nslookup vault.vitastrategies.com

# Test HTTPS access (after services are running)
curl -I https://erp.vitastrategies.com
curl -I https://analytics.vitastrategies.com
```

## 🚨 **Current Status**

- **IP Address**: 34.39.85.103 (GCP VM)
- **DNS Provider**: Cloudflare
- **SSL**: Managed by Cloudflare
- **Records Added**: ❌ **NEEDS TO BE DONE BY JAMIL**

## 📋 **Post-Setup Checklist**

After adding DNS records:
- [ ] All 8 DNS records point to 34.39.85.103
- [ ] All records are "Proxied" (orange cloud)
- [ ] SSL is set to "Flexible" mode
- [ ] "Always Use HTTPS" is enabled
- [ ] Services are accessible via HTTPS

---

**⚠️ Important**: DNS changes can take up to 24 hours to propagate globally, but Cloudflare is usually much faster (5-10 minutes).