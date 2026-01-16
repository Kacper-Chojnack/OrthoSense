"""
Unit tests for Model Integrity verification module.

Test coverage:
1. ModelIntegrityError exception
2. calculate_sha256 function
3. verify_model_integrity function
4. generate_model_hash function
5. verify_all_models function
"""

import hashlib
import tempfile
from pathlib import Path
from unittest.mock import patch

import pytest

from app.ai.core.integrity import (
    MODEL_HASHES,
    ModelIntegrityError,
    calculate_sha256,
    generate_model_hash,
    verify_all_models,
    verify_model_integrity,
)


class TestModelIntegrityError:
    """Tests for ModelIntegrityError exception class."""

    def test_error_stores_attributes(self) -> None:
        """ModelIntegrityError stores model path and hashes."""
        error = ModelIntegrityError(
            model_path="/path/to/model.tflite",
            expected="abc123def456",
            actual="xyz789uvw012",
        )

        assert error.model_path == "/path/to/model.tflite"
        assert error.expected == "abc123def456"
        assert error.actual == "xyz789uvw012"

    def test_error_message_format(self) -> None:
        """ModelIntegrityError message is properly formatted."""
        error = ModelIntegrityError(
            model_path="/models/classifier.tflite",
            expected="abcdef1234567890abcdef1234567890",
            actual="1234567890abcdef1234567890abcdef",
        )

        message = str(error)
        assert "integrity check failed" in message.lower()
        assert "classifier.tflite" in message
        # Shows truncated hashes
        assert "abcdef12345678" in message
        assert "12345678" in message

    def test_error_is_exception(self) -> None:
        """ModelIntegrityError is a proper exception."""
        error = ModelIntegrityError(
            model_path="test.model",
            expected="a" * 32,
            actual="b" * 32,
        )

        assert isinstance(error, Exception)

        with pytest.raises(ModelIntegrityError):
            raise error


class TestCalculateSha256:
    """Tests for calculate_sha256 function."""

    def test_calculate_hash_for_file(self) -> None:
        """SHA256 hash is calculated correctly for a file."""
        with tempfile.NamedTemporaryFile(delete=False, suffix=".bin") as f:
            f.write(b"test content for hashing")
            temp_path = Path(f.name)

        try:
            result = calculate_sha256(temp_path)

            # Verify it's a valid hex SHA256 hash (64 characters)
            assert len(result) == 64
            assert all(c in "0123456789abcdef" for c in result)

            # Calculate expected hash directly
            expected = hashlib.sha256(b"test content for hashing").hexdigest()
            assert result == expected
        finally:
            temp_path.unlink()

    def test_calculate_hash_empty_file(self) -> None:
        """SHA256 hash is calculated correctly for empty file."""
        with tempfile.NamedTemporaryFile(delete=False, suffix=".bin") as f:
            temp_path = Path(f.name)

        try:
            result = calculate_sha256(temp_path)

            # Empty file has a specific SHA256 hash
            expected = hashlib.sha256(b"").hexdigest()
            assert result == expected
        finally:
            temp_path.unlink()

    def test_calculate_hash_large_file(self) -> None:
        """SHA256 hash is calculated correctly for large file."""
        with tempfile.NamedTemporaryFile(delete=False, suffix=".bin") as f:
            # Write 1MB of data
            data = b"x" * (1024 * 1024)
            f.write(data)
            temp_path = Path(f.name)

        try:
            result = calculate_sha256(temp_path)

            expected = hashlib.sha256(data).hexdigest()
            assert result == expected
        finally:
            temp_path.unlink()

    def test_calculate_hash_file_not_found(self) -> None:
        """FileNotFoundError is raised for non-existent file."""
        non_existent = Path("/path/to/non_existent_file.bin")

        with pytest.raises(FileNotFoundError):
            calculate_sha256(non_existent)

    def test_calculate_hash_binary_content(self) -> None:
        """SHA256 handles binary content correctly."""
        with tempfile.NamedTemporaryFile(delete=False, suffix=".bin") as f:
            # Write binary content including null bytes
            binary_data = bytes(range(256))
            f.write(binary_data)
            temp_path = Path(f.name)

        try:
            result = calculate_sha256(temp_path)

            expected = hashlib.sha256(binary_data).hexdigest()
            assert result == expected
        finally:
            temp_path.unlink()


class TestVerifyModelIntegrity:
    """Tests for verify_model_integrity function."""

    def test_verify_passes_with_matching_hash(self) -> None:
        """Verification passes when hash matches."""
        with tempfile.NamedTemporaryFile(delete=False, suffix=".tflite") as f:
            f.write(b"model content")
            temp_path = Path(f.name)

        try:
            expected_hash = hashlib.sha256(b"model content").hexdigest()
            result = verify_model_integrity(
                temp_path,
                expected_hash=expected_hash,
            )

            assert result is True
        finally:
            temp_path.unlink()

    def test_verify_raises_on_hash_mismatch(self) -> None:
        """Verification raises ModelIntegrityError on hash mismatch."""
        with tempfile.NamedTemporaryFile(delete=False, suffix=".tflite") as f:
            f.write(b"model content")
            temp_path = Path(f.name)

        try:
            wrong_hash = "a" * 64  # Wrong hash

            with pytest.raises(ModelIntegrityError) as exc_info:
                verify_model_integrity(
                    temp_path,
                    expected_hash=wrong_hash,
                    skip_if_hash_empty=False,
                )

            assert exc_info.value.expected == wrong_hash
        finally:
            temp_path.unlink()

    def test_verify_file_not_found(self) -> None:
        """Verification raises FileNotFoundError for missing file."""
        non_existent = Path("/path/to/missing_model.tflite")

        with pytest.raises(FileNotFoundError) as exc_info:
            verify_model_integrity(non_existent)

        assert "not found" in str(exc_info.value).lower()

    def test_verify_skips_when_hash_empty(self) -> None:
        """Verification skips when hash is empty and skip_if_hash_empty=True."""
        with tempfile.NamedTemporaryFile(delete=False, suffix=".tflite") as f:
            f.write(b"model content")
            temp_path = Path(f.name)

        try:
            # With empty expected_hash and skip_if_hash_empty=True (default)
            result = verify_model_integrity(
                temp_path,
                expected_hash="",
                skip_if_hash_empty=True,
            )

            assert result is True
        finally:
            temp_path.unlink()

    def test_verify_does_not_skip_when_flag_false(self) -> None:
        """Verification raises when hash empty and skip_if_hash_empty=False."""
        with tempfile.NamedTemporaryFile(delete=False, suffix=".tflite") as f:
            f.write(b"model content")
            temp_path = Path(f.name)

        try:
            # Empty hash should fail when skip_if_hash_empty=False
            with pytest.raises(ModelIntegrityError):
                verify_model_integrity(
                    temp_path,
                    expected_hash="",
                    skip_if_hash_empty=False,
                )
        finally:
            temp_path.unlink()

    def test_verify_uses_model_hashes_lookup(self) -> None:
        """Verification looks up hash from MODEL_HASHES."""
        with tempfile.NamedTemporaryFile(
            delete=False,
            suffix=".tflite",
            prefix="test_model_",
        ) as f:
            f.write(b"test model data")
            temp_path = Path(f.name)

        try:
            # Without expected_hash, should lookup in MODEL_HASHES
            # Since the model name won't be in MODEL_HASHES, it should skip
            result = verify_model_integrity(temp_path)
            assert result is True  # Skips because hash not configured
        finally:
            temp_path.unlink()


class TestGenerateModelHash:
    """Tests for generate_model_hash function."""

    def test_generate_hash_returns_correct_hash(self) -> None:
        """generate_model_hash returns correct SHA256 hash."""
        with tempfile.NamedTemporaryFile(delete=False, suffix=".tflite") as f:
            f.write(b"model data for hash generation")
            temp_path = Path(f.name)

        try:
            result = generate_model_hash(temp_path)

            expected = hashlib.sha256(b"model data for hash generation").hexdigest()
            assert result == expected
        finally:
            temp_path.unlink()

    def test_generate_hash_prints_formatted_output(self, capsys) -> None:
        """generate_model_hash prints formatted output for copy-paste."""
        with tempfile.NamedTemporaryFile(
            delete=False,
            suffix=".tflite",
            prefix="my_model_",
        ) as f:
            f.write(b"model content")
            temp_path = Path(f.name)

        try:
            hash_value = generate_model_hash(temp_path)
            captured = capsys.readouterr()

            # Should print in dict format for easy copy-paste
            assert temp_path.name in captured.out
            assert hash_value in captured.out
            assert ":" in captured.out
        finally:
            temp_path.unlink()


class TestVerifyAllModels:
    """Tests for verify_all_models function."""

    def test_verify_all_models_empty_directory(self) -> None:
        """verify_all_models returns empty dict for empty MODEL_HASHES."""
        with tempfile.TemporaryDirectory() as temp_dir:
            models_dir = Path(temp_dir)

            with patch.dict("app.ai.core.integrity.MODEL_HASHES", {}, clear=True):
                results = verify_all_models(models_dir)

            assert results == {}

    def test_verify_all_models_missing_model(self) -> None:
        """verify_all_models handles missing model files."""
        with tempfile.TemporaryDirectory() as temp_dir:
            models_dir = Path(temp_dir)

            with patch.dict(
                "app.ai.core.integrity.MODEL_HASHES",
                {"missing_model.tflite": "abc123"},
                clear=True,
            ):
                results = verify_all_models(models_dir)

            assert results["missing_model.tflite"] is False

    def test_verify_all_models_present_model(self) -> None:
        """verify_all_models verifies present model files."""
        with tempfile.TemporaryDirectory() as temp_dir:
            models_dir = Path(temp_dir)

            # Create a model file
            model_content = b"test model content"
            model_path = models_dir / "test_model.tflite"
            model_path.write_bytes(model_content)

            correct_hash = hashlib.sha256(model_content).hexdigest()

            with patch.dict(
                "app.ai.core.integrity.MODEL_HASHES",
                {"test_model.tflite": correct_hash},
                clear=True,
            ):
                results = verify_all_models(models_dir)

            assert results["test_model.tflite"] is True

    def test_verify_all_models_mixed_results(self) -> None:
        """verify_all_models returns mixed results for multiple models."""
        with tempfile.TemporaryDirectory() as temp_dir:
            models_dir = Path(temp_dir)

            # Create one valid model
            valid_content = b"valid model"
            valid_path = models_dir / "valid.tflite"
            valid_path.write_bytes(valid_content)
            valid_hash = hashlib.sha256(valid_content).hexdigest()

            # Create one model with wrong hash
            invalid_content = b"invalid model"
            invalid_path = models_dir / "invalid.tflite"
            invalid_path.write_bytes(invalid_content)
            wrong_hash = "x" * 64

            with patch.dict(
                "app.ai.core.integrity.MODEL_HASHES",
                {
                    "valid.tflite": valid_hash,
                    "invalid.tflite": wrong_hash,
                    "missing.tflite": "abc123",
                },
                clear=True,
            ):
                results = verify_all_models(models_dir)

            assert results["valid.tflite"] is True
            assert results["invalid.tflite"] is False
            assert results["missing.tflite"] is False

    def test_verify_all_models_empty_hash_skips(self) -> None:
        """verify_all_models skips models with empty hash."""
        with tempfile.TemporaryDirectory() as temp_dir:
            models_dir = Path(temp_dir)

            # Create model file
            model_path = models_dir / "skip_me.tflite"
            model_path.write_bytes(b"content")

            with patch.dict(
                "app.ai.core.integrity.MODEL_HASHES",
                {"skip_me.tflite": ""},  # Empty hash
                clear=True,
            ):
                results = verify_all_models(models_dir)

            # Should return True (skipped, not failed)
            assert results["skip_me.tflite"] is True


class TestModelHashesConstant:
    """Tests for MODEL_HASHES constant."""

    def test_model_hashes_is_dict(self) -> None:
        """MODEL_HASHES is a dictionary."""
        assert isinstance(MODEL_HASHES, dict)

    def test_model_hashes_contains_expected_keys(self) -> None:
        """MODEL_HASHES contains expected model keys."""
        # Should contain the TFLite model at minimum
        assert "exercise_classifier.tflite" in MODEL_HASHES

    def test_model_hashes_values_are_strings(self) -> None:
        """MODEL_HASHES values are all strings."""
        for key, value in MODEL_HASHES.items():
            assert isinstance(key, str)
            assert isinstance(value, str)
