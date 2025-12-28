from pathlib import Path

import numpy as np
import torch
import torch.nn.functional as F
from scipy.interpolate import interp1d

import app.ai.core.config as config
from app.ai.core.diagnostics import MovementDiagnostician
from app.ai.core.model import Model

AI_DIR = Path(__file__).parent.parent
BASE_DIR = Path(__file__).parent.parent.parent.parent

# Model filename constant
DEFAULT_MODEL_FILENAME = "lstm_best_model.pt"


class OrthoSensePredictor:
    def __init__(self):
        self.diagnostician = MovementDiagnostician()
        self.device = torch.device("cpu")
        self.model = Model(num_class=config.NUM_CLASSES, in_channels=config.IN_CHANNELS)

        possible_paths = [
            AI_DIR / "models" / DEFAULT_MODEL_FILENAME,
            AI_DIR / config.WEIGHTS_PATH.replace("models/", ""),
            BASE_DIR / "app" / "ai" / "models" / DEFAULT_MODEL_FILENAME,
            BASE_DIR / config.WEIGHTS_PATH,
            BASE_DIR / "models" / DEFAULT_MODEL_FILENAME,
            BASE_DIR / "models" / "lstm_best_fold_1.pt",
        ]
        model_path = next((p for p in possible_paths if p.exists()), None)

        if model_path:
            self._load_weights(model_path)

        self.model.to(self.device)
        self.model.eval()
        self.LABELS = config.EXERCISE_NAMES

    def _load_weights(self, path: Path):
        try:
            weights = torch.load(path, map_location=self.device)
            if isinstance(weights, dict) and "state_dict" in weights:
                weights = weights["state_dict"]
            clean_state = {k.replace("module.", ""): v for k, v in weights.items()}
            self.model.load_state_dict(clean_state, strict=False)
        except Exception as e:
            print(f"Error loading weights: {e}")

    def reset(self):
        """Reset predictor state. Currently a no-op as model is stateless."""

    def preprocess_sequence(self, raw_data):
        data = np.array(raw_data, dtype=np.float32)
        T, V, C = data.shape
        target_frames = config.MAX_FRAME

        hip_center = (data[:, 23:24, :] + data[:, 24:25, :]) / 2.0
        data = data - hip_center

        if target_frames != T:
            x_old = np.linspace(0, 1, T)
            x_new = np.linspace(0, 1, target_frames)
            new_data = np.zeros((target_frames, V, C), dtype=np.float32)
            for v in range(V):
                for c in range(C):
                    f = interp1d(x_old, data[:, v, c], kind="linear")
                    new_data[:, v, c] = f(x_new)
            data = new_data

        data = np.transpose(data, (2, 0, 1))
        data = data[np.newaxis, :, :, :, np.newaxis]
        return torch.from_numpy(data).float()

    def analyze(self, raw_data, forced_exercise_name=None):
        final_name = "No Exercise Detected"
        final_conf = 0.0

        if forced_exercise_name:
            final_name = forced_exercise_name
            final_conf = 1.0
        elif len(raw_data) > 10:
            with torch.no_grad():
                input_tensor = self.preprocess_sequence(raw_data).to(self.device)
                output = self.model(input_tensor)
                probs = F.softmax(output, dim=1)
                conf, predicted_idx = torch.max(probs, 1)

                idx = predicted_idx.item()
                final_conf = conf.item()
                final_name = self.LABELS.get(idx, "Unknown")

        is_correct = True
        feedback = {}

        if final_name not in ["No Exercise Detected", "Unknown"]:
            is_correct, feedback = self.diagnostician.diagnose(final_name, raw_data)

            if not isinstance(feedback, dict):
                feedback = {"System": feedback} if feedback else {}

        return {
            "exercise": final_name,
            "confidence": final_conf,
            "is_correct": is_correct,
            "feedback": feedback,
        }
