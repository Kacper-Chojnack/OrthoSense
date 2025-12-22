"""Exercise demonstration videos endpoints.

Videos showing correct technique - NOT analyzed in real-time.
"""

from datetime import UTC, datetime
from typing import Annotated
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlmodel import select

from app.core.database import get_session
from app.core.deps import ActiveUser, TherapistUser
from app.core.logging import get_logger
from app.models.exercise import Exercise
from app.models.exercise_video import (
    ExerciseVideo,
    ExerciseVideoCreate,
    ExerciseVideoRead,
    ExerciseVideoUpdate,
)

router = APIRouter()
logger = get_logger(__name__)

_VIDEO_NOT_FOUND = "Video not found"
_EXERCISE_NOT_FOUND = "Exercise not found"


@router.get("/exercise/{exercise_id}", response_model=list[ExerciseVideoRead])
async def list_exercise_videos(
    exercise_id: UUID,
    session: Annotated[AsyncSession, Depends(get_session)],
    current_user: ActiveUser,
    skip: int = Query(0, ge=0),
    limit: int = Query(20, ge=1, le=50),
) -> list[ExerciseVideo]:
    """List all active demo videos for a specific exercise."""
    statement = (
        select(ExerciseVideo)
        .where(ExerciseVideo.exercise_id == exercise_id)
        .where(ExerciseVideo.is_active == True)  # noqa: E712
        .order_by(ExerciseVideo.is_primary.desc(), ExerciseVideo.sort_order)
        .offset(skip)
        .limit(limit)
    )
    result = await session.execute(statement)
    return list(result.scalars().all())


@router.get("/exercise/{exercise_id}/primary", response_model=ExerciseVideoRead | None)
async def get_primary_video(
    exercise_id: UUID,
    session: Annotated[AsyncSession, Depends(get_session)],
    current_user: ActiveUser,
) -> ExerciseVideo | None:
    """Get the primary demo video for an exercise (if any)."""
    statement = (
        select(ExerciseVideo)
        .where(ExerciseVideo.exercise_id == exercise_id)
        .where(ExerciseVideo.is_active == True)  # noqa: E712
        .where(ExerciseVideo.is_primary == True)  # noqa: E712
    )
    result = await session.execute(statement)
    return result.scalar_one_or_none()


@router.get("/{video_id}", response_model=ExerciseVideoRead)
async def get_video(
    video_id: UUID,
    session: Annotated[AsyncSession, Depends(get_session)],
    current_user: ActiveUser,
) -> ExerciseVideo:
    """Get a single video by ID."""
    video = await session.get(ExerciseVideo, video_id)
    if not video:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=_VIDEO_NOT_FOUND,
        )
    return video


@router.post("", response_model=ExerciseVideoRead, status_code=status.HTTP_201_CREATED)
async def create_video(
    data: ExerciseVideoCreate,
    session: Annotated[AsyncSession, Depends(get_session)],
    current_user: TherapistUser,
) -> ExerciseVideo:
    """Create a new demo video (Therapist/Admin only)."""
    # Verify exercise exists
    exercise = await session.get(Exercise, data.exercise_id)
    if not exercise:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=_EXERCISE_NOT_FOUND,
        )

    # If marking as primary, unset other primary videos
    if data.is_primary:
        await _unset_primary_videos(session, data.exercise_id)

    video = ExerciseVideo(**data.model_dump())
    session.add(video)
    await session.commit()
    await session.refresh(video)

    logger.info(
        "exercise_video_created",
        video_id=str(video.id),
        exercise_id=str(video.exercise_id),
        title=video.title,
        created_by=str(current_user.id),
    )
    return video


@router.patch("/{video_id}", response_model=ExerciseVideoRead)
async def update_video(
    video_id: UUID,
    data: ExerciseVideoUpdate,
    session: Annotated[AsyncSession, Depends(get_session)],
    current_user: TherapistUser,
) -> ExerciseVideo:
    """Update a demo video (Therapist/Admin only)."""
    video = await session.get(ExerciseVideo, video_id)
    if not video:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=_VIDEO_NOT_FOUND,
        )

    update_data = data.model_dump(exclude_unset=True)

    # If marking as primary, unset other primary videos
    if update_data.get("is_primary"):
        await _unset_primary_videos(session, video.exercise_id, exclude_id=video_id)

    for key, value in update_data.items():
        setattr(video, key, value)

    video.updated_at = datetime.now(UTC)
    session.add(video)
    await session.commit()
    await session.refresh(video)

    logger.info(
        "exercise_video_updated",
        video_id=str(video.id),
        updated_by=str(current_user.id),
    )
    return video


@router.delete("/{video_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_video(
    video_id: UUID,
    session: Annotated[AsyncSession, Depends(get_session)],
    current_user: TherapistUser,
) -> None:
    """Soft delete a demo video (Therapist/Admin only)."""
    video = await session.get(ExerciseVideo, video_id)
    if not video:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=_VIDEO_NOT_FOUND,
        )

    video.is_active = False
    video.updated_at = datetime.now(UTC)
    session.add(video)
    await session.commit()

    logger.info(
        "exercise_video_deleted",
        video_id=str(video.id),
        deleted_by=str(current_user.id),
    )


async def _unset_primary_videos(
    session: AsyncSession,
    exercise_id: UUID,
    exclude_id: UUID | None = None,
) -> None:
    """Unset is_primary for all videos of an exercise."""
    statement = (
        select(ExerciseVideo)
        .where(ExerciseVideo.exercise_id == exercise_id)
        .where(ExerciseVideo.is_primary == True)  # noqa: E712
    )
    if exclude_id:
        statement = statement.where(ExerciseVideo.id != exclude_id)

    result = await session.execute(statement)
    for video in result.scalars().all():
        video.is_primary = False
        video.updated_at = datetime.now(UTC)
        session.add(video)
