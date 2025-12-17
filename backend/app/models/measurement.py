"""Measurement model mirroring Flutter's MeasurementModel.

Schema matches Drift table for seamless offline-first sync.
"""

from datetime import UTC, datetime
from typing import Any
from uuid import UUID

from pydantic import Field
from sqlmodel import JSON, Column, SQLModel
from sqlmodel import Field as SQLField


def utc_now() -> datetime:
    """Get current UTC datetime (timezone-aware)."""
    return datetime.now(UTC)


class MeasurementBase(SQLModel):
    """Shared fields between create/read schemas."""

    user_id: str = SQLField(index=True)
    type: str = SQLField(index=True)
    json_data: dict[str, Any] = SQLField(sa_column=Column(JSON))


class Measurement(MeasurementBase, table=True):
    """Database table model for measurements."""

    __tablename__ = "measurements"

    # Client-generated UUID ensures idempotent syncs
    id: UUID = SQLField(primary_key=True)
    created_at: datetime = SQLField(default_factory=utc_now, index=True)
    updated_at: datetime | None = SQLField(default=None)

    # Server-side metadata
    received_at: datetime = SQLField(default_factory=utc_now)

    # Owner reference (authenticated user who synced this measurement)
    owner_id: UUID | None = SQLField(default=None, index=True)


class MeasurementCreate(MeasurementBase):
    """Schema for creating measurements (from Flutter client)."""

    id: UUID
    created_at: datetime


class MeasurementRead(MeasurementBase):
    """Schema for reading measurements (API response)."""

    id: UUID
    created_at: datetime
    updated_at: datetime | None
    received_at: datetime


class SyncResponse(SQLModel):
    """Response matching Flutter's SyncResponse model."""

    success: bool
    backend_id: str = Field(serialization_alias="backendId")
    error_message: str | None = Field(default=None, serialization_alias="errorMessage")
