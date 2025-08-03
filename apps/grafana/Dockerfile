# Multi-stage Dockerfile for Grafana Monitoring Platform
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
    curl

# Copy package files for dependency installation
COPY package*.json ./
RUN npm ci --only=production && npm cache clean --force

# Copy custom plugin sources
COPY plugins/ ./plugins/
COPY scripts/build-plugins.sh ./scripts/

# Build custom plugins
RUN chmod +x ./scripts/build-plugins.sh && \
    ./scripts/build-plugins.sh

# Production stage
FROM grafana/grafana:10.4.2

# Switch to root for installation
USER root

# Install additional packages for monitoring and security
RUN apk add --no-cache \
    curl \
    jq \
    bash \
    ca-certificates \
    tzdata \
    postgresql-client \
    redis \
    prometheus \
    && rm -rf /var/cache/apk/*

# Create necessary directories
RUN mkdir -p \
    /var/lib/grafana/plugins \
    /var/lib/grafana/dashboards \
    /var/lib/grafana/provisioning/datasources \
    /var/lib/grafana/provisioning/dashboards \
    /var/lib/grafana/provisioning/notifiers \
    /var/lib/grafana/provisioning/alerting \
    /var/log/grafana \
    /opt/grafana/scripts \
    /opt/grafana/config

# Copy built plugins from builder stage
COPY --from=builder /build/plugins/dist/ /var/lib/grafana/plugins/

# Copy configuration files
COPY config/grafana.ini /etc/grafana/grafana.ini
COPY config/ldap.toml /etc/grafana/ldap.toml
COPY provisioning/ /etc/grafana/provisioning/
COPY dashboards/ /var/lib/grafana/dashboards/

# Copy custom scripts
COPY scripts/docker-entrypoint.sh /opt/grafana/scripts/
COPY scripts/healthcheck.sh /opt/grafana/scripts/
COPY scripts/backup.sh /opt/grafana/scripts/
COPY scripts/restore.sh /opt/grafana/scripts/

# Copy custom configuration
COPY config/custom.ini /opt/grafana/config/
COPY config/logging.conf /opt/grafana/config/

# Install additional Grafana plugins
RUN grafana-cli plugins install grafana-piechart-panel && \
    grafana-cli plugins install grafana-worldmap-panel && \
    grafana-cli plugins install grafana-clock-panel && \
    grafana-cli plugins install camptocamp-prometheus-alertmanager-datasource && \
    grafana-cli plugins install redis-datasource && \
    grafana-cli plugins install grafana-polystat-panel && \
    grafana-cli plugins install vonage-status-panel && \
    grafana-cli plugins install blackmirror1-statusbygroup-panel

# Security hardening
RUN addgroup -g 1001 grafana && \
    adduser -D -s /bin/bash -u 1001 -G grafana grafana

# Set proper permissions
RUN chown -R grafana:grafana /var/lib/grafana /var/log/grafana /opt/grafana && \
    chmod +x /opt/grafana/scripts/*.sh && \
    chmod 755 /var/lib/grafana && \
    chmod 755 /var/log/grafana

# Create log rotation configuration
RUN echo '/var/log/grafana/*.log {\n\
    daily\n\
    rotate 30\n\
    compress\n\
    delaycompress\n\
    missingok\n\
    notifempty\n\
    create 0644 grafana grafana\n\
}' > /etc/logrotate.d/grafana

# Environment variables for production
ENV GF_PATHS_DATA=/var/lib/grafana \
    GF_PATHS_LOGS=/var/log/grafana \
    GF_PATHS_PLUGINS=/var/lib/grafana/plugins \
    GF_PATHS_PROVISIONING=/etc/grafana/provisioning \
    GF_SERVER_PROTOCOL=http \
    GF_SERVER_HTTP_PORT=3000 \
    GF_SERVER_DOMAIN=monitoring.vitastrategies.com \
    GF_SERVER_ROOT_URL=https://monitoring.vitastrategies.com \
    GF_SECURITY_ADMIN_USER=admin \
    GF_SECURITY_ADMIN_PASSWORD=changeme \
    GF_SECURITY_SECRET_KEY=changeme \
    GF_DATABASE_TYPE=postgres \
    GF_DATABASE_HOST=postgres:5432 \
    GF_DATABASE_NAME=grafana \
    GF_DATABASE_USER=grafana_user \
    GF_DATABASE_PASSWORD=changeme \
    GF_SESSION_PROVIDER=redis \
    GF_SESSION_PROVIDER_CONFIG=addr=redis:6379,pool_size=100 \
    GF_LOG_MODE=console,file \
    GF_LOG_LEVEL=info \
    GF_METRICS_ENABLED=true \
    GF_ANALYTICS_REPORTING_ENABLED=false \
    GF_ANALYTICS_CHECK_FOR_UPDATES=false \
    GF_INSTALL_PLUGINS=""

# JVM tuning for better performance
ENV JAVA_OPTS="-Xms512m -Xmx2g -XX:+UseG1GC -XX:MaxGCPauseMillis=100"

# Security environment variables
ENV GF_SECURITY_COOKIE_SECURE=true \
    GF_SECURITY_COOKIE_SAMESITE=strict \
    GF_SECURITY_DISABLE_GRAVATAR=true \
    GF_SECURITY_DISABLE_BRUTE_FORCE_LOGIN_PROTECTION=false \
    GF_AUTH_DISABLE_LOGIN_FORM=false \
    GF_AUTH_DISABLE_SIGNOUT_MENU=false

# SAML/SSO configuration
ENV GF_AUTH_SAML_ENABLED=false \
    GF_AUTH_SAML_NAME="Keycloak SSO" \
    GF_AUTH_SAML_SINGLE_LOGOUT=true \
    GF_AUTH_SAML_ALLOW_SIGN_UP=true

# SMTP configuration
ENV GF_SMTP_ENABLED=false \
    GF_SMTP_HOST=smtp.gmail.com:587 \
    GF_SMTP_USER="" \
    GF_SMTP_PASSWORD="" \
    GF_SMTP_FROM_ADDRESS=monitoring@vitastrategies.com \
    GF_SMTP_FROM_NAME="Vita Strategies Monitoring"

# Performance tuning
ENV GF_RENDERING_SERVER_URL="" \
    GF_RENDERING_CALLBACK_URL="" \
    GF_ALERTING_ENABLED=true \
    GF_ALERTING_EXECUTE_ALERTS=true \
    GF_EXPLORE_ENABLED=true

# Switch back to grafana user
USER 1001

# Health check
HEALTHCHECK --interval=30s --timeout=15s --start-period=60s --retries=3 \
    CMD ["/opt/grafana/scripts/healthcheck.sh"]

# Expose port
EXPOSE 3000

# Volume for persistent data
VOLUME ["/var/lib/grafana", "/var/log/grafana"]

# Set entrypoint
ENTRYPOINT ["/opt/grafana/scripts/docker-entrypoint.sh"]

# Default command
CMD ["grafana-server", \
     "--config=/etc/grafana/grafana.ini", \
     "--pidfile=/var/run/grafana-server.pid", \
     "--packaging=docker", \
     "cfg:default.log.mode=console", \
     "cfg:default.paths.data=/var/lib/grafana", \
     "cfg:default.paths.logs=/var/log/grafana", \
     "cfg:default.paths.plugins=/var/lib/grafana/plugins", \
     "cfg:default.paths.provisioning=/etc/grafana/provisioning"]

# Metadata labels
LABEL maintainer="platform@vitastrategies.com" \
      version="1.0.0" \
      description="Grafana Monitoring Platform for Vita Strategies" \
      org.opencontainers.image.title="Vita Strategies Grafana" \
      org.opencontainers.image.description="Enterprise monitoring and observability platform" \
      org.opencontainers.image.version="1.0.0" \
      org.opencontainers.image.created="2025-08-03" \
      org.opencontainers.image.source="https://github.com/vitastrategies/grafana" \
      org.opencontainers.image.vendor="Vita Strategies" \
      security.policy="https://vitastrategies.com/security-policy"
