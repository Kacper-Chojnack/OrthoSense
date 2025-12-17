import numpy as np
import os
from pathlib import Path
from typing import List, Dict, Any

from core.pose_estimation import VideoProcessor 
from core.engine import OrthoSensePredictor
from core.diagnostics import ReportGenerator
from collections import Counter


class OrthoSenseSystem:
    _instance = None

    def __new__(cls):
        if cls._instance is None:
            print("Initializing OrthoSense Core System...")
            cls._instance = super(OrthoSenseSystem, cls).__new__(cls)
            
            cls._instance.processor = VideoProcessor(complexity=1)
            cls._instance.engine = OrthoSensePredictor()
            cls._instance.reporter = ReportGenerator()
            
            print("OrthoSense Core Ready.")
        return cls._instance

    def analyze_live_frame(self, frame_sequence, forced_exercise=None):
        raw_array = np.array(frame_sequence)
        
        input_seq = np.expand_dims(raw_array, axis=0)

        result = self.engine.analyze(raw_array, input_seq, forced_exercise_name=forced_exercise)
        
        return result

    def analyze_video_file(self, video_path):        
        if not os.path.exists(video_path):
            return {"error": "File not found"}

        print(f"Processing video: {os.path.basename(video_path)}...")

        self.engine.reset()
        
        data_generator = self.processor.process_video_file(video_path)
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

        print("Classifying exercise...")
        votes = []
        
        for window_array in windows:
            if window_array.shape[0] == WINDOW_SIZE:
                input_seq = np.expand_dims(window_array, axis=0) 
                
                res = self.engine.analyze(window_array, input_seq)
                
                if res['confidence'] > 0.50 and res['exercise'] != "No Exercise Detected":
                    votes.append(res['exercise'])

        if not votes:
            return {"error": "No exercise detected with sufficient confidence."}

        winner_exercise = Counter(votes).most_common(1)[0][0]
        print(f"Exercise Locked: {winner_exercise}")

        print(f"Analyzing form for '{winner_exercise}'...")
        detailed_results = []
        
        for window_array in windows:
            if window_array.shape[0] == WINDOW_SIZE:
                input_seq = np.expand_dims(window_array, axis=0) 
                
                res = self.engine.analyze(window_array, input_seq, forced_exercise_name=winner_exercise)
                
                detailed_results.append(res)
        
        if not detailed_results and len(raw_data) < WINDOW_SIZE:
             sequences = self.processor.prepare_sequences_for_model(raw_data)
             res = self.engine.analyze(raw_data, sequences, forced_exercise_name=winner_exercise)
             detailed_results.append(res)

        if not detailed_results:
             return {"error": "Analysis failed in Phase 2"}

        text_report = self.reporter.generate_report(detailed_results)
        
        final_result = {
            "exercise": winner_exercise,
            "confidence": 1.0, 
            "text_report": text_report,
            "is_correct": detailed_results[-1]['is_correct'], 
            "feedback": detailed_results[-1]['feedback']
        }
        
        return self._make_serializable(final_result)

    def _make_serializable(self, obj):
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

    def _convert_mediapipe_to_kinect(self, landmarks: List[Dict]) -> np.ndarray:
        """
        Converts 33 MediaPipe landmarks to 25 Kinect v2 joint format.
        
        Args:
            landmarks: List of 33 landmark dicts with x, y, z, visibility keys
            
        Returns:
            numpy array of shape (25, 3) representing Kinect joints
        """
        def get_pos(idx: int) -> np.ndarray:
            lm = landmarks[idx]
            return np.array([lm['x'], lm['y'], lm['z']])

        # Hip landmarks
        l_hip = get_pos(23)
        r_hip = get_pos(24)
        spine_base = (l_hip + r_hip) / 2.0

        # Shoulder landmarks
        l_shoulder = get_pos(11)
        r_shoulder = get_pos(12)
        spine_shoulder = (l_shoulder + r_shoulder) / 2.0

        # Spine calculations
        spine_mid = (spine_base + spine_shoulder) / 2.0
        neck = spine_shoulder + (spine_shoulder - spine_mid) * 0.3
        head = (get_pos(7) + get_pos(8)) / 2.0  # Mid-point of ears

        # Build Kinect 25-joint skeleton (same order as pose_estimation.py)
        kinect_joints = [
            spine_base,           # 0: Spine Base
            spine_mid,            # 1: Spine Mid
            neck,                 # 2: Neck
            head,                 # 3: Head
            l_shoulder,           # 4: Shoulder Left
            get_pos(13),          # 5: Elbow Left
            get_pos(15),          # 6: Wrist Left
            get_pos(19),          # 7: Hand Left (index finger)
            r_shoulder,           # 8: Shoulder Right
            get_pos(14),          # 9: Elbow Right
            get_pos(16),          # 10: Wrist Right
            get_pos(20),          # 11: Hand Right (index finger)
            l_hip,                # 12: Hip Left
            get_pos(25),          # 13: Knee Left
            get_pos(27),          # 14: Ankle Left
            get_pos(31),          # 15: Foot Left
            r_hip,                # 16: Hip Right
            get_pos(26),          # 17: Knee Right
            get_pos(28),          # 18: Ankle Right
            get_pos(32),          # 19: Foot Right
            spine_shoulder,       # 20: Spine Shoulder
            get_pos(17),          # 21: Hand Tip Left (pinky)
            get_pos(21),          # 22: Thumb Left
            get_pos(18),          # 23: Hand Tip Right (pinky)
            get_pos(22),          # 24: Thumb Right
        ]

        return np.array(kinect_joints)

    def analyze_session_data(self, session_data: List[Dict[str, Any]]) -> Dict[str, Any]:
        """
        Analyzes pre-processed landmark data from mobile app.
        
        Skips VideoProcessor entirely - data is already extracted on mobile.
        
        Args:
            session_data: List of frame dictionaries, each containing:
                - landmarks: List of 33 MediaPipe landmarks (x, y, z, visibility)
                - timestamp (optional): ISO timestamp string
                - confidence (optional): Detection confidence
                
        Returns:
            Dictionary with exercise analysis results:
                - exercise: Detected exercise name
                - confidence: Classification confidence
                - text_report: Detailed text report
                - is_correct: Boolean indicating correct form
                - feedback: Feedback message
        """
        # Validate input
        if not session_data or len(session_data) == 0:
            return {"error": "No session data provided"}

        # Convert each frame's MediaPipe landmarks to Kinect format
        raw_data = []
        for frame in session_data:
            landmarks = frame.get('landmarks', [])
            
            if len(landmarks) < 33:
                # Skip frames with insufficient landmarks
                continue
                
            try:
                kinect_skeleton = self._convert_mediapipe_to_kinect(landmarks)
                raw_data.append(kinect_skeleton)
            except (KeyError, IndexError) as e:
                # Skip malformed frames
                print(f"Warning: Skipping malformed frame: {e}")
                continue

        if not raw_data or len(raw_data) == 0:
            return {"error": "No valid landmarks detected in session data"}

        print(f"Processing {len(raw_data)} frames from mobile session...")

        # Reset engine state
        self.engine.reset()

        # Sliding window parameters (same as video analysis)
        WINDOW_SIZE = 60
        STEP = 15

        # Create windows
        windows = []
        if len(raw_data) < WINDOW_SIZE:
            windows.append(np.array(raw_data))
        else:
            for i in range(0, len(raw_data) - WINDOW_SIZE + 1, STEP):
                chunk = raw_data[i:i + WINDOW_SIZE]
                windows.append(np.array(chunk))

        if not windows:
            return {"error": "Insufficient data for analysis"}

        # Phase 1: Exercise classification via voting
        print("Classifying exercise...")
        votes = []

        for window_array in windows:
            if window_array.shape[0] == WINDOW_SIZE:
                input_seq = np.expand_dims(window_array, axis=0)
                res = self.engine.analyze(window_array, input_seq)

                if res['confidence'] > 0.50 and res['exercise'] != "No Exercise Detected":
                    votes.append(res['exercise'])

        # Handle short sessions (< WINDOW_SIZE frames)
        if not votes and len(raw_data) < WINDOW_SIZE:
            window_array = np.array(raw_data)
            input_seq = np.expand_dims(window_array, axis=0)
            res = self.engine.analyze(window_array, input_seq)
            if res['confidence'] > 0.40:
                votes.append(res['exercise'])

        if not votes:
            return {"error": "No exercise detected with sufficient confidence."}

        winner_exercise = Counter(votes).most_common(1)[0][0]
        print(f"Exercise Locked: {winner_exercise}")

        # Phase 2: Detailed form analysis
        print(f"Analyzing form for '{winner_exercise}'...")
        detailed_results = []

        for window_array in windows:
            if window_array.shape[0] == WINDOW_SIZE:
                input_seq = np.expand_dims(window_array, axis=0)
                res = self.engine.analyze(window_array, input_seq, forced_exercise_name=winner_exercise)
                detailed_results.append(res)

        # Handle short sessions
        if not detailed_results and len(raw_data) < WINDOW_SIZE:
            window_array = np.array(raw_data)
            input_seq = np.expand_dims(window_array, axis=0)
            res = self.engine.analyze(window_array, input_seq, forced_exercise_name=winner_exercise)
            detailed_results.append(res)

        if not detailed_results:
            return {"error": "Analysis failed during form evaluation"}

        # Generate report
        text_report = self.reporter.generate_report(detailed_results)

        final_result = {
            "exercise": winner_exercise,
            "confidence": 1.0,
            "text_report": text_report,
            "is_correct": detailed_results[-1]['is_correct'],
            "feedback": detailed_results[-1]['feedback']
        }

        return self._make_serializable(final_result)