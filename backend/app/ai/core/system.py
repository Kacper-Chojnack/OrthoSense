"""OrthoSense AI System - processes landmarks from client-side ML Kit."""

from pathlib import Path

import numpy as np

from app.ai.core.diagnostics import ReportGenerator
from app.ai.core.engine import OrthoSensePredictor
from app.ai.core.integrity import ModelIntegrityError, verify_model_integrity
from app.core.logging import get_logger

logger = get_logger(__name__)

# Default models directory (can be overridden via environment)
MODELS_DIR = Path(__file__).parent.parent.parent.parent.parent / "assets" / "models"


class OrthoSenseSystem:
    """Singleton AI coordinator - analyzes pose landmarks."""

    _instance: "OrthoSenseSystem | None" = None
    engine: "OrthoSensePredictor"
    reporter: "ReportGenerator"
    _initialized: bool

    def __new__(cls) -> "OrthoSenseSystem":
        if cls._instance is None:
            cls._instance = super().__new__(cls)
            cls._instance.engine = OrthoSensePredictor()
            cls._instance.reporter = ReportGenerator()
            cls._instance._initialized = False
            cls._instance._models_verified = False
        return cls._instance

    def initialize(self, *, verify_models: bool = True) -> bool:
        """Init system. Verifies model integrity if enabled."""
        if verify_models and not self._models_verified:
            self._verify_models()
        self._initialized = True
        return True

    def _verify_models(self) -> None:
        """Check model file integrity."""
        model_path = MODELS_DIR / "exercise_classifier.tflite"
        if model_path.exists():
            try:
                verify_model_integrity(model_path)
                self._models_verified = True
                logger.info("model_integrity_ok")
            except ModelIntegrityError as e:
                logger.error("model_integrity_fail", error=str(e))
                raise
        else:
            # model loaded on demand
            logger.warning("model_missing", path=str(model_path))
            self._models_verified = True

    @property
    def is_initialized(self) -> bool:
        return self._initialized

    def close(self) -> None:
        self._initialized = False

    def analyze_landmarks(
        self, landmarks: list[list[list[float]]], exercise_name: str
    ) -> dict:
        """Main entry - takes landmark frames, returns analysis dict."""
        if not landmarks:
            return {"error": "No landmarks provided"}

        self.engine.reset()

        frames = []
        vis_flags = []

        # key joints for visibility
        key_idx = [11, 12, 23, 24, 25, 26, 27, 28]
        min_vis = 0.5

        for frame in landmarks:
            if len(frame) != 33:
                vis_flags.append(False)
                continue

            has_vis = len(frame) > 0 and len(frame[0]) >= 4
            frame_arr = np.array([j[:3] for j in frame], dtype=np.float32)
            frames.append(frame_arr)

            # check key joints visibility
            if has_vis:
                vis_cnt = sum(
                    1
                    for idx in key_idx
                    if idx < len(frame)
                    and len(frame[idx]) > 3
                    and frame[idx][3] >= min_vis
                )
            else:
                vis_cnt = sum(
                    1
                    for idx in key_idx
                    if idx < len(frame) and any(abs(c) > 0.0001 for c in frame[idx][:3])
                )

            vis_flags.append(vis_cnt >= 6)

        if not frames:
            return {"error": "No valid landmarks"}

        result = self.engine.analyze(frames, exercise_name=exercise_name)

        report = self.reporter.generate_report(
            (result["is_correct"], result["feedback"]),
            exercise_name,
        )

        out = {
            "exercise": exercise_name,
            "confidence": 1.0,
            "text_report": report,
            "is_correct": result["is_correct"],
            "feedback": result["feedback"],
        }

        return self._make_serializable(out)

    def _create_sliding_windows(
        self,
        frames: list,
        vis_flags: list,
        win_size: int = 60,
        step: int = 15,
    ) -> tuple[list, list]:
        """Create overlapping windows for analysis."""
        windows = []
        win_vis = []

        if len(frames) < win_size:
            windows.append(np.array(frames))
            win_vis.append(sum(vis_flags) >= len(vis_flags) * 0.7)
        else:
            for i in range(0, len(frames) - win_size, step):
                chunk = frames[i : i + win_size]
                windows.append(np.array(chunk))
                chunk_flags = vis_flags[i : i + win_size]
                win_vis.append(sum(chunk_flags) >= len(chunk_flags) * 0.7)

        return windows, win_vis

    def _classify_windows(self, windows: list, win_vis: list) -> list[str]:
        """Get exercise votes from each window."""
        votes = []
        for idx, win in enumerate(windows):
            if idx < len(win_vis) and not win_vis[idx]:
                continue

            res = self.engine.analyze(win)
            if res["confidence"] > 0.50 and res["exercise"] != "No Exercise Detected":
                votes.append(res["exercise"])

        return votes

    def _analyze_windows_detailed(
        self,
        windows: list,
        win_vis: list,
        exercise: str,
        frames: list,
    ) -> list[dict]:
        """Re-analyze with forced exercise for detailed feedback."""
        results = []

        for idx, win in enumerate(windows):
            if idx < len(win_vis) and not win_vis[idx]:
                continue
            res = self.engine.analyze(win, exercise_name=exercise)
            results.append(res)

        if not results and frames:
            res = self.engine.analyze(np.array(frames), exercise_name=exercise)
            results.append(res)

        return results

    def _make_serializable(self, obj):
        """Convert numpy types to JSON-safe python types."""
        if isinstance(obj, dict):
            return {k: self._make_serializable(v) for k, v in obj.items()}
        if isinstance(obj, list):
            return [self._make_serializable(x) for x in obj]
        if isinstance(obj, np.integer):
            return int(obj)
        if isinstance(obj, np.floating):
            return float(obj)
        if isinstance(obj, np.ndarray):
            return obj.tolist()
        return obj
