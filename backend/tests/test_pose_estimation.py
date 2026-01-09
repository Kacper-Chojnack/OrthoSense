"""Tests for pose estimation logic using OrthoSense AI components.

These tests validate the AI system components that process landmarks,
not the video processing (which is now handled client-side via ML Kit).
"""

import pytest

from app.ai.core.diagnostics import MovementDiagnostician
from app.ai.core.system import OrthoSenseSystem


class TestMovementDiagnostician:
    """Tests for MovementDiagnostician class."""

    @pytest.fixture
    def diagnostician(self):
        """Create MovementDiagnostician instance."""
        return MovementDiagnostician()

    def test_calculate_angle_straight_line(self, diagnostician):
        """Calculate angle for points forming 180 degrees."""
        a = [0, 0, 0]
        b = [1, 0, 0]
        c = [2, 0, 0]

        angle = diagnostician.calculate_angle(a, b, c)
        assert angle == pytest.approx(180.0, abs=0.1)

    def test_calculate_angle_right_angle(self, diagnostician):
        """Calculate angle for 90 degree corner."""
        a = [0, 1, 0]
        b = [0, 0, 0]
        c = [1, 0, 0]

        angle = diagnostician.calculate_angle(a, b, c)
        assert angle == pytest.approx(90.0, abs=0.1)

    def test_calculate_angle_acute(self, diagnostician):
        """Calculate acute angle."""
        a = [0, 1, 0]
        b = [0, 0, 0]
        c = [1, 1, 0]

        angle = diagnostician.calculate_angle(a, b, c)
        assert 0 < angle < 90

    def test_calculate_distance(self, diagnostician):
        """Calculate distance between two points."""
        a = [0, 0, 0]
        b = [3, 4, 0]

        distance = diagnostician.calculate_distance(a, b)
        assert distance == pytest.approx(5.0, abs=0.001)

    def test_calculate_projected_angle(self, diagnostician):
        """Calculate projected angle in 2D plane."""
        a = [0, 1, 5]  # z ignored
        b = [0, 0, 3]
        c = [1, 0, 7]

        angle = diagnostician.calculate_projected_angle(a, b, c)
        assert angle == pytest.approx(90.0, abs=0.1)

    def test_diagnose_with_no_data(self, diagnostician):
        """Diagnose returns False with no data."""
        is_correct, feedback = diagnostician.diagnose("Deep Squat", None)

        assert not is_correct
        assert "No data" in feedback.get("System", "")

    def test_diagnose_with_empty_data(self, diagnostician):
        """Diagnose returns False with empty data."""
        is_correct, feedback = diagnostician.diagnose("Deep Squat", [])

        assert not is_correct
        assert "No data" in feedback.get("System", "")

    def test_diagnose_unknown_exercise(self, diagnostician):
        """Diagnose returns True with generic message for unknown exercise."""
        skeleton_data = _create_mock_skeleton_frames(5)

        is_correct, feedback = diagnostician.diagnose("Unknown Exercise", skeleton_data)

        assert is_correct
        assert "No specific analysis" in feedback.get("System", "")


# NOTE: TestOrthoSensePredictor tests moved to tests/unit/ai/test_engine.py
# for better organization. See that file for comprehensive OrthoSensePredictor tests.


class TestOrthoSenseSystem:
    """Tests for OrthoSenseSystem singleton."""

    def test_singleton_pattern(self):
        """OrthoSenseSystem follows singleton pattern."""
        system1 = OrthoSenseSystem()
        system2 = OrthoSenseSystem()

        assert system1 is system2

    def test_initialize(self):
        """Initialize returns True."""
        system = OrthoSenseSystem()

        result = system.initialize()

        assert result is True
        assert system.is_initialized is True

    def test_close(self):
        """Close marks system as not initialized."""
        system = OrthoSenseSystem()
        system.initialize()

        system.close()

        assert system.is_initialized is False

    def test_analyze_landmarks_empty_input(self):
        """Analyze with empty landmarks returns error."""
        system = OrthoSenseSystem()

        result = system.analyze_landmarks([], "Deep Squat")

        assert "error" in result
        assert "No landmarks" in result["error"]

    def test_analyze_landmarks_valid_input(self):
        """Analyze with valid landmarks returns analysis."""
        system = OrthoSenseSystem()
        # 33 landmarks per frame, 3 coordinates each (x, y, z)
        landmarks = [
            [[float(j) * 0.01 for _ in range(3)] for j in range(33)] for _ in range(10)
        ]

        result = system.analyze_landmarks(landmarks, "Deep Squat")

        assert "error" not in result or result.get("error") is None
        assert "exercise" in result or "is_correct" in result

    def test_analyze_landmarks_with_visibility(self):
        """Analyze handles landmarks with visibility flag."""
        system = OrthoSenseSystem()
        # 33 landmarks with x, y, z, visibility
        landmarks = [
            [
                [float(j) * 0.01, float(j) * 0.02, float(j) * 0.03, 0.95]
                for j in range(33)
            ]
            for _ in range(10)
        ]

        result = system.analyze_landmarks(landmarks, "Hurdle Step")

        assert "error" not in result or result.get("error") is None

    def test_analyze_landmarks_invalid_frame_count(self):
        """Analyze handles frames with wrong landmark count."""
        system = OrthoSenseSystem()
        # Invalid: only 10 landmarks instead of 33
        landmarks = [[[0.0, 0.0, 0.0] for _ in range(10)] for _ in range(5)]

        result = system.analyze_landmarks(landmarks, "Deep Squat")

        # Should handle gracefully - either error or skip invalid frames
        assert isinstance(result, dict)


class TestVariantDetection:
    """Tests for exercise variant detection."""

    @pytest.fixture
    def diagnostician(self):
        """Create MovementDiagnostician instance."""
        return MovementDiagnostician()

    def test_detect_variant_no_data(self, diagnostician):
        """Detect variant returns BOTH with no data."""
        variant = diagnostician.detect_variant("Standing Shoulder Abduction", None)
        assert variant == "BOTH"

    def test_detect_variant_empty_data(self, diagnostician):
        """Detect variant returns BOTH with empty data."""
        variant = diagnostician.detect_variant("Standing Shoulder Abduction", [])
        assert variant == "BOTH"

    def test_detect_variant_shoulder_abduction_left(self, diagnostician):
        """Detect left arm active in shoulder abduction."""
        # Create frames where left wrist goes above left shoulder
        frames = _create_shoulder_abduction_frames(active_side="LEFT")

        variant = diagnostician.detect_variant("Standing Shoulder Abduction", frames)
        assert variant == "LEFT"

    def test_detect_variant_shoulder_abduction_right(self, diagnostician):
        """Detect right arm active in shoulder abduction."""
        frames = _create_shoulder_abduction_frames(active_side="RIGHT")

        variant = diagnostician.detect_variant("Standing Shoulder Abduction", frames)
        assert variant == "RIGHT"

    def test_detect_variant_hurdle_step(self, diagnostician):
        """Detect active leg in hurdle step."""
        frames = _create_hurdle_step_frames(active_side="LEFT")

        variant = diagnostician.detect_variant("Hurdle Step", frames)
        assert variant == "LEFT"

    def test_detect_variant_unknown_exercise(self, diagnostician):
        """Detect variant returns BOTH for unknown exercise."""
        frames = _create_mock_skeleton_frames(5)

        variant = diagnostician.detect_variant("Unknown Exercise", frames)
        assert variant == "BOTH"


def _create_mock_skeleton_frames(num_frames: int) -> list:
    """Create mock skeleton frames with 33 landmarks."""
    frames = []
    for _ in range(num_frames):
        frame = [[0.5, 0.5, 0.0] for _ in range(33)]
        frames.append(frame)
    return frames


def _create_shoulder_abduction_frames(active_side: str) -> list:
    """Create frames simulating shoulder abduction."""
    frames = []
    # MediaPipe indices: LEFT_WRIST=15, RIGHT_WRIST=16, LEFT_SHOULDER=11, RIGHT_SHOULDER=12
    for i in range(10):
        frame = [[0.5, 0.5, 0.0] for _ in range(33)]
        # Shoulders at y=0.4
        frame[11] = [0.4, 0.4, 0.0]  # LEFT_SHOULDER
        frame[12] = [0.6, 0.4, 0.0]  # RIGHT_SHOULDER

        if active_side == "LEFT":
            # Left wrist rises above shoulder
            frame[15] = [0.3, 0.4 - (i * 0.05), 0.0]  # LEFT_WRIST going up
            frame[16] = [0.7, 0.6, 0.0]  # RIGHT_WRIST stays down
        elif active_side == "RIGHT":
            frame[15] = [0.3, 0.6, 0.0]  # LEFT_WRIST stays down
            frame[16] = [0.7, 0.4 - (i * 0.05), 0.0]  # RIGHT_WRIST going up

        frames.append(frame)
    return frames


def _create_hurdle_step_frames(active_side: str) -> list:
    """Create frames simulating hurdle step."""
    frames = []
    # MediaPipe indices: LEFT_KNEE=25, RIGHT_KNEE=26
    for i in range(10):
        frame = [[0.5, 0.5, 0.0] for _ in range(33)]

        if active_side == "LEFT":
            # Left knee rises
            frame[25] = [0.4, 0.6 - (i * 0.05), 0.0]  # LEFT_KNEE going up
            frame[26] = [0.6, 0.7, 0.0]  # RIGHT_KNEE stays down
        elif active_side == "RIGHT":
            frame[25] = [0.4, 0.7, 0.0]  # LEFT_KNEE stays down
            frame[26] = [0.6, 0.6 - (i * 0.05), 0.0]  # RIGHT_KNEE going up

        frames.append(frame)
    return frames
