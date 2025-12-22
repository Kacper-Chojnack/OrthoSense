import numpy as np
import pytest
from unittest.mock import MagicMock, patch
from pathlib import Path
import sys

# Ensure we can import from app
sys.path.append(str(Path(__file__).parent.parent))

from app.ai.core.pose_estimation import PoseEstimator, PoseResult, Landmark

def test_landmark_to_array():
    """Test converting Landmark to numpy array."""
    lm = Landmark(x=1.0, y=2.0, z=3.0, visibility=0.9)
    arr = lm.to_array()
    expected = np.array([1.0, 2.0, 3.0, 0.9], dtype=np.float32)
    assert np.array_equal(arr, expected)

def test_pose_result_empty():
    """Test empty PoseResult behavior."""
    res = PoseResult()
    assert not res.is_valid
    assert len(res.landmarks) == 0
    
    flat = res.to_flat_array()
    assert len(flat) == 132
    assert np.all(flat == 0)

def test_pose_result_valid():
    """Test valid PoseResult with landmarks."""
    landmarks = [Landmark(x=i, y=i, z=i, visibility=1.0) for i in range(33)]
    res = PoseResult(landmarks=landmarks)
    
    assert res.is_valid
    flat = res.to_flat_array()
    assert len(flat) == 132  # 33 landmarks * 4 features
    assert flat[0] == 0.0  # x of first landmark
    assert flat[3] == 1.0  # visibility of first landmark

@patch("app.ai.core.pose_estimation.Path.exists")
def test_pose_estimator_init_fail_no_model(mock_exists):
    """Test initialization failure when model file is missing."""
    mock_exists.return_value = False
    estimator = PoseEstimator(model_path=Path("fake.task"))
    assert not estimator.initialize()
    assert not estimator._initialized

@patch("app.ai.core.pose_estimation.Path.exists")
def test_pose_estimator_init_success(mock_exists):
    """Test successful initialization."""
    mock_exists.return_value = True
    
    # Mock mediapipe imports inside the method
    with patch.dict("sys.modules", {
        "mediapipe": MagicMock(),
        "mediapipe.tasks": MagicMock(),
        "mediapipe.tasks.python": MagicMock(),
        "mediapipe.tasks.python.vision": MagicMock(),
    }):
        estimator = PoseEstimator()
        assert estimator.initialize()
        assert estimator._initialized
        
        # Test double init returns True immediately
        assert estimator.initialize()

@patch("app.ai.core.pose_estimation.Path.exists")
def test_pose_estimator_process(mock_exists):
    """Test processing a frame."""
    mock_exists.return_value = True

    # Mock detection result
    mock_result = MagicMock()
    mock_landmark = MagicMock()
    mock_landmark.x = 0.5
    mock_landmark.y = 0.5
    mock_landmark.z = 0.0
    mock_landmark.visibility = 0.9
    
    # Create 33 mock landmarks
    mock_result.pose_landmarks = [[mock_landmark for _ in range(33)]]

    # Mock landmarker instance
    mock_landmarker = MagicMock()
    mock_landmarker.detect.side_effect = lambda *args, **kwargs: mock_result

    # Mock vision module
    mock_vision = MagicMock()
    mock_vision.PoseLandmarker.create_from_options.side_effect = lambda *args, **kwargs: mock_landmarker

    # Mock python module to ensure vision attribute matches
    mock_python = MagicMock()
    mock_python.vision = mock_vision

    with patch.dict("sys.modules", {
        "mediapipe": MagicMock(),
        "mediapipe.tasks": MagicMock(),
        "mediapipe.tasks.python": mock_python,
        "mediapipe.tasks.python.vision": mock_vision,
    }):
        estimator = PoseEstimator()
        estimator.initialize()
        
        # Create dummy frame
        frame = np.zeros((100, 100, 3), dtype=np.uint8)
        result = estimator.process(frame)
        
        assert result.is_valid
        assert len(result.landmarks) == 33
        
        # Test close
        estimator.close()
        assert estimator._landmarker is None
        assert not estimator._initialized

def test_pose_estimator_process_uninitialized():
    """Test processing without initialization."""
    estimator = PoseEstimator()
    # Mock initialize to fail
    with patch.object(estimator, 'initialize', return_value=False):
        frame = np.zeros((100, 100, 3), dtype=np.uint8)
        result = estimator.process(frame)
        assert not result.is_valid
