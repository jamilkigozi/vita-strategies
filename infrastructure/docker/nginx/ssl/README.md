# SSL Certificate Placeholder
# This is a self-signed certificate for development
# In production, replace with Cloudflare Origin Certificate

# Generate self-signed certificate for development:
# openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
#   -keyout vitastrategies.com.key \
#   -out vitastrategies.com.crt \
#   -subj "/C=US/ST=State/L=City/O=Vita Strategies/CN=vitastrategies.com"

# For production, use Cloudflare Origin Certificate:
# 1. Go to Cloudflare Dashboard > SSL/TLS > Origin Server
# 2. Create certificate for *.vitastrategies.com
# 3. Save as vitastrategies.com.crt and vitastrategies.com.key
# 4. Replace these placeholder files

PLACEHOLDER_CERTIFICATE=true
PRODUCTION_READY=false

# Certificate should cover:
# - vitastrategies.com
# - *.vitastrategies.com (wildcard for all subdomains)
