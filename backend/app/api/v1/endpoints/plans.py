"""Treatment Plan management endpoints."""

from datetime import UTC, datetime
from typing import Annotated
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload
from sqlmodel import func, select

from app.core.database import get_session
from app.core.deps import ActiveUser, TherapistUser
from app.core.logging import get_logger
from app.models.session import Session, SessionStatus
from app.models.treatment_plan import (
    PlanStatus,
    TreatmentPlan,
    TreatmentPlanCreate,
    TreatmentPlanRead,
    TreatmentPlanReadWithDetails,
    TreatmentPlanUpdate,
)
from app.models.user import UserRole

router = APIRouter()
logger = get_logger(__name__)

_NOT_AUTHORIZED = "Not authorized"
_TREATMENT_PLAN_NOT_FOUND = "Treatment plan not found"


@router.get("", response_model=list[TreatmentPlanRead])
async def list_plans(
    session: Annotated[AsyncSession, Depends(get_session)],
    current_user: ActiveUser,
    status_filter: PlanStatus | None = None,
    skip: int = Query(0, ge=0),
    limit: int = Query(50, ge=1, le=100),
) -> list[TreatmentPlan]:
    """List treatment plans. Patients see their own, therapists see all assigned."""
    if current_user.role == UserRole.PATIENT:
        statement = select(TreatmentPlan).where(
            TreatmentPlan.patient_id == current_user.id
        )
    else:
        statement = select(TreatmentPlan).where(
            TreatmentPlan.therapist_id == current_user.id
        )

    if status_filter:
        statement = statement.where(TreatmentPlan.status == status_filter)

    statement = statement.offset(skip).limit(limit).order_by(TreatmentPlan.created_at.desc())
    result = await session.execute(statement)
    return list(result.scalars().all())


@router.get("/{plan_id}", response_model=TreatmentPlanReadWithDetails)
async def get_plan(
    plan_id: UUID,
    session: Annotated[AsyncSession, Depends(get_session)],
    current_user: ActiveUser,
) -> TreatmentPlanReadWithDetails:
    """Get a treatment plan with details."""
    statement = (
        select(TreatmentPlan)
        .where(TreatmentPlan.id == plan_id)
        .options(
            selectinload(TreatmentPlan.patient),
            selectinload(TreatmentPlan.protocol),
        )
    )
    result = await session.execute(statement)
    plan = result.scalar_one_or_none()

    if not plan:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Treatment plan not found",
        )

    # Check access
    if current_user.role == UserRole.PATIENT and plan.patient_id != current_user.id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Access denied",
        )
    if current_user.role == UserRole.THERAPIST and plan.therapist_id != current_user.id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Access denied",
        )

    # Calculate stats
    sessions_stmt = select(func.count(Session.id)).where(
        Session.treatment_plan_id == plan.id
    )
    total_result = await session.execute(sessions_stmt)
    total_sessions = total_result.scalar() or 0

    completed_stmt = select(func.count(Session.id)).where(
        Session.treatment_plan_id == plan.id,
        Session.status == SessionStatus.COMPLETED,
    )
    completed_result = await session.execute(completed_stmt)
    completed_sessions = completed_result.scalar() or 0

    compliance = (completed_sessions / total_sessions * 100) if total_sessions > 0 else 0

    return TreatmentPlanReadWithDetails(
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


@router.post("", response_model=TreatmentPlanRead, status_code=status.HTTP_201_CREATED)
async def create_plan(
    data: TreatmentPlanCreate,
    session: Annotated[AsyncSession, Depends(get_session)],
    current_user: TherapistUser,
) -> TreatmentPlan:
    """Create a treatment plan for a patient (Therapist only)."""
    # Verify patient exists
    from app.models.user import User

    patient = await session.get(User, data.patient_id)
    if not patient or patient.role != UserRole.PATIENT:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Patient not found",
        )

    # Verify protocol if provided
    if data.protocol_id:
        from app.models.protocol import Protocol

        protocol = await session.get(Protocol, data.protocol_id)
        if not protocol:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Protocol not found",
            )

    plan = TreatmentPlan(
        **data.model_dump(),
        therapist_id=current_user.id,
    )
    session.add(plan)
    await session.commit()
    await session.refresh(plan)

    logger.info(
        "treatment_plan_created",
        plan_id=str(plan.id),
        patient_id=str(plan.patient_id),
        therapist_id=str(current_user.id),
    )
    return plan


@router.patch("/{plan_id}", response_model=TreatmentPlanRead)
async def update_plan(
    plan_id: UUID,
    data: TreatmentPlanUpdate,
    session: Annotated[AsyncSession, Depends(get_session)],
    current_user: TherapistUser,
) -> TreatmentPlan:
    """Update/adjust a treatment plan (Plan Adjustment feature)."""
    plan = await session.get(TreatmentPlan, plan_id)
    if not plan:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=_TREATMENT_PLAN_NOT_FOUND,
        )

    # Check ownership
    if plan.therapist_id != current_user.id and current_user.role != UserRole.ADMIN:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail=_NOT_AUTHORIZED,
        )

    update_data = data.model_dump(exclude_unset=True)
    for key, value in update_data.items():
        setattr(plan, key, value)

    plan.updated_at = datetime.now(UTC)
    session.add(plan)
    await session.commit()
    await session.refresh(plan)

    logger.info(
        "treatment_plan_updated",
        plan_id=str(plan.id),
        updated_by=str(current_user.id),
        changes=list(update_data.keys()),
    )
    return plan


@router.post("/{plan_id}/activate", response_model=TreatmentPlanRead)
async def activate_plan(
    plan_id: UUID,
    session: Annotated[AsyncSession, Depends(get_session)],
    current_user: TherapistUser,
) -> TreatmentPlan:
    """Activate a pending treatment plan."""
    plan = await session.get(TreatmentPlan, plan_id)
    if not plan:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=_TREATMENT_PLAN_NOT_FOUND,
        )

    if plan.therapist_id != current_user.id and current_user.role != UserRole.ADMIN:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail=_NOT_AUTHORIZED,
        )

    if plan.status != PlanStatus.PENDING:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Cannot activate plan with status: {plan.status}",
        )

    plan.status = PlanStatus.ACTIVE
    plan.updated_at = datetime.now(UTC)
    session.add(plan)
    await session.commit()
    await session.refresh(plan)

    logger.info("treatment_plan_activated", plan_id=str(plan.id))
    return plan


@router.post("/{plan_id}/pause", response_model=TreatmentPlanRead)
async def pause_plan(
    plan_id: UUID,
    session: Annotated[AsyncSession, Depends(get_session)],
    current_user: TherapistUser,
) -> TreatmentPlan:
    """Pause an active treatment plan."""
    plan = await session.get(TreatmentPlan, plan_id)
    if not plan:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=_TREATMENT_PLAN_NOT_FOUND,
        )

    if plan.therapist_id != current_user.id and current_user.role != UserRole.ADMIN:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail=_NOT_AUTHORIZED,
        )

    if plan.status != PlanStatus.ACTIVE:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Cannot pause plan with status: {plan.status}",
        )

    plan.status = PlanStatus.PAUSED
    plan.updated_at = datetime.now(UTC)
    session.add(plan)
    await session.commit()
    await session.refresh(plan)

    logger.info("treatment_plan_paused", plan_id=str(plan.id))
    return plan


@router.post("/{plan_id}/complete", response_model=TreatmentPlanRead)
async def complete_plan(
    plan_id: UUID,
    session: Annotated[AsyncSession, Depends(get_session)],
    current_user: TherapistUser,
) -> TreatmentPlan:
    """Mark a treatment plan as completed."""
    plan = await session.get(TreatmentPlan, plan_id)
    if not plan:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=_TREATMENT_PLAN_NOT_FOUND,
        )

    if plan.therapist_id != current_user.id and current_user.role != UserRole.ADMIN:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail=_NOT_AUTHORIZED,
        )

    plan.status = PlanStatus.COMPLETED
    plan.updated_at = datetime.now(UTC)
    session.add(plan)
    await session.commit()
    await session.refresh(plan)

    logger.info("treatment_plan_completed", plan_id=str(plan.id))
    return plan
