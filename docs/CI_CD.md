# CI/CD Pipeline Documentation

## Overview
OrthoSense uses GitHub Actions for Continuous Integration and Deployment. The pipeline ensures code quality, security, and stability across the Hybrid AI architecture (Flutter + Python).

## Workflows

### 1. Backend CI (`backend-ci.yml`)
- **Triggers:** Push/PR to `backend/**`
- **Checks:**
  - **Linting:** Ruff (Strict rules)
  - **Type Checking:** MyPy (Strict mode)
  - **Testing:** Pytest with coverage (>80% required)
  - **Security:** Bandit (SAST) & Safety (Dependencies)
  - **Build:** Docker image creation smoke test

### 2. Frontend CI (`frontend-ci.yml`)
- **Triggers:** Push/PR to `lib/**`, `test/**`
- **Checks:**
  - **Analysis:** `flutter analyze` & `dart format`
  - **Testing:** Unit/Widget tests with coverage
  - **Builds:** Generates Android APK and Web artifacts

### 3. Integration Tests (`integration-tests.yml`)
- **Triggers:** Nightly or PR to main
- **Action:** Spins up full Docker Compose stack (Backend + DB) and runs E2E API tests.

### 4. Code Quality (`code-quality.yml`)
- **Triggers:** Push to main/develop, PRs
- **Action:** Runs SonarQube/SonarCloud analysis for both Backend and Frontend.

## Local Testing
Before pushing, run these commands to simulate CI:

**Backend:**
```bash
cd backend
ruff check .
mypy app
pytest
```

**Frontend:**
```bash
flutter analyze
flutter test
```

## Secrets Configuration
Ensure these secrets are set in GitHub Repository Settings:
- `CODECOV_TOKEN`: For coverage reports
- `SONAR_TOKEN`: For SonarCloud analysis
- `DOCKER_USERNAME` / `DOCKER_PASSWORD`: For pushing images (Future)
- `ANDROID_KEYSTORE_BASE64`: For signing release APKs (Future)
