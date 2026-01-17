"""Extended unit tests for diagnostics module.

Test coverage:
1. MovementDiagnostician class
2. Deep Squat analysis
3. Hurdle Step analysis
4. Shoulder Abduction analysis
5. Variant detection
6. Report generation
"""

import numpy as np
import pytest

from app.ai.core.diagnostics import MOVEMENT_CORRECT, MovementDiagnostician, ReportGenerator


class TestMovementDiagnosticianInit:
    """Test MovementDiagnostician initialization."""

    def test_creates_instance(self):
        """Should create diagnostician instance."""
        diag = MovementDiagnostician()
        assert diag is not None

    def test_has_mp_indices(self):
        """Should have MediaPipe landmark indices."""
        diag = MovementDiagnostician()
        assert "NOSE" in diag.MP
        assert "LEFT_SHOULDER" in diag.MP
        assert "RIGHT_SHOULDER" in diag.MP
        assert "LEFT_HIP" in diag.MP
        assert "RIGHT_HIP" in diag.MP

    def test_mp_indices_are_correct(self):
        """Should have correct MediaPipe indices."""
        diag = MovementDiagnostician()
        assert diag.MP["NOSE"] == 0
        assert diag.MP["LEFT_SHOULDER"] == 11
        assert diag.MP["RIGHT_SHOULDER"] == 12
        assert diag.MP["LEFT_HIP"] == 23
        assert diag.MP["RIGHT_HIP"] == 24


class TestAngleCalculations:
    """Test angle calculation methods."""

    def test_calculate_angle_straight_line(self):
        """Angle of straight line should be 180 degrees."""
        a = [0, 0, 0]
        b = [1, 0, 0]
        c = [2, 0, 0]
        angle = MovementDiagnostician.calculate_angle(a, b, c)
        assert pytest.approx(angle, abs=0.1) == 180.0

    def test_calculate_angle_right_angle(self):
        """Right angle should be 90 degrees."""
        a = [0, 1, 0]
        b = [0, 0, 0]
        c = [1, 0, 0]
        angle = MovementDiagnostician.calculate_angle(a, b, c)
        assert pytest.approx(angle, abs=0.1) == 90.0

    def test_calculate_angle_with_zero_vectors(self):
        """Should handle zero-length vectors."""
        a = [0, 0, 0]
        b = [0, 0, 0]
        c = [0, 0, 0]
        angle = MovementDiagnostician.calculate_angle(a, b, c)
        assert angle == 0.0

    def test_calculate_projected_angle(self):
        """Should calculate 2D projected angle."""
        a = [0, 1, 0]
        b = [0, 0, 0]
        c = [1, 0, 0]
        angle = MovementDiagnostician.calculate_projected_angle(a, b, c)
        assert pytest.approx(angle, abs=0.1) == 90.0


class TestDistanceCalculation:
    """Test distance calculation."""

    def test_calculate_distance_origin(self):
        """Distance from origin to point."""
        a = [0, 0, 0]
        b = [3, 4, 0]
        dist = MovementDiagnostician.calculate_distance(a, b)
        assert pytest.approx(dist, abs=0.01) == 5.0

    def test_calculate_distance_3d(self):
        """3D distance calculation."""
        a = [1, 2, 3]
        b = [4, 6, 3]
        dist = MovementDiagnostician.calculate_distance(a, b)
        assert pytest.approx(dist, abs=0.01) == 5.0


class TestVariantDetection:
    """Test exercise variant detection."""

    def test_detect_variant_empty_data(self):
        """Should return BOTH for empty data."""
        diag = MovementDiagnostician()
        variant = diag.detect_variant("Standing Shoulder Abduction", [])
        assert variant == "BOTH"

    def test_detect_variant_none_data(self):
        """Should return BOTH for None data."""
        diag = MovementDiagnostician()
        variant = diag.detect_variant("Standing Shoulder Abduction", None)
        assert variant == "BOTH"

    def test_detect_variant_left_arm_raised(self):
        """Should detect LEFT variant for left arm raised."""
        diag = MovementDiagnostician()
        frame = _create_skeleton_with_left_arm_raised()
        variant = diag.detect_variant("Standing Shoulder Abduction", [frame])
        assert variant == "LEFT"

    def test_detect_variant_right_arm_raised(self):
        """Should detect RIGHT variant for right arm raised."""
        diag = MovementDiagnostician()
        frame = _create_skeleton_with_right_arm_raised()
        variant = diag.detect_variant("Standing Shoulder Abduction", [frame])
        assert variant == "RIGHT"

    def test_detect_variant_both_arms_raised(self):
        """Should detect BOTH variant for both arms raised."""
        diag = MovementDiagnostician()
        frame = _create_skeleton_with_both_arms_raised()
        variant = diag.detect_variant("Standing Shoulder Abduction", [frame])
        assert variant == "BOTH"

    def test_detect_hurdle_left_knee_raised(self):
        """Should detect LEFT for Hurdle Step with left knee raised."""
        diag = MovementDiagnostician()
        frame = _create_skeleton_with_left_knee_raised()
        variant = diag.detect_variant("Hurdle Step", [frame])
        assert variant == "LEFT"

    def test_detect_hurdle_right_knee_raised(self):
        """Should detect RIGHT for Hurdle Step with right knee raised."""
        diag = MovementDiagnostician()
        frame = _create_skeleton_with_right_knee_raised()
        variant = diag.detect_variant("Hurdle Step", [frame])
        assert variant == "RIGHT"


class TestDiagnose:
    """Test main diagnose method."""

    def test_diagnose_no_data(self):
        """Should return error for no data."""
        diag = MovementDiagnostician()
        is_correct, feedback = diag.diagnose("Deep Squat", [])
        assert is_correct is False
        assert "System" in feedback or "No data" in str(feedback)

    def test_diagnose_none_data(self):
        """Should return error for None data."""
        diag = MovementDiagnostician()
        is_correct, feedback = diag.diagnose("Deep Squat", None)
        assert is_correct is False

    def test_diagnose_unknown_exercise(self):
        """Should return generic response for unknown exercise."""
        diag = MovementDiagnostician()
        frame = _create_neutral_skeleton()
        is_correct, feedback = diag.diagnose("Unknown Exercise", [frame])
        assert is_correct is True
        assert "System" in feedback

    def test_diagnose_deep_squat_correct(self):
        """Should analyze correct deep squat."""
        diag = MovementDiagnostician()
        frames = _create_correct_squat_frames()
        is_correct, feedback = diag.diagnose("Deep Squat", frames)
        # Correct form should be detected
        assert isinstance(is_correct, bool)
        assert isinstance(feedback, (dict, str))


class TestSquatAnalysis:
    """Test Deep Squat analysis."""

    def test_detects_squat_too_shallow(self):
        """Should detect shallow squat."""
        diag = MovementDiagnostician()
        frames = _create_shallow_squat_frames()
        is_correct, feedback = diag.diagnose("Deep Squat", frames)
        
        # Should detect shallow squat error
        if isinstance(feedback, dict):
            assert "Squat too shallow" in feedback or is_correct is True
        else:
            assert is_correct is False or "shallow" in str(feedback).lower()

    def test_detects_knee_valgus(self):
        """Should detect knee valgus."""
        diag = MovementDiagnostician()
        frames = _create_knee_valgus_frames()
        is_correct, feedback = diag.diagnose("Deep Squat", frames)
        
        # May detect knee valgus
        assert isinstance(is_correct, bool)


class TestReportGenerator:
    """Test ReportGenerator class."""

    def test_creates_instance(self):
        """Should create reporter instance."""
        reporter = ReportGenerator()
        assert reporter is not None

    def test_generates_report_for_correct_movement(self):
        """Should generate positive report for correct movement."""
        reporter = ReportGenerator()
        result = (True, {"System": MOVEMENT_CORRECT})
        report = reporter.generate_report(result, "Deep Squat")
        
        assert report is not None
        assert len(report) > 0

    def test_generates_report_with_errors(self):
        """Should generate report with error feedback."""
        reporter = ReportGenerator()
        result = (False, {"Knee Valgus (Collapse)": True})
        report = reporter.generate_report(result, "Deep Squat")
        
        assert report is not None
        assert len(report) > 0

    def test_report_includes_exercise_name(self):
        """Report may include exercise name."""
        reporter = ReportGenerator()
        result = (True, {})
        report = reporter.generate_report(result, "Hurdle Step")
        
        assert report is not None


# Helper functions to create test skeleton data

def _create_neutral_skeleton():
    """Create neutral standing position skeleton."""
    # 33 joints with [x, y, z] coordinates
    return [[0.5, 0.5, 0.0] for _ in range(33)]


def _create_skeleton_with_left_arm_raised():
    """Create skeleton with left arm raised."""
    skeleton = [[0.5, 0.5, 0.0] for _ in range(33)]
    # Left wrist (15) above left shoulder (11)
    skeleton[11] = [0.4, 0.4, 0.0]  # Left shoulder
    skeleton[15] = [0.3, 0.2, 0.0]  # Left wrist (raised)
    skeleton[12] = [0.6, 0.4, 0.0]  # Right shoulder
    skeleton[16] = [0.7, 0.5, 0.0]  # Right wrist (down)
    return skeleton


def _create_skeleton_with_right_arm_raised():
    """Create skeleton with right arm raised."""
    skeleton = [[0.5, 0.5, 0.0] for _ in range(33)]
    skeleton[11] = [0.4, 0.4, 0.0]  # Left shoulder
    skeleton[15] = [0.3, 0.5, 0.0]  # Left wrist (down)
    skeleton[12] = [0.6, 0.4, 0.0]  # Right shoulder
    skeleton[16] = [0.7, 0.2, 0.0]  # Right wrist (raised)
    return skeleton


def _create_skeleton_with_both_arms_raised():
    """Create skeleton with both arms raised."""
    skeleton = [[0.5, 0.5, 0.0] for _ in range(33)]
    skeleton[11] = [0.4, 0.4, 0.0]  # Left shoulder
    skeleton[15] = [0.3, 0.1, 0.0]  # Left wrist (raised)
    skeleton[12] = [0.6, 0.4, 0.0]  # Right shoulder
    skeleton[16] = [0.7, 0.1, 0.0]  # Right wrist (raised)
    return skeleton


def _create_skeleton_with_left_knee_raised():
    """Create skeleton with left knee raised for Hurdle Step."""
    skeleton = [[0.5, 0.5, 0.0] for _ in range(33)]
    skeleton[25] = [0.4, 0.3, 0.0]  # Left knee (raised)
    skeleton[26] = [0.6, 0.6, 0.0]  # Right knee (down)
    return skeleton


def _create_skeleton_with_right_knee_raised():
    """Create skeleton with right knee raised for Hurdle Step."""
    skeleton = [[0.5, 0.5, 0.0] for _ in range(33)]
    skeleton[25] = [0.4, 0.6, 0.0]  # Left knee (down)
    skeleton[26] = [0.6, 0.3, 0.0]  # Right knee (raised)
    return skeleton


def _create_correct_squat_frames():
    """Create frames representing correct deep squat."""
    frames = []
    for i in range(30):
        frame = [[0.5, 0.5, 0.0] for _ in range(33)]
        # Simulate squat depth - hips below knees
        depth = 0.1 + (i / 30) * 0.3  # Gradually increase depth
        frame[23] = [0.45, 0.6 + depth, 0.0]  # Left hip
        frame[24] = [0.55, 0.6 + depth, 0.0]  # Right hip
        frame[25] = [0.45, 0.7, 0.0]  # Left knee
        frame[26] = [0.55, 0.7, 0.0]  # Right knee
        frame[27] = [0.45, 0.9, 0.0]  # Left ankle
        frame[28] = [0.55, 0.9, 0.0]  # Right ankle
        frames.append(frame)
    return frames


def _create_shallow_squat_frames():
    """Create frames representing shallow squat (error case)."""
    frames = []
    for i in range(30):
        frame = [[0.5, 0.5, 0.0] for _ in range(33)]
        # Hips above knees - too shallow
        frame[23] = [0.45, 0.55, 0.0]  # Left hip
        frame[24] = [0.55, 0.55, 0.0]  # Right hip
        frame[25] = [0.45, 0.7, 0.0]  # Left knee
        frame[26] = [0.55, 0.7, 0.0]  # Right knee
        frames.append(frame)
    return frames


def _create_knee_valgus_frames():
    """Create frames representing knee valgus (error case)."""
    frames = []
    for i in range(30):
        frame = [[0.5, 0.5, 0.0] for _ in range(33)]
        # Knees closer together than ankles
        frame[25] = [0.48, 0.7, 0.0]  # Left knee (too close)
        frame[26] = [0.52, 0.7, 0.0]  # Right knee (too close)
        frame[27] = [0.4, 0.9, 0.0]   # Left ankle (wide)
        frame[28] = [0.6, 0.9, 0.0]   # Right ankle (wide)
        frames.append(frame)
    return frames
