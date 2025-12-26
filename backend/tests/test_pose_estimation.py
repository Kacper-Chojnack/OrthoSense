"""Tests for pose estimation module using VideoProcessor."""

from unittest.mock import MagicMock, patch

import pytest


def test_video_processor_get_raw_landmarks():
    """Test extracting raw landmarks from MediaPipe output."""
    # Create mock world landmarks
    mock_landmarks = []
    for i in range(33):
        mock_lm = MagicMock()
        mock_lm.x = float(i) / 33.0
        mock_lm.y = float(i) / 33.0
        mock_lm.z = float(i) / 33.0
        mock_landmarks.append(mock_lm)

    # We need to mock the entire module chain to test VideoProcessor
    with (
        patch.dict(
            "sys.modules",
            {
                "mediapipe": MagicMock(),
                "mediapipe.tasks": MagicMock(),
                "mediapipe.tasks.python": MagicMock(),
                "mediapipe.tasks.python.vision": MagicMock(),
            },
        ),
        patch("app.ai.core.pose_estimation.Path.exists", return_value=True),
        patch("app.ai.core.pose_estimation.vision.PoseLandmarker.create_from_options"),
    ):
        from app.ai.core.pose_estimation import VideoProcessor

        processor = MagicMock(spec=VideoProcessor)
        processor.get_raw_landmarks = VideoProcessor.get_raw_landmarks

        result = processor.get_raw_landmarks(processor, mock_landmarks)

        assert result.shape == (33, 3)
        assert result[0, 0] == pytest.approx(0.0, abs=0.01)
        assert result[32, 0] == pytest.approx(32.0 / 33.0, abs=0.01)


def test_check_visibility_no_landmarks():
    """Test visibility check with no landmarks."""
    with (
        patch.dict(
            "sys.modules",
            {
                "mediapipe": MagicMock(),
                "mediapipe.tasks": MagicMock(),
                "mediapipe.tasks.python": MagicMock(),
                "mediapipe.tasks.python.vision": MagicMock(),
            },
        ),
        patch("app.ai.core.pose_estimation.Path.exists", return_value=True),
        patch("app.ai.core.pose_estimation.vision.PoseLandmarker.create_from_options"),
    ):
        from app.ai.core.pose_estimation import VideoProcessor

        processor = MagicMock(spec=VideoProcessor)
        processor.check_visibility = VideoProcessor.check_visibility

        is_visible, visible_count, total = processor.check_visibility(processor, None)
        assert not is_visible
        assert visible_count == 0


def test_check_visibility_with_landmarks():
    """Test visibility check with landmarks."""
    # Create 33 mock landmarks with visibility
    mock_landmarks = []
    for i in range(33):
        mock_lm = MagicMock()
        mock_lm.visibility = 0.9 if i in [11, 12, 23, 24, 25, 26, 27, 28] else 0.5
        mock_landmarks.append(mock_lm)

    with (
        patch.dict(
            "sys.modules",
            {
                "mediapipe": MagicMock(),
                "mediapipe.tasks": MagicMock(),
                "mediapipe.tasks.python": MagicMock(),
                "mediapipe.tasks.python.vision": MagicMock(),
            },
        ),
        patch("app.ai.core.pose_estimation.Path.exists", return_value=True),
        patch("app.ai.core.pose_estimation.vision.PoseLandmarker.create_from_options"),
    ):
        from app.ai.core.pose_estimation import VideoProcessor

        processor = MagicMock(spec=VideoProcessor)
        processor.check_visibility = VideoProcessor.check_visibility

        is_visible, visible_count, total = processor.check_visibility(
            processor, mock_landmarks
        )
        assert is_visible
        assert visible_count == 8  # All key indices have visibility > 0.5
