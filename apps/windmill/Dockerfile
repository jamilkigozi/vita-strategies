# Windmill Production Container
# Multi-stage build for optimized workflow automation platform

# Stage 1: Base Windmill with production optimizations
FROM windmill-labs/windmill:latest AS base

# Set environment variables for production
ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    RUST_LOG=info \
    DEBIAN_FRONTEND=noninteractive \
    WINDMILL_USER=windmill

# Stage 2: Production optimizations and security hardening
FROM base AS production

# Switch to root for system updates
USER root

# Update system packages and install production dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    # Security and monitoring tools
    curl \
    wget \
    netcat \
    htop \
    # Database clients
    postgresql-client \
    redis-tools \
    # File processing tools
    imagemagick \
    ghostscript \
    poppler-utils \
    # Development tools for workflows
    git \
    jq \
    # Network tools
    dnsutils \
    iputils-ping \
    # Process management
    supervisor \
    # Log rotation
    logrotate \
    # Cleanup
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && rm -rf /tmp/* \
    && rm -rf /var/tmp/*

# Install additional workflow runtime dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    # Python runtime for workflows
    python3 \
    python3-pip \
    python3-venv \
    # Node.js runtime for TypeScript workflows
    nodejs \
    npm \
    # Go runtime for Go workflows
    golang-go \
    # Additional scripting tools
    bash \
    # Cleanup
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install Python packages for workflow automation
COPY requirements.txt /tmp/requirements.txt
RUN pip3 install --no-cache-dir -r /tmp/requirements.txt

# Install Node.js packages for TypeScript workflows
RUN npm install -g \
    typescript \
    ts-node \
    @types/node \
    axios \
    lodash \
    moment \
    uuid

# Create windmill user and directories
RUN groupadd -r windmill && useradd -r -g windmill -d /opt/windmill -s /bin/bash windmill

# Create application directories
RUN mkdir -p /opt/windmill \
    && mkdir -p /var/log/windmill \
    && mkdir -p /opt/windmill/workflows \
    && mkdir -p /opt/windmill/scripts \
    && mkdir -p /opt/windmill/config \
    && mkdir -p /opt/windmill/data

# Set proper ownership
RUN chown -R windmill:windmill /opt/windmill \
    && chown -R windmill:windmill /var/log/windmill

# Copy configuration files
COPY --chown=windmill:windmill config/ /opt/windmill/config/
COPY --chown=windmill:windmill scripts/ /opt/windmill/scripts/

# Copy workflow templates
COPY --chown=windmill:windmill workflows/ /opt/windmill/workflows/

# Set up log rotation
COPY logrotate.conf /etc/logrotate.d/windmill
RUN chmod 644 /etc/logrotate.d/windmill

# Configure supervisor for process management
COPY supervisor.conf /etc/supervisor/conf.d/windmill.conf
RUN chmod 644 /etc/supervisor/conf.d/windmill.conf

# Create health check script
COPY --chown=windmill:windmill healthcheck.sh /opt/windmill/healthcheck.sh
RUN chmod +x /opt/windmill/healthcheck.sh

# Create backup script
COPY --chown=windmill:windmill backup.sh /opt/windmill/backup.sh
RUN chmod +x /opt/windmill/backup.sh

# Create entrypoint script
COPY --chown=windmill:windmill docker-entrypoint.sh /opt/windmill/docker-entrypoint.sh
RUN chmod +x /opt/windmill/docker-entrypoint.sh

# Switch to windmill user
USER windmill

# Set working directory
WORKDIR /opt/windmill

# Configure production environment variables
ENV WINDMILL_SERVER_URL="http://localhost:8000" \
    DATABASE_URL="" \
    REDIS_URL="redis://redis:6379" \
    WINDMILL_COOKIE_DOMAIN="" \
    WINDMILL_FRONTEND_URL="" \
    WINDMILL_BASE_URL="" \
    DISABLE_NUSER="true" \
    KEEP_JOB_DIR="false" \
    DENO_AUTH_TOKENS="" \
    NPM_CONFIG_REGISTRY="https://registry.npmjs.org/" \
    PIP_INDEX_URL="https://pypi.org/simple/" \
    WINDMILL_WORKER_TAGS="" \
    NUM_WORKERS=4 \
    SLEEP_QUEUE=50 \
    MAX_LOG_LENGTH=500000 \
    DISABLE_STATS="false" \
    METRICS_ADDR="0.0.0.0:8001" \
    JSON_FMT="true" \
    RUST_BACKTRACE=1

# Health check configuration
HEALTHCHECK --interval=30s --timeout=15s --start-period=60s --retries=3 \
    CMD /opt/windmill/healthcheck.sh

# Expose ports
EXPOSE 8000 8001

# Set entrypoint
ENTRYPOINT ["/opt/windmill/docker-entrypoint.sh"]

# Default command
CMD ["supervisord", "-c", "/etc/supervisor/supervisord.conf"]

# Labels for container metadata
LABEL maintainer="Vita Strategies <admin@vitastrategies.com>" \
      version="1.0.0" \
      description="Production Windmill container with workflow automation capabilities" \
      org.opencontainers.image.title="Windmill Production" \
      org.opencontainers.image.description="Workflow automation platform for Vita Strategies" \
      org.opencontainers.image.version="1.0.0" \
      org.opencontainers.image.vendor="Vita Strategies" \
      org.opencontainers.image.url="https://windmill.vitastrategies.com" \
      org.opencontainers.image.documentation="https://docs.windmill.dev" \
      org.opencontainers.image.source="https://github.com/windmill-labs/windmill"
