# VITA STRATEGIES - SYSTEM ARCHITECTURE

This document provides a high-level overview of the system architecture for the Vita Strategies platform.

## System Overview

The Vita Strategies platform is a container-based system orchestrated by Docker Compose. It is designed to be a secure, scalable, and maintainable platform for a suite of business-critical applications.

The architecture is centered around a single, unified `docker-compose.yml` file that defines all the services in the platform. A Traefik reverse proxy acts as the single entry point for all incoming traffic, providing SSL termination and routing requests to the appropriate services.

```
+-----------------+      +-----------------+      +-----------------+
|   PostgreSQL    |      |     MariaDB     |      |      Redis      |
+-----------------+      +-----------------+      +-----------------+
        |                      |                      |
        |                      |                      |
+-------------------------------------------------------------+
|                        VITA-NETWORK                         |
+-------------------------------------------------------------+
        |                      |                      |
+-----------------+      +-----------------+      +-----------------+
|   WordPress     |      |     ERPNext     |      |    Mattermost   |
+-----------------+      +-----------------+      +-----------------+
        |                      |                      |
+-------------------------------------------------------------+
|                         TRAEFIK PROXY                         |
+-------------------------------------------------------------+
        |                      |                      |
+-----------------+      +-----------------+      +-----------------+
|   Internet      |      |   Developers    |      |      Users      |
+-----------------+      +-----------------+      +-----------------+
```

## Service Descriptions

The platform is composed of the following services:

*   **Traefik**: A modern, container-native reverse proxy that handles all incoming traffic, provides SSL termination, and routes requests to the appropriate services.
*   **PostgreSQL**: A powerful, open-source object-relational database system that provides database services for many of the applications.
*   **MariaDB**: A community-developed, commercially supported fork of the MySQL relational database management system, used by WordPress and ERPNext.
*   **Redis**: An in-memory data structure store, used as a database, cache, and message broker.
*   **WordPress**: A free and open-source content management system.
*   **ERPNext**: A free and open-source integrated enterprise resource planning software.
*   **Mattermost**: An open-source, self-hostable online chat service with file sharing, search, and integrations.
*   **Grafana**: A multi-platform open-source analytics and interactive visualization web application.
*   **Metabase**: An open-source business intelligence tool.
*   **Keycloak**: An open-source software product to allow single sign-on with Identity and Access Management aimed at modern applications and services.
*   **Appsmith**: An open-source, low-code platform for building internal tools.
*   **Windmill**: An open-source, self-hostable platform for building internal tools and workflows.

## Networking

All services are connected to a single Docker network called `vita-network`. This allows them to communicate with each other using their service names as hostnames.

Traefik is the only service that is exposed to the outside world. It listens on ports 80 and 443 and routes traffic to the appropriate services based on the hostname in the request. All services are configured to be exposed only through Traefik, and all traffic is automatically redirected to HTTPS.

## Data Persistence

All application data is stored in named Docker volumes. This ensures that the data is persisted even if the containers are removed or recreated. The volumes are mounted to the appropriate services in the `docker-compose.yml` file.

## Security

The Vita Strategies platform is designed with security in mind. The key security features are:

*   **Secret Management**: All secrets are stored in Google Cloud Secret Manager and are fetched at runtime. They are never committed to the repository.
*   **Network Segmentation**: All services are isolated in a private Docker network, and only Traefik is exposed to the outside world.
*   **SSL Termination**: All traffic is encrypted using SSL, and Traefik handles the SSL termination.
*   **Principle of Least Privilege**: Each service is configured with the minimum set of permissions required to perform its function.
