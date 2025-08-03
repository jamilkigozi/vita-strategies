# OpenBao Production Container
# Multi-stage build for secure secrets management platform

# Stage 1: Base OpenBao with production optimizations
FROM openbao/openbao:latest AS base

# Set environment variables for production
ENV OPENBAO_ADDR="http://127.0.0.1:8200" \
    OPENBAO_API_ADDR="http://127.0.0.1:8200" \
    OPENBAO_CLUSTER_ADDR="http://127.0.0.1:8201" \
    OPENBAO_LOG_LEVEL="INFO" \
    OPENBAO_LOG_FORMAT="json" \
    OPENBAO_DISABLE_MLOCK="true" \
    SKIP_CHOWN="true" \
    SKIP_SETCAP="true"

# Stage 2: Production optimizations and security hardening
FROM base AS production

# Switch to root for system updates
USER root

# Update system and install production dependencies
RUN apk update && apk add --no-cache \
    # Essential tools
    curl \
    wget \
    netcat-openbsd \
    jq \
    # Database clients
    postgresql-client \
    # Security tools
    gnupg \
    # Monitoring tools
    htop \
    # Process management
    supervisor \
    # Log management
    logrotate \
    # Networking tools
    bind-tools \
    iputils \
    # Cleanup
    && rm -rf /var/cache/apk/* \
    && rm -rf /tmp/*

# Create openbao user and directories
RUN addgroup -g 1000 openbao && \
    adduser -D -u 1000 -G openbao -h /opt/openbao -s /bin/sh openbao

# Create application directories
RUN mkdir -p /opt/openbao \
    && mkdir -p /opt/openbao/config \
    && mkdir -p /opt/openbao/data \
    && mkdir -p /opt/openbao/logs \
    && mkdir -p /opt/openbao/policies \
    && mkdir -p /opt/openbao/scripts \
    && mkdir -p /opt/openbao/audit \
    && mkdir -p /var/log/openbao

# Set proper ownership
RUN chown -R openbao:openbao /opt/openbao \
    && chown -R openbao:openbao /var/log/openbao \
    && chmod 755 /opt/openbao \
    && chmod 700 /opt/openbao/data \
    && chmod 755 /opt/openbao/config \
    && chmod 700 /opt/openbao/audit

# Copy configuration files
COPY --chown=openbao:openbao config/ /opt/openbao/config/
COPY --chown=openbao:openbao policies/ /opt/openbao/policies/
COPY --chown=openbao:openbao scripts/ /opt/openbao/scripts/

# Set up log rotation
COPY logrotate.conf /etc/logrotate.d/openbao
RUN chmod 644 /etc/logrotate.d/openbao

# Configure supervisor for process management
COPY supervisor.conf /etc/supervisor/conf.d/openbao.conf
RUN chmod 644 /etc/supervisor/conf.d/openbao.conf

# Create health check script
COPY --chown=openbao:openbao healthcheck.sh /opt/openbao/healthcheck.sh
RUN chmod +x /opt/openbao/healthcheck.sh

# Create backup script
COPY --chown=openbao:openbao backup.sh /opt/openbao/backup.sh
RUN chmod +x /opt/openbao/backup.sh

# Create initialization script
COPY --chown=openbao:openbao init.sh /opt/openbao/init.sh
RUN chmod +x /opt/openbao/init.sh

# Create entrypoint script
COPY --chown=openbao:openbao docker-entrypoint.sh /opt/openbao/docker-entrypoint.sh
RUN chmod +x /opt/openbao/docker-entrypoint.sh

# Switch to openbao user
USER openbao

# Set working directory
WORKDIR /opt/openbao

# Configure production environment variables
ENV OPENBAO_CONFIG_PATH="/opt/openbao/config/openbao.hcl" \
    OPENBAO_LOG_FILE="/var/log/openbao/openbao.log" \
    OPENBAO_AUDIT_FILE="/opt/openbao/audit/audit.log" \
    POSTGRES_URL="" \
    GCP_KMS_PROJECT="" \
    GCP_KMS_REGION="us-central1" \
    GCP_KMS_KEY_RING="openbao-keyring" \
    GCP_KMS_CRYPTO_KEY="openbao-key" \
    GOOGLE_APPLICATION_CREDENTIALS="/opt/openbao/config/gcp-kms-key.json" \
    OPENBAO_SEAL_TYPE="gcpckms" \
    OPENBAO_UI="true" \
    OPENBAO_CLUSTER_NAME="vita-strategies" \
    OPENBAO_MAX_LEASE_TTL="768h" \
    OPENBAO_DEFAULT_LEASE_TTL="24h" \
    OPENBAO_DISABLE_CACHE="false" \
    OPENBAO_DISABLE_CLUSTERING="false"

# Security configurations
ENV OPENBAO_TLS_CERT_FILE="/opt/openbao/config/tls.crt" \
    OPENBAO_TLS_KEY_FILE="/opt/openbao/config/tls.key" \
    OPENBAO_TLS_CA_FILE="/opt/openbao/config/ca.crt" \
    OPENBAO_TLS_MIN_VERSION="tls12" \
    OPENBAO_TLS_CIPHER_SUITES="TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256,TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384" \
    OPENBAO_DISABLE_SEALWRAP="false" \
    OPENBAO_DISABLE_PERFORMANCE_STANDBY="false"

# Clustering configuration
ENV OPENBAO_RAFT_NODE_ID="" \
    OPENBAO_RAFT_PATH="/opt/openbao/data/raft" \
    OPENBAO_RAFT_RETRY_JOIN="" \
    OPENBAO_API_ADDR_HOST="" \
    OPENBAO_CLUSTER_ADDR_HOST=""

# Health check configuration
HEALTHCHECK --interval=30s --timeout=15s --start-period=60s --retries=3 \
    CMD /opt/openbao/healthcheck.sh

# Expose ports
EXPOSE 8200 8201

# Set entrypoint
ENTRYPOINT ["/opt/openbao/docker-entrypoint.sh"]

# Default command
CMD ["openbao", "server", "-config=/opt/openbao/config/openbao.hcl"]

# Labels for container metadata
LABEL maintainer="Vita Strategies <admin@vitastrategies.com>" \
      version="1.0.0" \
      description="Production OpenBao container with enterprise security features" \
      org.opencontainers.image.title="OpenBao Production" \
      org.opencontainers.image.description="Secrets management platform for Vita Strategies" \
      org.opencontainers.image.version="1.0.0" \
      org.opencontainers.image.vendor="Vita Strategies" \
      org.opencontainers.image.url="https://vault.vitastrategies.com" \
      org.opencontainers.image.documentation="https://openbao.org/docs" \
      org.opencontainers.image.source="https://github.com/openbao/openbao"
