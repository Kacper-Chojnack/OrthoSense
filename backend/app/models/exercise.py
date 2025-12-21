"""Exercise model for rehabilitation exercises."""

from datetime import UTC, datetime
from enum import Enum
from uuid import UUID, uuid4

from sqlmodel import Field, Relationship, SQLModel


def utc_now() -> datetime:
    """Get current UTC datetime."""
    return datetime.now(UTC)


class ExerciseCategory(str, Enum):
    """Categories for rehabilitation exercises."""

    MOBILITY = "mobility"
    STRENGTH = "strength"
    BALANCE = "balance"
    STRETCHING = "stretching"
    COORDINATION = "coordination"
    ENDURANCE = "endurance"


class BodyPart(str, Enum):
    """Body parts targeted by exercises."""

    KNEE = "knee"
    HIP = "hip"
    SHOULDER = "shoulder"
    ANKLE = "ankle"
    SPINE = "spine"
    ELBOW = "elbow"
    WRIST = "wrist"
    NECK = "neck"
    FULL_BODY = "full_body"


class ExerciseBase(SQLModel):
    """Shared exercise fields."""

    name: str = Field(max_length=255, index=True)
    description: str = Field(default="")
    instructions: str = Field(default="")
    category: ExerciseCategory = Field(default=ExerciseCategory.MOBILITY)
    body_part: BodyPart = Field(default=BodyPart.KNEE)
    difficulty_level: int = Field(default=1, ge=1, le=5)
    video_url: str | None = Field(default=None)
    thumbnail_url: str | None = Field(default=None)
    duration_seconds: int | None = Field(default=None, ge=0)
    is_active: bool = Field(default=True)


class Exercise(ExerciseBase, table=True):
    """Database table model for exercises."""

    __tablename__ = "exercises"

    id: UUID = Field(default_factory=uuid4, primary_key=True)
    created_at: datetime = Field(default_factory=utc_now)
    updated_at: datetime | None = Field(default=None)

    # Relationships
    protocol_exercises: list["ProtocolExercise"] = Relationship(
        back_populates="exercise"
    )


# Forward reference
from app.models.protocol import ProtocolExercise  # noqa: E402


class ExerciseCreate(SQLModel):
    """Schema for creating an exercise."""

    name: str = Field(max_length=255)
    description: str = ""
    instructions: str = ""
    category: ExerciseCategory = ExerciseCategory.MOBILITY
    body_part: BodyPart = BodyPart.KNEE
    difficulty_level: int = Field(default=1, ge=1, le=5)
    video_url: str | None = None
    thumbnail_url: str | None = None
    duration_seconds: int | None = None


class ExerciseRead(SQLModel):
    """Schema for reading exercise data."""

    id: UUID
    name: str
    description: str
    instructions: str
    category: ExerciseCategory
    body_part: BodyPart
    difficulty_level: int
    video_url: str | None
    thumbnail_url: str | None
    duration_seconds: int | None
    is_active: bool
    created_at: datetime


class ExerciseUpdate(SQLModel):
    """Schema for updating an exercise."""

    name: str | None = None
    description: str | None = None
    instructions: str | None = None
    category: ExerciseCategory | None = None
    body_part: BodyPart | None = None
    difficulty_level: int | None = Field(default=None, ge=1, le=5)
    video_url: str | None = None
    thumbnail_url: str | None = None
    duration_seconds: int | None = None
    is_active: bool | None = None
