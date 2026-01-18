"""OrthoSense AI System - minimal server-side coordinator.

Movement diagnostics are performed client-side (Edge AI) for privacy.
This module handles model integrity verification and provides exercise metadata.
"""

from pathlib import Path

import numpy as np

from app.ai.core.integrity import ModelIntegrityError, verify_model_integrity
from app.core.logging import get_logger

logger = get_logger(__name__)

# Default models directory (can be overridden via environment)
MODELS_DIR = Path(__file__).parent.parent.parent.parent.parent / "assets" / "models"


class OrthoSenseSystem:
    """Singleton AI coordinator - provides exercise metadata and model verification."""

    _instance: "OrthoSenseSystem | None" = None
    _initialized: bool

    def __new__(cls) -> "OrthoSenseSystem":
        if cls._instance is None:
            cls._instance = super().__new__(cls)
            cls._instance._initialized = False
            cls._instance._models_verified = False
        return cls._instance

    def initialize(self, *, verify_models: bool = True) -> bool:
        """Init system. Verifies model integrity if enabled."""
        if verify_models and not self._models_verified:
            self._verify_models()
        self._initialized = True
        return True

    def _verify_models(self) -> None:
        """Check model file integrity."""
        model_path = MODELS_DIR / "exercise_classifier.tflite"
        if model_path.exists():
            try:
                verify_model_integrity(model_path)
                self._models_verified = True
                logger.info("model_integrity_ok")
            except ModelIntegrityError as e:
                logger.error("model_integrity_fail", error=str(e))
                raise
        else:
            # model loaded on demand
            logger.warning("model_missing", path=str(model_path))
            self._models_verified = True

    @property
    def is_initialized(self) -> bool:
        return self._initialized

    def close(self) -> None:
        self._initialized = False

    def _make_serializable(self, obj):
        """Convert numpy types to JSON-safe python types."""
        if isinstance(obj, dict):
            return {k: self._make_serializable(v) for k, v in obj.items()}
        if isinstance(obj, list):
            return [self._make_serializable(x) for x in obj]
        if isinstance(obj, np.integer):
            return int(obj)
        if isinstance(obj, np.floating):
            return float(obj)
        if isinstance(obj, np.ndarray):
            return obj.tolist()
        return obj
