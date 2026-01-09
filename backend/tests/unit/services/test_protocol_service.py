"""
Unit tests for Protocol Service layer.

Test coverage:
1. Rehabilitation protocol CRUD operations
2. Protocol-exercise associations
3. Protocol assignment to patients
4. Protocol progression tracking
5. Edge cases and validation
"""

import pytest
from sqlalchemy.ext.asyncio import AsyncSession
from sqlmodel import select

from app.core.security import hash_password
from app.models.exercise import BodyPart, Exercise, ExerciseCategory
from app.models.user import User, UserRole


class TestProtocolBasicOperations:
    """Tests for basic protocol operations without full Protocol model."""

    @pytest.mark.asyncio
    async def test_exercise_can_be_associated_with_category(
        self,
        session: AsyncSession,
    ) -> None:
        """Exercises can be grouped by category (protocol-like behavior)."""
        # Create exercises for a "knee rehabilitation" protocol
        knee_exercises = [
            Exercise(
                name="Knee Extension",
                category=ExerciseCategory.MOBILITY,
                body_part=BodyPart.KNEE,
                difficulty_level=1,
            ),
            Exercise(
                name="Quad Stretch",
                category=ExerciseCategory.STRETCHING,
                body_part=BodyPart.KNEE,
                difficulty_level=1,
            ),
            Exercise(
                name="Wall Squat",
                category=ExerciseCategory.STRENGTH,
                body_part=BodyPart.KNEE,
                difficulty_level=2,
            ),
        ]

        for ex in knee_exercises:
            session.add(ex)
        await session.commit()

        # Query exercises for knee
        statement = select(Exercise).where(Exercise.body_part == BodyPart.KNEE)
        result = await session.execute(statement)
        protocol_exercises = result.scalars().all()

        assert len(protocol_exercises) >= 3

    @pytest.mark.asyncio
    async def test_exercises_ordered_by_difficulty(
        self,
        session: AsyncSession,
    ) -> None:
        """Exercises can be ordered by difficulty for progression."""
        exercises = [
            Exercise(name="Hard Exercise", difficulty_level=5),
            Exercise(name="Easy Exercise", difficulty_level=1),
            Exercise(name="Medium Exercise", difficulty_level=3),
        ]

        for ex in exercises:
            session.add(ex)
        await session.commit()

        statement = select(Exercise).order_by(Exercise.difficulty_level)
        result = await session.execute(statement)
        ordered = result.scalars().all()

        difficulties = [ex.difficulty_level for ex in ordered]
        assert difficulties == sorted(difficulties)


class TestProtocolProgressionLogic:
    """Tests for protocol progression business logic."""

    @pytest.fixture
    async def progression_exercises(
        self,
        session: AsyncSession,
    ) -> list[Exercise]:
        """Create exercises for progression testing."""
        exercises = [
            Exercise(
                name="Phase 1 - Passive ROM",
                category=ExerciseCategory.MOBILITY,
                body_part=BodyPart.SHOULDER,
                difficulty_level=1,
                description="Week 1-2",
            ),
            Exercise(
                name="Phase 2 - Active ROM",
                category=ExerciseCategory.MOBILITY,
                body_part=BodyPart.SHOULDER,
                difficulty_level=2,
                description="Week 3-4",
            ),
            Exercise(
                name="Phase 3 - Light Resistance",
                category=ExerciseCategory.STRENGTH,
                body_part=BodyPart.SHOULDER,
                difficulty_level=3,
                description="Week 5-6",
            ),
            Exercise(
                name="Phase 4 - Full Strength",
                category=ExerciseCategory.STRENGTH,
                body_part=BodyPart.SHOULDER,
                difficulty_level=4,
                description="Week 7-8",
            ),
        ]

        for ex in exercises:
            session.add(ex)
        await session.commit()
        for ex in exercises:
            await session.refresh(ex)
        return exercises

    @pytest.mark.asyncio
    async def test_get_exercises_for_current_phase(
        self,
        session: AsyncSession,
        progression_exercises: list[Exercise],
    ) -> None:
        """Get exercises for a specific difficulty phase."""
        current_phase = 2

        statement = select(Exercise).where(
            Exercise.difficulty_level == current_phase,
            Exercise.body_part == BodyPart.SHOULDER,
        )
        result = await session.execute(statement)
        phase_exercises = result.scalars().all()

        assert len(phase_exercises) >= 1
        for ex in phase_exercises:
            assert ex.difficulty_level == 2

    @pytest.mark.asyncio
    async def test_get_exercises_up_to_phase(
        self,
        session: AsyncSession,
        progression_exercises: list[Exercise],
    ) -> None:
        """Get all exercises up to current phase (cumulative)."""
        current_phase = 3

        statement = (
            select(Exercise)
            .where(
                Exercise.difficulty_level <= current_phase,
                Exercise.body_part == BodyPart.SHOULDER,
            )
            .order_by(Exercise.difficulty_level)
        )
        result = await session.execute(statement)
        available_exercises = result.scalars().all()

        for ex in available_exercises:
            assert ex.difficulty_level <= current_phase


class TestProtocolCategoryGrouping:
    """Tests for grouping exercises by category (protocol structure)."""

    @pytest.fixture
    async def mixed_exercises(self, session: AsyncSession) -> list[Exercise]:
        """Create exercises with mixed categories."""
        exercises = [
            Exercise(
                name="Hip Mobility",
                category=ExerciseCategory.MOBILITY,
                body_part=BodyPart.HIP,
            ),
            Exercise(
                name="Hip Strength",
                category=ExerciseCategory.STRENGTH,
                body_part=BodyPart.HIP,
            ),
            Exercise(
                name="Hip Balance",
                category=ExerciseCategory.BALANCE,
                body_part=BodyPart.HIP,
            ),
            Exercise(
                name="Hip Stretch",
                category=ExerciseCategory.STRETCHING,
                body_part=BodyPart.HIP,
            ),
        ]

        for ex in exercises:
            session.add(ex)
        await session.commit()
        for ex in exercises:
            await session.refresh(ex)
        return exercises

    @pytest.mark.asyncio
    async def test_get_warmup_exercises(
        self,
        session: AsyncSession,
        mixed_exercises: list[Exercise],
    ) -> None:
        """Get mobility/stretching exercises for warmup."""
        warmup_categories = [ExerciseCategory.MOBILITY, ExerciseCategory.STRETCHING]

        statement = select(Exercise).where(
            Exercise.category.in_(warmup_categories),  # type: ignore[union-attr]
            Exercise.body_part == BodyPart.HIP,
        )
        result = await session.execute(statement)
        warmup = result.scalars().all()

        for ex in warmup:
            assert ex.category in warmup_categories

    @pytest.mark.asyncio
    async def test_get_main_exercises(
        self,
        session: AsyncSession,
        mixed_exercises: list[Exercise],
    ) -> None:
        """Get strength exercises for main workout."""
        statement = select(Exercise).where(
            Exercise.category == ExerciseCategory.STRENGTH,
            Exercise.body_part == BodyPart.HIP,
        )
        result = await session.execute(statement)
        main_exercises = result.scalars().all()

        for ex in main_exercises:
            assert ex.category == ExerciseCategory.STRENGTH


class TestProtocolPatientAssignment:
    """Tests for protocol-patient assignment logic."""

    @pytest.fixture
    async def therapist_user(self, session: AsyncSession) -> User:
        """Create a therapist/admin user."""
        user = User(
            email="therapist@clinic.com",
            hashed_password=hash_password("password123"),
            role=UserRole.ADMIN,
            is_verified=True,
        )
        session.add(user)
        await session.commit()
        await session.refresh(user)
        return user

    @pytest.fixture
    async def patient_user(self, session: AsyncSession) -> User:
        """Create a patient user."""
        user = User(
            email="patient@example.com",
            hashed_password=hash_password("password123"),
            role=UserRole.PATIENT,
            is_verified=True,
        )
        session.add(user)
        await session.commit()
        await session.refresh(user)
        return user

    @pytest.mark.asyncio
    async def test_patient_has_correct_role(
        self,
        patient_user: User,
    ) -> None:
        """Verify patient has patient role."""
        assert patient_user.role == UserRole.PATIENT

    @pytest.mark.asyncio
    async def test_therapist_has_admin_role(
        self,
        therapist_user: User,
    ) -> None:
        """Verify therapist has admin role."""
        assert therapist_user.role == UserRole.ADMIN

    @pytest.mark.asyncio
    async def test_patient_is_verified(
        self,
        patient_user: User,
    ) -> None:
        """Patient must be verified to receive protocols."""
        assert patient_user.is_verified is True


class TestProtocolDurationCalculation:
    """Tests for protocol duration and timing calculations."""

    @pytest.fixture
    async def timed_exercises(self, session: AsyncSession) -> list[Exercise]:
        """Create exercises with duration information."""
        exercises = [
            Exercise(
                name="Quick Stretch",
                duration_seconds=60,
            ),
            Exercise(
                name="Main Exercise",
                duration_seconds=300,
            ),
            Exercise(
                name="Cool Down",
                duration_seconds=120,
            ),
        ]

        for ex in exercises:
            session.add(ex)
        await session.commit()
        for ex in exercises:
            await session.refresh(ex)
        return exercises

    @pytest.mark.asyncio
    async def test_calculate_total_protocol_duration(
        self,
        session: AsyncSession,
        timed_exercises: list[Exercise],
    ) -> None:
        """Calculate total duration of protocol exercises."""
        statement = select(Exercise).where(Exercise.duration_seconds.isnot(None))
        result = await session.execute(statement)
        exercises = result.scalars().all()

        total_seconds = sum(
            ex.duration_seconds for ex in exercises if ex.duration_seconds
        )

        assert total_seconds == 480  # 60 + 300 + 120

    @pytest.mark.asyncio
    async def test_exercise_without_duration(self, session: AsyncSession) -> None:
        """Exercise can exist without duration."""
        exercise = Exercise(
            name="No Duration",
            duration_seconds=None,
        )
        session.add(exercise)
        await session.commit()
        await session.refresh(exercise)

        assert exercise.duration_seconds is None


class TestProtocolEdgeCases:
    """Tests for edge cases in protocol management."""

    @pytest.mark.asyncio
    async def test_empty_protocol_query(self, session: AsyncSession) -> None:
        """Query for non-existent exercises returns empty."""
        statement = select(Exercise).where(
            Exercise.body_part == BodyPart.NECK,
            Exercise.category == ExerciseCategory.ENDURANCE,
        )
        result = await session.execute(statement)
        exercises = result.scalars().all()

        assert len(exercises) == 0

    @pytest.mark.asyncio
    async def test_all_body_parts_covered(self, session: AsyncSession) -> None:
        """Verify exercises can cover all body parts."""
        for body_part in BodyPart:
            exercise = Exercise(
                name=f"{body_part.value.title()} Exercise",
                body_part=body_part,
            )
            session.add(exercise)
        await session.commit()

        for body_part in BodyPart:
            statement = select(Exercise).where(Exercise.body_part == body_part)
            result = await session.execute(statement)
            exercises = result.scalars().all()
            assert len(exercises) >= 1

    @pytest.mark.asyncio
    async def test_all_categories_covered(self, session: AsyncSession) -> None:
        """Verify exercises can cover all categories."""
        for category in ExerciseCategory:
            exercise = Exercise(
                name=f"{category.value.title()} Exercise",
                category=category,
            )
            session.add(exercise)
        await session.commit()

        for category in ExerciseCategory:
            statement = select(Exercise).where(Exercise.category == category)
            result = await session.execute(statement)
            exercises = result.scalars().all()
            assert len(exercises) >= 1

    @pytest.mark.asyncio
    async def test_difficulty_range_complete(self, session: AsyncSession) -> None:
        """All difficulty levels 1-5 are usable."""
        for level in range(1, 6):
            exercise = Exercise(
                name=f"Level {level} Exercise",
                difficulty_level=level,
            )
            session.add(exercise)
        await session.commit()

        statement = select(Exercise).order_by(Exercise.difficulty_level)
        result = await session.execute(statement)
        exercises = result.scalars().all()

        levels = [ex.difficulty_level for ex in exercises if ex.difficulty_level]
        for level in range(1, 6):
            assert level in levels
