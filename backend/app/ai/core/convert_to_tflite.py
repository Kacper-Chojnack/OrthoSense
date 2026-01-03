import torch
import torch.nn as nn
import numpy as np
import tensorflow as tf
import os

from tensorflow import keras
from tensorflow.keras import layers


MODEL_PATH = "lstm_best_model.pt"
TFLITE_PATH = "exercise_classifier.tflite"
NUM_CLASSES = 3
HIDDEN_SIZE = 64
NUM_JOINTS = 33
IN_CHANNELS = 3
MAX_FRAME = 60  


class SkeletonLSTMLight(nn.Module):
    def __init__(self):
        super().__init__()
        input_size = NUM_JOINTS * IN_CHANNELS
        self.lstm = nn.LSTM(input_size=input_size, hidden_size=HIDDEN_SIZE, num_layers=1, batch_first=True, bidirectional=True)
        self.dropout = nn.Dropout(0.2)
        self.fc = nn.Linear(HIDDEN_SIZE * 2, NUM_CLASSES)

def build_keras_model():
    inputs = keras.Input(batch_shape=(1, MAX_FRAME, NUM_JOINTS * IN_CHANNELS), name="input")
    
    x = layers.Bidirectional(layers.LSTM(HIDDEN_SIZE, return_sequences=True), name="lstm")(inputs)
    
    x = layers.GlobalAveragePooling1D()(x)
    
    x = layers.Dropout(0.2)(x)
    
    outputs = layers.Dense(NUM_CLASSES, activation='softmax', name="fc")(x)
    
    return keras.Model(inputs=inputs, outputs=outputs)

def transfer_weights(pt_model, tf_model):
    state = pt_model.state_dict()
    tf_lstm = tf_model.get_layer("lstm")

    fw_w_ih = state['lstm.weight_ih_l0'].numpy().T
    fw_w_hh = state['lstm.weight_hh_l0'].numpy().T
    
    fw_b_ih = state['lstm.bias_ih_l0'].numpy()
    fw_b_hh = state['lstm.bias_hh_l0'].numpy()
    fw_bias = fw_b_ih + fw_b_hh
    
    suffix = '_reverse'
    
    if f'lstm.weight_ih_l0{suffix}' not in state:
        keys = [k for k in state.keys() if 'reverse' in k or 'backward' in k]
        if keys:
            reverse_key_base = keys[0].replace('weight_ih_l0', '').replace('weight_hh_l0', '').replace('bias_ih_l0', '').replace('bias_hh_l0', '')
            suffix = reverse_key_base
        else:
            raise KeyError(f"Can't find the key: lstm.weight_ih_l0{suffix}")

    bw_w_ih = state[f'lstm.weight_ih_l0{suffix}'].numpy().T
    bw_w_hh = state[f'lstm.weight_hh_l0{suffix}'].numpy().T
    
    bw_b_ih = state[f'lstm.bias_ih_l0{suffix}'].numpy()
    bw_b_hh = state[f'lstm.bias_hh_l0{suffix}'].numpy()
    bw_bias = bw_b_ih + bw_b_hh
    
    tf_lstm.forward_layer.set_weights([fw_w_ih, fw_w_hh, fw_bias])
    tf_lstm.backward_layer.set_weights([bw_w_ih, bw_w_hh, bw_bias])

    tf_fc = tf_model.get_layer("fc")
    
    fc_w = state['fc.weight'].numpy().T
    fc_b = state['fc.bias'].numpy()
    
    tf_fc.set_weights([fc_w, fc_b])

def main():
    if not os.path.exists(MODEL_PATH):
        print(f"Can't find {MODEL_PATH}")
        return

    pt_model = SkeletonLSTMLight()
    state_dict = torch.load(MODEL_PATH, map_location="cpu")
    if "state_dict" in state_dict:
        state_dict = state_dict["state_dict"]
    
    clean_state = {k.replace("module.", ""): v for k, v in state_dict.items()}
    pt_model.load_state_dict(clean_state)
    pt_model.eval()

    tf_model = build_keras_model()
    
    dummy_input = tf.random.normal((1, MAX_FRAME, 99))
    tf_model(dummy_input)

    transfer_weights(pt_model, tf_model)
    
    tf_model.trainable = False
    
    with torch.no_grad():
        for test_idx in range(3):
            raw_data = np.random.randn(MAX_FRAME, NUM_JOINTS, IN_CHANNELS).astype(np.float32)
            
            hip_center = (raw_data[:, 23:24, :] + raw_data[:, 24:25, :]) / 2.0
            raw_data = raw_data - hip_center
            
            data = np.transpose(raw_data, (2, 0, 1)) 
            data = data[np.newaxis, :, :, :, np.newaxis]  
            pt_in = torch.from_numpy(data).float()
            
            pt_x = pt_in[:, :, :, :, 0].permute(0, 2, 3, 1).reshape(1, MAX_FRAME, 99)
            lstm_out, _ = pt_model.lstm(pt_x)
            pt_out = lstm_out.mean(dim=1)
            pt_fc_out = pt_model.fc(pt_out)
            pt_final = torch.softmax(pt_fc_out, dim=1).numpy()
            
            tf_in = pt_x.numpy()
            tf_final = tf_model(tf_in, training=False).numpy()
            
            diff = np.abs(pt_final - tf_final).max()
            
            if diff > 1e-4:
                pt_before_softmax = pt_fc_out.numpy()

                tf_model_no_softmax = keras.Model(
                    inputs=tf_model.input,
                    outputs=tf_model.get_layer("fc").output
                )
                tf_before_softmax = tf_model_no_softmax(tf_in, training=False).numpy()
                diff_before_softmax = np.abs(pt_before_softmax - tf_before_softmax).max()

    converter = tf.lite.TFLiteConverter.from_keras_model(tf_model)

    converter.target_spec.supported_ops = [
        tf.lite.OpsSet.TFLITE_BUILTINS, 
        tf.lite.OpsSet.SELECT_TF_OPS    
    ]
    
    converter._experimental_lower_tensor_list_ops = False
    
    tflite_model = converter.convert()

    with open(TFLITE_PATH, "wb") as f:
        f.write(tflite_model)
    
if __name__ == "__main__":
    main()