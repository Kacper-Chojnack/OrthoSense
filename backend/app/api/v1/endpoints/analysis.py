"""Exercise analysis endpoints.

Provides metadata about supported exercises and landmark analysis.
Video processing is handled client-side via ML Kit.
"""

from typing import Any

from fastapi import (
    APIRouter,
    HTTPException,
    status,
)

from app.ai.core.config import EXERCISE_NAMES
from app.ai.core.system import OrthoSenseSystem
from app.core.logging import get_logger
from app.models.analysis import LandmarksAnalysisRequest

router = APIRouter()
logger = get_logger(__name__)


@router.get("/exercises")
async def list_exercises() -> dict[str, Any]:
    """List available exercises for analysis."""
    return {
        "exercises": [
            {"id": idx, "name": name} for idx, name in EXERCISE_NAMES.items()
        ],
        "ai_available": True,
    }


@router.post("/landmarks", status_code=status.HTTP_200_OK)
async def analyze_landmarks(
    request: LandmarksAnalysisRequest,
) -> dict[str, Any]:
    """
    Analyze exercise from pre-extracted pose landmarks (ML Kit).

    This endpoint receives landmarks extracted on the client device using ML Kit.
    """
    try:
        if not request.landmarks:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="No landmarks provided",
            )

        for i, frame in enumerate(request.landmarks):
            if len(frame) != 33:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail=f"Frame {i} has {len(frame)} joints, expected 33 (BlazePose topology)",
                )
            if len(frame) > 0 and len(frame[0]) not in [3, 4]:
                 raise HTTPException(
                        status_code=status.HTTP_400_BAD_REQUEST,
                        detail=f"Frame {i} joint format invalid. Expected [x,y,z] or [x,y,z,visibility]",
                    )

        system = OrthoSenseSystem()
        result = system.analyze_landmarks(request.landmarks, request.exercise_name)
        
        if "error" in result:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST, detail=result["error"]
            )

        return result

    except HTTPException:
        raise
    except Exception as e:
        logger.error("landmarks_analysis_failed", error=str(e))
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Analysis failed: {e!s}",
        ) from e