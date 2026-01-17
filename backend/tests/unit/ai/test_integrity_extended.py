"""Extended unit tests for integrity module.

Test coverage:
1. SHA256 calculation
2. Model integrity verification
3. Error handling
"""

import hashlib
import tempfile
from pathlib import Path

import pytest

from app.ai.core.integrity import (
    MODEL_HASHES,
    ModelIntegrityError,
    calculate_sha256,
    verify_model_integrity,
)


class TestCalculateSHA256:
    """Test SHA256 hash calculation."""

    def test_calculates_hash_for_file(self):
        """Should calculate correct hash for file."""
        with tempfile.NamedTemporaryFile(delete=False) as f:
            f.write(b"test content")
            f.flush()
            temp_path = Path(f.name)

        try:
            result = calculate_sha256(temp_path)

            # Calculate expected hash
            expected = hashlib.sha256(b"test content").hexdigest()

            assert result == expected
        finally:
            temp_path.unlink()

    def test_returns_hex_string(self):
        """Should return hexadecimal string."""
        with tempfile.NamedTemporaryFile(delete=False) as f:
            f.write(b"test")
            f.flush()
            temp_path = Path(f.name)

        try:
            result = calculate_sha256(temp_path)

            assert isinstance(result, str)
            assert len(result) == 64  # SHA256 hex is 64 chars
            assert all(c in "0123456789abcdef" for c in result)
        finally:
            temp_path.unlink()

    def test_raises_for_missing_file(self):
        """Should raise FileNotFoundError for missing file."""
        fake_path = Path("/nonexistent/path/file.txt")

        with pytest.raises(FileNotFoundError):
            calculate_sha256(fake_path)

    def test_handles_empty_file(self):
        """Should handle empty file."""
        with tempfile.NamedTemporaryFile(delete=False) as f:
            temp_path = Path(f.name)

        try:
            result = calculate_sha256(temp_path)

            # Hash of empty string
            expected = hashlib.sha256(b"").hexdigest()

            assert result == expected
        finally:
            temp_path.unlink()

    def test_handles_large_file(self):
        """Should handle large file efficiently."""
        with tempfile.NamedTemporaryFile(delete=False) as f:
            # Write 1MB of data
            f.write(b"x" * (1024 * 1024))
            f.flush()
            temp_path = Path(f.name)

        try:
            result = calculate_sha256(temp_path)

            assert isinstance(result, str)
            assert len(result) == 64
        finally:
            temp_path.unlink()


class TestModelIntegrityError:
    """Test ModelIntegrityError exception."""

    def test_creates_with_all_args(self):
        """Should create exception with all arguments."""
        error = ModelIntegrityError(
            model_path="/path/to/model.tflite",
            expected="abc123",
            actual="def456",
        )

        assert error.model_path == "/path/to/model.tflite"
        assert error.expected == "abc123"
        assert error.actual == "def456"

    def test_message_contains_path(self):
        """Error message should contain model path."""
        error = ModelIntegrityError(
            model_path="/path/to/model.tflite",
            expected="abc123",
            actual="def456",
        )

        assert "/path/to/model.tflite" in str(error)

    def test_message_truncates_hashes(self):
        """Error message should truncate hash display."""
        error = ModelIntegrityError(
            model_path="model.tflite",
            expected="a" * 64,
            actual="b" * 64,
        )

        message = str(error)

        # Should show truncated versions
        assert "..." in message


class TestVerifyModelIntegrity:
    """Test model integrity verification."""

    def test_raises_for_missing_file(self):
        """Should raise FileNotFoundError for missing file."""
        fake_path = Path("/nonexistent/model.tflite")

        with pytest.raises(FileNotFoundError):
            verify_model_integrity(fake_path)

    def test_skips_verification_when_hash_empty(self):
        """Should skip verification when hash not configured."""
        with tempfile.NamedTemporaryFile(delete=False, suffix=".tflite") as f:
            f.write(b"fake model data")
            f.flush()
            temp_path = Path(f.name)

        try:
            # Should not raise when skip_if_hash_empty=True (default)
            result = verify_model_integrity(temp_path, skip_if_hash_empty=True)

            assert result is True
        finally:
            temp_path.unlink()

    def test_passes_with_correct_hash(self):
        """Should pass when hash matches."""
        with tempfile.NamedTemporaryFile(delete=False, suffix=".tflite") as f:
            content = b"test model content"
            f.write(content)
            f.flush()
            temp_path = Path(f.name)

        try:
            expected_hash = hashlib.sha256(content).hexdigest()

            result = verify_model_integrity(
                temp_path,
                expected_hash=expected_hash,
            )

            assert result is True
        finally:
            temp_path.unlink()

    def test_raises_with_wrong_hash(self):
        """Should raise when hash doesn't match."""
        with tempfile.NamedTemporaryFile(delete=False, suffix=".tflite") as f:
            f.write(b"test model content")
            f.flush()
            temp_path = Path(f.name)

        try:
            wrong_hash = "a" * 64

            with pytest.raises(ModelIntegrityError):
                verify_model_integrity(
                    temp_path,
                    expected_hash=wrong_hash,
                    raise_on_mismatch=True,
                )
        finally:
            temp_path.unlink()

    def test_returns_false_when_not_raising(self):
        """Should return False when raise_on_mismatch=False."""
        with tempfile.NamedTemporaryFile(delete=False, suffix=".tflite") as f:
            f.write(b"test model content")
            f.flush()
            temp_path = Path(f.name)

        try:
            wrong_hash = "a" * 64

            result = verify_model_integrity(
                temp_path,
                expected_hash=wrong_hash,
                raise_on_mismatch=False,
            )

            assert result is False
        finally:
            temp_path.unlink()


class TestModelHashes:
    """Test MODEL_HASHES configuration."""

    def test_contains_exercise_classifier(self):
        """Should have entry for exercise_classifier.tflite."""
        assert "exercise_classifier.tflite" in MODEL_HASHES

    def test_hash_is_string(self):
        """Hash values should be strings."""
        for _, hash_value in MODEL_HASHES.items():
            assert isinstance(hash_value, str)

    def test_hash_format(self):
        """Non-empty hashes should be valid hex."""
        for _, hash_value in MODEL_HASHES.items():
            if hash_value:  # Skip empty placeholder
                assert len(hash_value) == 64
                assert all(c in "0123456789abcdef" for c in hash_value.lower())
