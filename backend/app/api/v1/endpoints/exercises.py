"""Exercise management endpoints (Admin/Therapist only)."""

from datetime import UTC, datetime
from typing import Annotated
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlmodel import select

from app.core.database import get_session
from app.core.deps import ActiveUser, TherapistUser
from app.core.logging import get_logger
from app.models.exercise import (
    BodyPart,
    Exercise,
    ExerciseCategory,
    ExerciseCreate,
    ExerciseRead,
    ExerciseUpdate,
)

router = APIRouter()
logger = get_logger(__name__)

_EXERCISE_NOT_FOUND = "Exercise not found"


@router.get("", response_model=list[ExerciseRead])
async def list_exercises(
    session: Annotated[AsyncSession, Depends(get_session)],
    current_user: ActiveUser,
    category: ExerciseCategory | None = None,
    body_part: BodyPart | None = None,
    difficulty: int | None = Query(None, ge=1, le=5),
    skip: int = Query(0, ge=0),
    limit: int = Query(50, ge=1, le=100),
) -> list[Exercise]:
    """List all active exercises with optional filters."""
    statement = select(Exercise).where(Exercise.is_active == True)  # noqa: E712

    if category:
        statement = statement.where(Exercise.category == category)
    if body_part:
        statement = statement.where(Exercise.body_part == body_part)
    if difficulty:
        statement = statement.where(Exercise.difficulty_level == difficulty)

    statement = statement.offset(skip).limit(limit).order_by(Exercise.name)
    result = await session.execute(statement)
    return list(result.scalars().all())


@router.get("/{exercise_id}", response_model=ExerciseRead)
async def get_exercise(
    exercise_id: UUID,
    session: Annotated[AsyncSession, Depends(get_session)],
    current_user: ActiveUser,
) -> Exercise:
    """Get a single exercise by ID."""
    exercise = await session.get(Exercise, exercise_id)
    if not exercise:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=_EXERCISE_NOT_FOUND,
        )
    return exercise


@router.post("", response_model=ExerciseRead, status_code=status.HTTP_201_CREATED)
async def create_exercise(
    data: ExerciseCreate,
    session: Annotated[AsyncSession, Depends(get_session)],
    current_user: TherapistUser,
) -> Exercise:
    """Create a new exercise (Therapist/Admin only)."""
    exercise = Exercise(**data.model_dump())
    session.add(exercise)
    await session.commit()
    await session.refresh(exercise)

    logger.info(
        "exercise_created",
        exercise_id=str(exercise.id),
        name=exercise.name,
        created_by=str(current_user.id),
    )
    return exercise


@router.patch("/{exercise_id}", response_model=ExerciseRead)
async def update_exercise(
    exercise_id: UUID,
    data: ExerciseUpdate,
    session: Annotated[AsyncSession, Depends(get_session)],
    current_user: TherapistUser,
) -> Exercise:
    """Update an exercise (Therapist/Admin only)."""
    exercise = await session.get(Exercise, exercise_id)
    if not exercise:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=_EXERCISE_NOT_FOUND,
        )

    update_data = data.model_dump(exclude_unset=True)
    for key, value in update_data.items():
        setattr(exercise, key, value)

    exercise.updated_at = datetime.now(UTC)
    session.add(exercise)
    await session.commit()
    await session.refresh(exercise)

    logger.info(
        "exercise_updated",
        exercise_id=str(exercise.id),
        updated_by=str(current_user.id),
    )
    return exercise


@router.delete("/{exercise_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_exercise(
    exercise_id: UUID,
    session: Annotated[AsyncSession, Depends(get_session)],
    current_user: TherapistUser,
) -> None:
    """Soft delete an exercise (Therapist/Admin only)."""
    exercise = await session.get(Exercise, exercise_id)
    if not exercise:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=_EXERCISE_NOT_FOUND,
        )

    exercise.is_active = False
    exercise.updated_at = datetime.now(UTC)
    session.add(exercise)
    await session.commit()

    logger.info(
        "exercise_deleted",
        exercise_id=str(exercise.id),
        deleted_by=str(current_user.id),
    )
