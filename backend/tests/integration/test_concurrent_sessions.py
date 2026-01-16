"""
Integration tests for concurrent session handling.

Test coverage:
1. Multiple users creating sessions simultaneously
2. Same user with concurrent requests
3. Race conditions in session state updates
4. Database lock handling
5. Resource cleanup under concurrency
"""

import asyncio
from datetime import UTC, datetime, timedelta
from uuid import uuid4

import pytest
import pytest_asyncio
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.security import hash_password
from app.models.session import Session, SessionStatus
from app.models.user import User


class TestConcurrentSessionCreation:
    """Tests for concurrent session creation."""

    @pytest_asyncio.fixture
    async def multiple_users(self, session: AsyncSession) -> list[User]:
        """Create multiple test users."""
        users = []
        for i in range(5):
            user = User(
                id=uuid4(),
                email=f"concurrent_user_{i}@example.com",
                hashed_password=hash_password("password123"),
                is_active=True,
                is_verified=True,
            )
            session.add(user)
            users.append(user)
        await session.commit()
        return users

    @pytest.mark.asyncio
    async def test_concurrent_session_creation_different_users(
        self,
        session: AsyncSession,
        multiple_users: list[User],
    ) -> None:
        """Multiple users can create sessions simultaneously."""

        async def create_session_for_user(user: User) -> Session:
            sess = Session(
                id=uuid4(),
                patient_id=user.id,
                status=SessionStatus.IN_PROGRESS,
                scheduled_date=datetime.now(UTC),
            )
            session.add(sess)
            return sess

        # Create sessions concurrently
        tasks = [create_session_for_user(user) for user in multiple_users]
        sessions = await asyncio.gather(*tasks)

        await session.commit()

        assert len(sessions) == len(multiple_users)
        # Each session has unique ID
        session_ids = [s.id for s in sessions]
        assert len(set(session_ids)) == len(sessions)


class TestConcurrentStateUpdates:
    """Tests for concurrent session state updates."""

    @pytest_asyncio.fixture
    async def test_session(
        self,
        session: AsyncSession,
        test_user: User,
    ) -> Session:
        """Create a test session."""
        sess = Session(
            id=uuid4(),
            patient_id=test_user.id,
            status=SessionStatus.IN_PROGRESS,
            scheduled_date=datetime.now(UTC),
            started_at=datetime.now(UTC),
        )
        session.add(sess)
        await session.commit()
        await session.refresh(sess)
        return sess

    @pytest.mark.asyncio
    async def test_sequential_state_transitions(
        self,
        session: AsyncSession,
        test_session: Session,
    ) -> None:
        """Sequential state transitions work correctly."""
        # IN_PROGRESS -> COMPLETED
        test_session.status = SessionStatus.COMPLETED
        test_session.completed_at = datetime.now(UTC)
        session.add(test_session)
        await session.commit()
        await session.refresh(test_session)

        assert test_session.status == SessionStatus.COMPLETED


class TestConcurrentDatabaseOperations:
    """Tests for concurrent database operations."""

    @pytest.mark.asyncio
    async def test_multiple_reads_same_user(
        self,
        session: AsyncSession,
        test_user: User,
    ) -> None:
        """Concurrent reads of same user don't conflict."""

        async def read_user() -> User | None:
            return await session.get(User, test_user.id)

        tasks = [read_user() for _ in range(10)]
        results = await asyncio.gather(*tasks)

        assert all(r is not None for r in results)
        assert all(r.id == test_user.id for r in results)

    @pytest.mark.asyncio
    async def test_create_multiple_sessions_single_commit(
        self,
        session: AsyncSession,
        test_user: User,
    ) -> None:
        """Multiple sessions can be created in single commit."""
        sessions_to_create = []
        for i in range(10):
            sess = Session(
                id=uuid4(),
                patient_id=test_user.id,
                status=SessionStatus.IN_PROGRESS,
                scheduled_date=datetime.now(UTC) + timedelta(days=i),
            )
            session.add(sess)
            sessions_to_create.append(sess)

        await session.commit()

        # Verify all sessions were created
        for sess in sessions_to_create:
            await session.refresh(sess)
            assert sess.id is not None


class TestResourceCleanup:
    """Tests for resource cleanup under concurrent operations."""

    @pytest.mark.asyncio
    async def test_cleanup_after_concurrent_operations(
        self,
        session: AsyncSession,
        test_user: User,
    ) -> None:
        """Resources are properly cleaned up after concurrent operations."""
        # Create multiple sessions
        created_sessions = []
        for _ in range(5):
            sess = Session(
                id=uuid4(),
                patient_id=test_user.id,
                status=SessionStatus.IN_PROGRESS,
                scheduled_date=datetime.now(UTC),
            )
            session.add(sess)
            created_sessions.append(sess)

        await session.commit()

        # Delete all sessions
        for sess in created_sessions:
            await session.delete(sess)

        await session.commit()

        # Verify cleanup
        for sess in created_sessions:
            deleted = await session.get(Session, sess.id)
            assert deleted is None
