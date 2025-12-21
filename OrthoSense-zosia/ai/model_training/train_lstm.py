import os
os.environ['OMP_NUM_THREADS'] = '1'
os.environ['KMP_DUPLICATE_LIB_OK'] = 'True'

import torch
import torch.nn as nn
import torch.optim as optim
from torch.utils.data import TensorDataset, DataLoader
import numpy as np
from sklearn.model_selection import KFold
import config
from model_lstm import SkeletonLSTMLight
from tqdm import tqdm


def augment_data(X, y, factor=4):
    """
    Enhanced augmentation: noise, scaling, time shift (4x data).
    """
    augmented_X = [X]
    augmented_y = [y]
    
    for _ in range(factor - 1):
        #random noise
        X_noise = X + np.random.normal(0, 0.005, X.shape).astype(np.float32)
        augmented_X.append(X_noise)
        augmented_y.append(y)
    
    #scaling
    scale = np.random.uniform(0.9, 1.1, (X.shape[0], 1, 1, 1, 1)).astype(np.float32)
    X_scaled = X * scale
    augmented_X.append(X_scaled)
    augmented_y.append(y)
    
    #time shift
    shift = np.random.randint(-5, 6, X.shape[0])
    X_shifted = np.zeros_like(X)
    for i in range(X.shape[0]):
        X_shifted[i] = np.roll(X[i], shift[i], axis=1)
    augmented_X.append(X_shifted)
    augmented_y.append(y)
    
    return np.concatenate(augmented_X, axis=0), np.concatenate(augmented_y, axis=0)


def main():
    DEVICE = 'cpu'
    USE_AUGMENTATION = True
    
    from pathlib import Path
    models_dir = Path(__file__).parent.parent / "models"
    
    if not (models_dir / 'train_data.npy').exists():
        print("\nNO DATA! Run preprocessing.py first")
        return

    print("\n1/5 - Loading data...")
    X = np.load(models_dir / 'train_data.npy').astype(np.float32)
    y = np.load(models_dir / 'train_label.npy').astype(np.int64)
    subjects = np.load(models_dir / 'train_subjects.npy')
    
    print(f"  Data: {X.shape}")
    print(f"  Labels: {y.shape}, unique: {np.unique(y)}")
    print(f"  Subjects: {np.unique(subjects)}")
    
    for class_id in range(config.NUM_CLASSES):
        count = np.sum(y == class_id)
        print(f"  Class {class_id} ({config.EXERCISE_NAMES[class_id]}): {count} samples")
    
    unique_subjects = np.unique(subjects)
    k_folds = min(5, len(unique_subjects))
    kf = KFold(n_splits=k_folds, shuffle=True, random_state=42)
    fold_results = []

    PATIENCE = 10
    MAX_EPOCHS = 100
    
    best_overall_acc = 0.0
    best_model_state = None
    best_fold_num = 0
    
    for fold, (train_subj_idx, val_subj_idx) in enumerate(kf.split(unique_subjects)):
        print(f"\n{'='*60}")
        print(f"FOLD {fold+1}/{k_folds}")
        print(f"{'='*60}")
        
        train_subjs = unique_subjects[train_subj_idx]
        val_subjs = unique_subjects[val_subj_idx]
        
        train_mask = np.isin(subjects, train_subjs)
        val_mask = np.isin(subjects, val_subjs)
        
        X_train, y_train = X[train_mask], y[train_mask]
        X_val, y_val = X[val_mask], y[val_mask]
        
        print(f"Train (before aug): {len(X_train)} samples (subjects: {train_subjs})")
        print(f"Val: {len(X_val)} samples (subjects: {val_subjs})")
        
        if USE_AUGMENTATION:
            X_train_aug, y_train_aug = augment_data(X_train, y_train, factor=4)
            print(f"Train (after aug): {len(X_train_aug)} samples ({len(X_train_aug)//len(X_train)}x)")
        else:
            X_train_aug, y_train_aug = X_train, y_train
        
        print("\n2/5 - Creating DataLoaders...")
        train_ds = TensorDataset(torch.from_numpy(X_train_aug), torch.from_numpy(y_train_aug))
        val_ds = TensorDataset(torch.from_numpy(X_val), torch.from_numpy(y_val))
        
        train_loader = DataLoader(train_ds, batch_size=config.BATCH_SIZE, shuffle=True, num_workers=0)
        val_loader = DataLoader(val_ds, batch_size=config.BATCH_SIZE, shuffle=False, num_workers=0)
        
        print("\n3/5 - Initializing model...")
        model = SkeletonLSTMLight(
            num_class=config.NUM_CLASSES, 
            in_channels=config.IN_CHANNELS,
            num_joints=config.NUM_JOINTS,
            hidden_size=64,
            dropout=0.2
        )
        
        model.to(DEVICE)
        num_params = sum(p.numel() for p in model.parameters())
        print(f"  Parameters: {num_params:,}")
        
        optimizer = optim.Adam(model.parameters(), lr=0.001, weight_decay=1e-4)
        scheduler = optim.lr_scheduler.ReduceLROnPlateau(optimizer, mode='max', factor=0.5, patience=5)
        criterion = nn.CrossEntropyLoss()
        
        print(f"\n4/5 - Training ({MAX_EPOCHS} epochs, patience={PATIENCE})...")
        best_fold_acc = 0.0
        patience_counter = 0 
        
        for epoch in range(MAX_EPOCHS):
            model.train()
            train_loss = 0.0
            correct = 0
            total = 0
            
            loop = tqdm(train_loader, leave=False, desc=f"Epoch {epoch+1}/{MAX_EPOCHS}")
            
            for data, target in loop:
                data, target = data.to(DEVICE), target.to(DEVICE)
                
                optimizer.zero_grad()
                output = model(data)
                loss = criterion(output, target)
                loss.backward()
                optimizer.step()
                
                train_loss += loss.item()
                
                _, predicted = torch.max(output.data, 1)
                total += target.size(0)
                correct += (predicted == target).sum().item()
                
                loop.set_postfix(acc=100*correct/total, loss=loss.item())
            
            train_acc = 100 * correct / total
            
            model.eval()
            val_correct = 0
            val_total = 0
            with torch.no_grad():
                for data, target in val_loader:
                    data, target = data.to(DEVICE), target.to(DEVICE)
                    output = model(data)
                    _, predicted = torch.max(output.data, 1)
                    val_total += target.size(0)
                    val_correct += (predicted == target).sum().item()
            
            val_acc = 100 * val_correct / val_total
            scheduler.step(val_acc)
            
            current_lr = optimizer.param_groups[0]['lr']

            if val_acc > best_fold_acc:
                best_fold_acc = val_acc
                patience_counter = 0 
                
                model_path = models_dir / f"lstm_best_fold_{fold+1}.pt"
                torch.save(model.state_dict(), model_path)
                print(f"  Epoch {epoch+1:2d} - Train: {train_acc:.1f}% | Val: {val_acc:.1f}% | LR: {current_lr:.6f} | * BEST")
                
                if val_acc > best_overall_acc:
                    best_overall_acc = val_acc
                    best_model_state = model.state_dict().copy()
                    best_fold_num = fold + 1
            else:
                patience_counter += 1
                if epoch % 5 == 0 or patience_counter >= PATIENCE - 2:
                    print(f"  Epoch {epoch+1:2d} - Train: {train_acc:.1f}% | Val: {val_acc:.1f}% | LR: {current_lr:.6f}")

            if patience_counter >= PATIENCE:
                print(f"\n  Early Stopping! (no improvement for {PATIENCE} epochs)")
                break

        print(f"\n--> Fold {fold+1} Best: {best_fold_acc:.2f}%")
        fold_results.append(best_fold_acc)

    print(f"\n{'='*60}")
    print(f"LSTM SUMMARY")
    print(f"{'='*60}")
    print(f"Fold results: {[f'{r:.1f}%' for r in fold_results]}")
    print(f"Mean: {np.mean(fold_results):.2f}% (+/- {np.std(fold_results):.2f}%)")
    print(f"Best fold: {np.argmax(fold_results)+1} ({np.max(fold_results):.2f}%)")
    
    if best_model_state is not None:
        best_path = models_dir / 'lstm_best_model.pt'
        torch.save(best_model_state, best_path)
        print(f"\nBest model saved as: {best_path} ({best_overall_acc:.2f}%, fold {best_fold_num})")
    
    print(f"{'='*60}")


if __name__ == '__main__':
    main()
