"""Session model for tracking patient exercise sessions."""

from datetime import UTC, datetime
from enum import Enum
from uuid import UUID, uuid4

from sqlmodel import Column, Field, JSON, Relationship, SQLModel


def utc_now() -> datetime:
    """Get current UTC datetime."""
    return datetime.now(UTC)


class SessionStatus(str, Enum):
    """Status of an exercise session."""

    IN_PROGRESS = "in_progress"
    COMPLETED = "completed"
    ABANDONED = "abandoned"  # Started but not finished
    SKIPPED = "skipped"  # Marked as skipped by patient


class SessionBase(SQLModel):
    """Shared session fields."""

    scheduled_date: datetime
    status: SessionStatus = Field(default=SessionStatus.IN_PROGRESS)
    notes: str = Field(default="")
    pain_level_before: int | None = Field(default=None, ge=0, le=10)
    pain_level_after: int | None = Field(default=None, ge=0, le=10)
    overall_score: float | None = Field(default=None, ge=0, le=100)


class Session(SessionBase, table=True):
    """Database table model for exercise sessions."""

    __tablename__ = "sessions"

    id: UUID = Field(default_factory=uuid4, primary_key=True)
    patient_id: UUID = Field(foreign_key="users.id", index=True)
    treatment_plan_id: UUID = Field(foreign_key="treatment_plans.id", index=True)
    started_at: datetime | None = Field(default=None)
    completed_at: datetime | None = Field(default=None)
    duration_seconds: int | None = Field(default=None)
    created_at: datetime = Field(default_factory=utc_now)
    # Device info for debugging
    device_info: dict = Field(default_factory=dict, sa_column=Column(JSON))

    # Relationships
    patient: "User" = Relationship(back_populates="sessions")
    treatment_plan: "TreatmentPlan" = Relationship(back_populates="sessions")
    exercise_results: list["SessionExerciseResult"] = Relationship(
        back_populates="session",
        sa_relationship_kwargs={"cascade": "all, delete-orphan"},
    )


# Forward references
from app.models.treatment_plan import TreatmentPlan  # noqa: E402
from app.models.user import User  # noqa: E402


class SessionExerciseResult(SQLModel, table=True):
    """Results for individual exercises within a session."""

    __tablename__ = "session_exercise_results"

    id: UUID = Field(default_factory=uuid4, primary_key=True)
    session_id: UUID = Field(foreign_key="sessions.id", index=True)
    exercise_id: UUID = Field(foreign_key="exercises.id", index=True)
    sets_completed: int = Field(default=0)
    reps_completed: int = Field(default=0)
    hold_seconds_achieved: int | None = Field(default=None)
    score: float | None = Field(default=None, ge=0, le=100)
    # Detailed metrics from pose estimation (angles, velocities, etc.)
    metrics_data: dict = Field(default_factory=dict, sa_column=Column(JSON))
    # AI feedback generated during exercise
    feedback: str = Field(default="")
    started_at: datetime | None = Field(default=None)
    completed_at: datetime | None = Field(default=None)

    # Relationships
    session: Session = Relationship(back_populates="exercise_results")
    exercise: "Exercise" = Relationship()


# Forward reference
from app.models.exercise import Exercise  # noqa: E402


class SessionCreate(SQLModel):
    """Schema for creating a session."""

    treatment_plan_id: UUID
    scheduled_date: datetime
    notes: str = ""


class SessionStart(SQLModel):
    """Schema for starting a session."""

    pain_level_before: int | None = Field(default=None, ge=0, le=10)
    device_info: dict = Field(default_factory=dict)


class SessionComplete(SQLModel):
    """Schema for completing a session."""

    pain_level_after: int | None = Field(default=None, ge=0, le=10)
    notes: str = ""


class SessionRead(SQLModel):
    """Schema for reading session data."""

    id: UUID
    patient_id: UUID
    treatment_plan_id: UUID
    scheduled_date: datetime
    status: SessionStatus
    notes: str
    pain_level_before: int | None
    pain_level_after: int | None
    overall_score: float | None
    started_at: datetime | None
    completed_at: datetime | None
    duration_seconds: int | None
    created_at: datetime


class SessionReadWithResults(SessionRead):
    """Schema for reading session with exercise results."""

    exercise_results: list["SessionExerciseResultRead"] = []


class SessionExerciseResultCreate(SQLModel):
    """Schema for submitting exercise result."""

    exercise_id: UUID
    sets_completed: int = 0
    reps_completed: int = 0
    hold_seconds_achieved: int | None = None
    score: float | None = None
    metrics_data: dict = Field(default_factory=dict)
    feedback: str = ""


class SessionExerciseResultRead(SQLModel):
    """Schema for reading exercise result."""

    id: UUID
    session_id: UUID
    exercise_id: UUID
    sets_completed: int
    reps_completed: int
    hold_seconds_achieved: int | None
    score: float | None
    metrics_data: dict
    feedback: str
    started_at: datetime | None
    completed_at: datetime | None


class SessionSummary(SQLModel):
    """Summary of a session for dashboard display."""

    session_id: UUID
    patient_id: UUID
    patient_name: str
    scheduled_date: datetime
    status: SessionStatus
    overall_score: float | None
    exercises_completed: int
    total_exercises: int
    duration_seconds: int | None
