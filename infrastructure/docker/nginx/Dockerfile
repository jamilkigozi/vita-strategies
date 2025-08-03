# Nginx Reverse Proxy
# Production-grade configuration with security best practices
# Supports SSL termination, load balancing, and security headers

FROM nginx:1.25-alpine

# Install security and monitoring tools
RUN apk add --no-cache \
    openssl \
    curl \
    certbot \
    certbot-nginx \
    logrotate

# Create required directories
RUN mkdir -p /var/log/nginx \
    /etc/nginx/ssl \
    /etc/nginx/sites-available \
    /etc/nginx/sites-enabled \
    /var/cache/nginx \
    /var/run/nginx

# Copy configuration files
COPY nginx.conf /etc/nginx/nginx.conf
COPY sites-available/ /etc/nginx/sites-available/
COPY ssl/ /etc/nginx/ssl/

# Create symbolic links for enabled sites
RUN ln -sf /etc/nginx/sites-available/default.conf /etc/nginx/sites-enabled/ && \
    ln -sf /etc/nginx/sites-available/wordpress.conf /etc/nginx/sites-enabled/ && \
    ln -sf /etc/nginx/sites-available/erpnext.conf /etc/nginx/sites-enabled/ && \
    ln -sf /etc/nginx/sites-available/mattermost.conf /etc/nginx/sites-enabled/ && \
    ln -sf /etc/nginx/sites-available/metabase.conf /etc/nginx/sites-enabled/ && \
    ln -sf /etc/nginx/sites-available/grafana.conf /etc/nginx/sites-enabled/ && \
    ln -sf /etc/nginx/sites-available/keycloak.conf /etc/nginx/sites-enabled/ && \
    ln -sf /etc/nginx/sites-available/appsmith.conf /etc/nginx/sites-enabled/ && \
    ln -sf /etc/nginx/sites-available/windmill.conf /etc/nginx/sites-enabled/ && \
    ln -sf /etc/nginx/sites-available/bookstack.conf /etc/nginx/sites-enabled/ && \
    ln -sf /etc/nginx/sites-available/openbao.conf /etc/nginx/sites-enabled/

# Set proper permissions
RUN chown -R nginx:nginx /var/log/nginx /var/cache/nginx /var/run/nginx && \
    chmod -R 755 /etc/nginx/sites-available && \
    chmod -R 644 /etc/nginx/ssl

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:80/health || exit 1

# Expose ports
EXPOSE 80 443

# Start nginx
CMD ["nginx", "-g", "daemon off;"]
