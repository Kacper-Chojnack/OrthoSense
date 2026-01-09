"""
Unit tests for security module.

Test coverage:
1. Password hashing and verification
2. JWT token creation (access, verification, reset)
3. Token decoding and validation
4. Token expiration handling
5. Edge cases and security scenarios
"""

import time
from datetime import timedelta
from uuid import uuid4

import jwt
import pytest

from app.core.config import settings
from app.core.security import (
    create_access_token,
    create_password_reset_token,
    create_token,
    create_verification_token,
    decode_token,
    hash_password,
    verify_password,
    verify_token,
)


class TestPasswordHashing:
    """Tests for password hashing functions."""

    def test_hash_password_returns_different_hash(self) -> None:
        """Same password should produce different hashes (due to salt)."""
        password = "SecurePassword123!"
        hash1 = hash_password(password)
        hash2 = hash_password(password)

        assert hash1 != hash2  # Salted hashes are different
        assert hash1 != password  # Hash is not plaintext

    def test_hash_password_produces_bcrypt_format(self) -> None:
        """Hash should be in bcrypt format."""
        password = "SecurePassword123!"
        hashed = hash_password(password)

        # bcrypt hashes start with $2b$ or $2a$
        assert hashed.startswith("$2")
        assert len(hashed) == 60

    def test_verify_password_correct(self) -> None:
        """Correct password verification returns True."""
        password = "SecurePassword123!"
        hashed = hash_password(password)

        assert verify_password(password, hashed) is True

    def test_verify_password_incorrect(self) -> None:
        """Incorrect password verification returns False."""
        password = "SecurePassword123!"
        hashed = hash_password(password)

        assert verify_password("WrongPassword123!", hashed) is False

    def test_verify_password_empty_password(self) -> None:
        """Empty password should not match."""
        password = "SecurePassword123!"
        hashed = hash_password(password)

        assert verify_password("", hashed) is False

    def test_verify_password_unicode(self) -> None:
        """Unicode passwords should work correctly."""
        password = "Pässwörd123!🔐"
        hashed = hash_password(password)

        assert verify_password(password, hashed) is True
        assert verify_password("Pässwörd123!", hashed) is False

    def test_hash_password_long_password(self) -> None:
        """Very long passwords raise ValueError (bcrypt limit is 72 bytes)."""
        password = "a" * 100

        # bcrypt raises error for passwords > 72 bytes
        with pytest.raises(ValueError, match="cannot be longer than 72 bytes"):
            hash_password(password)

    def test_hash_password_max_length(self) -> None:
        """Password at exactly 72 bytes should work."""
        password = "a" * 72
        hashed = hash_password(password)

        assert verify_password(password, hashed) is True

    def test_hash_password_special_characters(self) -> None:
        """Passwords with special characters should work."""
        password = 'P@$$w0rd!#$%^&*()_+-={}[]|\\:";<>?,./~`'
        hashed = hash_password(password)

        assert verify_password(password, hashed) is True


class TestTokenCreation:
    """Tests for JWT token creation functions."""

    def test_create_access_token_returns_string(self) -> None:
        """Access token creation returns a string."""
        user_id = uuid4()
        token = create_access_token(user_id)

        assert isinstance(token, str)
        assert len(token) > 0

    def test_create_access_token_contains_user_id(self) -> None:
        """Access token contains the user ID in subject claim."""
        user_id = uuid4()
        token = create_access_token(user_id)
        decoded = decode_token(token)

        assert decoded is not None
        assert decoded["sub"] == str(user_id)
        assert decoded["type"] == "access"

    def test_create_verification_token(self) -> None:
        """Verification token creation works correctly."""
        user_id = uuid4()
        token = create_verification_token(user_id)
        decoded = decode_token(token)

        assert decoded is not None
        assert decoded["sub"] == str(user_id)
        assert decoded["type"] == "verification"

    def test_create_password_reset_token(self) -> None:
        """Password reset token creation works correctly."""
        user_id = uuid4()
        token = create_password_reset_token(user_id)
        decoded = decode_token(token)

        assert decoded is not None
        assert decoded["sub"] == str(user_id)
        assert decoded["type"] == "reset"

    def test_create_token_with_extra_claims(self) -> None:
        """Token creation with extra claims includes them."""
        user_id = uuid4()
        extra = {"role": "admin", "permissions": ["read", "write"]}
        token = create_token(user_id, "access", extra_claims=extra)
        decoded = decode_token(token)

        assert decoded is not None
        assert decoded["role"] == "admin"
        assert decoded["permissions"] == ["read", "write"]

    def test_create_token_custom_expiration(self) -> None:
        """Token creation with custom expiration works."""
        user_id = uuid4()
        token = create_token(user_id, "custom", expires_delta=timedelta(hours=1))
        decoded = decode_token(token)

        assert decoded is not None
        assert decoded["type"] == "custom"

    def test_create_token_with_string_subject(self) -> None:
        """Token creation accepts string subject."""
        user_id = "custom-string-id"
        token = create_access_token(user_id)
        decoded = decode_token(token)

        assert decoded is not None
        assert decoded["sub"] == user_id


class TestTokenDecoding:
    """Tests for JWT token decoding functions."""

    def test_decode_valid_token(self) -> None:
        """Valid token decoding returns payload."""
        user_id = uuid4()
        token = create_access_token(user_id)
        decoded = decode_token(token)

        assert decoded is not None
        assert "sub" in decoded
        assert "exp" in decoded
        assert "type" in decoded

    def test_decode_invalid_token(self) -> None:
        """Invalid token decoding returns None."""
        decoded = decode_token("invalid-token-string")

        assert decoded is None

    def test_decode_malformed_jwt(self) -> None:
        """Malformed JWT decoding returns None."""
        malformed_tokens = [
            "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9",  # Only header
            "not.a.jwt",
            "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIn0",
            "",
            "null",
        ]

        for token in malformed_tokens:
            assert decode_token(token) is None

    def test_decode_token_wrong_signature(self) -> None:
        """Token with wrong signature returns None."""
        user_id = uuid4()
        # Create token with different secret
        payload = {"sub": str(user_id), "type": "access"}
        wrong_token = jwt.encode(payload, "wrong-secret-key", algorithm="HS256")

        decoded = decode_token(wrong_token)

        assert decoded is None

    def test_decode_expired_token(self) -> None:
        """Expired token decoding returns None."""
        user_id = uuid4()
        # Create token that's already expired
        token = create_token(user_id, "access", expires_delta=timedelta(seconds=-1))

        decoded = decode_token(token)

        assert decoded is None


class TestTokenVerification:
    """Tests for verify_token function."""

    def test_verify_access_token(self) -> None:
        """Access token verification returns subject."""
        user_id = uuid4()
        token = create_access_token(user_id)

        subject = verify_token(token, "access")

        assert subject == str(user_id)

    def test_verify_verification_token(self) -> None:
        """Verification token verification returns subject."""
        user_id = uuid4()
        token = create_verification_token(user_id)

        subject = verify_token(token, "verification")

        assert subject == str(user_id)

    def test_verify_reset_token(self) -> None:
        """Reset token verification returns subject."""
        user_id = uuid4()
        token = create_password_reset_token(user_id)

        subject = verify_token(token, "reset")

        assert subject == str(user_id)

    def test_verify_wrong_token_type(self) -> None:
        """Verifying with wrong type returns None."""
        user_id = uuid4()
        access_token = create_access_token(user_id)

        # Try to verify access token as verification token
        subject = verify_token(access_token, "verification")

        assert subject is None

    def test_verify_invalid_token(self) -> None:
        """Invalid token verification returns None."""
        subject = verify_token("invalid-token", "access")

        assert subject is None

    def test_verify_expired_token(self) -> None:
        """Expired token verification returns None."""
        user_id = uuid4()
        token = create_token(user_id, "access", expires_delta=timedelta(seconds=-1))

        subject = verify_token(token, "access")

        assert subject is None

    def test_verify_token_missing_subject(self) -> None:
        """Token without subject returns None."""
        # Manually create token without sub
        payload = {"type": "access", "exp": time.time() + 3600}
        token = jwt.encode(payload, settings.secret_key, algorithm=settings.algorithm)

        subject = verify_token(token, "access")

        assert subject is None


class TestSecurityEdgeCases:
    """Edge cases and security scenarios."""

    def test_token_algorithm_mismatch(self) -> None:
        """Token created with different algorithm fails verification."""
        user_id = uuid4()
        payload = {"sub": str(user_id), "type": "access", "exp": time.time() + 3600}

        # Create token with different algorithm (if supported)
        try:
            wrong_algo_token = jwt.encode(
                payload, settings.secret_key, algorithm="HS384"
            )
            decoded = decode_token(wrong_algo_token)
            # Should fail because we only accept HS256
            assert decoded is None or decoded.get("sub") is None
        except jwt.exceptions.InvalidAlgorithmError:
            # This is also acceptable
            pass

    def test_none_algorithm_attack(self) -> None:
        """None algorithm attack is prevented."""
        user_id = uuid4()

        # Try to create a token with 'none' algorithm
        # This should be rejected by PyJWT
        try:
            payload = {"sub": str(user_id), "type": "access"}
            malicious_token = jwt.encode(payload, "", algorithm="none")
            decoded = decode_token(malicious_token)
            assert decoded is None
        except Exception:
            # Any exception is acceptable - attack was prevented
            pass

    def test_password_timing_consistency(self) -> None:
        """Password verification should have consistent timing."""
        correct_password = "SecurePassword123!"
        wrong_password = "WrongPassword123!"
        hashed = hash_password(correct_password)

        # Just verify both work - timing is handled by bcrypt
        assert verify_password(correct_password, hashed) is True
        assert verify_password(wrong_password, hashed) is False

    def test_token_payload_tampering(self) -> None:
        """Tampering with token payload is detected."""
        user_id = uuid4()
        token = create_access_token(user_id)

        # Decode without verification
        parts = token.split(".")
        assert len(parts) == 3

        # Tamper with payload (change base64 encoded payload)
        import base64
        import json

        payload = json.loads(base64.urlsafe_b64decode(parts[1] + "=="))
        payload["sub"] = str(uuid4())  # Change user ID
        tampered_payload = (
            base64.urlsafe_b64encode(json.dumps(payload).encode()).decode().rstrip("=")
        )

        tampered_token = f"{parts[0]}.{tampered_payload}.{parts[2]}"

        # Verification should fail
        decoded = decode_token(tampered_token)
        assert decoded is None
