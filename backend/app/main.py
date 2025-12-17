"""FastAPI application entry point.

Configures CORS, logging, and database lifecycle.
"""

from collections.abc import AsyncGenerator
from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.api.v1.router import api_router
from app.core.config import settings
from app.core.database import init_db
from app.core.logging import get_logger, setup_logging

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

    # Initialize AI system (loads ML models)
    logger.info("loading_ai_models")
    try:
        from app.ai.core.system import OrthoSenseSystem
        app.state.ai_system = OrthoSenseSystem()
        logger.info("ai_models_loaded")
    except Exception as e:
        logger.warning("ai_models_load_failed", error=str(e))
        app.state.ai_system = None

    yield
    logger.info("application_shutdown")


app = FastAPI(
    title=settings.project_name,
    openapi_url=f"{settings.api_v1_prefix}/openapi.json",
    lifespan=lifespan,
)

# CORS for Flutter app
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(api_router, prefix=settings.api_v1_prefix)


@app.get("/health")
async def health_check() -> dict[str, str]:
    """Health check endpoint for load balancers."""
    return {"status": "healthy"}
