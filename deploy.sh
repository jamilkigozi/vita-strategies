#!/bin/bash

# Quick deployment script
set -e

echo "🚀 Deploying platform to GCP..."

# Upload files
gcloud compute scp docker-compose.yml vita-strategies-server:~/ --zone=europe-west2-a
gcloud compute scp nginx.conf vita-strategies-server:~/ --zone=europe-west2-a

# Start services
gcloud compute ssh vita-strategies-server --zone=europe-west2-a --command="
sudo docker-compose down || true
sudo docker-compose up -d
docker-compose ps
"

echo "✅ Done! Services available at vitastrategies.com subdomains"
