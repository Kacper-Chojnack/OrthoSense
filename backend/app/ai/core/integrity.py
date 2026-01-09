"""Model integrity verification using SHA256.

Ensures AI model files haven't been tampered with before loading.
Critical for security in healthcare applications.
"""

import hashlib
from pathlib import Path

from app.core.logging import get_logger

logger = get_logger(__name__)


# Known SHA256 hashes of trusted model files
# Update these when deploying new model versions
MODEL_HASHES: dict[str, str] = {
    # TFLite exercise classifier model
    "exercise_classifier.tflite": "",  # TODO: Set actual hash on deployment
    # Add other model files here as needed
}


class ModelIntegrityError(Exception):
    """Raised when model integrity verification fails."""

    def __init__(self, model_path: str, expected: str, actual: str) -> None:
        self.model_path = model_path
        self.expected = expected
        self.actual = actual
        super().__init__(
            f"Model integrity check failed for {model_path}. "
            f"Expected hash: {expected[:16]}..., Got: {actual[:16]}..."
        )


def calculate_sha256(file_path: Path) -> str:
    """Calculate SHA256 hash of a file.

    Args:
        file_path: Path to the file to hash.

    Returns:
        Hex string of SHA256 hash.

    Raises:
        FileNotFoundError: If file doesn't exist.
        IOError: If file cannot be read.
    """
    sha256_hash = hashlib.sha256()
    with open(file_path, "rb") as f:
        # Read in 64kb chunks for memory efficiency
        for chunk in iter(lambda: f.read(65536), b""):
            sha256_hash.update(chunk)
    return sha256_hash.hexdigest()


def verify_model_integrity(
    model_path: Path,
    *,
    expected_hash: str | None = None,
    skip_if_hash_empty: bool = True,
) -> bool:
    """Verify integrity of a model file using SHA256.

    Args:
        model_path: Path to the model file.
        expected_hash: Expected SHA256 hash. If None, looks up in MODEL_HASHES.
        skip_if_hash_empty: If True, skip verification if hash is empty/not set.
            Useful during development when hashes aren't yet configured.

    Returns:
        True if verification passes or is skipped.

    Raises:
        ModelIntegrityError: If hash doesn't match.
        FileNotFoundError: If model file doesn't exist.
    """
    if not model_path.exists():
        raise FileNotFoundError(f"Model file not found: {model_path}")

    model_name = model_path.name

    # Get expected hash
    if expected_hash is None:
        expected_hash = MODEL_HASHES.get(model_name, "")

    # Skip if hash not configured and flag is set
    if not expected_hash and skip_if_hash_empty:
        logger.warning(
            "model_integrity_skip",
            model=model_name,
            reason="Hash not configured",
        )
        return True

    # Calculate actual hash
    actual_hash = calculate_sha256(model_path)

    # Verify
    if actual_hash != expected_hash:
        logger.error(
            "model_integrity_failed",
            model=model_name,
            expected_hash=expected_hash[:16] + "...",
            actual_hash=actual_hash[:16] + "...",
        )
        raise ModelIntegrityError(str(model_path), expected_hash, actual_hash)

    logger.info(
        "model_integrity_verified",
        model=model_name,
        hash=actual_hash[:16] + "...",
    )
    return True


def generate_model_hash(model_path: Path) -> str:
    """Generate and print SHA256 hash for a model file.

    Utility function for setting up MODEL_HASHES during deployment.

    Args:
        model_path: Path to the model file.

    Returns:
        SHA256 hash string.
    """
    hash_value = calculate_sha256(model_path)
    print(f'"{model_path.name}": "{hash_value}",')
    return hash_value


def verify_all_models(models_dir: Path) -> dict[str, bool]:
    """Verify all known models in a directory.

    Args:
        models_dir: Directory containing model files.

    Returns:
        Dict mapping model names to verification status.
    """
    results: dict[str, bool] = {}

    for model_name in MODEL_HASHES:
        model_path = models_dir / model_name
        try:
            results[model_name] = verify_model_integrity(model_path)
        except FileNotFoundError:
            logger.warning("model_not_found", model=model_name)
            results[model_name] = False
        except ModelIntegrityError:
            results[model_name] = False

    return results
