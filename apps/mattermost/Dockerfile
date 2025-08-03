# Mattermost Production Container
# Enterprise team communication platform with security and performance optimization

FROM mattermost/mattermost-team-edition:9.0

# Switch to root for installation
USER root

# Install additional tools and dependencies
RUN apt-get update && apt-get install -y \
    curl \
    wget \
    jq \
    postgresql-client \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Create required directories
RUN mkdir -p \
    /mattermost/config \
    /mattermost/data \
    /mattermost/logs \
    /mattermost/plugins \
    /mattermost/client/plugins \
    /var/log/mattermost

# Copy configuration files
COPY config/config.json /mattermost/config/config.json
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
COPY scripts/ /usr/local/bin/

# Make scripts executable
RUN chmod +x /usr/local/bin/entrypoint.sh \
    && chmod +x /usr/local/bin/*.sh

# Set proper permissions for mattermost user
RUN chown -R mattermost:mattermost /mattermost \
    && chown -R mattermost:mattermost /var/log/mattermost \
    && chmod 600 /mattermost/config/config.json

# Create plugin directory with proper permissions
RUN mkdir -p /mattermost/plugins/com.mattermost.plugin-channel-export \
    && chown -R mattermost:mattermost /mattermost/plugins

# Download and install essential plugins
RUN cd /tmp && \
    # Jitsi plugin for video calls
    wget -O jitsi.tar.gz https://github.com/mattermost/mattermost-plugin-jitsi/releases/latest/download/jitsi.tar.gz && \
    tar -xzf jitsi.tar.gz -C /mattermost/plugins/ && \
    # Channel export plugin for compliance
    wget -O channel-export.tar.gz https://github.com/mattermost/mattermost-plugin-channel-export/releases/latest/download/com.mattermost.plugin-channel-export.tar.gz && \
    tar -xzf channel-export.tar.gz -C /mattermost/plugins/ && \
    rm -f *.tar.gz

# Configure log rotation
COPY logrotate.conf /etc/logrotate.d/mattermost

# Health check script
COPY healthcheck.sh /usr/local/bin/healthcheck.sh
RUN chmod +x /usr/local/bin/healthcheck.sh

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD /usr/local/bin/healthcheck.sh

# Switch back to mattermost user
USER mattermost

# Set working directory
WORKDIR /mattermost

# Environment variables
ENV MM_SERVICESETTINGS_LISTENADDRESS=:8065
ENV MM_SERVICESETTINGS_CONNECTIONSECURITY=""
ENV MM_SERVICESETTINGS_TLS_CERT_FILE=""
ENV MM_SERVICESETTINGS_TLS_KEY_FILE=""
ENV MM_SERVICESETTINGS_FORWARD80TO443=false
ENV MM_SERVICESETTINGS_SITEURL=https://chat.vitastrategies.com
ENV MM_SERVICESETTINGS_WEBSOCKETURL=""
ENV MM_SERVICESETTINGS_ENABLEINSECUREOUTGOINGCONNECTIONS=false

# Expose port
EXPOSE 8065

# Custom entrypoint
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["mattermost"]
