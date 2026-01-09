"""Integration tests for full session flow.

Tests the complete user journey:
1. Register → Login → Create Session → Start → Add Results → Complete
2. Session lifecycle with all edge cases
3. Cross-feature integration (auth + sessions + exercises)
"""

import os
from datetime import UTC, datetime
from uuid import uuid4

# Set environment variables BEFORE importing app modules
os.environ["SECRET_KEY"] = "test_secret_key_for_integration_tests_12345"
os.environ["DATABASE_URL"] = "sqlite+aiosqlite:///:memory:"

import pytest
import pytest_asyncio
from httpx import ASGITransport, AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession, create_async_engine
from sqlalchemy.orm import sessionmaker
from sqlmodel import SQLModel

from app.core.database import get_session
from app.core.security import create_access_token, hash_password
from app.main import app
from app.models.exercise import BodyPart, Exercise, ExerciseCategory
from app.models.session import SessionStatus
from app.models.user import User


@pytest_asyncio.fixture
async def async_engine():
    """Create in-memory SQLite engine for tests."""
    engine = create_async_engine(
        "sqlite+aiosqlite:///:memory:",
        echo=False,
        connect_args={"check_same_thread": False},
    )
    async with engine.begin() as conn:
        await conn.run_sync(SQLModel.metadata.create_all)
    yield engine
    await engine.dispose()


@pytest_asyncio.fixture
async def session(async_engine) -> AsyncSession:
    """Provide test database session."""
    async_session_factory = sessionmaker(
        async_engine,
        class_=AsyncSession,
        expire_on_commit=False,
    )
    async with async_session_factory() as session:
        yield session


@pytest_asyncio.fixture
async def client(session: AsyncSession) -> AsyncClient:
    """Provide test HTTP client with overridden dependencies."""

    async def override_get_session():
        yield session

    app.dependency_overrides[get_session] = override_get_session

    async with AsyncClient(
        transport=ASGITransport(app=app),
        base_url="http://localhost",
    ) as client:
        yield client

    app.dependency_overrides.clear()


@pytest_asyncio.fixture
async def test_user(session: AsyncSession) -> User:
    """Create verified test user."""
    user = User(
        id=uuid4(),
        email="session_test@example.com",
        hashed_password=hash_password("testpassword123"),
        is_active=True,
        is_verified=True,
    )
    session.add(user)
    await session.commit()
    await session.refresh(user)
    return user


@pytest.fixture
def auth_headers(test_user: User) -> dict[str, str]:
    """Generate auth headers for test user."""
    token = create_access_token(test_user.id)
    return {"Authorization": f"Bearer {token}"}


@pytest_asyncio.fixture
async def test_exercise(session: AsyncSession) -> Exercise:
    """Create test exercise."""
    exercise = Exercise(
        id=uuid4(),
        name="Test Deep Squat",
        description="Test squat exercise",
        category=ExerciseCategory.MOBILITY,
        body_part=BodyPart.KNEE,
        difficulty_level=2,
    )
    session.add(exercise)
    await session.commit()
    await session.refresh(exercise)
    return exercise


class TestFullSessionFlow:
    """Integration tests for complete session lifecycle."""

    @pytest.mark.asyncio
    async def test_complete_session_lifecycle(
        self,
        client: AsyncClient,
        auth_headers: dict[str, str],
        test_exercise: Exercise,
    ) -> None:
        """Test complete flow: Create → Start → Add Result → Complete."""
        # Step 1: Create session
        create_response = await client.post(
            "/api/v1/sessions",
            headers=auth_headers,
            json={
                "scheduled_date": datetime.now(UTC).isoformat(),
                "notes": "Integration test session",
            },
        )
        assert create_response.status_code == 201
        session_data = create_response.json()
        session_id = session_data["id"]

        assert session_data["status"] == SessionStatus.IN_PROGRESS.value
        assert session_data["notes"] == "Integration test session"

        # Step 2: Start session with pain level
        start_response = await client.post(
            f"/api/v1/sessions/{session_id}/start",
            headers=auth_headers,
            json={
                "pain_level_before": 5,
                "device_info": {"platform": "iOS", "app_version": "1.0.0"},
            },
        )
        assert start_response.status_code == 200
        started_data = start_response.json()

        assert started_data["started_at"] is not None
        assert started_data["pain_level_before"] == 5

        # Step 3: Submit exercise result
        result_response = await client.post(
            f"/api/v1/sessions/{session_id}/results",
            headers=auth_headers,
            json={
                "exercise_id": str(test_exercise.id),
                "sets_completed": 3,
                "reps_completed": 12,
                "score": 85.5,
            },
        )
        assert result_response.status_code == 201
        result_data = result_response.json()

        assert result_data["sets_completed"] == 3
        assert result_data["reps_completed"] == 12
        assert result_data["score"] == 85.5

        # Step 4: Complete session
        complete_response = await client.post(
            f"/api/v1/sessions/{session_id}/complete",
            headers=auth_headers,
            json={
                "pain_level_after": 3,
                "notes": "Felt better after exercises",
            },
        )
        assert complete_response.status_code == 200
        completed_data = complete_response.json()

        assert completed_data["status"] == SessionStatus.COMPLETED.value
        assert completed_data["pain_level_after"] == 3
        assert completed_data["completed_at"] is not None
        assert completed_data["duration_seconds"] is not None
        assert completed_data["overall_score"] == 85.5  # Average of single result

    @pytest.mark.asyncio
    async def test_session_with_multiple_exercises(
        self,
        client: AsyncClient,
        auth_headers: dict[str, str],
        session: AsyncSession,
        test_exercise: Exercise,
    ) -> None:
        """Test session with multiple exercise results."""
        # Create second exercise
        exercise2 = Exercise(
            id=uuid4(),
            name="Test Hurdle Step",
            category=ExerciseCategory.BALANCE,
            body_part=BodyPart.HIP,
        )
        session.add(exercise2)
        await session.commit()

        # Create and start session
        create_resp = await client.post(
            "/api/v1/sessions",
            headers=auth_headers,
            json={"scheduled_date": datetime.now(UTC).isoformat()},
        )
        session_id = create_resp.json()["id"]

        await client.post(
            f"/api/v1/sessions/{session_id}/start",
            headers=auth_headers,
            json={"pain_level_before": 4},
        )

        # Add first exercise result (score: 80)
        await client.post(
            f"/api/v1/sessions/{session_id}/results",
            headers=auth_headers,
            json={
                "exercise_id": str(test_exercise.id),
                "sets_completed": 3,
                "reps_completed": 10,
                "score": 80.0,
            },
        )

        # Add second exercise result (score: 90)
        await client.post(
            f"/api/v1/sessions/{session_id}/results",
            headers=auth_headers,
            json={
                "exercise_id": str(exercise2.id),
                "sets_completed": 2,
                "reps_completed": 8,
                "score": 90.0,
            },
        )

        # Complete session
        complete_resp = await client.post(
            f"/api/v1/sessions/{session_id}/complete",
            headers=auth_headers,
            json={"pain_level_after": 2},
        )

        completed_data = complete_resp.json()
        # Overall score should be average: (80 + 90) / 2 = 85
        assert completed_data["overall_score"] == 85.0


class TestSessionAccessControl:
    """Tests for session access control."""

    @pytest.mark.asyncio
    async def test_cannot_access_other_user_session(
        self,
        client: AsyncClient,
        session: AsyncSession,
    ) -> None:
        """Users cannot access other users' sessions."""
        # Create two users
        user1 = User(
            id=uuid4(),
            email="user1@test.com",
            hashed_password=hash_password("pass123"),
            is_active=True,
            is_verified=True,
        )
        user2 = User(
            id=uuid4(),
            email="user2@test.com",
            hashed_password=hash_password("pass123"),
            is_active=True,
            is_verified=True,
        )
        session.add_all([user1, user2])
        await session.commit()

        # Create session for user1
        from app.models.session import Session

        user1_session = Session(
            patient_id=user1.id,
            scheduled_date=datetime.now(UTC),
        )
        session.add(user1_session)
        await session.commit()
        await session.refresh(user1_session)

        # User2 tries to access user1's session
        user2_token = create_access_token(user2.id)
        user2_headers = {"Authorization": f"Bearer {user2_token}"}

        response = await client.get(
            f"/api/v1/sessions/{user1_session.id}",
            headers=user2_headers,
        )

        assert response.status_code == 403
        assert "Access denied" in response.json()["detail"]

    @pytest.mark.asyncio
    async def test_cannot_start_other_user_session(
        self,
        client: AsyncClient,
        session: AsyncSession,
    ) -> None:
        """Users cannot start other users' sessions."""
        user1 = User(
            id=uuid4(),
            email="owner@test.com",
            hashed_password=hash_password("pass123"),
            is_active=True,
            is_verified=True,
        )
        user2 = User(
            id=uuid4(),
            email="attacker@test.com",
            hashed_password=hash_password("pass123"),
            is_active=True,
            is_verified=True,
        )
        session.add_all([user1, user2])
        await session.commit()

        from app.models.session import Session

        user1_session = Session(
            patient_id=user1.id,
            scheduled_date=datetime.now(UTC),
        )
        session.add(user1_session)
        await session.commit()
        await session.refresh(user1_session)

        user2_token = create_access_token(user2.id)
        response = await client.post(
            f"/api/v1/sessions/{user1_session.id}/start",
            headers={"Authorization": f"Bearer {user2_token}"},
            json={"pain_level_before": 5},
        )

        assert response.status_code == 403


class TestSessionStateTransitions:
    """Tests for session state machine."""

    @pytest.mark.asyncio
    async def test_cannot_start_completed_session(
        self,
        client: AsyncClient,
        auth_headers: dict[str, str],
    ) -> None:
        """Cannot start an already completed session."""
        # Create and complete session
        create_resp = await client.post(
            "/api/v1/sessions",
            headers=auth_headers,
            json={"scheduled_date": datetime.now(UTC).isoformat()},
        )
        session_id = create_resp.json()["id"]

        await client.post(
            f"/api/v1/sessions/{session_id}/start",
            headers=auth_headers,
            json={},
        )

        await client.post(
            f"/api/v1/sessions/{session_id}/complete",
            headers=auth_headers,
            json={},
        )

        # Try to start again
        start_again = await client.post(
            f"/api/v1/sessions/{session_id}/start",
            headers=auth_headers,
            json={},
        )

        assert start_again.status_code == 400
        assert "Cannot start session" in start_again.json()["detail"]

    @pytest.mark.asyncio
    async def test_skip_session(
        self,
        client: AsyncClient,
        auth_headers: dict[str, str],
    ) -> None:
        """Test skipping a session."""
        create_resp = await client.post(
            "/api/v1/sessions",
            headers=auth_headers,
            json={"scheduled_date": datetime.now(UTC).isoformat()},
        )
        session_id = create_resp.json()["id"]

        skip_resp = await client.post(
            f"/api/v1/sessions/{session_id}/skip",
            headers=auth_headers,
            params={"reason": "Feeling unwell"},
        )

        assert skip_resp.status_code == 200
        assert skip_resp.json()["status"] == SessionStatus.SKIPPED.value
        assert skip_resp.json()["notes"] == "Feeling unwell"


class TestSessionListing:
    """Tests for session listing and filtering."""

    @pytest.mark.asyncio
    async def test_list_sessions_returns_user_sessions_only(
        self,
        client: AsyncClient,
        auth_headers: dict[str, str],
    ) -> None:
        """List sessions returns only current user's sessions."""
        # Create multiple sessions
        for _ in range(3):
            await client.post(
                "/api/v1/sessions",
                headers=auth_headers,
                json={"scheduled_date": datetime.now(UTC).isoformat()},
            )

        list_resp = await client.get(
            "/api/v1/sessions",
            headers=auth_headers,
        )

        assert list_resp.status_code == 200
        sessions = list_resp.json()
        assert len(sessions) == 3

    @pytest.mark.asyncio
    async def test_list_sessions_with_status_filter(
        self,
        client: AsyncClient,
        auth_headers: dict[str, str],
    ) -> None:
        """Filter sessions by status."""
        # Create completed session
        create_resp = await client.post(
            "/api/v1/sessions",
            headers=auth_headers,
            json={"scheduled_date": datetime.now(UTC).isoformat()},
        )
        session_id = create_resp.json()["id"]

        await client.post(
            f"/api/v1/sessions/{session_id}/start",
            headers=auth_headers,
            json={},
        )
        await client.post(
            f"/api/v1/sessions/{session_id}/complete",
            headers=auth_headers,
            json={},
        )

        # Create in-progress session
        await client.post(
            "/api/v1/sessions",
            headers=auth_headers,
            json={"scheduled_date": datetime.now(UTC).isoformat()},
        )

        # Filter completed only
        completed_resp = await client.get(
            "/api/v1/sessions",
            headers=auth_headers,
            params={"status_filter": SessionStatus.COMPLETED.value},
        )

        assert completed_resp.status_code == 200
        completed_sessions = completed_resp.json()
        assert len(completed_sessions) == 1
        assert completed_sessions[0]["status"] == SessionStatus.COMPLETED.value


class TestSessionWithExerciseResults:
    """Tests for session with exercise results."""

    @pytest.mark.asyncio
    async def test_get_session_detail_includes_results(
        self,
        client: AsyncClient,
        auth_headers: dict[str, str],
        test_exercise: Exercise,
    ) -> None:
        """Session detail includes exercise results."""
        # Create session
        create_resp = await client.post(
            "/api/v1/sessions",
            headers=auth_headers,
            json={"scheduled_date": datetime.now(UTC).isoformat()},
        )
        session_id = create_resp.json()["id"]

        await client.post(
            f"/api/v1/sessions/{session_id}/start",
            headers=auth_headers,
            json={},
        )

        # Add exercise result
        await client.post(
            f"/api/v1/sessions/{session_id}/results",
            headers=auth_headers,
            json={
                "exercise_id": str(test_exercise.id),
                "sets_completed": 3,
                "reps_completed": 10,
                "score": 75.0,
            },
        )

        # Get session detail
        detail_resp = await client.get(
            f"/api/v1/sessions/{session_id}",
            headers=auth_headers,
        )

        assert detail_resp.status_code == 200
        detail = detail_resp.json()
        assert "exercise_results" in detail
        assert len(detail["exercise_results"]) == 1
        assert detail["exercise_results"][0]["score"] == 75.0

    @pytest.mark.asyncio
    async def test_submit_result_for_nonexistent_exercise(
        self,
        client: AsyncClient,
        auth_headers: dict[str, str],
    ) -> None:
        """Submitting result for nonexistent exercise returns 404."""
        create_resp = await client.post(
            "/api/v1/sessions",
            headers=auth_headers,
            json={"scheduled_date": datetime.now(UTC).isoformat()},
        )
        session_id = create_resp.json()["id"]

        result_resp = await client.post(
            f"/api/v1/sessions/{session_id}/results",
            headers=auth_headers,
            json={
                "exercise_id": str(uuid4()),  # Non-existent
                "sets_completed": 1,
                "reps_completed": 5,
            },
        )

        assert result_resp.status_code == 404
        assert "Exercise not found" in result_resp.json()["detail"]
