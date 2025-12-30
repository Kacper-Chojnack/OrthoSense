"""OrthoSense AI System - Video Analysis Only.

Real-time frame analysis has been removed for reimplementation.
This module now only supports video file analysis.
"""

import os
from collections import Counter
from dataclasses import dataclass, field
from uuid import uuid4

import numpy as np

from app.ai.core.diagnostics import ReportGenerator
from app.ai.core.engine import OrthoSensePredictor
from app.ai.core.pose_estimation import VideoProcessor


class OrthoSenseSystem:
    """
    OrthoSense AI System Coordinator (Singleton).

    Currently supports video file analysis only.
    Real-time frame analysis is disabled pending reimplementation.
    """

    _instance: "OrthoSenseSystem | None" = None

    WINDOW_SIZE = 60  

    processor: "VideoProcessor | None"
    engine: "OrthoSensePredictor"
    reporter: "ReportGenerator"
    _initialized: bool

    def __new__(cls) -> "OrthoSenseSystem":
        if cls._instance is None:
            cls._instance = super().__new__(cls)
            cls._instance.processor = None  
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

    def analyze_video_file(self, video_path: str) -> dict:
        """
        Analyze a full video file using a sliding window approach.

        This is the primary analysis method. Real-time frame analysis
        has been removed for reimplementation.

        Args:
            video_path: Path to the video file.

        Returns:
            Analysis result dict with exercise, confidence, feedback, and report.
        """
        if not os.path.exists(video_path):
            return {"error": "File not found"}

        if self.processor is None:
            self.processor = VideoProcessor(complexity=0)

        self.engine.reset()

        data_generator = self.processor.process_video_file(
            video_path, auto_rotate=False
        )
        raw_data_with_visibility = list(data_generator)

        if not raw_data_with_visibility:
            return {"error": "No person detected"}

        raw_data, visibility_flags = self._extract_landmarks_and_visibility(
            raw_data_with_visibility
        )

        if not raw_data:
            return {"error": "No person detected"}

        windows, window_visibility = self._create_sliding_windows(
            raw_data, visibility_flags
        )

        if not windows:
            return {"error": "Video too short or processing failed"}

        votes = self._classify_windows(windows, window_visibility)

        if not votes:
            return {"error": "No exercise detected with sufficient confidence."}

        vote_counts = Counter(votes)
        winner_exercise, winner_count = vote_counts.most_common(1)[0]
        voting_confidence = winner_count / len(votes)

        detailed_results = self._analyze_windows_detailed(
            windows, window_visibility, winner_exercise, raw_data
        )

        if not detailed_results:
            return {"error": "Analysis failed"}


        last_result = detailed_results[-1]
        analysis_tuple = (last_result["is_correct"], last_result["feedback"])
        text_report = self.reporter.generate_report(analysis_tuple, winner_exercise)

        final_result = {
            "exercise": winner_exercise,
            "confidence": voting_confidence,
            "text_report": text_report,
            "is_correct": last_result["is_correct"],
            "feedback": last_result["feedback"],
        }

        serialized = self._make_serializable(final_result)
        if isinstance(serialized, dict):
            return serialized
        return final_result

    def analyze_landmarks(self, landmarks: list[list[list[float]]]) -> dict:
        """
        Analyze pose landmarks directly (Edge AI mode).

        This method receives pre-extracted landmarks from the client device,
        eliminating the need for video processing on the server.

        Args:
            landmarks: List of frames, each containing 33 joints with [x, y, z] coordinates.
                     Format: frames × 33 joints × 3 coords
                     OR: frames × 33 joints × 4 coords (if visibility included as 4th element)

        Returns:
            Analysis result dict with exercise, confidence, feedback, and report.
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
                        if any(abs(c) > 0.01 for c in coords):
                            visible_count += 1
                
                is_visible = visible_count >= 6
                visibility_flags.append(is_visible)

        if not raw_data:
            return {"error": "No valid landmarks detected"}

        windows, window_visibility = self._create_sliding_windows(
            raw_data, visibility_flags
        )

        if not windows:
            return {"error": "Video too short or processing failed"}

        votes = self._classify_windows(windows, window_visibility)

        if not votes:
            return {"error": "No exercise detected with sufficient confidence."}

        vote_counts = Counter(votes)
        winner_exercise, winner_count = vote_counts.most_common(1)[0]
        voting_confidence = winner_count / len(votes)

        detailed_results = self._analyze_windows_detailed(
            windows, window_visibility, winner_exercise, raw_data
        )

        if not detailed_results:
            return {"error": "Analysis failed"}

        last_result = detailed_results[-1]
        analysis_tuple = (last_result["is_correct"], last_result["feedback"])
        text_report = self.reporter.generate_report(analysis_tuple, winner_exercise)

        final_result = {
            "exercise": winner_exercise,
            "confidence": voting_confidence,
            "text_report": text_report,
            "is_correct": last_result["is_correct"],
            "feedback": last_result["feedback"],
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
            return [self._make_serializable(i) for i in obj]
        if isinstance(obj, np.integer):
            return int(obj)
        if isinstance(obj, np.floating):
            return float(obj)
        if isinstance(obj, np.ndarray):
            return obj.tolist()
        return obj
