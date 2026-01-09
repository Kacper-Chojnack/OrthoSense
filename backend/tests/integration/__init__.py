"""
PostgreSQL Integration Test Configuration.

These tests require a running PostgreSQL database.
Set DATABASE_URL environment variable or use Docker:
    docker run -d -p 5432:5432 -e POSTGRES_PASSWORD=test postgres:16

Run tests with: pytest tests/integration/ -v
"""

import os
from collections.abc import AsyncGenerator

import pytest
import pytest_asyncio
from sqlalchemy.ext.asyncio import AsyncSession, create_async_engine
from sqlalchemy.orm import sessionmaker
from sqlmodel import SQLModel

# Use test database - either from env or default local PostgreSQL
TEST_DATABASE_URL = os.environ.get(
    "TEST_DATABASE_URL",
    "postgresql+asyncpg://postgres:test@localhost:5432/orthosense_test",
)


@pytest.fixture(scope="session")
def anyio_backend():
    """Use asyncio backend for anyio."""
    return "asyncio"


@pytest_asyncio.fixture(scope="module")
async def pg_engine():
    """Create PostgreSQL engine for integration tests."""
    # Skip if no PostgreSQL available
    try:
        engine = create_async_engine(
            TEST_DATABASE_URL,
            echo=False,
            pool_pre_ping=True,
        )
        # Test connection
        async with engine.begin() as conn:
            await conn.run_sync(SQLModel.metadata.create_all)
        yield engine
        # Cleanup - drop all tables after tests
        async with engine.begin() as conn:
            await conn.run_sync(SQLModel.metadata.drop_all)
        await engine.dispose()
    except Exception as e:
        pytest.skip(f"PostgreSQL not available: {e}")


@pytest_asyncio.fixture
async def pg_session(pg_engine) -> AsyncGenerator[AsyncSession]:
    """Provide PostgreSQL test session with transaction rollback."""
    async_session_factory = sessionmaker(
        pg_engine,
        class_=AsyncSession,
        expire_on_commit=False,
    )
    async with async_session_factory() as session, session.begin():
        # Transaction for test isolation
        yield session
        # Rollback after test
        await session.rollback()


@pytest_asyncio.fixture
async def pg_session_committed(pg_engine) -> AsyncGenerator[AsyncSession]:
    """Provide PostgreSQL session that commits (for testing real persistence)."""
    async_session_factory = sessionmaker(
        pg_engine,
        class_=AsyncSession,
        expire_on_commit=False,
    )
    async with async_session_factory() as session:
        yield session
        # Cleanup is handled by dropping tables at module end
