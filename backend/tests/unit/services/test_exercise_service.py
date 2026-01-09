"""
Unit tests for Exercise Service layer.

Test coverage:
1. Exercise CRUD operations
2. Exercise filtering by category, body part, difficulty
3. Active/inactive exercise management
4. Exercise metadata validation
5. Edge cases and error handling
"""

from datetime import UTC, datetime
from uuid import uuid4

import pytest
from sqlalchemy.ext.asyncio import AsyncSession
from sqlmodel import select

from app.models.exercise import (
    BodyPart,
    Exercise,
    ExerciseCategory,
)


class TestExerciseCreation:
    """Tests for exercise creation logic."""

    @pytest.mark.asyncio
    async def test_create_exercise_defaults(self, session: AsyncSession) -> None:
        """New exercise has correct default values."""
        exercise = Exercise(
            name="Knee Extension",
            description="Extend knee from bent position",
        )
        session.add(exercise)
        await session.commit()
        await session.refresh(exercise)

        assert exercise.id is not None
        assert exercise.name == "Knee Extension"
        assert exercise.category == ExerciseCategory.MOBILITY
        assert exercise.body_part == BodyPart.KNEE
        assert exercise.difficulty_level == 1
        assert exercise.is_active is True
        assert exercise.video_url is None
        assert exercise.created_at is not None

    @pytest.mark.asyncio
    async def test_create_exercise_with_all_fields(
        self,
        session: AsyncSession,
    ) -> None:
        """Exercise can be created with all fields populated."""
        exercise = Exercise(
            name="Shoulder Press",
            description="Overhead pressing motion",
            instructions="Start with dumbbells at shoulder height",
            category=ExerciseCategory.STRENGTH,
            body_part=BodyPart.SHOULDER,
            difficulty_level=3,
            video_url="https://example.com/video.mp4",
            thumbnail_url="https://example.com/thumb.jpg",
            duration_seconds=300,
        )
        session.add(exercise)
        await session.commit()
        await session.refresh(exercise)

        assert exercise.name == "Shoulder Press"
        assert exercise.category == ExerciseCategory.STRENGTH
        assert exercise.body_part == BodyPart.SHOULDER
        assert exercise.difficulty_level == 3
        assert exercise.video_url == "https://example.com/video.mp4"
        assert exercise.duration_seconds == 300

    @pytest.mark.asyncio
    async def test_create_exercise_for_each_category(
        self,
        session: AsyncSession,
    ) -> None:
        """Exercise can be created for each category."""
        for category in ExerciseCategory:
            exercise = Exercise(
                name=f"Test {category.value} Exercise",
                category=category,
            )
            session.add(exercise)
            await session.commit()
            await session.refresh(exercise)
            assert exercise.category == category

    @pytest.mark.asyncio
    async def test_create_exercise_for_each_body_part(
        self,
        session: AsyncSession,
    ) -> None:
        """Exercise can be created for each body part."""
        for body_part in BodyPart:
            exercise = Exercise(
                name=f"Test {body_part.value} Exercise",
                body_part=body_part,
            )
            session.add(exercise)
            await session.commit()
            await session.refresh(exercise)
            assert exercise.body_part == body_part


class TestExerciseRetrieval:
    """Tests for exercise retrieval operations."""

    @pytest.fixture
    async def sample_exercises(self, session: AsyncSession) -> list[Exercise]:
        """Create sample exercises for testing."""
        exercises = [
            Exercise(
                name="Knee Bend",
                category=ExerciseCategory.MOBILITY,
                body_part=BodyPart.KNEE,
                difficulty_level=1,
            ),
            Exercise(
                name="Shoulder Raise",
                category=ExerciseCategory.STRENGTH,
                body_part=BodyPart.SHOULDER,
                difficulty_level=2,
            ),
            Exercise(
                name="Hip Stretch",
                category=ExerciseCategory.STRETCHING,
                body_part=BodyPart.HIP,
                difficulty_level=1,
            ),
            Exercise(
                name="Balance Board",
                category=ExerciseCategory.BALANCE,
                body_part=BodyPart.FULL_BODY,
                difficulty_level=3,
            ),
            Exercise(
                name="Inactive Exercise",
                category=ExerciseCategory.MOBILITY,
                body_part=BodyPart.KNEE,
                is_active=False,
            ),
        ]
        for ex in exercises:
            session.add(ex)
        await session.commit()
        for ex in exercises:
            await session.refresh(ex)
        return exercises

    @pytest.mark.asyncio
    async def test_get_exercise_by_id(
        self,
        session: AsyncSession,
        sample_exercises: list[Exercise],
    ) -> None:
        """Exercise can be retrieved by ID."""
        exercise = sample_exercises[0]
        retrieved = await session.get(Exercise, exercise.id)

        assert retrieved is not None
        assert retrieved.id == exercise.id
        assert retrieved.name == exercise.name

    @pytest.mark.asyncio
    async def test_get_nonexistent_exercise(self, session: AsyncSession) -> None:
        """Retrieving nonexistent exercise returns None."""
        retrieved = await session.get(Exercise, uuid4())
        assert retrieved is None

    @pytest.mark.asyncio
    async def test_list_active_exercises(
        self,
        session: AsyncSession,
        sample_exercises: list[Exercise],
    ) -> None:
        """Only active exercises are listed by default."""
        statement = select(Exercise).where(Exercise.is_active == True)  # noqa: E712
        result = await session.execute(statement)
        active_exercises = result.scalars().all()

        names = [ex.name for ex in active_exercises]
        assert "Inactive Exercise" not in names
        assert "Knee Bend" in names

    @pytest.mark.asyncio
    async def test_filter_by_category(
        self,
        session: AsyncSession,
        sample_exercises: list[Exercise],
    ) -> None:
        """Exercises can be filtered by category."""
        statement = select(Exercise).where(
            Exercise.category == ExerciseCategory.MOBILITY
        )
        result = await session.execute(statement)
        mobility_exercises = result.scalars().all()

        assert len(mobility_exercises) >= 1
        for ex in mobility_exercises:
            assert ex.category == ExerciseCategory.MOBILITY

    @pytest.mark.asyncio
    async def test_filter_by_body_part(
        self,
        session: AsyncSession,
        sample_exercises: list[Exercise],
    ) -> None:
        """Exercises can be filtered by body part."""
        statement = select(Exercise).where(Exercise.body_part == BodyPart.SHOULDER)
        result = await session.execute(statement)
        shoulder_exercises = result.scalars().all()

        for ex in shoulder_exercises:
            assert ex.body_part == BodyPart.SHOULDER

    @pytest.mark.asyncio
    async def test_filter_by_difficulty(
        self,
        session: AsyncSession,
        sample_exercises: list[Exercise],
    ) -> None:
        """Exercises can be filtered by difficulty level."""
        statement = select(Exercise).where(Exercise.difficulty_level <= 2)
        result = await session.execute(statement)
        easy_exercises = result.scalars().all()

        for ex in easy_exercises:
            assert ex.difficulty_level <= 2

    @pytest.mark.asyncio
    async def test_combined_filters(
        self,
        session: AsyncSession,
        sample_exercises: list[Exercise],
    ) -> None:
        """Multiple filters can be combined."""
        statement = (
            select(Exercise)
            .where(Exercise.category == ExerciseCategory.MOBILITY)
            .where(Exercise.body_part == BodyPart.KNEE)
            .where(Exercise.is_active == True)  # noqa: E712
        )
        result = await session.execute(statement)
        filtered = result.scalars().all()

        for ex in filtered:
            assert ex.category == ExerciseCategory.MOBILITY
            assert ex.body_part == BodyPart.KNEE
            assert ex.is_active is True


class TestExerciseUpdate:
    """Tests for exercise update operations."""

    @pytest.mark.asyncio
    async def test_update_exercise_name(self, session: AsyncSession) -> None:
        """Exercise name can be updated."""
        exercise = Exercise(name="Original Name")
        session.add(exercise)
        await session.commit()

        exercise.name = "Updated Name"
        exercise.updated_at = datetime.now(UTC)
        await session.commit()
        await session.refresh(exercise)

        assert exercise.name == "Updated Name"
        assert exercise.updated_at is not None

    @pytest.mark.asyncio
    async def test_update_exercise_category(self, session: AsyncSession) -> None:
        """Exercise category can be changed."""
        exercise = Exercise(
            name="Category Test",
            category=ExerciseCategory.MOBILITY,
        )
        session.add(exercise)
        await session.commit()

        exercise.category = ExerciseCategory.STRENGTH
        await session.commit()
        await session.refresh(exercise)

        assert exercise.category == ExerciseCategory.STRENGTH

    @pytest.mark.asyncio
    async def test_update_exercise_difficulty(self, session: AsyncSession) -> None:
        """Exercise difficulty can be updated."""
        exercise = Exercise(name="Difficulty Test", difficulty_level=1)
        session.add(exercise)
        await session.commit()

        exercise.difficulty_level = 5
        await session.commit()
        await session.refresh(exercise)

        assert exercise.difficulty_level == 5

    @pytest.mark.asyncio
    async def test_deactivate_exercise(self, session: AsyncSession) -> None:
        """Exercise can be deactivated (soft delete)."""
        exercise = Exercise(name="To Deactivate", is_active=True)
        session.add(exercise)
        await session.commit()

        exercise.is_active = False
        exercise.updated_at = datetime.now(UTC)
        await session.commit()
        await session.refresh(exercise)

        assert exercise.is_active is False

    @pytest.mark.asyncio
    async def test_reactivate_exercise(self, session: AsyncSession) -> None:
        """Deactivated exercise can be reactivated."""
        exercise = Exercise(name="To Reactivate", is_active=False)
        session.add(exercise)
        await session.commit()

        exercise.is_active = True
        await session.commit()
        await session.refresh(exercise)

        assert exercise.is_active is True


class TestExerciseDeletion:
    """Tests for exercise deletion operations."""

    @pytest.mark.asyncio
    async def test_hard_delete_exercise(self, session: AsyncSession) -> None:
        """Exercise can be permanently deleted."""
        exercise = Exercise(name="To Delete")
        session.add(exercise)
        await session.commit()
        exercise_id = exercise.id

        await session.delete(exercise)
        await session.commit()

        retrieved = await session.get(Exercise, exercise_id)
        assert retrieved is None


class TestExerciseValidation:
    """Tests for exercise field validation."""

    @pytest.mark.asyncio
    async def test_difficulty_within_range(self, session: AsyncSession) -> None:
        """Difficulty level must be between 1 and 5."""
        for level in [1, 2, 3, 4, 5]:
            exercise = Exercise(
                name=f"Difficulty {level}",
                difficulty_level=level,
            )
            session.add(exercise)
            await session.commit()
            await session.refresh(exercise)
            assert exercise.difficulty_level == level

    @pytest.mark.asyncio
    async def test_duration_seconds_positive(self, session: AsyncSession) -> None:
        """Duration must be non-negative."""
        exercise = Exercise(
            name="Duration Test",
            duration_seconds=0,
        )
        session.add(exercise)
        await session.commit()
        await session.refresh(exercise)

        assert exercise.duration_seconds == 0

    @pytest.mark.asyncio
    async def test_empty_instructions(self, session: AsyncSession) -> None:
        """Exercise can have empty instructions."""
        exercise = Exercise(name="No Instructions", instructions="")
        session.add(exercise)
        await session.commit()
        await session.refresh(exercise)

        assert exercise.instructions == ""

    @pytest.mark.asyncio
    async def test_optional_video_url(self, session: AsyncSession) -> None:
        """Video URL is optional."""
        exercise = Exercise(name="No Video")
        session.add(exercise)
        await session.commit()
        await session.refresh(exercise)

        assert exercise.video_url is None


class TestExerciseEdgeCases:
    """Tests for edge cases and boundary conditions."""

    @pytest.mark.asyncio
    async def test_exercise_with_long_name(self, session: AsyncSession) -> None:
        """Exercise can have a long name within limits."""
        long_name = "A" * 255
        exercise = Exercise(name=long_name)
        session.add(exercise)
        await session.commit()
        await session.refresh(exercise)

        assert exercise.name == long_name

    @pytest.mark.asyncio
    async def test_exercise_with_unicode_characters(
        self,
        session: AsyncSession,
    ) -> None:
        """Exercise can have unicode in name and description."""
        exercise = Exercise(
            name="Ćwiczenie rehabilitacyjne",
            description="Rozciąganie mięśni 筋肉ストレッチ",
        )
        session.add(exercise)
        await session.commit()
        await session.refresh(exercise)

        assert exercise.name == "Ćwiczenie rehabilitacyjne"
        assert "筋肉ストレッチ" in exercise.description

    @pytest.mark.asyncio
    async def test_exercise_created_at_is_automatic(
        self,
        session: AsyncSession,
    ) -> None:
        """created_at is set automatically."""
        before = datetime.now(UTC).replace(
            tzinfo=None
        )  # Make offset-naive for comparison

        exercise = Exercise(name="Timestamp Test")
        session.add(exercise)
        await session.commit()
        await session.refresh(exercise)

        after = datetime.now(UTC).replace(tzinfo=None)

        assert exercise.created_at is not None
        # Handle both offset-aware and offset-naive from DB
        created = (
            exercise.created_at.replace(tzinfo=None)
            if exercise.created_at.tzinfo
            else exercise.created_at
        )
        assert before <= created <= after

    @pytest.mark.asyncio
    async def test_exercise_ordering_by_name(self, session: AsyncSession) -> None:
        """Exercises can be ordered by name."""
        names = ["Zebra", "Apple", "Mango"]
        for name in names:
            session.add(Exercise(name=name))
        await session.commit()

        statement = select(Exercise).order_by(Exercise.name)
        result = await session.execute(statement)
        ordered = [ex.name for ex in result.scalars().all()]

        # Verify Apple comes before Mango comes before Zebra
        apple_idx = ordered.index("Apple")
        mango_idx = ordered.index("Mango")
        zebra_idx = ordered.index("Zebra")
        assert apple_idx < mango_idx < zebra_idx

    @pytest.mark.asyncio
    async def test_exercise_with_null_thumbnail(self, session: AsyncSession) -> None:
        """Exercise can have null thumbnail URL."""
        exercise = Exercise(
            name="No Thumbnail",
            video_url="https://example.com/video.mp4",
            thumbnail_url=None,
        )
        session.add(exercise)
        await session.commit()
        await session.refresh(exercise)

        assert exercise.video_url is not None
        assert exercise.thumbnail_url is None
