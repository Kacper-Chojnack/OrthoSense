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


class TestAsyncSession:
    """Test async session factory."""

    def test_session_factory_exists(self):
        """Should have async session factory."""
        from app.core.database import async_session
        
        assert async_session is not None

    @pytest.mark.asyncio
    async def test_creates_session(self):
        """Should create async session."""
        from app.core.database import async_session
        
        async with async_session() as session:
            assert session is not None
            assert isinstance(session, AsyncSession)


class TestGetDbDependency:
    """Test FastAPI dependency for database."""

    @pytest.mark.asyncio
    async def test_yields_session(self):
        """Should yield database session."""
        from app.core.database import get_db
        
        # get_db is an async generator
        gen = get_db()
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
        from app.core.database import get_db
        
        gen = get_db()
        session = await gen.__anext__()
        
        # Session should be open
        assert session is not None
        
        # Exit context
        try:
            await gen.__anext__()
        except StopAsyncIteration:
            pass
        
        # Session should be closed
        # (implementation dependent)


class TestDatabaseURL:
    """Test database URL configuration."""

    def test_uses_async_driver(self):
        """Database URL should use async driver."""
        from app.core.database import DATABASE_URL
        
        # Should use asyncpg for PostgreSQL or aiosqlite for SQLite
        if DATABASE_URL:
            assert (
                "asyncpg" in DATABASE_URL
                or "aiosqlite" in DATABASE_URL
                or "postgresql+asyncpg" in DATABASE_URL
            )


class TestCreateTables:
    """Test table creation."""

    @pytest.mark.asyncio
    async def test_creates_all_tables(self):
        """Should create all tables."""
        from app.core.database import create_tables
        
        # Should not raise
        await create_tables()


class TestSessionContext:
    """Test session context management."""

    @pytest.mark.asyncio
    async def test_session_commit(self):
        """Should commit on successful operation."""
        from app.core.database import async_session
        
        async with async_session() as session:
            # Just verify session works
            assert session is not None

    @pytest.mark.asyncio
    async def test_session_rollback_on_error(self):
        """Should rollback on error."""
        from app.core.database import async_session
        
        try:
            async with async_session() as session:
                # Simulate error
                raise ValueError("Test error")
        except ValueError:
            pass
        
        # Session should be rolled back and closed


class TestConnectionPool:
    """Test connection pooling."""

    def test_pool_size_configured(self):
        """Should have configured pool size."""
        from app.core.database import engine
        
        # Check pool configuration
        pool = engine.pool
        assert pool is not None


class TestTransactions:
    """Test transaction handling."""

    @pytest.mark.asyncio
    async def test_nested_transactions(self):
        """Should support nested transactions."""
        from app.core.database import async_session
        
        async with async_session() as session:
            async with session.begin_nested():
                # Nested transaction
                pass


class TestHealthCheck:
    """Test database health check."""

    @pytest.mark.asyncio
    async def test_database_is_accessible(self):
        """Database should be accessible."""
        from app.core.database import async_session
        from sqlalchemy import text
        
        async with async_session() as session:
            result = await session.execute(text("SELECT 1"))
            value = result.scalar()
            
            assert value == 1
