import numpy as np

from app.ai.core.diagnostics import MovementDiagnostician


class OrthoSensePredictor:
    def __init__(self):
        self.diag = MovementDiagnostician()

    def reset(self):
        pass  # stateless for now

    def analyze(self, raw_data, exercise_name: str = ""):
        """Run diagnostics on pose data."""
        if not isinstance(raw_data, np.ndarray):
            raw_data = np.array(raw_data, dtype=np.float32)

        is_ok, feedback = self.diag.diagnose(exercise_name, raw_data)

        if not isinstance(feedback, dict):
            feedback = {"System": feedback} if feedback else {}

        return {
            "exercise": exercise_name,
            "confidence": 1.0,  # diagnostics-based, not ML
            "is_correct": is_ok,
            "feedback": feedback,
        }
