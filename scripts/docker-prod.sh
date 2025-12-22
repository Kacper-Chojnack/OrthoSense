#!/bin/bash
# Start production environment (detached)
echo "Starting OrthoSense in PRODUCTION mode..."
docker-compose -f docker-compose.yml -f docker-compose.prod.yml up -d --build
