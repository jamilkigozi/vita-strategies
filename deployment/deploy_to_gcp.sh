#!/bin/bash
set -euo pipefail
VM_NAME="${1:-vita-platform-01}"
ZONE="${2:-europe-west2-a}"
gcloud compute scp --recurse podfiles "vita@$VM_NAME:~/"
ssh "vita@$VM_NAME" "sudo podman-compose -f podfiles/core-infra/docker-compose.yml up -d"
