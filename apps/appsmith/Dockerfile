# Multi-stage Dockerfile for Appsmith Internal Tools Platform
# Optimized for production deployment with security hardening

# Build stage for custom plugins and configurations
FROM node:18-alpine AS builder

# Set working directory
WORKDIR /build

# Install build dependencies
RUN apk add --no-cache \
    git \
    python3 \
    make \
    g++ \
    curl \
    bash

# Copy package files for dependency installation
COPY package*.json ./
RUN npm ci --only=production && npm cache clean --force

# Copy custom widget sources
COPY widgets/ ./widgets/
COPY scripts/build-widgets.sh ./scripts/

# Build custom widgets
RUN chmod +x ./scripts/build-widgets.sh && \
    ./scripts/build-widgets.sh

# Production stage
FROM appsmith/appsmith-ce:v1.9.50

# Switch to root for installation
USER root

# Install additional packages for enterprise features
RUN apt-get update && apt-get install -y \
    curl \
    jq \
    bash \
    ca-certificates \
    postgresql-client \
    redis-tools \
    nginx \
    supervisor \
    logrotate \
    && rm -rf /var/lib/apt/lists/*

# Create necessary directories
RUN mkdir -p \
    /appsmith-stacks/configuration \
    /appsmith-stacks/data \
    /appsmith-stacks/logs \
    /appsmith-stacks/plugins \
    /appsmith-stacks/widgets \
    /appsmith-stacks/templates \
    /appsmith-stacks/backups \
    /opt/appsmith/scripts \
    /opt/appsmith/config \
    /var/log/appsmith

# Copy built widgets from builder stage
COPY --from=builder /build/widgets/dist/ /appsmith-stacks/widgets/

# Copy configuration files
COPY config/docker.env /appsmith-stacks/configuration/
COPY config/nginx.conf /etc/nginx/sites-available/appsmith
COPY config/supervisor.conf /etc/supervisor/conf.d/appsmith.conf

# Copy custom scripts
COPY scripts/docker-entrypoint.sh /opt/appsmith/scripts/
COPY scripts/healthcheck.sh /opt/appsmith/scripts/
COPY scripts/backup.sh /opt/appsmith/scripts/
COPY scripts/restore.sh /opt/appsmith/scripts/
COPY scripts/init-templates.sh /opt/appsmith/scripts/

# Copy application templates
COPY templates/ /appsmith-stacks/templates/

# Copy custom configuration
COPY config/application.yml /opt/appsmith/config/
COPY config/logback.xml /opt/appsmith/config/

# Security hardening
RUN groupadd -g 1001 appsmith && \
    useradd -r -u 1001 -g appsmith -d /appsmith-stacks -s /bin/bash appsmith

# Set proper permissions
RUN chown -R appsmith:appsmith /appsmith-stacks /var/log/appsmith /opt/appsmith && \
    chmod +x /opt/appsmith/scripts/*.sh && \
    chmod 755 /appsmith-stacks && \
    chmod 755 /var/log/appsmith

# Create log rotation configuration
RUN echo '/var/log/appsmith/*.log {\n\
    daily\n\
    rotate 30\n\
    compress\n\
    delaycompress\n\
    missingok\n\
    notifempty\n\
    create 0644 appsmith appsmith\n\
    postrotate\n\
        supervisorctl restart appsmith || true\n\
    endscript\n\
}' > /etc/logrotate.d/appsmith

# Environment variables for production
    APPSMITH_MAIL_FROM=notifications@vitastrategies.com \
    APPSMITH_REPLY_TO=noreply@vitastrategies.com \
    APPSMITH_MAIL_HOST=smtp.gmail.com \
    APPSMITH_MAIL_PORT=587 \
    APPSMITH_MAIL_SMTP_TLS_ENABLED=true \
    APPSMITH_MAIL_SMTP_AUTH=true \
    APPSMITH_OAUTH2_GITHUB_CLIENT_ID="" \
    APPSMITH_OAUTH2_GOOGLE_CLIENT_ID="" \
    APPSMITH_MARKETPLACE_ENABLED=false \
    APPSMITH_SEGMENT_KEY="" \
    APPSMITH_ALGOLIA_API_ID="" \
    APPSMITH_ALGOLIA_SEARCH_INDEX_NAME="" \
    APPSMITH_ALGOLIA_API_KEY="" \
    APPSMITH_CLIENT_LOG_LEVEL=ERROR \
    APPSMITH_GOOGLE_MAPS_API_KEY="" \
    APPSMITH_TNC_PP="" \
    APPSMITH_VERSION_ID="" \
    APPSMITH_INTERCOM_APP_ID="" \
    APPSMITH_MAIL_USERNAME="" \
    APPSMITH_MAIL_PASSWORD="" \
    APPSMITH_ENCRYPTION_PASSWORD=changeme \
    APPSMITH_ENCRYPTION_SALT=changeme \
    APPSMITH_CUSTOM_DOMAIN=tools.vitastrategies.com

# Database configuration
ENV APPSMITH_DB_URL="" \
    APPSMITH_REDIS_URL=redis://redis:6379 \
    APPSMITH_MONGODB_URI="" \
    APPSMITH_DB_HOST=postgres \
    APPSMITH_DB_PORT=5432 \
    APPSMITH_DB_NAME=appsmith \
    APPSMITH_DB_USERNAME=appsmith_user \
    APPSMITH_DB_PASSWORD=changeme

# Security environment variables
ENV APPSMITH_DISABLE_TELEMETRY=true \
    APPSMITH_HIDE_WATERMARK=true \
    APPSMITH_DISABLE_IFRAME_WIDGET_SANDBOX=false \
    APPSMITH_ALLOWED_FRAME_ANCESTORS="" \
    APPSMITH_CONTENT_SECURITY_POLICY_ENABLED=true

# SSO configuration
ENV APPSMITH_OAUTH2_OIDC_ENABLED=false \
    APPSMITH_OAUTH2_OIDC_CLIENT_ID="" \
    APPSMITH_OAUTH2_OIDC_CLIENT_SECRET="" \
    APPSMITH_OAUTH2_OIDC_RESPONSE_TYPE=code \
    APPSMITH_OAUTH2_OIDC_SCOPE="openid email profile" \
    APPSMITH_OAUTH2_OIDC_ISSUER="" \
    APPSMITH_OAUTH2_OIDC_AUTHORIZATION_URL="" \
    APPSMITH_OAUTH2_OIDC_TOKEN_URL="" \
    APPSMITH_OAUTH2_OIDC_USER_INFO_URL="" \
    APPSMITH_OAUTH2_OIDC_JWK_SET_URL="" \
    APPSMITH_OAUTH2_OIDC_USERNAME_ATTR=preferred_username \
    APPSMITH_OAUTH2_OIDC_EMAIL_ATTR=email \
    APPSMITH_OAUTH2_OIDC_NAME_ATTR=name

# SAML configuration
ENV APPSMITH_SAML_ENABLED=false \
    APPSMITH_SAML_REDIRECT_URL="" \
    APPSMITH_SAML_ENTITY_ID="" \
    APPSMITH_SAML_METADATA_URL="" \
    APPSMITH_SAML_METADATA_XML="" \
    APPSMITH_SAML_KEYSTORE_FILE_PATH="" \
    APPSMITH_SAML_KEYSTORE_PASSWORD="" \
    APPSMITH_SAML_PRIVATE_KEY_ALIAS="" \
    APPSMITH_SAML_IDP_IDENTIFIER="" \
    APPSMITH_SAML_USERNAME_ATTR=http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress \
    APPSMITH_SAML_EMAIL_ATTR=http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress \
    APPSMITH_SAML_FIRST_NAME_ATTR=http://schemas.xmlsoap.org/ws/2005/05/identity/claims/givenname \
    APPSMITH_SAML_LAST_NAME_ATTR=http://schemas.xmlsoap.org/ws/2005/05/identity/claims/surname

# Performance tuning
ENV JAVA_OPTS="-Xms512m -Xmx2g -XX:+UseG1GC -XX:MaxGCPauseMillis=100 -Djava.awt.headless=true" \
    APPSMITH_HEAP_SIZE="2g" \
    APPSMITH_JAVA_HEAP_SIZE="2g"

# Backup configuration
ENV APPSMITH_BACKUP_RETENTION_DAYS=30 \
    APPSMITH_BACKUP_SCHEDULE="0 2 * * *" \
    APPSMITH_BACKUP_ENABLED=true

# Feature flags
ENV APPSMITH_FEATURE_TENANT_ISOLATION_ENABLED=false \
    APPSMITH_FEATURE_LINTING_ENABLED=true \
    APPSMITH_FEATURE_MULTIPLAYER_ENABLED=false

# Switch back to appsmith user
USER 1001

# Health check
HEALTHCHECK --interval=30s --timeout=15s --start-period=120s --retries=3 \
    CMD ["/opt/appsmith/scripts/healthcheck.sh"]

# Expose ports
EXPOSE 80 443 9001

# Volume for persistent data
VOLUME ["/appsmith-stacks"]

# Set entrypoint
ENTRYPOINT ["/opt/appsmith/scripts/docker-entrypoint.sh"]

# Default command
CMD ["supervisord", "-c", "/etc/supervisor/conf.d/appsmith.conf"]

# Metadata labels
LABEL maintainer="platform@vitastrategies.com" \
      version="1.0.0" \
      description="Appsmith Internal Tools Platform for Vita Strategies" \
      org.opencontainers.image.title="Vita Strategies Appsmith" \
      org.opencontainers.image.description="Enterprise low-code platform for internal tools" \
      org.opencontainers.image.version="1.0.0" \
      org.opencontainers.image.created="2025-08-03" \
      org.opencontainers.image.source="https://github.com/vitastrategies/appsmith" \
      org.opencontainers.image.vendor="Vita Strategies" \
      security.policy="https://vitastrategies.com/security-policy"
