"""Measurement sync endpoints for Flutter offline-first pattern.

Accepts client-generated UUIDs to support idempotent sync operations.
Protected by JWT authentication.
"""

from collections.abc import Sequence
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlmodel import select

from app.core.database import get_session
from app.core.deps import ActiveUser
from app.core.logging import get_logger
from app.models.measurement import (
    Measurement,
    MeasurementCreate,
    MeasurementRead,
    SyncResponse,
)

router = APIRouter()
logger = get_logger(__name__)


@router.post(
    "",
    response_model=SyncResponse,
    status_code=status.HTTP_201_CREATED,
)
async def create_measurement(
    data: MeasurementCreate,
    current_user: ActiveUser,
    session: AsyncSession = Depends(get_session),
) -> SyncResponse:
    """Sync a single measurement from Flutter client.

    Client sends pre-generated UUID - enables idempotent retries.
    If ID exists, returns success without duplicate insertion.
    Requires authentication.
    """
    # Check for existing measurement (idempotent sync)
    existing = await session.get(Measurement, data.id)
    if existing:
        # Verify ownership
        if existing.owner_id and existing.owner_id != current_user.id:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Not authorized to access this measurement",
            )
        logger.info(
            "measurement_already_synced",
            measurement_id=str(data.id),
            user_id=data.user_id,
        )
        return SyncResponse(success=True, backend_id=str(data.id))

    measurement = Measurement.model_validate(data)
    measurement.owner_id = current_user.id
    session.add(measurement)
    await session.commit()
    await session.refresh(measurement)

    logger.info(
        "measurement_synced",
        measurement_id=str(measurement.id),
        user_id=measurement.user_id,
        owner_id=str(current_user.id),
        type=measurement.type,
    )

    return SyncResponse(success=True, backend_id=str(measurement.id))


@router.post(
    "/batch",
    response_model=list[SyncResponse],
    status_code=status.HTTP_201_CREATED,
)
async def create_measurements_batch(
    data: list[MeasurementCreate],
    current_user: ActiveUser,
    session: AsyncSession = Depends(get_session),
) -> list[SyncResponse]:
    """Batch sync measurements for efficient network usage.

    Processes each measurement individually to provide per-item status.
    Requires authentication.
    """
    responses: list[SyncResponse] = []

    for item in data:
        try:
            existing = await session.get(Measurement, item.id)
            if existing:
                if existing.owner_id and existing.owner_id != current_user.id:
                    responses.append(
                        SyncResponse(
                            success=False,
                            backend_id=str(item.id),
                            error_message="Not authorized",
                        )
                    )
                    continue
                responses.append(SyncResponse(success=True, backend_id=str(item.id)))
                continue

            measurement = Measurement.model_validate(item)
            measurement.owner_id = current_user.id
            session.add(measurement)
            await session.flush()

            responses.append(SyncResponse(success=True, backend_id=str(measurement.id)))

        except Exception as e:
            logger.error(
                "batch_sync_item_failed",
                measurement_id=str(item.id),
                error=str(e),
            )
            responses.append(
                SyncResponse(
                    success=False,
                    backend_id=str(item.id),
                    error_message=str(e),
                )
            )

    await session.commit()

    logger.info(
        "batch_sync_completed",
        owner_id=str(current_user.id),
        total=len(data),
        succeeded=sum(1 for r in responses if r.success),
        failed=sum(1 for r in responses if not r.success),
    )

    return responses


@router.get(
    "/my",
    response_model=list[MeasurementRead],
)
async def get_my_measurements(
    current_user: ActiveUser,
    limit: int = 100,
    offset: int = 0,
    session: AsyncSession = Depends(get_session),
) -> Sequence[Measurement]:
    """Retrieve all measurements owned by the current user."""
    statement = (
        select(Measurement)
        .where(Measurement.owner_id == current_user.id)
        .order_by(Measurement.created_at.desc())
        .offset(offset)
        .limit(limit)
    )
    result = await session.execute(statement)
    return result.scalars().all()


@router.get(
    "/user/{user_id}",
    response_model=list[MeasurementRead],
)
async def get_user_measurements(
    user_id: str,
    current_user: ActiveUser,
    limit: int = 100,
    offset: int = 0,
    session: AsyncSession = Depends(get_session),
) -> Sequence[Measurement]:
    """Retrieve measurements for a user (for data verification/admin).

    Users can only access their own measurements.
    """
    statement = (
        select(Measurement)
        .where(Measurement.user_id == user_id)
        .where(Measurement.owner_id == current_user.id)
        .order_by(Measurement.created_at.desc())
        .offset(offset)
        .limit(limit)
    )
    result = await session.execute(statement)
    return result.scalars().all()


@router.get(
    "/{measurement_id}",
    response_model=MeasurementRead,
)
async def get_measurement(
    measurement_id: UUID,
    current_user: ActiveUser,
    session: AsyncSession = Depends(get_session),
) -> Measurement:
    """Retrieve a single measurement by ID.

    Users can only access their own measurements.
    """
    measurement = await session.get(Measurement, measurement_id)
    if not measurement:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Measurement not found",
        )

    if measurement.owner_id and measurement.owner_id != current_user.id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Not authorized to access this measurement",
        )

    return measurement
