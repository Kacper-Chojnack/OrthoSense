"""Unit tests for User model.

Tests cover:
- User creation with required fields
- Email validation
- UUID auto-generation
- Timestamps (created_at, updated_at)
- Default values (is_active, is_verified)
- Schema validation (UserCreate, UserRead, etc.)
"""

from datetime import UTC, datetime
from uuid import UUID, uuid4

import pytest
from pydantic import ValidationError

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
    UserUpdate,
)


class TestUserModel:
    """Tests for User database model."""

    def test_user_creation_with_required_fields(self) -> None:
        """User can be created with required fields."""
        user = User(
            email="test@example.com",
            hashed_password="$2b$12$hashedpassword",
        )

        assert user.email == "test@example.com"
        assert user.hashed_password == "$2b$12$hashedpassword"

    def test_user_id_auto_generated(self) -> None:
        """User ID is auto-generated as UUID."""
        user = User(
            email="test@example.com",
            hashed_password="hashed",
        )

        assert user.id is not None
        assert isinstance(user.id, UUID)

    def test_user_id_can_be_provided(self) -> None:
        """User ID can be explicitly provided."""
        custom_id = uuid4()
        user = User(
            id=custom_id,
            email="test@example.com",
            hashed_password="hashed",
        )

        assert user.id == custom_id

    def test_user_default_is_active_true(self) -> None:
        """User is_active defaults to True."""
        user = User(
            email="test@example.com",
            hashed_password="hashed",
        )

        assert user.is_active is True

    def test_user_default_is_verified_false(self) -> None:
        """User is_verified defaults to False."""
        user = User(
            email="test@example.com",
            hashed_password="hashed",
        )

        assert user.is_verified is False

    def test_user_created_at_auto_set(self) -> None:
        """User created_at is automatically set to current time."""
        before = datetime.now(UTC)
        user = User(
            email="test@example.com",
            hashed_password="hashed",
        )
        after = datetime.now(UTC)

        assert user.created_at is not None
        # created_at should be between before and after
        assert before <= user.created_at <= after

    def test_user_updated_at_defaults_to_none(self) -> None:
        """User updated_at defaults to None."""
        user = User(
            email="test@example.com",
            hashed_password="hashed",
        )

        assert user.updated_at is None

    def test_user_with_all_fields(self) -> None:
        """User can be created with all fields explicitly set."""
        custom_id = uuid4()
        created = datetime.now(UTC)
        updated = datetime.now(UTC)

        user = User(
            id=custom_id,
            email="complete@example.com",
            hashed_password="hashed",
            is_active=False,
            is_verified=True,
            created_at=created,
            updated_at=updated,
        )

        assert user.id == custom_id
        assert user.email == "complete@example.com"
        assert user.is_active is False
        assert user.is_verified is True
        assert user.created_at == created
        assert user.updated_at == updated


class TestUserCreateSchema:
    """Tests for UserCreate validation schema."""

    def test_user_create_valid(self) -> None:
        """Valid user creation data passes validation."""
        user_create = UserCreate(
            email="valid@example.com",
            password="securepassword123",
        )

        assert user_create.email == "valid@example.com"
        assert user_create.password == "securepassword123"

    def test_user_create_invalid_email(self) -> None:
        """Invalid email format raises ValidationError."""
        with pytest.raises(ValidationError) as exc_info:
            UserCreate(
                email="not-an-email",
                password="securepassword123",
            )

        errors = exc_info.value.errors()
        assert len(errors) == 1
        assert "email" in str(errors[0]["loc"])

    @pytest.mark.parametrize(
        "invalid_email",
        [
            "",
            "missing-at-sign.com",
            "@missing-local.com",
            "missing-domain@",
            "spaces in@email.com",
            "double@@at.com",
        ],
    )
    def test_user_create_various_invalid_emails(self, invalid_email: str) -> None:
        """Various invalid email formats raise ValidationError."""
        with pytest.raises(ValidationError):
            UserCreate(
                email=invalid_email,
                password="securepassword123",
            )

    def test_user_create_password_too_short(self) -> None:
        """Password shorter than 8 characters raises ValidationError."""
        with pytest.raises(ValidationError) as exc_info:
            UserCreate(
                email="valid@example.com",
                password="short",
            )

        errors = exc_info.value.errors()
        assert any("password" in str(err["loc"]) for err in errors)

    def test_user_create_password_exactly_8_chars(self) -> None:
        """Password with exactly 8 characters is valid."""
        user_create = UserCreate(
            email="valid@example.com",
            password="12345678",
        )

        assert len(user_create.password) == 8

    def test_user_create_password_empty(self) -> None:
        """Empty password raises ValidationError."""
        with pytest.raises(ValidationError):
            UserCreate(
                email="valid@example.com",
                password="",
            )


class TestUserLoginSchema:
    """Tests for UserLogin schema."""

    def test_user_login_valid(self) -> None:
        """Valid login data passes validation."""
        login = UserLogin(
            email="user@example.com",
            password="anypassword",
        )

        assert login.email == "user@example.com"
        assert login.password == "anypassword"

    def test_user_login_invalid_email(self) -> None:
        """Invalid email raises ValidationError."""
        with pytest.raises(ValidationError):
            UserLogin(
                email="not-valid",
                password="password",
            )


class TestUserReadSchema:
    """Tests for UserRead response schema."""

    def test_user_read_from_user_model(self) -> None:
        """UserRead can be created from User model data."""
        user_id = uuid4()
        created = datetime.now(UTC)

        user_read = UserRead(
            id=user_id,
            email="read@example.com",
            is_active=True,
            is_verified=True,
            created_at=created,
        )

        assert user_read.id == user_id
        assert user_read.email == "read@example.com"
        assert user_read.is_active is True
        assert user_read.is_verified is True
        assert user_read.created_at == created

    def test_user_read_excludes_password(self) -> None:
        """UserRead schema does not include password field."""
        user_read = UserRead(
            id=uuid4(),
            email="test@example.com",
            is_active=True,
            is_verified=False,
            created_at=datetime.now(UTC),
        )

        # Check that hashed_password is not in the model fields
        assert "hashed_password" not in user_read.model_fields
        assert "password" not in user_read.model_fields


class TestUserUpdateSchema:
    """Tests for UserUpdate schema."""

    def test_user_update_email(self) -> None:
        """UserUpdate can specify new email."""
        update = UserUpdate(email="new@example.com")
        assert update.email == "new@example.com"

    def test_user_update_empty(self) -> None:
        """UserUpdate can be empty (no changes)."""
        update = UserUpdate()
        assert update.email is None

    def test_user_update_invalid_email(self) -> None:
        """Invalid email in update raises ValidationError."""
        with pytest.raises(ValidationError):
            UserUpdate(email="invalid-email")


class TestTokenSchemas:
    """Tests for Token-related schemas."""

    def test_token_schema(self) -> None:
        """Token schema holds access token."""
        token = Token(access_token="jwt.token.here")

        assert token.access_token == "jwt.token.here"
        assert token.token_type == "bearer"

    def test_token_payload_schema(self) -> None:
        """TokenPayload schema holds token data."""
        exp = datetime.now(UTC)
        payload = TokenPayload(
            sub="user-uuid",
            exp=exp,
            type="access",
        )

        assert payload.sub == "user-uuid"
        assert payload.exp == exp
        assert payload.type == "access"


class TestPasswordResetSchemas:
    """Tests for password reset schemas."""

    def test_password_reset_valid(self) -> None:
        """Valid password reset data passes validation."""
        reset = PasswordReset(
            token="reset-token",
            new_password="newpassword123",
        )

        assert reset.token == "reset-token"
        assert reset.new_password == "newpassword123"

    def test_password_reset_weak_password(self) -> None:
        """Short new password raises ValidationError."""
        with pytest.raises(ValidationError):
            PasswordReset(
                token="reset-token",
                new_password="short",
            )

    def test_forgot_password_valid(self) -> None:
        """Valid forgot password request passes validation."""
        forgot = ForgotPassword(email="user@example.com")
        assert forgot.email == "user@example.com"

    def test_forgot_password_invalid_email(self) -> None:
        """Invalid email raises ValidationError."""
        with pytest.raises(ValidationError):
            ForgotPassword(email="invalid")


class TestEmailVerificationSchema:
    """Tests for email verification schema."""

    def test_email_verification_valid(self) -> None:
        """Valid email verification data passes validation."""
        verification = EmailVerification(token="verification-token")
        assert verification.token == "verification-token"
