import asyncio
import os
from collections.abc import AsyncGenerator
from uuid import uuid4

import pytest
import pytest_asyncio
from httpx import ASGITransport, AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession, create_async_engine
from sqlalchemy.orm import sessionmaker
from sqlmodel import SQLModel

# Set environment variables BEFORE importing app modules
os.environ["SECRET_KEY"] = "test_secret_key_for_pytest_only_12345"
os.environ["DATABASE_URL"] = "sqlite+aiosqlite:///:memory:"
os.environ["RATE_LIMIT_ENABLED"] = "false"  # Disable rate limiting in tests

from app.core.database import get_session
from app.core.security import create_access_token, hash_password
from app.main import app
from app.models.user import User

"""Pytest fixtures for async testing with authentication support."""


# Ensure clean event loop shutdown after all tests
@pytest.fixture(scope="session", autouse=True)
def event_loop_policy():
    policy = asyncio.get_event_loop_policy()
    yield policy
    try:
        loop = asyncio.get_event_loop()
        if loop.is_running():
            loop.stop()
        if not loop.is_closed():
            loop.close()
    except Exception:
        pass


@pytest_asyncio.fixture
async def async_engine():
    """Create in-memory SQLite engine for tests."""
    engine = create_async_engine(
        "sqlite+aiosqlite:///:memory:",
        echo=False,
        connect_args={"check_same_thread": False},
    )
    import os

    """Pytest fixtures for async testing with authentication support."""

    # Set environment variables BEFORE importing app modules
    os.environ["SECRET_KEY"] = "test_secret_key_for_pytest_only_12345"
    os.environ["DATABASE_URL"] = "sqlite+aiosqlite:///:memory:"
    os.environ["RATE_LIMIT_ENABLED"] = "false"  # Disable rate limiting in tests

    async with engine.begin() as conn:
        await conn.run_sync(SQLModel.metadata.create_all)
    yield engine
    await engine.dispose()


@pytest_asyncio.fixture
async def session(async_engine) -> AsyncGenerator[AsyncSession]:
    """Provide test database session."""
    async_session_factory = sessionmaker(
        async_engine,
        class_=AsyncSession,
        expire_on_commit=False,
    )
    async with async_session_factory() as session:
        try:
            yield session
        finally:
            await session.close()
            # Note: Do NOT dispose engine here - async_engine fixture handles cleanup


@pytest_asyncio.fixture
async def client(session: AsyncSession) -> AsyncGenerator[AsyncClient]:
    """Provide test HTTP client with overridden dependencies."""

    async def override_get_session() -> AsyncGenerator[AsyncSession]:
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
    """Create a test user in the database."""
    user = User(
        id=uuid4(),
        email="test@example.com",
        hashed_password=hash_password("testpassword123"),
        is_active=True,
        is_verified=True,
    )
    session.add(user)
    await session.commit()
    await session.refresh(user)
    return user


@pytest_asyncio.fixture
async def unverified_user(session: AsyncSession) -> User:
    """Create an unverified test user."""
    user = User(
        id=uuid4(),
        email="unverified@example.com",
        hashed_password=hash_password("testpassword123"),
        is_active=True,
        is_verified=False,
    )
    session.add(user)
    await session.commit()
    await session.refresh(user)
    return user


@pytest_asyncio.fixture
async def auth_headers(test_user: User) -> dict[str, str]:
    """Generate authorization headers for test user."""
    # Access user.id in async context to avoid MissingGreenlet error
    user_id = test_user.id
    token = create_access_token(user_id)
    return {"Authorization": f"Bearer {token}"}
