import numpy as np

from app.ai.core.diagnostics import MovementDiagnostician


class OrthoSensePredictor:
    def __init__(self):
        self.diagnostician = MovementDiagnostician()

    def reset(self):
        """Reset predictor state."""
        pass

    def analyze(self, raw_data, exercise_name: str):
        """
        Analyze the movement based on provided exercise name.
        """

        if not isinstance(raw_data, np.ndarray):
            raw_data = np.array(raw_data, dtype=np.float32)

        final_conf = 1.0

        is_correct, feedback = self.diagnostician.diagnose(exercise_name, raw_data)

        if not isinstance(feedback, dict):
            feedback = {"System": feedback} if feedback else {}

        return {
            "exercise": exercise_name,
            "confidence": final_conf,
            "is_correct": is_correct,
            "feedback": feedback,
        }
