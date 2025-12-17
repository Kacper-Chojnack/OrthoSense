"""Authentication endpoints: register, login, verify, reset password."""

from datetime import UTC, datetime
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import OAuth2PasswordRequestForm
from pydantic import EmailStr
from sqlalchemy.ext.asyncio import AsyncSession
from sqlmodel import select

from app.core.database import get_session
from app.core.deps import CurrentUser
from app.core.logging import get_logger
from app.core.security import (
    create_access_token,
    create_password_reset_token,
    create_verification_token,
    hash_password,
    verify_password,
    verify_token,
)
from app.models.user import (
    EmailVerification,
    ForgotPassword,
    PasswordReset,
    Token,
    User,
    UserCreate,
    UserRead,
)
from app.services.email import (
    send_password_reset_email,
    send_verification_email,
    send_welcome_email,
)

router = APIRouter()
logger = get_logger(__name__)


@router.post(
    "/register",
    response_model=UserRead,
    status_code=status.HTTP_201_CREATED,
)
async def register(
    data: UserCreate,
    session: AsyncSession = Depends(get_session),
) -> User:
    """Register a new user account.

    Sends verification email (logged to console in dev mode).
    """
    # Check if email already exists
    statement = select(User).where(User.email == data.email)
    result = await session.execute(statement)
    existing_user = result.scalar_one_or_none()

    if existing_user:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Email already registered",
        )

    # Create user with hashed password
    user = User(
        email=data.email,
        hashed_password=hash_password(data.password),
    )
    session.add(user)
    await session.commit()
    await session.refresh(user)

    # Send verification email
    verification_token = create_verification_token(user.id)
    await send_verification_email(str(user.email), verification_token)

    logger.info(
        "user_registered",
        user_id=str(user.id),
        email=str(user.email),
    )

    return user


@router.post("/login", response_model=Token)
async def login(
    form_data: OAuth2PasswordRequestForm = Depends(),
    session: AsyncSession = Depends(get_session),
) -> Token:
    """Authenticate user and return access token.

    Uses OAuth2 password flow for compatibility with OpenAPI.
    """
    # Find user by email
    statement = select(User).where(User.email == form_data.username)
    result = await session.execute(statement)
    user = result.scalar_one_or_none()

    if not user or not verify_password(form_data.password, user.hashed_password):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect email or password",
            headers={"WWW-Authenticate": "Bearer"},
        )

    if not user.is_active:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="User account is disabled",
        )

    access_token = create_access_token(user.id)

    logger.info(
        "user_login",
        user_id=str(user.id),
        email=str(user.email),
    )

    return Token(access_token=access_token)


@router.post("/verify-email", response_model=UserRead)
async def verify_email(
    data: EmailVerification,
    session: AsyncSession = Depends(get_session),
) -> User:
    """Verify user's email address using token from email link."""
    user_id = verify_token(data.token, "verification")
    if user_id is None:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid or expired verification token",
        )

    user = await session.get(User, UUID(user_id))
    if user is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found",
        )

    if user.is_verified:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Email already verified",
        )

    user.is_verified = True
    user.updated_at = datetime.now(UTC)
    session.add(user)
    await session.commit()
    await session.refresh(user)

    await send_welcome_email(str(user.email))

    logger.info(
        "email_verified",
        user_id=str(user.id),
        email=str(user.email),
    )

    return user


@router.post("/forgot-password", status_code=status.HTTP_202_ACCEPTED)
async def forgot_password(
    data: ForgotPassword,
    session: AsyncSession = Depends(get_session),
) -> dict[str, str]:
    """Request password reset email.

    Always returns success to prevent email enumeration attacks.
    """
    statement = select(User).where(User.email == data.email)
    result = await session.execute(statement)
    user = result.scalar_one_or_none()

    if user and user.is_active:
        reset_token = create_password_reset_token(user.id)
        await send_password_reset_email(str(user.email), reset_token)

        logger.info(
            "password_reset_requested",
            user_id=str(user.id),
            email=str(user.email),
        )

    # Always return success to prevent email enumeration
    return {"message": "If the email exists, a reset link has been sent"}


@router.post("/reset-password", response_model=UserRead)
async def reset_password(
    data: PasswordReset,
    session: AsyncSession = Depends(get_session),
) -> User:
    """Reset password using token from email link."""
    user_id = verify_token(data.token, "reset")
    if user_id is None:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid or expired reset token",
        )

    user = await session.get(User, UUID(user_id))
    if user is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found",
        )

    if not user.is_active:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="User account is disabled",
        )

    user.hashed_password = hash_password(data.new_password)
    user.updated_at = datetime.now(UTC)
    session.add(user)
    await session.commit()
    await session.refresh(user)

    logger.info(
        "password_reset_completed",
        user_id=str(user.id),
        email=str(user.email),
    )

    return user


@router.get("/me", response_model=UserRead)
async def get_current_user_profile(
    current_user: CurrentUser,
) -> User:
    """Get current authenticated user's profile."""
    return current_user


@router.post("/resend-verification", status_code=status.HTTP_202_ACCEPTED)
async def resend_verification(
    email: EmailStr,
    session: AsyncSession = Depends(get_session),
) -> dict[str, str]:
    """Resend verification email.

    Always returns success to prevent email enumeration.
    """
    statement = select(User).where(User.email == email)
    result = await session.execute(statement)
    user = result.scalar_one_or_none()

    if user and not user.is_verified and user.is_active:
        verification_token = create_verification_token(user.id)
        await send_verification_email(str(user.email), verification_token)

        logger.info(
            "verification_resent",
            user_id=str(user.id),
            email=str(user.email),
        )

    return {"message": "If the email exists and is unverified, a link has been sent"}
