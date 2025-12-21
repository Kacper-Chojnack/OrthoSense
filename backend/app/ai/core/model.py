"""LSTM model for exercise classification."""

from pathlib import Path
from typing import Any

import numpy as np

from app.ai.core.config import (
    DROPOUT,
    HIDDEN_SIZE,
    INPUT_SIZE,
    LSTM_MODEL_PATH,
    NUM_CLASSES,
    NUM_LAYERS,
)
from app.core.logging import get_logger

logger = get_logger(__name__)


class LSTMModel:
    """Bi-LSTM model for exercise classification.

    Architecture:
        - Input: (batch, seq_len, 132) - 33 landmarks × 4 features
        - Bi-LSTM: 2 layers, 128 hidden units
        - Output: (batch, num_classes) - softmax probabilities
    """

    def __init__(self, model_path: Path | None = None) -> None:
        """Initialize LSTM model.

        Args:
            model_path: Path to trained .pt model file.
        """
        self._model_path = model_path or LSTM_MODEL_PATH
        self._model: Any = None
        self._device: Any = None
        self._initialized = False

    def initialize(self) -> bool:
        """Load model weights.

        Returns:
            True if loading successful, False otherwise.
        """
        if self._initialized:
            return True

        try:
            import torch
            import torch.nn as nn

            # Determine device
            self._device = torch.device("cuda" if torch.cuda.is_available() else "cpu")

            # Build model architecture
            class BiLSTMClassifier(nn.Module):
                def __init__(self) -> None:
                    super().__init__()
                    self.lstm = nn.LSTM(
                        input_size=INPUT_SIZE,
                        hidden_size=HIDDEN_SIZE,
                        num_layers=NUM_LAYERS,
                        batch_first=True,
                        bidirectional=True,
                        dropout=DROPOUT if NUM_LAYERS > 1 else 0,
                    )
                    self.fc = nn.Linear(HIDDEN_SIZE * 2, NUM_CLASSES)
                    self.dropout = nn.Dropout(DROPOUT)

                def forward(self, x: torch.Tensor) -> torch.Tensor:
                    lstm_out, _ = self.lstm(x)
                    # Use last timestep output
                    last_output = lstm_out[:, -1, :]
                    out = self.dropout(last_output)
                    return self.fc(out)

            self._model = BiLSTMClassifier()

            if self._model_path.exists():
                state_dict = torch.load(
                    self._model_path,
                    map_location=self._device,
                    weights_only=True,
                )
                self._model.load_state_dict(state_dict, strict=False)
                logger.info(
                    "lstm_model_loaded",
                    path=str(self._model_path),
                    device=str(self._device),
                )
            else:
                logger.warning(
                    "lstm_model_not_found_using_random",
                    path=str(self._model_path),
                )

            self._model.to(self._device)
            self._model.eval()
            self._initialized = True
            return True

        except ImportError as e:
            logger.error("torch_import_error", error=str(e))
            return False
        except Exception as e:
            logger.error("lstm_model_load_error", error=str(e))
            return False

    def predict(self, sequence: np.ndarray) -> tuple[int, float, np.ndarray]:
        """Classify exercise from landmark sequence.

        Args:
            sequence: Shape (seq_len, 132) - normalized landmark features.

        Returns:
            Tuple of (predicted_class, confidence, all_probabilities).
        """
        if not self._initialized and not self.initialize():
            return 0, 0.0, np.zeros(NUM_CLASSES)

        try:
            import torch

            with torch.no_grad():
                # Add batch dimension: (1, seq_len, 132)
                x = torch.FloatTensor(sequence).unsqueeze(0).to(self._device)
                logits = self._model(x)
                probs = torch.softmax(logits, dim=1).cpu().numpy()[0]

                predicted_class = int(np.argmax(probs))
                confidence = float(probs[predicted_class])

                return predicted_class, confidence, probs

        except Exception as e:
            logger.error("lstm_prediction_error", error=str(e))
            return 0, 0.0, np.zeros(NUM_CLASSES)
