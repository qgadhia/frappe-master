#!/bin/bash

set -euo pipefail

source /home/factory/$DEPLOYMENT_NAME/ci/build.env
MAX_ATTEMPTS=3
RETRY_DELAY=5 

echo "[DEBUG] CI_COMMIT_SHA: ${CI_COMMIT_SHA:-missing}"

# Path setup
APP_DIR="/home/$VM_USER/ci/$DEPLOYMENT_NAME"
COMPOSE_FILE="$APP_DIR/docker-compose.yml"

echo "🔄 Changing to app directory: $APP_DIR"
cd "$APP_DIR"

# Replace placeholder in compose file
echo "✏️  Replacing CI_COMMIT_SHA in compose file..."
sed -i -e "s/\\\$CI_COMMIT_SHA/${CI_COMMIT_SHA}/g" "$COMPOSE_FILE"

# Stop existing stack
echo "🛑 Bringing down existing containers..."
docker compose -f docker-compose.yml down || true

# Start the stack
echo "🚀 Starting containers..."
docker compose -f "$COMPOSE_FILE" up -d --no-build

echo "✅ Deployment complete"