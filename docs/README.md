# Documentation
This folder holds system architecture diagrams, pod explanations, and operational runbooks.

## Architecture Diagram
Place architecture.png or SVG diagrams here.

## Pod Overview
Each pod in /podfiles represents a functional domain:
- core-infra: Traefik, Keycloak, OpenBao, AWX, GitLab CE, Pritunl
- client-services: ERPNext, Appsmith, WordPress, Metabase, NextCloud, Jitsi, Mailcow
- monitoring-security: Grafana, Prometheus, Netdata, Uptime Kuma, Wazuh, Graylog
- internal-ops: Mattermost, OpenProject, Kimai, BookStack, Wiki.js, Discourse, Windmill
- utilities-support: Duplicati, GLPI, ArchiveBox
- shared-infra: Redis, MongoDB, PostgreSQL, MySQL, MariaDB
- business-intelligence: Apache Superset, Metabase
