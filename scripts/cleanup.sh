#!/bin/bash
set -euo pipefail
echo "Stopping & removing containers, images, volumes..."
podman ps -aq | xargs -r podman rm -f
podman images -aq | xargs -r podman rmi -f
podman volume ls -q | xargs -r podman volume rm -f
