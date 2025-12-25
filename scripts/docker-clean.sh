#!/bin/bash
# Clean Docker to free up space
set -e

echo "🧹 Cleaning Docker..."

# Remove stopped containers
echo "Removing stopped containers..."
docker container prune -f

# Remove unused images
echo "Removing unused images..."
docker image prune -a -f

# Remove unused volumes
echo "Removing unused volumes..."
docker volume prune -f

# Remove unused networks
echo "Removing unused networks..."
docker network prune -f

# Remove build cache
echo "Removing build cache..."
docker builder prune -a -f

echo "✅ Docker cleanup complete!"
echo ""
echo "📊 Current Docker disk usage:"
docker system df


