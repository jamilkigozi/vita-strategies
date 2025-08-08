# VITA STRATEGIES - CLOUDFLARE DEPLOYMENT

This repository contains the infrastructure and application code for the Vita Strategies platform. It is designed to be a secure, scalable, and maintainable system using Google Cloud Platform and Cloudflare services.

## Architecture

The Vita Strategies platform uses a modern, cloud-native architecture:

*   **Google Cloud Platform**: Infrastructure hosted on GCP with Compute Engine VM, Cloud SQL databases, and Cloud Storage buckets.
*   **Cloudflare Tunnel**: Secure tunnel connection eliminating the need for public IP exposure and SSL certificate management.
*   **Docker Compose**: Single `docker-compose.cloudflare.yml` file orchestrates all application services.
*   **Cloud SQL**: Managed PostgreSQL, MySQL, and MariaDB instances with private networking.
*   **Google Secret Manager**: All secrets securely stored and accessed at runtime.
*   **Terraform**: Infrastructure as Code for consistent and reproducible deployments.

This architecture provides:

*   **Security**: Private networking, Cloudflare protection, and centralized secret management.
*   **Simplicity**: Single deployment command via Cloud Shell.
*   **Scalability**: Cloud-native services that scale automatically.
*   **Reliability**: Managed databases with automated backups and high availability.

## Prerequisites

*   **Google Cloud Project**: Active GCP project with billing enabled.
*   **Cloudflare Account**: Domain managed through Cloudflare.
*   **Cloud Shell**: No local tools required - deploy directly from Cloud Shell.

## Deployment

Deploy the entire platform using Cloud Shell:

1.  **Open Cloud Shell** in your GCP console

2.  **Clone the repository**:
    ```bash
    git clone https://github.com/jamilkigozi/vita-strategies.git
    cd vita-strategies
    ```

3.  **Deploy the platform**:
    ```bash
    bash scripts/deploy-cloudshell.sh
    ```

4.  **Configure Cloudflare Tunnel** with the VM IP provided by the deployment script.

## Services

The following services are included in the Vita Strategies platform:

| Service           | URL                                           | Port |
| ----------------- | --------------------------------------------- | ---- |
| WordPress         | https://vitastrategies.com, https://www.vitastrategies.com | 8001 |
| Metabase          | https://analytics.vitastrategies.com          | 8002 |
| Appsmith          | https://apps.vitastrategies.com               | 8003 |
| Keycloak          | https://auth.vitastrategies.com               | 8004 |
| Mattermost        | https://chat.vitastrategies.com               | 8005 |
| ERPNext           | https://erp.vitastrategies.com                | 8006 |
| Windmill          | https://flows.vitastrategies.com              | 8007 |
| Grafana           | https://monitoring.vitastrategies.com         | 8008 |
