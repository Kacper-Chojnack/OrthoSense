"""Pydantic schemas for AI analysis endpoints.

These schemas define the request/response models for video and frame analysis.
"""

from datetime import datetime
from enum import Enum
from uuid import UUID

from pydantic import BaseModel, ConfigDict, Field


class AnalysisStatus(str, Enum):
    """Status of an analysis task."""

    PENDING = "pending"
    PROCESSING = "processing"
    COMPLETED = "completed"
    FAILED = "failed"


class VideoAnalysisRequest(BaseModel):
    """Request model for video upload analysis."""

    session_id: UUID | None = Field(
        default=None,
        description="Optional session ID to associate with the analysis",
    )
    exercise_hint: str | None = Field(
        default=None,
        description="Optional hint for expected exercise type",
    )


class VideoAnalysisResponse(BaseModel):
    """Response model for video analysis initiation."""

    model_config = ConfigDict(from_attributes=True)

    task_id: str = Field(description="Unique task identifier for tracking")
    session_id: str = Field(description="Session ID for retrieving results")
    status: AnalysisStatus = Field(description="Current status of the analysis")
    message: str = Field(description="Human-readable status message")
    created_at: datetime = Field(
        default_factory=datetime.utcnow,
        description="Task creation timestamp",
    )


class AnalysisResult(BaseModel):
    """Complete analysis result model."""

    model_config = ConfigDict(from_attributes=True)

    session_id: str = Field(description="Session identifier")
    task_id: str | None = Field(default=None, description="Task identifier if async")
    status: AnalysisStatus = Field(description="Analysis status")
    exercise: str = Field(description="Detected exercise type")
    confidence: float = Field(ge=0.0, le=1.0, description="Overall confidence")
    is_correct: bool = Field(description="Whether exercise form was correct")
    feedback: dict[str, str | bool] = Field(
        default_factory=dict,
        description="Feedback dictionary with error names as keys and details as values",
    )
    text_report: str | None = Field(
        default=None,
        description="Detailed text report of the analysis",
    )
    metrics: dict = Field(
        default_factory=dict,
        description="Detailed metrics from analysis",
    )
    created_at: datetime = Field(
        default_factory=datetime.utcnow,
        description="Analysis timestamp",
    )
    completed_at: datetime | None = Field(
        default=None,
        description="Completion timestamp",
    )


class AnalysisError(BaseModel):
    """Error response model for analysis failures."""

    error: str = Field(description="Error type")
    detail: str = Field(description="Detailed error message")
    session_id: str | None = Field(default=None, description="Session ID if available")


class TaskStatusResponse(BaseModel):
    """Response model for task status queries."""

    task_id: str = Field(description="Task identifier")
    session_id: str = Field(description="Session identifier")
    status: AnalysisStatus = Field(description="Current status")
    progress: float | None = Field(
        default=None,
        ge=0.0,
        le=100.0,
        description="Progress percentage if available",
    )
    message: str | None = Field(default=None, description="Status message")
    result: AnalysisResult | None = Field(
        default=None, description="Result if completed"
    )


class LandmarksAnalysisRequest(BaseModel):
    """Request model for landmarks-based analysis (Edge AI)."""

    landmarks: list[list[list[float]]] = Field(
        description="Pose landmarks: frames × 33 joints × 3 coordinates [x, y, z]"
    )
    fps: float = Field(
        default=30.0,
        ge=1.0,
        le=120.0,
        description="Video frames per second",
    )
