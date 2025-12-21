"""Patient management endpoints for therapists (remote monitoring)."""

from datetime import datetime, timedelta
from typing import Annotated
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload
from sqlmodel import func, select

from app.core.database import get_session
from app.core.deps import TherapistUser
from app.core.logging import get_logger
from app.models.session import Session, SessionStatus, SessionSummary
from app.models.treatment_plan import (
    PatientStats,
    PlanStatus,
    TreatmentPlan,
    TreatmentPlanReadWithDetails,
)
from app.models.user import User, UserRead, UserRole

router = APIRouter()
logger = get_logger(__name__)


def _calculate_compliance(completed: int, total: int) -> float:
    """Calculate compliance rate as percentage."""
    return (completed / total * 100) if total > 0 else 0.0


def _calculate_average_score(sessions: list[Session]) -> float | None:
    """Calculate average score from completed sessions."""
    scores = [s.overall_score for s in sessions if s.overall_score is not None]
    return sum(scores) / len(scores) if scores else None


def _get_last_completed_session_date(sessions: list[Session]) -> datetime | None:
    """Get the date of the most recently completed session."""
    completed = _get_sorted_completed_sessions(sessions)
    if not completed:
        return None
    return completed[0].completed_at


def _get_sorted_completed_sessions(sessions: list[Session]) -> list[Session]:
    """Get completed sessions sorted by completion date (newest first)."""
    return sorted(
        [s for s in sessions if s.status == SessionStatus.COMPLETED],
        key=lambda s: s.completed_at or s.scheduled_date,
        reverse=True,
    )


def _calculate_streak(completed_sessions: list[Session]) -> int:
    """Calculate consecutive day streak from sorted completed sessions."""
    if not completed_sessions:
        return 0

    first_session = completed_sessions[0]
    current_date = (
        first_session.completed_at.date() if first_session.completed_at else None
    )
    if not current_date:
        return 0

    streak = 0
    for s in completed_sessions:
        session_date = s.completed_at.date() if s.completed_at else None
        if session_date == current_date:
            streak += 1
            current_date -= timedelta(days=1)
        elif session_date and session_date < current_date:
            break

    return streak


@router.get("", response_model=list[UserRead])
async def list_patients(
    session: Annotated[AsyncSession, Depends(get_session)],
    current_user: TherapistUser,
    active_only: bool = True,
    skip: int = Query(0, ge=0),
    limit: int = Query(50, ge=1, le=100),
) -> list[User]:
    """List patients assigned to the current therapist."""
    # Get unique patient IDs from treatment plans
    subquery = (
        select(TreatmentPlan.patient_id)
        .where(TreatmentPlan.therapist_id == current_user.id)
        .distinct()
    )

    if active_only:
        subquery = subquery.where(TreatmentPlan.status == PlanStatus.ACTIVE)

    statement = (
        select(User)
        .where(User.id.in_(subquery))  # type: ignore[attr-defined]
        .where(User.role == UserRole.PATIENT)
        .offset(skip)
        .limit(limit)
        .order_by(User.full_name)
    )

    result = await session.execute(statement)
    return list(result.scalars().all())


@router.get("/{patient_id}", response_model=UserRead)
async def get_patient(
    patient_id: UUID,
    session: Annotated[AsyncSession, Depends(get_session)],
    current_user: TherapistUser,
) -> User:
    """Get a specific patient's details."""
    # Verify therapist has access to this patient
    statement = select(TreatmentPlan).where(
        TreatmentPlan.therapist_id == current_user.id,
        TreatmentPlan.patient_id == patient_id,
    )
    result = await session.execute(statement)
    if not result.first():
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Not authorized to view this patient",
        )

    patient = await session.get(User, patient_id)
    if not patient or patient.role != UserRole.PATIENT:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Patient not found",
        )

    return patient


@router.get("/{patient_id}/plans", response_model=list[TreatmentPlanReadWithDetails])
async def get_patient_plans(
    patient_id: UUID,
    session: Annotated[AsyncSession, Depends(get_session)],
    current_user: TherapistUser,
    status_filter: PlanStatus | None = None,
) -> list[TreatmentPlanReadWithDetails]:
    """Get all treatment plans for a patient."""
    # Base query with relationships
    statement = (
        select(TreatmentPlan)
        .where(
            TreatmentPlan.therapist_id == current_user.id,
            TreatmentPlan.patient_id == patient_id,
        )
        .options(
            selectinload(TreatmentPlan.patient),  # type: ignore[arg-type]
            selectinload(TreatmentPlan.protocol),  # type: ignore[arg-type]
        )
    )

    if status_filter:
        statement = statement.where(TreatmentPlan.status == status_filter)

    statement = statement.order_by(
        TreatmentPlan.created_at.desc()  # type: ignore[attr-defined]
    )
    result = await session.execute(statement)
    plans = result.scalars().all()

    # Enrich with stats
    enriched_plans = []
    for plan in plans:
        # Count sessions
        sessions_stmt = select(func.count(Session.id)).where(  # type: ignore[arg-type]
            Session.treatment_plan_id == plan.id
        )
        total_result = await session.execute(sessions_stmt)
        total_sessions = total_result.scalar() or 0

        completed_stmt = select(func.count(Session.id)).where(  # type: ignore[arg-type]
            Session.treatment_plan_id == plan.id,
            Session.status == SessionStatus.COMPLETED,
        )
        completed_result = await session.execute(completed_stmt)
        completed_sessions = completed_result.scalar() or 0

        compliance = (
            (completed_sessions / total_sessions * 100) if total_sessions > 0 else 0
        )

        enriched = TreatmentPlanReadWithDetails(
            id=plan.id,
            name=plan.name,
            patient_id=plan.patient_id,
            therapist_id=plan.therapist_id,
            protocol_id=plan.protocol_id,
            notes=plan.notes,
            start_date=plan.start_date,
            end_date=plan.end_date,
            status=plan.status,
            frequency_per_week=plan.frequency_per_week,
            custom_parameters=plan.custom_parameters,
            created_at=plan.created_at,
            patient_name=plan.patient.full_name if plan.patient else "",
            protocol_name=plan.protocol.name if plan.protocol else None,
            sessions_completed=completed_sessions,
            compliance_rate=compliance,
        )
        enriched_plans.append(enriched)

    return enriched_plans


@router.get("/{patient_id}/stats", response_model=PatientStats)
async def get_patient_stats(
    patient_id: UUID,
    session: Annotated[AsyncSession, Depends(get_session)],
    current_user: TherapistUser,
    plan_id: UUID | None = None,
) -> PatientStats:
    """Get statistics for a patient's rehabilitation progress."""
    plan = await _verify_plan_access(session, current_user.id, patient_id, plan_id)

    all_sessions = await _fetch_plan_sessions(session, plan.id)

    total_sessions = len(all_sessions)
    completed_sessions = sum(
        1 for s in all_sessions if s.status == SessionStatus.COMPLETED
    )
    completed_sorted = _get_sorted_completed_sessions(all_sessions)

    return PatientStats(
        plan_id=plan.id,
        total_sessions=total_sessions,
        completed_sessions=completed_sessions,
        compliance_rate=_calculate_compliance(completed_sessions, total_sessions),
        average_score=_calculate_average_score(all_sessions),
        last_session_date=_get_last_completed_session_date(all_sessions),
        streak_days=_calculate_streak(completed_sorted),
    )


async def _verify_plan_access(
    session: AsyncSession,
    therapist_id: UUID,
    patient_id: UUID,
    plan_id: UUID | None,
) -> TreatmentPlan:
    """Verify therapist has access to the patient's plan."""
    access_stmt = select(TreatmentPlan).where(
        TreatmentPlan.therapist_id == therapist_id,
        TreatmentPlan.patient_id == patient_id,
    )
    if plan_id:
        access_stmt = access_stmt.where(TreatmentPlan.id == plan_id)

    result = await session.execute(access_stmt)
    plan = result.scalar_one_or_none()

    if not plan:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Not authorized or plan not found",
        )
    return plan


async def _fetch_plan_sessions(session: AsyncSession, plan_id: UUID) -> list[Session]:
    """Fetch all sessions for a treatment plan."""
    sessions_stmt = select(Session).where(Session.treatment_plan_id == plan_id)
    sessions_result = await session.execute(sessions_stmt)
    return list(sessions_result.scalars().all())


@router.get("/{patient_id}/sessions", response_model=list[SessionSummary])
async def get_patient_sessions(
    patient_id: UUID,
    session: Annotated[AsyncSession, Depends(get_session)],
    current_user: TherapistUser,
    plan_id: UUID | None = None,
    status_filter: SessionStatus | None = None,
    skip: int = Query(0, ge=0),
    limit: int = Query(20, ge=1, le=100),
) -> list[SessionSummary]:
    """Get recent sessions for a patient (for remote monitoring)."""
    # Verify access
    access_stmt = select(TreatmentPlan.id).where(
        TreatmentPlan.therapist_id == current_user.id,
        TreatmentPlan.patient_id == patient_id,
    )
    access_result = await session.execute(access_stmt)
    plan_ids = [row[0] for row in access_result.all()]

    if not plan_ids:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Not authorized to view this patient",
        )

    # Query sessions
    statement = (
        select(Session)
        .where(Session.treatment_plan_id.in_(plan_ids))  # type: ignore[attr-defined]
        .options(
            selectinload(Session.patient),  # type: ignore[arg-type]
            selectinload(Session.exercise_results),  # type: ignore[arg-type]
        )
    )

    if plan_id and plan_id in plan_ids:
        statement = statement.where(Session.treatment_plan_id == plan_id)
    if status_filter:
        statement = statement.where(Session.status == status_filter)

    statement = (
        statement.order_by(
            Session.scheduled_date.desc()  # type: ignore[attr-defined]
        )
        .offset(skip)
        .limit(limit)
    )
    result = await session.execute(statement)
    sessions = result.scalars().all()

    summaries = []
    for s in sessions:
        # Count exercises (would need protocol exercises count for total)
        exercises_completed = len(
            [r for r in s.exercise_results if r.score is not None]
        )
        total_exercises = len(s.exercise_results) if s.exercise_results else 0

        summaries.append(
            SessionSummary(
                session_id=s.id,
                patient_id=s.patient_id,
                patient_name=s.patient.full_name if s.patient else "",
                scheduled_date=s.scheduled_date,
                status=s.status,
                overall_score=s.overall_score,
                exercises_completed=exercises_completed,
                total_exercises=total_exercises,
                duration_seconds=s.duration_seconds,
            )
        )

    return summaries
