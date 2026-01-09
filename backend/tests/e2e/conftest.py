"""
Pytest configuration for E2E tests.

E2E tests run against a test database and test the complete
API workflows without mocking.

Note: These tests require PostgreSQL. They are skipped if PG is unavailable.
"""

import os
from collections.abc import AsyncGenerator
from datetime import UTC, datetime

import pytest_asyncio
from httpx import ASGITransport, AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker, create_async_engine
from sqlmodel import SQLModel

from app.core.database import get_session
from app.main import app

# Test database URL - falls back to SQLite for CI
E2E_DATABASE_URL = os.environ.get(
    "E2E_DATABASE_URL",
    "sqlite+aiosqlite:///:memory:",
)

# Determine if using PostgreSQL
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

    Each test runs in its own transaction that is rolled back,
    ensuring test isolation.
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
def test_timestamp() -> datetime:
    """Provide a consistent timestamp for tests."""
    return datetime.now(UTC)
