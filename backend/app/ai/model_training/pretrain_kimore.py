import numpy as np
import tensorflow as tf
import os
import sys
from pathlib import Path

BASE_DIR = Path(__file__).parent.parent
sys.path.insert(0, str(BASE_DIR))

from utils.preprocessing import load_kimore_dataset
from model_training.train_uiprmd import (
    align_skeleton_to_camera, 
    augment_data, 
    add_velocity, 
    flatten_skeleton, 
    build_model
)

KIMORE_PATH = BASE_DIR / "datasets" / "kimore"
MODELS_DIR = BASE_DIR / "models" 

def main():
    X, y = load_kimore_dataset(str(KIMORE_PATH), target_len=60)
    
    if len(X) == 0:
        print("Error: No KiMoRe files found. Please verify KIMORE_PATH.")
        return

    if np.isnan(X).any():
        X = np.nan_to_num(X, nan=0.0, posinf=0.0, neginf=0.0)
    
    non_zero_mask = np.sum(np.abs(X.reshape(X.shape[0], -1)), axis=1) > 0
    X = X[non_zero_mask]
    y = y[non_zero_mask]

    if np.max(np.abs(X)) > 100:
        X = X / 100.0
        
    X_aligned = np.zeros_like(X)
    for i in range(len(X)):
        X_aligned[i] = align_skeleton_to_camera(X[i])
    X = X_aligned
    
    X_train, y_train = augment_data(X, y) 
    
    X_train = add_velocity(X_train)
    X_train = flatten_skeleton(X_train)
    
    mean = np.mean(X_train)
    std = np.std(X_train)
    X_train = (X_train - mean) / (std + 1e-7)
    
    model = build_model(input_shape=(60, 150), num_classes=5)
    
    model.fit(
        X_train, y_train, 
        epochs=40,           
        batch_size=16, 
        validation_split=0.2
    )
    
    os.makedirs(MODELS_DIR, exist_ok=True)
    weights_path = MODELS_DIR / "kimore_pretrained.weights.h5"
    model.save_weights(str(weights_path))

if __name__ == "__main__":
    main()