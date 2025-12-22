#!/bin/bash
# Start development environment with hot-reload
echo "Starting OrthoSense in DEVELOPMENT mode..."
docker-compose -f docker-compose.yml -f docker-compose.dev.yml up --build
