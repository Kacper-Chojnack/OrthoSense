"""Integration tests for Auth + Sessions + Exercises flow.

Tests comprehensive user journey:
1. Registration → Email Verification → Login
2. Create Session → Add Exercises → Start → Complete
3. View Results → Analytics
4. Cross-feature data integrity
"""

import os
from datetime import UTC, datetime
from uuid import uuid4

# Set environment variables BEFORE importing app modules
os.environ["SECRET_KEY"] = "test_secret_key_for_auth_session_exercise_flow"
os.environ["DATABASE_URL"] = "sqlite+aiosqlite:///:memory:"
os.environ["RATE_LIMIT_ENABLED"] = "false"

import pytest
import pytest_asyncio
from httpx import ASGITransport, AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession, create_async_engine
from sqlalchemy.orm import sessionmaker
from sqlmodel import SQLModel

from app.core.database import get_session
from app.core.security import (
    create_access_token,
    create_verification_token,
    hash_password,
)
from app.main import app
from app.models.exercise import BodyPart, Exercise, ExerciseCategory
from app.models.session import SessionStatus
from app.models.user import User, UserRole


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
async def admin_user(session: AsyncSession) -> User:
    """Create admin user for exercise management."""
    user = User(
        id=uuid4(),
        email="admin@orthosense.com",
        hashed_password=hash_password("adminpassword123"),
        is_active=True,
        is_verified=True,
        role=UserRole.ADMIN,
    )
    session.add(user)
    await session.commit()
    await session.refresh(user)
    return user


@pytest.fixture
def admin_headers(admin_user: User) -> dict[str, str]:
    """Generate auth headers for admin user."""
    token = create_access_token(admin_user.id)
    return {"Authorization": f"Bearer {token}"}


@pytest_asyncio.fixture
async def sample_exercises(session: AsyncSession) -> list[Exercise]:
    """Create sample exercises for testing."""
    exercises = [
        Exercise(
            id=uuid4(),
            name="Deep Squat",
            description="Full depth squat for mobility assessment",
            category=ExerciseCategory.MOBILITY,
            body_part=BodyPart.KNEE,
            difficulty_level=2,
        ),
        Exercise(
            id=uuid4(),
            name="Standing Shoulder Abduction",
            description="Arm raise for shoulder mobility",
            category=ExerciseCategory.STRETCHING,
            body_part=BodyPart.SHOULDER,
            difficulty_level=1,
        ),
        Exercise(
            id=uuid4(),
            name="Single Leg Stand",
            description="Balance exercise",
            category=ExerciseCategory.BALANCE,
            body_part=BodyPart.ANKLE,
            difficulty_level=3,
        ),
    ]
    for ex in exercises:
        session.add(ex)
    await session.commit()
    for ex in exercises:
        await session.refresh(ex)
    return exercises


class TestFullAuthFlow:
    """Tests for complete authentication flow."""

    @pytest.mark.asyncio
    async def test_registration_creates_user(self, client: AsyncClient) -> None:
        """User registration creates account."""
        response = await client.post(
            "/api/v1/auth/register",
            json={
                "email": "newuser@example.com",
                "password": "SecurePassword123!",
            },
        )

        assert response.status_code == 201
        data = response.json()
        assert data["email"] == "newuser@example.com"
        assert data["is_verified"] is False
        assert "id" in data

    @pytest.mark.asyncio
    async def test_login_after_verification(
        self,
        client: AsyncClient,
        session: AsyncSession,
    ) -> None:
        """User can login after email verification."""
        # Step 1: Register
        register_response = await client.post(
            "/api/v1/auth/register",
            json={
                "email": "verified@example.com",
                "password": "SecurePassword123!",
            },
        )
        assert register_response.status_code == 201
        user_id = register_response.json()["id"]

        # Step 2: Verify email (simulate token verification)
        verification_token = create_verification_token(user_id)
        verify_response = await client.post(
            "/api/v1/auth/verify-email",
            json={"token": verification_token},
        )
        assert verify_response.status_code == 200
        assert verify_response.json()["is_verified"] is True

        # Step 3: Login
        login_response = await client.post(
            "/api/v1/auth/login",
            data={
                "username": "verified@example.com",
                "password": "SecurePassword123!",
            },
        )
        assert login_response.status_code == 200
        assert "access_token" in login_response.json()

    @pytest.mark.asyncio
    async def test_get_current_user_with_token(
        self,
        client: AsyncClient,
        session: AsyncSession,
    ) -> None:
        """Authenticated user can get their profile."""
        # Create verified user directly
        user = User(
            id=uuid4(),
            email="profile@example.com",
            hashed_password=hash_password("password123"),
            is_active=True,
            is_verified=True,
        )
        session.add(user)
        await session.commit()
        await session.refresh(user)

        token = create_access_token(user.id)

        response = await client.get(
            "/api/v1/auth/me",
            headers={"Authorization": f"Bearer {token}"},
        )

        assert response.status_code == 200
        assert response.json()["email"] == "profile@example.com"


class TestAuthToSessionFlow:
    """Tests for auth to session creation flow."""

    @pytest.mark.asyncio
    async def test_authenticated_user_creates_session(
        self,
        client: AsyncClient,
        session: AsyncSession,
        sample_exercises: list[Exercise],
    ) -> None:
        """Authenticated user can create exercise session."""
        # Create user
        user = User(
            id=uuid4(),
            email="session_user@example.com",
            hashed_password=hash_password("password123"),
            is_active=True,
            is_verified=True,
        )
        session.add(user)
        await session.commit()
        await session.refresh(user)

        token = create_access_token(user.id)
        headers = {"Authorization": f"Bearer {token}"}

        # Create session
        response = await client.post(
            "/api/v1/sessions",
            headers=headers,
            json={
                "scheduled_date": datetime.now(UTC).isoformat(),
                "notes": "Integration test session",
            },
        )

        assert response.status_code == 201
        data = response.json()
        assert data["status"] == SessionStatus.IN_PROGRESS.value
        assert data["notes"] == "Integration test session"

    @pytest.mark.asyncio
    async def test_unauthenticated_cannot_create_session(
        self, client: AsyncClient
    ) -> None:
        """Unauthenticated request cannot create session."""
        response = await client.post(
            "/api/v1/sessions",
            json={
                "scheduled_date": datetime.now(UTC).isoformat(),
            },
        )

        assert response.status_code == 401


class TestSessionToExerciseFlow:
    """Tests for session with exercises flow."""

    @pytest.mark.asyncio
    async def test_full_session_with_exercises(
        self,
        client: AsyncClient,
        session: AsyncSession,
        sample_exercises: list[Exercise],
    ) -> None:
        """Complete session flow with exercise results."""
        # Create user
        user = User(
            id=uuid4(),
            email="full_flow@example.com",
            hashed_password=hash_password("password123"),
            is_active=True,
            is_verified=True,
        )
        session.add(user)
        await session.commit()
        await session.refresh(user)

        token = create_access_token(user.id)
        headers = {"Authorization": f"Bearer {token}"}

        # Step 1: Create session
        create_response = await client.post(
            "/api/v1/sessions",
            headers=headers,
            json={"scheduled_date": datetime.now(UTC).isoformat()},
        )
        assert create_response.status_code == 201
        session_id = create_response.json()["id"]

        # Step 2: Start session
        start_response = await client.post(
            f"/api/v1/sessions/{session_id}/start",
            headers=headers,
            json={
                "pain_level_before": 3,
                "device_info": {"platform": "iOS", "version": "1.0.0"},
            },
        )
        assert start_response.status_code == 200

        # Step 3: Add exercise results
        for exercise in sample_exercises[:2]:
            result_response = await client.post(
                f"/api/v1/sessions/{session_id}/results",
                headers=headers,
                json={
                    "exercise_id": str(exercise.id),
                    "repetitions_completed": 10,
                    "quality_score": 0.85,
                    "feedback": {"posture": "good", "depth": "adequate"},
                },
            )
            assert result_response.status_code == 201

        # Step 4: Complete session
        complete_response = await client.post(
            f"/api/v1/sessions/{session_id}/complete",
            headers=headers,
            json={
                "pain_level_after": 2,
                "notes": "Good session",
            },
        )
        assert complete_response.status_code == 200
        assert complete_response.json()["status"] == SessionStatus.COMPLETED.value

        # Step 5: Get session with results
        detail_response = await client.get(
            f"/api/v1/sessions/{session_id}",
            headers=headers,
        )
        assert detail_response.status_code == 200
        detail_data = detail_response.json()
        assert len(detail_data["exercise_results"]) == 2


class TestExerciseManagement:
    """Tests for exercise management (admin)."""

    @pytest.mark.asyncio
    async def test_admin_creates_exercise(
        self,
        client: AsyncClient,
        admin_headers: dict[str, str],
    ) -> None:
        """Admin can create new exercise."""
        response = await client.post(
            "/api/v1/exercises",
            headers=admin_headers,
            json={
                "name": "New Test Exercise",
                "description": "Test description",
                "category": ExerciseCategory.STRENGTH.value,
                "body_part": BodyPart.HIP.value,
                "difficulty_level": 2,
            },
        )

        assert response.status_code == 201
        data = response.json()
        assert data["name"] == "New Test Exercise"
        assert data["is_active"] is True

    @pytest.mark.asyncio
    async def test_user_lists_exercises(
        self,
        client: AsyncClient,
        session: AsyncSession,
        sample_exercises: list[Exercise],
    ) -> None:
        """Regular user can list exercises."""
        user = User(
            id=uuid4(),
            email="list_exercises@example.com",
            hashed_password=hash_password("password123"),
            is_active=True,
            is_verified=True,
        )
        session.add(user)
        await session.commit()
        await session.refresh(user)

        token = create_access_token(user.id)

        response = await client.get(
            "/api/v1/exercises",
            headers={"Authorization": f"Bearer {token}"},
        )

        assert response.status_code == 200
        data = response.json()
        assert len(data) >= 3

    @pytest.mark.asyncio
    async def test_filter_exercises_by_body_part(
        self,
        client: AsyncClient,
        session: AsyncSession,
        sample_exercises: list[Exercise],
    ) -> None:
        """Exercises can be filtered by body part."""
        user = User(
            id=uuid4(),
            email="filter_test@example.com",
            hashed_password=hash_password("password123"),
            is_active=True,
            is_verified=True,
        )
        session.add(user)
        await session.commit()
        await session.refresh(user)

        token = create_access_token(user.id)

        response = await client.get(
            "/api/v1/exercises",
            headers={"Authorization": f"Bearer {token}"},
            params={"body_part": BodyPart.KNEE.value},
        )

        assert response.status_code == 200
        data = response.json()
        assert all(ex["body_part"] == BodyPart.KNEE.value for ex in data)


class TestCrossFeatureDataIntegrity:
    """Tests for data integrity across features."""

    @pytest.mark.asyncio
    async def test_session_belongs_to_correct_user(
        self,
        client: AsyncClient,
        session: AsyncSession,
    ) -> None:
        """Session is only accessible by its owner."""
        # Create two users
        user1 = User(
            id=uuid4(),
            email="user1@example.com",
            hashed_password=hash_password("password123"),
            is_active=True,
            is_verified=True,
        )
        user2 = User(
            id=uuid4(),
            email="user2@example.com",
            hashed_password=hash_password("password123"),
            is_active=True,
            is_verified=True,
        )
        session.add_all([user1, user2])
        await session.commit()
        await session.refresh(user1)
        await session.refresh(user2)

        token1 = create_access_token(user1.id)
        token2 = create_access_token(user2.id)

        # User1 creates session
        create_response = await client.post(
            "/api/v1/sessions",
            headers={"Authorization": f"Bearer {token1}"},
            json={"scheduled_date": datetime.now(UTC).isoformat()},
        )
        session_id = create_response.json()["id"]

        # User2 cannot access User1's session
        access_response = await client.get(
            f"/api/v1/sessions/{session_id}",
            headers={"Authorization": f"Bearer {token2}"},
        )
        assert access_response.status_code == 403

    @pytest.mark.asyncio
    async def test_exercise_result_references_valid_exercise(
        self,
        client: AsyncClient,
        session: AsyncSession,
        sample_exercises: list[Exercise],
    ) -> None:
        """Exercise result must reference existing exercise."""
        user = User(
            id=uuid4(),
            email="result_test@example.com",
            hashed_password=hash_password("password123"),
            is_active=True,
            is_verified=True,
        )
        session.add(user)
        await session.commit()
        await session.refresh(user)

        token = create_access_token(user.id)
        headers = {"Authorization": f"Bearer {token}"}

        # Create session
        create_response = await client.post(
            "/api/v1/sessions",
            headers=headers,
            json={"scheduled_date": datetime.now(UTC).isoformat()},
        )
        session_id = create_response.json()["id"]

        # Try to add result with non-existent exercise
        response = await client.post(
            f"/api/v1/sessions/{session_id}/results",
            headers=headers,
            json={
                "exercise_id": str(uuid4()),  # Non-existent exercise
                "repetitions_completed": 10,
                "quality_score": 0.85,
            },
        )

        # Should fail with 404 or 400
        assert response.status_code in [400, 404]
