"""User model for authentication and authorization."""

from datetime import UTC, datetime
from enum import Enum
from uuid import UUID, uuid4

from pydantic import EmailStr
from sqlmodel import Field, Relationship, SQLModel


def utc_now() -> datetime:
    """Get current UTC datetime."""
    return datetime.now(UTC)


class UserRole(str, Enum):
    """User roles for authorization."""

    PATIENT = "patient"
    ADMIN = "admin"


class UserBase(SQLModel):
    """Shared user fields."""

    email: EmailStr = Field(unique=True, index=True)
    full_name: str = Field(default="", max_length=255)
    role: UserRole = Field(default=UserRole.PATIENT)
    is_active: bool = Field(default=True)
    is_verified: bool = Field(default=False)


class User(UserBase, table=True):
    """Database table model for users."""

    __tablename__ = "users"

    id: UUID = Field(default_factory=uuid4, primary_key=True)
    hashed_password: str
    created_at: datetime = Field(default_factory=utc_now)
    updated_at: datetime | None = Field(default=None)

    # Relationships
    sessions: list["Session"] = Relationship(back_populates="patient")


# Forward references for relationships
from app.models.session import Session  # noqa: E402


class UserCreate(SQLModel):
    """Schema for user registration."""

    email: EmailStr
    password: str = Field(min_length=8)
    full_name: str = ""
    role: UserRole = UserRole.PATIENT


class UserLogin(SQLModel):
    """Schema for user login."""

    email: EmailStr
    password: str


class UserRead(SQLModel):
    """Schema for reading user data (public)."""

    id: UUID
    email: EmailStr
    full_name: str
    role: UserRole
    is_active: bool
    is_verified: bool
    created_at: datetime


class UserUpdate(SQLModel):
    """Schema for updating user profile."""

    email: EmailStr | None = None
    full_name: str | None = None


class Token(SQLModel):
    """JWT token response."""

    access_token: str
    token_type: str = "bearer"


class TokenPayload(SQLModel):
    """JWT token payload."""

    sub: str  # user_id
    exp: datetime
    type: str  # "access", "refresh", "verification", "reset"


class PasswordReset(SQLModel):
    """Password reset request."""

    token: str
    new_password: str = Field(min_length=8)


class EmailVerification(SQLModel):
    """Email verification request."""

    token: str


class ForgotPassword(SQLModel):
    """Forgot password request."""

    email: EmailStr
