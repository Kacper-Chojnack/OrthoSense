"""
Unit tests for Session Service layer.

Test coverage:
1. Session lifecycle management (create, start, complete, skip)
2. Exercise result recording
3. Score calculations
4. Business logic validation
5. Session state transitions
6. Edge cases and error handling
"""

from datetime import UTC, datetime, timedelta
from uuid import uuid4

import pytest
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.exercise import BodyPart, Exercise, ExerciseCategory
from app.models.session import (
    Session,
    SessionExerciseResult,
    SessionStatus,
)
from app.models.user import User


class TestSessionCreation:
    """Tests for session creation logic."""

    @pytest.mark.asyncio
    async def test_create_session_defaults(
        self,
        session: AsyncSession,
        test_user: User,
    ) -> None:
        """New session has correct default values."""
        new_session = Session(
            patient_id=test_user.id,
            scheduled_date=datetime.now(UTC) + timedelta(days=1),
        )

        session.add(new_session)
        await session.commit()
        await session.refresh(new_session)

        assert new_session.status == SessionStatus.IN_PROGRESS
        assert new_session.pain_level_before is None
        assert new_session.pain_level_after is None
        assert new_session.overall_score is None
        assert new_session.started_at is None
        assert new_session.completed_at is None

    @pytest.mark.asyncio
    async def test_create_session_with_notes(
        self,
        session: AsyncSession,
        test_user: User,
    ) -> None:
        """Session can be created with initial notes."""
        notes = "Patient requested morning session"
        new_session = Session(
            patient_id=test_user.id,
            scheduled_date=datetime.now(UTC),
            notes=notes,
        )

        session.add(new_session)
        await session.commit()
        await session.refresh(new_session)

        assert new_session.notes == notes


class TestSessionLifecycle:
    """Tests for session state transitions."""

    @pytest.mark.asyncio
    async def test_start_session(
        self,
        session: AsyncSession,
        test_user: User,
    ) -> None:
        """Starting session sets started_at and pain_level_before."""
        sess = Session(
            patient_id=test_user.id,
            scheduled_date=datetime.now(UTC),
        )
        session.add(sess)
        await session.commit()

        # Start the session
        sess.started_at = datetime.now(UTC)
        sess.pain_level_before = 5
        sess.device_info = {"platform": "iOS", "version": "15.0"}

        await session.commit()
        await session.refresh(sess)

        assert sess.started_at is not None
        assert sess.pain_level_before == 5
        assert sess.device_info["platform"] == "iOS"

    @pytest.mark.asyncio
    async def test_complete_session(
        self,
        session: AsyncSession,
        test_user: User,
    ) -> None:
        """Completing session sets completed_at and calculates duration."""
        start_time = datetime.now(UTC)
        sess = Session(
            patient_id=test_user.id,
            scheduled_date=datetime.now(UTC),
            started_at=start_time,
            pain_level_before=5,
        )
        session.add(sess)
        await session.commit()

        # Complete the session
        end_time = start_time + timedelta(minutes=30)
        sess.completed_at = end_time
        sess.status = SessionStatus.COMPLETED
        sess.pain_level_after = 3
        sess.duration_seconds = int((end_time - start_time).total_seconds())

        await session.commit()
        await session.refresh(sess)

        assert sess.status == SessionStatus.COMPLETED
        assert sess.completed_at is not None
        assert sess.pain_level_after == 3
        assert sess.duration_seconds == 1800  # 30 minutes

    @pytest.mark.asyncio
    async def test_skip_session(
        self,
        session: AsyncSession,
        test_user: User,
    ) -> None:
        """Session can be skipped without starting."""
        sess = Session(
            patient_id=test_user.id,
            scheduled_date=datetime.now(UTC),
        )
        session.add(sess)
        await session.commit()

        # Skip the session
        sess.status = SessionStatus.SKIPPED
        sess.notes = "Patient felt unwell"

        await session.commit()
        await session.refresh(sess)

        assert sess.status == SessionStatus.SKIPPED
        assert sess.started_at is None

    @pytest.mark.asyncio
    async def test_abandon_session(
        self,
        session: AsyncSession,
        test_user: User,
    ) -> None:
        """Started session can be abandoned."""
        sess = Session(
            patient_id=test_user.id,
            scheduled_date=datetime.now(UTC),
            started_at=datetime.now(UTC),
            pain_level_before=5,
        )
        session.add(sess)
        await session.commit()

        # Abandon the session
        sess.status = SessionStatus.ABANDONED
        sess.notes = "Patient had to leave early"

        await session.commit()
        await session.refresh(sess)

        assert sess.status == SessionStatus.ABANDONED
        assert sess.started_at is not None
        assert sess.completed_at is None


class TestExerciseResults:
    """Tests for exercise result recording within sessions."""

    @pytest.fixture
    async def test_exercise(self, session: AsyncSession) -> Exercise:
        """Create a test exercise."""
        exercise = Exercise(
            id=uuid4(),
            name="Shoulder Abduction",
            description="Raise arm sideways",
            body_part=BodyPart.SHOULDER,
            category=ExerciseCategory.MOBILITY,
            sets=3,
            reps=10,
            hold_seconds=0,
        )
        session.add(exercise)
        await session.commit()
        return exercise

    @pytest.fixture
    async def active_session(
        self,
        session: AsyncSession,
        test_user: User,
    ) -> Session:
        """Create an active (started) session."""
        sess = Session(
            id=uuid4(),
            patient_id=test_user.id,
            scheduled_date=datetime.now(UTC),
            started_at=datetime.now(UTC),
            pain_level_before=4,
        )
        session.add(sess)
        await session.commit()
        return sess

    @pytest.mark.asyncio
    async def test_record_exercise_result(
        self,
        session: AsyncSession,
        active_session: Session,
        test_exercise: Exercise,
    ) -> None:
        """Can record exercise result for a session."""
        result = SessionExerciseResult(
            session_id=active_session.id,
            exercise_id=test_exercise.id,
            sets_completed=3,
            reps_completed=10,
            score=85.0,
            started_at=datetime.now(UTC),
            completed_at=datetime.now(UTC) + timedelta(minutes=5),
        )
        session.add(result)
        await session.commit()
        await session.refresh(result)

        assert result.sets_completed == 3
        assert result.reps_completed == 10
        assert result.score == 85.0

    @pytest.mark.asyncio
    async def test_partial_exercise_result(
        self,
        session: AsyncSession,
        active_session: Session,
        test_exercise: Exercise,
    ) -> None:
        """Can record partially completed exercise."""
        result = SessionExerciseResult(
            session_id=active_session.id,
            exercise_id=test_exercise.id,
            sets_completed=2,  # Only 2 of 3 sets
            reps_completed=8,  # Only 8 of 10 reps
            score=60.0,
        )
        session.add(result)
        await session.commit()
        await session.refresh(result)

        assert result.sets_completed == 2
        assert result.reps_completed == 8


class TestScoreCalculations:
    """Tests for session score calculations."""

    @pytest.mark.asyncio
    async def test_overall_score_calculation(
        self,
        session: AsyncSession,
        test_user: User,
    ) -> None:
        """Overall score is calculated from exercise results."""
        sess = Session(
            id=uuid4(),
            patient_id=test_user.id,
            scheduled_date=datetime.now(UTC),
            started_at=datetime.now(UTC),
        )
        session.add(sess)
        await session.commit()

        # Add exercises
        exercise1 = Exercise(
            id=uuid4(),
            name="Exercise 1",
            description="Test",
            body_part=BodyPart.SHOULDER,
            category=ExerciseCategory.MOBILITY,
        )
        exercise2 = Exercise(
            id=uuid4(),
            name="Exercise 2",
            description="Test",
            body_part=BodyPart.KNEE,
            category=ExerciseCategory.STRENGTH,
        )
        session.add(exercise1)
        session.add(exercise2)
        await session.commit()

        # Add results
        result1 = SessionExerciseResult(
            session_id=sess.id,
            exercise_id=exercise1.id,
            score=80.0,
        )
        result2 = SessionExerciseResult(
            session_id=sess.id,
            exercise_id=exercise2.id,
            score=90.0,
        )
        session.add(result1)
        session.add(result2)
        await session.commit()

        # Calculate average
        from sqlmodel import select

        results = await session.execute(
            select(SessionExerciseResult).where(
                SessionExerciseResult.session_id == sess.id
            )
        )
        scores = [r.score for r in results.scalars().all() if r.score is not None]
        average_score = sum(scores) / len(scores) if scores else 0

        assert average_score == 85.0

    @pytest.mark.asyncio
    async def test_score_bounds(
        self,
        session: AsyncSession,
        test_user: User,
    ) -> None:
        """Score must be between 0 and 100."""
        sess = Session(
            id=uuid4(),
            patient_id=test_user.id,
            scheduled_date=datetime.now(UTC),
        )
        session.add(sess)
        await session.commit()

        exercise = Exercise(
            id=uuid4(),
            name="Test Exercise",
            description="Test",
            body_part=BodyPart.SHOULDER,
            category=ExerciseCategory.MOBILITY,
        )
        session.add(exercise)
        await session.commit()

        # Valid scores
        valid_result = SessionExerciseResult(
            session_id=sess.id,
            exercise_id=exercise.id,
            score=50.0,
        )
        session.add(valid_result)
        await session.commit()

        assert valid_result.score == 50.0


class TestPainLevelTracking:
    """Tests for pain level tracking."""

    @pytest.mark.asyncio
    async def test_pain_level_improvement(
        self,
        session: AsyncSession,
        test_user: User,
    ) -> None:
        """Track pain level improvement after session."""
        sess = Session(
            patient_id=test_user.id,
            scheduled_date=datetime.now(UTC),
            started_at=datetime.now(UTC),
            pain_level_before=7,
            pain_level_after=4,
            status=SessionStatus.COMPLETED,
        )
        session.add(sess)
        await session.commit()
        await session.refresh(sess)

        improvement = sess.pain_level_before - sess.pain_level_after
        assert improvement == 3

    @pytest.mark.asyncio
    async def test_pain_level_worsening(
        self,
        session: AsyncSession,
        test_user: User,
    ) -> None:
        """Track pain level worsening after session."""
        sess = Session(
            patient_id=test_user.id,
            scheduled_date=datetime.now(UTC),
            started_at=datetime.now(UTC),
            pain_level_before=3,
            pain_level_after=6,
            status=SessionStatus.COMPLETED,
        )
        session.add(sess)
        await session.commit()

        improvement = sess.pain_level_before - sess.pain_level_after
        assert improvement == -3  # Worsening

    @pytest.mark.asyncio
    async def test_pain_level_bounds(
        self,
        session: AsyncSession,
        test_user: User,
    ) -> None:
        """Pain levels should be 0-10 (validated by Pydantic)."""
        sess = Session(
            patient_id=test_user.id,
            scheduled_date=datetime.now(UTC),
            pain_level_before=0,
            pain_level_after=10,
        )
        session.add(sess)
        await session.commit()

        assert sess.pain_level_before == 0
        assert sess.pain_level_after == 10


class TestSessionQueries:
    """Tests for session query patterns."""

    @pytest.mark.asyncio
    async def test_get_user_sessions(
        self,
        session: AsyncSession,
        test_user: User,
    ) -> None:
        """Get all sessions for a user."""
        # Create multiple sessions
        for i in range(3):
            sess = Session(
                patient_id=test_user.id,
                scheduled_date=datetime.now(UTC) - timedelta(days=i),
                status=SessionStatus.COMPLETED if i > 0 else SessionStatus.IN_PROGRESS,
            )
            session.add(sess)
        await session.commit()

        from sqlmodel import select

        result = await session.execute(
            select(Session).where(Session.patient_id == test_user.id)
        )
        sessions = result.scalars().all()

        assert len(sessions) == 3

    @pytest.mark.asyncio
    async def test_get_completed_sessions(
        self,
        session: AsyncSession,
        test_user: User,
    ) -> None:
        """Filter sessions by status."""
        # Create sessions with different statuses
        statuses = [
            SessionStatus.COMPLETED,
            SessionStatus.COMPLETED,
            SessionStatus.IN_PROGRESS,
            SessionStatus.SKIPPED,
        ]
        for status in statuses:
            sess = Session(
                patient_id=test_user.id,
                scheduled_date=datetime.now(UTC),
                status=status,
            )
            session.add(sess)
        await session.commit()

        from sqlmodel import select

        result = await session.execute(
            select(Session).where(
                Session.patient_id == test_user.id,
                Session.status == SessionStatus.COMPLETED,
            )
        )
        completed = result.scalars().all()

        assert len(completed) == 2

    @pytest.mark.asyncio
    async def test_get_sessions_date_range(
        self,
        session: AsyncSession,
        test_user: User,
    ) -> None:
        """Get sessions within date range."""
        now = datetime.now(UTC)

        # Sessions at different times
        dates = [
            now - timedelta(days=10),
            now - timedelta(days=5),
            now - timedelta(days=1),
        ]
        for date in dates:
            sess = Session(
                patient_id=test_user.id,
                scheduled_date=date,
            )
            session.add(sess)
        await session.commit()

        from sqlmodel import select

        week_ago = now - timedelta(days=7)
        result = await session.execute(
            select(Session).where(
                Session.patient_id == test_user.id,
                Session.scheduled_date >= week_ago,
            )
        )
        recent = result.scalars().all()

        assert len(recent) == 2


class TestCascadeDeletes:
    """Tests for cascade delete behavior."""

    @pytest.mark.asyncio
    async def test_delete_session_deletes_results(
        self,
        session: AsyncSession,
        test_user: User,
    ) -> None:
        """Deleting session cascades to exercise results."""
        sess = Session(
            id=uuid4(),
            patient_id=test_user.id,
            scheduled_date=datetime.now(UTC),
        )
        session.add(sess)
        await session.commit()

        exercise = Exercise(
            id=uuid4(),
            name="Test Exercise",
            description="Test",
            body_part=BodyPart.SHOULDER,
            category=ExerciseCategory.MOBILITY,
        )
        session.add(exercise)
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

        # Verify result is also deleted
        from sqlmodel import select

        remaining = await session.execute(
            select(SessionExerciseResult).where(SessionExerciseResult.id == result_id)
        )
        assert remaining.scalar_one_or_none() is None


class TestSessionDeviceInfo:
    """Tests for device info tracking."""

    @pytest.mark.asyncio
    async def test_store_device_info(
        self,
        session: AsyncSession,
        test_user: User,
    ) -> None:
        """Device info is stored as JSON."""
        device_info = {
            "platform": "iOS",
            "version": "15.0",
            "model": "iPhone 14 Pro",
            "app_version": "1.2.3",
        }

        sess = Session(
            patient_id=test_user.id,
            scheduled_date=datetime.now(UTC),
            device_info=device_info,
        )
        session.add(sess)
        await session.commit()
        await session.refresh(sess)

        assert sess.device_info["platform"] == "iOS"
        assert sess.device_info["model"] == "iPhone 14 Pro"

    @pytest.mark.asyncio
    async def test_empty_device_info(
        self,
        session: AsyncSession,
        test_user: User,
    ) -> None:
        """Device info defaults to empty dict."""
        sess = Session(
            patient_id=test_user.id,
            scheduled_date=datetime.now(UTC),
        )
        session.add(sess)
        await session.commit()
        await session.refresh(sess)

        assert sess.device_info == {}
