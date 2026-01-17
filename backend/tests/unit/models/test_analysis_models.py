"""
Comprehensive unit tests for Pydantic analysis models.

Test coverage:
1. Model validation
2. Default values
3. Field constraints
4. Serialization
"""

from datetime import datetime

import pytest
from pydantic import ValidationError

from app.models.analysis import (
    AnalysisError,
    AnalysisResult,
    AnalysisStatus,
    LandmarksAnalysisRequest,
    TaskStatusResponse,
    VideoAnalysisResponse,
)


class TestAnalysisStatus:
    """Tests for AnalysisStatus enum."""

    def test_pending_status_value(self) -> None:
        """Pending status has correct value."""
        assert AnalysisStatus.PENDING.value == "pending"

    def test_processing_status_value(self) -> None:
        """Processing status has correct value."""
        assert AnalysisStatus.PROCESSING.value == "processing"

    def test_completed_status_value(self) -> None:
        """Completed status has correct value."""
        assert AnalysisStatus.COMPLETED.value == "completed"

    def test_failed_status_value(self) -> None:
        """Failed status has correct value."""
        assert AnalysisStatus.FAILED.value == "failed"

    def test_status_is_string_enum(self) -> None:
        """Status is a string enum."""
        assert isinstance(AnalysisStatus.PENDING, str)
        assert isinstance(AnalysisStatus.PENDING, AnalysisStatus)


class TestLandmarksAnalysisRequest:
    """Tests for LandmarksAnalysisRequest model."""

    def test_valid_request_creation(self) -> None:
        """Valid request is created successfully."""
        landmarks = [
            [[0.5, 0.5, 0.0] for _ in range(33)]
            for _ in range(30)
        ]
        request = LandmarksAnalysisRequest(
            landmarks=landmarks,
            exercise_name="Deep Squat",
        )
        
        assert request.exercise_name == "Deep Squat"
        assert len(request.landmarks) == 30

    def test_default_fps_value(self) -> None:
        """Default FPS is 30.0."""
        landmarks = [[[0.5, 0.5, 0.0] for _ in range(33)]]
        request = LandmarksAnalysisRequest(
            landmarks=landmarks,
            exercise_name="Test",
        )
        
        assert request.fps == 30.0

    def test_custom_fps_value(self) -> None:
        """Custom FPS value is accepted."""
        landmarks = [[[0.5, 0.5, 0.0] for _ in range(33)]]
        request = LandmarksAnalysisRequest(
            landmarks=landmarks,
            exercise_name="Test",
            fps=60.0,
        )
        
        assert request.fps == 60.0

    def test_fps_minimum_constraint(self) -> None:
        """FPS must be at least 1.0."""
        landmarks = [[[0.5, 0.5, 0.0] for _ in range(33)]]
        
        with pytest.raises(ValidationError):
            LandmarksAnalysisRequest(
                landmarks=landmarks,
                exercise_name="Test",
                fps=0.5,
            )

    def test_fps_maximum_constraint(self) -> None:
        """FPS must be at most 120.0."""
        landmarks = [[[0.5, 0.5, 0.0] for _ in range(33)]]
        
        with pytest.raises(ValidationError):
            LandmarksAnalysisRequest(
                landmarks=landmarks,
                exercise_name="Test",
                fps=121.0,
            )

    def test_landmarks_with_visibility(self) -> None:
        """Landmarks with visibility scores are accepted."""
        landmarks = [
            [[0.5, 0.5, 0.0, 0.9] for _ in range(33)]
            for _ in range(30)
        ]
        request = LandmarksAnalysisRequest(
            landmarks=landmarks,
            exercise_name="Test",
        )
        
        assert len(request.landmarks[0][0]) == 4


class TestVideoAnalysisResponse:
    """Tests for VideoAnalysisResponse model."""

    def test_valid_response_creation(self) -> None:
        """Valid response is created successfully."""
        response = VideoAnalysisResponse(
            task_id="task-123",
            session_id="session-456",
            status=AnalysisStatus.PENDING,
            message="Analysis started",
        )
        
        assert response.task_id == "task-123"
        assert response.session_id == "session-456"
        assert response.status == AnalysisStatus.PENDING
        assert response.message == "Analysis started"

    def test_created_at_default_value(self) -> None:
        """Created at defaults to current time."""
        before = datetime.utcnow()
        
        response = VideoAnalysisResponse(
            task_id="task-123",
            session_id="session-456",
            status=AnalysisStatus.PENDING,
            message="Analysis started",
        )
        
        after = datetime.utcnow()
        
        assert before <= response.created_at <= after


class TestAnalysisResult:
    """Tests for AnalysisResult model."""

    def test_valid_result_creation(self) -> None:
        """Valid result is created successfully."""
        result = AnalysisResult(
            session_id="session-123",
            status=AnalysisStatus.COMPLETED,
            exercise="Deep Squat",
            confidence=0.95,
            is_correct=True,
        )
        
        assert result.session_id == "session-123"
        assert result.exercise == "Deep Squat"
        assert result.confidence == 0.95
        assert result.is_correct is True

    def test_confidence_minimum_constraint(self) -> None:
        """Confidence must be at least 0.0."""
        with pytest.raises(ValidationError):
            AnalysisResult(
                session_id="session-123",
                status=AnalysisStatus.COMPLETED,
                exercise="Deep Squat",
                confidence=-0.1,
                is_correct=True,
            )

    def test_confidence_maximum_constraint(self) -> None:
        """Confidence must be at most 1.0."""
        with pytest.raises(ValidationError):
            AnalysisResult(
                session_id="session-123",
                status=AnalysisStatus.COMPLETED,
                exercise="Deep Squat",
                confidence=1.1,
                is_correct=True,
            )

    def test_feedback_default_value(self) -> None:
        """Feedback defaults to empty dict."""
        result = AnalysisResult(
            session_id="session-123",
            status=AnalysisStatus.COMPLETED,
            exercise="Deep Squat",
            confidence=0.95,
            is_correct=True,
        )
        
        assert result.feedback == {}

    def test_feedback_with_custom_value(self) -> None:
        """Custom feedback is accepted."""
        feedback = {
            "knee_valgus": "Knees caving inward",
            "depth": True,
        }
        result = AnalysisResult(
            session_id="session-123",
            status=AnalysisStatus.COMPLETED,
            exercise="Deep Squat",
            confidence=0.95,
            is_correct=False,
            feedback=feedback,
        )
        
        assert result.feedback == feedback

    def test_text_report_default_none(self) -> None:
        """Text report defaults to None."""
        result = AnalysisResult(
            session_id="session-123",
            status=AnalysisStatus.COMPLETED,
            exercise="Deep Squat",
            confidence=0.95,
            is_correct=True,
        )
        
        assert result.text_report is None

    def test_metrics_default_value(self) -> None:
        """Metrics defaults to empty dict."""
        result = AnalysisResult(
            session_id="session-123",
            status=AnalysisStatus.COMPLETED,
            exercise="Deep Squat",
            confidence=0.95,
            is_correct=True,
        )
        
        assert result.metrics == {}

    def test_completed_at_optional(self) -> None:
        """Completed at is optional."""
        result = AnalysisResult(
            session_id="session-123",
            status=AnalysisStatus.PROCESSING,
            exercise="Deep Squat",
            confidence=0.0,
            is_correct=False,
        )
        
        assert result.completed_at is None

    def test_completed_at_with_value(self) -> None:
        """Completed at can be set."""
        completed = datetime.utcnow()
        result = AnalysisResult(
            session_id="session-123",
            status=AnalysisStatus.COMPLETED,
            exercise="Deep Squat",
            confidence=0.95,
            is_correct=True,
            completed_at=completed,
        )
        
        assert result.completed_at == completed


class TestAnalysisError:
    """Tests for AnalysisError model."""

    def test_valid_error_creation(self) -> None:
        """Valid error is created successfully."""
        error = AnalysisError(
            error="validation_error",
            detail="Invalid landmark format",
        )
        
        assert error.error == "validation_error"
        assert error.detail == "Invalid landmark format"

    def test_session_id_optional(self) -> None:
        """Session ID is optional."""
        error = AnalysisError(
            error="server_error",
            detail="Internal error",
        )
        
        assert error.session_id is None

    def test_session_id_with_value(self) -> None:
        """Session ID can be set."""
        error = AnalysisError(
            error="analysis_failed",
            detail="Failed to process video",
            session_id="session-789",
        )
        
        assert error.session_id == "session-789"


class TestTaskStatusResponse:
    """Tests for TaskStatusResponse model."""

    def test_valid_status_response_creation(self) -> None:
        """Valid status response is created successfully."""
        status = TaskStatusResponse(
            task_id="task-123",
            session_id="session-456",
            status=AnalysisStatus.PROCESSING,
        )
        
        assert status.task_id == "task-123"
        assert status.session_id == "session-456"
        assert status.status == AnalysisStatus.PROCESSING

    def test_required_fields(self) -> None:
        """Task ID, session ID and status are required."""
        with pytest.raises(ValidationError):
            TaskStatusResponse(task_id="task-123", status=AnalysisStatus.PENDING)
        
        with pytest.raises(ValidationError):
            TaskStatusResponse(session_id="session-456", status=AnalysisStatus.PENDING)
        
        with pytest.raises(ValidationError):
            TaskStatusResponse(task_id="task-123", session_id="session-456")

    def test_optional_fields_default_none(self) -> None:
        """Optional fields default to None."""
        status = TaskStatusResponse(
            task_id="task-123",
            session_id="session-456",
            status=AnalysisStatus.PENDING,
        )
        
        assert status.progress is None
        assert status.message is None
        assert status.result is None

    def test_progress_constraints(self) -> None:
        """Progress must be between 0 and 100."""
        # Valid progress
        status = TaskStatusResponse(
            task_id="task-123",
            session_id="session-456",
            status=AnalysisStatus.PROCESSING,
            progress=50.0,
        )
        assert status.progress == 50.0
        
        # Invalid progress (negative)
        with pytest.raises(ValidationError):
            TaskStatusResponse(
                task_id="task-123",
                session_id="session-456",
                status=AnalysisStatus.PROCESSING,
                progress=-1.0,
            )
        
        # Invalid progress (over 100)
        with pytest.raises(ValidationError):
            TaskStatusResponse(
                task_id="task-123",
                session_id="session-456",
                status=AnalysisStatus.PROCESSING,
                progress=101.0,
            )


class TestModelSerialization:
    """Tests for model serialization."""

    def test_analysis_result_to_dict(self) -> None:
        """Analysis result serializes to dict."""
        result = AnalysisResult(
            session_id="session-123",
            status=AnalysisStatus.COMPLETED,
            exercise="Deep Squat",
            confidence=0.95,
            is_correct=True,
        )
        
        data = result.model_dump()
        
        assert isinstance(data, dict)
        assert data["session_id"] == "session-123"
        assert data["exercise"] == "Deep Squat"

    def test_analysis_result_to_json(self) -> None:
        """Analysis result serializes to JSON."""
        result = AnalysisResult(
            session_id="session-123",
            status=AnalysisStatus.COMPLETED,
            exercise="Deep Squat",
            confidence=0.95,
            is_correct=True,
        )
        
        json_str = result.model_dump_json()
        
        assert isinstance(json_str, str)
        assert "session-123" in json_str
        assert "Deep Squat" in json_str

    def test_landmarks_request_from_dict(self) -> None:
        """Landmarks request created from dict."""
        data = {
            "landmarks": [[[0.5, 0.5, 0.0] for _ in range(33)]],
            "exercise_name": "Test",
            "fps": 25.0,
        }
        
        request = LandmarksAnalysisRequest.model_validate(data)
        
        assert request.exercise_name == "Test"
        assert request.fps == 25.0
