"""
Unit tests for Session models.

Test coverage:
1. Session model creation and defaults
2. SessionStatus enum
3. SessionCreate/Start/Complete schemas
4. SessionRead/ReadWithResults schemas
5. SessionExerciseResult model
6. SessionSummary schema
7. Field validation (pain levels, scores)
"""

from datetime import UTC, datetime
from uuid import uuid4

import pytest
from pydantic import ValidationError

from app.models.session import (
    Session,
    SessionBase,
    SessionComplete,
    SessionCreate,
    SessionExerciseResult,
    SessionExerciseResultCreate,
    SessionExerciseResultRead,
    SessionRead,
    SessionReadWithResults,
    SessionStart,
    SessionStatus,
    SessionSummary,
)


class TestSessionStatus:
    """Tests for SessionStatus enum."""

    def test_session_status_values(self) -> None:
        """SessionStatus has expected values."""
        assert SessionStatus.IN_PROGRESS.value == "in_progress"
        assert SessionStatus.COMPLETED.value == "completed"
        assert SessionStatus.ABANDONED.value == "abandoned"
        assert SessionStatus.SKIPPED.value == "skipped"

    def test_session_status_from_string(self) -> None:
        """SessionStatus can be created from string."""
        assert SessionStatus("in_progress") == SessionStatus.IN_PROGRESS
        assert SessionStatus("completed") == SessionStatus.COMPLETED
        assert SessionStatus("abandoned") == SessionStatus.ABANDONED
        assert SessionStatus("skipped") == SessionStatus.SKIPPED


class TestSessionModel:
    """Tests for Session SQLModel."""

    def test_session_creation_with_required_fields(self) -> None:
        """Session can be created with required fields."""
        patient_id = uuid4()
        scheduled_date = datetime.now(UTC).replace(tzinfo=None)

        session = Session(
            patient_id=patient_id,
            scheduled_date=scheduled_date,
        )

        assert session.patient_id == patient_id
        assert session.scheduled_date == scheduled_date
        assert session.status == SessionStatus.IN_PROGRESS
        assert session.notes == ""
        assert session.pain_level_before is None
        assert session.pain_level_after is None
        assert session.overall_score is None
        assert session.started_at is None
        assert session.completed_at is None
        assert session.duration_seconds is None
        assert session.device_info == {}

    def test_session_creation_with_all_fields(self) -> None:
        """Session can be created with all fields."""
        session_id = uuid4()
        patient_id = uuid4()
        now = datetime.now(UTC).replace(tzinfo=None)

        session = Session(
            id=session_id,
            patient_id=patient_id,
            scheduled_date=now,
            status=SessionStatus.COMPLETED,
            notes="Session completed successfully",
            pain_level_before=3,
            pain_level_after=2,
            overall_score=85.5,
            started_at=now,
            completed_at=now,
            duration_seconds=1800,
            device_info={"platform": "ios", "version": "1.0.0"},
        )

        assert session.id == session_id
        assert session.status == SessionStatus.COMPLETED
        assert session.pain_level_before == 3
        assert session.pain_level_after == 2
        assert session.overall_score == 85.5
        assert session.duration_seconds == 1800
        assert session.device_info["platform"] == "ios"

    def test_session_id_auto_generated(self) -> None:
        """Session ID is auto-generated if not provided."""
        session = Session(
            patient_id=uuid4(),
            scheduled_date=datetime.now(UTC).replace(tzinfo=None),
        )

        assert session.id is not None

    def test_session_created_at_auto_generated(self) -> None:
        """created_at is auto-generated."""
        session = Session(
            patient_id=uuid4(),
            scheduled_date=datetime.now(UTC).replace(tzinfo=None),
        )

        assert session.created_at is not None


class TestSessionBaseSchema:
    """Tests for SessionBase schema validation."""

    def test_session_base_pain_level_minimum(self) -> None:
        """pain_level_before/after must be at least 0."""
        with pytest.raises(ValidationError) as exc_info:
            SessionBase(
                scheduled_date=datetime.now(UTC),
                pain_level_before=-1,
            )

        assert "pain_level_before" in str(exc_info.value)

    def test_session_base_pain_level_maximum(self) -> None:
        """pain_level_before/after cannot exceed 10."""
        with pytest.raises(ValidationError) as exc_info:
            SessionBase(
                scheduled_date=datetime.now(UTC),
                pain_level_after=11,
            )

        assert "pain_level_after" in str(exc_info.value)

    def test_session_base_overall_score_minimum(self) -> None:
        """overall_score must be at least 0."""
        with pytest.raises(ValidationError) as exc_info:
            SessionBase(
                scheduled_date=datetime.now(UTC),
                overall_score=-1,
            )

        assert "overall_score" in str(exc_info.value)

    def test_session_base_overall_score_maximum(self) -> None:
        """overall_score cannot exceed 100."""
        with pytest.raises(ValidationError) as exc_info:
            SessionBase(
                scheduled_date=datetime.now(UTC),
                overall_score=101,
            )

        assert "overall_score" in str(exc_info.value)

    def test_session_base_valid_edge_values(self) -> None:
        """Edge values are valid."""
        data = SessionBase(
            scheduled_date=datetime.now(UTC),
            pain_level_before=0,
            pain_level_after=10,
            overall_score=0,
        )

        assert data.pain_level_before == 0
        assert data.pain_level_after == 10
        assert data.overall_score == 0

        data_max = SessionBase(
            scheduled_date=datetime.now(UTC),
            overall_score=100,
        )

        assert data_max.overall_score == 100


class TestSessionCreateSchema:
    """Tests for SessionCreate schema."""

    def test_session_create_minimal(self) -> None:
        """SessionCreate with minimal fields."""
        now = datetime.now(UTC)
        data = SessionCreate(scheduled_date=now)

        assert data.scheduled_date == now
        assert data.notes == ""

    def test_session_create_with_notes(self) -> None:
        """SessionCreate with notes."""
        data = SessionCreate(
            scheduled_date=datetime.now(UTC),
            notes="Pre-surgery assessment",
        )

        assert data.notes == "Pre-surgery assessment"


class TestSessionStartSchema:
    """Tests for SessionStart schema."""

    def test_session_start_minimal(self) -> None:
        """SessionStart with minimal fields."""
        data = SessionStart()

        assert data.pain_level_before is None
        assert data.device_info == {}

    def test_session_start_with_all_fields(self) -> None:
        """SessionStart with all fields."""
        data = SessionStart(
            pain_level_before=5,
            device_info={"os": "android", "model": "Pixel 8"},
        )

        assert data.pain_level_before == 5
        assert data.device_info["os"] == "android"

    def test_session_start_pain_level_validation(self) -> None:
        """SessionStart validates pain_level_before."""
        with pytest.raises(ValidationError):
            SessionStart(pain_level_before=11)


class TestSessionCompleteSchema:
    """Tests for SessionComplete schema."""

    def test_session_complete_minimal(self) -> None:
        """SessionComplete with minimal fields."""
        data = SessionComplete()

        assert data.pain_level_after is None
        assert data.notes == ""

    def test_session_complete_with_all_fields(self) -> None:
        """SessionComplete with all fields."""
        data = SessionComplete(
            pain_level_after=2,
            notes="Good session, patient progressing well",
        )

        assert data.pain_level_after == 2
        assert "progressing" in data.notes


class TestSessionReadSchema:
    """Tests for SessionRead schema."""

    def test_session_read_serialization(self) -> None:
        """SessionRead serializes all fields."""
        session_id = uuid4()
        patient_id = uuid4()
        now = datetime.now(UTC)

        data = SessionRead(
            id=session_id,
            patient_id=patient_id,
            scheduled_date=now,
            status=SessionStatus.COMPLETED,
            notes="Test notes",
            pain_level_before=3,
            pain_level_after=2,
            overall_score=90.0,
            started_at=now,
            completed_at=now,
            duration_seconds=1200,
            created_at=now,
        )

        assert data.id == session_id
        assert data.status == SessionStatus.COMPLETED
        assert data.overall_score == 90.0


class TestSessionExerciseResultModel:
    """Tests for SessionExerciseResult model."""

    def test_exercise_result_creation_with_defaults(self) -> None:
        """SessionExerciseResult can be created with minimal fields."""
        session_id = uuid4()
        exercise_id = uuid4()

        result = SessionExerciseResult(
            session_id=session_id,
            exercise_id=exercise_id,
        )

        assert result.session_id == session_id
        assert result.exercise_id == exercise_id
        assert result.sets_completed == 0
        assert result.reps_completed == 0
        assert result.hold_seconds_achieved is None
        assert result.score is None
        assert result.started_at is None
        assert result.completed_at is None

    def test_exercise_result_creation_with_all_fields(self) -> None:
        """SessionExerciseResult can be created with all fields."""
        result_id = uuid4()
        session_id = uuid4()
        exercise_id = uuid4()
        now = datetime.now(UTC).replace(tzinfo=None)

        result = SessionExerciseResult(
            id=result_id,
            session_id=session_id,
            exercise_id=exercise_id,
            sets_completed=3,
            reps_completed=12,
            hold_seconds_achieved=30,
            score=95.5,
            started_at=now,
            completed_at=now,
        )

        assert result.id == result_id
        assert result.sets_completed == 3
        assert result.reps_completed == 12
        assert result.hold_seconds_achieved == 30
        assert result.score == 95.5


class TestSessionExerciseResultSchemas:
    """Tests for SessionExerciseResult schemas."""

    def test_exercise_result_create_valid(self) -> None:
        """SessionExerciseResultCreate with valid data."""
        data = SessionExerciseResultCreate(
            exercise_id=uuid4(),
            sets_completed=3,
            reps_completed=10,
            hold_seconds_achieved=15,
            score=88.0,
        )

        assert data.sets_completed == 3
        assert data.reps_completed == 10
        assert data.score == 88.0

    def test_exercise_result_create_defaults(self) -> None:
        """SessionExerciseResultCreate applies defaults."""
        data = SessionExerciseResultCreate(exercise_id=uuid4())

        assert data.sets_completed == 0
        assert data.reps_completed == 0
        assert data.hold_seconds_achieved is None
        assert data.score is None

    def test_exercise_result_create_score_validation(self) -> None:
        """SessionExerciseResultCreate validates score range."""
        # Score below 0
        with pytest.raises(ValidationError):
            SessionExerciseResultCreate(
                exercise_id=uuid4(),
                score=-1,
            )

        # Score above 100
        with pytest.raises(ValidationError):
            SessionExerciseResultCreate(
                exercise_id=uuid4(),
                score=101,
            )

    def test_exercise_result_read_serialization(self) -> None:
        """SessionExerciseResultRead serializes correctly."""
        result_id = uuid4()
        session_id = uuid4()
        exercise_id = uuid4()
        now = datetime.now(UTC)

        data = SessionExerciseResultRead(
            id=result_id,
            session_id=session_id,
            exercise_id=exercise_id,
            sets_completed=4,
            reps_completed=15,
            hold_seconds_achieved=20,
            score=92.0,
            started_at=now,
            completed_at=now,
        )

        assert data.id == result_id
        assert data.sets_completed == 4
        assert data.score == 92.0


class TestSessionSummarySchema:
    """Tests for SessionSummary schema."""

    def test_session_summary_creation(self) -> None:
        """SessionSummary can be created with all fields."""
        session_id = uuid4()
        patient_id = uuid4()
        now = datetime.now(UTC)

        summary = SessionSummary(
            session_id=session_id,
            patient_id=patient_id,
            patient_name="John Doe",
            scheduled_date=now,
            status=SessionStatus.COMPLETED,
            overall_score=87.5,
            exercises_completed=8,
            total_exercises=10,
            duration_seconds=2400,
        )

        assert summary.session_id == session_id
        assert summary.patient_name == "John Doe"
        assert summary.status == SessionStatus.COMPLETED
        assert summary.overall_score == 87.5
        assert summary.exercises_completed == 8
        assert summary.total_exercises == 10
        assert summary.duration_seconds == 2400

    def test_session_summary_optional_fields(self) -> None:
        """SessionSummary handles optional fields."""
        summary = SessionSummary(
            session_id=uuid4(),
            patient_id=uuid4(),
            patient_name="Jane Doe",
            scheduled_date=datetime.now(UTC),
            status=SessionStatus.IN_PROGRESS,
            overall_score=None,
            exercises_completed=0,
            total_exercises=5,
            duration_seconds=None,
        )

        assert summary.overall_score is None
        assert summary.duration_seconds is None
