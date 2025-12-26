import os
import time
from collections import Counter
from dataclasses import dataclass, field
from uuid import uuid4

import numpy as np

from app.ai.core.diagnostics import ReportGenerator
from app.ai.core.engine import OrthoSensePredictor
from app.ai.core.pose_estimation import VideoProcessor


@dataclass
class FrameAnalysisResult:
    """Compatibility wrapper for frame analysis results."""

    feedback: str
    voice_message: str
    is_correct: bool
    score: float
    angles: dict
    classification: dict | None = None
    frames_buffered: int = 0
    frames_needed: int = 60
    pose_detected: bool = False

    def to_dict(self) -> dict:
        """Convert to JSON-serializable dictionary."""
        result = {
            "feedback": self.feedback,
            "voice_message": self.voice_message,
            "is_correct": self.is_correct,
            "score": self.score,
            "angles": self.angles,
            "frames_buffered": self.frames_buffered,
            "frames_needed": self.frames_needed,
            "pose_detected": self.pose_detected,
        }
        if self.classification:
            result["classification"] = self.classification
        return result


@dataclass
class AnalysisSession:
    """
    Holds state for a single analysis session (User/WebSocket connection).

    Decouples per-user state from the Singleton AI System, enabling concurrent
    multi-user support without race conditions.
    """

    session_id: str = field(default_factory=lambda: str(uuid4()))
    frame_buffer: list = field(default_factory=list)
    visibility_buffer: list = field(default_factory=list)
    calibration_votes: list = field(default_factory=list)
    start_time: float = field(default_factory=time.time)
    frame_count: int = 0
    locked_exercise: str | None = None
    current_exercise: str = "Deep Squat"

    def reset(self) -> None:
        """Reset session state for a new analysis."""
        self.frame_buffer = []
        self.visibility_buffer = []
        self.calibration_votes = []
        self.start_time = time.time()
        self.frame_count = 0
        self.locked_exercise = None


class OrthoSenseSystem:
    """
    OrthoSense AI System Coordinator (Singleton).

    Architecture:
    - Manages heavy shared resources (ML models) as a Singleton.
    - All analysis methods require an `AnalysisSession` context for state.
    - Enables concurrent multi-user support without race conditions.
    """

    _instance: "OrthoSenseSystem | None" = None

    # Phase timing constants
    TIME_SETUP = 5.0
    TIME_CALIBRATION = 10.0
    PREDICTION_INTERVAL = 5

    # Instance attributes (initialized in __new__)
    processor: "VideoProcessor"
    engine: "OrthoSensePredictor"
    reporter: "ReportGenerator"
    _initialized: bool

    def __new__(cls) -> "OrthoSenseSystem":
        if cls._instance is None:
            cls._instance = super().__new__(cls)
            # Shared heavy resources (loaded once)
            cls._instance.processor = VideoProcessor(complexity=0)
            cls._instance.engine = OrthoSensePredictor()
            cls._instance.reporter = ReportGenerator()
            cls._instance._initialized = False
        return cls._instance

    def initialize(self) -> bool:
        """Initialize the system resources."""
        self._initialized = True
        return True

    def create_session(self, exercise: str = "Deep Squat") -> AnalysisSession:
        """Factory method to create a new isolated session for a user."""
        return AnalysisSession(current_exercise=exercise)

    def set_exercise(self, session: AnalysisSession, exercise_name: str) -> bool:
        """Set the current exercise for a specific session."""
        from app.ai.core.config import EXERCISE_NAMES

        if exercise_name in EXERCISE_NAMES.values():
            session.current_exercise = exercise_name
            session.reset()
            return True
        return False

    def analyze_frame(
        self, frame: np.ndarray, session: AnalysisSession
    ) -> FrameAnalysisResult:
        """
        Analyze a single frame within a specific session context.

        Args:
            frame: BGR image frame from camera/video.
            session: User-specific session holding state.

        Returns:
            FrameAnalysisResult with feedback and classification.
        """
        frame_rgb = frame[..., ::-1].copy()
        world_landmarks, _, is_visible = self.processor.process_frame(frame_rgb)

        if world_landmarks is None:
            return FrameAnalysisResult(
                feedback="No pose detected - ensure full body is visible",
                voice_message="",
                is_correct=False,
                score=0.0,
                angles={},
                pose_detected=False,
            )

        # Update session buffers
        session.frame_buffer.append(world_landmarks)
        session.visibility_buffer.append(is_visible)
        session.frame_count += 1

        # Maintain buffer size
        if len(session.frame_buffer) > 60:
            session.frame_buffer = session.frame_buffer[-60:]
            session.visibility_buffer = session.visibility_buffer[-60:]

        elapsed_time = time.time() - session.start_time

        # Phase 1: Setup
        if elapsed_time < self.TIME_SETUP:
            return FrameAnalysisResult(
                feedback="Get ready",
                voice_message="Get ready",
                is_correct=True,
                score=50.0,
                angles={},
                frames_buffered=len(session.frame_buffer),
                frames_needed=60,
                pose_detected=True,
            )

        # Phase 2: Calibration / Auto-detection
        if elapsed_time < self.TIME_CALIBRATION:
            self._run_calibration(session, is_visible)
            return FrameAnalysisResult(
                feedback="Analyzing",
                voice_message="Analyzing exercise",
                is_correct=True,
                score=50.0,
                angles={},
                frames_buffered=len(session.frame_buffer),
                frames_needed=60,
                pose_detected=True,
            )

        # Phase 3: Active Training
        return self._run_training_phase(session)

    def _run_calibration(self, session: AnalysisSession, is_visible: bool) -> None:
        """Run calibration phase to auto-detect exercise type."""
        if (
            len(session.frame_buffer) >= 30
            and session.frame_count % self.PREDICTION_INTERVAL == 0
        ):
            visible_count = sum(session.visibility_buffer[-30:])
            visibility_ratio = visible_count / 30.0

            if visibility_ratio >= 0.7 and is_visible:
                result = self.engine.analyze(
                    np.array(session.frame_buffer[-30:]), forced_exercise_name=None
                )
                ex_name = result.get("exercise", "")
                if (
                    ex_name != "No Exercise Detected"
                    and result.get("confidence", 0.0) > 0.0
                ):
                    session.calibration_votes.append(ex_name)

    def _run_training_phase(self, session: AnalysisSession) -> FrameAnalysisResult:
        """Run training phase with locked exercise."""
        # Lock exercise if not locked
        if session.locked_exercise is None:
            if session.calibration_votes:
                most_common = Counter(session.calibration_votes).most_common(1)
                if most_common:
                    session.locked_exercise = most_common[0][0]
            else:
                # Extend calibration phase
                session.start_time = time.time() - self.TIME_SETUP
                session.calibration_votes = []
                return FrameAnalysisResult(
                    feedback="Analyzing",
                    voice_message="Please perform an exercise",
                    is_correct=True,
                    score=50.0,
                    angles={},
                    frames_buffered=len(session.frame_buffer),
                    frames_needed=30,
                    pose_detected=True,
                )

        if len(session.frame_buffer) < 30:
            return FrameAnalysisResult(
                feedback=f"Collecting frames... {len(session.frame_buffer)}/30",
                voice_message="",
                is_correct=True,
                score=50.0,
                angles={},
                frames_buffered=len(session.frame_buffer),
                frames_needed=30,
                pose_detected=True,
            )

        # Check visibility
        visible_count = sum(session.visibility_buffer[-30:])
        visibility_ratio = visible_count / 30.0

        if visibility_ratio < 0.7:
            return FrameAnalysisResult(
                feedback="Insufficient body visibility - ensure full body is visible",
                voice_message="Position yourself so your full body is visible",
                is_correct=False,
                score=0.0,
                angles={},
                frames_buffered=len(session.frame_buffer),
                frames_needed=30,
                pose_detected=True,
            )

        # Run inference
        result = self.engine.analyze(
            np.array(session.frame_buffer[-30:]),
            forced_exercise_name=session.locked_exercise,
        )

        return FrameAnalysisResult(
            feedback=result.get("feedback", ""),
            voice_message=result.get("feedback", ""),
            is_correct=result.get("is_correct", True),
            score=100.0 if result.get("is_correct", True) else 50.0,
            angles={},
            classification={
                "exercise_name": session.locked_exercise,
                "confidence": 1.0,
            },
            frames_buffered=len(session.frame_buffer),
            frames_needed=30,
            pose_detected=True,
        )

    def reset(self) -> None:
        """Legacy reset - no-op since state is now in sessions."""
        pass

    def close(self) -> None:
        """Release resources."""
        self._initialized = False

    @property
    def is_initialized(self) -> bool:
        """Check if system is initialized."""
        return self._initialized

    def analyze_live_frame(
        self, frame_sequence: list, forced_exercise: str | None = None
    ) -> dict:
        """
        Analyze a single sliding window of frames (stateless).

        For direct inference without session management.
        """
        raw_array = np.array(frame_sequence)
        return self.engine.analyze(raw_array, forced_exercise_name=forced_exercise)

    def analyze_video_file(self, video_path: str) -> dict:
        """
        Analyze a full video file using a sliding window approach.

        This method is stateless - creates an isolated context for video analysis
        without affecting any active real-time sessions.

        Args:
            video_path: Path to the video file.

        Returns:
            Analysis result dict with exercise, confidence, feedback, and report.
        """
        if not os.path.exists(video_path):
            return {"error": "File not found"}

        self.engine.reset()

        # Extract landmarks from video
        data_generator = self.processor.process_video_file(
            video_path, auto_rotate=False
        )
        raw_data_with_visibility = list(data_generator)

        if not raw_data_with_visibility:
            return {"error": "No person detected"}

        # Separate landmarks and visibility flags
        raw_data, visibility_flags = self._extract_landmarks_and_visibility(
            raw_data_with_visibility
        )

        if not raw_data:
            return {"error": "No person detected"}

        # Create sliding windows
        windows, window_visibility = self._create_sliding_windows(
            raw_data, visibility_flags
        )

        if not windows:
            return {"error": "Video too short or processing failed"}

        # Phase 1: Classification voting
        votes = self._classify_windows(windows, window_visibility)

        if not votes:
            return {"error": "No exercise detected with sufficient confidence."}

        # Determine winner by majority vote
        vote_counts = Counter(votes)
        winner_exercise, winner_count = vote_counts.most_common(1)[0]
        voting_confidence = winner_count / len(votes)

        # Phase 2: Detailed analysis with locked exercise
        detailed_results = self._analyze_windows_detailed(
            windows, window_visibility, winner_exercise, raw_data
        )

        if not detailed_results:
            return {"error": "Analysis failed"}

        # Generate report
        text_report = self.reporter.generate_report(detailed_results)

        final_result = {
            "exercise": winner_exercise,
            "confidence": voting_confidence,
            "text_report": text_report,
            "is_correct": detailed_results[-1]["is_correct"],
            "feedback": detailed_results[-1]["feedback"],
        }

        serialized = self._make_serializable(final_result)
        if isinstance(serialized, dict):
            return serialized
        return final_result

    def _extract_landmarks_and_visibility(
        self, raw_data_with_visibility: list
    ) -> tuple[list, list]:
        """Extract landmarks and visibility flags from processor output."""
        raw_data = []
        visibility_flags = []

        for item in raw_data_with_visibility:
            if isinstance(item, tuple) and len(item) == 2:
                landmarks, is_visible = item
                raw_data.append(landmarks)
                visibility_flags.append(is_visible)
            else:
                raw_data.append(item)
                visibility_flags.append(True)

        return raw_data, visibility_flags

    def _create_sliding_windows(
        self,
        raw_data: list,
        visibility_flags: list,
        window_size: int = 60,
        step: int = 15,
    ) -> tuple[list, list]:
        """Create sliding windows from landmark data."""
        windows = []
        window_visibility = []

        if len(raw_data) < window_size:
            windows.append(np.array(raw_data))
            window_vis = sum(visibility_flags) >= len(visibility_flags) * 0.7
            window_visibility.append(window_vis)
        else:
            for i in range(0, len(raw_data) - window_size, step):
                chunk = raw_data[i : i + window_size]
                windows.append(np.array(chunk))
                chunk_vis_flags = visibility_flags[i : i + window_size]
                window_vis = sum(chunk_vis_flags) >= len(chunk_vis_flags) * 0.7
                window_visibility.append(window_vis)

        return windows, window_visibility

    def _classify_windows(self, windows: list, window_visibility: list) -> list[str]:
        """Classify windows and collect votes for exercise detection."""
        votes = []

        for idx, window_array in enumerate(windows):
            is_visible = (
                window_visibility[idx] if idx < len(window_visibility) else True
            )

            if not is_visible:
                continue

            res = self.engine.analyze(window_array)

            if res["confidence"] > 0.50 and res["exercise"] != "No Exercise Detected":
                votes.append(res["exercise"])

        return votes

    def _analyze_windows_detailed(
        self,
        windows: list,
        window_visibility: list,
        winner_exercise: str,
        raw_data: list,
    ) -> list[dict]:
        """Analyze windows with forced exercise for detailed feedback."""
        detailed_results = []

        for idx, window_array in enumerate(windows):
            is_visible = (
                window_visibility[idx] if idx < len(window_visibility) else True
            )
            if not is_visible:
                continue

            res = self.engine.analyze(
                window_array, forced_exercise_name=winner_exercise
            )
            detailed_results.append(res)

        # Fallback for very short videos
        if not detailed_results and len(raw_data) > 0:
            res = self.engine.analyze(
                np.array(raw_data), forced_exercise_name=winner_exercise
            )
            detailed_results.append(res)

        return detailed_results

    def _make_serializable(self, obj: object) -> dict | list | int | float | object:
        """Convert NumPy types to JSON-serializable Python types."""
        if isinstance(obj, dict):
            return {k: self._make_serializable(v) for k, v in obj.items()}
        if isinstance(obj, list):
            return [self._make_serializable(v) for v in obj]
        if isinstance(obj, np.integer):
            return int(obj)
        if isinstance(obj, np.floating):
            return float(obj)
        if isinstance(obj, np.ndarray):
            return obj.tolist()
        return obj
