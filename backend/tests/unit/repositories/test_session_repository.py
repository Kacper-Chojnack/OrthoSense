"""
Unit tests for Session Repository layer.

Test coverage:
1. Session CRUD operations
2. Session queries (by user, status, date range)
3. Exercise result association
4. Session lifecycle state management
5. Pagination and filtering
6. Device info and metadata
7. Score aggregation
8. Edge cases and error handling
"""

from datetime import UTC, datetime, timedelta
from uuid import uuid4

import pytest
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload
from sqlmodel import select

from app.core.security import hash_password
from app.models.exercise import BodyPart, Exercise, ExerciseCategory
from app.models.session import (
    Session,
    SessionExerciseResult,
    SessionStatus,
)
from app.models.user import User


class TestSessionCreate:
    """Tests for session creation at repository level."""

    @pytest.fixture
    async def patient_user(self, session: AsyncSession) -> User:
        """Create a patient user for sessions."""
        user = User(
            id=uuid4(),
            email="patient@example.com",
            hashed_password=hash_password("password123"),
            is_active=True,
            is_verified=True,
        )
        session.add(user)
        await session.commit()
        return user

    @pytest.mark.asyncio
    async def test_create_session_minimal(
        self,
        session: AsyncSession,
        patient_user: User,
    ) -> None:
        """Create session with minimal data."""
        new_session = Session(
            patient_id=patient_user.id,
            scheduled_date=datetime.now(UTC),
        )
        session.add(new_session)
        await session.commit()
        await session.refresh(new_session)

        assert new_session.id is not None
        assert new_session.patient_id == patient_user.id
        assert new_session.status == SessionStatus.IN_PROGRESS
        assert new_session.created_at is not None

    @pytest.mark.asyncio
    async def test_create_session_with_notes(
        self,
        session: AsyncSession,
        patient_user: User,
    ) -> None:
        """Create session with notes."""
        new_session = Session(
            patient_id=patient_user.id,
            scheduled_date=datetime.now(UTC),
            notes="Morning session, patient feeling good",
        )
        session.add(new_session)
        await session.commit()

        assert new_session.notes == "Morning session, patient feeling good"

    @pytest.mark.asyncio
    async def test_create_scheduled_session(
        self,
        session: AsyncSession,
        patient_user: User,
    ) -> None:
        """Create session scheduled for future."""
        future_date = datetime.now(UTC) + timedelta(days=7)
        new_session = Session(
            patient_id=patient_user.id,
            scheduled_date=future_date,
        )
        session.add(new_session)
        await session.commit()

        assert new_session.scheduled_date == future_date


class TestSessionQueries:
    """Tests for session query operations."""

    @pytest.fixture
    async def patient_with_sessions(
        self,
        session: AsyncSession,
    ) -> tuple[User, list[Session]]:
        """Create patient with multiple sessions."""
        user = User(
            id=uuid4(),
            email="multi@example.com",
            hashed_password=hash_password("password123"),
            is_active=True,
            is_verified=True,
        )
        session.add(user)
        await session.commit()

        sessions_list = []
        now = datetime.now(UTC)

        # Create sessions with different statuses
        for i, status in enumerate(
            [
                SessionStatus.COMPLETED,
                SessionStatus.COMPLETED,
                SessionStatus.IN_PROGRESS,
                SessionStatus.SKIPPED,
                SessionStatus.ABANDONED,
            ]
        ):
            sess = Session(
                patient_id=user.id,
                scheduled_date=now - timedelta(days=i),
                status=status,
            )
            session.add(sess)
            sessions_list.append(sess)

        await session.commit()
        return user, sessions_list

    @pytest.mark.asyncio
    async def test_query_sessions_by_patient(
        self,
        session: AsyncSession,
        patient_with_sessions: tuple[User, list[Session]],
    ) -> None:
        """Query all sessions for a patient."""
        user, _ = patient_with_sessions

        statement = select(Session).where(Session.patient_id == user.id)
        result = await session.execute(statement)
        sessions = result.scalars().all()

        assert len(sessions) == 5

    @pytest.mark.asyncio
    async def test_query_sessions_by_status(
        self,
        session: AsyncSession,
        patient_with_sessions: tuple[User, list[Session]],
    ) -> None:
        """Filter sessions by status."""
        user, _ = patient_with_sessions

        statement = select(Session).where(
            Session.patient_id == user.id,
            Session.status == SessionStatus.COMPLETED,
        )
        result = await session.execute(statement)
        sessions = result.scalars().all()

        assert len(sessions) == 2

    @pytest.mark.asyncio
    async def test_query_sessions_date_range(
        self,
        session: AsyncSession,
        patient_with_sessions: tuple[User, list[Session]],
    ) -> None:
        """Query sessions within date range."""
        user, _ = patient_with_sessions
        now = datetime.now(UTC)
        # Use 3.5 days ago to ensure we get day -3 included
        three_days_ago = now - timedelta(days=3, hours=12)

        statement = select(Session).where(
            Session.patient_id == user.id,
            Session.scheduled_date >= three_days_ago,
        )
        result = await session.execute(statement)
        sessions = result.scalars().all()

        # Fixture creates sessions at day 0, -1, -2, -3, -4
        # >= 3.5 days ago should return 4 sessions (days 0, -1, -2, -3)
        assert len(sessions) == 4

    @pytest.mark.asyncio
    async def test_query_sessions_ordered_by_date(
        self,
        session: AsyncSession,
        patient_with_sessions: tuple[User, list[Session]],
    ) -> None:
        """Sessions ordered by date descending."""
        user, _ = patient_with_sessions

        statement = (
            select(Session)
            .where(Session.patient_id == user.id)
            .order_by(Session.scheduled_date.desc())
        )
        result = await session.execute(statement)
        sessions = result.scalars().all()

        dates = [s.scheduled_date for s in sessions]
        assert dates == sorted(dates, reverse=True)


class TestSessionPagination:
    """Tests for session pagination."""

    @pytest.fixture
    async def user_with_many_sessions(
        self,
        session: AsyncSession,
    ) -> tuple[User, list[Session]]:
        """Create user with many sessions for pagination."""
        user = User(
            id=uuid4(),
            email="paginate@example.com",
            hashed_password=hash_password("password123"),
            is_active=True,
            is_verified=True,
        )
        session.add(user)
        await session.commit()

        sessions_list = []
        now = datetime.now(UTC)

        for i in range(30):
            sess = Session(
                patient_id=user.id,
                scheduled_date=now - timedelta(days=i),
                status=SessionStatus.COMPLETED,
            )
            session.add(sess)
            sessions_list.append(sess)

        await session.commit()
        return user, sessions_list

    @pytest.mark.asyncio
    async def test_pagination_skip_limit(
        self,
        session: AsyncSession,
        user_with_many_sessions: tuple[User, list[Session]],
    ) -> None:
        """Test skip and limit pagination."""
        user, _ = user_with_many_sessions

        statement = (
            select(Session).where(Session.patient_id == user.id).offset(0).limit(10)
        )
        result = await session.execute(statement)
        page1 = result.scalars().all()

        assert len(page1) == 10

        statement = (
            select(Session).where(Session.patient_id == user.id).offset(10).limit(10)
        )
        result = await session.execute(statement)
        page2 = result.scalars().all()

        assert len(page2) == 10
        assert page1[0].id != page2[0].id

    @pytest.mark.asyncio
    async def test_pagination_last_page(
        self,
        session: AsyncSession,
        user_with_many_sessions: tuple[User, list[Session]],
    ) -> None:
        """Last page has remaining items."""
        user, _ = user_with_many_sessions

        statement = (
            select(Session).where(Session.patient_id == user.id).offset(25).limit(10)
        )
        result = await session.execute(statement)
        sessions = result.scalars().all()

        assert len(sessions) == 5


class TestSessionExerciseResults:
    """Tests for session-exercise result relationships."""

    @pytest.fixture
    async def session_with_exercises(
        self,
        session: AsyncSession,
    ) -> tuple[Session, list[Exercise]]:
        """Create session with exercises."""
        user = User(
            id=uuid4(),
            email="exercises@example.com",
            hashed_password=hash_password("password123"),
            is_active=True,
            is_verified=True,
        )
        session.add(user)
        await session.commit()

        exercises = [
            Exercise(
                id=uuid4(),
                name=f"Exercise {i}",
                category=ExerciseCategory.MOBILITY,
                body_part=BodyPart.KNEE,
            )
            for i in range(3)
        ]
        for ex in exercises:
            session.add(ex)

        sess = Session(
            id=uuid4(),
            patient_id=user.id,
            scheduled_date=datetime.now(UTC),
            started_at=datetime.now(UTC),
        )
        session.add(sess)
        await session.commit()

        return sess, exercises

    @pytest.mark.asyncio
    async def test_add_exercise_result(
        self,
        session: AsyncSession,
        session_with_exercises: tuple[Session, list[Exercise]],
    ) -> None:
        """Add exercise result to session."""
        sess, exercises = session_with_exercises

        result = SessionExerciseResult(
            session_id=sess.id,
            exercise_id=exercises[0].id,
            sets_completed=3,
            reps_completed=10,
            score=85.0,
        )
        session.add(result)
        await session.commit()
        await session.refresh(result)

        assert result.id is not None
        assert result.score == 85.0

    @pytest.mark.asyncio
    async def test_multiple_exercise_results(
        self,
        session: AsyncSession,
        session_with_exercises: tuple[Session, list[Exercise]],
    ) -> None:
        """Add multiple results to one session."""
        sess, exercises = session_with_exercises

        for i, ex in enumerate(exercises):
            result = SessionExerciseResult(
                session_id=sess.id,
                exercise_id=ex.id,
                score=80.0 + i * 5,
            )
            session.add(result)

        await session.commit()

        # Query with relationship loading
        statement = (
            select(Session)
            .where(Session.id == sess.id)
            .options(selectinload(Session.exercise_results))  # type: ignore[arg-type]
        )
        result = await session.execute(statement)
        loaded_session = result.scalar_one()

        assert len(loaded_session.exercise_results) == 3

    @pytest.mark.asyncio
    async def test_calculate_session_average_score(
        self,
        session: AsyncSession,
        session_with_exercises: tuple[Session, list[Exercise]],
    ) -> None:
        """Calculate average score from exercise results."""
        sess, exercises = session_with_exercises

        scores = [80.0, 90.0, 85.0]
        for ex, score in zip(exercises, scores, strict=True):
            result = SessionExerciseResult(
                session_id=sess.id,
                exercise_id=ex.id,
                score=score,
            )
            session.add(result)

        await session.commit()

        # Calculate average
        statement = select(SessionExerciseResult).where(
            SessionExerciseResult.session_id == sess.id,
        )
        result = await session.execute(statement)
        results = result.scalars().all()

        scores_list = [r.score for r in results if r.score is not None]
        average = sum(scores_list) / len(scores_list)

        assert average == 85.0


class TestSessionLifecycle:
    """Tests for session state transitions."""

    @pytest.fixture
    async def patient_session(
        self,
        session: AsyncSession,
    ) -> Session:
        """Create patient and session."""
        user = User(
            id=uuid4(),
            email="lifecycle@example.com",
            hashed_password=hash_password("password123"),
            is_active=True,
            is_verified=True,
        )
        session.add(user)
        await session.commit()

        sess = Session(
            patient_id=user.id,
            scheduled_date=datetime.now(UTC),
        )
        session.add(sess)
        await session.commit()

        return sess

    @pytest.mark.asyncio
    async def test_session_start_transition(
        self,
        session: AsyncSession,
        patient_session: Session,
    ) -> None:
        """Start session updates started_at."""
        patient_session.started_at = datetime.now(UTC)
        patient_session.pain_level_before = 5

        session.add(patient_session)
        await session.commit()
        await session.refresh(patient_session)

        assert patient_session.started_at is not None
        assert patient_session.pain_level_before == 5
        assert patient_session.status == SessionStatus.IN_PROGRESS

    @pytest.mark.asyncio
    async def test_session_complete_transition(
        self,
        session: AsyncSession,
        patient_session: Session,
    ) -> None:
        """Complete session updates all fields."""
        start_time = datetime.now(UTC) - timedelta(minutes=30)
        patient_session.started_at = start_time
        patient_session.pain_level_before = 6

        patient_session.completed_at = datetime.now(UTC)
        patient_session.status = SessionStatus.COMPLETED
        patient_session.pain_level_after = 3
        patient_session.overall_score = 87.5

        if patient_session.started_at:
            duration = patient_session.completed_at - patient_session.started_at
            patient_session.duration_seconds = int(duration.total_seconds())

        session.add(patient_session)
        await session.commit()
        await session.refresh(patient_session)

        assert patient_session.status == SessionStatus.COMPLETED
        assert patient_session.duration_seconds >= 1800  # ~30 min
        assert patient_session.pain_level_after == 3

    @pytest.mark.asyncio
    async def test_session_skip_transition(
        self,
        session: AsyncSession,
        patient_session: Session,
    ) -> None:
        """Skip session without starting."""
        patient_session.status = SessionStatus.SKIPPED
        patient_session.notes = "Patient unavailable"

        session.add(patient_session)
        await session.commit()
        await session.refresh(patient_session)

        assert patient_session.status == SessionStatus.SKIPPED
        assert patient_session.started_at is None

    @pytest.mark.asyncio
    async def test_session_abandon_transition(
        self,
        session: AsyncSession,
        patient_session: Session,
    ) -> None:
        """Abandon session after starting."""
        patient_session.started_at = datetime.now(UTC)
        patient_session.status = SessionStatus.ABANDONED
        patient_session.notes = "Technical issues"

        session.add(patient_session)
        await session.commit()
        await session.refresh(patient_session)

        assert patient_session.status == SessionStatus.ABANDONED
        assert patient_session.started_at is not None
        assert patient_session.completed_at is None


class TestSessionDeviceInfo:
    """Tests for device info metadata."""

    @pytest.fixture
    async def session_for_device(
        self,
        session: AsyncSession,
    ) -> Session:
        """Create session for device tests."""
        user = User(
            id=uuid4(),
            email="device@example.com",
            hashed_password=hash_password("password123"),
            is_active=True,
            is_verified=True,
        )
        session.add(user)
        await session.commit()

        sess = Session(
            patient_id=user.id,
            scheduled_date=datetime.now(UTC),
        )
        session.add(sess)
        await session.commit()

        return sess

    @pytest.mark.asyncio
    async def test_store_device_info(
        self,
        session: AsyncSession,
        session_for_device: Session,
    ) -> None:
        """Store device information."""
        session_for_device.device_info = {
            "platform": "iOS",
            "version": "17.0",
            "model": "iPhone 15 Pro",
            "app_version": "2.0.0",
        }

        session.add(session_for_device)
        await session.commit()
        await session.refresh(session_for_device)

        assert session_for_device.device_info["platform"] == "iOS"
        assert session_for_device.device_info["model"] == "iPhone 15 Pro"

    @pytest.mark.asyncio
    async def test_device_info_defaults_empty(
        self,
        session: AsyncSession,
        session_for_device: Session,
    ) -> None:
        """Device info defaults to empty dict."""
        await session.refresh(session_for_device)

        assert session_for_device.device_info == {}


class TestSessionIsolation:
    """Tests for user session isolation."""

    @pytest.mark.asyncio
    async def test_sessions_isolated_by_user(
        self,
        session: AsyncSession,
    ) -> None:
        """Different users have isolated sessions."""
        user1 = User(
            id=uuid4(),
            email="user1@example.com",
            hashed_password=hash_password("password"),
            is_active=True,
        )
        user2 = User(
            id=uuid4(),
            email="user2@example.com",
            hashed_password=hash_password("password"),
            is_active=True,
        )
        session.add(user1)
        session.add(user2)
        await session.commit()

        # Create sessions for each user
        sess1 = Session(patient_id=user1.id, scheduled_date=datetime.now(UTC))
        sess2 = Session(patient_id=user2.id, scheduled_date=datetime.now(UTC))
        session.add(sess1)
        session.add(sess2)
        await session.commit()

        # Query user1's sessions
        statement = select(Session).where(Session.patient_id == user1.id)
        result = await session.execute(statement)
        user1_sessions = result.scalars().all()

        assert len(user1_sessions) == 1
        assert user1_sessions[0].patient_id == user1.id


class TestSessionCascadeDeletes:
    """Tests for cascade delete behavior."""

    @pytest.mark.asyncio
    async def test_delete_session_cascades_results(
        self,
        session: AsyncSession,
    ) -> None:
        """Deleting session cascades to exercise results."""
        user = User(
            id=uuid4(),
            email="cascade@example.com",
            hashed_password=hash_password("password"),
            is_active=True,
        )
        session.add(user)

        exercise = Exercise(
            id=uuid4(),
            name="Test Exercise",
            category=ExerciseCategory.MOBILITY,
            body_part=BodyPart.KNEE,
        )
        session.add(exercise)
        await session.commit()

        sess = Session(
            id=uuid4(),
            patient_id=user.id,
            scheduled_date=datetime.now(UTC),
        )
        session.add(sess)
        await session.commit()

        result = SessionExerciseResult(
            id=uuid4(),
            session_id=sess.id,
            exercise_id=exercise.id,
            score=80.0,
        )
        session.add(result)
        await session.commit()

        result_id = result.id

        # Delete session
        await session.delete(sess)
        await session.commit()

        # Verify result is deleted
        remaining = await session.get(SessionExerciseResult, result_id)
        assert remaining is None


class TestSessionEdgeCases:
    """Edge case tests for sessions."""

    @pytest.fixture
    async def edge_case_user(self, session: AsyncSession) -> User:
        """Create user for edge case tests."""
        user = User(
            id=uuid4(),
            email="edge@example.com",
            hashed_password=hash_password("password"),
            is_active=True,
        )
        session.add(user)
        await session.commit()
        return user

    @pytest.mark.asyncio
    async def test_session_with_zero_duration(
        self,
        session: AsyncSession,
        edge_case_user: User,
    ) -> None:
        """Session can have zero duration."""
        now = datetime.now(UTC)
        sess = Session(
            patient_id=edge_case_user.id,
            scheduled_date=now,
            started_at=now,
            completed_at=now,
            duration_seconds=0,
            status=SessionStatus.COMPLETED,
        )
        session.add(sess)
        await session.commit()

        assert sess.duration_seconds == 0

    @pytest.mark.asyncio
    async def test_session_with_unicode_notes(
        self,
        session: AsyncSession,
        edge_case_user: User,
    ) -> None:
        """Session notes support unicode."""
        sess = Session(
            patient_id=edge_case_user.id,
            scheduled_date=datetime.now(UTC),
            notes="Ćwiczenie 💪 テスト",
        )
        session.add(sess)
        await session.commit()
        await session.refresh(sess)

        assert "💪" in sess.notes

    @pytest.mark.asyncio
    async def test_session_pain_levels_boundary(
        self,
        session: AsyncSession,
        edge_case_user: User,
    ) -> None:
        """Pain levels at boundary values."""
        sess = Session(
            patient_id=edge_case_user.id,
            scheduled_date=datetime.now(UTC),
            pain_level_before=0,
            pain_level_after=10,
        )
        session.add(sess)
        await session.commit()

        assert sess.pain_level_before == 0
        assert sess.pain_level_after == 10

    @pytest.mark.asyncio
    async def test_session_score_boundary(
        self,
        session: AsyncSession,
        edge_case_user: User,
    ) -> None:
        """Overall score at boundary values."""
        sess = Session(
            patient_id=edge_case_user.id,
            scheduled_date=datetime.now(UTC),
            overall_score=100.0,
        )
        session.add(sess)
        await session.commit()

        assert sess.overall_score == 100.0
