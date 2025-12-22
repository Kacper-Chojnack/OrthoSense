#!/bin/bash
# Start production environment (detached)
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
DOCKER_DIR="$PROJECT_ROOT/config/docker"

echo "🚀 Starting OrthoSense in PRODUCTION mode..."

docker-compose \
  -f "$DOCKER_DIR/docker-compose.yml" \
  -f "$DOCKER_DIR/docker-compose.prod.yml" \
  up -d --build

echo "✅ OrthoSense is running!"
echo "   Web App: http://localhost"
echo "   API:     http://localhost/api/v1/docs"
