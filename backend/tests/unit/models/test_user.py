"""
Unit tests for User model.

Test coverage:
1. User model creation
2. UserCreate schema validation
3. UserRead schema serialization
4. UserUpdate schema
5. Token models
6. Password/Email validation schemas
7. XSS prevention in name fields
"""

from datetime import UTC, datetime
from uuid import uuid4

import pytest
from pydantic import ValidationError

from app.core.security import hash_password
from app.models.user import (
    EmailVerification,
    ForgotPassword,
    PasswordReset,
    Token,
    TokenPayload,
    User,
    UserCreate,
    UserLogin,
    UserRead,
    UserRole,
    UserUpdate,
)


class TestUserModel:
    """Tests for User SQLModel."""

    def test_user_creation_with_defaults(self) -> None:
        """User can be created with minimal fields."""
        user = User(
            email="test@example.com",
            hashed_password=hash_password("password123"),
        )

        assert user.email == "test@example.com"
        assert user.role == UserRole.PATIENT
        assert user.is_active is True
        assert user.is_verified is False
        assert user.full_name == ""

    def test_user_creation_with_all_fields(self) -> None:
        """User can be created with all fields."""
        user_id = uuid4()
        now = datetime.now(UTC)

        user = User(
            id=user_id,
            email="admin@example.com",
            hashed_password="hashed",
            full_name="Admin User",
            role=UserRole.ADMIN,
            is_active=True,
            is_verified=True,
            created_at=now,
        )

        assert user.id == user_id
        assert user.email == "admin@example.com"
        assert user.full_name == "Admin User"
        assert user.role == UserRole.ADMIN
        assert user.is_verified is True

    def test_user_id_auto_generated(self) -> None:
        """User ID is auto-generated if not provided."""
        user = User(
            email="test@example.com",
            hashed_password="hashed",
        )

        assert user.id is not None

    def test_user_created_at_auto_generated(self) -> None:
        """created_at is auto-generated."""
        user = User(
            email="test@example.com",
            hashed_password="hashed",
        )

        assert user.created_at is not None


class TestUserCreateSchema:
    """Tests for UserCreate schema."""

    def test_user_create_valid(self) -> None:
        """Valid UserCreate schema."""
        data = UserCreate(
            email="test@example.com",
            password="SecurePass123!",
            full_name="Test User",
        )

        assert data.email == "test@example.com"
        assert data.password == "SecurePass123!"
        assert data.full_name == "Test User"
        assert data.role == UserRole.PATIENT

    def test_user_create_minimal(self) -> None:
        """UserCreate with minimal fields."""
        data = UserCreate(
            email="test@example.com",
            password="password123",
        )

        assert data.email == "test@example.com"
        assert data.full_name == ""

    def test_user_create_invalid_email(self) -> None:
        """Invalid email raises ValidationError."""
        with pytest.raises(ValidationError):
            UserCreate(
                email="invalid-email",
                password="password123",
            )

    def test_user_create_short_password(self) -> None:
        """Password shorter than 8 characters raises ValidationError."""
        with pytest.raises(ValidationError):
            UserCreate(
                email="test@example.com",
                password="short",
            )

    def test_user_create_name_alias(self) -> None:
        """name field maps to full_name."""
        data = UserCreate(
            email="test@example.com",
            password="password123",
            name="Test User",
        )

        assert data.full_name == "Test User"

    def test_user_create_xss_in_name_rejected(self) -> None:
        """XSS payload in name field is rejected."""
        with pytest.raises(ValidationError) as exc_info:
            UserCreate(
                email="test@example.com",
                password="password123",
                full_name="<script>alert('xss')</script>",
            )

        assert "dangerous content" in str(exc_info.value).lower()

    def test_user_create_xss_in_name_alias_rejected(self) -> None:
        """XSS payload in name alias field is rejected."""
        with pytest.raises(ValidationError) as exc_info:
            UserCreate(
                email="test@example.com",
                password="password123",
                name="<img src=x onerror=alert(1)>",
            )

        assert "dangerous content" in str(exc_info.value).lower()


class TestUserReadSchema:
    """Tests for UserRead schema."""

    def test_user_read_from_model(self) -> None:
        """UserRead can be created from User model."""
        user = User(
            id=uuid4(),
            email="test@example.com",
            hashed_password="hashed",
            full_name="Test User",
            role=UserRole.PATIENT,
            is_active=True,
            is_verified=True,
            created_at=datetime.now(UTC),
        )

        # Manually create UserRead from user data
        user_read = UserRead(
            id=user.id,
            email=user.email,
            full_name=user.full_name,
            role=user.role,
            is_active=user.is_active,
            is_verified=user.is_verified,
            created_at=user.created_at,
        )

        assert user_read.id == user.id
        assert user_read.email == user.email
        assert not hasattr(user_read, "hashed_password")


class TestUserUpdateSchema:
    """Tests for UserUpdate schema."""

    def test_user_update_email(self) -> None:
        """UserUpdate with email."""
        data = UserUpdate(email="new@example.com")

        assert data.email == "new@example.com"
        assert data.full_name is None

    def test_user_update_full_name(self) -> None:
        """UserUpdate with full_name."""
        data = UserUpdate(full_name="New Name")

        assert data.full_name == "New Name"
        assert data.email is None

    def test_user_update_both_fields(self) -> None:
        """UserUpdate with both fields."""
        data = UserUpdate(
            email="new@example.com",
            full_name="New Name",
        )

        assert data.email == "new@example.com"
        assert data.full_name == "New Name"

    def test_user_update_empty(self) -> None:
        """UserUpdate with no fields is valid."""
        data = UserUpdate()

        assert data.email is None
        assert data.full_name is None


class TestUserLoginSchema:
    """Tests for UserLogin schema."""

    def test_user_login_valid(self) -> None:
        """Valid UserLogin schema."""
        data = UserLogin(
            email="test@example.com",
            password="password123",
        )

        assert data.email == "test@example.com"
        assert data.password == "password123"

    def test_user_login_invalid_email(self) -> None:
        """Invalid email raises ValidationError."""
        with pytest.raises(ValidationError):
            UserLogin(
                email="invalid",
                password="password123",
            )


class TestTokenSchema:
    """Tests for Token schema."""

    def test_token_defaults(self) -> None:
        """Token has correct defaults."""
        token = Token(access_token="jwt.token.here")

        assert token.access_token == "jwt.token.here"
        assert token.token_type == "bearer"

    def test_token_custom_type(self) -> None:
        """Token type can be customized."""
        token = Token(
            access_token="jwt.token.here",
            token_type="custom",
        )

        assert token.token_type == "custom"


class TestTokenPayloadSchema:
    """Tests for TokenPayload schema."""

    def test_token_payload_valid(self) -> None:
        """Valid TokenPayload schema."""
        now = datetime.now(UTC)
        payload = TokenPayload(
            sub="user-id-123",
            exp=now,
            type="access",
        )

        assert payload.sub == "user-id-123"
        assert payload.exp == now
        assert payload.type == "access"


class TestPasswordResetSchema:
    """Tests for PasswordReset schema."""

    def test_password_reset_valid(self) -> None:
        """Valid PasswordReset schema."""
        data = PasswordReset(
            token="reset-token",
            new_password="NewPassword123!",
        )

        assert data.token == "reset-token"
        assert data.new_password == "NewPassword123!"

    def test_password_reset_short_password(self) -> None:
        """Short password raises ValidationError."""
        with pytest.raises(ValidationError):
            PasswordReset(
                token="reset-token",
                new_password="short",
            )


class TestEmailVerificationSchema:
    """Tests for EmailVerification schema."""

    def test_email_verification_valid(self) -> None:
        """Valid EmailVerification schema."""
        data = EmailVerification(token="verification-token")

        assert data.token == "verification-token"


class TestForgotPasswordSchema:
    """Tests for ForgotPassword schema."""

    def test_forgot_password_valid(self) -> None:
        """Valid ForgotPassword schema."""
        data = ForgotPassword(email="test@example.com")

        assert data.email == "test@example.com"

    def test_forgot_password_invalid_email(self) -> None:
        """Invalid email raises ValidationError."""
        with pytest.raises(ValidationError):
            ForgotPassword(email="invalid")


class TestUserRoleEnum:
    """Tests for UserRole enum."""

    def test_user_role_values(self) -> None:
        """UserRole has expected values."""
        assert UserRole.PATIENT == "patient"
        assert UserRole.ADMIN == "admin"

    def test_user_role_list(self) -> None:
        """All user roles are defined."""
        roles = list(UserRole)
        assert len(roles) == 2
        assert UserRole.PATIENT in roles
        assert UserRole.ADMIN in roles
