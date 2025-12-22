# SonarQube Integration Guide for OrthoSense

## 1. Introduction
This document details the integration of SonarQube for continuous code quality inspection in the OrthoSense project. We monitor both the Python Backend (FastAPI) and Flutter Frontend.

**Key Metrics Monitored:**
- **Reliability:** Bugs and potential logic errors.
- **Security:** Vulnerabilities and Security Hotspots.
- **Maintainability:** Code smells, technical debt, and complexity.
- **Coverage:** Unit test coverage (Target: >80%).
- **Duplications:** Copy-pasted code blocks (Target: <3%).

## 2. Local Setup

### Prerequisites
- Docker & Docker Compose
- `sonar-scanner` CLI installed locally (optional, for manual runs)

### Step-by-Step
1. **Start SonarQube:**
   ```bash
   ./scripts/sonarqube-local.sh
   ```
2. **Access Dashboard:**
   Open [http://localhost:9000](http://localhost:9000).
   Login with `admin` / `admin`. Change password when prompted.

3. **Create Projects:**
   - Create two manual projects: `orthosense-backend` and `orthosense-frontend`.
   - Use the "Locally" option to generate a token.

4. **Run Analysis:**
   Export your token and run the script:
   ```bash
   export SONAR_TOKEN=sqp_xxxxxxxxxxxxxxxxxxxxxxxxxxxx
   ./scripts/run-sonar-analysis.sh
   ```

## 3. CI/CD Integration (GitHub Actions)

The workflow is defined in `.github/workflows/sonarqube.yml`.

**Required Secrets:**
- `SONAR_HOST_URL`: URL to your SonarQube instance (or SonarCloud).
- `SONAR_TOKEN`: Authentication token.

## 4. Quality Gate

We use a custom "OrthoSense Quality Gate" (import `sonarqube-quality-gate.json`).

**Thresholds:**
- **Coverage on New Code:** < 80% fails the gate.
- **New Bugs/Vulnerabilities:** > 0 fails the gate.
- **New Code Smells:** > 10 fails the gate.

## 5. Troubleshooting

**Common Issues:**
- **"No space left on device" (Docker):** Prune unused images `docker system prune`.
- **Coverage not showing:** Ensure paths in `sonar-project.properties` match the generated XML/LCOV files.
- **Elasticsearch errors:** Increase host map count: `sysctl -w vm.max_map_count=262144`.

## 6. Thesis Metrics Baseline

| Metric | Before SonarQube | Target |
|--------|------------------|--------|
| Test Coverage | ~40% | >80% |
| Code Smells | Unknown | <50 |
| Technical Debt | Unknown | <5 days |
| Duplications | Unknown | <3% |
