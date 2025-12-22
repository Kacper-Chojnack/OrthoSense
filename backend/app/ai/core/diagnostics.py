"""Real-time diagnostics engine for exercise form feedback."""

from dataclasses import dataclass
from enum import Enum
from typing import TYPE_CHECKING

import numpy as np

from app.ai.core.config import AngleThresholds
from app.core.logging import get_logger

if TYPE_CHECKING:
    from app.ai.core.pose_estimation import PoseResult

logger = get_logger(__name__)

DEFAULT_FEEDBACK = "Good form!"


class ExerciseType(Enum):
    """Supported exercise types for diagnostics."""

    DEEP_SQUAT = 0
    HURDLE_STEP = 1
    SHOULDER_ABDUCTION = 2


class LandmarkIndex:
    """MediaPipe pose landmark indices."""

    NOSE = 0
    LEFT_SHOULDER = 11
    RIGHT_SHOULDER = 12
    LEFT_ELBOW = 13
    RIGHT_ELBOW = 14
    LEFT_WRIST = 15
    RIGHT_WRIST = 16
    LEFT_HIP = 23
    RIGHT_HIP = 24
    LEFT_KNEE = 25
    RIGHT_KNEE = 26
    LEFT_ANKLE = 27
    RIGHT_ANKLE = 28


@dataclass
class DiagnosticResult:
    """Result of form analysis for a single frame."""

    feedback: str
    voice_message: str
    is_correct: bool
    angles: dict[str, float]
    score: float  # 0-100


class DiagnosticsEngine:
    """Analyzes exercise form and provides real-time feedback."""

    def __init__(self, exercise_type: ExerciseType | None = None) -> None:
        """Initialize diagnostics for specific exercise.

        Args:
            exercise_type: Type of exercise to analyze.
        """
        self._exercise_type = exercise_type or ExerciseType.DEEP_SQUAT
        self._last_feedback = ""
        self._feedback_cooldown = 0

    def set_exercise(self, exercise_type: ExerciseType) -> None:
        """Change the exercise being analyzed."""
        self._exercise_type = exercise_type
        self._last_feedback = ""
        self._feedback_cooldown = 0

    def analyze(self, pose_result: "PoseResult") -> DiagnosticResult:
        """Analyze pose and generate feedback.

        Args:
            pose_result: Current frame pose landmarks.

        Returns:
            DiagnosticResult with feedback and scores.
        """
        if not pose_result.is_valid:
            return DiagnosticResult(
                feedback="No pose detected - ensure full body is visible",
                voice_message="",
                is_correct=False,
                angles={},
                score=0.0,
            )

        landmarks = pose_result.landmarks

        # Calculate relevant angles
        angles = self._calculate_angles(landmarks)

        # Generate exercise-specific feedback
        if self._exercise_type == ExerciseType.DEEP_SQUAT:
            return self._analyze_squat(angles)
        elif self._exercise_type == ExerciseType.HURDLE_STEP:
            return self._analyze_hurdle_step(angles)
        elif self._exercise_type == ExerciseType.SHOULDER_ABDUCTION:
            return self._analyze_shoulder_abduction(angles)

        return DiagnosticResult(
            feedback="",
            voice_message="",
            is_correct=True,
            angles=angles,
            score=50.0,
        )

    def _calculate_angles(self, landmarks: list) -> dict[str, float]:
        """Calculate joint angles from landmarks."""
        angles: dict[str, float] = {}

        try:
            # Extract key points as numpy arrays
            l_hip = self._get_point(landmarks, LandmarkIndex.LEFT_HIP)
            r_hip = self._get_point(landmarks, LandmarkIndex.RIGHT_HIP)
            l_knee = self._get_point(landmarks, LandmarkIndex.LEFT_KNEE)
            r_knee = self._get_point(landmarks, LandmarkIndex.RIGHT_KNEE)
            l_ankle = self._get_point(landmarks, LandmarkIndex.LEFT_ANKLE)
            r_ankle = self._get_point(landmarks, LandmarkIndex.RIGHT_ANKLE)
            l_shoulder = self._get_point(landmarks, LandmarkIndex.LEFT_SHOULDER)
            r_shoulder = self._get_point(landmarks, LandmarkIndex.RIGHT_SHOULDER)
            l_elbow = self._get_point(landmarks, LandmarkIndex.LEFT_ELBOW)
            r_elbow = self._get_point(landmarks, LandmarkIndex.RIGHT_ELBOW)

            # Knee flexion angles
            angles["left_knee"] = self._calculate_angle(l_hip, l_knee, l_ankle)
            angles["right_knee"] = self._calculate_angle(r_hip, r_knee, r_ankle)

            # Hip flexion angles
            angles["left_hip"] = self._calculate_angle(l_shoulder, l_hip, l_knee)
            angles["right_hip"] = self._calculate_angle(r_shoulder, r_hip, r_knee)

            # Shoulder abduction (arm raise)
            hip_mid = (l_hip + r_hip) / 2
            angles["left_shoulder_abduction"] = self._calculate_angle(
                hip_mid, l_shoulder, l_elbow
            )
            angles["right_shoulder_abduction"] = self._calculate_angle(
                hip_mid, r_shoulder, r_elbow
            )

            # Trunk lean (vertical alignment)
            shoulder_mid = (l_shoulder + r_shoulder) / 2
            vertical = shoulder_mid + np.array([0, -1, 0])
            angles["trunk_lean"] = self._calculate_angle(
                hip_mid, shoulder_mid, vertical
            )

        except (IndexError, TypeError) as e:
            logger.debug("angle_calculation_error", error=str(e))

        return angles

    def _get_point(self, landmarks: list, index: int) -> np.ndarray:
        """Extract 3D point from landmarks."""
        lm = landmarks[index]
        return np.array([lm.x, lm.y, lm.z])

    def _calculate_angle(
        self, point_a: np.ndarray, point_b: np.ndarray, point_c: np.ndarray
    ) -> float:
        """Calculate angle at point_b between vectors BA and BC."""
        ba = point_a - point_b
        bc = point_c - point_b

        norm_ba = np.linalg.norm(ba)
        norm_bc = np.linalg.norm(bc)

        if norm_ba == 0 or norm_bc == 0:
            return 0.0

        cosine = np.dot(ba, bc) / (norm_ba * norm_bc + 1e-6)
        angle = np.arccos(np.clip(cosine, -1.0, 1.0))
        return float(np.degrees(angle))

    def _analyze_squat(self, angles: dict[str, float]) -> DiagnosticResult:
        """Analyze deep squat form."""
        issues: list[str] = []
        score = 100.0

        left_knee = angles.get("left_knee", 180)
        right_knee = angles.get("right_knee", 180)
        trunk_lean = angles.get("trunk_lean", 0)

        avg_knee = (left_knee + right_knee) / 2

        # Check knee flexion
        if avg_knee > AngleThresholds.SQUAT_KNEE_MAX:
            issues.append("Go deeper - bend your knees more")
            score -= 30
        elif avg_knee < AngleThresholds.SQUAT_KNEE_MIN:
            issues.append("Good depth!")

        # Check trunk lean
        if trunk_lean > AngleThresholds.SQUAT_BACK_MAX_LEAN:
            issues.append("Keep your back more upright")
            score -= 20

        # Check knee symmetry
        knee_diff = abs(left_knee - right_knee)
        if knee_diff > 15:
            issues.append("Keep knees even")
            score -= 15

        feedback = " | ".join(issues) if issues else DEFAULT_FEEDBACK
        voice_message = self._get_voice_message(issues)

        return DiagnosticResult(
            feedback=feedback,
            voice_message=voice_message,
            is_correct=len(issues) == 0 or "Good" in feedback,
            angles=angles,
            score=max(0, score),
        )

    def _analyze_hurdle_step(self, angles: dict[str, float]) -> DiagnosticResult:
        """Analyze hurdle step form."""
        issues: list[str] = []
        score = 100.0

        left_hip = angles.get("left_hip", 180)
        right_hip = angles.get("right_hip", 180)

        # Detect which leg is raised (lower hip angle = raised leg)
        raised_hip = min(left_hip, right_hip)

        if raised_hip > AngleThresholds.HURDLE_HIP_MIN:
            issues.append("Lift your knee higher")
            score -= 30

        trunk_lean = angles.get("trunk_lean", 0)
        if trunk_lean > 20:
            issues.append("Keep your torso upright")
            score -= 20

        feedback = " | ".join(issues) if issues else DEFAULT_FEEDBACK
        voice_message = self._get_voice_message(issues)

        return DiagnosticResult(
            feedback=feedback,
            voice_message=voice_message,
            is_correct=len(issues) == 0,
            angles=angles,
            score=max(0, score),
        )

    def _analyze_shoulder_abduction(self, angles: dict[str, float]) -> DiagnosticResult:
        """Analyze shoulder abduction form."""
        issues: list[str] = []
        score = 100.0

        left_abd = angles.get("left_shoulder_abduction", 0)
        right_abd = angles.get("right_shoulder_abduction", 0)

        avg_abduction = (left_abd + right_abd) / 2

        if avg_abduction < AngleThresholds.SHOULDER_ABDUCTION_MIN:
            issues.append("Raise your arms higher")
            score -= 30
        elif avg_abduction > AngleThresholds.SHOULDER_ABDUCTION_MAX:
            issues.append("Arms slightly too high")
            score -= 10

        # Check symmetry
        abd_diff = abs(left_abd - right_abd)
        if abd_diff > 15:
            issues.append("Keep arms at same height")
            score -= 20

        feedback = " | ".join(issues) if issues else DEFAULT_FEEDBACK
        voice_message = self._get_voice_message(issues)

        return DiagnosticResult(
            feedback=feedback,
            voice_message=voice_message,
            is_correct=len(issues) == 0,
            angles=angles,
            score=max(0, score),
        )

    def _get_voice_message(self, issues: list[str]) -> str:
        """Generate voice message with cooldown to avoid spam."""
        if not issues:
            return ""

        # Return first issue as voice feedback
        message = issues[0]

        # Avoid repeating same message
        if message == self._last_feedback:
            self._feedback_cooldown += 1
            if self._feedback_cooldown < 10:  # ~1.5 seconds at 150ms per frame
                return ""
            self._feedback_cooldown = 0

        self._last_feedback = message
        return message
