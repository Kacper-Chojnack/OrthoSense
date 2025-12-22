"""Pytest fixtures for async testing with authentication support."""

import os
from collections.abc import AsyncGenerator
from uuid import uuid4

# Set environment variables BEFORE importing app modules
os.environ["SECRET_KEY"] = "test_secret_key_for_pytest_only_12345"
os.environ["DATABASE_URL"] = "sqlite+aiosqlite:///:memory:"

import pytest
from httpx import ASGITransport, AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession, create_async_engine
from sqlalchemy.orm import sessionmaker
from sqlmodel import SQLModel

from app.core.database import get_session
from app.core.security import create_access_token, hash_password
from app.main import app
from app.models.user import User


@pytest.fixture
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


@pytest.fixture
async def session(async_engine) -> AsyncGenerator[AsyncSession]:
    """Provide test database session."""
    async_session_factory = sessionmaker(
        async_engine,
        class_=AsyncSession,
        expire_on_commit=False,
    )
    async with async_session_factory() as session:
        yield session


@pytest.fixture
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


@pytest.fixture
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


@pytest.fixture
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


@pytest.fixture
def auth_headers(test_user: User) -> dict[str, str]:
    """Generate authorization headers for test user."""
    token = create_access_token(test_user.id)
    return {"Authorization": f"Bearer {token}"}
