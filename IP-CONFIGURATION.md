# 🌐 IP Configuration Guide

## Before Deployment - Set Your IP Address

Your IP address has been removed from all configuration files for security and portability. Before deploying, you'll need to configure your public IP address.

### 1. Get Your Public IP

```bash
# Option 1: Using curl
curl ifconfig.me

# Option 2: Using dig
dig +short myip.opendns.com @resolver1.opendns.com

# Option 3: Using online service
# Visit: https://whatismyipaddress.com/
```

### 2. Update terraform.tfvars

Edit `/infrastructure/terraform/terraform.tfvars` and replace placeholders:

```hcl
# Replace these with your actual IP
user_ip = "YOUR_PUBLIC_IP_HERE"      # e.g., "203.0.113.123"
admin_ip = "YOUR_PUBLIC_IP_HERE/32"  # e.g., "203.0.113.123/32"
```

### 3. Optional: Restrict Admin Access

For enhanced security, you can uncomment and configure IP restrictions in nginx configs:

**File**: `/infrastructure/docker/nginx/sites-available/keycloak.conf`
```nginx
# Uncomment and set your IP for admin access only
allow YOUR_IP_HERE;  # e.g., allow 203.0.113.123;
deny all;
```

### 4. Why Remove Hardcoded IPs?

✅ **Security**: No personal IPs in version control  
✅ **Portability**: Others can use the configuration  
✅ **Flexibility**: Easy to change IPs without code changes  
✅ **Best Practice**: Configuration should be environment-specific  

### 5. Dynamic IP Considerations

If you have a dynamic IP address:
- Use `0.0.0.0/0` for testing (less secure)
- Consider using a VPN with static IP
- Update firewall rules when IP changes
- Use Cloudflare Access for additional security

### 6. Production Security Recommendations

🔒 **For Production Environments**:
- Use specific IP ranges, not `0.0.0.0/0`
- Enable Cloudflare security features
- Use VPN or bastion host for admin access
- Regularly audit access logs
- Consider additional authentication layers

---

**Next**: Update your IP in `terraform.tfvars` and proceed with deployment! 🚀
