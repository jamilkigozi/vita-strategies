# Vita Strategies - Quick Start Guide

## Prerequisites
- Docker and Docker Compose installed
- 8GB+ RAM available
- 20GB+ disk space

## Quick Deployment

1. **Clone the repository:**
   ```bash
   git clone https://github.com/jamilkigozi/vita-strategies.git
   cd vita-strategies
   ```

2. **Start all services:**
   ```bash
   docker-compose up -d
   ```

3. **Check service status:**
   ```bash
   docker-compose ps
   ```

## Service Access

Once running, access services at:

- **ERPNext**: http://localhost (or http://erp.vita-strategies.com)
- **Windmill**: http://windmill.vita-strategies.com
- **Metabase**: http://analytics.vita-strategies.com  
- **Grafana**: http://monitoring.vita-strategies.com
- **Mattermost**: http://chat.vita-strategies.com

## Default Credentials

### ERPNext
- Admin setup required on first access

### Grafana
- Username: admin
- Password: vita_admin_2024

### Databases
- Root password: vita_secure_2024

## Troubleshooting

**Services not starting?**
```bash
docker-compose logs [service-name]
```

**Reset everything:**
```bash
docker-compose down -v
docker-compose up -d
```

**Check network:**
```bash
docker network ls
docker network inspect vita-strategies_vita-network
```

## Development

For development work, see individual service READMEs in the `apps/` directory.

## Support

For issues or questions, check the main README.md or create an issue on GitHub.