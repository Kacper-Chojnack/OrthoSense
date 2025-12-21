NUM_CLASSES = 3
NUM_JOINTS = 33  
IN_CHANNELS = 3 
MAX_FRAME = 60     
BATCH_SIZE = 16

WEIGHTS_PATH = "models/lstm_best_model.pt"

EXERCISE_NAMES = {
    0: "Deep Squat",
    1: "Hurdle Step",
    2: "Standing Shoulder Abduction"
}

MODEL_TYPE = "lstm"
