"""
Unit tests for Sessions API endpoints.

Test coverage:
1. Session CRUD operations
2. Session lifecycle (create, start, complete, skip)
3. Exercise result submission
4. Access control (patient can only access own sessions)
5. Edge cases and error handling
"""

from datetime import UTC, datetime, timedelta
from uuid import uuid4

import pytest
from httpx import AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.security import create_access_token, hash_password
from app.models.exercise import BodyPart, Exercise, ExerciseCategory
from app.models.session import Session, SessionStatus
from app.models.user import User


@pytest.fixture
async def other_user(session: AsyncSession) -> User:
    """Create another user for access control tests."""
    user = User(
        id=uuid4(),
        email="other@example.com",
        hashed_password=hash_password("otherpassword123"),
        is_active=True,
        is_verified=True,
    )
    session.add(user)
    await session.commit()
    await session.refresh(user)
    return user


@pytest.fixture
def other_user_headers(other_user: User) -> dict[str, str]:
    """Generate headers for other user."""
    token = create_access_token(other_user.id)
    return {"Authorization": f"Bearer {token}"}


@pytest.fixture
async def test_session(session: AsyncSession, test_user: User) -> Session:
    """Create a test session."""
    sess = Session(
        id=uuid4(),
        patient_id=test_user.id,
        scheduled_date=datetime.now(UTC) + timedelta(hours=1),
        status=SessionStatus.IN_PROGRESS,
    )
    session.add(sess)
    await session.commit()
    await session.refresh(sess)
    return sess


@pytest.fixture
async def started_session(session: AsyncSession, test_user: User) -> Session:
    """Create a started session."""
    sess = Session(
        id=uuid4(),
        patient_id=test_user.id,
        scheduled_date=datetime.now(UTC),
        status=SessionStatus.IN_PROGRESS,
        started_at=datetime.now(UTC),
        pain_level_before=5,
    )
    session.add(sess)
    await session.commit()
    await session.refresh(sess)
    return sess


@pytest.fixture
async def test_exercise(session: AsyncSession) -> Exercise:
    """Create a test exercise."""
    exercise = Exercise(
        id=uuid4(),
        name="Test Knee Flex",
        category=ExerciseCategory.MOBILITY,
        body_part=BodyPart.KNEE,
    )
    session.add(exercise)
    await session.commit()
    await session.refresh(exercise)
    return exercise


class TestListSessions:
    """Tests for GET /sessions endpoint."""

    async def test_list_sessions_unauthenticated(
        self,
        client: AsyncClient,
    ) -> None:
        """Unauthenticated request returns 401."""
        response = await client.get("/api/v1/sessions")
        assert response.status_code == 401

    async def test_list_sessions_success(
        self,
        client: AsyncClient,
        auth_headers: dict[str, str],
        test_session: Session,
    ) -> None:
        """User can list their own sessions."""
        response = await client.get(
            "/api/v1/sessions",
            headers=auth_headers,
        )

        assert response.status_code == 200
        data = response.json()
        assert isinstance(data, list)

    async def test_list_sessions_only_own(
        self,
        client: AsyncClient,
        auth_headers: dict[str, str],
        other_user_headers: dict[str, str],
        test_session: Session,
    ) -> None:
        """User only sees their own sessions."""
        # Other user's sessions list
        response = await client.get(
            "/api/v1/sessions",
            headers=other_user_headers,
        )

        assert response.status_code == 200
        ids = [s["id"] for s in response.json()]
        assert str(test_session.id) not in ids

    async def test_list_sessions_filter_by_status(
        self,
        client: AsyncClient,
        auth_headers: dict[str, str],
        test_session: Session,
    ) -> None:
        """Sessions can be filtered by status."""
        response = await client.get(
            "/api/v1/sessions",
            params={"status_filter": "in_progress"},
            headers=auth_headers,
        )

        assert response.status_code == 200
        for sess in response.json():
            assert sess["status"] == "in_progress"

    async def test_list_sessions_pagination(
        self,
        client: AsyncClient,
        auth_headers: dict[str, str],
    ) -> None:
        """Sessions list supports pagination."""
        response = await client.get(
            "/api/v1/sessions",
            params={"skip": 0, "limit": 5},
            headers=auth_headers,
        )

        assert response.status_code == 200
        assert len(response.json()) <= 5


class TestGetSession:
    """Tests for GET /sessions/{session_id} endpoint."""

    async def test_get_session_success(
        self,
        client: AsyncClient,
        auth_headers: dict[str, str],
        test_session: Session,
    ) -> None:
        """User can get their own session details."""
        response = await client.get(
            f"/api/v1/sessions/{test_session.id}",
            headers=auth_headers,
        )

        assert response.status_code == 200
        data = response.json()
        assert data["id"] == str(test_session.id)

    async def test_get_session_not_found(
        self,
        client: AsyncClient,
        auth_headers: dict[str, str],
    ) -> None:
        """Nonexistent session returns 404."""
        response = await client.get(
            f"/api/v1/sessions/{uuid4()}",
            headers=auth_headers,
        )

        assert response.status_code == 404

    async def test_get_session_access_denied(
        self,
        client: AsyncClient,
        other_user_headers: dict[str, str],
        test_session: Session,
    ) -> None:
        """User cannot access another user's session."""
        response = await client.get(
            f"/api/v1/sessions/{test_session.id}",
            headers=other_user_headers,
        )

        assert response.status_code == 403


class TestCreateSession:
    """Tests for POST /sessions endpoint."""

    async def test_create_session_success(
        self,
        client: AsyncClient,
        auth_headers: dict[str, str],
    ) -> None:
        """User can create a new session."""
        session_data = {
            "scheduled_date": (datetime.now(UTC) + timedelta(days=1)).isoformat(),
            "notes": "Morning session",
        }

        response = await client.post(
            "/api/v1/sessions",
            json=session_data,
            headers=auth_headers,
        )

        assert response.status_code == 201
        data = response.json()
        assert data["status"] == "in_progress"
        assert "id" in data

    async def test_create_session_minimal(
        self,
        client: AsyncClient,
        auth_headers: dict[str, str],
    ) -> None:
        """Session can be created with minimal data."""
        session_data = {
            "scheduled_date": datetime.now(UTC).isoformat(),
        }

        response = await client.post(
            "/api/v1/sessions",
            json=session_data,
            headers=auth_headers,
        )

        assert response.status_code == 201


class TestStartSession:
    """Tests for POST /sessions/{session_id}/start endpoint."""

    async def test_start_session_success(
        self,
        client: AsyncClient,
        auth_headers: dict[str, str],
        test_session: Session,
    ) -> None:
        """User can start their session."""
        start_data = {
            "pain_level_before": 6,
            "device_info": {"platform": "iOS", "version": "15.0"},
        }

        response = await client.post(
            f"/api/v1/sessions/{test_session.id}/start",
            json=start_data,
            headers=auth_headers,
        )

        assert response.status_code == 200
        data = response.json()
        assert data["pain_level_before"] == 6
        assert data["started_at"] is not None

    async def test_start_session_access_denied(
        self,
        client: AsyncClient,
        other_user_headers: dict[str, str],
        test_session: Session,
    ) -> None:
        """User cannot start another user's session."""
        response = await client.post(
            f"/api/v1/sessions/{test_session.id}/start",
            json={"pain_level_before": 5},
            headers=other_user_headers,
        )

        assert response.status_code == 403

    async def test_start_session_not_found(
        self,
        client: AsyncClient,
        auth_headers: dict[str, str],
    ) -> None:
        """Starting nonexistent session returns 404."""
        response = await client.post(
            f"/api/v1/sessions/{uuid4()}/start",
            json={"pain_level_before": 5},
            headers=auth_headers,
        )

        assert response.status_code == 404


class TestCompleteSession:
    """Tests for POST /sessions/{session_id}/complete endpoint."""

    async def test_complete_session_success(
        self,
        client: AsyncClient,
        auth_headers: dict[str, str],
        started_session: Session,
    ) -> None:
        """User can complete their started session."""
        complete_data = {
            "pain_level_after": 3,
            "notes": "Felt good after exercises",
        }

        response = await client.post(
            f"/api/v1/sessions/{started_session.id}/complete",
            json=complete_data,
            headers=auth_headers,
        )

        assert response.status_code == 200
        data = response.json()
        assert data["status"] == "completed"
        assert data["pain_level_after"] == 3

    async def test_complete_session_access_denied(
        self,
        client: AsyncClient,
        other_user_headers: dict[str, str],
        started_session: Session,
    ) -> None:
        """User cannot complete another user's session."""
        response = await client.post(
            f"/api/v1/sessions/{started_session.id}/complete",
            json={"pain_level_after": 3},
            headers=other_user_headers,
        )

        assert response.status_code == 403


class TestSkipSession:
    """Tests for POST /sessions/{session_id}/skip endpoint."""

    async def test_skip_session_success(
        self,
        client: AsyncClient,
        auth_headers: dict[str, str],
        test_session: Session,
    ) -> None:
        """User can skip their session."""
        response = await client.post(
            f"/api/v1/sessions/{test_session.id}/skip",
            params={"reason": "Not feeling well"},
            headers=auth_headers,
        )

        assert response.status_code == 200
        data = response.json()
        assert data["status"] == "skipped"

    async def test_skip_session_access_denied(
        self,
        client: AsyncClient,
        other_user_headers: dict[str, str],
        test_session: Session,
    ) -> None:
        """User cannot skip another user's session."""
        response = await client.post(
            f"/api/v1/sessions/{test_session.id}/skip",
            headers=other_user_headers,
        )

        assert response.status_code == 403


class TestSubmitExerciseResult:
    """Tests for POST /sessions/{session_id}/results endpoint."""

    async def test_submit_result_success(
        self,
        client: AsyncClient,
        auth_headers: dict[str, str],
        started_session: Session,
        test_exercise: Exercise,
    ) -> None:
        """User can submit exercise result."""
        result_data = {
            "exercise_id": str(test_exercise.id),
            "sets_completed": 3,
            "reps_completed": 10,
            "score": 85.5,
        }

        response = await client.post(
            f"/api/v1/sessions/{started_session.id}/results",
            json=result_data,
            headers=auth_headers,
        )

        assert response.status_code == 201
        data = response.json()
        assert data["sets_completed"] == 3
        assert data["score"] == 85.5

    async def test_submit_result_invalid_exercise(
        self,
        client: AsyncClient,
        auth_headers: dict[str, str],
        started_session: Session,
    ) -> None:
        """Submitting result for nonexistent exercise fails."""
        result_data = {
            "exercise_id": str(uuid4()),
            "sets_completed": 3,
            "reps_completed": 10,
        }

        response = await client.post(
            f"/api/v1/sessions/{started_session.id}/results",
            json=result_data,
            headers=auth_headers,
        )

        assert response.status_code == 404

    async def test_submit_result_access_denied(
        self,
        client: AsyncClient,
        other_user_headers: dict[str, str],
        started_session: Session,
        test_exercise: Exercise,
    ) -> None:
        """User cannot submit results to another user's session."""
        result_data = {
            "exercise_id": str(test_exercise.id),
            "sets_completed": 3,
            "reps_completed": 10,
        }

        response = await client.post(
            f"/api/v1/sessions/{started_session.id}/results",
            json=result_data,
            headers=other_user_headers,
        )

        assert response.status_code == 403


class TestSessionEdgeCases:
    """Tests for edge cases."""

    async def test_session_with_max_pain_level(
        self,
        client: AsyncClient,
        auth_headers: dict[str, str],
        test_session: Session,
    ) -> None:
        """Pain level at maximum (10) is accepted."""
        response = await client.post(
            f"/api/v1/sessions/{test_session.id}/start",
            json={"pain_level_before": 10},
            headers=auth_headers,
        )

        assert response.status_code == 200

    async def test_session_with_zero_pain_level(
        self,
        client: AsyncClient,
        auth_headers: dict[str, str],
        test_session: Session,
    ) -> None:
        """Pain level at minimum (0) is accepted."""
        response = await client.post(
            f"/api/v1/sessions/{test_session.id}/start",
            json={"pain_level_before": 0},
            headers=auth_headers,
        )

        assert response.status_code == 200

    async def test_session_scheduled_in_past(
        self,
        client: AsyncClient,
        auth_headers: dict[str, str],
    ) -> None:
        """Session can be created for past date (ad-hoc logging)."""
        session_data = {
            "scheduled_date": (datetime.now(UTC) - timedelta(days=1)).isoformat(),
        }

        response = await client.post(
            "/api/v1/sessions",
            json=session_data,
            headers=auth_headers,
        )

        # Should be allowed for recording past sessions
        assert response.status_code == 201

    async def test_result_with_max_score(
        self,
        client: AsyncClient,
        auth_headers: dict[str, str],
        started_session: Session,
        test_exercise: Exercise,
    ) -> None:
        """Perfect score (100) is accepted."""
        result_data = {
            "exercise_id": str(test_exercise.id),
            "sets_completed": 3,
            "reps_completed": 10,
            "score": 100.0,
        }

        response = await client.post(
            f"/api/v1/sessions/{started_session.id}/results",
            json=result_data,
            headers=auth_headers,
        )

        assert response.status_code == 201

    async def test_result_with_zero_score(
        self,
        client: AsyncClient,
        auth_headers: dict[str, str],
        started_session: Session,
        test_exercise: Exercise,
    ) -> None:
        """Zero score is accepted."""
        result_data = {
            "exercise_id": str(test_exercise.id),
            "sets_completed": 0,
            "reps_completed": 0,
            "score": 0.0,
        }

        response = await client.post(
            f"/api/v1/sessions/{started_session.id}/results",
            json=result_data,
            headers=auth_headers,
        )

        assert response.status_code == 201
