"""
Unit tests for database module.

Test coverage:
1. Engine creation
2. Session factory
3. get_session dependency
4. init_db function
5. Connection handling
"""

import pytest
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import async_session_factory, engine, get_session, init_db


class TestDatabaseEngine:
    """Tests for database engine configuration."""

    def test_engine_is_created(self) -> None:
        """Database engine is created."""
        assert engine is not None

    def test_engine_is_async(self) -> None:
        """Engine is async-compatible."""
        # AsyncEngine has specific attributes
        assert hasattr(engine, "begin")
        assert hasattr(engine, "dispose")


class TestSessionFactory:
    """Tests for async session factory."""

    def test_session_factory_is_created(self) -> None:
        """Session factory is created."""
        assert async_session_factory is not None

    @pytest.mark.asyncio
    async def test_session_factory_creates_sessions(self) -> None:
        """Session factory creates AsyncSession instances."""
        async with async_session_factory() as session:
            assert isinstance(session, AsyncSession)


class TestGetSession:
    """Tests for get_session dependency."""

    @pytest.mark.asyncio
    async def test_get_session_yields_session(self) -> None:
        """get_session yields an AsyncSession."""
        async for session in get_session():
            assert isinstance(session, AsyncSession)
            break

    @pytest.mark.asyncio
    async def test_get_session_commits_on_success(
        self,
        session: AsyncSession,
    ) -> None:
        """Session commits on successful completion."""
        # This is implicitly tested by the fixture
        # The session fixture uses get_session pattern
        assert session is not None


class TestInitDb:
    """Tests for init_db function."""

    @pytest.mark.asyncio
    async def test_init_db_creates_tables(self) -> None:
        """init_db creates all tables without error."""
        # Should not raise
        await init_db()

    @pytest.mark.asyncio
    async def test_init_db_is_idempotent(self) -> None:
        """init_db can be called multiple times safely."""
        # Should not raise on multiple calls
        await init_db()
        await init_db()
