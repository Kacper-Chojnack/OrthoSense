"""
Unit tests for Protocol models.

Test coverage:
1. Protocol model creation and defaults
2. ProtocolBase schema validation
3. ProtocolExercise association model
4. Field constraints (duration_weeks, sets, reps, etc.)
5. Timestamp auto-generation
"""

from datetime import UTC, datetime
from uuid import uuid4

import pytest
from pydantic import ValidationError

from app.models.protocol import (
    Protocol,
    ProtocolBase,
    ProtocolExercise,
    ProtocolExerciseBase,
)


class TestProtocolModel:
    """Tests for Protocol SQLModel."""

    def test_protocol_creation_with_defaults(self) -> None:
        """Protocol can be created with minimal fields."""
        protocol = Protocol(name="Knee Rehabilitation")

        assert protocol.name == "Knee Rehabilitation"
        assert protocol.description == ""
        assert protocol.duration_weeks == 4
        assert protocol.is_active is True
        assert protocol.id is not None

    def test_protocol_creation_with_all_fields(self) -> None:
        """Protocol can be created with all fields."""
        protocol_id = uuid4()
        now = datetime.now(UTC).replace(tzinfo=None)

        protocol = Protocol(
            id=protocol_id,
            name="ACL Recovery Protocol",
            description="12-week ACL rehabilitation program",
            duration_weeks=12,
            is_active=True,
            created_at=now,
        )

        assert protocol.id == protocol_id
        assert protocol.name == "ACL Recovery Protocol"
        assert protocol.description == "12-week ACL rehabilitation program"
        assert protocol.duration_weeks == 12
        assert protocol.is_active is True
        assert protocol.created_at == now

    def test_protocol_id_auto_generated(self) -> None:
        """Protocol ID is auto-generated if not provided."""
        protocol = Protocol(name="Test Protocol")

        assert protocol.id is not None

    def test_protocol_created_at_auto_generated(self) -> None:
        """created_at is auto-generated."""
        protocol = Protocol(name="Test Protocol")

        assert protocol.created_at is not None
        # Should be close to now
        now = datetime.now(UTC).replace(tzinfo=None)
        diff = abs((now - protocol.created_at).total_seconds())
        assert diff < 2  # Within 2 seconds

    def test_protocol_updated_at_initially_none(self) -> None:
        """updated_at is None by default."""
        protocol = Protocol(name="Test Protocol")

        assert protocol.updated_at is None


class TestProtocolBaseSchema:
    """Tests for ProtocolBase Pydantic schema."""

    def test_protocol_base_valid(self) -> None:
        """Valid ProtocolBase schema."""
        data = ProtocolBase(
            name="Hip Mobility Program",
            description="Comprehensive hip rehabilitation",
            duration_weeks=8,
            is_active=True,
        )

        assert data.name == "Hip Mobility Program"
        assert data.duration_weeks == 8

    def test_protocol_base_defaults(self) -> None:
        """ProtocolBase applies default values."""
        data = ProtocolBase(name="Minimal Protocol")

        assert data.name == "Minimal Protocol"
        assert data.description == ""
        assert data.duration_weeks == 4
        assert data.is_active is True

    def test_protocol_base_duration_minimum(self) -> None:
        """duration_weeks must be at least 1."""
        with pytest.raises(ValidationError) as exc_info:
            ProtocolBase(name="Invalid", duration_weeks=0)

        assert "duration_weeks" in str(exc_info.value)

    def test_protocol_base_duration_maximum(self) -> None:
        """duration_weeks cannot exceed 52."""
        with pytest.raises(ValidationError) as exc_info:
            ProtocolBase(name="Invalid", duration_weeks=53)

        assert "duration_weeks" in str(exc_info.value)

    def test_protocol_base_valid_edge_durations(self) -> None:
        """Edge values for duration_weeks are valid."""
        min_duration = ProtocolBase(name="Short", duration_weeks=1)
        max_duration = ProtocolBase(name="Long", duration_weeks=52)

        assert min_duration.duration_weeks == 1
        assert max_duration.duration_weeks == 52

    def test_protocol_base_name_max_length(self) -> None:
        """Name has maximum length of 255 characters."""
        # Valid: exactly 255 characters
        long_name = "A" * 255
        data = ProtocolBase(name=long_name)
        assert len(data.name) == 255

        # Invalid: 256 characters
        with pytest.raises(ValidationError):
            ProtocolBase(name="A" * 256)


class TestProtocolExerciseModel:
    """Tests for ProtocolExercise association model."""

    def test_protocol_exercise_creation_with_defaults(self) -> None:
        """ProtocolExercise can be created with minimal fields."""
        protocol_id = uuid4()
        exercise_id = uuid4()

        pe = ProtocolExercise(
            protocol_id=protocol_id,
            exercise_id=exercise_id,
        )

        assert pe.protocol_id == protocol_id
        assert pe.exercise_id == exercise_id
        assert pe.order == 0
        assert pe.sets == 3
        assert pe.reps == 10
        assert pe.hold_seconds == 0
        assert pe.rest_seconds == 30

    def test_protocol_exercise_creation_with_all_fields(self) -> None:
        """ProtocolExercise can be created with all fields."""
        pe_id = uuid4()
        protocol_id = uuid4()
        exercise_id = uuid4()

        pe = ProtocolExercise(
            id=pe_id,
            protocol_id=protocol_id,
            exercise_id=exercise_id,
            order=5,
            sets=4,
            reps=15,
            hold_seconds=30,
            rest_seconds=60,
        )

        assert pe.id == pe_id
        assert pe.order == 5
        assert pe.sets == 4
        assert pe.reps == 15
        assert pe.hold_seconds == 30
        assert pe.rest_seconds == 60


class TestProtocolExerciseBaseSchema:
    """Tests for ProtocolExerciseBase schema validation."""

    def test_protocol_exercise_base_valid(self) -> None:
        """Valid ProtocolExerciseBase schema."""
        data = ProtocolExerciseBase(
            protocol_id=uuid4(),
            exercise_id=uuid4(),
            order=1,
            sets=3,
            reps=12,
            hold_seconds=15,
            rest_seconds=45,
        )

        assert data.sets == 3
        assert data.reps == 12

    def test_sets_minimum(self) -> None:
        """sets must be at least 1."""
        with pytest.raises(ValidationError) as exc_info:
            ProtocolExerciseBase(
                protocol_id=uuid4(),
                exercise_id=uuid4(),
                sets=0,
            )

        assert "sets" in str(exc_info.value)

    def test_sets_maximum(self) -> None:
        """sets cannot exceed 10."""
        with pytest.raises(ValidationError) as exc_info:
            ProtocolExerciseBase(
                protocol_id=uuid4(),
                exercise_id=uuid4(),
                sets=11,
            )

        assert "sets" in str(exc_info.value)

    def test_reps_minimum(self) -> None:
        """reps must be at least 1."""
        with pytest.raises(ValidationError) as exc_info:
            ProtocolExerciseBase(
                protocol_id=uuid4(),
                exercise_id=uuid4(),
                reps=0,
            )

        assert "reps" in str(exc_info.value)

    def test_reps_maximum(self) -> None:
        """reps cannot exceed 100."""
        with pytest.raises(ValidationError) as exc_info:
            ProtocolExerciseBase(
                protocol_id=uuid4(),
                exercise_id=uuid4(),
                reps=101,
            )

        assert "reps" in str(exc_info.value)

    def test_hold_seconds_minimum(self) -> None:
        """hold_seconds must be at least 0."""
        with pytest.raises(ValidationError) as exc_info:
            ProtocolExerciseBase(
                protocol_id=uuid4(),
                exercise_id=uuid4(),
                hold_seconds=-1,
            )

        assert "hold_seconds" in str(exc_info.value)

    def test_hold_seconds_maximum(self) -> None:
        """hold_seconds cannot exceed 120."""
        with pytest.raises(ValidationError) as exc_info:
            ProtocolExerciseBase(
                protocol_id=uuid4(),
                exercise_id=uuid4(),
                hold_seconds=121,
            )

        assert "hold_seconds" in str(exc_info.value)

    def test_rest_seconds_minimum(self) -> None:
        """rest_seconds must be at least 0."""
        with pytest.raises(ValidationError) as exc_info:
            ProtocolExerciseBase(
                protocol_id=uuid4(),
                exercise_id=uuid4(),
                rest_seconds=-1,
            )

        assert "rest_seconds" in str(exc_info.value)

    def test_rest_seconds_maximum(self) -> None:
        """rest_seconds cannot exceed 300."""
        with pytest.raises(ValidationError) as exc_info:
            ProtocolExerciseBase(
                protocol_id=uuid4(),
                exercise_id=uuid4(),
                rest_seconds=301,
            )

        assert "rest_seconds" in str(exc_info.value)

    def test_order_minimum(self) -> None:
        """order must be at least 0."""
        with pytest.raises(ValidationError) as exc_info:
            ProtocolExerciseBase(
                protocol_id=uuid4(),
                exercise_id=uuid4(),
                order=-1,
            )

        assert "order" in str(exc_info.value)

    def test_valid_edge_values(self) -> None:
        """Edge values for all fields are valid."""
        data = ProtocolExerciseBase(
            protocol_id=uuid4(),
            exercise_id=uuid4(),
            order=0,
            sets=1,
            reps=1,
            hold_seconds=0,
            rest_seconds=0,
        )

        assert data.sets == 1
        assert data.reps == 1
        assert data.hold_seconds == 0
        assert data.rest_seconds == 0

        data_max = ProtocolExerciseBase(
            protocol_id=uuid4(),
            exercise_id=uuid4(),
            sets=10,
            reps=100,
            hold_seconds=120,
            rest_seconds=300,
        )

        assert data_max.sets == 10
        assert data_max.reps == 100
        assert data_max.hold_seconds == 120
        assert data_max.rest_seconds == 300
