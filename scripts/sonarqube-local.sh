#!/bin/bash
# Uruchom lokalny SonarQube
docker-compose -f docker-compose.sonarqube.yml up -d

echo "⏳ Waiting for SonarQube to start..."
until curl -s http://localhost:9000/api/system/status | grep -q "UP"; do
  sleep 5
done

echo "✅ SonarQube is ready!"
echo "🌐 Access at: http://localhost:9000"
echo "👤 Default credentials: admin / admin"
