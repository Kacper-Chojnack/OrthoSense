"""Exercise demonstration video model.

Stores reference videos showing correct exercise technique.
These videos are NOT analyzed in real-time - they serve as instructional content.
"""

from datetime import UTC, datetime
from uuid import UUID, uuid4

from sqlmodel import Field, Relationship, SQLModel


def utc_now() -> datetime:
    """Get current UTC datetime (naive, for PostgreSQL compatibility)."""
    return datetime.now(UTC).replace(tzinfo=None)


class ExerciseVideoBase(SQLModel):
    """Base fields for exercise demonstration videos."""

    title: str = Field(max_length=255)
    description: str = Field(default="")
    video_url: str = Field(max_length=2048)
    thumbnail_url: str | None = Field(default=None, max_length=2048)
    duration_seconds: int = Field(default=0, ge=0)
    view_angle: str = Field(default="front", max_length=50)
    is_primary: bool = Field(default=False)
    sort_order: int = Field(default=0)


class ExerciseVideo(ExerciseVideoBase, table=True):
    """Database table for exercise demonstration videos."""

    __tablename__ = "exercise_videos"

    id: UUID = Field(default_factory=uuid4, primary_key=True)
    exercise_id: UUID = Field(foreign_key="exercises.id", index=True)
    created_at: datetime = Field(default_factory=utc_now)
    updated_at: datetime | None = Field(default=None)
    is_active: bool = Field(default=True)

    # Relationship
    exercise: "Exercise" = Relationship(back_populates="demo_videos")


# Forward reference
from app.models.exercise import Exercise  # noqa: E402


class ExerciseVideoCreate(SQLModel):
    """Schema for creating an exercise video."""

    exercise_id: UUID
    title: str = Field(max_length=255)
    description: str = ""
    video_url: str = Field(max_length=2048)
    thumbnail_url: str | None = None
    duration_seconds: int = 0
    view_angle: str = "front"
    is_primary: bool = False
    sort_order: int = 0


class ExerciseVideoRead(SQLModel):
    """Schema for reading exercise video data."""

    id: UUID
    exercise_id: UUID
    title: str
    description: str
    video_url: str
    thumbnail_url: str | None
    duration_seconds: int
    view_angle: str
    is_primary: bool
    sort_order: int
    is_active: bool
    created_at: datetime


class ExerciseVideoUpdate(SQLModel):
    """Schema for updating an exercise video."""

    title: str | None = None
    description: str | None = None
    video_url: str | None = None
    thumbnail_url: str | None = None
    duration_seconds: int | None = None
    view_angle: str | None = None
    is_primary: bool | None = None
    sort_order: int | None = None
    is_active: bool | None = None
