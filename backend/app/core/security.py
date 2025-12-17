"""Security utilities: password hashing and JWT management."""

from datetime import UTC, datetime, timedelta
from typing import Any
from uuid import UUID

import bcrypt
from jose import JWTError, jwt

from app.core.config import settings


def verify_password(plain_password: str, hashed_password: str) -> bool:
    """Verify a password against its hash."""
    return bcrypt.checkpw(
        plain_password.encode("utf-8"),
        hashed_password.encode("utf-8"),
    )


def hash_password(password: str) -> str:
    """Hash a password using bcrypt."""
    salt = bcrypt.gensalt()
    return bcrypt.hashpw(password.encode("utf-8"), salt).decode("utf-8")


def create_token(
    subject: str | UUID,
    token_type: str,
    expires_delta: timedelta | None = None,
    extra_claims: dict[str, Any] | None = None,
) -> str:
    """Create a JWT token with specified claims."""
    if expires_delta is None:
        if token_type == "access":
            expires_delta = timedelta(minutes=settings.access_token_expire_minutes)
        elif token_type == "refresh":
            expires_delta = timedelta(days=settings.refresh_token_expire_days)
        elif token_type == "verification":
            expires_delta = timedelta(hours=settings.verification_token_expire_hours)
        elif token_type == "reset":
            expires_delta = timedelta(hours=settings.password_reset_token_expire_hours)
        else:
            expires_delta = timedelta(minutes=15)

    expire = datetime.now(UTC) + expires_delta
    to_encode: dict[str, Any] = {
        "sub": str(subject),
        "exp": expire,
        "type": token_type,
    }

    if extra_claims:
        to_encode.update(extra_claims)

    return jwt.encode(to_encode, settings.secret_key, algorithm=settings.algorithm)


def create_access_token(user_id: str | UUID) -> str:
    """Create an access token for a user."""
    return create_token(user_id, "access")


def create_verification_token(user_id: str | UUID) -> str:
    """Create an email verification token."""
    return create_token(user_id, "verification")


def create_password_reset_token(user_id: str | UUID) -> str:
    """Create a password reset token."""
    return create_token(user_id, "reset")


def decode_token(token: str) -> dict[str, Any] | None:
    """Decode and validate a JWT token."""
    try:
        payload = jwt.decode(
            token,
            settings.secret_key,
            algorithms=[settings.algorithm],
        )
        return payload
    except JWTError:
        return None


def verify_token(token: str, expected_type: str) -> str | None:
    """Verify a token and return the subject if valid."""
    payload = decode_token(token)
    if payload is None:
        return None

    token_type = payload.get("type")
    if token_type != expected_type:
        return None

    subject = payload.get("sub")
    if subject is None:
        return None

    return subject
