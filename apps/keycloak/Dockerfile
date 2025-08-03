# Keycloak Production Container
# Multi-stage build for enterprise identity and access management

# Stage 1: Build base with Java optimizations
FROM quay.io/keycloak/keycloak:24.0 AS base

# Set environment variables
ENV KC_HEALTH_ENABLED=true \
    KC_METRICS_ENABLED=true \
    KC_DB=postgres \
    KC_FEATURES=token-exchange,admin-fine-grained-authz \
    KC_PROXY=edge \
    KC_HOSTNAME_STRICT=false \
    KC_HOSTNAME_STRICT_HTTPS=false \
    KC_HTTP_ENABLED=true \
    KC_HTTPS_PORT=8443 \
    KC_HTTP_PORT=8080

# Stage 2: Production optimizations and security hardening  
FROM base AS builder

# Switch to root for system setup
USER root

# Install additional tools and security updates
RUN microdnf update -y && \
    microdnf install -y \
    # Essential tools
    curl \
    wget \
    nc \
    # Database clients
    postgresql \
    # Security tools
    openssl \
    # Monitoring tools
    procps-ng \
    # Process management
    supervisor \
    # Cleanup
    && microdnf clean all \
    && rm -rf /var/cache/yum

# Create application directories
RUN mkdir -p /opt/keycloak/themes/vita-strategies \
    && mkdir -p /opt/keycloak/providers \
    && mkdir -p /opt/keycloak/conf/vault \
    && mkdir -p /opt/keycloak/data/export \
    && mkdir -p /opt/keycloak/data/import \
    && mkdir -p /opt/keycloak/logs \
    && mkdir -p /opt/keycloak/backup \
    && mkdir -p /var/log/keycloak

# Set proper ownership for keycloak user
RUN chown -R keycloak:keycloak /opt/keycloak \
    && chown -R keycloak:keycloak /var/log/keycloak \
    && chmod 755 /opt/keycloak/themes \
    && chmod 755 /opt/keycloak/providers \
    && chmod 700 /opt/keycloak/conf/vault \
    && chmod 755 /opt/keycloak/data

# Copy custom configuration
COPY --chown=keycloak:keycloak conf/ /opt/keycloak/conf/
COPY --chown=keycloak:keycloak themes/ /opt/keycloak/themes/
COPY --chown=keycloak:keycloak providers/ /opt/keycloak/providers/
COPY --chown=keycloak:keycloak data/import/ /opt/keycloak/data/import/

# Build Keycloak with custom configuration
USER keycloak
WORKDIR /opt/keycloak
RUN /opt/keycloak/bin/kc.sh build \
    --db=postgres \
    --features=token-exchange,admin-fine-grained-authz,preview \
    --health-enabled=true \
    --metrics-enabled=true

# Stage 3: Final production image
FROM base AS production

# Copy built Keycloak from builder stage
COPY --from=builder --chown=keycloak:keycloak /opt/keycloak/ /opt/keycloak/

# Switch to root for final setup
USER root

# Install runtime dependencies
RUN microdnf update -y && \
    microdnf install -y \
    # Essential tools
    curl \
    wget \
    nc \
    jq \
    # Database clients
    postgresql \
    # Monitoring tools
    htop \
    # Log management
    logrotate \
    # Networking tools
    bind-utils \
    iputils \
    # Cleanup
    && microdnf clean all \
    && rm -rf /var/cache/yum

# Create custom scripts directory
RUN mkdir -p /opt/keycloak/scripts

# Copy custom scripts and configurations
COPY --chown=keycloak:keycloak scripts/ /opt/keycloak/scripts/
COPY --chown=keycloak:keycloak docker-entrypoint.sh /opt/keycloak/docker-entrypoint.sh
COPY --chown=keycloak:keycloak healthcheck.sh /opt/keycloak/healthcheck.sh
COPY --chown=keycloak:keycloak backup.sh /opt/keycloak/backup.sh

# Set executable permissions
RUN chmod +x /opt/keycloak/docker-entrypoint.sh \
    && chmod +x /opt/keycloak/healthcheck.sh \
    && chmod +x /opt/keycloak/backup.sh \
    && chmod +x /opt/keycloak/scripts/*.sh

# Set up log rotation
COPY logrotate.conf /etc/logrotate.d/keycloak
RUN chmod 644 /etc/logrotate.d/keycloak

# Configure supervisor for process management
COPY supervisor.conf /etc/supervisor/conf.d/keycloak.conf
RUN chmod 644 /etc/supervisor/conf.d/keycloak.conf

# Create systemd-style directories for logging
RUN mkdir -p /var/log/keycloak \
    && chown -R keycloak:keycloak /var/log/keycloak

# Switch back to keycloak user
USER keycloak

# Set working directory
WORKDIR /opt/keycloak

# Production environment variables
ENV JAVA_OPTS="-server -Xms512m -Xmx2g -XX:+UseG1GC -XX:+UseG1GCParallelCollections -XX:MaxGCPauseMillis=200 -XX:ParallelGCThreads=4 -XX:+DisableExplicitGC -XX:+UseStringDeduplication -XX:+OptimizeStringConcat -Djava.awt.headless=true -Djava.net.preferIPv4Stack=true" \
    KC_LOG_LEVEL=INFO \
    KC_LOG_FILE=/var/log/keycloak/keycloak.log \
    KC_CACHE=ispn \
    KC_CACHE_STACK=kubernetes \
    KC_CACHE_CONFIG_FILE=cache-ispn.xml

# Database configuration
ENV KC_DB=postgres \
    KC_DB_URL_HOST=postgres \
    KC_DB_URL_PORT=5432 \
    KC_DB_URL_DATABASE=keycloak \
    KC_DB_USERNAME=keycloak_user \
    KC_DB_PASSWORD="" \
    KC_DB_SCHEMA=public

# Hostname and proxy configuration
ENV KC_HOSTNAME=auth.vitastrategies.com \
    KC_HOSTNAME_ADMIN=auth.vitastrategies.com \
    KC_HOSTNAME_STRICT=false \
    KC_HOSTNAME_STRICT_HTTPS=false \
    KC_PROXY=edge \
    KC_PROXY_ADDRESS_FORWARDING=true

# HTTPS and security configuration
ENV KC_HTTPS_CERTIFICATE_FILE=/opt/keycloak/conf/tls.crt \
    KC_HTTPS_CERTIFICATE_KEY_FILE=/opt/keycloak/conf/tls.key \
    KC_HTTPS_CLIENT_AUTH=request \
    KC_HTTPS_PORT=8443 \
    KC_HTTP_ENABLED=true \
    KC_HTTP_PORT=8080

# Admin configuration
ENV KEYCLOAK_ADMIN=admin \
    KEYCLOAK_ADMIN_PASSWORD="" \
    KC_BOOTSTRAP_ADMIN_USERNAME=admin \
    KC_BOOTSTRAP_ADMIN_PASSWORD=""

# Feature flags and optimizations
ENV KC_FEATURES=token-exchange,admin-fine-grained-authz,recovery-codes,update-email \
    KC_TRANSACTION_XA_ENABLED=false \
    KC_HEALTH_ENABLED=true \
    KC_METRICS_ENABLED=true \
    KC_SPI_THEME_STATIC_MAX_AGE=2592000 \
    KC_SPI_THEME_CACHE_THEMES=true \
    KC_SPI_THEME_CACHE_TEMPLATES=true

# Clustering and session configuration
ENV KC_CACHE=ispn \
    KC_CACHE_STACK=kubernetes \
    KC_CACHE_CONFIG_FILE=cache-ispn.xml \
    JGROUPS_DISCOVERY_PROTOCOL=kubernetes.KUBE_PING \
    JGROUPS_DISCOVERY_PROPERTIES=namespace=keycloak

# Logging configuration
ENV KC_LOG=console,file \
    KC_LOG_LEVEL=INFO \
    KC_LOG_FILE=/var/log/keycloak/keycloak.log \
    KC_LOG_FORMAT=json \
    KC_LOG_CONSOLE_FORMAT="%d{yyyy-MM-dd HH:mm:ss,SSS} %-5p [%c] (%t) %s%e%n"

# Vault integration (for secrets management)
ENV KC_VAULT_FILE=/opt/keycloak/conf/vault/vault.properties \
    KC_SPI_VAULT_HASHICORP_VAULT_URL=https://vault.vitastrategies.com \
    KC_SPI_VAULT_HASHICORP_VAULT_TOKEN=""

# Security settings
ENV KC_SPI_LOGIN_PROTOCOL_OPENID_CONNECT_LEGACY_LOGOUT_REDIRECT_URI=false \
    KC_SPI_LOGIN_PROTOCOL_OPENID_CONNECT_SUPPRESS_LOGOUT_CONFIRMATION_SCREEN=false \
    KC_SPI_TRUSTSTORE_FILE_FILE=/opt/keycloak/conf/truststore.jks \
    KC_SPI_TRUSTSTORE_FILE_PASSWORD=changeit

# Health check configuration
HEALTHCHECK --interval=30s --timeout=15s --start-period=120s --retries=3 \
    CMD /opt/keycloak/healthcheck.sh

# Expose ports
EXPOSE 8080 8443 9000 9990

# Set entrypoint
ENTRYPOINT ["/opt/keycloak/docker-entrypoint.sh"]

# Default command
CMD ["start", "--optimized"]

# Labels for container metadata
LABEL maintainer="Vita Strategies <admin@vitastrategies.com>" \
      version="1.0.0" \
      description="Production Keycloak container with enterprise identity management" \
      org.opencontainers.image.title="Keycloak Production" \
      org.opencontainers.image.description="Identity and Access Management platform for Vita Strategies" \
      org.opencontainers.image.version="1.0.0" \
      org.opencontainers.image.vendor="Vita Strategies" \
      org.opencontainers.image.url="https://auth.vitastrategies.com" \
      org.opencontainers.image.documentation="https://www.keycloak.org/documentation" \
      org.opencontainers.image.source="https://github.com/keycloak/keycloak"
