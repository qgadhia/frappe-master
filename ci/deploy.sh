#!/bin/bash

set -euo pipefail

source /home/ubuntu/cicd/build.env

echo "[DEBUG] CI_COMMIT_SHA: ${CI_COMMIT_SHA:-missing}"
echo "[DEBUG] DOCKER_REGISTRY_URL: ${DOCKER_REGISTRY_URL:-missing}"

# Path setup
APP_DIR="/home/$VM_USER/cicd"
COMPOSE_FILE="$APP_DIR/docker-compose.yml"

echo "🔄 Changing to app directory: $APP_DIR"
cd "$APP_DIR"

# Replace placeholder in compose file
echo "✏️  Replacing CI_COMMIT_SHA in compose file..."
sed -i -e "s/\\\$CI_COMMIT_SHA/${CI_COMMIT_SHA}/g" "$COMPOSE_FILE"

# Stop existing stack
echo "🛑 Bringing down existing containers..."
docker compose -f docker-compose.yml down || true

# Removing some unwanted volumes
sudo ls /var/lib/docker/volumes/ | grep -v '^cicd_sites' | xargs -r docker volume rm || true
sudo mkdir -p /var/lib/docker/volumes/cicd_{config,env,apps,assets,logs}/_data || true

#sudo chown -R "$(whoami):docker" /var/lib/docker/volumes/cicd_*
#sudo chmod -R 775 /var/lib/docker/volumes/cicd_*

# Start the stack
echo "🚀 Starting containers..."
docker compose -f "$COMPOSE_FILE" up -d

echo "✅ Deployment complete"
