"""API v1 router aggregating all endpoint routers."""

from fastapi import APIRouter

from app.api.v1.endpoints import (
    analysis,
    auth,
    exercise_videos,
    exercises,
    patients,
    plans,
    protocols,
    sessions,
)

api_router = APIRouter()

api_router.include_router(
    analysis.router,
    prefix="/analysis",
    tags=["analysis"],
)

api_router.include_router(
    auth.router,
    prefix="/auth",
    tags=["auth"],
)

api_router.include_router(
    exercises.router,
    prefix="/exercises",
    tags=["exercises"],
)

api_router.include_router(
    exercise_videos.router,
    prefix="/exercise-videos",
    tags=["exercise-videos"],
)

api_router.include_router(
    protocols.router,
    prefix="/protocols",
    tags=["protocols"],
)

api_router.include_router(
    plans.router,
    prefix="/plans",
    tags=["treatment-plans"],
)

api_router.include_router(
    patients.router,
    prefix="/patients",
    tags=["patients"],
)

api_router.include_router(
    sessions.router,
    prefix="/sessions",
    tags=["sessions"],
)
