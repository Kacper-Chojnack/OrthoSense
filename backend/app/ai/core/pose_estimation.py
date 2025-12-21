"""MediaPipe Pose Landmarker wrapper for pose estimation."""

from dataclasses import dataclass, field
from pathlib import Path
from typing import Any

import numpy as np

from app.ai.core.config import (
    POSE_DETECTION_CONFIDENCE,
    POSE_LANDMARKER_PATH,
    POSE_TRACKING_CONFIDENCE,
)
from app.core.logging import get_logger

logger = get_logger(__name__)


@dataclass
class Landmark:
    """Single pose landmark with coordinates and visibility."""

    x: float
    y: float
    z: float
    visibility: float

    def to_array(self) -> np.ndarray:
        """Convert to numpy array [x, y, z, visibility]."""
        return np.array([self.x, self.y, self.z, self.visibility], dtype=np.float32)


@dataclass
class PoseResult:
    """Result of pose estimation for a single frame."""

    landmarks: list[Landmark] = field(default_factory=list)
    timestamp_ms: int = 0

    @property
    def is_valid(self) -> bool:
        """Check if pose was detected (33 landmarks expected)."""
        return len(self.landmarks) == 33

    def to_flat_array(self) -> np.ndarray:
        """Convert all landmarks to flat array [x1,y1,z1,v1, x2,y2,z2,v2, ...]."""
        if not self.is_valid:
            return np.zeros(132, dtype=np.float32)
        return np.concatenate([lm.to_array() for lm in self.landmarks])


class PoseEstimator:
    """Wrapper for MediaPipe Pose Landmarker."""

    def __init__(self, model_path: Path | None = None) -> None:
        """Initialize pose estimator.

        Args:
            model_path: Path to pose_landmarker.task file.
                       Defaults to bundled model.
        """
        self._model_path = model_path or POSE_LANDMARKER_PATH
        self._landmarker: Any = None
        self._initialized = False

    def initialize(self) -> bool:
        """Lazy initialization of MediaPipe landmarker.

        Returns:
            True if initialization successful, False otherwise.
        """
        if self._initialized:
            return True

        try:
            from mediapipe.tasks import python as mp_tasks
            from mediapipe.tasks.python import vision

            if not self._model_path.exists():
                logger.error(
                    "pose_model_not_found",
                    path=str(self._model_path),
                )
                return False

            base_options = mp_tasks.BaseOptions(model_asset_path=str(self._model_path))
            options = vision.PoseLandmarkerOptions(
                base_options=base_options,
                running_mode=vision.RunningMode.IMAGE,
                min_pose_detection_confidence=POSE_DETECTION_CONFIDENCE,
                min_tracking_confidence=POSE_TRACKING_CONFIDENCE,
            )
            self._landmarker = vision.PoseLandmarker.create_from_options(options)
            self._initialized = True
            logger.info("pose_estimator_initialized")
            return True

        except ImportError as e:
            logger.error("mediapipe_import_error", error=str(e))
            return False
        except Exception as e:
            logger.error("pose_estimator_init_error", error=str(e))
            return False

    def process(self, frame: np.ndarray) -> PoseResult:
        """Process a single frame and extract pose landmarks.

        Args:
            frame: BGR image as numpy array (OpenCV format).

        Returns:
            PoseResult with extracted landmarks.
        """
        if not self._initialized and not self.initialize():
            return PoseResult()

        try:
            import mediapipe as mp

            # Convert BGR to RGB for MediaPipe
            rgb_frame = frame[..., ::-1].copy()
            mp_image = mp.Image(image_format=mp.ImageFormat.SRGB, data=rgb_frame)

            result = self._landmarker.detect(mp_image)

            if not result.pose_landmarks:
                return PoseResult()

            # Extract first detected pose
            landmarks = [
                Landmark(
                    x=lm.x,
                    y=lm.y,
                    z=lm.z,
                    visibility=lm.visibility,
                )
                for lm in result.pose_landmarks[0]
            ]

            return PoseResult(landmarks=landmarks)

        except Exception as e:
            logger.error("pose_estimation_error", error=str(e))
            return PoseResult()

    def close(self) -> None:
        """Release resources."""
        if self._landmarker:
            self._landmarker.close()
            self._landmarker = None
            self._initialized = False
