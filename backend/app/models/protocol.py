"""Protocol model for rehabilitation protocols (exercise templates)."""

from datetime import UTC, datetime
from enum import Enum
from uuid import UUID, uuid4

from sqlmodel import Field, Relationship, SQLModel


def utc_now() -> datetime:
    """Get current UTC datetime."""
    return datetime.now(UTC)


class ProtocolStatus(str, Enum):
    """Status of a protocol."""

    DRAFT = "draft"
    PUBLISHED = "published"
    ARCHIVED = "archived"


class ProtocolBase(SQLModel):
    """Shared protocol fields."""

    name: str = Field(max_length=255, index=True)
    description: str = Field(default="")
    condition: str = Field(default="", max_length=255)  # e.g., "ACL reconstruction"
    phase: str = Field(default="", max_length=100)  # e.g., "Phase 1: Acute"
    duration_weeks: int | None = Field(default=None, ge=1)
    frequency_per_week: int = Field(default=3, ge=1, le=14)
    status: ProtocolStatus = Field(default=ProtocolStatus.DRAFT)
    is_template: bool = Field(default=True)  # Can be used as template for plans


class Protocol(ProtocolBase, table=True):
    """Database table model for rehabilitation protocols."""

    __tablename__ = "protocols"

    id: UUID = Field(default_factory=uuid4, primary_key=True)
    created_by: UUID = Field(foreign_key="users.id", index=True)
    created_at: datetime = Field(default_factory=utc_now)
    updated_at: datetime | None = Field(default=None)

    # Relationships
    created_by_user: "User" = Relationship(back_populates="protocols_created")
    exercises: list["ProtocolExercise"] = Relationship(
        back_populates="protocol",
        sa_relationship_kwargs={"cascade": "all, delete-orphan"},
    )
    treatment_plans: list["TreatmentPlan"] = Relationship(back_populates="protocol")


# Forward references
from app.models.treatment_plan import TreatmentPlan  # noqa: E402
from app.models.user import User  # noqa: E402


class ProtocolExercise(SQLModel, table=True):
    """Link table between Protocol and Exercise with parameters."""

    __tablename__ = "protocol_exercises"

    id: UUID = Field(default_factory=uuid4, primary_key=True)
    protocol_id: UUID = Field(foreign_key="protocols.id", index=True)
    exercise_id: UUID = Field(foreign_key="exercises.id", index=True)
    order: int = Field(default=0)  # Order within the protocol
    sets: int = Field(default=3, ge=1)
    reps: int | None = Field(default=10, ge=1)  # None for time-based exercises
    hold_seconds: int | None = Field(default=None, ge=1)  # For static holds
    rest_seconds: int = Field(default=60, ge=0)
    notes: str = Field(default="")

    # Relationships
    protocol: Protocol = Relationship(back_populates="exercises")
    exercise: "Exercise" = Relationship(back_populates="protocol_exercises")


# Forward reference
from app.models.exercise import Exercise  # noqa: E402


class ProtocolCreate(SQLModel):
    """Schema for creating a protocol."""

    name: str = Field(max_length=255)
    description: str = ""
    condition: str = ""
    phase: str = ""
    duration_weeks: int | None = None
    frequency_per_week: int = 3
    status: ProtocolStatus = ProtocolStatus.DRAFT
    is_template: bool = True


class ProtocolRead(SQLModel):
    """Schema for reading protocol data."""

    id: UUID
    name: str
    description: str
    condition: str
    phase: str
    duration_weeks: int | None
    frequency_per_week: int
    status: ProtocolStatus
    is_template: bool
    created_by: UUID
    created_at: datetime


class ProtocolReadWithExercises(ProtocolRead):
    """Schema for reading protocol with exercises."""

    exercises: list["ProtocolExerciseRead"] = []


class ProtocolUpdate(SQLModel):
    """Schema for updating a protocol."""

    name: str | None = None
    description: str | None = None
    condition: str | None = None
    phase: str | None = None
    duration_weeks: int | None = None
    frequency_per_week: int | None = None
    status: ProtocolStatus | None = None
    is_template: bool | None = None


class ProtocolExerciseCreate(SQLModel):
    """Schema for adding exercise to protocol."""

    exercise_id: UUID
    order: int = 0
    sets: int = 3
    reps: int | None = 10
    hold_seconds: int | None = None
    rest_seconds: int = 60
    notes: str = ""


class ProtocolExerciseRead(SQLModel):
    """Schema for reading protocol exercise data."""

    id: UUID
    protocol_id: UUID
    exercise_id: UUID
    order: int
    sets: int
    reps: int | None
    hold_seconds: int | None
    rest_seconds: int
    notes: str


class ProtocolExerciseUpdate(SQLModel):
    """Schema for updating exercise in protocol."""

    order: int | None = None
    sets: int | None = None
    reps: int | None = None
    hold_seconds: int | None = None
    rest_seconds: int | None = None
    notes: str | None = None
