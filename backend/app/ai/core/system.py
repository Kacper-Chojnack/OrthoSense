"""OrthoSense AI System - Landmarks Analysis Only.

Video processing has been offloaded to client-side (ML Kit).
This module now supports analysis of pre-extracted landmarks.
"""

from collections import Counter
import numpy as np

from app.ai.core.diagnostics import ReportGenerator
from app.ai.core.engine import OrthoSensePredictor


class OrthoSenseSystem:
    """
    OrthoSense AI System Coordinator (Singleton).
    Analyzes landmarks received from the client.
    """

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
        return cls._instance

    def initialize(self) -> bool:
        """Initialize the system resources."""
        self._initialized = True
        return True

    @property
    def is_initialized(self) -> bool:
        """Check if system is initialized."""
        return self._initialized

    def close(self) -> None:
        """Release resources."""
        self._initialized = False

    def analyze_landmarks(self, landmarks: list[list[list[float]]], exercise_name: str) -> dict:        
        """
        Analyze pose landmarks directly (Edge AI mode / ML Kit).
        """
        if not landmarks:
            return {"error": "No landmarks provided"}

        self.engine.reset()

        raw_data = []
        visibility_flags = []

        key_indices = [11, 12, 23, 24, 25, 26, 27, 28]
        min_visibility = 0.5

        for frame in landmarks:
            if len(frame) != 33:
                visibility_flags.append(False)
                continue

            has_visibility = len(frame) > 0 and len(frame[0]) >= 4
            
            frame_array = np.array([joint[:3] for joint in frame], dtype=np.float32)
            raw_data.append(frame_array)

            if has_visibility:
                visible_count = 0
                for idx in key_indices:
                    if idx < len(frame) and len(frame[idx]) > 3:
                        visibility = frame[idx][3]
                        if visibility >= min_visibility:
                            visible_count += 1
                
                is_visible = visible_count >= 6
                visibility_flags.append(is_visible)
            else:
                visible_count = 0
                for idx in key_indices:
                    if idx < len(frame):
                        coords = frame[idx][:3]
                        if any(abs(c) > 0.0001 for c in coords):
                            visible_count += 1
                
                is_visible = visible_count >= 6
                visibility_flags.append(is_visible)

        if not raw_data:
            return {"error": "No valid landmarks detected"}

        analysis_result = self.engine.analyze(raw_data, exercise_name=exercise_name)
        
        analysis_tuple = (analysis_result["is_correct"], analysis_result["feedback"])
        text_report = self.reporter.generate_report(analysis_tuple, exercise_name)

        final_result = {
            "exercise": exercise_name,
            "confidence": 1.0, 
            "text_report": text_report,
            "is_correct": analysis_result["is_correct"],
            "feedback": analysis_result["feedback"],
        }

        return self._make_serializable(final_result)

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
            return [self._make_serializable(i) for i in obj]
        if isinstance(obj, np.integer):
            return int(obj)
        if isinstance(obj, np.floating):
            return float(obj)
        if isinstance(obj, np.ndarray):
            return obj.tolist()
        return obj