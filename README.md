# VITA STRATEGIES - UNIFIED DEPLOYMENT

This repository contains the infrastructure and application code for the Vita Strategies platform. It is designed to be a secure, scalable, and maintainable system for deploying and managing a suite of business-critical applications.

## Architecture

The Vita Strategies platform is built on a modern, container-based architecture using Docker and Docker Compose. The key components are:

*   **Docker Compose**: A single `docker-compose.yml` file defines and orchestrates all the services in the platform.
*   **Traefik**: A modern, container-native reverse proxy that handles all incoming traffic, provides SSL termination, and routes requests to the appropriate services.
*   **Centralized Databases**: A single PostgreSQL and a single MariaDB instance provide database services for all the applications.
*   **Centralized Caching**: A single Redis instance provides caching and session storage for all the applications.
*   **Google Cloud Secret Manager**: All secrets are securely stored in Google Cloud Secret Manager and are fetched at runtime.

This architecture provides a number of benefits, including:

*   **Simplicity**: A single, unified deployment process makes it easy to get the platform up and running.
*   **Consistency**: All services are configured and managed in a consistent way.
*   **Security**: All secrets are securely stored and are never committed to the repository.
*   **Scalability**: The container-based architecture makes it easy to scale individual services as needed.

## Prerequisites

To deploy the Vita Strategies platform, you will need the following tools installed:

*   **Docker**: A containerization platform for building and running applications.
*   **Docker Compose**: A tool for defining and running multi-container Docker applications.
*   **Google Cloud SDK**: A set of tools for interacting with the Google Cloud Platform.

## Deployment

The deployment process is fully automated and is handled by a single script. To deploy the platform, follow these steps:

1.  **Clone the repository**:
    ```bash
    git clone https://github.com/jamilkigozi/vita-strategies.git
    cd vita-strategies
    ```

2.  **Set up your GCP project**:
    ```bash
    gcloud config set project [YOUR_GCP_PROJECT_ID]
    ```

3.  **Create the secrets in GCP Secret Manager**:
    ```bash
    bash scripts/setup-secrets.sh
    ```

4.  **Deploy the platform**:
    ```bash
    bash scripts/deploy.sh [safe|fresh]
    ```

    The `deploy.sh` script accepts two arguments:
    *   `safe`: Deploys the services, preserving existing data (default).
    *   `fresh`: Deletes all existing data and performs a fresh deployment.

## Services

The following services are included in the Vita Strategies platform:

| Service           | URL                                           |
| ----------------- | --------------------------------------------- |
| Traefik Dashboard | http://traefik.vitastrategies.com             |
| WordPress         | https://vitastrategies.com, https://www.vitastrategies.com |
| ERPNext           | https://erp.vitastrategies.com                |
| Mattermost        | https://chat.vitastrategies.com               |
| Grafana           | https://monitoring.vitastrategies.com         |
| Metabase          | https://analytics.vitastrategies.com          |
| Keycloak          | https://auth.vitastrategies.com               |
| Appsmith          | https://apps.vitastrategies.com               |
| Windmill          | https://flows.vitastrategies.com              |
