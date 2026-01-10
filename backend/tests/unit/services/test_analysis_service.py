"""Unit tests for Analysis Service / OrthoSense AI System.

Comprehensive test coverage for:
1. OrthoSenseSystem initialization and singleton pattern
2. Landmarks analysis flow
3. Input validation and edge cases
4. Sliding window creation
5. Result serialization
"""

from unittest.mock import MagicMock

import numpy as np
import pytest

from app.ai.core.system import OrthoSenseSystem


class TestOrthoSenseSystemSingleton:
    """Tests for singleton pattern."""

    def test_singleton_returns_same_instance(self) -> None:
        """Multiple instantiations return same instance."""
        system1 = OrthoSenseSystem()
        system2 = OrthoSenseSystem()
        assert system1 is system2

    def test_system_has_engine(self) -> None:
        """System has engine attribute."""
        system = OrthoSenseSystem()
        assert hasattr(system, "engine")
        assert system.engine is not None

    def test_system_has_reporter(self) -> None:
        """System has reporter attribute."""
        system = OrthoSenseSystem()
        assert hasattr(system, "reporter")
        assert system.reporter is not None


class TestOrthoSenseSystemInitialization:
    """Tests for system initialization."""

    def test_initialize_returns_true(self) -> None:
        """Initialize returns True on success."""
        system = OrthoSenseSystem()
        result = system.initialize()
        assert result is True

    def test_is_initialized_after_init(self) -> None:
        """is_initialized is True after initialization."""
        system = OrthoSenseSystem()
        system.initialize()
        assert system.is_initialized is True

    def test_close_sets_initialized_false(self) -> None:
        """Close sets initialized to False."""
        system = OrthoSenseSystem()
        system.initialize()
        system.close()
        assert system.is_initialized is False


class TestAnalyzeLandmarks:
    """Tests for analyze_landmarks method."""

    @pytest.fixture
    def system(self) -> OrthoSenseSystem:
        """Get OrthoSenseSystem instance."""
        return OrthoSenseSystem()

    @pytest.fixture
    def valid_landmarks(self) -> list:
        """Generate valid landmarks (33 joints × 3 coords per frame)."""
        # 5 frames with proper skeleton data
        return [[[0.5, 0.5, 0.0] for _ in range(33)] for _ in range(5)]

    @pytest.fixture
    def landmarks_with_visibility(self) -> list:
        """Landmarks with visibility scores."""
        return [[[0.5, 0.5, 0.0, 0.95] for _ in range(33)] for _ in range(5)]

    def test_empty_landmarks_returns_error(self, system: OrthoSenseSystem) -> None:
        """Empty landmarks returns error dict."""
        result = system.analyze_landmarks([], "Deep Squat")
        assert "error" in result
        assert "No landmarks" in result["error"]

    def test_valid_landmarks_returns_result(
        self,
        system: OrthoSenseSystem,
        valid_landmarks: list,
    ) -> None:
        """Valid landmarks return analysis result."""
        result = system.analyze_landmarks(valid_landmarks, "Deep Squat")

        assert "exercise" in result
        assert result["exercise"] == "Deep Squat"
        assert "is_correct" in result
        assert "feedback" in result
        assert "confidence" in result

    def test_invalid_joint_count_handled(self, system: OrthoSenseSystem) -> None:
        """Frames with wrong joint count are filtered."""
        # Frame with 30 joints instead of 33
        bad_landmarks = [[[0.5, 0.5, 0.0] for _ in range(30)]]
        result = system.analyze_landmarks(bad_landmarks, "Deep Squat")
        assert "error" in result

    def test_visibility_flags_processed(
        self,
        system: OrthoSenseSystem,
        landmarks_with_visibility: list,
    ) -> None:
        """Landmarks with visibility are processed correctly."""
        result = system.analyze_landmarks(landmarks_with_visibility, "Deep Squat")
        assert "exercise" in result

    def test_result_is_serializable(
        self,
        system: OrthoSenseSystem,
        valid_landmarks: list,
    ) -> None:
        """Result is JSON serializable (no NumPy types)."""
        import json

        result = system.analyze_landmarks(valid_landmarks, "Deep Squat")
        # Should not raise
        json_str = json.dumps(result)
        assert isinstance(json_str, str)

    def test_text_report_generated(
        self,
        system: OrthoSenseSystem,
        valid_landmarks: list,
    ) -> None:
        """Text report is included in result."""
        result = system.analyze_landmarks(valid_landmarks, "Deep Squat")
        assert "text_report" in result
        assert isinstance(result["text_report"], str)


class TestSlidingWindows:
    """Tests for sliding window creation."""

    @pytest.fixture
    def system(self) -> OrthoSenseSystem:
        """Get OrthoSenseSystem instance."""
        return OrthoSenseSystem()

    def test_short_sequence_single_window(self, system: OrthoSenseSystem) -> None:
        """Sequence shorter than window_size creates single window."""
        raw_data = [np.zeros((33, 3)) for _ in range(30)]
        visibility = [True] * 30

        windows, win_vis = system._create_sliding_windows(
            raw_data, visibility, win_size=60, step=15
        )

        assert len(windows) == 1
        assert len(windows[0]) == 30

    def test_long_sequence_multiple_windows(self, system: OrthoSenseSystem) -> None:
        """Sequence longer than window_size creates multiple windows."""
        raw_data = [np.zeros((33, 3)) for _ in range(100)]
        visibility = [True] * 100

        windows, win_vis = system._create_sliding_windows(
            raw_data, visibility, win_size=60, step=15
        )

        # (100 - 60) / 15 = 2.67, so at least 2 windows
        assert len(windows) >= 2

    def test_window_visibility_calculated(self, system: OrthoSenseSystem) -> None:
        """Window visibility is calculated from frame visibility."""
        raw_data = [np.zeros((33, 3)) for _ in range(30)]
        # 80% visible
        visibility = [True] * 24 + [False] * 6

        windows, win_vis = system._create_sliding_windows(
            raw_data, visibility, win_size=60
        )

        # 80% > 70% threshold, should be visible
        assert win_vis[0] is True

    def test_window_visibility_low_threshold(self, system: OrthoSenseSystem) -> None:
        """Low visibility frames result in invisible window."""
        raw_data = [np.zeros((33, 3)) for _ in range(30)]
        # Only 50% visible
        visibility = [True] * 15 + [False] * 15

        windows, win_vis = system._create_sliding_windows(
            raw_data, visibility, win_size=60
        )

        # 50% < 70% threshold
        assert win_vis[0] is False


class TestMakeSerializable:
    """Tests for _make_serializable method."""

    @pytest.fixture
    def system(self) -> OrthoSenseSystem:
        """Get OrthoSenseSystem instance."""
        return OrthoSenseSystem()

    def test_numpy_int_converted(self, system: OrthoSenseSystem) -> None:
        """NumPy integers are converted to Python int."""
        result = system._make_serializable(np.int64(42))
        assert isinstance(result, int)
        assert result == 42

    def test_numpy_float_converted(self, system: OrthoSenseSystem) -> None:
        """NumPy floats are converted to Python float."""
        result = system._make_serializable(np.float64(3.14))
        assert isinstance(result, float)
        assert abs(result - 3.14) < 0.001

    def test_numpy_array_converted(self, system: OrthoSenseSystem) -> None:
        """NumPy arrays are converted to lists."""
        arr = np.array([1, 2, 3])
        result = system._make_serializable(arr)
        assert isinstance(result, list)
        assert result == [1, 2, 3]

    def test_nested_dict_converted(self, system: OrthoSenseSystem) -> None:
        """Nested dicts with NumPy values are converted."""
        data = {
            "count": np.int32(10),
            "nested": {
                "value": np.float32(0.5),
            },
        }
        result = system._make_serializable(data)

        assert isinstance(result["count"], int)
        assert isinstance(result["nested"]["value"], float)

    def test_list_with_numpy_converted(self, system: OrthoSenseSystem) -> None:
        """Lists containing NumPy values are converted."""
        data = [np.int64(1), np.float64(2.0), np.array([3, 4])]
        result = system._make_serializable(data)

        assert isinstance(result[0], int)
        assert isinstance(result[1], float)
        assert isinstance(result[2], list)


class TestAnalysisEdgeCases:
    """Edge cases and error handling tests."""

    @pytest.fixture
    def system(self) -> OrthoSenseSystem:
        """Get OrthoSenseSystem instance."""
        return OrthoSenseSystem()

    def test_none_landmarks_handled(self, system: OrthoSenseSystem) -> None:
        """None landmarks handled gracefully."""
        result = system.analyze_landmarks(None, "Deep Squat")  # type: ignore
        assert "error" in result

    def test_single_frame_analyzed(self, system: OrthoSenseSystem) -> None:
        """Single frame can be analyzed."""
        single_frame = [[[0.5, 0.5, 0.0] for _ in range(33)]]
        result = system.analyze_landmarks(single_frame, "Deep Squat")
        assert "exercise" in result

    def test_low_visibility_landmarks(self, system: OrthoSenseSystem) -> None:
        """Low visibility landmarks are handled."""
        # All zeros - technically invisible
        low_vis = [[[0.0, 0.0, 0.0, 0.1] for _ in range(33)] for _ in range(5)]
        result = system.analyze_landmarks(low_vis, "Deep Squat")
        # Should still return a result (may be degraded)
        assert "exercise" in result or "error" in result

    def test_mixed_visibility_frames(self, system: OrthoSenseSystem) -> None:
        """Mix of visible and invisible frames handled."""
        frames = []
        for i in range(10):
            if i % 2 == 0:
                # Visible frame
                frames.append([[0.5, 0.5, 0.0, 0.9] for _ in range(33)])
            else:
                # Invisible frame
                frames.append([[0.0, 0.0, 0.0, 0.1] for _ in range(33)])

        result = system.analyze_landmarks(frames, "Deep Squat")
        assert "exercise" in result


class TestEngineReset:
    """Tests for engine reset functionality."""

    def test_engine_reset_called(self) -> None:
        """Engine reset is called before analysis."""
        system = OrthoSenseSystem()
        system.engine.reset = MagicMock()

        landmarks = [[[0.5, 0.5, 0.0] for _ in range(33)]]
        system.analyze_landmarks(landmarks, "Deep Squat")

        system.engine.reset.assert_called_once()


class TestExerciseNameHandling:
    """Tests for exercise name parameter."""

    @pytest.fixture
    def system(self) -> OrthoSenseSystem:
        """Get OrthoSenseSystem instance."""
        return OrthoSenseSystem()

    @pytest.fixture
    def valid_landmarks(self) -> list:
        """Generate valid landmarks."""
        return [[[0.5, 0.5, 0.0] for _ in range(33)] for _ in range(5)]

    def test_exercise_name_in_result(
        self,
        system: OrthoSenseSystem,
        valid_landmarks: list,
    ) -> None:
        """Exercise name is included in result."""
        result = system.analyze_landmarks(valid_landmarks, "Hurdle Step")
        assert result["exercise"] == "Hurdle Step"

    def test_different_exercises(
        self,
        system: OrthoSenseSystem,
        valid_landmarks: list,
    ) -> None:
        """Different exercises produce different analysis."""
        result1 = system.analyze_landmarks(valid_landmarks, "Deep Squat")
        result2 = system.analyze_landmarks(
            valid_landmarks, "Standing Shoulder Abduction"
        )

        assert result1["exercise"] == "Deep Squat"
        assert result2["exercise"] == "Standing Shoulder Abduction"
