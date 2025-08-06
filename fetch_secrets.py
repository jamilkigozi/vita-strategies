#!/usr/bin/env python3
"""
VITA STRATEGIES - Google Secret Manager Integration
Fetches secrets from Google Secret Manager and sets them as environment variables
"""

import os
import subprocess
import sys

def get_secret(secret_id, project_id=None):
    """Fetch a secret from Google Secret Manager"""
    if not project_id:
        # Get project ID from gcloud config
        try:
            result = subprocess.run(['gcloud', 'config', 'get-value', 'project'], 
                                  capture_output=True, text=True, check=True)
            project_id = result.stdout.strip()
        except subprocess.CalledProcessError:
            print("Error: Could not determine GCP project ID", file=sys.stderr)
            return None
    
    try:
        # Use gcloud to fetch secret
        cmd = ['gcloud', 'secrets', 'versions', 'access', 'latest', '--secret', secret_id]
        if project_id:
            cmd.extend(['--project', project_id])
        
        result = subprocess.run(cmd, capture_output=True, text=True, check=True)
        return result.stdout.strip()
    except subprocess.CalledProcessError as e:
        print(f"Error fetching secret {secret_id}: {e}", file=sys.stderr)
        return None

def fetch_all_secrets():
    """Fetch all required secrets and return as environment variables"""
    secrets = {
        'POSTGRES_USER': 'POSTGRES_USER',
        'POSTGRES_PASSWORD': 'POSTGRES_PASSWORD',
        'MYSQL_ROOT_PASSWORD': 'MYSQL_ROOT_PASSWORD',
        'WORDPRESS_DB_USER': 'WORDPRESS_DB_USER',
        'WORDPRESS_DB_PASSWORD': 'WORDPRESS_DB_PASSWORD',
        'ERPNEXT_DB_USER': 'ERPNEXT_DB_USER',
        'ERPNEXT_DB_PASSWORD': 'ERPNEXT_DB_PASSWORD',
        'MATTERMOST_DB_USER': 'MATTERMOST_DB_USER',
        'MATTERMOST_DB_PASSWORD': 'MATTERMOST_DB_PASSWORD',
        'BOOKSTACK_DB_USER': 'BOOKSTACK_DB_USER',
        'BOOKSTACK_DB_PASSWORD': 'BOOKSTACK_DB_PASSWORD',
        'METABASE_DB_USER': 'METABASE_DB_USER',
        'METABASE_DB_PASSWORD': 'METABASE_DB_PASSWORD',
        'GRAFANA_DB_USER': 'GRAFANA_DB_USER',
        'GRAFANA_DB_PASSWORD': 'GRAFANA_DB_PASSWORD',
        'KEYCLOAK_DB_USERNAME': 'KEYCLOAK_DB_USERNAME',
        'KEYCLOAK_DB_PASSWORD': 'KEYCLOAK_DB_PASSWORD',
        'KEYCLOAK_ADMIN_USER': 'KEYCLOAK_ADMIN_USER',
        'KEYCLOAK_ADMIN_PASSWORD': 'KEYCLOAK_ADMIN_PASSWORD',
        'APPSMITH_ENCRYPTION_PASSWORD': 'APPSMITH_ENCRYPTION_PASSWORD',
        'APPSMITH_ENCRYPTION_SALT': 'APPSMITH_ENCRYPTION_SALT',
        'APPSMITH_DB_USER': 'APPSMITH_DB_USER',
        'APPSMITH_DB_PASSWORD': 'APPSMITH_DB_PASSWORD',
        'REDIS_PASSWORD': 'REDIS_PASSWORD',
        'MONGO_ROOT_USER': 'MONGO_ROOT_USER',
        'MONGO_ROOT_PASSWORD': 'MONGO_ROOT_PASSWORD',
        'MINIO_ACCESS_KEY': 'MINIO_ACCESS_KEY',
        'MINIO_SECRET_KEY': 'MINIO_SECRET_KEY',
        'DB_PASSWORD': 'DB_PASSWORD', # For ERPNext and Windmill apps
        'ADMIN_PASSWORD': 'ADMIN_PASSWORD', # For ERPNext and Windmill apps
        'GRAFANA_METRICS_USER': 'GRAFANA_METRICS_USER',
        'GRAFANA_METRICS_PASSWORD': 'GRAFANA_METRICS_PASSWORD',
        'KEYCLOAK_TRUSTSTORE_PASSWORD': 'KEYCLOAK_TRUSTSTORE_PASSWORD',
        'OPENBAO_DB_USERNAME': 'OPENBAO_DB_USERNAME',
        'OPENBAO_DB_PASSWORD': 'OPENBAO_DB_PASSWORD',
        'OPENBAO_ADMIN_USER': 'OPENBAO_ADMIN_USER',
        'OPENBAO_ADMIN_PASSWORD': 'OPENBAO_ADMIN_PASSWORD',
        'WINDMILL_DB_USERNAME': 'WINDMILL_DB_USERNAME',
    }
    
    env_vars = {}
    for env_var, secret_name in secrets.items():
        value = get_secret(secret_name)
        if value:
            env_vars[env_var] = value
    
    return env_vars

if __name__ == "__main__":
    secrets = fetch_all_secrets()
    for key, value in secrets.items():
        print(f"export {key}='{value}'")