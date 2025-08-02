#!/bin/bash

# SSL Setup Script for Vita Strategies Platform using Cloudflare
# This script sets up SSL certificates using Cloudflare's Universal SSL

set -e

# Configuration
DOMAIN="vitastrategies.com"
EXTERNAL_IP="34.39.85.103"
CLOUDFLARE_EMAIL="${CLOUDFLARE_EMAIL}"
CLOUDFLARE_API_KEY="${CLOUDFLARE_API_KEY}"

# Subdomains to configure
SUBDOMAINS=(
    "erp"
    "windmill" 
    "auth"
    "analytics"
    "apps"
    "chat"
    "monitoring"
    "vault"
)

echo "🔒 Setting up SSL configuration for Cloudflare Universal SSL..."

# Check if running on GCP instance
if [[ $(curl -s -H "Metadata-Flavor: Google" http://metadata.google.internal/computeMetadata/v1/instance/name 2>/dev/null) ]]; then
    echo "✅ Running on GCP instance"
    IS_GCP=true
else
    echo "ℹ️  Running locally"
    IS_GCP=false
fi

# Create SSL directory
mkdir -p ./nginx/ssl

# Since you're using Cloudflare, we'll create a self-signed cert for the backend
# Cloudflare will handle the actual SSL termination
echo "🔐 Creating backend SSL certificate for Cloudflare..."

# Generate private key
openssl genrsa -out ./nginx/ssl/$DOMAIN.key 2048

# Generate certificate signing request
openssl req -new -key ./nginx/ssl/$DOMAIN.key -out ./nginx/ssl/$DOMAIN.csr -subj "/C=US/ST=CA/L=SF/O=VitaStrategies/CN=*.$DOMAIN"

# Generate self-signed certificate (Cloudflare will present the real one)
openssl x509 -req -days 365 -in ./nginx/ssl/$DOMAIN.csr -signkey ./nginx/ssl/$DOMAIN.key -out ./nginx/ssl/$DOMAIN.crt

# Set proper permissions
chmod 644 ./nginx/ssl/$DOMAIN.crt
chmod 600 ./nginx/ssl/$DOMAIN.key

# Clean up CSR
rm ./nginx/ssl/$DOMAIN.csr

echo "✅ Backend SSL certificates created!"
echo ""
echo "🌐 Cloudflare Configuration Required:"
echo ""
echo "1. Log into Cloudflare Dashboard"
echo "2. Go to your domain: $DOMAIN"
echo "3. Navigate to SSL/TLS → Overview"
echo "4. Set SSL/TLS encryption mode to 'Full (strict)'"
echo "5. Navigate to DNS → Records"
echo "6. Ensure these A records point to $EXTERNAL_IP:"
echo "   - $DOMAIN"
for subdomain in "${SUBDOMAINS[@]}"; do
    echo "   - $subdomain.$DOMAIN"
done
echo ""
echo "7. Navigate to SSL/TLS → Edge Certificates"
echo "8. Enable 'Always Use HTTPS'"
echo "9. Enable 'HTTP Strict Transport Security (HSTS)'"
echo ""
echo "🚀 After Cloudflare configuration, your services will be available at:"
for subdomain in "${SUBDOMAINS[@]}"; do
    echo "  - https://$subdomain.$DOMAIN"
done
echo "  - https://$DOMAIN (redirects to ERPNext)"
echo ""
echo "⚠️  Important: With Cloudflare Universal SSL:"
echo "   - SSL termination happens at Cloudflare"
echo "   - Traffic from Cloudflare to your server is encrypted with the backend cert"
echo "   - No need for Let's Encrypt when using Cloudflare"

# Create Cloudflare configuration script
cat << 'EOF' > ./cloudflare-config.sh
#!/bin/bash

# Cloudflare DNS Configuration Script
# Run this to automatically configure DNS records via API

DOMAIN="vitastrategies.com"
EXTERNAL_IP="34.39.85.103"
CLOUDFLARE_EMAIL="${CLOUDFLARE_EMAIL}"
CLOUDFLARE_API_KEY="${CLOUDFLARE_API_KEY}"

if [[ -z "$CLOUDFLARE_EMAIL" || -z "$CLOUDFLARE_API_KEY" ]]; then
    echo "❌ Error: Set CLOUDFLARE_EMAIL and CLOUDFLARE_API_KEY environment variables"
    exit 1
fi

# Get Zone ID
ZONE_ID=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones?name=$DOMAIN" \
     -H "X-Auth-Email: $CLOUDFLARE_EMAIL" \
     -H "X-Auth-Key: $CLOUDFLARE_API_KEY" \
     -H "Content-Type: application/json" | jq -r '.result[0].id')

if [[ "$ZONE_ID" == "null" ]]; then
    echo "❌ Error: Could not find zone for $DOMAIN"
    exit 1
fi

echo "✅ Found zone ID: $ZONE_ID"

# Create/update DNS records
SUBDOMAINS=("@" "erp" "windmill" "auth" "analytics" "apps" "chat" "monitoring" "vault")

for subdomain in "${SUBDOMAINS[@]}"; do
    if [[ "$subdomain" == "@" ]]; then
        record_name="$DOMAIN"
        display_name="$DOMAIN"
    else
        record_name="$subdomain.$DOMAIN"
        display_name="$subdomain"
    fi
    
    echo "🔄 Creating/updating DNS record for $display_name..."
    
    curl -s -X POST "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records" \
         -H "X-Auth-Email: $CLOUDFLARE_EMAIL" \
         -H "X-Auth-Key: $CLOUDFLARE_API_KEY" \
         -H "Content-Type: application/json" \
         --data '{
           "type": "A",
           "name": "'$record_name'",
           "content": "'$EXTERNAL_IP'",
           "ttl": 300,
           "proxied": true
         }' > /dev/null
    
    echo "✅ DNS record for $display_name configured"
done

echo ""
echo "🎉 All DNS records configured!"
echo "🌐 Cloudflare proxy enabled for all subdomains"
EOF

chmod +x ./cloudflare-config.sh

echo ""
echo "📝 Configuration files created:"
echo "  - ./nginx/ssl/$DOMAIN.crt (backend certificate)"
echo "  - ./nginx/ssl/$DOMAIN.key (private key)"
echo "  - ./cloudflare-config.sh (DNS configuration script)"
echo ""
echo "🔧 Next steps:"
echo "1. Set your Cloudflare credentials:"
echo "   export CLOUDFLARE_EMAIL='your-email@domain.com'"
echo "   export CLOUDFLARE_API_KEY='your-api-key'"
echo "2. Run: ./cloudflare-config.sh (optional - for automated DNS setup)"
echo "3. Start services: docker-compose up -d"
