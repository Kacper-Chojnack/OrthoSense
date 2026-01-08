"""Protocol models for rehabilitation protocols and their exercises."""

from datetime import datetime, timezone
from uuid import UUID, uuid4

from sqlmodel import Field, Relationship, SQLModel


def utc_now() -> datetime:
    """Return current UTC datetime."""
    return datetime.now(timezone.utc)


class ProtocolBase(SQLModel):
    """Base schema for rehabilitation protocol."""

    name: str = Field(max_length=255)
    description: str = ""
    duration_weeks: int = Field(default=4, ge=1, le=52)
    is_active: bool = True


class Protocol(ProtocolBase, table=True):
    """Database table model for rehabilitation protocols."""

    __tablename__ = "protocols"

    id: UUID = Field(default_factory=uuid4, primary_key=True)
    created_at: datetime = Field(default_factory=utc_now)
    updated_at: datetime | None = Field(default=None)

    # Relationships
    protocol_exercises: list["ProtocolExercise"] = Relationship(
        back_populates="protocol"
    )


class ProtocolExerciseBase(SQLModel):
    """Base schema for protocol-exercise association."""

    protocol_id: UUID = Field(foreign_key="protocols.id")
    exercise_id: UUID = Field(foreign_key="exercises.id")
    order: int = Field(default=0, ge=0)
    sets: int = Field(default=3, ge=1, le=10)
    reps: int = Field(default=10, ge=1, le=100)
    hold_seconds: int = Field(default=0, ge=0, le=120)
    rest_seconds: int = Field(default=30, ge=0, le=300)


class ProtocolExercise(ProtocolExerciseBase, table=True):
    """Database table model for protocol-exercise association."""

    __tablename__ = "protocol_exercises"

    id: UUID = Field(default_factory=uuid4, primary_key=True)
    created_at: datetime = Field(default_factory=utc_now)

    # Relationships
    protocol: Protocol = Relationship(back_populates="protocol_exercises")
    exercise: "Exercise" = Relationship(back_populates="protocol_exercises")


# Forward reference
from app.models.exercise import Exercise  # noqa: E402
