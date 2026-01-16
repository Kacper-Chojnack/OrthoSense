"""
Pytest configuration for E2E API tests.

E2E tests run against a test database and test the complete
API workflows without mocking internal components.
"""

import os
from collections.abc import AsyncGenerator
from uuid import uuid4

# Set environment variables BEFORE importing app modules
os.environ["SECRET_KEY"] = "e2e_test_secret_key_for_pytest_only_12345"
os.environ["DATABASE_URL"] = "sqlite+aiosqlite:///:memory:"
os.environ["RATE_LIMIT_ENABLED"] = "false"  # Disable rate limiting in E2E tests

import pytest
import pytest_asyncio
from httpx import ASGITransport, AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker, create_async_engine
from sqlmodel import SQLModel

from app.core.database import get_session
from app.core.security import create_access_token, hash_password
from app.main import app
from app.models.user import User, UserRole

# E2E Database URL - can be overridden for integration testing with real DB
E2E_DATABASE_URL = os.environ.get(
    "E2E_DATABASE_URL",
    "sqlite+aiosqlite:///:memory:",
)

IS_POSTGRES = "postgresql" in E2E_DATABASE_URL


@pytest_asyncio.fixture(scope="function")
async def e2e_engine():
    """Create database engine for E2E tests."""
    if IS_POSTGRES:
        engine = create_async_engine(
            E2E_DATABASE_URL,
            echo=False,
            pool_pre_ping=True,
        )
    else:
        engine = create_async_engine(
            E2E_DATABASE_URL,
            echo=False,
            connect_args={"check_same_thread": False},
        )

    async with engine.begin() as conn:
        await conn.run_sync(SQLModel.metadata.create_all)

    yield engine

    if not IS_POSTGRES:
        async with engine.begin() as conn:
            await conn.run_sync(SQLModel.metadata.drop_all)

    await engine.dispose()


@pytest_asyncio.fixture
async def session(e2e_engine) -> AsyncGenerator[AsyncSession]:
    """
    Provide a transactional database session for E2E tests.

    Each test runs in its own transaction for isolation.
    """
    E2ESessionLocal = async_sessionmaker(
        e2e_engine,
        class_=AsyncSession,
        expire_on_commit=False,
    )
    async with E2ESessionLocal() as db_session:
        yield db_session
        await db_session.rollback()


@pytest_asyncio.fixture
async def client(session: AsyncSession) -> AsyncGenerator[AsyncClient]:
    """
    Provide an async HTTP client configured for E2E testing.

    Overrides the database session dependency to use the test session.
    """

    async def override_get_session() -> AsyncGenerator[AsyncSession]:
        yield session

    app.dependency_overrides[get_session] = override_get_session

    async with AsyncClient(
        transport=ASGITransport(app=app),
        base_url="http://test",
    ) as test_client:
        yield test_client

    app.dependency_overrides.clear()


@pytest_asyncio.fixture
async def test_user(session: AsyncSession) -> User:
    """Create a standard test user."""
    user = User(
        id=uuid4(),
        email="e2e_test@example.com",
        hashed_password=hash_password("TestPass123!"),
        role=UserRole.PATIENT,
        is_active=True,
        is_verified=True,
    )
    session.add(user)
    await session.commit()
    await session.refresh(user)
    return user


@pytest_asyncio.fixture
async def admin_user(session: AsyncSession) -> User:
    """Create an admin test user."""
    user = User(
        id=uuid4(),
        email="e2e_admin@example.com",
        hashed_password=hash_password("AdminPass123!"),
        role=UserRole.ADMIN,
        is_active=True,
        is_verified=True,
    )
    session.add(user)
    await session.commit()
    await session.refresh(user)
    return user


@pytest_asyncio.fixture
async def authenticated_user(
    session: AsyncSession,
    test_user: User,
) -> dict:
    """
    Provide an authenticated user with valid token and headers.

    Returns:
        Dictionary with 'user', 'token', and 'headers' keys.
    """
    token = create_access_token(test_user.id)
    return {
        "user": test_user,
        "token": token,
        "headers": {"Authorization": f"Bearer {token}"},
    }


@pytest_asyncio.fixture
async def authenticated_admin(
    session: AsyncSession,
    admin_user: User,
) -> dict:
    """
    Provide an authenticated admin user with valid token and headers.

    Returns:
        Dictionary with 'user', 'token', and 'headers' keys.
    """
    token = create_access_token(admin_user.id)
    return {
        "user": admin_user,
        "token": token,
        "headers": {"Authorization": f"Bearer {token}"},
    }


@pytest.fixture
def auth_headers(test_user: User) -> dict[str, str]:
    """Generate authorization headers for test user."""
    token = create_access_token(test_user.id)
    return {"Authorization": f"Bearer {token}"}


# ============================================================================
# Test Data Factories
# ============================================================================


class E2ETestDataFactory:
    """Factory for creating test data in E2E tests."""

    @staticmethod
    def create_user_data(
        email: str = None,
        password: str = "SecurePass123!",
    ) -> dict:
        """Create user registration data."""
        if email is None:
            email = f"e2e_{uuid4().hex[:8]}@test.com"
        return {
            "email": email,
            "password": password,
        }

    @staticmethod
    def create_session_data(
        notes: str = "E2E test session",
    ) -> dict:
        """Create exercise session data."""
        from datetime import UTC, datetime

        return {
            "scheduled_date": datetime.now(UTC).isoformat(),
            "notes": notes,
        }

    @staticmethod
    def create_exercise_result_data(
        exercise_id: str,
        sets: int = 3,
        reps: int = 10,
        score: float = 85.0,
    ) -> dict:
        """Create exercise result data."""
        return {
            "exercise_id": exercise_id,
            "sets_completed": sets,
            "reps_completed": reps,
            "score": score,
        }

    @staticmethod
    def create_landmarks_data(
        num_frames: int = 30,
        quality: int = 90,
    ) -> list:
        """Create fake pose landmarks data."""
        import random

        landmarks_data = []
        noise_factor = (100 - quality) / 100

        for _ in range(num_frames):
            frame = []
            for i in range(33):
                noise = random.uniform(0, noise_factor * 0.1)
                frame.append([
                    0.5 + (0.02 * (i % 10)) - noise,  # x
                    0.2 + (0.025 * i) - noise,         # y
                    random.uniform(-0.1, 0.1),         # z
                    quality / 100,                     # visibility
                ])
            landmarks_data.append(frame)

        return landmarks_data


@pytest.fixture
def e2e_factory() -> E2ETestDataFactory:
    """Provide test data factory."""
    return E2ETestDataFactory()
