import numpy as np
import os
from pathlib import Path
from typing import List, Tuple, Dict, Optional
from scipy.interpolate import interp1d
import glob
import pandas as pd

KINECT_JOINTS = {
    'SPINE_BASE': 0,
    'SPINE_MID': 1,
    'NECK': 2,
    'HEAD': 3,
    'SHOULDER_LEFT': 4,
    'ELBOW_LEFT': 5,
    'WRIST_LEFT': 6,
    'HAND_LEFT': 7,
    'SHOULDER_RIGHT': 8,
    'ELBOW_RIGHT': 9,
    'WRIST_RIGHT': 10,
    'HAND_RIGHT': 11,
    'HIP_LEFT': 12,
    'KNEE_LEFT': 13,
    'ANKLE_LEFT': 14,
    'FOOT_LEFT': 15,
    'HIP_RIGHT': 16,
    'KNEE_RIGHT': 17,
    'ANKLE_RIGHT': 18,
    'FOOT_RIGHT': 19,
    'SPINE_SHOULDER': 20,
    'HAND_TIP_LEFT': 21,
    'THUMB_LEFT': 22,
    'HAND_TIP_RIGHT': 23,
    'THUMB_RIGHT': 24
}

ESSENTIAL_JOINTS = [
    'SHOULDER_LEFT', 'SHOULDER_RIGHT',
    'ELBOW_LEFT', 'ELBOW_RIGHT',
    'WRIST_LEFT', 'WRIST_RIGHT',
    'HIP_LEFT', 'HIP_RIGHT',
    'KNEE_LEFT', 'KNEE_RIGHT',
    'ANKLE_LEFT', 'ANKLE_RIGHT',
    'SPINE_BASE', 'SPINE_MID', 'NECK'
]

MEDIAPIPE_MAPPING = {
    'LEFT_SHOULDER': 'SHOULDER_LEFT',
    'RIGHT_SHOULDER': 'SHOULDER_RIGHT',
    'LEFT_ELBOW': 'ELBOW_LEFT',
    'RIGHT_ELBOW': 'ELBOW_RIGHT',
    'LEFT_WRIST': 'WRIST_LEFT',
    'RIGHT_WRIST': 'WRIST_RIGHT',
    'LEFT_HIP': 'HIP_LEFT',
    'RIGHT_HIP': 'HIP_RIGHT',
    'LEFT_KNEE': 'KNEE_LEFT',
    'RIGHT_KNEE': 'KNEE_RIGHT',
    'LEFT_ANKLE': 'ANKLE_LEFT',
    'RIGHT_ANKLE': 'ANKLE_RIGHT',
}

def calculate_angle_3d(point_a: np.ndarray, point_b: np.ndarray, point_c: np.ndarray) -> float:
    '''
    Calculate angle between three 3D points (angle at vertex B).
    '''

    ba = point_a - point_b
    bc = point_c - point_b
    
    ba_norm = np.linalg.norm(ba)
    bc_norm = np.linalg.norm(bc)
    
    if ba_norm == 0 or bc_norm == 0:
        return 0.0
    
    cos_angle = np.dot(ba, bc) / (ba_norm * bc_norm)
    cos_angle = np.clip(cos_angle, -1.0, 1.0)
    
    angle = np.arccos(cos_angle) * 180.0 / np.pi
    
    return angle

def calculate_trunk_lean(spine_base: np.ndarray, spine_mid: np.ndarray, neck: np.ndarray) -> float:
    '''
    Calculate trunk lean angle relative to vertical axis (Y).
    '''

    spine_vector = neck - spine_base
    vertical = np.array([0, 1, 0])
    
    spine_norm = np.linalg.norm(spine_vector)
    if spine_norm == 0:
        return 0.0
    
    spine_normalized = spine_vector / spine_norm
    
    cos_angle = np.dot(spine_normalized, vertical)
    cos_angle = np.clip(cos_angle, -1.0, 1.0)
    
    angle = np.arccos(cos_angle) * 180.0 / np.pi
    
    return angle

def get_angles(landmarks: np.ndarray, joint_indices: Optional[Dict[str, int]] = None) -> np.ndarray:
    '''
    Extract angle features from joint positions (knees, hips, elbows, trunk lean).
    '''

    if joint_indices is None:
        joint_indices = KINECT_JOINTS
    
    is_sequence = len(landmarks.shape) == 3
    if not is_sequence:
        landmarks = landmarks[np.newaxis, ...]
    
    n_frames = landmarks.shape[0]
    angles_list = []
    last_valid_angles = None
    
    for frame_idx in range(n_frames):
        frame_landmarks = landmarks[frame_idx]
        
        try:
            left_knee_angle = calculate_angle_3d(
                frame_landmarks[joint_indices['HIP_LEFT']],
                frame_landmarks[joint_indices['KNEE_LEFT']],
                frame_landmarks[joint_indices['ANKLE_LEFT']]
            )
            
            right_knee_angle = calculate_angle_3d(
                frame_landmarks[joint_indices['HIP_RIGHT']],
                frame_landmarks[joint_indices['KNEE_RIGHT']],
                frame_landmarks[joint_indices['ANKLE_RIGHT']]
            )
            
            left_hip_angle = calculate_angle_3d(
                frame_landmarks[joint_indices['SHOULDER_LEFT']],
                frame_landmarks[joint_indices['HIP_LEFT']],
                frame_landmarks[joint_indices['KNEE_LEFT']]
            )
            
            right_hip_angle = calculate_angle_3d(
                frame_landmarks[joint_indices['SHOULDER_RIGHT']],
                frame_landmarks[joint_indices['HIP_RIGHT']],
                frame_landmarks[joint_indices['KNEE_RIGHT']]
            )
            
            left_elbow_angle = calculate_angle_3d(
                frame_landmarks[joint_indices['SHOULDER_LEFT']],
                frame_landmarks[joint_indices['ELBOW_LEFT']],
                frame_landmarks[joint_indices['WRIST_LEFT']]
            )
            
            right_elbow_angle = calculate_angle_3d(
                frame_landmarks[joint_indices['SHOULDER_RIGHT']],
                frame_landmarks[joint_indices['ELBOW_RIGHT']],
                frame_landmarks[joint_indices['WRIST_RIGHT']]
            )
            
            trunk_lean = calculate_trunk_lean(
                frame_landmarks[joint_indices['SPINE_BASE']],
                frame_landmarks[joint_indices['SPINE_MID']],
                frame_landmarks[joint_indices['NECK']]
            )
            
            shoulder_width_angle = calculate_angle_3d(
                frame_landmarks[joint_indices['SHOULDER_LEFT']],
                frame_landmarks[joint_indices['SPINE_MID']],
                frame_landmarks[joint_indices['SHOULDER_RIGHT']]
            )
            
            hip_width_angle = calculate_angle_3d(
                frame_landmarks[joint_indices['HIP_LEFT']],
                frame_landmarks[joint_indices['SPINE_BASE']],
                frame_landmarks[joint_indices['HIP_RIGHT']]
            )
            
            spine_side_angle = calculate_angle_3d(
                frame_landmarks[joint_indices['SPINE_BASE']],
                frame_landmarks[joint_indices['SPINE_MID']],
                frame_landmarks[joint_indices['NECK']]
            )
            
        except (IndexError, KeyError) as e:
            if last_valid_angles is not None:
                angles_list.append(last_valid_angles.copy())
            else:
                angles_list.append(np.zeros(10))
            continue
        
        frame_angles = np.array([
            left_knee_angle,
            right_knee_angle,
            left_hip_angle,
            right_hip_angle,
            left_elbow_angle,
            right_elbow_angle,
            trunk_lean,
            shoulder_width_angle,
            hip_width_angle,
            spine_side_angle
        ])
        
        last_valid_angles = frame_angles
        angles_list.append(frame_angles)
    
    angles_array = np.array(angles_list)
    
    if not is_sequence:
        angles_array = angles_array[0]
    
    return angles_array

def resample_sequence(data: np.ndarray, target_len: int = 60, method: str = 'linear') -> np.ndarray:
    '''
    Resample temporal sequence to fixed length using interpolation.
    '''
    
    current_len = data.shape[0]
    
    if current_len == target_len:
        return data
    
    original_time = np.linspace(0, 1, current_len)
    target_time = np.linspace(0, 1, target_len)
    
    if len(data.shape) == 2:
        n_features = data.shape[1]
        resampled = np.zeros((target_len, n_features))
        
        for feat_idx in range(n_features):
            interp_func = interp1d(original_time, data[:, feat_idx], 
                                 kind=method, fill_value='extrapolate')
            resampled[:, feat_idx] = interp_func(target_time)
    
    elif len(data.shape) == 3:
        n_joints = data.shape[1]
        n_coords = data.shape[2]
        resampled = np.zeros((target_len, n_joints, n_coords))
        
        for joint_idx in range(n_joints):
            for coord_idx in range(n_coords):
                interp_func = interp1d(original_time, data[:, joint_idx, coord_idx],
                                     kind=method, fill_value='extrapolate')
                resampled[:, joint_idx, coord_idx] = interp_func(target_time)
    
    else:
        raise ValueError(f"Unsupported data shape: {data.shape}")
    
    return resampled

def load_positions_file(file_path: str) -> np.ndarray:
    '''
    Load joint positions file from UI-PRMD dataset.
    '''

    try:
        with open(file_path, 'r') as f:
            lines = f.readlines()
        
        data_rows = []
        expected_cols = None
        
        for line_idx, line in enumerate(lines):
            line = line.strip()
            if not line:
                continue
            
            values = line.split(',')
            values = [v.strip() for v in values if v.strip()]
            
            if not values:
                continue
            
            try:
                row = [float(v) for v in values]
            except ValueError:
                continue
            
            if expected_cols is None:
                expected_cols = len(row)
            elif len(row) != expected_cols:
                continue
            
            data_rows.append(row)
        
        if not data_rows:
            return None
        
        data = np.array(data_rows)
        
        if len(data.shape) == 1:
            data = data[np.newaxis, :]
        
        n_frames = data.shape[0]
        n_cols = data.shape[1]
        
        if n_cols % 3 == 0:
            n_joints = n_cols // 3
            data = data.reshape(n_frames, n_joints, 3)
        
        return data
    
    except Exception as e:
        print(f"Error reading {file_path}: {e}. Skipping this file.")
        return None

def parse_filename(filename: str) -> Dict[str, str]:
    '''
    Parse UI-PRMD filename to extract metadata (movement_id, subject_id, episode_id, is_incorrect).
    '''

    basename = os.path.basename(filename)
    
    is_incorrect = '_inc' in basename
    
    clean_name = basename.replace('_inc', '').replace('_positions.txt', '').replace('_angles.txt', '')
    parts = clean_name.split('_')
    
    result = {
        'movement_id': None,
        'subject_id': None,
        'episode_id': None,
        'is_incorrect': is_incorrect
    }
    
    for part in parts:
        if part.startswith('m') and part[1:].isdigit():
            result['movement_id'] = part
        elif part.startswith('s') and part[1:].isdigit():
            result['subject_id'] = part
        elif part.startswith('e') and part[1:].isdigit():
            result['episode_id'] = part
            
    return result

def load_dataset(
    data_dir: str,
    use_angles: bool = False,
    class_mode: str = 'binary',
    keep_positions: bool = False,
) -> Tuple[np.ndarray, np.ndarray, List[Dict]]:
    '''
    Load dataset in one of three modes:
    - binary (0=correct, 1=incorrect)
    - movement (0-9=exercise type)
    - diagnostic (unique class per exercise variant)
    '''
    data_dir = Path(data_dir)
    
    if use_angles:
        correct_dir = data_dir / 'Segmented Movements' / 'Kinect' / 'Angles'
        incorrect_dir = data_dir / 'Incorrect Segmented Movements' / 'Kinect' / 'Angles'
        file_pattern = '*_angles*.txt'
    else:
        correct_dir = data_dir / 'Segmented Movements' / 'Kinect' / 'Positions'
        incorrect_dir = data_dir / 'Incorrect Segmented Movements' / 'Kinect' / 'Positions'
        file_pattern = '*_positions*.txt'
    
    sequences = []
    labels = []
    metadata_list = []
    
    def process_files(file_list, is_correct_folder):
        total_files = len(file_list)
        for idx, file_path in enumerate(file_list, 1):
            file_meta = parse_filename(str(file_path))
            file_meta['file_path'] = str(file_path)
            
            positions = load_positions_file(str(file_path))
            if positions is None:
                continue
                
            if not use_angles:
                if keep_positions:
                    data_to_use = positions
                else:
                    data_to_use = get_angles(positions)
            else:
                data_to_use = positions
            
            data_resampled = resample_sequence(data_to_use, target_len=60)
            
            label = -1
            
            if file_meta['movement_id']:
                move_idx = int(file_meta['movement_id'][1:]) - 1
            else:
                continue

            if class_mode == 'binary':
                label = 0 if is_correct_folder else 1
                
            elif class_mode == 'movement':
                label = move_idx
                
            elif class_mode == 'diagnostic':
                base_class = move_idx * 2
                offset = 0 if is_correct_folder else 1
                label = base_class + offset

            if label != -1:
                sequences.append(data_resampled)
                labels.append(label)
                metadata_list.append(file_meta)
        return

    if correct_dir.exists():
        files = list(correct_dir.glob(file_pattern))
        process_files(files, is_correct_folder=True)
    
    if incorrect_dir.exists():
        files = list(incorrect_dir.glob(file_pattern))
        process_files(files, is_correct_folder=False)
    
    X = np.array(sequences)
    y = np.array(labels)
    
    return X, y, metadata_list

def split_by_subjects(X: np.ndarray, y: np.ndarray, metadata: List[Dict], 
                     train_subjects: List[str] = None,
                     val_subjects: List[str] = None,
                     test_subjects: List[str] = None) -> Tuple:
    '''
    Split dataset by subjects to avoid data leakage.
    '''
    
    if train_subjects is None:
        train_subjects = ['01', '02', '03', '04', '05', '06', '07']
    if val_subjects is None:
        val_subjects = ['08']
    if test_subjects is None:
        test_subjects = ['09', '10']
    
    train_indices = []
    val_indices = []
    test_indices = []
    
    for idx, meta in enumerate(metadata):
        subject_id = meta.get('subject_id')
        
        if subject_id and subject_id.startswith('s'):
            subject_num = subject_id[1:]
        else:
            subject_num = subject_id
        
        if subject_num in train_subjects:
            train_indices.append(idx)
        elif subject_num in val_subjects:
            val_indices.append(idx)
        elif subject_num in test_subjects:
            test_indices.append(idx)
        else:
            train_indices.append(idx)
    
    X_train = X[train_indices]
    y_train = y[train_indices]
    
    X_val = X[val_indices] if val_indices else np.array([])
    y_val = y[val_indices] if val_indices else np.array([])
    
    X_test = X[test_indices] if test_indices else np.array([])
    y_test = y[test_indices] if test_indices else np.array([])
    
    return X_train, y_train, X_val, y_val, X_test, y_test

def mediapipe_to_angles(landmarks: np.ndarray) -> np.ndarray:
    '''
    Convert MediaPipe Pose keypoints to angle features.
    '''

    MEDIAPIPE_INDICES = {
        'LEFT_SHOULDER': 11,
        'RIGHT_SHOULDER': 12,
        'LEFT_ELBOW': 13,
        'RIGHT_ELBOW': 14,
        'LEFT_WRIST': 15,
        'RIGHT_WRIST': 16,
        'LEFT_HIP': 23,
        'RIGHT_HIP': 24,
        'LEFT_KNEE': 25,
        'RIGHT_KNEE': 26,
        'LEFT_ANKLE': 27,
        'RIGHT_ANKLE': 28,
        'NOSE': 0,
    }
    
    is_sequence = len(landmarks.shape) == 3
    if not is_sequence:
        landmarks = landmarks[np.newaxis, ...]
    
    n_frames = landmarks.shape[0]
    kinect_format = []
    
    for frame_idx in range(n_frames):
        frame = landmarks[frame_idx]
        
        spine_base = (frame[MEDIAPIPE_INDICES['LEFT_HIP']] + 
                     frame[MEDIAPIPE_INDICES['RIGHT_HIP']]) / 2
        spine_mid = (frame[MEDIAPIPE_INDICES['LEFT_HIP']] + 
                    frame[MEDIAPIPE_INDICES['RIGHT_HIP']] +
                    frame[MEDIAPIPE_INDICES['LEFT_SHOULDER']] + 
                    frame[MEDIAPIPE_INDICES['RIGHT_SHOULDER']]) / 4
        neck = (frame[MEDIAPIPE_INDICES['LEFT_SHOULDER']] + 
               frame[MEDIAPIPE_INDICES['RIGHT_SHOULDER']]) / 2
        
        kinect_frame = np.zeros((25, 3))
        kinect_frame[KINECT_JOINTS['SPINE_BASE']] = spine_base
        kinect_frame[KINECT_JOINTS['SPINE_MID']] = spine_mid
        kinect_frame[KINECT_JOINTS['NECK']] = neck
        kinect_frame[KINECT_JOINTS['SHOULDER_LEFT']] = frame[MEDIAPIPE_INDICES['LEFT_SHOULDER']]
        kinect_frame[KINECT_JOINTS['SHOULDER_RIGHT']] = frame[MEDIAPIPE_INDICES['RIGHT_SHOULDER']]
        kinect_frame[KINECT_JOINTS['ELBOW_LEFT']] = frame[MEDIAPIPE_INDICES['LEFT_ELBOW']]
        kinect_frame[KINECT_JOINTS['ELBOW_RIGHT']] = frame[MEDIAPIPE_INDICES['RIGHT_ELBOW']]
        kinect_frame[KINECT_JOINTS['WRIST_LEFT']] = frame[MEDIAPIPE_INDICES['LEFT_WRIST']]
        kinect_frame[KINECT_JOINTS['WRIST_RIGHT']] = frame[MEDIAPIPE_INDICES['RIGHT_WRIST']]
        kinect_frame[KINECT_JOINTS['HIP_LEFT']] = frame[MEDIAPIPE_INDICES['LEFT_HIP']]
        kinect_frame[KINECT_JOINTS['HIP_RIGHT']] = frame[MEDIAPIPE_INDICES['RIGHT_HIP']]
        kinect_frame[KINECT_JOINTS['KNEE_LEFT']] = frame[MEDIAPIPE_INDICES['LEFT_KNEE']]
        kinect_frame[KINECT_JOINTS['KNEE_RIGHT']] = frame[MEDIAPIPE_INDICES['RIGHT_KNEE']]
        kinect_frame[KINECT_JOINTS['ANKLE_LEFT']] = frame[MEDIAPIPE_INDICES['LEFT_ANKLE']]
        kinect_frame[KINECT_JOINTS['ANKLE_RIGHT']] = frame[MEDIAPIPE_INDICES['RIGHT_ANKLE']]
        
        kinect_format.append(kinect_frame)
    
    kinect_array = np.array(kinect_format)
    
    if not is_sequence:
        kinect_array = kinect_array[0]
    
    return get_angles(kinect_array)

def load_kimore_dataset(data_dir, target_len=60):
    """
    Loads the KiMoRe dataset, handling different file formats (75 or 100 columns)
    and splitting long recordings into shorter windows (sliding window).
    """

    sequences = []
    labels = []
    
    exercises = ['Es1', 'Es2', 'Es3', 'Es4', 'Es5']
    
    WINDOW_SIZE = 60   
    STRIDE = 40        
    
    for ex_idx, ex_name in enumerate(exercises):
        search_pattern = os.path.join(data_dir, '**', ex_name, 'Raw', 'JointPosition*.csv')
        files = glob.glob(search_pattern, recursive=True)
        
        for f in files:
            try:
                df = pd.read_csv(f, header=None, engine='python')
                
                data = df.select_dtypes(include=[np.number]).values
                
                data = data[~np.isnan(data).all(axis=1)]
                
                if data.shape[1] >= 100:
                    data = data[:, :100]
                    data = data.reshape(-1, 25, 4)
                    full_sequence = data[:, :, :3]
                    
                elif data.shape[1] == 75:
                    full_sequence = data.reshape(-1, 25, 3)
                    
                else:
                    continue

                num_frames = full_sequence.shape[0]
                if num_frames == 0: continue


                if num_frames < WINDOW_SIZE:
                    resampled = resample_sequence(full_sequence, target_len=WINDOW_SIZE)
                    sequences.append(resampled)
                    labels.append(ex_idx)
                
                else:
                    for start in range(0, num_frames - WINDOW_SIZE + 1, STRIDE):
                        end = start + WINDOW_SIZE
                        chunk = full_sequence[start:end]
                        
                        sequences.append(chunk)
                        labels.append(ex_idx)
                        
            except Exception as e:
                print(f"Error processing file {os.path.basename(f)} for exercise {ex_name}: {e}. Skipping.")
                
    X = np.array(sequences)
    y = np.array(labels)
           
    return X, y