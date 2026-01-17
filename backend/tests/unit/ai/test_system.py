"""
Comprehensive unit tests for OrthoSenseSystem AI coordinator.

Test coverage:
1. System initialization (singleton pattern)
2. Landmark analysis
3. Sliding window creation
4. Window classification
5. Serialization helpers
6. Edge cases
"""

import numpy as np
import pytest

from app.ai.core.system import OrthoSenseSystem


class TestOrthoSenseSystemSingleton:
    """Tests for singleton pattern."""

    def test_singleton_returns_same_instance(self) -> None:
        """Multiple instantiations return same object."""
        system1 = OrthoSenseSystem()
        system2 = OrthoSenseSystem()

        assert system1 is system2

    def test_system_has_engine(self) -> None:
        """System has an engine component."""
        system = OrthoSenseSystem()

        assert system.engine is not None

    def test_system_has_reporter(self) -> None:
        """System has a reporter component."""
        system = OrthoSenseSystem()

        assert system.reporter is not None


class TestSystemInitialization:
    """Tests for system initialization."""

    def test_initialize_without_model_verification(self) -> None:
        """System initializes without model verification."""
        system = OrthoSenseSystem()
        result = system.initialize(verify_models=False)

        assert result is True
        assert system.is_initialized is True

    def test_close_resets_initialized_flag(self) -> None:
        """Close method resets initialized state."""
        system = OrthoSenseSystem()
        system.initialize(verify_models=False)
        system.close()

        assert system.is_initialized is False


class TestLandmarkAnalysis:
    """Tests for landmark analysis functionality."""

    @pytest.fixture
    def system(self) -> OrthoSenseSystem:
        system = OrthoSenseSystem()
        system.initialize(verify_models=False)
        return system

    @pytest.fixture
    def valid_landmarks(self) -> list[list[list[float]]]:
        """Generate valid landmarks (60 frames, 33 landmarks, 3 coords)."""
        return [
            [[0.5 + i * 0.001, 0.5 + j * 0.001, 0.0] for j in range(33)]
            for i in range(60)
        ]

    @pytest.fixture
    def landmarks_with_visibility(self) -> list[list[list[float]]]:
        """Generate landmarks with visibility scores (4 coords)."""
        return [[[0.5, 0.5, 0.0, 0.9] for _ in range(33)] for _ in range(60)]

    def test_analyze_returns_dict(
        self, system: OrthoSenseSystem, valid_landmarks: list
    ) -> None:
        """Analysis returns dictionary result."""
        result = system.analyze_landmarks(valid_landmarks, "Deep Squat")

        assert isinstance(result, dict)

    def test_analyze_result_has_exercise_key(
        self, system: OrthoSenseSystem, valid_landmarks: list
    ) -> None:
        """Result contains exercise name."""
        result = system.analyze_landmarks(valid_landmarks, "Deep Squat")

        assert "exercise" in result
        assert result["exercise"] == "Deep Squat"

    def test_analyze_result_has_confidence_key(
        self, system: OrthoSenseSystem, valid_landmarks: list
    ) -> None:
        """Result contains confidence score."""
        result = system.analyze_landmarks(valid_landmarks, "Deep Squat")

        assert "confidence" in result

    def test_analyze_result_has_is_correct_key(
        self, system: OrthoSenseSystem, valid_landmarks: list
    ) -> None:
        """Result contains is_correct flag."""
        result = system.analyze_landmarks(valid_landmarks, "Deep Squat")

        assert "is_correct" in result

    def test_analyze_result_has_feedback_key(
        self, system: OrthoSenseSystem, valid_landmarks: list
    ) -> None:
        """Result contains feedback."""
        result = system.analyze_landmarks(valid_landmarks, "Deep Squat")

        assert "feedback" in result

    def test_analyze_result_has_text_report(
        self, system: OrthoSenseSystem, valid_landmarks: list
    ) -> None:
        """Result contains text report."""
        result = system.analyze_landmarks(valid_landmarks, "Deep Squat")

        assert "text_report" in result

    def test_analyze_empty_landmarks_returns_error(
        self, system: OrthoSenseSystem
    ) -> None:
        """Empty landmarks return error dict."""
        result = system.analyze_landmarks([], "Deep Squat")

        assert "error" in result
        assert result["error"] == "No landmarks provided"

    def test_analyze_with_visibility_scores(
        self, system: OrthoSenseSystem, landmarks_with_visibility: list
    ) -> None:
        """Analysis handles landmarks with visibility scores."""
        result = system.analyze_landmarks(landmarks_with_visibility, "Deep Squat")

        assert isinstance(result, dict)
        assert "exercise" in result


class TestSlidingWindows:
    """Tests for sliding window creation."""

    @pytest.fixture
    def system(self) -> OrthoSenseSystem:
        system = OrthoSenseSystem()
        system.initialize(verify_models=False)
        return system

    def test_create_windows_with_short_sequence(self, system: OrthoSenseSystem) -> None:
        """Short sequences create single window."""
        frames = [np.zeros((33, 3)) for _ in range(30)]
        vis_flags = [True] * 30

        windows, win_vis = system._create_sliding_windows(frames, vis_flags)

        assert len(windows) == 1
        assert len(win_vis) == 1

    def test_create_windows_with_long_sequence(self, system: OrthoSenseSystem) -> None:
        """Long sequences create multiple overlapping windows."""
        frames = [np.zeros((33, 3)) for _ in range(120)]
        vis_flags = [True] * 120

        windows, win_vis = system._create_sliding_windows(
            frames, vis_flags, win_size=60, step=15
        )

        assert len(windows) > 1

    def test_window_visibility_calculation(self, system: OrthoSenseSystem) -> None:
        """Window visibility is calculated from frame flags."""
        frames = [np.zeros((33, 3)) for _ in range(30)]
        # All frames visible
        vis_flags = [True] * 30

        _, win_vis = system._create_sliding_windows(frames, vis_flags)

        assert win_vis[0] is True

    def test_window_visibility_with_low_visible_count(
        self, system: OrthoSenseSystem
    ) -> None:
        """Low visibility count marks window as not visible."""
        frames = [np.zeros((33, 3)) for _ in range(30)]
        # Only 5 frames visible (less than 70%)
        vis_flags = [True] * 5 + [False] * 25

        _, win_vis = system._create_sliding_windows(frames, vis_flags)

        assert win_vis[0] is False


class TestWindowClassification:
    """Tests for window classification."""

    @pytest.fixture
    def system(self) -> OrthoSenseSystem:
        system = OrthoSenseSystem()
        system.initialize(verify_models=False)
        return system

    def test_classify_windows_returns_list(self, system: OrthoSenseSystem) -> None:
        """Window classification returns list of votes."""
        windows = [
            np.array([[[0.5, 0.5, 0.0] for _ in range(33)] for _ in range(20)])
            for _ in range(3)
        ]
        win_vis = [True, True, True]

        votes = system._classify_windows(windows, win_vis)

        assert isinstance(votes, list)

    def test_invisible_windows_skipped(self, system: OrthoSenseSystem) -> None:
        """Windows marked as invisible are skipped."""
        windows = [
            np.array([[[0.5, 0.5, 0.0] for _ in range(33)] for _ in range(20)])
            for _ in range(3)
        ]
        # Only first and third windows visible
        win_vis = [True, False, True]

        votes = system._classify_windows(windows, win_vis)

        # Should process at most 2 windows
        assert len(votes) <= 2


class TestSerializationHelpers:
    """Tests for serialization helper methods."""

    @pytest.fixture
    def system(self) -> OrthoSenseSystem:
        return OrthoSenseSystem()

    def test_make_serializable_with_dict(self, system: OrthoSenseSystem) -> None:
        """Dict with numpy types is converted."""
        data = {
            "value": np.float32(0.5),
            "count": np.int64(10),
        }

        result = system._make_serializable(data)

        assert isinstance(result["value"], float)
        assert isinstance(result["count"], int)

    def test_make_serializable_with_list(self, system: OrthoSenseSystem) -> None:
        """List with numpy types is converted."""
        data = [np.float32(0.1), np.float32(0.2)]

        result = system._make_serializable(data)

        assert all(isinstance(v, float) for v in result)

    def test_make_serializable_with_ndarray(self, system: OrthoSenseSystem) -> None:
        """Numpy array is converted to list."""
        data = np.array([1, 2, 3])

        result = system._make_serializable(data)

        assert isinstance(result, list)
        assert result == [1, 2, 3]

    def test_make_serializable_with_nested_structures(
        self, system: OrthoSenseSystem
    ) -> None:
        """Nested structures are recursively converted."""
        data = {
            "outer": {
                "inner": np.float64(0.5),
                "array": np.array([1, 2, 3]),
            },
            "list": [np.int32(1), np.int32(2)],
        }

        result = system._make_serializable(data)

        assert isinstance(result["outer"]["inner"], float)
        assert isinstance(result["outer"]["array"], list)
        assert all(isinstance(v, int) for v in result["list"])

    def test_make_serializable_with_python_types(
        self, system: OrthoSenseSystem
    ) -> None:
        """Python native types pass through unchanged."""
        data = {
            "string": "hello",
            "int": 42,
            "float": 3.14,
            "bool": True,
            "none": None,
        }

        result = system._make_serializable(data)

        assert result == data


class TestEdgeCases:
    """Tests for edge cases and error handling."""

    @pytest.fixture
    def system(self) -> OrthoSenseSystem:
        system = OrthoSenseSystem()
        system.initialize(verify_models=False)
        return system

    def test_analyze_single_frame(self, system: OrthoSenseSystem) -> None:
        """Single frame is handled gracefully."""
        single_frame = [[[0.5, 0.5, 0.0] for _ in range(33)]]

        result = system.analyze_landmarks(single_frame, "Deep Squat")

        assert result is not None
        assert isinstance(result, dict)

    def test_analyze_many_frames(self, system: OrthoSenseSystem) -> None:
        """Many frames are handled."""
        many_frames = [[[0.5, 0.5, 0.0] for _ in range(33)] for _ in range(500)]

        result = system.analyze_landmarks(many_frames, "Deep Squat")

        assert result is not None

    def test_analyze_frame_with_wrong_landmark_count(
        self, system: OrthoSenseSystem
    ) -> None:
        """Frames with wrong landmark count are skipped."""
        # Some frames have wrong number of landmarks
        frames = [
            [[0.5, 0.5, 0.0] for _ in range(33)],  # Correct
            [[0.5, 0.5, 0.0] for _ in range(20)],  # Wrong count
            [[0.5, 0.5, 0.0] for _ in range(33)],  # Correct
        ]

        result = system.analyze_landmarks(frames, "Deep Squat")

        # Should still return result
        assert isinstance(result, dict)

    def test_analyze_all_frames_wrong_count_returns_error(
        self, system: OrthoSenseSystem
    ) -> None:
        """All frames with wrong landmark count returns error."""
        frames = [
            [[0.5, 0.5, 0.0] for _ in range(10)]  # Wrong count
            for _ in range(30)
        ]

        result = system.analyze_landmarks(frames, "Deep Squat")

        assert "error" in result

    def test_analyze_with_different_exercises(self, system: OrthoSenseSystem) -> None:
        """Analysis works for different exercise names."""
        frames = [[[0.5, 0.5, 0.0] for _ in range(33)] for _ in range(60)]

        exercises = [
            "Deep Squat",
            "Hurdle Step",
            "Standing Shoulder Abduction",
            "Unknown Exercise",
        ]

        for exercise in exercises:
            result = system.analyze_landmarks(frames, exercise)
            assert result["exercise"] == exercise
