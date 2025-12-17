import os
import numpy as np
import tensorflow as tf
from tensorflow.keras.models import Sequential
from tensorflow.keras.layers import LSTM, Dense, Dropout, Bidirectional, Input, BatchNormalization
from tensorflow.keras.callbacks import ModelCheckpoint, EarlyStopping, ReduceLROnPlateau
from tensorflow.keras.regularizers import l2
import matplotlib.pyplot as plt
import seaborn as sns
import json
from sklearn.model_selection import KFold


import sys
from pathlib import Path

BASE_DIR = Path(__file__).parent.parent
sys.path.insert(0, str(BASE_DIR))

from utils.preprocessing import load_dataset

DATASET_PATH = BASE_DIR / "datasets" / "ui_prmd"
MODELS_DIR = BASE_DIR / "models"
BATCH_SIZE = 16
EPOCHS = 80
LEARNING_RATE = 0.0005

def align_skeleton_to_camera(data):
    """
    Rotate skeleton around Y so shoulders align with the X axis.
    """

    if data.ndim != 3 or data.shape[1] < 9 or data.shape[2] != 3:
        return data
    aligned_data = data.copy()
    first_frame = data[0]
    left = first_frame[4]
    right = first_frame[8]
    delta = right - left
    angle = np.arctan2(delta[2], delta[0])
    rotation_angle = -angle
    c, s = np.cos(rotation_angle), np.sin(rotation_angle)
    rotation_matrix = np.array([[c, 0, s], [0, 1, 0], [-s, 0, c]])
    
    T, N, C = aligned_data.shape
    flat_data = aligned_data.reshape(-1, 3)
    rotated_flat = np.dot(flat_data, rotation_matrix.T)
    return rotated_flat.reshape(T, N, C)

def add_velocity(X):
    """
    Append velocity (temporal derivative) to positions, expanding channels from 3 to 6.
    """

    velocity = np.zeros_like(X)
    velocity[:, :-1, :, :] = X[:, 1:, :, :] - X[:, :-1, :, :]
    velocity[:, -1, :, :] = velocity[:, -2, :, :]
    return np.concatenate([X, velocity], axis=-1)

def flatten_skeleton(X):
    """
    Convert 4D skeleton data (N, 60, 25, C) to 3D (N, 60, 25*C) for LSTM input.
    """

    N, T, V, C = X.shape
    return X.reshape(N, T, V * C)

def augment_data(X, y):
    """
    Data augmentation: Gaussian noise and small Y-axis rotations (±5 degrees).
    """

    X_aug = [X]
    y_aug = [y]
    
    noise = np.random.normal(0, 0.02, X.shape)
    X_aug.append(X + noise)
    y_aug.append(y)
    
    X_rotated = np.zeros_like(X)
    for i in range(len(X)):
        theta = np.radians(np.random.uniform(-5, 5))
        c, s = np.cos(theta), np.sin(theta)
        rotation_matrix = np.array([[c, 0, s], [0, 1, 0], [-s, 0, c]])
        
        flat_sample = X[i].reshape(-1, 3)
        rotated_flat = np.dot(flat_sample, rotation_matrix)
        X_rotated[i] = rotated_flat.reshape(X[i].shape)
        
    X_aug.append(X_rotated)
    y_aug.append(y)
    
    return np.concatenate(X_aug), np.concatenate(y_aug)

def build_subject_folds(metadata, n_splits=5):
    """
    Build subject-based cross-validation folds.
    """

    subjects = sorted({m.get('subject_id') for m in metadata if m.get('subject_id')})
    if len(subjects) < 3:
        return [([], [], subjects)]

    kf = KFold(n_splits=n_splits, shuffle=True, random_state=42)
    folds = []
    for train_idx, test_idx in kf.split(subjects):
        train_subjects = [subjects[i] for i in train_idx]
        test_subjects = [subjects[i] for i in test_idx]
        if len(train_subjects) > 1:
            val_subjects = [train_subjects.pop()]
        else:
            val_subjects = test_subjects[:1]
        folds.append((train_subjects, val_subjects, test_subjects))
    return folds

def build_model(input_shape, num_classes):
    """
    Build Bi-LSTM classifier for sequences.
    """
    
    model = Sequential([
        Input(shape=input_shape),
        BatchNormalization(),
        Bidirectional(LSTM(32, return_sequences=True, kernel_regularizer=l2(0.01))),
        Dropout(0.5),
        LSTM(16, return_sequences=False, kernel_regularizer=l2(0.01)),
        Dropout(0.5),
        Dense(num_classes, activation='softmax')
    ])
    
    optimizer = tf.keras.optimizers.Adam(learning_rate=LEARNING_RATE, clipnorm=1.0)
    
    model.compile(loss='sparse_categorical_crossentropy',
                  optimizer=optimizer,
                  metrics=['accuracy'])
    
    return model

def create_class_mapping(num_classes, model_type='all'):
    """
    Create class mapping depending on selected module (all/legs/arms).
    """

    all_exercises = [
        "Deep Squat", "Hurdle Step", "Inline Lunge", "Side Lunge", "Sit to Stand",
        "Standing Active Straight Leg Raise", "Standing Shoulder Abduction",
        "Standing Shoulder Extension", "Standing Shoulder Int/Ext Rotation",
        "Standing Shoulder Scaption"
    ]
    
    if model_type == 'legs':
        names = all_exercises[:5]

    elif model_type == 'arms':
        names = all_exercises[5:]

    else:
        names = all_exercises

    return {i: names[i] for i in range(min(len(names), num_classes))}

def train_module(X, y, metadata, module: str):
    '''
    Trains a model for a specific module (legs/arms) using Transfer Learning from KiMoRe.
    '''
    
    os.makedirs(MODELS_DIR, exist_ok=True)

    if module == 'legs':
        mask = y < 5
        save_path = MODELS_DIR / "best_legs_model.keras"
        mapping_path = MODELS_DIR / "class_mapping_legs.json"
        y_shift = 0

    elif module == 'arms':
        mask = y >= 5
        save_path = MODELS_DIR / "best_arms_model.keras"
        mapping_path = MODELS_DIR / "class_mapping_arms.json"
        y_shift = -5

    else:
        return

    X_mod = X[mask]
    y_mod = y[mask] + y_shift
    metadata_mod = [m for i, m in enumerate(metadata) if mask[i]]

    num_classes = len(np.unique(y_mod))
    
    mapping = create_class_mapping(num_classes, model_type=module)
    with open(str(mapping_path), 'w') as f:
        json.dump(mapping, f, indent=4)

    if np.max(np.abs(X_mod)) > 100:
        X_mod = X_mod / 100.0
    elif np.max(np.abs(X_mod)) > 2000:
        X_mod = X_mod / 1000.0

    X_aligned = np.zeros_like(X_mod)
    for i in range(len(X_mod)):
        X_aligned[i] = align_skeleton_to_camera(X_mod[i])
    X_mod = X_aligned
    
    folds = build_subject_folds(metadata_mod, n_splits=5)
    fold_metrics = []

    for fold_id, (train_subj, val_subj, test_subj) in enumerate(folds, start=1):
        train_idx = [i for i, m in enumerate(metadata_mod) if m.get('subject_id') in train_subj]
        val_idx = [i for i, m in enumerate(metadata_mod) if m.get('subject_id') in val_subj]
        test_idx = [i for i, m in enumerate(metadata_mod) if m.get('subject_id') in test_subj]

        X_train, y_train = X_mod[train_idx], y_mod[train_idx]
        X_val, y_val = X_mod[val_idx], y_mod[val_idx]
        X_test, y_test = X_mod[test_idx], y_mod[test_idx]

        X_train, y_train = augment_data(X_train, y_train)

        X_train = add_velocity(X_train)
        X_val = add_velocity(X_val)
        X_test = add_velocity(X_test)

        X_train = flatten_skeleton(X_train)
        X_val = flatten_skeleton(X_val)
        X_test = flatten_skeleton(X_test)
        
        mean = np.mean(X_train)
        std = np.std(X_train)
        X_train = (X_train - mean) / (std + 1e-7)
        X_val = (X_val - mean) / (std + 1e-7)
        X_test = (X_test - mean) / (std + 1e-7)

        model = build_model(input_shape=(X_train.shape[1], X_train.shape[2]), num_classes=num_classes)

        weights_path = MODELS_DIR / "kimore_pretrained.weights.h5"
        try:
            model.load_weights(str(weights_path))
        except (OSError, ValueError) as e:
            print(f"[{module}] Could not load pretrained weights ({e}). Training from scratch.")

        callbacks = [
            ModelCheckpoint(str(save_path).replace(".keras", f"_fold{fold_id}.keras"), 
                            save_best_only=True, monitor='val_accuracy', mode='max', verbose=0),
            EarlyStopping(monitor='val_loss', patience=15, restore_best_weights=True, verbose=1),
            ReduceLROnPlateau(monitor='val_loss', factor=0.5, patience=8, min_lr=1e-5, verbose=1)
        ]

        history = model.fit(
            X_train, y_train,
            validation_data=(X_val, y_val),
            epochs=EPOCHS,
            batch_size=BATCH_SIZE,
            callbacks=callbacks,
            verbose=1
        )

        test_loss, test_acc = model.evaluate(X_test, y_test, verbose=0)
        fold_metrics.append(test_acc)

        plt.figure(figsize=(12, 4))
        plt.subplot(1, 2, 1)
        plt.plot(history.history['accuracy'], label='Train')
        plt.plot(history.history['val_accuracy'], label='Val')
        plt.title(f'Accuracy (Fold {fold_id})')
        plt.legend()
        
        plt.subplot(1, 2, 2)
        plt.plot(history.history['loss'], label='Train')
        plt.plot(history.history['val_loss'], label='Val')
        plt.title(f'Loss (Fold {fold_id})')
        plt.legend()
        plt.tight_layout()
        plt.savefig(f"training_history_{module}_fold{fold_id}.png")
        plt.close()

def main():
    if not DATASET_PATH.exists():
        raise FileNotFoundError(f"Dataset folder not found at '{DATASET_PATH}'. Update DATASET_PATH or place the data accordingly.")

    X, y, metadata = load_dataset(DATASET_PATH, use_angles=False, class_mode='movement', keep_positions=True)
  
    #difference in ui-prmd and kimore joints
    current_joints = X.shape[2] 
    target_joints = 25
    
    if current_joints < target_joints:
        diff = target_joints - current_joints
        padding = np.zeros((X.shape[0], X.shape[1], diff, X.shape[3]))
        
        X = np.concatenate([X, padding], axis=2)

    print("Training legs module...")
    train_module(X, y, metadata, module='legs')
    
    print("\nTraining arms module...")
    train_module(X, y, metadata, module='arms')

if __name__ == "__main__":
    tf.random.set_seed(42)
    np.random.seed(42)
    main()