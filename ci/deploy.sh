#!/bin/bash

set -euo pipefail

echo "[DEBUG] CI_COMMIT_SHA: ${CI_COMMIT_SHA:-missing}"
echo "[DEBUG] DOCKER_REGISTRY_URL: ${DOCKER_REGISTRY_URL:-missing}"

# Path setup
APP_DIR="/home/hrmsdev/cicd"
COMPOSE_FILE="$APP_DIR/docker-compose.yml"

aws ecr get-login-password --region ap-south-1 | docker login --username AWS --password-stdin $DOCKER_REGISTRY_URL

echo "🔄 Changing to app directory: $APP_DIR"
cd "$APP_DIR"

# Stop existing stack
echo "🛑 Bringing down existing containers..."
docker compose -f docker-compose.yml down --volumes || true

# Replace placeholder in compose file
echo "✏️  Replacing CI_COMMIT_SHA in compose file..."
sed -i -e "s/\\\$CI_COMMIT_SHA/${CI_COMMIT_SHA}/g" "$COMPOSE_FILE"

# Pull latest images
echo "⬇️  Pulling latest images..."
docker compose -f "$COMPOSE_FILE" pull --quiet

# Start the stack
echo "🚀 Starting containers..."
docker compose -f "$COMPOSE_FILE" up -d --quiet-pull --no-build

echo "✅ Deployment complete"

