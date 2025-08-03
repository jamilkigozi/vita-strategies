# Docker Infrastructure

Docker containerization and orchestration for the Vita Strategies platform.

## 🐳 Container Architecture

### Main Orchestration
- **[docker-compose.yml](./docker-compose.yml)** - Production container orchestration
- **[docker-compose.prod.yml](./docker-compose.prod.yml)** - Production overrides
- **[.env.template](./.env.template)** - Environment variables template

### Nginx Configuration
- **[nginx/](./nginx/)** - Reverse proxy container and configuration
- **SSL termination** and **load balancing**
- **Static file serving** for performance

## 🔧 Service Configuration

### Container Network
- **Internal network:** `vita-network` (bridge)
- **External access:** Through Nginx reverse proxy only
- **Database access:** Private network to Cloud SQL

### Volume Management
- **Persistent data:** Mounted to Cloud Storage via gcsfuse
- **Configuration:** Bind mounts from host
- **Logs:** Centralized logging with log rotation

### Health Monitoring
- **Container health checks** for all services
- **Depends_on** relationships for startup order
- **Restart policies** for high availability

## 🚀 Deployment Commands

### Production Deployment
```bash
# Start all services
docker-compose up -d

# View service status
docker-compose ps

# View logs
docker-compose logs -f [service-name]

# Scale services
docker-compose up -d --scale [service-name]=3
```

### Update Procedures
```bash
# Pull latest images
docker-compose pull

# Restart with new images
docker-compose up -d --force-recreate

# Rolling updates (zero downtime)
docker-compose up -d --no-deps [service-name]
```

### Maintenance Commands
```bash
# Stop all services
docker-compose down

# Remove all containers and volumes
docker-compose down -v

# Clean up unused resources
docker system prune -a
```

## 📊 Resource Monitoring

### Container Resources
- **CPU limits** to prevent resource contention
- **Memory limits** with proper Java heap sizing
- **Storage quotas** for log files and temporary data

### Performance Optimization
- **Multi-stage builds** for smaller images
- **Layer caching** for faster builds
- **Resource constraints** for stability

---

*Containerized infrastructure - deploy anywhere! 🐳*
