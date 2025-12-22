#!/bin/bash
# Uruchom lokalny SonarQube
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

docker-compose -f "$PROJECT_ROOT/config/docker/docker-compose.sonarqube.yml" up -d

echo "⏳ Waiting for SonarQube to start..."
until curl -s http://localhost:9000/api/system/status | grep -q "UP"; do
  sleep 5
done

echo "✅ SonarQube is ready!"
echo "🌐 Access at: http://localhost:9000"
echo "👤 Default credentials: admin / admin"
