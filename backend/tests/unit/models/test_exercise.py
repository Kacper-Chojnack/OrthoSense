"""
Unit tests for Exercise model.

Test coverage:
1. Exercise model creation
2. ExerciseCreate schema validation
3. ExerciseRead schema serialization
4. ExerciseUpdate schema
5. ExerciseCategory enum
6. BodyPart enum
7. Difficulty level validation
"""

from datetime import UTC, datetime
from uuid import uuid4

import pytest
from pydantic import ValidationError

from app.models.exercise import (
    BodyPart,
    Exercise,
    ExerciseCategory,
    ExerciseCreate,
    ExerciseRead,
    ExerciseUpdate,
)


class TestExerciseModel:
    """Tests for Exercise SQLModel."""

    def test_exercise_creation_with_defaults(self) -> None:
        """Exercise can be created with minimal fields."""
        exercise = Exercise(name="Test Exercise")

        assert exercise.name == "Test Exercise"
        assert exercise.category == ExerciseCategory.MOBILITY
        assert exercise.body_part == BodyPart.KNEE
        assert exercise.difficulty_level == 1
        assert exercise.is_active is True
        assert exercise.description == ""

    def test_exercise_creation_with_all_fields(self) -> None:
        """Exercise can be created with all fields."""
        exercise_id = uuid4()
        now = datetime.now(UTC)

        exercise = Exercise(
            id=exercise_id,
            name="Advanced Squat",
            description="A challenging squat exercise",
            instructions="Stand with feet shoulder-width apart...",
            category=ExerciseCategory.STRENGTH,
            body_part=BodyPart.HIP,
            difficulty_level=4,
            video_url="https://example.com/video.mp4",
            thumbnail_url="https://example.com/thumb.jpg",
            duration_seconds=300,
            is_active=True,
            created_at=now,
        )

        assert exercise.id == exercise_id
        assert exercise.name == "Advanced Squat"
        assert exercise.category == ExerciseCategory.STRENGTH
        assert exercise.body_part == BodyPart.HIP
        assert exercise.difficulty_level == 4
        assert exercise.duration_seconds == 300

    def test_exercise_id_auto_generated(self) -> None:
        """Exercise ID is auto-generated if not provided."""
        exercise = Exercise(name="Test Exercise")

        assert exercise.id is not None

    def test_exercise_created_at_auto_generated(self) -> None:
        """created_at is auto-generated."""
        exercise = Exercise(name="Test Exercise")

        assert exercise.created_at is not None


class TestExerciseCreateSchema:
    """Tests for ExerciseCreate schema."""

    def test_exercise_create_valid(self) -> None:
        """Valid ExerciseCreate schema."""
        data = ExerciseCreate(
            name="New Exercise",
            description="Exercise description",
            category=ExerciseCategory.BALANCE,
            body_part=BodyPart.ANKLE,
            difficulty_level=3,
        )

        assert data.name == "New Exercise"
        assert data.category == ExerciseCategory.BALANCE
        assert data.body_part == BodyPart.ANKLE
        assert data.difficulty_level == 3

    def test_exercise_create_minimal(self) -> None:
        """ExerciseCreate with minimal fields."""
        data = ExerciseCreate(name="Minimal Exercise")

        assert data.name == "Minimal Exercise"
        assert data.description == ""
        assert data.category == ExerciseCategory.MOBILITY
        assert data.difficulty_level == 1

    def test_exercise_create_difficulty_range(self) -> None:
        """Difficulty level must be between 1 and 5."""
        # Valid levels
        for level in [1, 2, 3, 4, 5]:
            data = ExerciseCreate(name="Test", difficulty_level=level)
            assert data.difficulty_level == level

    def test_exercise_create_difficulty_too_low(self) -> None:
        """Difficulty below 1 raises ValidationError."""
        with pytest.raises(ValidationError):
            ExerciseCreate(name="Test", difficulty_level=0)

    def test_exercise_create_difficulty_too_high(self) -> None:
        """Difficulty above 5 raises ValidationError."""
        with pytest.raises(ValidationError):
            ExerciseCreate(name="Test", difficulty_level=6)

    def test_exercise_create_with_urls(self) -> None:
        """ExerciseCreate with video and thumbnail URLs."""
        data = ExerciseCreate(
            name="Video Exercise",
            video_url="https://example.com/video.mp4",
            thumbnail_url="https://example.com/thumb.jpg",
        )

        assert data.video_url == "https://example.com/video.mp4"
        assert data.thumbnail_url == "https://example.com/thumb.jpg"

    def test_exercise_create_name_max_length(self) -> None:
        """Exercise name has max length of 255."""
        # Should work
        data = ExerciseCreate(name="A" * 255)
        assert len(data.name) == 255

        # Should fail
        with pytest.raises(ValidationError):
            ExerciseCreate(name="A" * 256)


class TestExerciseReadSchema:
    """Tests for ExerciseRead schema."""

    def test_exercise_read_from_model(self) -> None:
        """ExerciseRead can be created from Exercise model data."""
        exercise = Exercise(
            id=uuid4(),
            name="Test Exercise",
            description="Description",
            instructions="Instructions",
            category=ExerciseCategory.STRETCHING,
            body_part=BodyPart.SHOULDER,
            difficulty_level=2,
            is_active=True,
            created_at=datetime.now(UTC),
        )

        exercise_read = ExerciseRead(
            id=exercise.id,
            name=exercise.name,
            description=exercise.description,
            instructions=exercise.instructions,
            category=exercise.category,
            body_part=exercise.body_part,
            difficulty_level=exercise.difficulty_level,
            video_url=exercise.video_url,
            thumbnail_url=exercise.thumbnail_url,
            duration_seconds=exercise.duration_seconds,
            is_active=exercise.is_active,
            created_at=exercise.created_at,
        )

        assert exercise_read.id == exercise.id
        assert exercise_read.name == exercise.name
        assert exercise_read.category == ExerciseCategory.STRETCHING


class TestExerciseUpdateSchema:
    """Tests for ExerciseUpdate schema."""

    def test_exercise_update_single_field(self) -> None:
        """ExerciseUpdate with single field."""
        data = ExerciseUpdate(name="Updated Name")

        assert data.name == "Updated Name"
        assert data.description is None
        assert data.category is None

    def test_exercise_update_multiple_fields(self) -> None:
        """ExerciseUpdate with multiple fields."""
        data = ExerciseUpdate(
            name="Updated Name",
            description="Updated description",
            difficulty_level=5,
        )

        assert data.name == "Updated Name"
        assert data.description == "Updated description"
        assert data.difficulty_level == 5

    def test_exercise_update_empty(self) -> None:
        """ExerciseUpdate with no fields is valid."""
        data = ExerciseUpdate()

        assert data.name is None
        assert data.description is None
        assert data.category is None

    def test_exercise_update_is_active(self) -> None:
        """ExerciseUpdate can update is_active."""
        data = ExerciseUpdate(is_active=False)

        assert data.is_active is False

    def test_exercise_update_difficulty_validation(self) -> None:
        """ExerciseUpdate validates difficulty range."""
        # Valid
        data = ExerciseUpdate(difficulty_level=3)
        assert data.difficulty_level == 3

        # Invalid
        with pytest.raises(ValidationError):
            ExerciseUpdate(difficulty_level=10)


class TestExerciseCategoryEnum:
    """Tests for ExerciseCategory enum."""

    def test_category_values(self) -> None:
        """ExerciseCategory has expected values."""
        assert ExerciseCategory.MOBILITY == "mobility"
        assert ExerciseCategory.STRENGTH == "strength"
        assert ExerciseCategory.BALANCE == "balance"
        assert ExerciseCategory.STRETCHING == "stretching"
        assert ExerciseCategory.COORDINATION == "coordination"
        assert ExerciseCategory.ENDURANCE == "endurance"

    def test_category_count(self) -> None:
        """All exercise categories are defined."""
        categories = list(ExerciseCategory)
        assert len(categories) == 6


class TestBodyPartEnum:
    """Tests for BodyPart enum."""

    def test_body_part_values(self) -> None:
        """BodyPart has expected values."""
        assert BodyPart.KNEE == "knee"
        assert BodyPart.HIP == "hip"
        assert BodyPart.SHOULDER == "shoulder"
        assert BodyPart.ANKLE == "ankle"
        assert BodyPart.SPINE == "spine"
        assert BodyPart.ELBOW == "elbow"
        assert BodyPart.WRIST == "wrist"
        assert BodyPart.NECK == "neck"
        assert BodyPart.FULL_BODY == "full_body"

    def test_body_part_count(self) -> None:
        """All body parts are defined."""
        body_parts = list(BodyPart)
        assert len(body_parts) == 9
