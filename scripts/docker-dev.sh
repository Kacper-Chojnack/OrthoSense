#!/bin/bash
# Start development environment with hot-reload
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
DOCKER_DIR="$PROJECT_ROOT/config/docker"

echo "🚀 Starting OrthoSense in DEVELOPMENT mode..."

docker compose \
  -f "$DOCKER_DIR/docker-compose.yml" \
  -f "$DOCKER_DIR/docker-compose.dev.yml" \
  up --build
