# Applications Directory

This directory contains configuration files and customizations for each application in the Vita Strategies platform.

## Application Structure

Each application directory contains:
- **Dockerfile**: Custom application image (if needed)
- **Configuration files**: Application-specific configs
- **Health checks**: Container health monitoring
- **Documentation**: Application-specific setup notes

## Applications

### WordPress (`apps/wordpress/`)
- **Port**: 8001
- **Database**: MySQL (Cloud SQL)
- **Purpose**: Main website and content management

### ERPNext (`apps/erpnext/`)
- **Port**: 8006
- **Database**: MariaDB (Cloud SQL)
- **Purpose**: Enterprise resource planning

### Mattermost (`apps/mattermost/`)
- **Port**: 8005
- **Database**: PostgreSQL (Cloud SQL)
- **Purpose**: Team communication and collaboration

### Grafana (`apps/grafana/`)
- **Port**: 8008
- **Database**: PostgreSQL (Cloud SQL)
- **Purpose**: Monitoring and observability dashboards

### Metabase (`apps/metabase/`)
- **Port**: 8002
- **Database**: PostgreSQL (Cloud SQL)
- **Purpose**: Business intelligence and analytics

### Keycloak (`apps/keycloak/`)
- **Port**: 8004
- **Database**: PostgreSQL (Cloud SQL)
- **Purpose**: Identity and access management

### Appsmith (`apps/appsmith/`)
- **Port**: 8003
- **Database**: MongoDB (containerized)
- **Purpose**: Low-code application development

### Windmill (`apps/windmill/`)
- **Port**: 8007
- **Database**: PostgreSQL (Cloud SQL)
- **Purpose**: Workflow automation and scripting

### OpenBao (`apps/openbao/`)
- **Database**: PostgreSQL (Cloud SQL)
- **Purpose**: Secrets management (currently configured but not deployed)

## Database Connections

All applications connect to Cloud SQL instances via the `cloud-sql-proxy` container:
- **PostgreSQL**: `cloud-sql-proxy:5432`
- **MySQL**: `cloud-sql-proxy:3306`
- **MariaDB**: `cloud-sql-proxy:3307`

## Shared Services

- **Redis**: Caching and session storage
- **MongoDB**: Document storage for Appsmith

## Configuration Management

- Environment variables defined in `.env` file
- Secrets fetched from Google Secret Manager
- Application-specific configs in respective directories
- Health checks ensure service availability