<?php
/**
 * WordPress Configuration - Production Ready
 * Vita Strategies WordPress Installation
 * 
 * Security hardened with best practices
 * Cloud SQL database integration
 * Redis caching enabled
 * Environment-based configuration
 */

// ** Database settings - Cloud SQL ** //
$db_password = getenv('WORDPRESS_DB_PASSWORD');
if (empty($db_password)) {
    error_log('CRITICAL: WORDPRESS_DB_PASSWORD environment variable is not set');
    die('Database configuration error. Please check server configuration.');
}

define( 'DB_NAME', getenv('WORDPRESS_DB_NAME') ?: 'wordpress' );
define( 'DB_USER', getenv('WORDPRESS_DB_USER') ?: 'wordpress' );
define( 'DB_PASSWORD', $db_password );
define( 'DB_HOST', getenv('WORDPRESS_DB_HOST') ?: 'localhost' );
define( 'DB_CHARSET', 'utf8mb4' );
define( 'DB_COLLATE', '' );

// ** Security Keys and Salts ** //
// Generate your own: https://api.wordpress.org/secret-key/1.1/salt/
define( 'AUTH_KEY',         getenv('WORDPRESS_AUTH_KEY') ?: 'put your unique phrase here' );
define( 'SECURE_AUTH_KEY',  getenv('WORDPRESS_SECURE_AUTH_KEY') ?: 'put your unique phrase here' );
define( 'LOGGED_IN_KEY',    getenv('WORDPRESS_LOGGED_IN_KEY') ?: 'put your unique phrase here' );
define( 'NONCE_KEY',        getenv('WORDPRESS_NONCE_KEY') ?: 'put your unique phrase here' );
define( 'AUTH_SALT',        getenv('WORDPRESS_AUTH_SALT') ?: 'put your unique phrase here' );
define( 'SECURE_AUTH_SALT', getenv('WORDPRESS_SECURE_AUTH_SALT') ?: 'put your unique phrase here' );
define( 'LOGGED_IN_SALT',   getenv('WORDPRESS_LOGGED_IN_SALT') ?: 'put your unique phrase here' );
define( 'NONCE_SALT',       getenv('WORDPRESS_NONCE_SALT') ?: 'put your unique phrase here' );

// ** WordPress Database Table Prefix ** //
$table_prefix = getenv('WORDPRESS_TABLE_PREFIX') ?: 'wp_';

// ** Environment Configuration ** //
define( 'WP_ENVIRONMENT_TYPE', getenv('WP_ENVIRONMENT_TYPE') ?: 'production' );

// ** Debug Settings ** //
define( 'WP_DEBUG', getenv('WP_DEBUG') === 'true' );
define( 'WP_DEBUG_LOG', getenv('WP_DEBUG_LOG') === 'true' );
define( 'WP_DEBUG_DISPLAY', getenv('WP_DEBUG_DISPLAY') === 'true' );
define( 'SCRIPT_DEBUG', getenv('SCRIPT_DEBUG') === 'true' );

// ** WordPress URLs ** //
define( 'WP_HOME', getenv('WP_HOME') ?: 'https://vitastrategies.com' );
define( 'WP_SITEURL', getenv('WP_SITEURL') ?: 'https://vitastrategies.com' );

// ** Content Directory ** //
define( 'WP_CONTENT_DIR', '/var/www/html/wp-content' );
define( 'WP_CONTENT_URL', 'https://vitastrategies.com/wp-content' );

// ** Upload Settings ** //
define( 'UPLOADS', 'wp-content/uploads' );

// ** Security Settings ** //
define( 'DISALLOW_FILE_EDIT', true );           // Disable file editing
define( 'DISALLOW_FILE_MODS', false );          // Allow plugin/theme installation
define( 'FORCE_SSL_ADMIN', true );              // Force SSL for admin
define( 'WP_AUTO_UPDATE_CORE', 'minor' );       // Auto update minor versions only

// ** Performance Settings ** //
define( 'WP_MEMORY_LIMIT', '512M' );
define( 'WP_MAX_MEMORY_LIMIT', '512M' );
define( 'AUTOSAVE_INTERVAL', 300 );             // 5 minutes
define( 'WP_POST_REVISIONS', 5 );               // Limit revisions
define( 'EMPTY_TRASH_DAYS', 30 );               // Empty trash after 30 days

// ** Redis Cache Configuration ** //
define( 'WP_REDIS_HOST', getenv('REDIS_HOST') ?: '127.0.0.1' );
define( 'WP_REDIS_PORT', getenv('REDIS_PORT') ?: 6379 );
define( 'WP_REDIS_PASSWORD', getenv('REDIS_PASSWORD') ?: '' );
define( 'WP_REDIS_DATABASE', 0 );
define( 'WP_CACHE', true );

// ** Session Configuration ** //
define( 'COOKIE_DOMAIN', '.vitastrategies.com' );
ini_set( 'session.cookie_httponly', true );
ini_set( 'session.cookie_secure', true );
ini_set( 'session.use_only_cookies', true );

// ** File Permissions ** //
define( 'FS_CHMOD_DIR', (0755 & ~ umask()) );
define( 'FS_CHMOD_FILE', (0644 & ~ umask()) );

// ** Multisite Configuration (if needed) ** //
// define( 'WP_ALLOW_MULTISITE', true );

// ** CloudFlare Integration ** //
if ( isset($_SERVER['HTTP_CF_CONNECTING_IP']) ) {
    $_SERVER['REMOTE_ADDR'] = $_SERVER['HTTP_CF_CONNECTING_IP'];
}

// ** Custom Configuration ** //
// Increase maximum execution time
ini_set( 'max_execution_time', 300 );

// Increase upload limits
ini_set( 'upload_max_filesize', '100M' );
ini_set( 'post_max_size', '100M' );

// ** WordPress Absolute Path ** //
if ( ! defined( 'ABSPATH' ) ) {
    define( 'ABSPATH', __DIR__ . '/' );
}

// ** WordPress Bootstrap ** //
require_once ABSPATH . 'wp-settings.php';

// ** Custom Functions ** //
// Log PHP errors to WordPress debug log
if ( WP_DEBUG && WP_DEBUG_LOG ) {
    ini_set( 'log_errors', 1 );
    ini_set( 'error_log', WP_CONTENT_DIR . '/debug.log' );
}

// Security: Hide WordPress version
function remove_wp_version() {
    return '';
}
add_filter( 'the_generator', 'remove_wp_version' );

// Security: Remove WordPress version from scripts and styles
function remove_wp_version_from_scripts( $src ) {
    global $wp_version;
    parse_str( parse_url( $src, PHP_URL_QUERY ), $query );
    if ( ! empty( $query['ver'] ) && $query['ver'] === $wp_version ) {
        $src = remove_query_arg( 'ver', $src );
    }
    return $src;
}
add_filter( 'script_loader_src', 'remove_wp_version_from_scripts', 15, 1 );
add_filter( 'style_loader_src', 'remove_wp_version_from_scripts', 15, 1 );

// Performance: Disable pingbacks
function disable_pingback( &$links ) {
    foreach ( $links as $l => $link ) {
        if ( 0 === strpos( $link, get_option( 'home' ) ) ) {
            unset( $links[$l] );
        }
    }
}
add_action( 'pre_ping', 'disable_pingback' );

// Performance: Remove query strings from static resources
function remove_query_strings() {
    if ( ! is_admin() ) {
        add_filter( 'script_loader_src', 'remove_query_strings_split', 15 );
        add_filter( 'style_loader_src', 'remove_query_strings_split', 15 );
    }
}
function remove_query_strings_split( $src ) {
    $output = preg_split( "/(&ver|\?ver)/", $src );
    return $output[0];
}
add_action( 'init', 'remove_query_strings' );
