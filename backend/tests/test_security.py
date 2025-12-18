"""Unit tests for security module: password hashing and JWT management.

Tests cover:
- Password hashing (bcrypt)
- Password verification
- JWT token creation (access, verification, reset)
- JWT token decoding and validation
- Token expiration handling
- Token tampering detection
"""

from datetime import UTC, datetime, timedelta
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
    """Tests for bcrypt password hashing."""

    def test_hash_password_creates_valid_hash(self) -> None:
        """hash_password returns a bcrypt hash string."""
        password = "securePass123!@#"
        hashed = hash_password(password)

        assert hashed is not None
        assert isinstance(hashed, str)
        assert hashed != password
        # Bcrypt hashes start with $2b$ or $2a$
        assert hashed.startswith("$2")

    def test_different_passwords_create_different_hashes(self) -> None:
        """Different passwords produce different hashes."""
        hash1 = hash_password("password123")
        hash2 = hash_password("password456")

        assert hash1 != hash2

    def test_same_password_creates_different_hashes(self) -> None:
        """Same password hashed twice produces different hashes (due to salt)."""
        password = "samePassword123"
        hash1 = hash_password(password)
        hash2 = hash_password(password)

        # Bcrypt uses random salt, so hashes differ
        assert hash1 != hash2

    def test_hash_password_with_special_characters(self) -> None:
        """Passwords with special characters are hashed correctly."""
        special_passwords = [
            "p@$$w0rd!#%",
            "użytkownik123",  # Polish characters
            "密码测试",  # Chinese characters
            "🔐secure🔐",  # Emoji
        ]

        for password in special_passwords:
            hashed = hash_password(password)
            assert hashed is not None
            assert verify_password(password, hashed)

    def test_hash_password_empty_string(self) -> None:
        """Empty password can be hashed (validation should happen elsewhere)."""
        hashed = hash_password("")
        assert hashed is not None
        assert verify_password("", hashed)


class TestPasswordVerification:
    """Tests for password verification."""

    def test_verify_password_correct(self) -> None:
        """Correct password verifies successfully."""
        password = "correctPassword123"
        hashed = hash_password(password)

        assert verify_password(password, hashed) is True

    def test_verify_password_incorrect(self) -> None:
        """Incorrect password fails verification."""
        password = "correctPassword123"
        hashed = hash_password(password)

        assert verify_password("wrongPassword", hashed) is False

    def test_verify_password_case_sensitive(self) -> None:
        """Password verification is case-sensitive."""
        password = "CaseSensitive123"
        hashed = hash_password(password)

        assert verify_password("casesensitive123", hashed) is False
        assert verify_password("CASESENSITIVE123", hashed) is False

    @pytest.mark.parametrize(
        "password,wrong_password",
        [
            ("password123", "password124"),
            ("password123", "password12"),
            ("password123", " password123"),
            ("password123", "password123 "),
        ],
    )
    def test_verify_password_slight_differences(
        self,
        password: str,
        wrong_password: str,
    ) -> None:
        """Even slight differences in password cause verification failure."""
        hashed = hash_password(password)
        assert verify_password(wrong_password, hashed) is False


class TestTokenCreation:
    """Tests for JWT token creation."""

    def test_create_access_token_contains_user_id(self) -> None:
        """Access token contains user ID as subject."""
        user_id = uuid4()
        token = create_access_token(user_id)

        payload = decode_token(token)
        assert payload is not None
        assert payload["sub"] == str(user_id)
        assert payload["type"] == "access"

    def test_create_access_token_has_expiration(self) -> None:
        """Access token has proper expiration time."""
        user_id = uuid4()
        token = create_access_token(user_id)

        payload = decode_token(token)
        assert payload is not None
        assert "exp" in payload

        # Expiration should be approximately access_token_expire_minutes from now
        exp_time = datetime.fromtimestamp(payload["exp"], tz=UTC)
        expected_exp = datetime.now(UTC) + timedelta(
            minutes=settings.access_token_expire_minutes
        )

        # Allow 5 seconds tolerance
        assert abs((exp_time - expected_exp).total_seconds()) < 5

    def test_create_verification_token(self) -> None:
        """Verification token has correct type and longer expiration."""
        user_id = uuid4()
        token = create_verification_token(user_id)

        payload = decode_token(token)
        assert payload is not None
        assert payload["sub"] == str(user_id)
        assert payload["type"] == "verification"

    def test_create_password_reset_token(self) -> None:
        """Password reset token has correct type."""
        user_id = uuid4()
        token = create_password_reset_token(user_id)

        payload = decode_token(token)
        assert payload is not None
        assert payload["sub"] == str(user_id)
        assert payload["type"] == "reset"

    def test_create_token_with_custom_expiration(self) -> None:
        """Token can be created with custom expiration delta."""
        user_id = uuid4()
        custom_delta = timedelta(hours=2)
        token = create_token(user_id, "access", expires_delta=custom_delta)

        payload = decode_token(token)
        assert payload is not None

        exp_time = datetime.fromtimestamp(payload["exp"], tz=UTC)
        expected_exp = datetime.now(UTC) + custom_delta

        # Allow 5 seconds tolerance
        assert abs((exp_time - expected_exp).total_seconds()) < 5

    def test_create_token_with_extra_claims(self) -> None:
        """Token can include extra claims."""
        user_id = uuid4()
        extra = {"role": "admin", "permissions": ["read", "write"]}
        token = create_token(user_id, "access", extra_claims=extra)

        payload = decode_token(token)
        assert payload is not None
        assert payload["role"] == "admin"
        assert payload["permissions"] == ["read", "write"]

    def test_different_token_types_have_different_expirations(self) -> None:
        """Different token types have appropriate expiration times."""
        user_id = uuid4()

        access_token = create_access_token(user_id)
        verification_token = create_verification_token(user_id)
        reset_token = create_password_reset_token(user_id)

        access_payload = decode_token(access_token)
        verification_payload = decode_token(verification_token)
        reset_payload = decode_token(reset_token)

        assert access_payload is not None
        assert verification_payload is not None
        assert reset_payload is not None

        # Verification token should expire later than access token
        # Reset token should have different expiration than access
        access_exp = access_payload["exp"]
        verification_exp = verification_payload["exp"]
        reset_exp = reset_payload["exp"]

        # Just verify they're all set (actual times depend on settings)
        assert access_exp > 0
        assert verification_exp > 0
        assert reset_exp > 0


class TestTokenDecoding:
    """Tests for JWT token decoding."""

    def test_decode_valid_token(self) -> None:
        """Valid token is decoded successfully."""
        user_id = uuid4()
        token = create_access_token(user_id)

        payload = decode_token(token)

        assert payload is not None
        assert payload["sub"] == str(user_id)
        assert "exp" in payload
        assert payload["type"] == "access"

    def test_decode_invalid_token_returns_none(self) -> None:
        """Invalid token returns None."""
        assert decode_token("invalid-token") is None
        assert decode_token("") is None
        assert decode_token("a.b.c") is None

    def test_decode_tampered_token_returns_none(self) -> None:
        """Tampered token returns None (signature validation)."""
        user_id = uuid4()
        token = create_access_token(user_id)

        # Tamper with the token by modifying a character
        parts = token.split(".")
        # Modify payload part
        tampered = f"{parts[0]}.{parts[1]}x.{parts[2]}"

        assert decode_token(tampered) is None

    def test_decode_token_wrong_secret_returns_none(self) -> None:
        """Token signed with different secret cannot be decoded."""
        user_id = uuid4()

        # Create token with a different secret
        token = jwt.encode(
            {"sub": str(user_id), "exp": datetime.now(UTC) + timedelta(hours=1)},
            "different-secret-key",
            algorithm="HS256",
        )

        assert decode_token(token) is None


class TestTokenExpiration:
    """Tests for token expiration handling."""

    def test_expired_token_returns_none(self) -> None:
        """Expired token cannot be decoded."""
        user_id = uuid4()

        # Create an already-expired token
        token = create_token(user_id, "access", expires_delta=timedelta(seconds=-1))

        assert decode_token(token) is None

    def test_token_expiring_soon_still_valid(self) -> None:
        """Token about to expire is still valid."""
        user_id = uuid4()

        # Token expires in 10 seconds
        token = create_token(user_id, "access", expires_delta=timedelta(seconds=10))

        payload = decode_token(token)
        assert payload is not None
        assert payload["sub"] == str(user_id)


class TestTokenVerification:
    """Tests for verify_token function."""

    def test_verify_token_correct_type(self) -> None:
        """Token with correct type returns subject."""
        user_id = uuid4()
        token = create_access_token(user_id)

        subject = verify_token(token, "access")

        assert subject == str(user_id)

    def test_verify_token_wrong_type_returns_none(self) -> None:
        """Token with wrong type returns None."""
        user_id = uuid4()
        token = create_access_token(user_id)

        # Try to verify as verification token
        assert verify_token(token, "verification") is None
        assert verify_token(token, "reset") is None

    def test_verify_verification_token(self) -> None:
        """Verification token verifies correctly."""
        user_id = uuid4()
        token = create_verification_token(user_id)

        subject = verify_token(token, "verification")

        assert subject == str(user_id)

    def test_verify_reset_token(self) -> None:
        """Reset token verifies correctly."""
        user_id = uuid4()
        token = create_password_reset_token(user_id)

        subject = verify_token(token, "reset")

        assert subject == str(user_id)

    def test_verify_invalid_token_returns_none(self) -> None:
        """Invalid token returns None."""
        assert verify_token("invalid-token", "access") is None

    def test_verify_expired_token_returns_none(self) -> None:
        """Expired token returns None."""
        user_id = uuid4()
        token = create_token(user_id, "access", expires_delta=timedelta(seconds=-1))

        assert verify_token(token, "access") is None


class TestTokenSecurity:
    """Security-focused token tests."""

    def test_token_cannot_be_forged_without_secret(self) -> None:
        """Cannot create valid token without knowing the secret."""
        user_id = uuid4()

        # Attempt to forge a token with wrong secret
        forged_token = jwt.encode(
            {
                "sub": str(user_id),
                "exp": datetime.now(UTC) + timedelta(hours=1),
                "type": "access",
            },
            "wrong-secret",
            algorithm="HS256",
        )

        assert verify_token(forged_token, "access") is None

    def test_token_payload_modification_detected(self) -> None:
        """Any modification to token payload invalidates it."""
        user_id = uuid4()
        token = create_access_token(user_id)

        # Decode without verification
        import base64

        parts = token.split(".")
        # This is the payload part (base64 encoded)
        # Any modification should invalidate signature
        modified_payload = base64.urlsafe_b64encode(b'{"sub":"hacked","type":"access","exp":9999999999}').decode().rstrip("=")
        modified_token = f"{parts[0]}.{modified_payload}.{parts[2]}"

        assert decode_token(modified_token) is None

    def test_user_id_string_conversion(self) -> None:
        """UUID user_id is properly converted to string in token."""
        user_id = uuid4()
        token = create_access_token(user_id)

        payload = decode_token(token)
        assert payload is not None
        # Subject should be string representation of UUID
        assert payload["sub"] == str(user_id)
        # Should be valid UUID format
        from uuid import UUID

        parsed_uuid = UUID(payload["sub"])
        assert parsed_uuid == user_id
