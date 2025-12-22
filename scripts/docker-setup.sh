#!/bin/bash
# Initial Docker environment setup
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

echo "⚙️  Setting up Docker environment..."

# Create backend .env if not exists
if [ ! -f "$PROJECT_ROOT/backend/.env" ]; then
    echo "📝 Creating backend/.env from example..."
    cp "$PROJECT_ROOT/backend/.env.example" "$PROJECT_ROOT/backend/.env"
    
    # Generate a random secret key
    SECRET_KEY=$(openssl rand -hex 32)
    if [[ "$OSTYPE" == "darwin"* ]]; then
        sed -i '' "s/change-this-to-a-secure-random-string-in-production/$SECRET_KEY/" "$PROJECT_ROOT/backend/.env"
    else
        sed -i "s/change-this-to-a-secure-random-string-in-production/$SECRET_KEY/" "$PROJECT_ROOT/backend/.env"
    fi
fi

# Ensure scripts are executable
chmod +x "$SCRIPT_DIR"/*.sh

echo "✅ Setup complete!"
echo "   Run: ./scripts/docker-dev.sh to start development server"
