# Build Configuration - Vita Strategies Platform

## Build System Overview

### Docker Multi-Stage Builds
All services use optimized Docker builds with multi-stage configurations for production efficiency.

### Build Environments
- **Development**: Hot reload, debug symbols, development dependencies
- **Testing**: Test runners, coverage tools, minimal production simulation
- **Production**: Optimized binaries, minimal attack surface, performance focused

## Service Build Configurations

### ERPNext Build
```dockerfile
# Production build optimizations
FROM frappe/erpnext:v15 as production
RUN bench build --production
RUN bench clear-cache
```

**Build Requirements:**
- Node.js 16+ for asset compilation
- Python 3.9+ with development headers
- 4GB RAM minimum during build
- Asset compilation takes 10-15 minutes

### Windmill Build
```dockerfile
FROM ghcr.io/windmill-labs/windmill:main
# Pre-built Rust binaries, no compilation needed
```

**Configuration:**
- Uses pre-compiled Rust binaries
- TypeScript compilation at runtime
- WebAssembly support enabled

### Nginx Build
```dockerfile
FROM nginx:alpine
COPY nginx.conf /etc/nginx/nginx.conf
```

**Optimizations:**
- Alpine Linux for minimal size
- Custom configuration injection
- SSL/TLS optimization modules

## Asset Pipeline

### ERPNext Assets
```bash
# Asset build process
bench build --force --verbose
bench clear-cache --doctype --report

# Static file collection
bench collect-static
```

### Build Artifacts
- CSS bundles: `/assets/css/`
- JavaScript bundles: `/assets/js/`
- Images and icons: `/assets/img/`
- Font files: `/assets/fonts/`

## Build Optimization

### Image Size Reduction
- Multi-stage builds to exclude build dependencies
- .dockerignore for unnecessary files
- Alpine Linux base images where possible
- Layer caching optimization

### Build Performance
```yaml
# Docker Compose build configuration
services:
  erpnext:
    build:
      context: .
      dockerfile: Dockerfile.erpnext
      cache_from:
        - erpnext:latest
      args:
        BUILDKIT_INLINE_CACHE: 1
```

### Build Caching Strategy
- Layer-based caching for dependencies
- BuildKit for advanced caching
- Registry-based cache sharing
- Parallel build execution

## CI/CD Build Pipeline

### Build Stages
1. **Code Quality**: Linting, security scanning
2. **Testing**: Unit tests, integration tests
3. **Building**: Docker image creation
4. **Security**: Vulnerability scanning
5. **Registry**: Push to container registry

### Build Matrix
```yaml
strategy:
  matrix:
    platform: [linux/amd64, linux/arm64]
    environment: [staging, production]
```

## Configuration Management

### Environment-Specific Builds
- Development: Debug enabled, hot reload
- Staging: Production-like with debug logging  
- Production: Optimized, minimal logging

### Build-time Variables
```bash
# Required build arguments
ARG ENVIRONMENT=production
ARG VERSION=latest
ARG BUILD_DATE
ARG COMMIT_SHA
```

## Quality Assurance

### Build Validation
- Container security scanning
- Dependency vulnerability assessment
- License compliance checking
- Performance benchmarking

### Testing Integration
- Unit test execution during build
- Integration test preparation
- Build artifact validation
- Regression test preparation

## Build Monitoring

### Metrics Collection
- Build duration tracking
- Resource usage monitoring
- Success/failure rates
- Image size trends

### Build Notifications
- Slack/email notifications
- Build status badges
- Automated reports
- Failure analysis

## Troubleshooting

### Common Build Issues
```bash
# ERPNext build failures
docker-compose build erpnext --no-cache

# Asset compilation issues
docker-compose exec erpnext bench build --force

# Dependency conflicts
docker-compose exec erpnext pip install --force-reinstall [package]
```

### Build Debugging
```bash
# Interactive build debugging
docker run -it --rm erpnext:latest /bin/bash

# Build log analysis
docker-compose logs --tail=100 [service]
```

## Security Considerations

### Build Security
- Base image vulnerability scanning
- Dependency security assessment
- Secret management during builds
- Signed image verification

### Runtime Security
- Non-root user execution
- Read-only filesystems
- Capability dropping
- Security context constraints

---

**Build Status**: ✅ Optimized for production
**Last Updated**: August 4, 2025
**Next Review**: Monthly build optimization review