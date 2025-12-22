# OrthoSense Docker Setup

This guide explains how to run the OrthoSense platform using Docker.

## Prerequisites
- Docker Engine 20.10+
- Docker Compose v2+

## Quick Start

1. **Setup Environment:**
   ```bash
   chmod +x scripts/*.sh
   ./scripts/docker-setup.sh
   ```

2. **Run Development (Hot Reload):**
   ```bash
   ./scripts/docker-dev.sh
   ```
   - Backend API: http://localhost:8000/docs
   - Database (Adminer): http://localhost:8080

3. **Run Production (Web App + API):**
   ```bash
   ./scripts/docker-prod.sh
   ```
   - Web App: http://localhost
   - API: http://localhost/api/v1/...

## Architecture

- **Backend:** Python 3.13 FastAPI container.
  - In `dev`: Code is mounted via volume for live updates.
  - In `prod`: Code is copied into the image.
- **Frontend:** Flutter Web.
  - Only runs in `prod` mode via Docker.
  - Served via Nginx, which also acts as a reverse proxy for the API.
- **Database:** PostgreSQL 16.
- **Cache:** Redis 7 (for rate limiting).

## Troubleshooting

**"No space left on device" during build:**
This usually happens when installing PyTorch. We use the CPU-only version to mitigate this. Run `docker system prune -a` to clear space.

**Database connection failed:**
Ensure the `db` service is healthy. The backend waits for it, but on slower machines, it might time out. Check logs: `docker-compose logs db`.

**Permission denied on scripts:**
Run `chmod +x scripts/*.sh`.
