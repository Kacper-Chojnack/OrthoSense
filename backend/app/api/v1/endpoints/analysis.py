"""Exercise analysis endpoints.

Provides metadata about supported exercises.
All movement analysis is performed client-side (Edge AI) for privacy.
"""

from typing import Any

from fastapi import APIRouter

from app.ai.core.config import EXERCISE_NAMES

router = APIRouter()


@router.get("/exercises")
async def list_exercises() -> dict[str, Any]:
    """List available exercises for analysis."""
    return {
        "exercises": [
            {"id": idx, "name": name} for idx, name in EXERCISE_NAMES.items()
        ],
        "ai_available": True,
    }
