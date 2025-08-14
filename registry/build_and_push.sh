#!/bin/bash
set -euo pipefail
if [ $# -ne 2 ]; then
  echo "Usage: $0 <pod-name> <gcp-registry>"
  exit 1
fi
POD="$1"
REGISTRY="$2"
TAG=$(date +%Y%m%d%H%M%S)
echo "Logging into $REGISTRY..."
podman login -u _json_key --password-stdin "$REGISTRY" <<< "$(bao vault read -field=key gcp/artifact-registry)"
find "podfiles/$POD" -name Dockerfile -exec dirname {} \; | \
while read -r dir; do
  service=$(basename "$dir")
  podman build -t "$REGISTRY/$service:$TAG" "$dir"
  podman push "$REGISTRY/$service:$TAG"
done
