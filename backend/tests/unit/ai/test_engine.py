"""
Comprehensive unit tests for OrthoSensePredictor AI Engine.

Test coverage:
1. Predictor initialization
2. Analysis with valid data
3. Analysis with invalid data
4. Exercise name handling
5. Confidence scores
6. Feedback generation
7. Reset functionality
8. Edge cases
"""

import numpy as np
import pytest

from app.ai.core.engine import OrthoSensePredictor


class TestPredictorInitialization:
    """Tests for predictor initialization."""

    def test_predictor_creates_diagnostician(self) -> None:
        """Predictor initializes with diagnostician."""
        predictor = OrthoSensePredictor()

        assert predictor.diag is not None

    def test_predictor_reset(self) -> None:
        """Predictor reset completes without error."""
        predictor = OrthoSensePredictor()

        # Should not raise
        predictor.reset()


class TestPredictorAnalysis:
    """Tests for predictor analysis functionality."""

    @pytest.fixture
    def predictor(self) -> OrthoSensePredictor:
        return OrthoSensePredictor()

    @pytest.fixture
    def valid_pose_data(self) -> np.ndarray:
        """Create valid 33-landmark pose data (10 frames)."""
        # Each frame: 33 landmarks * 3 coordinates (x, y, z)
        return np.random.rand(10, 33, 3).astype(np.float32)

    def test_analyze_returns_dict(
        self,
        predictor: OrthoSensePredictor,
        valid_pose_data: np.ndarray,
    ) -> None:
        """Analysis returns dictionary with required keys."""
        result = predictor.analyze(valid_pose_data, "Standing Shoulder Abduction")

        assert isinstance(result, dict)
        assert "exercise" in result
        assert "confidence" in result
        assert "is_correct" in result
        assert "feedback" in result

    def test_analyze_exercise_name_preserved(
        self,
        predictor: OrthoSensePredictor,
        valid_pose_data: np.ndarray,
    ) -> None:
        """Exercise name is preserved in result."""
        exercise_name = "Seated Knee Extension"
        result = predictor.analyze(valid_pose_data, exercise_name)

        assert result["exercise"] == exercise_name

    def test_analyze_confidence_range(
        self,
        predictor: OrthoSensePredictor,
        valid_pose_data: np.ndarray,
    ) -> None:
        """Confidence score is within valid range."""
        result = predictor.analyze(valid_pose_data, "Standing Shoulder Abduction")

        assert 0.0 <= result["confidence"] <= 1.0

    def test_analyze_is_correct_is_boolean(
        self,
        predictor: OrthoSensePredictor,
        valid_pose_data: np.ndarray,
    ) -> None:
        """is_correct is a boolean value."""
        result = predictor.analyze(valid_pose_data, "Standing Shoulder Abduction")

        assert isinstance(result["is_correct"], bool)

    def test_analyze_feedback_is_dict(
        self,
        predictor: OrthoSensePredictor,
        valid_pose_data: np.ndarray,
    ) -> None:
        """Feedback is returned as dictionary."""
        result = predictor.analyze(valid_pose_data, "Standing Shoulder Abduction")

        assert isinstance(result["feedback"], dict)

    def test_analyze_with_list_input(
        self,
        predictor: OrthoSensePredictor,
    ) -> None:
        """Analysis handles list input (converts to ndarray)."""
        list_data = [[[0.5, 0.5, 0.0] for _ in range(33)] for _ in range(10)]
        result = predictor.analyze(list_data, "Standing Shoulder Abduction")

        assert isinstance(result, dict)
        assert "exercise" in result

    def test_analyze_different_exercises(
        self,
        predictor: OrthoSensePredictor,
        valid_pose_data: np.ndarray,
    ) -> None:
        """Analysis works for different exercise types."""
        exercises = [
            "Standing Shoulder Abduction",
            "Seated Knee Extension",
            "Hip Flexion",
            "Ankle Rotation",
        ]

        for exercise in exercises:
            result = predictor.analyze(valid_pose_data, exercise)
            assert result["exercise"] == exercise


class TestPredictorEdgeCases:
    """Tests for edge cases and error handling."""

    @pytest.fixture
    def predictor(self) -> OrthoSensePredictor:
        return OrthoSensePredictor()

    def test_analyze_empty_data(
        self,
        predictor: OrthoSensePredictor,
    ) -> None:
        """Analysis handles empty data."""
        empty_data = np.array([])
        result = predictor.analyze(empty_data, "Standing Shoulder Abduction")

        # Should return result without crashing
        assert isinstance(result, dict)

    def test_analyze_single_frame(
        self,
        predictor: OrthoSensePredictor,
    ) -> None:
        """Analysis handles single frame."""
        single_frame = np.random.rand(1, 33, 3).astype(np.float32)
        result = predictor.analyze(single_frame, "Standing Shoulder Abduction")

        assert isinstance(result, dict)

    def test_analyze_unknown_exercise(
        self,
        predictor: OrthoSensePredictor,
    ) -> None:
        """Analysis handles unknown exercise name gracefully."""
        valid_data = np.random.rand(10, 33, 3).astype(np.float32)
        result = predictor.analyze(valid_data, "Unknown Exercise XYZ")

        # Should return result with exercise name
        assert result["exercise"] == "Unknown Exercise XYZ"

    def test_analyze_zero_data(
        self,
        predictor: OrthoSensePredictor,
    ) -> None:
        """Analysis handles all-zero data."""
        zero_data = np.zeros((10, 33, 3), dtype=np.float32)
        result = predictor.analyze(zero_data, "Standing Shoulder Abduction")

        assert isinstance(result, dict)

    def test_analyze_normalized_data(
        self,
        predictor: OrthoSensePredictor,
    ) -> None:
        """Analysis handles normalized (0-1) data."""
        normalized_data = np.random.rand(10, 33, 3).astype(np.float32)
        result = predictor.analyze(normalized_data, "Standing Shoulder Abduction")

        assert isinstance(result, dict)

    def test_multiple_sequential_analyses(
        self,
        predictor: OrthoSensePredictor,
    ) -> None:
        """Multiple sequential analyses work correctly."""
        data = np.random.rand(10, 33, 3).astype(np.float32)

        results = []
        for i in range(5):
            result = predictor.analyze(data, f"Exercise {i}")
            results.append(result)

        assert len(results) == 5
        assert all(isinstance(r, dict) for r in results)


class TestPredictorDataTypes:
    """Tests for various input data types."""

    @pytest.fixture
    def predictor(self) -> OrthoSensePredictor:
        return OrthoSensePredictor()

    def test_analyze_float32_input(
        self,
        predictor: OrthoSensePredictor,
    ) -> None:
        """Float32 input is handled correctly."""
        data = np.random.rand(10, 33, 3).astype(np.float32)
        result = predictor.analyze(data, "Standing Shoulder Abduction")

        assert isinstance(result, dict)

    def test_analyze_float64_input(
        self,
        predictor: OrthoSensePredictor,
    ) -> None:
        """Float64 input is handled correctly."""
        data = np.random.rand(10, 33, 3).astype(np.float64)
        result = predictor.analyze(data, "Standing Shoulder Abduction")

        assert isinstance(result, dict)

    def test_analyze_nested_list_input(
        self,
        predictor: OrthoSensePredictor,
    ) -> None:
        """Nested list input is converted and handled."""
        data = [
            [[float(i + j + k) / 100 for k in range(3)] for j in range(33)]
            for i in range(10)
        ]
        result = predictor.analyze(data, "Standing Shoulder Abduction")

        assert isinstance(result, dict)
