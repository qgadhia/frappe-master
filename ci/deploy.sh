#!/bin/bash

set -euo pipefail

source /home/factory/$DEPLOYMENT_NAME/build.env
MAX_ATTEMPTS=3
RETRY_DELAY=5 

echo "[DEBUG] CI_COMMIT_SHA: ${CI_COMMIT_SHA:-missing}"

# Path setup
APP_DIR="/home/$VM_USER/$DEPLOYMENT_NAME"
COMPOSE_FILE="$APP_DIR/docker-compose.yml"

echo "🔄 Changing to app directory: $APP_DIR"
cd "$APP_DIR"

# Replace placeholder in compose file
echo "✏️  Replacing CI_COMMIT_SHA in compose file..."
sed -i -e "s/\\\$CI_COMMIT_SHA/${CI_COMMIT_SHA}/g" "$COMPOSE_FILE"

# Stop existing stack
echo "🛑 Bringing down existing containers..."
docker compose -f docker-compose.yml down  || true

# Removing some unwanted volumes
sudo ls /var/lib/docker/volumes/ | grep -v '^$DEPLOYMENT_NAME_sites' | xargs -r docker volume rm || true
sudo mkdir -p /var/lib/docker/volumes/$DEPLOYMENT_NAME_{config,env,apps,assets,logs}/_data || true
	
# Start the stack
echo "🚀 Starting containers..."
# --- Start the stack with Retry Loop ---
echo "🚀 Starting containers with retry (Max attempts: $MAX_ATTEMPTS)..."
ATTEMPT=1
until docker compose -f "$COMPOSE_FILE" up -d; do
  if [ $ATTEMPT -ge $MAX_ATTEMPTS ]; then
    echo "❌ Deployment failed after $MAX_ATTEMPTS attempts. Exiting."
    exit 1
  fi
  
  echo "⚠️ Deployment failed on attempt $ATTEMPT. Cleaning up failed containers and retrying..."

  # Bring down stack & volumes
  docker compose -f "$COMPOSE_FILE" down -t 1 || true

  # Force-remove any stuck containers
  docker ps -a --filter "name=$DEPLOYMENT_NAME" --format "{{.ID}}" | xargs -r docker rm -f || true

  echo "🧹 Waiting 10 seconds for Docker cleanup..."
  sleep 10

  ATTEMPT=$((ATTEMPT+1))
  sleep_time=$((RETRY_DELAY * ATTEMPT))
  echo "⏳ Waiting ${sleep_time}s before retry..."
  sleep $sleep_time
done

echo "✅ Deployment complete"

