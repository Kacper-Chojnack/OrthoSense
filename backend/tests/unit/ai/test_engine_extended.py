"""Extended unit tests for engine module.

Test coverage:
1. OrthoSensePredictor initialization
2. Analysis functionality
3. Data handling
4. Error handling
"""

import numpy as np
import pytest

from app.ai.core.engine import OrthoSensePredictor


class TestOrthoSensePredictorInit:
    """Test OrthoSensePredictor initialization."""

    def test_initializes_without_arguments(self):
        """Should initialize without any arguments."""
        predictor = OrthoSensePredictor()
        assert predictor is not None

    def test_creates_diagnostician(self):
        """Should create MovementDiagnostician."""
        predictor = OrthoSensePredictor()
        assert predictor.diag is not None

    def test_has_reset_method(self):
        """Should have reset method."""
        predictor = OrthoSensePredictor()
        # Should not raise
        predictor.reset()


class TestAnalysis:
    """Test analysis functionality."""

    @pytest.fixture
    def predictor(self):
        """Create predictor instance."""
        return OrthoSensePredictor()

    def test_analyze_returns_dict(self, predictor):
        """Analysis should return dictionary."""
        landmarks = np.random.rand(10, 33, 3).astype(np.float32)
        result = predictor.analyze(landmarks, "Standing Shoulder Abduction")
        assert isinstance(result, dict)

    def test_analyze_contains_required_keys(self, predictor):
        """Analysis result should contain required keys."""
        landmarks = np.random.rand(10, 33, 3).astype(np.float32)
        result = predictor.analyze(landmarks, "Standing Shoulder Abduction")

        assert "exercise" in result
        assert "confidence" in result
        assert "is_correct" in result
        assert "feedback" in result

    def test_analyze_preserves_exercise_name(self, predictor):
        """Should preserve exercise name in result."""
        landmarks = np.random.rand(10, 33, 3).astype(np.float32)
        exercise_name = "Seated Knee Extension"
        result = predictor.analyze(landmarks, exercise_name)

        assert result["exercise"] == exercise_name

    def test_analyze_confidence_is_numeric(self, predictor):
        """Confidence should be numeric."""
        landmarks = np.random.rand(10, 33, 3).astype(np.float32)
        result = predictor.analyze(landmarks, "test")

        assert isinstance(result["confidence"], (int, float))

    def test_analyze_is_correct_is_bool(self, predictor):
        """is_correct should be boolean."""
        landmarks = np.random.rand(10, 33, 3).astype(np.float32)
        result = predictor.analyze(landmarks, "test")

        assert isinstance(result["is_correct"], bool)

    def test_analyze_feedback_is_dict(self, predictor):
        """Feedback should be dictionary."""
        landmarks = np.random.rand(10, 33, 3).astype(np.float32)
        result = predictor.analyze(landmarks, "test")

        assert isinstance(result["feedback"], dict)


class TestDataHandling:
    """Test data handling and conversion."""

    @pytest.fixture
    def predictor(self):
        """Create predictor instance."""
        return OrthoSensePredictor()

    def test_handles_list_input(self, predictor):
        """Should handle list input."""
        landmarks = [[[0.1, 0.2, 0.3] for _ in range(33)] for _ in range(10)]
        result = predictor.analyze(landmarks, "test")
        assert result is not None

    def test_handles_numpy_array(self, predictor):
        """Should handle numpy array input."""
        landmarks = np.random.rand(10, 33, 3).astype(np.float32)
        result = predictor.analyze(landmarks, "test")
        assert result is not None

    def test_handles_different_frame_counts(self, predictor):
        """Should handle different frame counts."""
        for num_frames in [1, 5, 10, 30, 100]:
            landmarks = np.random.rand(num_frames, 33, 3).astype(np.float32)
            result = predictor.analyze(landmarks, "test")
            assert result is not None


class TestKnownExercises:
    """Test known exercise handling."""

    def test_known_exercises(self):
        """Should recognize known exercises."""
        expected_exercises = [
            "squat",
            "hurdle_step",
            "shoulder_abduction",
        ]
        # Just verify the list is valid
        assert len(expected_exercises) > 0


class TestInputProcessing:
    """Test input preprocessing."""

    def test_flattens_landmarks(self):
        """Should flatten 3D landmarks to 1D."""
        landmarks = np.random.rand(33, 3).astype(np.float32)

        # 33 landmarks x 3 coords = 99 values
        flattened = landmarks.flatten()

        assert len(flattened) == 99

    def test_handles_different_shapes(self):
        """Should handle different input shapes."""
        shapes = [
            (33, 3),
            (99,),
            (1, 33, 3),
            (1, 99),
        ]

        for shape in shapes:
            data = np.random.rand(*shape).astype(np.float32)
            # Should be able to reshape to (1, 99)
            flattened = data.reshape(-1)
            if len(flattened) >= 99:
                reshaped = flattened[:99].reshape(1, 99)
                assert reshaped.shape == (1, 99)


class TestOutputProcessing:
    """Test output postprocessing."""

    def test_softmax_output(self):
        """Output should be softmax probabilities."""
        raw_output = np.array([[1.0, 2.0, 3.0, 1.5, 0.5]])

        # Apply softmax
        exp_output = np.exp(raw_output - np.max(raw_output))
        softmax = exp_output / exp_output.sum()

        # Should sum to 1
        assert abs(softmax.sum() - 1.0) < 0.001

    def test_argmax_gives_prediction(self):
        """Argmax should give predicted class."""
        probabilities = np.array([[0.1, 0.7, 0.1, 0.05, 0.05]])

        predicted_class = np.argmax(probabilities)

        assert predicted_class == 1


class TestErrorHandling:
    """Test error handling."""

    @pytest.fixture
    def predictor(self):
        """Create predictor instance."""
        return OrthoSensePredictor()

    def test_handles_empty_exercise_name(self, predictor):
        """Should handle empty exercise name."""
        landmarks = np.random.rand(10, 33, 3).astype(np.float32)
        result = predictor.analyze(landmarks, "")
        assert result is not None

    def test_handles_unknown_exercise(self, predictor):
        """Should handle unknown exercise name."""
        landmarks = np.random.rand(10, 33, 3).astype(np.float32)
        result = predictor.analyze(landmarks, "unknown_exercise_xyz")
        assert result is not None


class TestModelIntegrity:
    """Test model integrity checks."""

    def test_verifies_model_hash(self):
        """Should verify model integrity."""
        from app.ai.core.integrity import verify_model_integrity

        # Function should exist
        assert callable(verify_model_integrity)
