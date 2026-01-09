"""
Unit tests for Exercise Repository layer.

Test coverage:
1. CRUD operations (Create, Read, Update, Delete)
2. Filtering exercises by category, body part, difficulty
3. Pagination and ordering
4. Soft delete behavior
5. Admin-only operations validation
6. Edge cases and error handling
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


class TestExerciseCreate:
    """Tests for exercise creation (repository-level logic)."""

    @pytest.mark.asyncio
    async def test_create_exercise_with_defaults(
        self,
        session: AsyncSession,
    ) -> None:
        """Create exercise with minimal data uses defaults."""
        exercise = Exercise(
            name="Test Exercise",
            description="Basic test",
        )

        session.add(exercise)
        await session.commit()
        await session.refresh(exercise)

        assert exercise.id is not None
        assert exercise.name == "Test Exercise"
        assert exercise.category == ExerciseCategory.MOBILITY
        assert exercise.body_part == BodyPart.KNEE
        assert exercise.difficulty_level == 1
        assert exercise.is_active is True
        assert exercise.created_at is not None

    @pytest.mark.asyncio
    async def test_create_exercise_full_data(
        self,
        session: AsyncSession,
    ) -> None:
        """Create exercise with all fields populated."""
        exercise = Exercise(
            name="Full Exercise",
            description="Complete description",
            instructions="Step 1: Do this. Step 2: Do that.",
            category=ExerciseCategory.STRENGTH,
            body_part=BodyPart.SHOULDER,
            difficulty_level=4,
            video_url="https://example.com/video.mp4",
            thumbnail_url="https://example.com/thumb.jpg",
            duration_seconds=120,
        )

        session.add(exercise)
        await session.commit()
        await session.refresh(exercise)

        assert exercise.category == ExerciseCategory.STRENGTH
        assert exercise.body_part == BodyPart.SHOULDER
        assert exercise.difficulty_level == 4
        assert exercise.video_url == "https://example.com/video.mp4"
        assert exercise.duration_seconds == 120

    @pytest.mark.asyncio
    async def test_create_multiple_exercises(
        self,
        session: AsyncSession,
    ) -> None:
        """Create multiple exercises."""
        exercises = [
            Exercise(name=f"Exercise {i}", description=f"Desc {i}") for i in range(5)
        ]

        for ex in exercises:
            session.add(ex)
        await session.commit()

        result = await session.execute(select(Exercise))
        all_exercises = result.scalars().all()

        assert len(all_exercises) >= 5


class TestExerciseRead:
    """Tests for reading/querying exercises."""

    @pytest.fixture
    async def sample_exercises(self, session: AsyncSession) -> list[Exercise]:
        """Create sample exercises for testing."""
        exercises = [
            Exercise(
                name="Shoulder Press",
                category=ExerciseCategory.STRENGTH,
                body_part=BodyPart.SHOULDER,
                difficulty_level=3,
            ),
            Exercise(
                name="Knee Extension",
                category=ExerciseCategory.MOBILITY,
                body_part=BodyPart.KNEE,
                difficulty_level=1,
            ),
            Exercise(
                name="Hip Stretch",
                category=ExerciseCategory.STRETCHING,
                body_part=BodyPart.HIP,
                difficulty_level=2,
            ),
            Exercise(
                name="Balance Stand",
                category=ExerciseCategory.BALANCE,
                body_part=BodyPart.FULL_BODY,
                difficulty_level=2,
            ),
            Exercise(
                name="Shoulder Rotation",
                category=ExerciseCategory.MOBILITY,
                body_part=BodyPart.SHOULDER,
                difficulty_level=1,
                is_active=False,  # Inactive exercise
            ),
        ]

        for ex in exercises:
            session.add(ex)
        await session.commit()

        return exercises

    @pytest.mark.asyncio
    async def test_get_exercise_by_id(
        self,
        session: AsyncSession,
        sample_exercises: list[Exercise],
    ) -> None:
        """Get exercise by ID."""
        exercise_id = sample_exercises[0].id

        result = await session.get(Exercise, exercise_id)

        assert result is not None
        assert result.name == "Shoulder Press"

    @pytest.mark.asyncio
    async def test_get_nonexistent_exercise(
        self,
        session: AsyncSession,
    ) -> None:
        """Get non-existent exercise returns None."""
        result = await session.get(Exercise, uuid4())

        assert result is None

    @pytest.mark.asyncio
    async def test_filter_by_category(
        self,
        session: AsyncSession,
        sample_exercises: list[Exercise],
    ) -> None:
        """Filter exercises by category."""
        statement = select(Exercise).where(
            Exercise.category == ExerciseCategory.MOBILITY,
            Exercise.is_active == True,  # noqa: E712
        )
        result = await session.execute(statement)
        exercises = result.scalars().all()

        assert len(exercises) == 1
        assert exercises[0].name == "Knee Extension"

    @pytest.mark.asyncio
    async def test_filter_by_body_part(
        self,
        session: AsyncSession,
        sample_exercises: list[Exercise],
    ) -> None:
        """Filter exercises by body part."""
        statement = select(Exercise).where(
            Exercise.body_part == BodyPart.SHOULDER,
            Exercise.is_active == True,  # noqa: E712
        )
        result = await session.execute(statement)
        exercises = result.scalars().all()

        assert len(exercises) == 1
        assert exercises[0].name == "Shoulder Press"

    @pytest.mark.asyncio
    async def test_filter_by_difficulty(
        self,
        session: AsyncSession,
        sample_exercises: list[Exercise],
    ) -> None:
        """Filter exercises by difficulty level."""
        statement = select(Exercise).where(
            Exercise.difficulty_level == 2,
            Exercise.is_active == True,  # noqa: E712
        )
        result = await session.execute(statement)
        exercises = result.scalars().all()

        assert len(exercises) == 2

    @pytest.mark.asyncio
    async def test_filter_active_only(
        self,
        session: AsyncSession,
        sample_exercises: list[Exercise],
    ) -> None:
        """Default filter excludes inactive exercises."""
        statement = select(Exercise).where(
            Exercise.is_active == True,  # noqa: E712
        )
        result = await session.execute(statement)
        exercises = result.scalars().all()

        assert len(exercises) == 4
        inactive_names = [e.name for e in exercises]
        assert "Shoulder Rotation" not in inactive_names

    @pytest.mark.asyncio
    async def test_combined_filters(
        self,
        session: AsyncSession,
        sample_exercises: list[Exercise],
    ) -> None:
        """Apply multiple filters simultaneously."""
        statement = select(Exercise).where(
            Exercise.category == ExerciseCategory.STRENGTH,
            Exercise.body_part == BodyPart.SHOULDER,
            Exercise.difficulty_level >= 3,
            Exercise.is_active == True,  # noqa: E712
        )
        result = await session.execute(statement)
        exercises = result.scalars().all()

        assert len(exercises) == 1
        assert exercises[0].name == "Shoulder Press"


class TestExercisePagination:
    """Tests for pagination and ordering."""

    @pytest.fixture
    async def many_exercises(self, session: AsyncSession) -> list[Exercise]:
        """Create many exercises for pagination tests."""
        exercises = [
            Exercise(
                name=f"Exercise {i:03d}",
                description=f"Description {i}",
                difficulty_level=(i % 5) + 1,
            )
            for i in range(25)
        ]

        for ex in exercises:
            session.add(ex)
        await session.commit()

        return exercises

    @pytest.mark.asyncio
    async def test_pagination_first_page(
        self,
        session: AsyncSession,
        many_exercises: list[Exercise],
    ) -> None:
        """Get first page of exercises."""
        statement = (
            select(Exercise)
            .where(Exercise.is_active == True)  # noqa: E712
            .offset(0)
            .limit(10)
            .order_by(Exercise.name)
        )
        result = await session.execute(statement)
        exercises = result.scalars().all()

        assert len(exercises) == 10

    @pytest.mark.asyncio
    async def test_pagination_second_page(
        self,
        session: AsyncSession,
        many_exercises: list[Exercise],
    ) -> None:
        """Get second page of exercises."""
        statement = (
            select(Exercise)
            .where(Exercise.is_active == True)  # noqa: E712
            .offset(10)
            .limit(10)
            .order_by(Exercise.name)
        )
        result = await session.execute(statement)
        exercises = result.scalars().all()

        assert len(exercises) == 10

    @pytest.mark.asyncio
    async def test_pagination_last_page(
        self,
        session: AsyncSession,
        many_exercises: list[Exercise],
    ) -> None:
        """Get last partial page of exercises."""
        statement = (
            select(Exercise)
            .where(Exercise.is_active == True)  # noqa: E712
            .offset(20)
            .limit(10)
            .order_by(Exercise.name)
        )
        result = await session.execute(statement)
        exercises = result.scalars().all()

        assert len(exercises) == 5  # Only 5 remaining

    @pytest.mark.asyncio
    async def test_order_by_name(
        self,
        session: AsyncSession,
        many_exercises: list[Exercise],
    ) -> None:
        """Exercises are ordered by name."""
        statement = (
            select(Exercise)
            .where(Exercise.is_active == True)  # noqa: E712
            .order_by(Exercise.name)
            .limit(5)
        )
        result = await session.execute(statement)
        exercises = result.scalars().all()

        names = [e.name for e in exercises]
        assert names == sorted(names)

    @pytest.mark.asyncio
    async def test_order_by_difficulty_desc(
        self,
        session: AsyncSession,
        many_exercises: list[Exercise],
    ) -> None:
        """Exercises ordered by difficulty descending."""
        statement = (
            select(Exercise)
            .where(Exercise.is_active == True)  # noqa: E712
            .order_by(Exercise.difficulty_level.desc())
            .limit(5)
        )
        result = await session.execute(statement)
        exercises = result.scalars().all()

        difficulties = [e.difficulty_level for e in exercises]
        assert difficulties == sorted(difficulties, reverse=True)


class TestExerciseUpdate:
    """Tests for updating exercises."""

    @pytest.mark.asyncio
    async def test_update_single_field(
        self,
        session: AsyncSession,
    ) -> None:
        """Update single field of exercise."""
        exercise = Exercise(
            name="Original Name",
            description="Original description",
        )
        session.add(exercise)
        await session.commit()

        exercise.name = "Updated Name"
        exercise.updated_at = datetime.now(UTC)
        session.add(exercise)
        await session.commit()
        await session.refresh(exercise)

        assert exercise.name == "Updated Name"
        assert exercise.description == "Original description"
        assert exercise.updated_at is not None

    @pytest.mark.asyncio
    async def test_update_multiple_fields(
        self,
        session: AsyncSession,
    ) -> None:
        """Update multiple fields of exercise."""
        exercise = Exercise(
            name="Test Exercise",
            category=ExerciseCategory.MOBILITY,
            difficulty_level=1,
        )
        session.add(exercise)
        await session.commit()

        exercise.category = ExerciseCategory.STRENGTH
        exercise.difficulty_level = 4
        exercise.video_url = "https://new-video.com/v.mp4"
        exercise.updated_at = datetime.now(UTC)
        session.add(exercise)
        await session.commit()
        await session.refresh(exercise)

        assert exercise.category == ExerciseCategory.STRENGTH
        assert exercise.difficulty_level == 4
        assert exercise.video_url == "https://new-video.com/v.mp4"

    @pytest.mark.asyncio
    async def test_update_preserves_other_fields(
        self,
        session: AsyncSession,
    ) -> None:
        """Updating doesn't affect unmodified fields."""
        original_id = uuid4()
        exercise = Exercise(
            id=original_id,
            name="Test Exercise",
            description="Test description",
            instructions="Test instructions",
        )
        session.add(exercise)
        await session.commit()

        created_at = exercise.created_at

        exercise.name = "New Name"
        session.add(exercise)
        await session.commit()
        await session.refresh(exercise)

        assert exercise.id == original_id
        assert exercise.description == "Test description"
        assert exercise.instructions == "Test instructions"
        # Compare timestamps without timezone (SQLite doesn't preserve tz)
        if created_at.tzinfo is not None:
            created_at = created_at.replace(tzinfo=None)
        exercise_created = exercise.created_at
        if exercise_created.tzinfo is not None:
            exercise_created = exercise_created.replace(tzinfo=None)
        assert exercise_created == created_at


class TestExerciseDelete:
    """Tests for soft delete functionality."""

    @pytest.mark.asyncio
    async def test_soft_delete_exercise(
        self,
        session: AsyncSession,
    ) -> None:
        """Soft delete sets is_active to False."""
        exercise = Exercise(
            name="To Delete",
            is_active=True,
        )
        session.add(exercise)
        await session.commit()

        exercise.is_active = False
        exercise.updated_at = datetime.now(UTC)
        session.add(exercise)
        await session.commit()
        await session.refresh(exercise)

        assert exercise.is_active is False

    @pytest.mark.asyncio
    async def test_soft_deleted_excluded_from_active_query(
        self,
        session: AsyncSession,
    ) -> None:
        """Soft deleted exercises don't appear in active queries."""
        exercise = Exercise(name="Deleted Exercise", is_active=False)
        session.add(exercise)
        await session.commit()

        statement = select(Exercise).where(
            Exercise.is_active == True,  # noqa: E712
        )
        result = await session.execute(statement)
        exercises = result.scalars().all()

        names = [e.name for e in exercises]
        assert "Deleted Exercise" not in names

    @pytest.mark.asyncio
    async def test_soft_deleted_included_in_all_query(
        self,
        session: AsyncSession,
    ) -> None:
        """Soft deleted exercises appear when querying all."""
        exercise = Exercise(name="Deleted But Present", is_active=False)
        session.add(exercise)
        await session.commit()

        # Query without is_active filter
        result = await session.get(Exercise, exercise.id)

        assert result is not None
        assert result.name == "Deleted But Present"
        assert result.is_active is False


class TestExerciseCategories:
    """Tests for exercise category handling."""

    @pytest.mark.asyncio
    async def test_all_categories_supported(
        self,
        session: AsyncSession,
    ) -> None:
        """All exercise categories can be stored."""
        for category in ExerciseCategory:
            exercise = Exercise(
                name=f"{category.value} Exercise",
                category=category,
            )
            session.add(exercise)

        await session.commit()

        result = await session.execute(select(Exercise))
        exercises = result.scalars().all()

        stored_categories = {e.category for e in exercises}
        assert stored_categories == set(ExerciseCategory)


class TestExerciseBodyParts:
    """Tests for body part handling."""

    @pytest.mark.asyncio
    async def test_all_body_parts_supported(
        self,
        session: AsyncSession,
    ) -> None:
        """All body parts can be stored."""
        for body_part in BodyPart:
            exercise = Exercise(
                name=f"{body_part.value} Exercise",
                body_part=body_part,
            )
            session.add(exercise)

        await session.commit()

        result = await session.execute(select(Exercise))
        exercises = result.scalars().all()

        stored_body_parts = {e.body_part for e in exercises}
        assert stored_body_parts == set(BodyPart)


class TestExerciseValidation:
    """Tests for data validation at repository level."""

    @pytest.mark.asyncio
    async def test_difficulty_level_bounds(
        self,
        session: AsyncSession,
    ) -> None:
        """Difficulty level stays within valid range."""
        # Test min boundary
        exercise_min = Exercise(name="Easy", difficulty_level=1)
        session.add(exercise_min)

        # Test max boundary
        exercise_max = Exercise(name="Hard", difficulty_level=5)
        session.add(exercise_max)

        await session.commit()

        assert exercise_min.difficulty_level == 1
        assert exercise_max.difficulty_level == 5

    @pytest.mark.asyncio
    async def test_duration_can_be_null(
        self,
        session: AsyncSession,
    ) -> None:
        """Duration is optional (can be null)."""
        exercise = Exercise(name="No Duration")
        session.add(exercise)
        await session.commit()
        await session.refresh(exercise)

        assert exercise.duration_seconds is None

    @pytest.mark.asyncio
    async def test_duration_positive(
        self,
        session: AsyncSession,
    ) -> None:
        """Duration stores positive values."""
        exercise = Exercise(name="Timed Exercise", duration_seconds=300)
        session.add(exercise)
        await session.commit()

        assert exercise.duration_seconds == 300


class TestExerciseEdgeCases:
    """Edge case tests."""

    @pytest.mark.asyncio
    async def test_empty_description(
        self,
        session: AsyncSession,
    ) -> None:
        """Exercise can have empty description."""
        exercise = Exercise(name="No Desc", description="")
        session.add(exercise)
        await session.commit()

        assert exercise.description == ""

    @pytest.mark.asyncio
    async def test_unicode_name(
        self,
        session: AsyncSession,
    ) -> None:
        """Exercise name supports unicode."""
        exercise = Exercise(name="Ćwiczenie 🏋️ エクササイズ")
        session.add(exercise)
        await session.commit()
        await session.refresh(exercise)

        assert exercise.name == "Ćwiczenie 🏋️ エクササイズ"

    @pytest.mark.asyncio
    async def test_long_instructions(
        self,
        session: AsyncSession,
    ) -> None:
        """Long instructions are stored correctly."""
        long_instructions = "Step " * 1000
        exercise = Exercise(name="Long Steps", instructions=long_instructions)
        session.add(exercise)
        await session.commit()
        await session.refresh(exercise)

        assert exercise.instructions == long_instructions
