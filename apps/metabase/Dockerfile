# Metabase Production Container
# Multi-stage build for business intelligence and analytics platform

# Stage 1: Base Metabase with Java optimizations
FROM metabase/metabase:v0.49.0 AS base

# Set environment variables for production
ENV MB_JETTY_HOST="0.0.0.0" \
    MB_JETTY_PORT="3000" \
    MB_DB_TYPE="postgres" \
    MB_PLUGINS_DIR="/opt/metabase/plugins" \
    MB_SEND_EMAIL_ON_FIRST_LOGIN_FROM_NEW_DEVICE="false" \
    MB_ANON_TRACKING_ENABLED="false" \
    MB_CHECK_FOR_UPDATES="false"

# Stage 2: Production optimizations and security hardening
FROM base AS production

# Switch to root for system setup
USER root

# Install additional tools and security updates
RUN apt-get update && apt-get install -y \
    # Essential tools
    curl \
    wget \
    netcat-openbsd \
    jq \
    # Database clients
    postgresql-client \
    mysql-client \
    # Security tools
    gnupg \
    # Monitoring tools
    htop \
    procps \
    # Process management
    supervisor \
    # Log management
    logrotate \
    # Networking tools
    dnsutils \
    iputils-ping \
    # Cleanup
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && rm -rf /tmp/*

# Create metabase user and directories
RUN groupadd -g 2000 metabase && \
    useradd -u 2000 -g metabase -d /opt/metabase -s /bin/bash metabase

# Create application directories
RUN mkdir -p /opt/metabase \
    && mkdir -p /opt/metabase/data \
    && mkdir -p /opt/metabase/logs \
    && mkdir -p /opt/metabase/plugins \
    && mkdir -p /opt/metabase/scripts \
    && mkdir -p /opt/metabase/backup \
    && mkdir -p /opt/metabase/exports \
    && mkdir -p /var/log/metabase

# Set proper ownership
RUN chown -R metabase:metabase /opt/metabase \
    && chown -R metabase:metabase /var/log/metabase \
    && chmod 755 /opt/metabase \
    && chmod 755 /opt/metabase/data \
    && chmod 755 /opt/metabase/logs \
    && chmod 755 /opt/metabase/plugins \
    && chmod 700 /opt/metabase/backup

# Copy custom scripts and configurations
COPY --chown=metabase:metabase scripts/ /opt/metabase/scripts/
COPY --chown=metabase:metabase plugins/ /opt/metabase/plugins/
COPY --chown=metabase:metabase docker-entrypoint.sh /opt/metabase/docker-entrypoint.sh
COPY --chown=metabase:metabase healthcheck.sh /opt/metabase/healthcheck.sh
COPY --chown=metabase:metabase backup.sh /opt/metabase/backup.sh

# Set executable permissions
RUN chmod +x /opt/metabase/docker-entrypoint.sh \
    && chmod +x /opt/metabase/healthcheck.sh \
    && chmod +x /opt/metabase/backup.sh \
    && chmod +x /opt/metabase/scripts/*.sh

# Set up log rotation
COPY logrotate.conf /etc/logrotate.d/metabase
RUN chmod 644 /etc/logrotate.d/metabase

# Configure supervisor for process management
COPY supervisor.conf /etc/supervisor/conf.d/metabase.conf
RUN chmod 644 /etc/supervisor/conf.d/metabase.conf

# Copy the main Metabase JAR
COPY --from=base /app/metabase.jar /opt/metabase/metabase.jar
RUN chown metabase:metabase /opt/metabase/metabase.jar

# Switch to metabase user
USER metabase

# Set working directory
WORKDIR /opt/metabase

# Production environment variables
ENV JAVA_OPTS="-server -Xms1g -Xmx3g -XX:+UseG1GC -XX:MaxGCPauseMillis=200 -XX:ParallelGCThreads=4 -XX:+DisableExplicitGC -XX:+UseStringDeduplication -XX:+OptimizeStringConcat -Djava.awt.headless=true -Djava.net.preferIPv4Stack=true -Dfile.encoding=UTF-8 -Duser.timezone=UTC" \
    MB_JETTY_HOST="0.0.0.0" \
    MB_JETTY_PORT="3000" \
    MB_JETTY_MAX_THREADS="50" \
    MB_JETTY_MIN_THREADS="8" \
    MB_JETTY_MAX_IDLE_TIME="200000"

# Database configuration
ENV MB_DB_TYPE="postgres" \
    MB_DB_HOST="postgres" \
    MB_DB_PORT="5432" \
    MB_DB_DBNAME="metabase" \
    MB_DB_USER="metabase_user" \
    MB_DB_PASS="" \
    MB_DB_CONNECTION_URI=""

# Application configuration
ENV MB_SITE_NAME="Vita Strategies Analytics" \
    MB_SITE_URL="https://analytics.vitastrategies.com" \
    MB_SITE_LOCALE="en" \
    MB_ADMIN_EMAIL="" \
    MB_ANON_TRACKING_ENABLED="false" \
    MB_CHECK_FOR_UPDATES="false" \
    MB_SEND_EMAIL_ON_FIRST_LOGIN_FROM_NEW_DEVICE="false"

# Security configuration
ENV MB_ENCRYPTION_SECRET_KEY="" \
    MB_SESSION_COOKIES="true" \
    MB_SESSION_COOKIE_SAMESITE="strict" \
    MB_COOKIE_SAMESITE="strict" \
    MB_ENABLE_XRAYS="true" \
    MB_ENABLE_QUERY_CACHING="true" \
    MB_QUERY_CACHING_TTL_RATIO="10" \
    MB_QUERY_CACHING_MAX_KB="1000"

# SAML/SSO configuration (Keycloak)
ENV MB_SAML_ENABLED="false" \
    MB_SAML_IDENTITY_PROVIDER_URI="" \
    MB_SAML_KEYSTORE_PATH="" \
    MB_SAML_KEYSTORE_PASSWORD="" \
    MB_SAML_APPLICATION_NAME="Metabase Analytics" \
    MB_SAML_ATTRIBUTE_EMAIL="email" \
    MB_SAML_ATTRIBUTE_FIRSTNAME="given_name" \
    MB_SAML_ATTRIBUTE_LASTNAME="family_name"

# Email configuration
ENV MB_EMAIL_SMTP_HOST="" \
    MB_EMAIL_SMTP_PORT="587" \
    MB_EMAIL_SMTP_SECURITY="tls" \
    MB_EMAIL_SMTP_USERNAME="" \
    MB_EMAIL_SMTP_PASSWORD="" \
    MB_EMAIL_FROM_ADDRESS="" \
    MB_EMAIL_FROM_NAME="Vita Strategies Analytics"

# Slack integration
ENV MB_SLACK_TOKEN="" \
    MB_SLACK_CHANNEL="#analytics" \
    MB_SLACK_FILES_CHANNEL="#analytics-files"

# Performance and caching
ENV MB_APPLICATION_DB_MAX_CONNECTION_POOL_SIZE="15" \
    MB_ENABLE_QUERY_CACHING="true" \
    MB_QUERY_CACHING_MAX_KB="2000" \
    MB_QUERY_CACHING_TTL_RATIO="10" \
    MB_QP_CACHE_BACKEND="db" \
    MB_ENABLE_XRAYS="true"

# Plugin configuration
ENV MB_PLUGINS_DIR="/opt/metabase/plugins" \
    MB_COLORIZE_LOGS="false" \
    MB_EMOJI_IN_LOGS="false"

# Logging configuration
ENV MB_LOG_LEVEL="INFO" \
    MB_LOG_FILE="/var/log/metabase/metabase.log" \
    MB_COLORIZE_LOGS="false" \
    MB_EMOJI_IN_LOGS="false"

# Health check configuration
ENV HEALTH_CHECK_TIMEOUT="15" \
    CRITICAL_THRESHOLD="90" \
    WARNING_THRESHOLD="75"

# Premium features (if license available)
ENV MB_PREMIUM_EMBEDDING_TOKEN="" \
    MB_ENABLE_EMBEDDING="true" \
    MB_EMBEDDING_SECRET_KEY=""

# Data source connection limits
ENV MB_DB_MAX_CONNECTION_POOL_SIZE="15" \
    MB_DB_CONNECTION_TIMEOUT="10000" \
    MB_DB_READ_ONLY="false"

# Security headers and CORS
ENV MB_CORS_ORIGINS="https://vitastrategies.com,https://*.vitastrategies.com" \
    MB_DISABLE_SESSION_REGENERATION="false"

# Health check
HEALTHCHECK --interval=30s --timeout=15s --start-period=120s --retries=3 \
    CMD /opt/metabase/healthcheck.sh

# Expose ports
EXPOSE 3000

# Set entrypoint
ENTRYPOINT ["/opt/metabase/docker-entrypoint.sh"]

# Default command
CMD ["java", "-jar", "/opt/metabase/metabase.jar"]

# Labels for container metadata
LABEL maintainer="Vita Strategies <admin@vitastrategies.com>" \
      version="1.0.0" \
      description="Production Metabase container with business intelligence features" \
      org.opencontainers.image.title="Metabase Production" \
      org.opencontainers.image.description="Business Intelligence and Analytics platform for Vita Strategies" \
      org.opencontainers.image.version="1.0.0" \
      org.opencontainers.image.vendor="Vita Strategies" \
      org.opencontainers.image.url="https://analytics.vitastrategies.com" \
      org.opencontainers.image.documentation="https://www.metabase.com/docs/" \
      org.opencontainers.image.source="https://github.com/metabase/metabase"
