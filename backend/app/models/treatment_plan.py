"""Treatment Plan model for patient-specific rehabilitation plans."""

from datetime import UTC, date, datetime
from enum import Enum
from uuid import UUID, uuid4

from sqlmodel import Field, Relationship, SQLModel


def utc_now() -> datetime:
    """Get current UTC datetime."""
    return datetime.now(UTC)


class PlanStatus(str, Enum):
    """Status of a treatment plan."""

    PENDING = "pending"  # Created but not started
    ACTIVE = "active"  # Currently in progress
    PAUSED = "paused"  # Temporarily paused
    COMPLETED = "completed"  # Successfully completed
    CANCELLED = "cancelled"  # Cancelled before completion


class TreatmentPlanBase(SQLModel):
    """Shared treatment plan fields."""

    name: str = Field(max_length=255)
    notes: str = Field(default="")
    start_date: date
    end_date: date | None = Field(default=None)
    status: PlanStatus = Field(default=PlanStatus.PENDING)
    frequency_per_week: int = Field(default=3, ge=1, le=14)
    # Custom adjustments (overrides protocol defaults)
    custom_parameters: dict = Field(default_factory=dict)


class TreatmentPlan(TreatmentPlanBase, table=True):
    """Database table model for treatment plans."""

    __tablename__ = "treatment_plans"

    id: UUID = Field(default_factory=uuid4, primary_key=True)
    patient_id: UUID = Field(foreign_key="users.id", index=True)
    therapist_id: UUID = Field(foreign_key="users.id", index=True)
    protocol_id: UUID | None = Field(default=None, foreign_key="protocols.id", index=True)
    created_at: datetime = Field(default_factory=utc_now)
    updated_at: datetime | None = Field(default=None)

    # Relationships
    patient: "User" = Relationship(
        back_populates="treatment_plans_as_patient",
        sa_relationship_kwargs={"foreign_keys": "[TreatmentPlan.patient_id]"},
    )
    therapist: "User" = Relationship(
        back_populates="treatment_plans_as_therapist",
        sa_relationship_kwargs={"foreign_keys": "[TreatmentPlan.therapist_id]"},
    )
    protocol: "Protocol" = Relationship(back_populates="treatment_plans")
    sessions: list["Session"] = Relationship(
        back_populates="treatment_plan",
        sa_relationship_kwargs={"cascade": "all, delete-orphan"},
    )


# Forward references
from app.models.protocol import Protocol  # noqa: E402
from app.models.session import Session  # noqa: E402
from app.models.user import User  # noqa: E402


class TreatmentPlanCreate(SQLModel):
    """Schema for creating a treatment plan."""

    name: str = Field(max_length=255)
    patient_id: UUID
    protocol_id: UUID | None = None
    notes: str = ""
    start_date: date
    end_date: date | None = None
    frequency_per_week: int = 3
    custom_parameters: dict = Field(default_factory=dict)


class TreatmentPlanRead(SQLModel):
    """Schema for reading treatment plan data."""

    id: UUID
    name: str
    patient_id: UUID
    therapist_id: UUID
    protocol_id: UUID | None
    notes: str
    start_date: date
    end_date: date | None
    status: PlanStatus
    frequency_per_week: int
    custom_parameters: dict
    created_at: datetime


class TreatmentPlanReadWithDetails(TreatmentPlanRead):
    """Schema for reading treatment plan with patient and protocol info."""

    patient_name: str = ""
    protocol_name: str | None = None
    sessions_completed: int = 0
    compliance_rate: float = 0.0


class TreatmentPlanUpdate(SQLModel):
    """Schema for updating a treatment plan (plan adjustment)."""

    name: str | None = None
    notes: str | None = None
    end_date: date | None = None
    status: PlanStatus | None = None
    frequency_per_week: int | None = None
    custom_parameters: dict | None = None


class PatientStats(SQLModel):
    """Statistics for a patient's treatment plan."""

    plan_id: UUID
    total_sessions: int
    completed_sessions: int
    compliance_rate: float  # Percentage (0-100)
    average_score: float | None  # Average exercise score
    last_session_date: datetime | None
    streak_days: int  # Consecutive days with completed sessions
