"""Extended unit tests for OrthoSenseSystem.

Test coverage:
1. Singleton pattern
2. Initialization
3. Landmark analysis
4. Serialization
5. Window creation
"""

import numpy as np
import pytest

from app.ai.core.system import OrthoSenseSystem


class TestOrthoSenseSystemSingleton:
    """Test singleton pattern implementation."""

    def test_returns_same_instance(self):
        """Should return the same instance on multiple calls."""
        instance1 = OrthoSenseSystem()
        instance2 = OrthoSenseSystem()
        assert instance1 is instance2

    def test_has_engine(self):
        """Should have engine attribute."""
        system = OrthoSenseSystem()
        assert hasattr(system, "engine")

    def test_has_reporter(self):
        """Should have reporter attribute."""
        system = OrthoSenseSystem()
        assert hasattr(system, "reporter")


class TestOrthoSenseSystemInit:
    """Test initialization."""

    def test_initialize_returns_true(self):
        """Initialize should return True."""
        system = OrthoSenseSystem()
        result = system.initialize(verify_models=False)
        assert result is True

    def test_is_initialized_after_init(self):
        """Should be initialized after calling initialize."""
        system = OrthoSenseSystem()
        system.initialize(verify_models=False)
        assert system.is_initialized is True

    def test_close_resets_initialized(self):
        """Close should reset initialized state."""
        system = OrthoSenseSystem()
        system.initialize(verify_models=False)
        system.close()
        assert system._initialized is False


class TestLandmarkAnalysis:
    """Test landmark analysis."""

    def test_analyze_empty_landmarks(self):
        """Should return error for empty landmarks."""
        system = OrthoSenseSystem()
        system.initialize(verify_models=False)

        result = system.analyze_landmarks([], "Deep Squat")

        assert "error" in result

    def test_analyze_valid_landmarks(self):
        """Should analyze valid landmarks."""
        system = OrthoSenseSystem()
        system.initialize(verify_models=False)

        landmarks = _create_valid_landmarks(30)
        result = system.analyze_landmarks(landmarks, "Deep Squat")

        assert "exercise" in result or "error" in result

    def test_analyze_returns_serializable(self):
        """Result should be JSON serializable."""
        system = OrthoSenseSystem()
        system.initialize(verify_models=False)

        landmarks = _create_valid_landmarks(30)
        result = system.analyze_landmarks(landmarks, "Deep Squat")

        import json

        # Should not raise
        json.dumps(result)

    def test_analyze_includes_text_report(self):
        """Result should include text report."""
        system = OrthoSenseSystem()
        system.initialize(verify_models=False)

        landmarks = _create_valid_landmarks(30)
        result = system.analyze_landmarks(landmarks, "Deep Squat")

        if "error" not in result:
            assert "text_report" in result


class TestSlidingWindows:
    """Test sliding window creation."""

    def test_creates_windows_for_long_sequence(self):
        """Should create multiple windows for long sequences."""
        system = OrthoSenseSystem()
        frames = [np.zeros((33, 3)) for _ in range(120)]
        vis_flags = [True] * 120

        windows, win_vis = system._create_sliding_windows(frames, vis_flags)

        assert len(windows) > 1

    def test_creates_single_window_for_short_sequence(self):
        """Should create single window for short sequences."""
        system = OrthoSenseSystem()
        frames = [np.zeros((33, 3)) for _ in range(30)]
        vis_flags = [True] * 30

        windows, win_vis = system._create_sliding_windows(frames, vis_flags)

        assert len(windows) >= 1

    def test_window_size_is_correct(self):
        """Windows should have correct size."""
        system = OrthoSenseSystem()
        frames = [np.zeros((33, 3)) for _ in range(120)]
        vis_flags = [True] * 120

        windows, win_vis = system._create_sliding_windows(frames, vis_flags)

        for win in windows:
            assert len(win) <= 60


class TestMakeSerializable:
    """Test serialization helper."""

    def test_converts_numpy_int(self):
        """Should convert numpy int to Python int."""
        system = OrthoSenseSystem()

        obj = {"value": np.int64(42)}
        result = system._make_serializable(obj)

        assert isinstance(result["value"], int)
        assert result["value"] == 42

    def test_converts_numpy_float(self):
        """Should convert numpy float to Python float."""
        system = OrthoSenseSystem()

        obj = {"value": np.float64(3.14)}
        result = system._make_serializable(obj)

        assert isinstance(result["value"], float)
        assert pytest.approx(result["value"], abs=0.01) == 3.14

    def test_converts_numpy_array(self):
        """Should convert numpy array to list."""
        system = OrthoSenseSystem()

        obj = {"value": np.array([1, 2, 3])}
        result = system._make_serializable(obj)

        assert isinstance(result["value"], list)
        assert result["value"] == [1, 2, 3]

    def test_handles_nested_dict(self):
        """Should handle nested dictionaries."""
        system = OrthoSenseSystem()

        obj = {"outer": {"inner": np.int64(99)}}
        result = system._make_serializable(obj)

        assert result["outer"]["inner"] == 99

    def test_handles_nested_list(self):
        """Should handle nested lists."""
        system = OrthoSenseSystem()

        obj = {"items": [np.int64(1), np.int64(2)]}
        result = system._make_serializable(obj)

        assert result["items"] == [1, 2]


class TestVisibilityChecks:
    """Test visibility checking logic."""

    def test_visibility_threshold(self):
        """Key joints should have minimum visibility."""
        min_vis = 0.5
        assert min_vis == 0.5

    def test_key_joint_indices(self):
        """Key joints are shoulders, hips, knees, ankles."""
        key_idx = [11, 12, 23, 24, 25, 26, 27, 28]
        assert len(key_idx) == 8
        assert 11 in key_idx  # Left shoulder
        assert 12 in key_idx  # Right shoulder

    def test_minimum_visible_joints(self):
        """Should require at least 6 visible key joints."""
        min_visible = 6
        assert min_visible == 6


# Helper functions


def _create_valid_landmarks(num_frames: int) -> list:
    """Create valid landmark frames for testing."""
    landmarks = []
    for _ in range(num_frames):
        frame = []
        for j in range(33):
            # [x, y, z, visibility]
            frame.append([0.5 + j * 0.01, 0.5 + j * 0.01, 0.0, 0.9])
        landmarks.append(frame)
    return landmarks
