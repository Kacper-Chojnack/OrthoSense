"""Analysis engine for buffering frames and triggering LSTM classification."""

from dataclasses import dataclass, field
from typing import TYPE_CHECKING

import numpy as np

from app.ai.core.config import (
    CONFIDENCE_THRESHOLD,
    EXERCISE_CLASSES,
    SEQUENCE_LENGTH,
)
from app.core.logging import get_logger

if TYPE_CHECKING:
    from app.ai.core.model import LSTMModel
    from app.ai.core.pose_estimation import PoseResult

logger = get_logger(__name__)


@dataclass
class AnalysisResult:
    """Result of LSTM exercise classification."""

    exercise_name: str
    exercise_id: int
    confidence: float
    probabilities: dict[str, float]
    is_confident: bool

    @classmethod
    def empty(cls) -> "AnalysisResult":
        """Create empty result when analysis not ready."""
        return cls(
            exercise_name="",
            exercise_id=-1,
            confidence=0.0,
            probabilities={},
            is_confident=False,
        )


@dataclass
class AnalysisEngine:
    """Buffers frames and triggers LSTM classification when ready.

    Collects pose landmarks over SEQUENCE_LENGTH frames, then passes
    the sequence to LSTM for exercise classification.
    """

    model: "LSTMModel"
    sequence_length: int = SEQUENCE_LENGTH
    _buffer: list[np.ndarray] = field(default_factory=list)

    def add_frame(self, pose_result: "PoseResult") -> bool:
        """Add pose landmarks to buffer.

        Args:
            pose_result: Pose estimation result for current frame.

        Returns:
            True if buffer is full and ready for analysis.
        """
        if not pose_result.is_valid:
            return False

        features = pose_result.to_flat_array()
        self._buffer.append(features)

        # Keep only last sequence_length frames
        if len(self._buffer) > self.sequence_length:
            self._buffer = self._buffer[-self.sequence_length :]

        return len(self._buffer) >= self.sequence_length

    def analyze(self) -> AnalysisResult:
        """Run LSTM classification on buffered sequence.

        Returns:
            AnalysisResult with classification if buffer full,
            empty result otherwise.
        """
        if len(self._buffer) < self.sequence_length:
            return AnalysisResult.empty()

        sequence = np.array(self._buffer[-self.sequence_length :])
        predicted_class, confidence, probs = self.model.predict(sequence)

        probabilities = {
            EXERCISE_CLASSES[i]: float(probs[i]) for i in range(len(probs))
        }

        return AnalysisResult(
            exercise_name=EXERCISE_CLASSES.get(predicted_class, "Unknown"),
            exercise_id=predicted_class,
            confidence=confidence,
            probabilities=probabilities,
            is_confident=confidence >= CONFIDENCE_THRESHOLD,
        )

    def reset(self) -> None:
        """Clear the frame buffer."""
        self._buffer.clear()

    @property
    def frames_buffered(self) -> int:
        """Number of frames currently in buffer."""
        return len(self._buffer)

    @property
    def frames_needed(self) -> int:
        """Total frames needed for analysis."""
        return self.sequence_length
