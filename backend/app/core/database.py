"""Async database session management with SQLModel.

Uses connection pooling for Postgres, simple connections for SQLite.
"""

from collections.abc import AsyncGenerator

from sqlalchemy.ext.asyncio import AsyncSession, create_async_engine
from sqlalchemy.orm import sessionmaker
from sqlmodel import SQLModel

from app.core.config import settings

# Engine configuration varies by database type
_connect_args = {"check_same_thread": False} if settings.is_sqlite else {}

engine = create_async_engine(
    settings.database_url,
    echo=settings.debug,
    connect_args=_connect_args,
)

async_session_factory = sessionmaker(  # type: ignore[call-overload]
    engine,
    class_=AsyncSession,
    expire_on_commit=False,
)


async def init_db() -> None:
    """Create all tables. Called on application startup.

    Gracefully handles connection failures for cloud deployments
    where database might not be immediately available.
    """
    import asyncio

    from app.core.logging import get_logger

    logger = get_logger(__name__)
    max_retries = 3
    retry_delay = 2

    for attempt in range(max_retries):
        try:
            async with engine.begin() as conn:
                await conn.run_sync(SQLModel.metadata.create_all)
            logger.info("database_initialized_successfully")
            return
        except Exception as e:
            if attempt < max_retries - 1:
                logger.warning(
                    "database_connection_retry",
                    attempt=attempt + 1,
                    max_retries=max_retries,
                    error=str(e),
                )
                await asyncio.sleep(retry_delay)
            else:
                logger.error(
                    "database_initialization_failed",
                    error=str(e),
                    message="App will start but DB operations may fail",
                )
                # Don't raise - let app start for health checks


async def get_session() -> AsyncGenerator[AsyncSession]:
    """Dependency injection for async database sessions."""
    async with async_session_factory() as session:
        try:
            yield session
            await session.commit()
        except Exception:
            await session.rollback()
            raise
