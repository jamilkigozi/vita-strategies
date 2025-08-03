# WordPress Application
# Production-ready WordPress with security and performance optimizations

## 🔧 Configuration

This WordPress setup includes:
- **Security hardening** with proper file permissions
- **Performance optimization** with Redis caching
- **Cloud Storage integration** for media files
- **Automated backups** and health monitoring
- **Multi-environment support** (dev, staging, production)

## 📦 Container Features

### Security
- Non-root user execution
- Read-only filesystem for WordPress core
- Minimal attack surface
- Security plugins pre-configured

### Performance  
- Redis object caching
- Image optimization
- CDN integration via Cloud Storage
- Database query optimization

### Storage
- **Local storage:** WordPress core and themes
- **Cloud Storage:** Media uploads via gcsfuse
- **Database:** Cloud SQL MySQL instance

## 🚀 Deployment

```bash
# Build container
docker build -t vita-wordpress .

# Run with Docker Compose
docker-compose up -d wordpress

# Access site
https://vitastrategies.com
```

## 🔧 Configuration Files

- **[Dockerfile](./Dockerfile)** - Container build configuration
- **[docker-compose.yml](./docker-compose.yml)** - Service definition
- **[wp-config.php](./wp-config.php)** - WordPress configuration
- **[php.ini](./php.ini)** - PHP optimization settings

## 🔐 Security Features

### File Permissions
- WordPress core: read-only
- wp-content: writable by web server only
- wp-config.php: 600 permissions

### Plugin Security
- Security scanner integration
- Automated vulnerability checks
- Login attempt limiting
- Two-factor authentication ready

### Database Security
- Prepared statements
- Input sanitization
- SQL injection protection
- Regular security updates

---

*Enterprise WordPress - secure, fast, scalable! 🚀*
