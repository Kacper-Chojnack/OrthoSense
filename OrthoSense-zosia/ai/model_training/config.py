import torch

DATA_PATH = "../dataset_csv"

WEIGHTS_PATH = None  

NUM_JOINTS = 33  
MAX_FRAME = 60
NUM_PERSON = 1
IN_CHANNELS = 3  

NUM_CLASSES = 3

EXERCISE_FILTER = {
    'm01': 0,  # Deep Squat
    'm02': 1,  # Hurdle Step
    'm07': 2,  # Standing Shoulder Abduction
}

EXERCISE_NAMES = [
    "Deep Squat",
    "Hurdle Step",
    "Standing Shoulder Abduction"
]

BATCH_SIZE = 16
LEARNING_RATE = 0.001
EPOCHS = 30
DEVICE = 'cuda' if torch.cuda.is_available() else 'cpu'
