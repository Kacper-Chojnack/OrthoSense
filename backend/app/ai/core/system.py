import numpy as np
import os
import time
from pathlib import Path
from collections import Counter
from dataclasses import dataclass

from app.ai.core.pose_estimation import VideoProcessor
from app.ai.core.engine import OrthoSensePredictor
from app.ai.core.diagnostics import ReportGenerator


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

    def to_dict(self):
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


class OrthoSenseSystem:
    _instance = None

    def __new__(cls):
        if cls._instance is None:
            cls._instance = super(OrthoSenseSystem, cls).__new__(cls)
            cls._instance.processor = VideoProcessor(complexity=0)
            cls._instance.engine = OrthoSensePredictor()
            cls._instance.reporter = ReportGenerator()
            cls._instance._initialized = False
            cls._instance._current_exercise = "Deep Squat"
            cls._instance._frame_buffer = []
            cls._instance._session_start_time = None
            cls._instance._locked_exercise = None
            cls._instance._calibration_votes = []
            cls._instance._frame_count = 0
            cls._instance.TIME_SETUP = 5.0
            cls._instance.TIME_CALIBRATION = 10.0  
            cls._instance.PREDICTION_INTERVAL = 5 
        return cls._instance

    def initialize(self):
        """Initialize the system."""
        self._initialized = True
        return True

    def set_exercise(self, exercise_name: str) -> bool:
        """Set the current exercise."""
        from app.ai.core.config import EXERCISE_NAMES
        if exercise_name in EXERCISE_NAMES.values():
            self._current_exercise = exercise_name
            return True
        return False

    def analyze_frame(self, frame: np.ndarray):
        """Analyze a single frame for WebSocket endpoint.
        """
        if self._session_start_time is None:
            self._session_start_time = time.time()
            self._locked_exercise = None
            self._calibration_votes = []
            self._frame_count = 0
        
        frame_rgb = frame[..., ::-1].copy() 
        world_landmarks, image_landmarks, is_visible = self.processor.process_frame(frame_rgb)
        
        if world_landmarks is None:
            return FrameAnalysisResult(
                feedback="No pose detected - ensure full body is visible",
                voice_message="",
                is_correct=False,
                score=0.0,
                angles={},
                pose_detected=False,
            )
        
        if not hasattr(self, '_visibility_buffer'):
            self._visibility_buffer = []
        
        self._frame_buffer.append(world_landmarks)
        self._visibility_buffer.append(is_visible)
        self._frame_count += 1
        
        if len(self._frame_buffer) > 60:
            self._frame_buffer = self._frame_buffer[-60:]
            self._visibility_buffer = self._visibility_buffer[-60:]
        
        elapsed_time = time.time() - self._session_start_time
        if elapsed_time < self.TIME_SETUP:
            phase = "SETUP"
            
            return FrameAnalysisResult(
                feedback="Get ready",
                voice_message="Get ready",
                is_correct=True,
                score=50.0,
                angles={},
                frames_buffered=len(self._frame_buffer),
                frames_needed=60,
                pose_detected=True,
            )
        elif elapsed_time < self.TIME_CALIBRATION:
            phase = "CALIBRATION"
            
            if len(self._frame_buffer) >= 30 and self._frame_count % self.PREDICTION_INTERVAL == 0:
                visible_count = sum(self._visibility_buffer[-30:])
                visibility_ratio = visible_count / 30.0
                
                if visibility_ratio >= 0.7 and is_visible:
                    result = self.engine.analyze(np.array(self._frame_buffer[-30:]), forced_exercise_name=None)
                    ex_name = result.get('exercise', '')
                    if ex_name != "No Exercise Detected" and result.get('confidence', 0.0) > 0.0:
                        self._calibration_votes.append(ex_name)
            
            return FrameAnalysisResult(
                feedback="Analyzing",
                voice_message="Analyzing exercise",
                is_correct=True,
                score=50.0,
                angles={},
                frames_buffered=len(self._frame_buffer),
                frames_needed=60,
                pose_detected=True,
            )
        else:
            phase = "TRAINING"
            
            if self._locked_exercise is None:
                if self._calibration_votes:
                    most_common = Counter(self._calibration_votes).most_common(1)
                    if most_common:
                        self._locked_exercise = most_common[0][0]
                else:
                    self._session_start_time = time.time() - self.TIME_SETUP
                    self._calibration_votes = []

                    elapsed_time = time.time() - self._session_start_time
                    if elapsed_time < self.TIME_CALIBRATION:
                        return FrameAnalysisResult(
                            feedback="Analyzing",
                            voice_message="Please perform an exercise",
                            is_correct=True,
                            score=50.0,
                            angles={},
                            frames_buffered=len(self._frame_buffer),
                            frames_needed=30,
                            pose_detected=True,
                        )
            
            if len(self._frame_buffer) >= 30:
                visible_count = sum(self._visibility_buffer[-30:])
                visibility_ratio = visible_count / 30.0
                
                if visibility_ratio < 0.7:
                    return FrameAnalysisResult(
                        feedback="Insufficient body visibility - ensure full body is visible",
                        voice_message="Position yourself so your full body is visible",
                        is_correct=False,
                        score=0.0,
                        angles={},
                        frames_buffered=len(self._frame_buffer),
                        frames_needed=30,
                        pose_detected=True,
                    )
                
                result = self.engine.analyze(
                    np.array(self._frame_buffer[-30:]), 
                    forced_exercise_name=self._locked_exercise
                )
                
                return FrameAnalysisResult(
                    feedback=result.get('feedback', ''),
                    voice_message=result.get('feedback', ''),
                    is_correct=result.get('is_correct', True),
                    score=100.0 if result.get('is_correct', True) else 50.0,
                    angles={},
                    classification={
                        "exercise_name": self._locked_exercise,
                        "confidence": 1.0,
                    },
                    frames_buffered=len(self._frame_buffer),
                    frames_needed=30,
                    pose_detected=True,
                )
            else:
                return FrameAnalysisResult(
                    feedback=f"Collecting frames... {len(self._frame_buffer)}/30",
                    voice_message="",
                    is_correct=True,
                    score=50.0,
                    angles={},
                    frames_buffered=len(self._frame_buffer),
                    frames_needed=30,
                    pose_detected=True,
                )

    def reset(self):
        """Reset analysis state."""
        self._frame_buffer = []
        if hasattr(self, '_visibility_buffer'):
            self._visibility_buffer = []
        self._session_start_time = None
        self._locked_exercise = None
        self._calibration_votes = []
        self._frame_count = 0

    def close(self):
        """Release resources."""
        self._initialized = False
        self._frame_buffer = []

    @property
    def is_initialized(self) -> bool:
        """Check if system is initialized."""
        return self._initialized

    @property
    def current_exercise(self) -> str:
        """Get currently selected exercise."""
        return self._current_exercise

    def analyze_live_frame(self, frame_sequence, forced_exercise=None):
        """
        Analyze a single sliding window of frames from the live camera stream.
        """

        raw_array = np.array(frame_sequence)
        result = self.engine.analyze(raw_array, forced_exercise_name=forced_exercise)
        return result

    def analyze_video_file(self, video_path):        
        """
        Analyze a full video file using a sliding window over the entire recording.
        """

        if not os.path.exists(video_path):
            return {"error": "File not found"}

        self.engine.reset()
        
        data_generator = self.processor.process_video_file(video_path, auto_rotate=False)
        raw_data_with_visibility = list(data_generator)
        
        if not raw_data_with_visibility or len(raw_data_with_visibility) == 0:
            return {"error": "No person detected"}
        
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
        
        if not raw_data or len(raw_data) == 0:
            return {"error": "No person detected"}
        
        WINDOW_SIZE = 60
        STEP = 15 
        
        windows = []
        window_visibility = []
        
        if len(raw_data) < WINDOW_SIZE:
             windows.append(np.array(raw_data))
             window_vis = sum(visibility_flags) >= len(visibility_flags) * 0.7
             window_visibility.append(window_vis)
        else:
            for i in range(0, len(raw_data) - WINDOW_SIZE, STEP):
                chunk = raw_data[i : i + WINDOW_SIZE]
                windows.append(np.array(chunk))
                chunk_vis_flags = visibility_flags[i : i + WINDOW_SIZE]
                window_vis = sum(chunk_vis_flags) >= len(chunk_vis_flags) * 0.7
                window_visibility.append(window_vis)

        if not windows:
            return {"error": "Video too short or processing failed"}

        votes = []
        window_results = []
        skipped_windows = 0
        
        for idx, window_array in enumerate(windows):
            is_visible = window_visibility[idx] if idx < len(window_visibility) else True
            
            if not is_visible:
                skipped_windows += 1
                window_results.append((idx, "SKIPPED", 0.0))
                continue
            
            res = self.engine.analyze(window_array)
            window_results.append((idx, res['exercise'], res['confidence']))
            
            if res['confidence'] > 0.50 and res['exercise'] != "No Exercise Detected":
                votes.append(res['exercise'])

        print(f"\n[DEBUG] All window predictions ({len(windows)} windows, {skipped_windows} skipped):")
        for idx, ex, conf in window_results:
            if ex == "SKIPPED":
                print(f"  Window {idx+1}: SKIPPED [Insufficient body visibility]")
            else:
                status = "OK" if conf > 0.50 and ex != "No Exercise Detected" else "REJECTED"
                print(f"  Window {idx+1}: {ex} ({conf*100:.1f}%) [{status}]")
        
        if not votes:
            return {"error": "No exercise detected with sufficient confidence."}

        vote_counts = Counter(votes)
        print(f"\n[DEBUG] Vote summary:")
        for ex, count in vote_counts.most_common():
            print(f"  {ex}: {count} votes ({count/len(votes)*100:.1f}%)")
        
        top_result = vote_counts.most_common(1)[0]
        
        winner_exercise = top_result[0]     
        winner_count = top_result[1]        
        total_valid_votes = len(votes)      
        
        voting_confidence = winner_count / total_valid_votes
        print(f"\n[DEBUG] Winner: {winner_exercise} ({voting_confidence*100:.1f}% of votes)")

        detailed_results = []
        
        for idx, window_array in enumerate(windows):
            is_visible = window_visibility[idx] if idx < len(window_visibility) else True
            if not is_visible:
                continue
                
            res = self.engine.analyze(window_array, forced_exercise_name=winner_exercise)
            detailed_results.append(res)
        
        if not detailed_results and len(raw_data) > 0:
             res = self.engine.analyze(np.array(raw_data), forced_exercise_name=winner_exercise)
             detailed_results.append(res)

        if not detailed_results:
             return {"error": "Analysis failed"}

        text_report = self.reporter.generate_report(detailed_results)
        
        final_result = {
            "exercise": winner_exercise,
            "confidence": voting_confidence, 
            "text_report": text_report,
            "is_correct": detailed_results[-1]['is_correct'], 
            "feedback": detailed_results[-1]['feedback']
        }
        
        return self._make_serializable(final_result)

    def _make_serializable(self, obj):
        """Helper to convert NumPy types to plain Python types."""
        
        if isinstance(obj, dict):
            return {k: self._make_serializable(v) for k, v in obj.items()}
        elif isinstance(obj, list):
            return [self._make_serializable(v) for v in obj]
        elif isinstance(obj, np.integer):
            return int(obj)
        elif isinstance(obj, np.floating):
            return float(obj)
        elif isinstance(obj, np.ndarray):
            return obj.tolist()
        else:
            return obj
