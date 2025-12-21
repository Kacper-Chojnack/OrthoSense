"""Main OrthoSense AI System facade."""

from dataclasses import dataclass, field
from typing import Any

import numpy as np

from app.ai.core.config import EXERCISE_NAME_TO_ID, SEQUENCE_LENGTH
from app.ai.core.diagnostics import DiagnosticsEngine, ExerciseType
from app.ai.core.engine import AnalysisEngine, AnalysisResult
from app.ai.core.model import LSTMModel
from app.ai.core.pose_estimation import PoseEstimator
from app.core.logging import get_logger

logger = get_logger(__name__)


@dataclass
class FrameAnalysisResult:
    """Complete result of analyzing a single frame."""

    # Diagnostics (real-time feedback)
    feedback: str
    voice_message: str
    is_correct: bool
    score: float
    angles: dict[str, float]

    # Classification (when buffer full)
    classification: AnalysisResult | None

    # Buffer status
    frames_buffered: int
    frames_needed: int
    pose_detected: bool

    def to_dict(self) -> dict[str, Any]:
        """Convert to JSON-serializable dictionary."""
        result: dict[str, Any] = {
            "feedback": self.feedback,
            "voice_message": self.voice_message,
            "is_correct": self.is_correct,
            "score": self.score,
            "angles": self.angles,
            "frames_buffered": self.frames_buffered,
            "frames_needed": self.frames_needed,
            "pose_detected": self.pose_detected,
        }

        if self.classification and self.classification.is_confident:
            result["classification"] = {
                "exercise_name": self.classification.exercise_name,
                "exercise_id": self.classification.exercise_id,
                "confidence": self.classification.confidence,
                "probabilities": self.classification.probabilities,
            }

        return result


@dataclass
class OrthoSenseSystem:
    """Main AI system orchestrating pose estimation, analysis, and diagnostics.

    This is the primary interface for the backend to interact with AI components.
    Implements the Facade pattern to provide a simple interface.
    """

    _pose_estimator: PoseEstimator = field(default_factory=PoseEstimator)
    _model: LSTMModel = field(default_factory=LSTMModel)
    _engine: AnalysisEngine | None = field(default=None)
    _diagnostics: DiagnosticsEngine = field(default_factory=DiagnosticsEngine)
    _initialized: bool = field(default=False)
    _current_exercise: str = field(default="Deep Squat")

    def __post_init__(self) -> None:
        """Initialize engine after dataclass init."""
        self._engine = AnalysisEngine(model=self._model)

    def initialize(self) -> bool:
        """Initialize all AI components.

        Returns:
            True if all components initialized successfully.
        """
        if self._initialized:
            return True

        pose_ok = self._pose_estimator.initialize()
        model_ok = self._model.initialize()

        self._initialized = pose_ok and model_ok

        if self._initialized:
            logger.info("orthosense_system_initialized")
        else:
            logger.warning(
                "orthosense_system_partial_init",
                pose_ok=pose_ok,
                model_ok=model_ok,
            )

        return self._initialized

    def set_exercise(self, exercise_name: str) -> bool:
        """Set the current exercise for analysis.

        Args:
            exercise_name: Name of exercise (e.g., "Deep Squat").

        Returns:
            True if exercise is supported.
        """
        exercise_id = EXERCISE_NAME_TO_ID.get(exercise_name)
        if exercise_id is None:
            logger.warning("unknown_exercise", name=exercise_name)
            return False

        self._current_exercise = exercise_name
        self._diagnostics.set_exercise(ExerciseType(exercise_id))
        if self._engine:
            self._engine.reset()  # Clear buffer when switching exercises

        logger.info("exercise_set", name=exercise_name, id=exercise_id)
        return True

    def analyze_frame(self, frame: np.ndarray) -> FrameAnalysisResult:
        """Process a single video frame and return analysis.

        This is the main entry point for real-time analysis.

        Args:
            frame: BGR image as numpy array (OpenCV format).

        Returns:
            FrameAnalysisResult with feedback, scores, and classification.
        """
        if not self._initialized:
            self.initialize()

        # Step 1: Pose estimation
        pose_result = self._pose_estimator.process(frame)

        # Step 2: Real-time diagnostics
        diagnostic_result = self._diagnostics.analyze(pose_result)

        # Step 3: Buffer for LSTM classification
        classification = None
        if self._engine and self._engine.add_frame(pose_result):
            classification = self._engine.analyze()

        frames_buffered = self._engine.frames_buffered if self._engine else 0
        frames_needed = self._engine.frames_needed if self._engine else SEQUENCE_LENGTH

        return FrameAnalysisResult(
            feedback=diagnostic_result.feedback,
            voice_message=diagnostic_result.voice_message,
            is_correct=diagnostic_result.is_correct,
            score=diagnostic_result.score,
            angles=diagnostic_result.angles,
            classification=classification,
            frames_buffered=frames_buffered,
            frames_needed=frames_needed,
            pose_detected=pose_result.is_valid,
        )

    def reset(self) -> None:
        """Reset analysis state (e.g., when starting new session)."""
        if self._engine:
            self._engine.reset()

    def close(self) -> None:
        """Release resources."""
        self._pose_estimator.close()
        self._initialized = False

    @property
    def is_initialized(self) -> bool:
        """Check if system is ready."""
        return self._initialized

    @property
    def current_exercise(self) -> str:
        """Get currently selected exercise."""
        return self._current_exercise
