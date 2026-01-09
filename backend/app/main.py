"""FastAPI application entry point.

Configures CORS, logging, database lifecycle, and WebSocket endpoints.
"""

from collections.abc import AsyncGenerator
from contextlib import asynccontextmanager

from fastapi import FastAPI, HTTPException, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.middleware.gzip import GZipMiddleware
from fastapi.middleware.trustedhost import TrustedHostMiddleware

from app.api.v1.router import api_router
from app.core.config import settings
from app.core.database import init_db
from app.core.exceptions import global_exception_handler, http_exception_handler
from app.core.logging import get_logger, setup_logging
from app.core.rate_limit import api_limiter

setup_logging(
    json_logs=not settings.debug,
    log_level="DEBUG" if settings.debug else "INFO",
)
logger = get_logger(__name__)


@asynccontextmanager
async def lifespan(app: FastAPI) -> AsyncGenerator[None]:
    """Application lifecycle manager."""
    logger.info("application_startup", database_url=settings.database_url[:20] + "...")
    await init_db()
    logger.info("database_initialized")

    # AI system will be initialized lazily on first use (not during startup)
    # This prevents blocking the application startup with heavy model loading
    logger.info("ai_system_will_initialize_lazily")

    yield
    logger.info("application_shutdown")


app = FastAPI(
    title=settings.project_name,
    openapi_url=f"{settings.api_v1_prefix}/openapi.json",
    lifespan=lifespan,
)

# Register exception handlers for production safety
app.add_exception_handler(Exception, global_exception_handler)
app.add_exception_handler(HTTPException, http_exception_handler)

# GZip Compression (30% bandwidth savings)
# Compress responses larger than 500 bytes
app.add_middleware(GZipMiddleware, minimum_size=500)

# Trusted Host Middleware (Security)
# Prevents HTTP Host header attacks
app.add_middleware(
    TrustedHostMiddleware,
    allowed_hosts=settings.allowed_hosts,
)

# 2. CORS for Flutter app - Secure configuration
# Note: allow_credentials=True requires specific origins, not wildcards
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origins,
    allow_credentials=True,
    allow_methods=["GET", "POST", "PUT", "DELETE", "PATCH", "OPTIONS"],
    allow_headers=["Authorization", "Content-Type", "X-Requested-With"],
)


# Global Security Headers & Rate Limiting
@app.middleware("http")
async def security_and_rate_limit_middleware(request: Request, call_next):
    """Add security headers and enforce global rate limits."""
    # Global Rate Limiting (skip for health checks)
    if request.url.path != "/health" and settings.rate_limit_enabled:
        await api_limiter.check(request, "global")

    response = await call_next(request)

    # Security Headers (HTTPS Enforcement & Hardening)
    # HSTS: Tell browser to only use HTTPS for next 2 years
    response.headers["Strict-Transport-Security"] = (
        "max-age=63072000; includeSubDomains; preload"
    )
    # Prevent MIME type sniffing
    response.headers["X-Content-Type-Options"] = "nosniff"
    # Prevent clickjacking
    response.headers["X-Frame-Options"] = "DENY"
    # Enable XSS protection in older browsers
    response.headers["X-XSS-Protection"] = "1; mode=block"
    # Control referrer information
    response.headers["Referrer-Policy"] = "strict-origin-when-cross-origin"

    return response


app.include_router(api_router, prefix=settings.api_v1_prefix)


@app.get("/health")
async def health_check() -> dict[str, str]:
    """Health check endpoint for load balancers."""
    return {"status": "healthy"}


@app.get("/health/db")
async def health_check_db() -> dict[str, str]:
    """Database connectivity health check."""
    from sqlalchemy import text

    from app.core.database import engine

    try:
        async with engine.connect() as conn:
            await conn.execute(text("SELECT 1"))
        return {"status": "healthy", "database": "connected"}
    except Exception as e:
        logger.error("db_health_check_failed", error=str(e))
        return {"status": "unhealthy", "database": "disconnected", "error": str(e)}


@app.get("/health/config")
async def health_check_config() -> dict[str, str]:
    """Configuration health check (debug only)."""
    if not settings.debug:
        return {"status": "forbidden"}
    return {
        "database_url_prefix": settings.database_url[:30] + "...",
        "rate_limit_enabled": str(settings.rate_limit_enabled),
        "debug": str(settings.debug),
    }
