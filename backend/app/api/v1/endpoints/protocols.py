"""Protocol management endpoints (Therapist only)."""

from datetime import UTC, datetime
from typing import Annotated
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload
from sqlmodel import select

from app.core.database import get_session
from app.core.deps import ActiveUser, TherapistUser
from app.core.logging import get_logger
from app.models.protocol import (
    Protocol,
    ProtocolCreate,
    ProtocolExercise,
    ProtocolExerciseCreate,
    ProtocolExerciseRead,
    ProtocolExerciseUpdate,
    ProtocolRead,
    ProtocolReadWithExercises,
    ProtocolStatus,
    ProtocolUpdate,
)
from app.models.user import UserRole

router = APIRouter()
logger = get_logger(__name__)


# --- Helper Functions (Reduce Cognitive Complexity) ---


async def _get_protocol_or_404(
    session: AsyncSession,
    protocol_id: UUID,
) -> Protocol:
    """Fetch protocol or raise 404."""
    protocol = await session.get(Protocol, protocol_id)
    if not protocol:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Protocol not found",
        )
    return protocol


def _check_protocol_ownership(protocol: Protocol, user: TherapistUser) -> None:
    """Verify user can modify protocol (owner or admin)."""
    if protocol.created_by != user.id and user.role != UserRole.ADMIN:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Not authorized to modify this protocol",
        )


async def _get_protocol_exercise_or_404(
    session: AsyncSession,
    protocol_exercise_id: UUID,
    protocol_id: UUID,
) -> ProtocolExercise:
    """Fetch protocol exercise or raise 404."""
    protocol_exercise = await session.get(ProtocolExercise, protocol_exercise_id)
    if not protocol_exercise or protocol_exercise.protocol_id != protocol_id:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Protocol exercise not found",
        )
    return protocol_exercise


def _check_patient_access(protocol: Protocol, user: ActiveUser) -> None:
    """Verify patient can access protocol (published templates only)."""
    if user.role != UserRole.PATIENT:
        return
    if protocol.status != ProtocolStatus.PUBLISHED or not protocol.is_template:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Access denied",
        )


@router.get("", response_model=list[ProtocolRead])
async def list_protocols(
    session: Annotated[AsyncSession, Depends(get_session)],
    current_user: ActiveUser,
    status_filter: ProtocolStatus | None = None,
    condition: str | None = None,
    only_mine: bool = False,
    skip: int = Query(0, ge=0),
    limit: int = Query(50, ge=1, le=100),
) -> list[Protocol]:
    """List protocols. Patients see only published templates."""
    statement = select(Protocol)

    # Patients can only see published templates
    if current_user.role == UserRole.PATIENT:
        statement = statement.where(
            Protocol.status == ProtocolStatus.PUBLISHED,
            Protocol.is_template == True,  # noqa: E712
        )
    else:
        if status_filter:
            statement = statement.where(Protocol.status == status_filter)
        if only_mine:
            statement = statement.where(Protocol.created_by == current_user.id)

    if condition:
        statement = statement.where(Protocol.condition.ilike(f"%{condition}%"))

    statement = statement.offset(skip).limit(limit).order_by(Protocol.name)
    result = await session.execute(statement)
    return list(result.scalars().all())


@router.get("/{protocol_id}", response_model=ProtocolReadWithExercises)
async def get_protocol(
    protocol_id: UUID,
    session: Annotated[AsyncSession, Depends(get_session)],
    current_user: ActiveUser,
) -> Protocol:
    """Get a single protocol with its exercises."""
    statement = (
        select(Protocol)
        .where(Protocol.id == protocol_id)
        .options(selectinload(Protocol.exercises))
    )
    result = await session.execute(statement)
    protocol = result.scalar_one_or_none()

    if not protocol:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Protocol not found",
        )

    _check_patient_access(protocol, current_user)
    return protocol


@router.post("", response_model=ProtocolRead, status_code=status.HTTP_201_CREATED)
async def create_protocol(
    data: ProtocolCreate,
    session: Annotated[AsyncSession, Depends(get_session)],
    current_user: TherapistUser,
) -> Protocol:
    """Create a new rehabilitation protocol (Therapist only)."""
    protocol = Protocol(
        **data.model_dump(),
        created_by=current_user.id,
    )
    session.add(protocol)
    await session.commit()
    await session.refresh(protocol)

    logger.info(
        "protocol_created",
        protocol_id=str(protocol.id),
        name=protocol.name,
        created_by=str(current_user.id),
    )
    return protocol


@router.patch("/{protocol_id}", response_model=ProtocolRead)
async def update_protocol(
    protocol_id: UUID,
    data: ProtocolUpdate,
    session: Annotated[AsyncSession, Depends(get_session)],
    current_user: TherapistUser,
) -> Protocol:
    """Update a protocol (owner or admin only)."""
    protocol = await _get_protocol_or_404(session, protocol_id)
    _check_protocol_ownership(protocol, current_user)

    update_data = data.model_dump(exclude_unset=True)
    for key, value in update_data.items():
        setattr(protocol, key, value)

    protocol.updated_at = datetime.now(UTC)
    session.add(protocol)
    await session.commit()
    await session.refresh(protocol)

    logger.info(
        "protocol_updated",
        protocol_id=str(protocol.id),
        updated_by=str(current_user.id),
    )
    return protocol


@router.delete("/{protocol_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_protocol(
    protocol_id: UUID,
    session: Annotated[AsyncSession, Depends(get_session)],
    current_user: TherapistUser,
) -> None:
    """Archive a protocol (soft delete)."""
    protocol = await _get_protocol_or_404(session, protocol_id)
    _check_protocol_ownership(protocol, current_user)

    protocol.status = ProtocolStatus.ARCHIVED
    protocol.updated_at = datetime.now(UTC)
    session.add(protocol)
    await session.commit()

    logger.info(
        "protocol_archived",
        protocol_id=str(protocol.id),
        archived_by=str(current_user.id),
    )


# --- Protocol Exercise Management ---


@router.post(
    "/{protocol_id}/exercises",
    response_model=ProtocolExerciseRead,
    status_code=status.HTTP_201_CREATED,
)
async def add_exercise_to_protocol(
    protocol_id: UUID,
    data: ProtocolExerciseCreate,
    session: Annotated[AsyncSession, Depends(get_session)],
    current_user: TherapistUser,
) -> ProtocolExercise:
    """Add an exercise to a protocol."""
    protocol = await _get_protocol_or_404(session, protocol_id)
    _check_protocol_ownership(protocol, current_user)

    from app.models.exercise import Exercise

    exercise = await session.get(Exercise, data.exercise_id)
    if not exercise:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Exercise not found",
        )

    protocol_exercise = ProtocolExercise(
        protocol_id=protocol_id,
        **data.model_dump(),
    )
    session.add(protocol_exercise)
    await session.commit()
    await session.refresh(protocol_exercise)

    return protocol_exercise


@router.patch(
    "/{protocol_id}/exercises/{protocol_exercise_id}",
    response_model=ProtocolExerciseRead,
)
async def update_protocol_exercise(
    protocol_id: UUID,
    protocol_exercise_id: UUID,
    data: ProtocolExerciseUpdate,
    session: Annotated[AsyncSession, Depends(get_session)],
    current_user: TherapistUser,
) -> ProtocolExercise:
    """Update exercise parameters within a protocol."""
    protocol = await _get_protocol_or_404(session, protocol_id)
    _check_protocol_ownership(protocol, current_user)
    protocol_exercise = await _get_protocol_exercise_or_404(
        session, protocol_exercise_id, protocol_id
    )

    update_data = data.model_dump(exclude_unset=True)
    for key, value in update_data.items():
        setattr(protocol_exercise, key, value)

    session.add(protocol_exercise)
    await session.commit()
    await session.refresh(protocol_exercise)

    return protocol_exercise


@router.delete(
    "/{protocol_id}/exercises/{protocol_exercise_id}",
    status_code=status.HTTP_204_NO_CONTENT,
)
async def remove_exercise_from_protocol(
    protocol_id: UUID,
    protocol_exercise_id: UUID,
    session: Annotated[AsyncSession, Depends(get_session)],
    current_user: TherapistUser,
) -> None:
    """Remove an exercise from a protocol."""
    protocol = await _get_protocol_or_404(session, protocol_id)
    _check_protocol_ownership(protocol, current_user)
    protocol_exercise = await _get_protocol_exercise_or_404(
        session, protocol_exercise_id, protocol_id
    )

    await session.delete(protocol_exercise)
    await session.commit()
