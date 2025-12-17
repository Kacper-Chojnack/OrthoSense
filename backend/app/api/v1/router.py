"""API v1 router aggregating all endpoint routers."""

from fastapi import APIRouter

from app.api.v1.endpoints import analysis, auth, measurements

api_router = APIRouter()

api_router.include_router(
    auth.router,
    prefix="/auth",
    tags=["auth"],
)

api_router.include_router(
    measurements.router,
    prefix="/measurements",
    tags=["measurements"],
)

api_router.include_router(
    analysis.router,
    prefix="/analysis",
    tags=["analysis"],
)
