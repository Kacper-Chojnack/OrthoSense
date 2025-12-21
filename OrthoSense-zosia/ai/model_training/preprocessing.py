import os
import numpy as np
from pathlib import Path
from scipy.interpolate import interp1d
import config
import io

def load_file(file_path):
    """
    Load file with raw MediaPipe data.
    """
    try:
        with open(file_path, 'r') as f:
            lines = f.readlines()
            
        cleaned_lines = []
        for line in lines:
            line = line.strip()
            if not line: continue
            if line.endswith(','): line = line[:-1] 
            cleaned_lines.append(line)
            
        if not cleaned_lines: 
            return None, "Empty file"

        first_line = cleaned_lines[0]
        delimiter = ',' if ',' in first_line else None 
        
        s_io = io.StringIO('\n'.join(cleaned_lines))
        data = np.loadtxt(s_io, delimiter=delimiter)
        
        if data.size == 0: 
            return None, "Empty array"
        
        if data.ndim == 1:
            data = data.reshape(1, -1)
        
        num_frames, num_values = data.shape
        
        if num_values == 99:
            data = data.reshape(num_frames, 33, 3)
            return data, "OK (99 - MediaPipe)"
        else:
            return None, f"Shape Error: {num_values} values (expected 99 for MediaPipe)"

    except Exception as e:
        return None, f"Read Error: {str(e)}"


def normalize_sequence(data, target_frames=config.MAX_FRAME):
    """
    Simple sequence normalization:
    1. Center relative to hip center (landmarks 23 and 24)
    2. Resample to target_frames
    """
    T, V, C = data.shape  
    
    hip_center = (data[:, 23:24, :] + data[:, 24:25, :]) / 2.0
    data = data - hip_center
    
    if T != target_frames:
        x_old = np.linspace(0, 1, T)
        x_new = np.linspace(0, 1, target_frames)
        new_data = np.zeros((target_frames, V, C))
        
        for v in range(V):
            for c in range(C):
                f = interp1d(x_old, data[:, v, c], kind='linear')
                new_data[:, v, c] = f(x_new)
        data = new_data
    
    return data.astype(np.float32)


def process_dataset():
    """
    Preprocessing for exercises from raw MediaPipe data.
    """
    root = Path(config.DATA_PATH)
    
    if not root.exists():
        print(f"ERROR: Folder {root} does not exist!")
        return
    
    all_files = list(root.rglob('*_positions.txt'))
    files = [f for f in all_files if 'Incorrect' not in str(f)]
    files = list(set(files))
    
    data_list = []
    label_list = []
    subject_list = []
    
    stats = {name: 0 for name in config.EXERCISE_FILTER.keys()}
    skipped_other = 0
    skipped_error = 0
    
    for f in files:
        folder_name = f.parent.name
        m_str = None
        if folder_name.startswith('m') and len(folder_name) >= 3:
            m_part = folder_name[:3]
            if m_part[1:].isdigit():
                m_str = m_part
        
        if m_str not in config.EXERCISE_FILTER:
            skipped_other += 1
            continue
        
        parts = f.stem.split('_')
        s_str = None
        for part in parts:
            if part.lower().startswith('subject') and len(part) > 7:
                subj_num = part[7:]
                if subj_num.isdigit():
                    s_str = part
                    break
        
        if not s_str:
            skipped_error += 1
            continue
        
        raw_data, status = load_file(f)
        if raw_data is None:
            skipped_error += 1
            if skipped_error <= 5:
                print(f"  Load error {f.name}: {status}")
            continue
        
        norm_data = normalize_sequence(raw_data)
        
        new_label = config.EXERCISE_FILTER[m_str]
        subj_id = int(s_str[7:])
        
        data_list.append(norm_data)
        label_list.append(new_label)
        subject_list.append(subj_id)
        stats[m_str] += 1

    print(f"Loaded: {len(data_list)} samples")
    for m_str, count in stats.items():
        exercise_name = config.EXERCISE_NAMES[config.EXERCISE_FILTER[m_str]]
        print(f"  {m_str} ({exercise_name}): {count}")
    print(f"Skipped (other exercises): {skipped_other}")
    print(f"Skipped (errors): {skipped_error}")
    print(f"Subjects: {sorted(np.unique(subject_list))}")
    
    if len(data_list) == 0:
        print("CRITICAL ERROR: No data!")
        return

    X = np.array(data_list).astype(np.float32)
    print(f"\nShape before transpose: {X.shape}")
    
    X = X.transpose(0, 3, 1, 2)
    X = np.expand_dims(X, axis=-1)
    
    
    models_dir = Path(__file__).parent.parent / "models"
    models_dir.mkdir(exist_ok=True)
    np.save(models_dir / 'train_data.npy', X)
    np.save(models_dir / 'train_label.npy', np.array(label_list, dtype=np.int64))
    np.save(models_dir / 'train_subjects.npy', np.array(subject_list, dtype=np.int64))
    
    print(f"\nSaved .npy files:")
    print(f"  - {models_dir}/train_data.npy")
    print(f"  - {models_dir}/train_label.npy")
    print(f"  - {models_dir}/train_subjects.npy")
    print(f"="*60)


if __name__ == '__main__':
    process_dataset()
