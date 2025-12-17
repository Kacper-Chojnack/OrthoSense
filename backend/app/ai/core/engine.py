import os
import sys
import numpy as np
import tensorflow as tf
from collections import Counter
from pathlib import Path
from collections import deque

BASE_DIR = Path(__file__).parent.parent
sys.path.insert(0, str(BASE_DIR))

from core.utils import align_skeleton_to_camera, add_velocity, flatten_skeleton
from core.diagnostics import MovementDiagnostician

MODELS_DIR = BASE_DIR / "models"
LEGS_MODEL_PATH = MODELS_DIR / "best_legs_model.keras"
ARMS_MODEL_PATH = MODELS_DIR / "best_arms_model.keras"
        
class OrthoSensePredictor:
    def __init__(self):
        print("Initializing OrthoSensePredictor...")
        self.diagnostician = MovementDiagnostician()
        
        self.model_legs = self._load_model(LEGS_MODEL_PATH, "Legs")
        self.model_arms = self._load_model(ARMS_MODEL_PATH, "Arms")

        self.LABELS_LEGS = {0: "Deep Squat", 1: "Hurdle Step", 2: "Inline Lunge", 3: "Side Lunge", 4: "Sit to Stand"}
        self.LABELS_ARMS = {0: "Standing Active Straight Leg Raise", 1: "Standing Shoulder Abduction", 2: "Standing Shoulder Extension", 3: "Standing Shoulder Int/Ext Rotation", 4: "Standing Shoulder Scaption"}

        self.angle_buffer = deque(maxlen=10)

    def reset(self):
        """Clears the recent measurements buffer."""
        self.angle_buffer.clear()
        print("Engine state reset.")

    def _load_model(self, path, name):
        if os.path.exists(path):
            try:
                model = tf.keras.models.load_model(path)
                return model
            except Exception as e:
                print(f"Error loading model {name}: {e}")
                return None
        else:
            print(f"Model {name} not found at {path}")
            return None

    def preprocess_input(self, X_sequence):
        processed_batch = [align_skeleton_to_camera(s) for s in X_sequence]
        X = np.array(processed_batch)
        if np.max(np.abs(X)) > 100: X = X / 100.0
        X = add_velocity(X)
        X = flatten_skeleton(X)
        X = (X - np.mean(X)) / (np.std(X) + 1e-7)

        return X

    def _get_prediction(self, model, X_data, labels):
        if model is None: return None, 0.0
        
        predictions = model.predict(X_data, verbose=0)
        
        predicted_indices = np.argmax(predictions, axis=1)
        confidences = np.max(predictions, axis=1)
        
        vote_counter = Counter(predicted_indices)
        if not vote_counter: return None, 0.0
        
        winner_id = vote_counter.most_common(1)[0][0]
        winner_name = labels[winner_id]
        
        winner_confidences = [conf for i, conf in enumerate(confidences) if predicted_indices[i] == winner_id]
        avg_confidence = np.mean(winner_confidences)
        
        return winner_name, avg_confidence

    def analyze(self, raw_data, sequences, forced_exercise_name=None):            
        if not forced_exercise_name:
            X_legs = self.preprocess_input(sequences)
            if sequences.shape[2] == 25:
                X_arms_raw = sequences[:, :, :22, :] 
            else:
                X_arms_raw = sequences
            X_arms = self.preprocess_input(X_arms_raw)

        knee_angles = []
        hip_ankle_distances = [] 
        ankle_z_diffs = []

        for frame in raw_data:
            angle_l = self.diagnostician.calculate_angle(frame[12], frame[13], frame[14])
            angle_r = self.diagnostician.calculate_angle(frame[16], frame[17], frame[18])
            knee_angles.append(min(angle_l, angle_r))

            l_dist = abs(frame[12][1] - frame[14][1])
            r_dist = abs(frame[16][1] - frame[18][1])
            avg_dist = (l_dist + r_dist) / 2.0
            hip_ankle_distances.append(avg_dist)

            z_diff = abs(frame[14][2] - frame[18][2])
            ankle_z_diffs.append(z_diff)

        avg_knee_angle = np.mean(knee_angles) if knee_angles else 180.0
        if hip_ankle_distances:
            motion_range = np.max(hip_ankle_distances) - np.min(hip_ankle_distances)
        else:
            motion_range = 0.0
        avg_ankle_z_diff = np.mean(ankle_z_diffs) if ankle_z_diffs else 0.0
        
        if forced_exercise_name:
            final_name = forced_exercise_name
            winner_model = "LOCKED"
            final_conf = 1.0
            
        else:
            name_l, conf_l = self._get_prediction(self.model_legs, X_legs, self.LABELS_LEGS)
            name_a, conf_a = self._get_prediction(self.model_arms, X_arms, self.LABELS_ARMS)
            
            print(f"Votes: LEGS [{name_l}]={conf_l*100:.1f}% vs ARMS [{name_a}]={conf_a*100:.1f}%")

            if conf_l > conf_a:
                winner_model = "Legs"
                final_name = name_l
                final_conf = conf_l
            else:
                winner_model = "Arms"
                final_name = name_a
                final_conf = conf_a

            IS_DYNAMIC_SQUAT = (avg_knee_angle < 135.0) and (motion_range > 0.10)
            IS_STATIC_DEEP_HOLD = avg_knee_angle < 110.0
            AI_SAYS_STANDING = "Standing" in final_name

            if (IS_DYNAMIC_SQUAT or IS_STATIC_DEEP_HOLD) and AI_SAYS_STANDING:
                print(f"LOGIC OVERRIDE: Forcing Deep Squat based on geometry.")
                final_name = "Deep Squat"
                winner_model = "Legs (Forced)"

            if final_name == "Inline Lunge" and avg_ankle_z_diff < 0.20:
                print(f"SYMMETRY CHECK: Changing Lunge to Squat.")
                final_name = "Deep Squat"

            MIN_CONFIDENCE_THRESHOLD = 0.60
            if final_conf < MIN_CONFIDENCE_THRESHOLD:
                final_name = "No Exercise Detected"
                winner_model = "None"
                final_conf = 0.0

        is_correct = True
        feedback = ""
        
        if final_name != "No Exercise Detected":
            is_correct, feedback = self.diagnostician.diagnose(final_name, raw_data, buffer=self.angle_buffer)
        elif forced_exercise_name: 
            is_correct, feedback = self.diagnostician.diagnose(forced_exercise_name, raw_data, buffer=self.angle_buffer)

        return {
            "exercise": final_name,
            "model_used": winner_model,
            "confidence": final_conf,
            "is_correct": is_correct,
            "feedback": feedback
        }
