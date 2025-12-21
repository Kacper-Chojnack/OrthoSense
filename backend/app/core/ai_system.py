"""Singleton wrapper for OrthoSense AI System.

Provides global access to the heavy AI system instance.
Backend creates ONE instance at startup; all requests share it.
"""

import sys
from collections import deque
from pathlib import Path
from typing import TYPE_CHECKING

import numpy as np

AI_PATH = Path(__file__).parent.parent.parent.parent / "OrthoSense-zosia" / "ai"
sys.path.insert(0, str(AI_PATH))

if TYPE_CHECKING:
    from core.system import OrthoSenseSystem as OrthoSenseSystemType

_ai_instance: "OrthoSenseSystemType | None" = None


class LiveAnalysisSession:
    """Manages frame buffer for live analysis sliding window."""

    WINDOW_SIZE = 60
    MIN_FRAMES = 30

    def __init__(self, exercise_name: str) -> None:
        self.exercise_name = exercise_name
        self.frame_buffer: deque[np.ndarray] = deque(maxlen=self.WINDOW_SIZE)
        self.last_feedback: str = ""
        self.last_is_correct: bool = True

    def add_frame(self, landmarks: np.ndarray) -> None:
        """Add processed landmarks to the buffer."""
        self.frame_buffer.append(landmarks)

    def can_analyze(self) -> bool:
        """Check if we have enough frames for analysis."""
        return len(self.frame_buffer) >= self.MIN_FRAMES

    def get_window(self) -> list[np.ndarray]:
        """Get current frame window for analysis."""
        return list(self.frame_buffer)

    def reset(self) -> None:
        """Clear the frame buffer."""
        self.frame_buffer.clear()


def get_ai_system() -> "OrthoSenseSystemType":
    """Get the global AI system instance (Singleton pattern).

    Returns:
        OrthoSenseSystem: The initialized AI system instance.

    Raises:
        ImportError: If AI modules cannot be loaded.
    """
    global _ai_instance

    if _ai_instance is None:
        from core.system import OrthoSenseSystem

        _ai_instance = OrthoSenseSystem()

    return _ai_instance


def is_ai_available() -> bool:
    """Check if AI system can be initialized."""
    try:
        from core.system import OrthoSenseSystem  # noqa: F401

        return True
    except ImportError:
        return False


def get_available_exercises() -> dict[int, str]:
    """Get list of available exercises from AI config."""
    try:
        from core import config

        return config.EXERCISE_NAMES
    except ImportError:
        return {
            0: "Deep Squat",
            1: "Hurdle Step",
            2: "Standing Shoulder Abduction",
        }
