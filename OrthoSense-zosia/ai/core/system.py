import numpy as np
import os
from pathlib import Path
from collections import Counter

from core.pose_estimation import VideoProcessor
from core.engine import OrthoSensePredictor
from core.diagnostics import ReportGenerator


class OrthoSenseSystem:
    _instance = None

    def __new__(cls):
        if cls._instance is None:
            cls._instance = super(OrthoSenseSystem, cls).__new__(cls)
            cls._instance.processor = VideoProcessor(complexity=0)
            cls._instance.engine = OrthoSensePredictor()
            cls._instance.reporter = ReportGenerator()
        return cls._instance

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
        raw_data = list(data_generator)
        
        if not raw_data or len(raw_data) == 0:
            return {"error": "No person detected"}
        
        WINDOW_SIZE = 60
        STEP = 15 
        
        windows = []
        
        if len(raw_data) < WINDOW_SIZE:
             windows.append(np.array(raw_data))
        else:
            for i in range(0, len(raw_data) - WINDOW_SIZE, STEP):
                chunk = raw_data[i : i + WINDOW_SIZE]
                windows.append(np.array(chunk))

        if not windows:
            return {"error": "Video too short or processing failed"}

        votes = []
        window_results = []
        
        for idx, window_array in enumerate(windows):
            res = self.engine.analyze(window_array)
            window_results.append((idx, res['exercise'], res['confidence']))
            
            if res['confidence'] > 0.50 and res['exercise'] != "No Exercise Detected":
                votes.append(res['exercise'])

        print(f"\n[DEBUG] All window predictions ({len(windows)} windows):")
        for idx, ex, conf in window_results:
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
        
        for window_array in windows:
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
