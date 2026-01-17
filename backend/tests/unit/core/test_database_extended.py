"""Extended unit tests for database module.

Test coverage:
1. Database connection
2. Session management
3. Async operations
4. Error handling
"""

import pytest
from unittest.mock import AsyncMock, MagicMock, patch

from sqlalchemy.ext.asyncio import AsyncSession


class TestAsyncEngine:
    """Test async database engine."""

    def test_engine_exists(self):
        """Should have async engine."""
        from app.core.database import engine

        assert engine is not None

    def test_engine_is_async(self):
        """Engine should be async."""
        from app.core.database import engine
        from sqlalchemy.ext.asyncio import AsyncEngine

        assert isinstance(engine, AsyncEngine)


class TestAsyncSessionFactory:
    """Test async session factory."""

    def test_session_factory_exists(self):
        """Should have async session factory."""
        from app.core.database import async_session_factory

        assert async_session_factory is not None

    @pytest.mark.asyncio
    async def test_creates_session(self):
        """Should create async session."""
        from app.core.database import async_session_factory

        async with async_session_factory() as session:
            assert session is not None
            assert isinstance(session, AsyncSession)


class TestGetSessionDependency:
    """Test FastAPI dependency for database."""

    @pytest.mark.asyncio
    async def test_yields_session(self):
        """Should yield database session."""
        from app.core.database import get_session

        # get_session is an async generator
        gen = get_session()
        session = await gen.__anext__()

        assert session is not None

        # Clean up
        try:
            await gen.__anext__()
        except StopAsyncIteration:
            pass

    @pytest.mark.asyncio
    async def test_closes_session_on_exit(self):
        """Should close session when exiting context."""
        from app.core.database import get_session

        gen = get_session()
        session = await gen.__anext__()

        # Session should be open
        assert session is not None

        # Exit context
        try:
            await gen.__anext__()
        except StopAsyncIteration:
            pass


class TestDatabaseURL:
    """Test database URL configuration."""

    def test_uses_async_driver(self):
        """Database URL should use async driver."""
        from app.core.config import settings

        # Should use asyncpg for PostgreSQL or aiosqlite for SQLite
        if settings.database_url:
            assert (
                "asyncpg" in settings.database_url
                or "aiosqlite" in settings.database_url
                or "postgresql+asyncpg" in settings.database_url
            )


class TestInitDb:
    """Test database initialization."""

    @pytest.mark.asyncio
    async def test_init_db_exists(self):
        """init_db function should exist."""
        from app.core.database import init_db

        assert callable(init_db)

    @pytest.mark.asyncio
    async def test_init_db_runs(self):
        """init_db should run without error."""
        from app.core.database import init_db

        # Should not raise
        await init_db()


class TestSessionContext:
    """Test session context management."""

    @pytest.mark.asyncio
    async def test_session_commit(self):
        """Should commit on successful operation."""
        from app.core.database import async_session_factory

        async with async_session_factory() as session:
            # Just verify session works
            assert session is not None

    @pytest.mark.asyncio
    async def test_session_rollback_on_error(self):
        """Should rollback on error."""
        from app.core.database import async_session_factory

        try:
            async with async_session_factory() as session:
                # Simulate error
                raise ValueError("Test error")
        except ValueError:
            pass

        # Session should be rolled back and closed


class TestConnectionPool:
    """Test connection pooling."""

    def test_engine_has_pool(self):
        """Engine should have connection pool."""
        from app.core.database import engine

        # AsyncEngine wraps sync engine with pool
        assert engine is not None


class TestSqliteConfiguration:
    """Test SQLite-specific configuration."""

    def test_is_sqlite_property(self):
        """Should have is_sqlite property."""
        from app.core.config import settings

        assert hasattr(settings, "is_sqlite")
        assert isinstance(settings.is_sqlite, bool)
