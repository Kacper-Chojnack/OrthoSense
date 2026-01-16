#!/bin/bash
set -e

# Load environment variables from .env if present
if [ -f .env ]; then
  export $(cat .env | xargs)
fi

echo "🔍 Running SonarQube Analysis for OrthoSense"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Backend Analysis
echo -e "${BLUE}📦 Analyzing Backend...${NC}"
cd backend

# Run tests with coverage
echo "Running backend tests (skipping E2E)..."
./venv/bin/pytest tests/ \
  --ignore=tests/test_e2e_video_analysis.py \
  --cov=app \
  --cov-report=xml:coverage.xml \
  --cov-report=term \
  --junitxml=test-results.xml

# Run linters
echo "Running Ruff..."
./venv/bin/ruff check app/ --output-format=json > ruff-report.json || true

echo "Running MyPy..."
./venv/bin/mypy app/ --junit-xml mypy-report.xml || true

# SonarQube scan
echo "Running SonarQube scanner..."
sonar-scanner \
  -Dsonar.projectKey=orthosense-backend \
  -Dsonar.sources=app \
  -Dsonar.tests=tests \
  -Dsonar.python.coverage.reportPaths=coverage.xml \
  -Dsonar.python.xunit.reportPath=test-results.xml \
  -Dsonar.python.ruff.reportPaths=ruff-report.json \
  -Dsonar.python.mypy.reportPaths=mypy-report.xml \
  -Dsonar.python.version=3.13 \
  -Dsonar.host.url=http://localhost:9000 \
  -Dsonar.token=${SONAR_TOKEN}

cd ..

# Frontend Analysis
echo -e "${BLUE}📱 Analyzing Frontend...${NC}"

# Run tests with coverage
echo "Running Flutter tests..."
flutter test --coverage

# Run analyzer
echo "Running Flutter analyze..."
flutter analyze --no-fatal-warnings --write=flutter-analyze.txt || true

# SonarQube scan
echo "Running SonarQube scanner..."
sonar-scanner \
  -Dproject.settings=config/sonar/sonar-project-frontend.properties \
  -Dsonar.host.url=http://localhost:9000 \
  -Dsonar.token=${SONAR_TOKEN}

echo -e "${GREEN}✅ Analysis complete! Check results at http://localhost:9000${NC}"
