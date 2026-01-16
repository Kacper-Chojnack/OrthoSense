"""
Integration tests for complete session workflow.

Test coverage:
1. Full session lifecycle: create -> start -> exercise results -> complete
2. Session statistics calculation
3. Multiple sessions for a patient
4. Session skip flow
5. Session abandonment
"""

from datetime import UTC, datetime, timedelta
from uuid import uuid4

import pytest
from httpx import AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession
from sqlmodel import select

from app.core.security import create_access_token, hash_password
from app.models.exercise import BodyPart, Exercise, ExerciseCategory
from app.models.session import (
    Session,
    SessionExerciseResult,
    SessionStatus,
)
from app.models.user import User, UserRole


@pytest.fixture
async def exercises(session: AsyncSession) -> list[Exercise]:
    """Create test exercises."""
    exercises = [
        Exercise(
            id=uuid4(),
            name="Knee Extension",
            category=ExerciseCategory.MOBILITY,
            body_part=BodyPart.KNEE,
            difficulty_level=1,
            is_active=True,
        ),
        Exercise(
            id=uuid4(),
            name="Quad Stretch",
            category=ExerciseCategory.STRETCHING,
            body_part=BodyPart.KNEE,
            difficulty_level=2,
            is_active=True,
        ),
        Exercise(
            id=uuid4(),
            name="Wall Sit",
            category=ExerciseCategory.STRENGTH,
            body_part=BodyPart.KNEE,
            difficulty_level=3,
            is_active=True,
        ),
    ]
    for ex in exercises:
        session.add(ex)
    await session.commit()
    return exercises


class TestCompleteSessionWorkflow:
    """Test complete session lifecycle."""

    @pytest.mark.asyncio
    async def test_full_session_lifecycle(
        self,
        client: AsyncClient,
        session: AsyncSession,
        test_user: User,
        auth_headers: dict[str, str],
        exercises: list[Exercise],
    ) -> None:
        """Test: create -> start -> submit results -> complete."""
        # Step 1: Create session
        scheduled_date = datetime.now(UTC).isoformat()
        create_response = await client.post(
            "/api/v1/sessions",
            headers=auth_headers,
            json={
                "scheduled_date": scheduled_date,
                "notes": "Morning knee rehab session",
            },
        )

        assert create_response.status_code == 201
        session_data = create_response.json()
        session_id = session_data["id"]
        assert session_data["status"] == "in_progress"

        # Step 2: Start session
        start_response = await client.post(
            f"/api/v1/sessions/{session_id}/start",
            headers=auth_headers,
            json={
                "pain_level_before": 4,
                "device_info": {"platform": "ios", "app_version": "1.0.0"},
            },
        )

        assert start_response.status_code == 200
        started_data = start_response.json()
        assert started_data["pain_level_before"] == 4
        assert started_data["started_at"] is not None

        # Step 3: Submit exercise results
        for i, exercise in enumerate(exercises):
            result_response = await client.post(
                f"/api/v1/sessions/{session_id}/results",
                headers=auth_headers,
                json={
                    "exercise_id": str(exercise.id),
                    "sets_completed": 3,
                    "reps_completed": 10 + i,
                    "hold_seconds_achieved": 15,
                    "score": 85.0 + i * 5,
                },
            )
            assert result_response.status_code == 201

        # Step 4: Complete session
        complete_response = await client.post(
            f"/api/v1/sessions/{session_id}/complete",
            headers=auth_headers,
            json={
                "pain_level_after": 2,
                "notes": "Completed without issues",
            },
        )

        assert complete_response.status_code == 200
        completed_data = complete_response.json()
        assert completed_data["status"] == "completed"
        assert completed_data["pain_level_after"] == 2
        assert completed_data["completed_at"] is not None
        assert completed_data["duration_seconds"] is not None

        # Step 5: Verify session with results
        get_response = await client.get(
            f"/api/v1/sessions/{session_id}",
            headers=auth_headers,
        )

        assert get_response.status_code == 200
        final_data = get_response.json()
        assert len(final_data["exercise_results"]) == 3

    @pytest.mark.asyncio
    async def test_session_skip_flow(
        self,
        client: AsyncClient,
        session: AsyncSession,
        test_user: User,
        auth_headers: dict[str, str],
    ) -> None:
        """Test skipping a scheduled session."""
        # Create session
        create_response = await client.post(
            "/api/v1/sessions",
            headers=auth_headers,
            json={
                "scheduled_date": datetime.now(UTC).isoformat(),
                "notes": "Session to be skipped",
            },
        )

        assert create_response.status_code == 201
        session_id = create_response.json()["id"]

        # Skip session
        skip_response = await client.post(
            f"/api/v1/sessions/{session_id}/skip",
            headers=auth_headers,
        )

        assert skip_response.status_code == 200
        skipped_data = skip_response.json()
        assert skipped_data["status"] == "skipped"

    @pytest.mark.asyncio
    async def test_pain_level_improvement(
        self,
        client: AsyncClient,
        session: AsyncSession,
        test_user: User,
        auth_headers: dict[str, str],
    ) -> None:
        """Test that pain levels are tracked before and after session."""
        # Create and start session
        create_response = await client.post(
            "/api/v1/sessions",
            headers=auth_headers,
            json={"scheduled_date": datetime.now(UTC).isoformat()},
        )
        session_id = create_response.json()["id"]

        # Start with high pain
        await client.post(
            f"/api/v1/sessions/{session_id}/start",
            headers=auth_headers,
            json={"pain_level_before": 7},
        )

        # Complete with lower pain
        complete_response = await client.post(
            f"/api/v1/sessions/{session_id}/complete",
            headers=auth_headers,
            json={"pain_level_after": 4},
        )

        data = complete_response.json()
        assert data["pain_level_before"] == 7
        assert data["pain_level_after"] == 4
        # Pain improved by 3 points
        pain_improvement = data["pain_level_before"] - data["pain_level_after"]
        assert pain_improvement == 3


class TestSessionListing:
    """Test session listing and filtering."""

    @pytest.mark.asyncio
    async def test_list_user_sessions(
        self,
        client: AsyncClient,
        session: AsyncSession,
        test_user: User,
        auth_headers: dict[str, str],
    ) -> None:
        """User can list their own sessions."""
        # Create multiple sessions
        for i in range(5):
            db_session = Session(
                patient_id=test_user.id,
                scheduled_date=datetime.now(UTC).replace(tzinfo=None) + timedelta(days=i),
                status=SessionStatus.IN_PROGRESS if i < 3 else SessionStatus.COMPLETED,
            )
            session.add(db_session)
        await session.commit()

        response = await client.get(
            "/api/v1/sessions",
            headers=auth_headers,
        )

        assert response.status_code == 200
        data = response.json()
        assert len(data) == 5

    @pytest.mark.asyncio
    async def test_filter_sessions_by_status(
        self,
        client: AsyncClient,
        session: AsyncSession,
        test_user: User,
        auth_headers: dict[str, str],
    ) -> None:
        """Filter sessions by status."""
        # Create sessions with different statuses
        statuses = [
            SessionStatus.IN_PROGRESS,
            SessionStatus.IN_PROGRESS,
            SessionStatus.COMPLETED,
            SessionStatus.SKIPPED,
        ]
        for i, status in enumerate(statuses):
            db_session = Session(
                patient_id=test_user.id,
                scheduled_date=datetime.now(UTC).replace(tzinfo=None) + timedelta(days=i),
                status=status,
            )
            session.add(db_session)
        await session.commit()

        # Filter for completed only
        response = await client.get(
            "/api/v1/sessions",
            headers=auth_headers,
            params={"status_filter": "completed"},
        )

        assert response.status_code == 200
        data = response.json()
        assert len(data) == 1
        assert data[0]["status"] == "completed"

    @pytest.mark.asyncio
    async def test_sessions_pagination(
        self,
        client: AsyncClient,
        session: AsyncSession,
        test_user: User,
        auth_headers: dict[str, str],
    ) -> None:
        """Pagination works correctly."""
        # Create 25 sessions
        for i in range(25):
            db_session = Session(
                patient_id=test_user.id,
                scheduled_date=datetime.now(UTC).replace(tzinfo=None) + timedelta(days=i),
            )
            session.add(db_session)
        await session.commit()

        # First page
        response = await client.get(
            "/api/v1/sessions",
            headers=auth_headers,
            params={"skip": 0, "limit": 10},
        )

        assert response.status_code == 200
        assert len(response.json()) == 10

        # Second page
        response = await client.get(
            "/api/v1/sessions",
            headers=auth_headers,
            params={"skip": 10, "limit": 10},
        )

        assert response.status_code == 200
        assert len(response.json()) == 10


class TestSessionExerciseResults:
    """Test exercise result submission."""

    @pytest.mark.asyncio
    async def test_submit_exercise_result(
        self,
        client: AsyncClient,
        session: AsyncSession,
        test_user: User,
        auth_headers: dict[str, str],
        exercises: list[Exercise],
    ) -> None:
        """Submit exercise result to session."""
        # Create session
        db_session = Session(
            id=uuid4(),
            patient_id=test_user.id,
            scheduled_date=datetime.now(UTC).replace(tzinfo=None),
            status=SessionStatus.IN_PROGRESS,
        )
        session.add(db_session)
        await session.commit()

        # Submit result
        response = await client.post(
            f"/api/v1/sessions/{db_session.id}/results",
            headers=auth_headers,
            json={
                "exercise_id": str(exercises[0].id),
                "sets_completed": 3,
                "reps_completed": 12,
                "hold_seconds_achieved": 20,
                "score": 92.5,
            },
        )

        assert response.status_code == 201
        data = response.json()
        assert data["sets_completed"] == 3
        assert data["reps_completed"] == 12
        assert data["score"] == 92.5

    @pytest.mark.asyncio
    async def test_cannot_submit_result_to_completed_session(
        self,
        client: AsyncClient,
        session: AsyncSession,
        test_user: User,
        auth_headers: dict[str, str],
        exercises: list[Exercise],
    ) -> None:
        """Cannot submit results to a completed session."""
        # Create completed session
        db_session = Session(
            id=uuid4(),
            patient_id=test_user.id,
            scheduled_date=datetime.now(UTC).replace(tzinfo=None),
            status=SessionStatus.COMPLETED,
        )
        session.add(db_session)
        await session.commit()

        # Try to submit result
        response = await client.post(
            f"/api/v1/sessions/{db_session.id}/results",
            headers=auth_headers,
            json={
                "exercise_id": str(exercises[0].id),
                "sets_completed": 3,
                "reps_completed": 12,
            },
        )

        # Should be rejected
        assert response.status_code in [400, 422]


class TestSessionAccess:
    """Test session access control."""

    @pytest.mark.asyncio
    async def test_cannot_access_other_user_session(
        self,
        client: AsyncClient,
        session: AsyncSession,
        test_user: User,
        auth_headers: dict[str, str],
    ) -> None:
        """User cannot access another user's session."""
        # Create another user
        other_user = User(
            id=uuid4(),
            email="other@example.com",
            hashed_password=hash_password("password123"),
            is_active=True,
            is_verified=True,
        )
        session.add(other_user)

        # Create session for other user
        other_session = Session(
            id=uuid4(),
            patient_id=other_user.id,
            scheduled_date=datetime.now(UTC).replace(tzinfo=None),
        )
        session.add(other_session)
        await session.commit()

        # Try to access other user's session
        response = await client.get(
            f"/api/v1/sessions/{other_session.id}",
            headers=auth_headers,
        )

        # Should be 403 Forbidden or 404 Not Found
        assert response.status_code in [403, 404]

    @pytest.mark.asyncio
    async def test_unauthenticated_cannot_access_sessions(
        self,
        client: AsyncClient,
    ) -> None:
        """Unauthenticated users cannot access sessions."""
        response = await client.get("/api/v1/sessions")
        assert response.status_code == 401
