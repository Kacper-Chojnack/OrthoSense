import numpy as np
from scipy.interpolate import interp1d


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