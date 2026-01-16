"""Session management endpoints (for patients to record sessions)."""

from datetime import UTC, datetime
from typing import Annotated
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload
from sqlmodel import select

from app.core.database import get_session
from app.core.deps import ActiveUser
from app.core.logging import get_logger
from app.models.session import (
    Session,
    SessionComplete,
    SessionCreate,
    SessionExerciseResult,
    SessionExerciseResultCreate,
    SessionExerciseResultRead,
    SessionRead,
    SessionReadWithResults,
    SessionStart,
    SessionStatus,
)
from app.models.user import UserRole

router = APIRouter()
logger = get_logger(__name__)

SESSION_NOT_FOUND = "Session not found"
ACCESS_DENIED = "Access denied"


@router.get("", response_model=list[SessionRead])
async def list_sessions(
    session: Annotated[AsyncSession, Depends(get_session)],
    current_user: ActiveUser,
    status_filter: SessionStatus | None = None,
    skip: int = Query(0, ge=0),
    limit: int = Query(20, ge=1, le=100),
) -> list[Session]:
    """List sessions for the current user."""
    statement = select(Session).where(Session.patient_id == current_user.id)

    if status_filter:
        statement = statement.where(Session.status == status_filter)

    statement = (
        statement.order_by(Session.scheduled_date.desc()).offset(skip).limit(limit)
    )
    result = await session.execute(statement)
    return list(result.scalars().all())


@router.get("/{session_id}", response_model=SessionReadWithResults)
async def get_session_detail(
    session_id: UUID,
    session: Annotated[AsyncSession, Depends(get_session)],
    current_user: ActiveUser,
) -> Session:
    """Get session details with exercise results."""
    statement = (
        select(Session)
        .where(Session.id == session_id)
        .options(selectinload(Session.exercise_results))  # type: ignore[arg-type]
    )
    result = await session.execute(statement)
    exercise_session = result.scalar_one_or_none()

    if not exercise_session:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=SESSION_NOT_FOUND,
        )

    if (
        current_user.role == UserRole.PATIENT
        and exercise_session.patient_id != current_user.id
    ):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail=ACCESS_DENIED,
        )
    # TODO: Add TreatmentPlan check for therapists when model is implemented

    return exercise_session


@router.post("", response_model=SessionRead, status_code=status.HTTP_201_CREATED)
async def create_session(
    data: SessionCreate,
    session: Annotated[AsyncSession, Depends(get_session)],
    current_user: ActiveUser,
) -> Session:
    """Create a new session (scheduled or ad-hoc)."""
    exercise_session = Session(
        patient_id=current_user.id,
        **data.model_dump(),
    )
    session.add(exercise_session)
    await session.commit()
    await session.refresh(exercise_session)

    logger.info(
        "session_created",
        session_id=str(exercise_session.id),
        patient_id=str(exercise_session.patient_id),
    )
    return exercise_session


@router.post("/{session_id}/start", response_model=SessionRead)
async def start_session(
    session_id: UUID,
    data: SessionStart,
    session: Annotated[AsyncSession, Depends(get_session)],
    current_user: ActiveUser,
) -> Session:
    """Start an exercise session."""
    exercise_session = await session.get(Session, session_id)
    if not exercise_session:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=SESSION_NOT_FOUND,
        )

    if exercise_session.patient_id != current_user.id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail=ACCESS_DENIED,
        )

    if exercise_session.status != SessionStatus.IN_PROGRESS:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Cannot start session with status: {exercise_session.status}",
        )

    exercise_session.started_at = datetime.now(UTC)
    exercise_session.pain_level_before = data.pain_level_before
    exercise_session.device_info = data.device_info
    session.add(exercise_session)
    await session.commit()
    await session.refresh(exercise_session)

    logger.info("session_started", session_id=str(session_id))
    return exercise_session


@router.post("/{session_id}/complete", response_model=SessionRead)
async def complete_session(
    session_id: UUID,
    data: SessionComplete,
    session: Annotated[AsyncSession, Depends(get_session)],
    current_user: ActiveUser,
) -> Session:
    """Complete an exercise session."""
    exercise_session = await session.get(Session, session_id)
    if not exercise_session:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=SESSION_NOT_FOUND,
        )

    if exercise_session.patient_id != current_user.id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail=ACCESS_DENIED,
        )

    exercise_session.status = SessionStatus.COMPLETED
    exercise_session.completed_at = datetime.now(UTC)
    exercise_session.pain_level_after = data.pain_level_after
    exercise_session.notes = data.notes

    if exercise_session.started_at:
        # Handle both offset-naive (from SQLite) and offset-aware datetimes
        started = exercise_session.started_at
        completed = exercise_session.completed_at
        if started.tzinfo is None:
            started = started.replace(tzinfo=UTC)
        if completed.tzinfo is None:
            completed = completed.replace(tzinfo=UTC)
        duration = completed - started
        exercise_session.duration_seconds = int(duration.total_seconds())

    statement = select(SessionExerciseResult).where(
        SessionExerciseResult.session_id == session_id
    )
    result = await session.execute(statement)
    results = result.scalars().all()

    if results:
        scores = [r.score for r in results if r.score is not None]
        if scores:
            exercise_session.overall_score = sum(scores) / len(scores)

    session.add(exercise_session)
    await session.commit()
    await session.refresh(exercise_session)

    logger.info(
        "session_completed",
        session_id=str(session_id),
        duration=exercise_session.duration_seconds,
        score=exercise_session.overall_score,
    )
    return exercise_session


@router.post("/{session_id}/skip", response_model=SessionRead)
async def skip_session(
    session_id: UUID,
    session: Annotated[AsyncSession, Depends(get_session)],
    current_user: ActiveUser,
    reason: str = "",
) -> Session:
    """Mark a session as skipped."""
    exercise_session = await session.get(Session, session_id)
    if not exercise_session:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=SESSION_NOT_FOUND,
        )

    if exercise_session.patient_id != current_user.id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail=ACCESS_DENIED,
        )

    exercise_session.status = SessionStatus.SKIPPED
    exercise_session.notes = reason
    session.add(exercise_session)
    await session.commit()
    await session.refresh(exercise_session)

    logger.info("session_skipped", session_id=str(session_id), reason=reason)
    return exercise_session


@router.post(
    "/{session_id}/results",
    response_model=SessionExerciseResultRead,
    status_code=status.HTTP_201_CREATED,
)
async def submit_exercise_result(
    session_id: UUID,
    data: SessionExerciseResultCreate,
    session: Annotated[AsyncSession, Depends(get_session)],
    current_user: ActiveUser,
) -> SessionExerciseResult:
    """Submit results for an exercise within a session."""
    exercise_session = await session.get(Session, session_id)
    if not exercise_session:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=SESSION_NOT_FOUND,
        )

    if exercise_session.patient_id != current_user.id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail=ACCESS_DENIED,
        )

    if exercise_session.status == SessionStatus.COMPLETED:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Cannot submit results to a completed session",
        )

    from app.models.exercise import Exercise

    exercise = await session.get(Exercise, data.exercise_id)
    if not exercise:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Exercise not found",
        )

    result = SessionExerciseResult(
        session_id=session_id,
        **data.model_dump(),
        completed_at=datetime.now(UTC),
    )
    session.add(result)
    await session.commit()
    await session.refresh(result)

    logger.info(
        "exercise_result_submitted",
        session_id=str(session_id),
        exercise_id=str(data.exercise_id),
        score=data.score,
    )
    return result
