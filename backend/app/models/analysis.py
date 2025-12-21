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


class FrameAnalysisRequest(BaseModel):
    """Request model for single frame analysis."""

    session_id: UUID | None = Field(
        default=None,
        description="Optional session ID to associate with the analysis",
    )
    exercise_hint: str | None = Field(
        default=None,
        description="Optional hint for expected exercise type",
    )


class FrameAnalysisResponse(BaseModel):
    """Response model for single frame analysis."""

    model_config = ConfigDict(from_attributes=True)

    timestamp: float = Field(description="Timestamp of the analysis")
    exercise: str = Field(description="Detected exercise type")
    confidence: float = Field(ge=0.0, le=1.0, description="Detection confidence")
    is_correct: bool = Field(description="Whether the exercise form is correct")
    feedback: list[str] = Field(
        default_factory=list, description="List of feedback messages"
    )
    landmarks_detected: bool = Field(
        default=True, description="Whether pose landmarks were detected"
    )
    metrics: dict = Field(
        default_factory=dict,
        description="Additional metrics from analysis",
    )


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
    feedback: list[str] = Field(
        default_factory=list,
        description="Feedback messages for improvement",
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
