#!/bin/bash
set -e

echo "Setting up Docker environment..."

# Create .env if not exists
if [ ! -f backend/.env ]; then
    echo "Creating backend/.env from example..."
    cp backend/.env.example backend/.env
    # Generate a random secret key
    sed -i '' "s/change-this-to-a-secure-random-string-in-production/$(openssl rand -hex 32)/" backend/.env
fi

# Ensure scripts are executable
chmod +x scripts/*.sh

echo "Setup complete. Run ./scripts/docker-dev.sh to start."
