"""AI analysis endpoint for processing pose estimation data from Flutter app.

Accepts pre-processed MediaPipe landmarks and returns exercise analysis results.
Protected by JWT authentication.
"""

from typing import Any

from fastapi import APIRouter, HTTPException, Request, status
from fastapi.concurrency import run_in_threadpool
from pydantic import BaseModel, Field

from app.core.deps import ActiveUser
from app.core.logging import get_logger

router = APIRouter()
logger = get_logger(__name__)


class Landmark(BaseModel):
    """Single MediaPipe pose landmark."""

    x: float = Field(..., description="Normalized x coordinate (0-1)")
    y: float = Field(..., description="Normalized y coordinate (0-1)")
    z: float = Field(..., description="Depth coordinate")
    visibility: float = Field(
        default=1.0, ge=0.0, le=1.0, description="Landmark visibility confidence"
    )


class Frame(BaseModel):
    """Single frame of pose estimation data."""

    landmarks: list[Landmark] = Field(
        ..., min_length=33, max_length=33, description="33 MediaPipe pose landmarks"
    )
    timestamp: str | None = Field(default=None, description="ISO timestamp string")
    confidence: float = Field(
        default=1.0, ge=0.0, le=1.0, description="Detection confidence"
    )


class SessionData(BaseModel):
    """Session data containing multiple frames of pose landmarks."""

    frames: list[Frame] = Field(
        ..., min_length=1, description="List of pose frames to analyze"
    )


class AnalysisResult(BaseModel):
    """Result of AI exercise analysis."""

    exercise: str = Field(..., description="Detected exercise name")
    confidence: float = Field(..., description="Classification confidence (0-1)")
    text_report: str = Field(..., description="Detailed text report")
    is_correct: bool = Field(..., description="Whether form is correct")
    feedback: str = Field(..., description="Feedback message for user")


class AnalysisError(BaseModel):
    """Error response from analysis."""

    error: str = Field(..., description="Error message")


@router.post(
    "/analyze",
    response_model=AnalysisResult | AnalysisError,
    responses={
        200: {"description": "Successful analysis"},
        400: {"description": "Invalid input data"},
        503: {"description": "AI system not available"},
    },
)
async def analyze_session(
    data: SessionData,
    request: Request,
    current_user: ActiveUser,
) -> dict[str, Any]:
    """Analyze pose estimation session data from Flutter app.

    Processes pre-extracted MediaPipe landmarks and returns exercise
    classification with form analysis feedback.

    Requires authentication.
    """
    # Check if AI system is available
    ai_system = request.app.state.ai_system
    if ai_system is None:
        logger.error("ai_system_unavailable")
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="AI analysis system is not available",
        )

    # Convert Pydantic models to dict format expected by AI system
    session_data = [
        {
            "landmarks": [
                {"x": lm.x, "y": lm.y, "z": lm.z, "visibility": lm.visibility}
                for lm in frame.landmarks
            ],
            "timestamp": frame.timestamp,
            "confidence": frame.confidence,
        }
        for frame in data.frames
    ]

    logger.info(
        "analysis_started",
        user_id=str(current_user.id),
        frame_count=len(data.frames),
    )

    # Run CPU-intensive AI inference in thread pool to avoid blocking
    result = await run_in_threadpool(ai_system.analyze_session_data, session_data)

    # Check for errors from AI system
    if "error" in result:
        logger.warning(
            "analysis_failed",
            user_id=str(current_user.id),
            error=result["error"],
        )
        return result

    logger.info(
        "analysis_completed",
        user_id=str(current_user.id),
        exercise=result.get("exercise"),
        is_correct=result.get("is_correct"),
    )

    return result
