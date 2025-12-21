"""AI module configuration constants."""

from pathlib import Path

# Model paths - relative to backend directory
AI_MODULE_DIR = Path(__file__).parent.parent
MODELS_DIR = AI_MODULE_DIR / "models"

# MediaPipe Pose Landmarker model
POSE_LANDMARKER_PATH = MODELS_DIR / "pose_landmarker_lite.task"

# LSTM classification model
LSTM_MODEL_PATH = MODELS_DIR / "lstm_best_model.pt"

# Analysis parameters
SEQUENCE_LENGTH = 30  # Frames needed for LSTM analysis
NUM_LANDMARKS = 33  # MediaPipe pose landmarks count
FEATURES_PER_LANDMARK = 4  # x, y, z, visibility
INPUT_SIZE = NUM_LANDMARKS * FEATURES_PER_LANDMARK  # 132 features

# LSTM architecture
HIDDEN_SIZE = 128
NUM_LAYERS = 2
NUM_CLASSES = 3
DROPOUT = 0.3

# Exercise class mapping
EXERCISE_CLASSES: dict[int, str] = {
    0: "Deep Squat",
    1: "Hurdle Step",
    2: "Standing Shoulder Abduction",
}

# Reverse mapping for lookup
EXERCISE_NAME_TO_ID: dict[str, int] = {
    name: idx for idx, name in EXERCISE_CLASSES.items()
}

# Analysis thresholds
CONFIDENCE_THRESHOLD = 0.7
POSE_DETECTION_CONFIDENCE = 0.5
POSE_TRACKING_CONFIDENCE = 0.5


class AngleThresholds:
    """Thresholds for exercise form evaluation."""

    # Deep Squat
    SQUAT_KNEE_MIN = 70  # Minimum knee flexion for valid squat
    SQUAT_KNEE_MAX = 120  # Maximum knee flexion (not deep enough)
    SQUAT_HIP_MIN = 60  # Minimum hip flexion
    SQUAT_BACK_MAX_LEAN = 30  # Maximum forward lean

    # Hurdle Step
    HURDLE_HIP_MIN = 80  # Minimum hip flexion for raised leg
    HURDLE_STANCE_KNEE_MAX = 10  # Standing leg should be straight

    # Shoulder Abduction
    SHOULDER_ABDUCTION_MIN = 80  # Minimum arm raise angle
    SHOULDER_ABDUCTION_MAX = 100  # Target range


class AIConfig:
    """Configuration container for AI settings."""

    sequence_length = SEQUENCE_LENGTH
    num_landmarks = NUM_LANDMARKS
    features_per_landmark = FEATURES_PER_LANDMARK
    input_size = INPUT_SIZE
    hidden_size = HIDDEN_SIZE
    num_layers = NUM_LAYERS
    num_classes = NUM_CLASSES
    dropout = DROPOUT
    confidence_threshold = CONFIDENCE_THRESHOLD
    pose_detection_confidence = POSE_DETECTION_CONFIDENCE
    pose_tracking_confidence = POSE_TRACKING_CONFIDENCE
