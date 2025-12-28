"""Tests for movement diagnostics module."""

import numpy as np

from app.ai.core.diagnostics import MovementDiagnostician


def create_mock_skeleton_frame(joint_positions: dict | None = None) -> np.ndarray:
    """Create a mock skeleton frame with 33 landmarks × 3 coords."""
    frame = np.zeros((33, 3), dtype=np.float32)
    if joint_positions:
        for idx, (x, y, z) in joint_positions.items():
            frame[idx] = [x, y, z]
    return frame


def test_diagnostician_init():
    """Test initialization of MovementDiagnostician."""
    diag = MovementDiagnostician()
    assert diag.MP is not None
    assert "LEFT_HIP" in diag.MP
    assert "RIGHT_KNEE" in diag.MP


def test_calculate_angle_90_degrees():
    """Test angle calculation for 90 degree angle."""
    # 90 degree angle
    a = np.array([1, 0, 0])
    b = np.array([0, 0, 0])  # Vertex
    c = np.array([0, 1, 0])

    angle = MovementDiagnostician.calculate_angle(a, b, c)
    assert abs(angle - 90.0) < 0.1


def test_calculate_angle_180_degrees():
    """Test angle calculation for straight line (180 degrees)."""
    a = np.array([1, 0, 0])
    b = np.array([0, 0, 0])
    c = np.array([-1, 0, 0])

    angle = MovementDiagnostician.calculate_angle(a, b, c)
    assert abs(angle - 180.0) < 0.1


def test_calculate_distance():
    """Test distance calculation between two points."""
    a = np.array([0, 0, 0])
    b = np.array([3, 4, 0])

    distance = MovementDiagnostician.calculate_distance(a, b)
    assert abs(distance - 5.0) < 0.01


def test_diagnose_empty_data():
    """Test diagnosis with empty skeleton data."""
    diag = MovementDiagnostician()
    is_correct, feedback = diag.diagnose("Deep Squat", None)
    assert is_correct is False
    assert isinstance(feedback, dict)
    assert "System" in feedback
    assert "No data" in feedback["System"]


def test_diagnose_unknown_exercise():
    """Test diagnosis with unknown exercise returns generic feedback."""
    diag = MovementDiagnostician()
    skeleton_data = [create_mock_skeleton_frame()]
    is_correct, feedback = diag.diagnose("Unknown Exercise", skeleton_data)
    assert is_correct is True
    assert isinstance(feedback, dict)
    assert "System" in feedback
    assert "analysis" in feedback["System"].lower()
