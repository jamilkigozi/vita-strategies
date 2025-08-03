# WordPress Production Container
# Optimized for security, performance, and cloud integration

FROM wordpress:6.6-php8.3-apache

# Install system dependencies
RUN apt-get update && apt-get install -y \
    wget \
    curl \
    unzip \
    git \
    redis-tools \
    imagemagick \
    libmagickwand-dev \
    ghostscript \
    && rm -rf /var/lib/apt/lists/*

# Install PHP extensions
RUN docker-php-ext-install \
    bcmath \
    exif \
    imagick \
    && docker-php-ext-enable \
    imagick

# Install Redis PHP extension
RUN pecl install redis \
    && docker-php-ext-enable redis

# Configure PHP for production
COPY php.ini /usr/local/etc/php/conf.d/wordpress.ini

# Install WP-CLI
RUN curl -O https://raw.githubusercontent.com/wp-cli/wp-cli/v2.8.1/wp-cli.phar \
    && chmod +x wp-cli.phar \
    && mv wp-cli.phar /usr/local/bin/wp

# Create WordPress user
RUN groupadd -r wordpress && useradd -r -g wordpress wordpress

# Set up WordPress directory structure
RUN mkdir -p /var/www/html/wp-content/uploads \
    /var/www/html/wp-content/cache \
    /var/www/html/wp-content/backups

# Copy WordPress configuration
COPY wp-config.php /var/www/html/wp-config.php
COPY .htaccess /var/www/html/.htaccess

# Install essential plugins
RUN cd /var/www/html/wp-content/plugins && \
    # Security plugin
    wget https://downloads.wordpress.org/plugin/wordfence.latest-stable.zip && \
    unzip wordfence.latest-stable.zip && rm wordfence.latest-stable.zip && \
    # Caching plugin
    wget https://downloads.wordpress.org/plugin/redis-cache.latest-stable.zip && \
    unzip redis-cache.latest-stable.zip && rm redis-cache.latest-stable.zip && \
    # SEO plugin
    wget https://downloads.wordpress.org/plugin/wordpress-seo.latest-stable.zip && \
    unzip wordpress-seo.latest-stable.zip && rm wordpress-seo.latest-stable.zip && \
    # Backup plugin
    wget https://downloads.wordpress.org/plugin/updraftplus.latest-stable.zip && \
    unzip updraftplus.latest-stable.zip && rm updraftplus.latest-stable.zip

# Install premium theme (Astra)
RUN cd /var/www/html/wp-content/themes && \
    wget https://downloads.wordpress.org/theme/astra.latest-stable.zip && \
    unzip astra.latest-stable.zip && rm astra.latest-stable.zip

# Copy custom scripts
COPY scripts/ /usr/local/bin/
RUN chmod +x /usr/local/bin/*.sh

# Set proper permissions
RUN chown -R www-data:www-data /var/www/html \
    && chmod -R 755 /var/www/html \
    && chmod 600 /var/www/html/wp-config.php \
    && chmod 644 /var/www/html/.htaccess

# Configure Apache
RUN a2enmod rewrite expires headers deflate ssl

# Copy Apache configuration
COPY apache2.conf /etc/apache2/sites-available/wordpress.conf
RUN a2ensite wordpress && a2dissite 000-default

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:80/wp-admin/admin-ajax.php?action=heartbeat || exit 1

# Expose port
EXPOSE 80

# Start script
COPY docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["apache2-foreground"]
