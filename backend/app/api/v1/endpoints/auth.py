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


@router.put("/me", response_model=UserRead)
async def update_current_user_profile(
    data: UserUpdate,
    current_user: CurrentUser,
    session: AsyncSession = Depends(get_session),
) -> User:
    """Update current user's profile (name, email).

    GDPR: Users can update their personal data.
    """
    # Check if new email is already taken
    if data.email and data.email != current_user.email:
        stmt = select(User).where(User.email == data.email)
        result = await session.execute(stmt)
        if result.scalar_one_or_none():
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Email already in use",
            )
        current_user.email = data.email
        current_user.is_verified = False  # Re-verify after email change

    if data.full_name is not None:
        current_user.full_name = data.full_name

    current_user.updated_at = datetime.now(UTC)
    session.add(current_user)
    await session.commit()
    await session.refresh(current_user)

    logger.info(
        "user_profile_updated",
        user_id=str(current_user.id),
        email=str(current_user.email),
    )

    return current_user


@router.delete("/me", status_code=status.HTTP_204_NO_CONTENT)
async def delete_current_user_account(
    current_user: CurrentUser,
    session: AsyncSession = Depends(get_session),
) -> None:
    """Delete current user and all associated data (GDPR Right to be Forgotten).

    Cascades deletion to:
    - Treatment plans (as patient)
    - Sessions
    - Session exercise results
    - Protocols created by user
    """
    from app.models.protocol import Protocol
    from app.models.session import Session
    from app.models.treatment_plan import TreatmentPlan

    user_id = current_user.id

    # Delete sessions where user is patient
    sessions_stmt = select(Session).where(Session.patient_id == user_id)
    sessions_result = await session.execute(sessions_stmt)
    for sess in sessions_result.scalars().all():
        await session.delete(sess)

    # Delete treatment plans where user is patient
    plans_stmt = select(TreatmentPlan).where(TreatmentPlan.patient_id == user_id)
    plans_result = await session.execute(plans_stmt)
    for plan in plans_result.scalars().all():
        await session.delete(plan)

    # Nullify therapist_id in plans where user is therapist (preserve plan for patient)
    therapist_plans_stmt = select(TreatmentPlan).where(
        TreatmentPlan.therapist_id == user_id
    )
    therapist_plans_result = await session.execute(therapist_plans_stmt)
    for plan in therapist_plans_result.scalars().all():
        plan.therapist_id = None  # type: ignore[assignment]
        session.add(plan)

    # Delete protocols created by user
    protocols_stmt = select(Protocol).where(Protocol.created_by == user_id)
    protocols_result = await session.execute(protocols_stmt)
    for protocol in protocols_result.scalars().all():
        await session.delete(protocol)

    # Finally delete the user
    await session.delete(current_user)
    await session.commit()

    logger.info(
        "user_account_deleted_gdpr",
        user_id=str(user_id),
        email=str(current_user.email),
    )


@router.get("/me/export")
async def export_user_data(
    current_user: CurrentUser,
    session: AsyncSession = Depends(get_session),
) -> dict:
    """Export all user data (GDPR Right to Data Portability).

    Returns all user data in a structured JSON format.
    """
    from app.models.protocol import Protocol
    from app.models.session import Session, SessionExerciseResult
    from app.models.treatment_plan import TreatmentPlan

    user_id = current_user.id

    # Get treatment plans
    plans_stmt = select(TreatmentPlan).where(
        (TreatmentPlan.patient_id == user_id)
        | (TreatmentPlan.therapist_id == user_id)
    )
    plans_result = await session.execute(plans_stmt)
    plans_data = [
        {
            "id": str(p.id),
            "name": p.name,
            "role": "patient" if p.patient_id == user_id else "therapist",
            "status": p.status.value,
            "start_date": p.start_date.isoformat(),
            "end_date": p.end_date.isoformat() if p.end_date else None,
            "notes": p.notes,
            "frequency_per_week": p.frequency_per_week,
            "created_at": p.created_at.isoformat(),
        }
        for p in plans_result.scalars().all()
    ]

    # Get sessions
    sessions_stmt = select(Session).where(Session.patient_id == user_id)
    sessions_result = await session.execute(sessions_stmt)
    sessions_data = []
    for sess in sessions_result.scalars().all():
        # Get exercise results for each session
        results_stmt = select(SessionExerciseResult).where(
            SessionExerciseResult.session_id == sess.id
        )
        results_result = await session.execute(results_stmt)
        exercise_results = [
            {
                "exercise_id": str(r.exercise_id),
                "sets_completed": r.sets_completed,
                "reps_completed": r.reps_completed,
                "score": r.score,
                "feedback": r.feedback,
            }
            for r in results_result.scalars().all()
        ]

        sessions_data.append(
            {
                "id": str(sess.id),
                "status": sess.status.value,
                "scheduled_date": sess.scheduled_date.isoformat(),
                "started_at": sess.started_at.isoformat() if sess.started_at else None,
                "completed_at": (
                    sess.completed_at.isoformat() if sess.completed_at else None
                ),
                "duration_seconds": sess.duration_seconds,
                "pain_level_before": sess.pain_level_before,
                "pain_level_after": sess.pain_level_after,
                "overall_score": sess.overall_score,
                "notes": sess.notes,
                "exercise_results": exercise_results,
            }
        )

    # Get protocols created
    protocols_stmt = select(Protocol).where(Protocol.created_by == user_id)
    protocols_result = await session.execute(protocols_stmt)
    protocols_data = [
        {
            "id": str(p.id),
            "name": p.name,
            "description": p.description,
            "body_region": p.body_region.value if p.body_region else None,
            "difficulty": p.difficulty.value if p.difficulty else None,
            "created_at": p.created_at.isoformat(),
        }
        for p in protocols_result.scalars().all()
    ]

    export_data = {
        "export_date": datetime.now(UTC).isoformat(),
        "user": {
            "id": str(current_user.id),
            "email": str(current_user.email),
            "full_name": current_user.full_name,
            "role": current_user.role.value,
            "created_at": current_user.created_at.isoformat(),
            "is_verified": current_user.is_verified,
        },
        "treatment_plans": plans_data,
        "sessions": sessions_data,
        "protocols_created": protocols_data,
    }

    logger.info(
        "user_data_exported_gdpr",
        user_id=str(user_id),
        email=str(current_user.email),
    )

    return export_data
