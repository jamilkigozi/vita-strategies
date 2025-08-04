FROM wordpress:latest

# Install additional PHP extensions if needed
RUN docker-php-ext-install mysqli pdo pdo_mysql

# Copy custom configuration
COPY wp-config.php /var/www/html/

EXPOSE 80