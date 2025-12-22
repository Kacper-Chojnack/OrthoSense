import pytest
import numpy as np
from app.ai.core.diagnostics import DiagnosticsEngine, ExerciseType, DiagnosticResult
from app.ai.core.pose_estimation import PoseResult, Landmark

def create_mock_pose(points_map=None):
    """Create a PoseResult with specific points set."""
    landmarks = [Landmark(0, 0, 0, 0) for _ in range(33)]
    if points_map:
        for idx, (x, y, z) in points_map.items():
            landmarks[idx] = Landmark(x, y, z, 1.0)
    return PoseResult(landmarks=landmarks)

def test_diagnostics_init():
    """Test initialization and exercise setting."""
    engine = DiagnosticsEngine()
    assert engine._exercise_type == ExerciseType.DEEP_SQUAT
    
    engine.set_exercise(ExerciseType.HURDLE_STEP)
    assert engine._exercise_type == ExerciseType.HURDLE_STEP
    assert engine._last_feedback == ""

def test_analyze_no_pose():
    """Test analysis with invalid pose."""
    engine = DiagnosticsEngine()
    res = engine.analyze(PoseResult())
    assert not res.is_correct
    assert "No pose detected" in res.feedback

def test_calculate_angle():
    """Test vector angle calculation."""
    engine = DiagnosticsEngine()
    
    # 90 degree angle
    a = np.array([1, 0, 0])
    b = np.array([0, 0, 0]) # Vertex
    c = np.array([0, 1, 0])
    
    angle = engine._calculate_angle(a, b, c)
    assert abs(angle - 90.0) < 0.1
    
    # 180 degree angle
    a = np.array([1, 0, 0])
    b = np.array([0, 0, 0])
    c = np.array([-1, 0, 0])
    angle = engine._calculate_angle(a, b, c)
    assert abs(angle - 180.0) < 0.1

def test_analyze_squat_good():
    """Test squat analysis with good form."""
    engine = DiagnosticsEngine(ExerciseType.DEEP_SQUAT)
    
    # Mock landmarks for a good squat (knees bent ~90 deg)
    # Hip (23, 24), Knee (25, 26), Ankle (27, 28)
    # Simple 2D coordinates for 90 deg knee
    points = {
        23: (0, 1, 0), # Hip
        25: (1, 1, 0), # Knee
        27: (1, 0, 0), # Ankle
        24: (0, 1, 0), # R Hip
        26: (1, 1, 0), # R Knee
        28: (1, 0, 0), # R Ankle
        11: (0, 2, 0), # L Shoulder (upright)
        12: (0, 2, 0), # R Shoulder
    }
    
    pose = create_mock_pose(points)
    res = engine.analyze(pose)
    
    # Note: The exact angle calculation depends on 3D vectors, 
    # but this setup should produce valid angles.
    assert res.angles
    # We just check it runs without error and produces a result
    assert isinstance(res, DiagnosticResult)

def test_voice_message_cooldown():
    """Test that voice messages don't spam."""
    engine = DiagnosticsEngine()
    issues = ["Fix your back"]
    
    # First time
    msg1 = engine._get_voice_message(issues)
    assert msg1 == "Fix your back"
    
    # Immediate second time (should be silenced)
    msg2 = engine._get_voice_message(issues)
    assert msg2 == ""
    
    # After cooldown
    engine._feedback_cooldown = 100
    msg3 = engine._get_voice_message(issues)
    assert msg3 == "Fix your back"
