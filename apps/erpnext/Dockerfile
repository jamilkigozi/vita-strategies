# ERPNext Production Container
# Multi-stage build for optimized production deployment

# Stage 1: Base ERPNext with production optimizations
FROM frappe/erpnext:v15.17.0 AS base

# Set environment variables for production
ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1 \
    DEBIAN_FRONTEND=noninteractive \
    FRAPPE_USER=frappe \
    APPS_JSON_BASE64="" \
    COMMON_SITE_CONFIG_JSON=""

# Stage 2: Production optimizations and security hardening
FROM base AS production

# Install additional production dependencies
USER root

# Update system packages and install security tools
RUN apt-get update && apt-get install -y --no-install-recommends \
    # Security and monitoring tools
    fail2ban \
    logrotate \
    supervisor \
    # Database optimization tools
    mysql-client \
    redis-tools \
    # File processing and optimization
    imagemagick \
    ghostscript \
    poppler-utils \
    # Networking and debugging tools
    curl \
    wget \
    netcat \
    # Cleanup
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && rm -rf /tmp/* \
    && rm -rf /var/tmp/*

# Configure ImageMagick security policy for PDF processing
RUN sed -i 's/<policy domain="coder" rights="none" pattern="PDF" \/>/<policy domain="coder" rights="read|write" pattern="PDF" \/>/' /etc/ImageMagick-6/policy.xml

# Install additional Python packages for production
USER frappe
WORKDIR /home/frappe/frappe-bench

# Install production Python dependencies
COPY requirements.txt /tmp/requirements.txt
RUN pip install --user --no-cache-dir -r /tmp/requirements.txt

# Install custom ERPNext applications (if any)
# COPY custom_apps/ ./apps/

# Copy custom configuration files
COPY --chown=frappe:frappe config/ ./config/
COPY --chown=frappe:frappe scripts/ ./scripts/

# Set up log directories with proper permissions
USER root
RUN mkdir -p /var/log/erpnext \
    && chown -R frappe:frappe /var/log/erpnext \
    && chmod 755 /var/log/erpnext

# Configure logrotate for ERPNext logs
COPY logrotate.conf /etc/logrotate.d/erpnext
RUN chmod 644 /etc/logrotate.d/erpnext

# Set up supervisor for process management
COPY supervisor.conf /etc/supervisor/conf.d/erpnext.conf
RUN chmod 644 /etc/supervisor/conf.d/erpnext.conf

# Create health check script
COPY --chown=frappe:frappe healthcheck.sh /home/frappe/healthcheck.sh
RUN chmod +x /home/frappe/healthcheck.sh

# Create backup script
COPY --chown=frappe:frappe backup.sh /home/frappe/backup.sh
RUN chmod +x /home/frappe/backup.sh

# Switch back to frappe user
USER frappe

# Copy custom entrypoint script
COPY --chown=frappe:frappe docker-entrypoint.sh /home/frappe/docker-entrypoint.sh
RUN chmod +x /home/frappe/docker-entrypoint.sh

# Configure production site settings
ENV DEVELOPER_MODE=0 \
    ADMIN_PASSWORD="" \
    ENCRYPTION_KEY="" \
    DB_HOST="" \
    DB_PORT=3306 \
    DB_NAME="" \
    DB_USER="" \
    DB_PASSWORD="" \
    REDIS_CACHE="redis://redis:6379/0" \
    REDIS_QUEUE="redis://redis:6379/1" \
    REDIS_SOCKETIO="redis://redis:6379/2" \
    MAIL_SERVER="" \
    MAIL_PORT=587 \
    MAIL_USE_TLS=1 \
    MAIL_USERNAME="" \
    MAIL_PASSWORD="" \
    SITE_NAME="erp.vitastrategies.com" \
    FORCE_HTTPS=1 \
    AUTO_MIGRATE=1 \
    BACKUP_SCHEDULE="0 2 * * *"

# Set up working directory
WORKDIR /home/frappe/frappe-bench

# Health check configuration
HEALTHCHECK --interval=30s --timeout=15s --start-period=60s --retries=3 \
    CMD /home/frappe/healthcheck.sh

# Expose port for ERPNext application
EXPOSE 8000

# Set entrypoint
ENTRYPOINT ["/home/frappe/docker-entrypoint.sh"]

# Default command
CMD ["supervisord", "-c", "/etc/supervisor/supervisord.conf"]

# Labels for container metadata
LABEL maintainer="Vita Strategies <admin@vitastrategies.com>" \
      version="15.17.0" \
      description="Production ERPNext container with security hardening and performance optimizations" \
      org.opencontainers.image.title="ERPNext Production" \
      org.opencontainers.image.description="Enterprise Resource Planning system for Vita Strategies" \
      org.opencontainers.image.version="15.17.0" \
      org.opencontainers.image.vendor="Vita Strategies" \
      org.opencontainers.image.url="https://erp.vitastrategies.com" \
      org.opencontainers.image.documentation="https://docs.erpnext.com" \
      org.opencontainers.image.source="https://github.com/frappe/erpnext"
