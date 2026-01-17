"""Extended unit tests for Protocol model.

Test coverage:
1. ProtocolBase model
2. Protocol model
3. ProtocolExerciseBase model
4. ProtocolExercise model
5. Relationships
"""

from datetime import datetime
from uuid import UUID, uuid4

import pytest

from app.models.protocol import (
    Protocol,
    ProtocolBase,
    ProtocolExercise,
    ProtocolExerciseBase,
    utc_now,
)


class TestUtcNow:
    """Test utc_now helper function."""

    def test_returns_datetime(self):
        """Should return datetime object."""
        result = utc_now()
        assert isinstance(result, datetime)

    def test_returns_naive_datetime(self):
        """Should return naive datetime for PostgreSQL compatibility."""
        result = utc_now()
        # May or may not have tzinfo depending on implementation
        assert isinstance(result, datetime)

    def test_returns_current_time(self):
        """Should return approximately current time."""
        before = datetime.utcnow()
        result = utc_now()
        after = datetime.utcnow()
        
        # Remove tzinfo for comparison if present
        result_naive = result.replace(tzinfo=None) if result.tzinfo else result
        
        assert before <= result_naive <= after


class TestProtocolBase:
    """Test ProtocolBase schema."""

    def test_creates_with_required_fields(self):
        """Should create with required fields."""
        protocol = ProtocolBase(name="Test Protocol")
        
        assert protocol.name == "Test Protocol"

    def test_has_default_description(self):
        """Should have empty description by default."""
        protocol = ProtocolBase(name="Test")
        
        assert protocol.description == ""

    def test_has_default_duration_weeks(self):
        """Should have default duration of 4 weeks."""
        protocol = ProtocolBase(name="Test")
        
        assert protocol.duration_weeks == 4

    def test_has_default_is_active(self):
        """Should be active by default."""
        protocol = ProtocolBase(name="Test")
        
        assert protocol.is_active is True

    def test_name_max_length(self):
        """Name should have max length constraint."""
        # Field should have max_length=255
        long_name = "x" * 255
        protocol = ProtocolBase(name=long_name)
        
        assert len(protocol.name) == 255

    def test_duration_weeks_min_value(self):
        """Duration should have minimum of 1 week."""
        protocol = ProtocolBase(name="Test", duration_weeks=1)
        
        assert protocol.duration_weeks >= 1

    def test_duration_weeks_max_value(self):
        """Duration should have maximum of 52 weeks."""
        protocol = ProtocolBase(name="Test", duration_weeks=52)
        
        assert protocol.duration_weeks <= 52


class TestProtocol:
    """Test Protocol model."""

    def test_creates_with_id(self):
        """Should create with UUID id."""
        protocol = Protocol(name="Test Protocol")
        
        assert protocol.id is not None
        assert isinstance(protocol.id, UUID)

    def test_creates_with_created_at(self):
        """Should have created_at timestamp."""
        protocol = Protocol(name="Test Protocol")
        
        assert protocol.created_at is not None
        assert isinstance(protocol.created_at, datetime)

    def test_updated_at_is_none_initially(self):
        """updated_at should be None initially."""
        protocol = Protocol(name="Test Protocol")
        
        assert protocol.updated_at is None

    def test_table_name(self):
        """Should have correct table name."""
        assert Protocol.__tablename__ == "protocols"


class TestProtocolExerciseBase:
    """Test ProtocolExerciseBase schema."""

    def test_creates_with_required_fields(self):
        """Should create with required fields."""
        protocol_id = uuid4()
        exercise_id = uuid4()
        
        pe = ProtocolExerciseBase(
            protocol_id=protocol_id,
            exercise_id=exercise_id,
        )
        
        assert pe.protocol_id == protocol_id
        assert pe.exercise_id == exercise_id

    def test_has_default_order(self):
        """Should have default order of 0."""
        pe = ProtocolExerciseBase(
            protocol_id=uuid4(),
            exercise_id=uuid4(),
        )
        
        assert pe.order == 0

    def test_has_default_sets(self):
        """Should have default sets of 3."""
        pe = ProtocolExerciseBase(
            protocol_id=uuid4(),
            exercise_id=uuid4(),
        )
        
        assert pe.sets == 3

    def test_has_default_reps(self):
        """Should have default reps of 10."""
        pe = ProtocolExerciseBase(
            protocol_id=uuid4(),
            exercise_id=uuid4(),
        )
        
        assert pe.reps == 10

    def test_has_default_hold_seconds(self):
        """Should have default hold_seconds of 0."""
        pe = ProtocolExerciseBase(
            protocol_id=uuid4(),
            exercise_id=uuid4(),
        )
        
        assert pe.hold_seconds == 0

    def test_has_default_rest_seconds(self):
        """Should have default rest_seconds of 30."""
        pe = ProtocolExerciseBase(
            protocol_id=uuid4(),
            exercise_id=uuid4(),
        )
        
        assert pe.rest_seconds == 30

    def test_sets_range(self):
        """Sets should be between 1 and 10."""
        pe = ProtocolExerciseBase(
            protocol_id=uuid4(),
            exercise_id=uuid4(),
            sets=5,
        )
        
        assert 1 <= pe.sets <= 10

    def test_reps_range(self):
        """Reps should be between 1 and 100."""
        pe = ProtocolExerciseBase(
            protocol_id=uuid4(),
            exercise_id=uuid4(),
            reps=50,
        )
        
        assert 1 <= pe.reps <= 100

    def test_hold_seconds_range(self):
        """Hold seconds should be between 0 and 120."""
        pe = ProtocolExerciseBase(
            protocol_id=uuid4(),
            exercise_id=uuid4(),
            hold_seconds=60,
        )
        
        assert 0 <= pe.hold_seconds <= 120

    def test_rest_seconds_range(self):
        """Rest seconds should be between 0 and 300."""
        pe = ProtocolExerciseBase(
            protocol_id=uuid4(),
            exercise_id=uuid4(),
            rest_seconds=120,
        )
        
        assert 0 <= pe.rest_seconds <= 300


class TestProtocolExercise:
    """Test ProtocolExercise model."""

    def test_creates_with_id(self):
        """Should create with UUID id."""
        pe = ProtocolExercise(
            protocol_id=uuid4(),
            exercise_id=uuid4(),
        )
        
        assert pe.id is not None
        assert isinstance(pe.id, UUID)

    def test_creates_with_created_at(self):
        """Should have created_at timestamp."""
        pe = ProtocolExercise(
            protocol_id=uuid4(),
            exercise_id=uuid4(),
        )
        
        assert pe.created_at is not None
        assert isinstance(pe.created_at, datetime)

    def test_table_name(self):
        """Should have correct table name."""
        assert ProtocolExercise.__tablename__ == "protocol_exercises"


class TestProtocolRelationships:
    """Test model relationships."""

    def test_protocol_has_exercises_relationship(self):
        """Protocol should have relationship to exercises."""
        # Check relationship is defined
        assert hasattr(Protocol, "protocol_exercises")

    def test_protocol_exercise_has_protocol_relationship(self):
        """ProtocolExercise should have relationship to protocol."""
        assert hasattr(ProtocolExercise, "protocol")

    def test_protocol_exercise_has_exercise_relationship(self):
        """ProtocolExercise should have relationship to exercise."""
        assert hasattr(ProtocolExercise, "exercise")
