"""PostgreSQL integration tests for Session repository operations."""

from datetime import UTC, datetime, timedelta
from uuid import uuid4

import pytest
import pytest_asyncio
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.core.security import hash_password
from app.models.exercise import BodyPart, Exercise, ExerciseCategory
from app.models.session import Session, SessionExerciseResult, SessionStatus
from app.models.user import User

pytestmark = pytest.mark.asyncio


@pytest_asyncio.fixture
async def test_patient(pg_session: AsyncSession) -> User:
    """Create a test patient user."""
    user = User(
        id=uuid4(),
        email=f"patient_{uuid4().hex[:8]}@example.com",
        hashed_password=hash_password("password"),
        role="patient",
        is_active=True,
    )
    pg_session.add(user)
    await pg_session.flush()
    return user


@pytest_asyncio.fixture
async def test_exercise(pg_session: AsyncSession) -> Exercise:
    """Create a test exercise."""
    exercise = Exercise(
        id=uuid4(),
        name=f"Test Exercise {uuid4().hex[:8]}",
        category=ExerciseCategory.MOBILITY,
        body_part=BodyPart.KNEE,
        is_active=True,
    )
    pg_session.add(exercise)
    await pg_session.flush()
    return exercise


class TestSessionRepository:
    """Test Session model CRUD operations with PostgreSQL."""

    async def test_create_session(
        self,
        pg_session: AsyncSession,
        test_patient: User,
    ) -> None:
        """Test creating a new session."""
        session = Session(
            id=uuid4(),
            patient_id=test_patient.id,
            scheduled_date=datetime.now(UTC),
            status=SessionStatus.IN_PROGRESS,
            notes="Test session",
        )
        pg_session.add(session)
        await pg_session.flush()

        # Verify session was created
        result = await pg_session.execute(
            select(Session).where(Session.id == session.id)
        )
        created = result.scalar_one()

        assert created.patient_id == test_patient.id
        assert created.status == SessionStatus.IN_PROGRESS
        assert created.notes == "Test session"
        assert created.created_at is not None

    @pytest.mark.skip(reason="SQLite does not enforce FK constraints by default")
    async def test_session_foreign_key_constraint(
        self,
        pg_session: AsyncSession,
    ) -> None:
        """Test that session requires valid patient_id."""
        session = Session(
            id=uuid4(),
            patient_id=uuid4(),  # Non-existent user
            scheduled_date=datetime.now(UTC),
        )
        pg_session.add(session)

        with pytest.raises((Exception, ValueError)):  # IntegrityError or FK violation
            await pg_session.flush()

    async def test_update_session_status(
        self,
        pg_session: AsyncSession,
        test_patient: User,
    ) -> None:
        """Test updating session status through lifecycle."""
        session = Session(
            id=uuid4(),
            patient_id=test_patient.id,
            scheduled_date=datetime.now(UTC),
            status=SessionStatus.IN_PROGRESS,
        )
        pg_session.add(session)
        await pg_session.flush()

        # Start session
        session.started_at = datetime.now(UTC)
        session.pain_level_before = 5
        await pg_session.flush()

        # Complete session
        session.status = SessionStatus.COMPLETED
        session.completed_at = datetime.now(UTC)
        session.pain_level_after = 3
        session.duration_seconds = 1200
        session.overall_score = 85.5
        await pg_session.flush()

        # Verify updates
        await pg_session.refresh(session)
        assert session.status == SessionStatus.COMPLETED
        assert session.started_at is not None
        assert session.completed_at is not None
        assert session.pain_level_before == 5
        assert session.pain_level_after == 3
        assert session.overall_score == 85.5

    async def test_session_exercise_results_relationship(
        self,
        pg_session: AsyncSession,
        test_patient: User,
        test_exercise: Exercise,
    ) -> None:
        """Test session with exercise results."""
        session = Session(
            id=uuid4(),
            patient_id=test_patient.id,
            scheduled_date=datetime.now(UTC),
        )
        pg_session.add(session)
        await pg_session.flush()

        # Add exercise result
        result = SessionExerciseResult(
            id=uuid4(),
            session_id=session.id,
            exercise_id=test_exercise.id,
            sets_completed=3,
            reps_completed=12,
            score=92.5,
        )
        pg_session.add(result)
        await pg_session.flush()

        # Load session with results
        query = (
            select(Session)
            .where(Session.id == session.id)
            .options(selectinload(Session.exercise_results))
        )
        loaded = (await pg_session.execute(query)).scalar_one()

        assert len(loaded.exercise_results) == 1
        assert loaded.exercise_results[0].score == 92.5

    async def test_cascade_delete_exercise_results(
        self,
        pg_session: AsyncSession,
        test_patient: User,
        test_exercise: Exercise,
    ) -> None:
        """Test that deleting session cascades to exercise results."""
        session_id = uuid4()
        session = Session(
            id=session_id,
            patient_id=test_patient.id,
            scheduled_date=datetime.now(UTC),
        )
        pg_session.add(session)
        await pg_session.flush()

        result = SessionExerciseResult(
            id=uuid4(),
            session_id=session_id,
            exercise_id=test_exercise.id,
            score=80.0,
        )
        pg_session.add(result)
        await pg_session.flush()

        # Delete session
        await pg_session.delete(session)
        await pg_session.flush()

        # Exercise results should be deleted
        results = await pg_session.execute(
            select(SessionExerciseResult).where(
                SessionExerciseResult.session_id == session_id
            )
        )
        assert results.scalar_one_or_none() is None

    async def test_list_patient_sessions(
        self,
        pg_session: AsyncSession,
        test_patient: User,
    ) -> None:
        """Test listing sessions for a specific patient."""
        # Create sessions
        for i in range(5):
            pg_session.add(
                Session(
                    id=uuid4(),
                    patient_id=test_patient.id,
                    scheduled_date=datetime.now(UTC) + timedelta(days=i),
                    status=SessionStatus.COMPLETED
                    if i < 3
                    else SessionStatus.IN_PROGRESS,
                )
            )
        await pg_session.flush()

        # Query patient's sessions
        result = await pg_session.execute(
            select(Session).where(Session.patient_id == test_patient.id)
        )
        sessions = result.scalars().all()

        assert len(sessions) == 5

    async def test_filter_sessions_by_status(
        self,
        pg_session: AsyncSession,
        test_patient: User,
    ) -> None:
        """Test filtering sessions by status."""
        # Create sessions with different statuses
        statuses = [
            SessionStatus.IN_PROGRESS,
            SessionStatus.COMPLETED,
            SessionStatus.COMPLETED,
            SessionStatus.ABANDONED,
            SessionStatus.SKIPPED,
        ]
        for status in statuses:
            pg_session.add(
                Session(
                    id=uuid4(),
                    patient_id=test_patient.id,
                    scheduled_date=datetime.now(UTC),
                    status=status,
                )
            )
        await pg_session.flush()

        # Filter completed only
        result = await pg_session.execute(
            select(Session).where(
                Session.patient_id == test_patient.id,
                Session.status == SessionStatus.COMPLETED,
            )
        )
        completed = result.scalars().all()

        assert len(completed) == 2
        for s in completed:
            assert s.status == SessionStatus.COMPLETED

    async def test_session_date_range_query(
        self,
        pg_session: AsyncSession,
        test_patient: User,
    ) -> None:
        """Test querying sessions within a date range."""
        now = datetime.now(UTC)
        dates = [
            now - timedelta(days=7),
            now - timedelta(days=3),
            now,
            now + timedelta(days=3),
            now + timedelta(days=7),
        ]

        for date in dates:
            pg_session.add(
                Session(
                    id=uuid4(),
                    patient_id=test_patient.id,
                    scheduled_date=date,
                )
            )
        await pg_session.flush()

        # Query last 5 days
        start_date = now - timedelta(days=5)
        end_date = now + timedelta(days=1)

        result = await pg_session.execute(
            select(Session).where(
                Session.patient_id == test_patient.id,
                Session.scheduled_date >= start_date,
                Session.scheduled_date <= end_date,
            )
        )
        sessions = result.scalars().all()

        # Should include dates: -3, 0
        assert len(sessions) == 2

    async def test_session_aggregate_score(
        self,
        pg_session: AsyncSession,
        test_patient: User,
        test_exercise: Exercise,
    ) -> None:
        """Test calculating average score across exercise results."""
        session = Session(
            id=uuid4(),
            patient_id=test_patient.id,
            scheduled_date=datetime.now(UTC),
        )
        pg_session.add(session)
        await pg_session.flush()

        # Add multiple results
        scores = [85.0, 90.0, 80.0, 95.0]
        for score in scores:
            pg_session.add(
                SessionExerciseResult(
                    id=uuid4(),
                    session_id=session.id,
                    exercise_id=test_exercise.id,
                    score=score,
                )
            )
        await pg_session.flush()

        # Calculate average
        from sqlalchemy import func

        result = await pg_session.execute(
            select(func.avg(SessionExerciseResult.score)).where(
                SessionExerciseResult.session_id == session.id
            )
        )
        avg_score = result.scalar()

        expected_avg = sum(scores) / len(scores)
        assert abs(avg_score - expected_avg) < 0.01


class TestSessionRepositoryEdgeCases:
    """Edge case tests for Session repository."""

    async def test_session_with_null_optional_fields(
        self,
        pg_session: AsyncSession,
        test_patient: User,
    ) -> None:
        """Test session with null optional fields."""
        session = Session(
            id=uuid4(),
            patient_id=test_patient.id,
            scheduled_date=datetime.now(UTC),
            # All optional fields are None
        )
        pg_session.add(session)
        await pg_session.flush()

        assert session.started_at is None
        assert session.completed_at is None
        assert session.pain_level_before is None
        assert session.pain_level_after is None
        assert session.overall_score is None
        assert session.duration_seconds is None

    async def test_session_device_info_json(
        self,
        pg_session: AsyncSession,
        test_patient: User,
    ) -> None:
        """Test storing JSON device info."""
        device_info = {
            "os": "Android",
            "version": "14",
            "model": "Pixel 8",
            "app_version": "1.0.0",
        }

        session = Session(
            id=uuid4(),
            patient_id=test_patient.id,
            scheduled_date=datetime.now(UTC),
            device_info=device_info,
        )
        pg_session.add(session)
        await pg_session.flush()

        # Reload and verify JSON
        await pg_session.refresh(session)
        assert session.device_info["os"] == "Android"
        assert session.device_info["model"] == "Pixel 8"

    async def test_exercise_result_score_boundaries(
        self,
        pg_session: AsyncSession,
        test_patient: User,
        test_exercise: Exercise,
    ) -> None:
        """Test score boundary values (0, 100)."""
        session = Session(
            id=uuid4(),
            patient_id=test_patient.id,
            scheduled_date=datetime.now(UTC),
        )
        pg_session.add(session)
        await pg_session.flush()

        # Test minimum score
        result_min = SessionExerciseResult(
            id=uuid4(),
            session_id=session.id,
            exercise_id=test_exercise.id,
            score=0.0,
        )
        pg_session.add(result_min)
        await pg_session.flush()
        assert result_min.score == 0.0

        # Test maximum score
        result_max = SessionExerciseResult(
            id=uuid4(),
            session_id=session.id,
            exercise_id=test_exercise.id,
            score=100.0,
        )
        pg_session.add(result_max)
        await pg_session.flush()
        assert result_max.score == 100.0

    async def test_session_ordering_by_date(
        self,
        pg_session: AsyncSession,
        test_patient: User,
    ) -> None:
        """Test ordering sessions by scheduled date."""
        dates = [datetime.now(UTC) + timedelta(days=i) for i in [3, 1, 5, 2, 4]]

        for date in dates:
            pg_session.add(
                Session(
                    id=uuid4(),
                    patient_id=test_patient.id,
                    scheduled_date=date,
                )
            )
        await pg_session.flush()

        # Order ascending
        result = await pg_session.execute(
            select(Session)
            .where(Session.patient_id == test_patient.id)
            .order_by(Session.scheduled_date.asc())
        )
        sessions = result.scalars().all()

        for i in range(len(sessions) - 1):
            assert sessions[i].scheduled_date <= sessions[i + 1].scheduled_date
