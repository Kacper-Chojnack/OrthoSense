"""
PostgreSQL Integration Test Configuration.

These tests require a running PostgreSQL database.
Set TEST_DATABASE_URL environment variable or use Docker:
    docker run -d -p 5432:5432 -e POSTGRES_PASSWORD=test postgres:16

Run tests with: pytest tests/integration/ -v
"""

import os
from collections.abc import AsyncGenerator
from uuid import uuid4

import pytest_asyncio
from sqlalchemy.ext.asyncio import AsyncSession, create_async_engine
from sqlalchemy.orm import sessionmaker
from sqlmodel import SQLModel

from app.core.security import hash_password
from app.models.exercise import BodyPart, Exercise, ExerciseCategory
from app.models.user import User

# Use SQLite for CI, PostgreSQL for local development
TEST_DATABASE_URL = os.environ.get(
    "TEST_DATABASE_URL",
    "sqlite+aiosqlite:///:memory:",
)

IS_POSTGRES = "postgresql" in TEST_DATABASE_URL


@pytest_asyncio.fixture(scope="function")
async def pg_engine():
    """Create database engine for integration tests."""
    connect_args = {} if IS_POSTGRES else {"check_same_thread": False}

    engine = create_async_engine(
        TEST_DATABASE_URL,
        echo=False,
        connect_args=connect_args,
    )

    async with engine.begin() as conn:
        await conn.run_sync(SQLModel.metadata.create_all)

    yield engine

    if not IS_POSTGRES:
        async with engine.begin() as conn:
            await conn.run_sync(SQLModel.metadata.drop_all)

    await engine.dispose()


@pytest_asyncio.fixture
async def pg_session(pg_engine) -> AsyncGenerator[AsyncSession]:
    """Provide test session with transaction rollback."""
    async_session_factory = sessionmaker(
        pg_engine,
        class_=AsyncSession,
        expire_on_commit=False,
    )
    async with async_session_factory() as session:
        yield session
        await session.rollback()


@pytest_asyncio.fixture
async def pg_session_committed(pg_engine) -> AsyncGenerator[AsyncSession]:
    """Provide session that commits (for testing real persistence)."""
    async_session_factory = sessionmaker(
        pg_engine,
        class_=AsyncSession,
        expire_on_commit=False,
    )
    async with async_session_factory() as session:
        yield session


@pytest_asyncio.fixture
async def test_patient(pg_session: AsyncSession) -> User:
    """Create a test patient user."""
    user = User(
        id=uuid4(),
        email=f"patient_{uuid4().hex[:8]}@example.com",
        hashed_password=hash_password("password"),
        role="patient",
        is_active=True,
    )
    pg_session.add(user)
    await pg_session.flush()
    return user


@pytest_asyncio.fixture
async def test_exercise(pg_session: AsyncSession) -> Exercise:
    """Create a test exercise."""
    exercise = Exercise(
        id=uuid4(),
        name=f"Test Exercise {uuid4().hex[:8]}",
        category=ExerciseCategory.MOBILITY,
        body_part=BodyPart.KNEE,
        is_active=True,
    )
    pg_session.add(exercise)
    await pg_session.flush()
    return exercise
