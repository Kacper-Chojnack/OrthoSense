"""
Unit tests for User Repository (data access layer).

Test coverage:
1. User CRUD operations at repository level
2. Query operations
3. Email lookups
4. Role filtering
5. Activation status filtering
6. Error handling
"""

from uuid import uuid4

import pytest
from sqlalchemy.ext.asyncio import AsyncSession
from sqlmodel import select

from app.core.security import hash_password
from app.models.user import User, UserRole


class TestUserRepository:
    """Unit tests for user repository operations."""

    @pytest.mark.asyncio
    async def test_create_user(self, session: AsyncSession) -> None:
        """Create user in database."""
        user = User(
            id=uuid4(),
            email="repo_test@example.com",
            hashed_password=hash_password("testpassword123"),
        )
        session.add(user)
        await session.commit()
        await session.refresh(user)

        assert user.id is not None
        assert user.email == "repo_test@example.com"

    @pytest.mark.asyncio
    async def test_get_user_by_id(
        self,
        session: AsyncSession,
        test_user: User,
    ) -> None:
        """Retrieve user by ID."""
        retrieved = await session.get(User, test_user.id)

        assert retrieved is not None
        assert retrieved.id == test_user.id
        assert retrieved.email == test_user.email

    @pytest.mark.asyncio
    async def test_get_user_by_id_not_found(
        self,
        session: AsyncSession,
    ) -> None:
        """Retrieve non-existent user returns None."""
        retrieved = await session.get(User, uuid4())

        assert retrieved is None

    @pytest.mark.asyncio
    async def test_get_user_by_email(
        self,
        session: AsyncSession,
        test_user: User,
    ) -> None:
        """Retrieve user by email."""
        statement = select(User).where(User.email == test_user.email)
        result = await session.execute(statement)
        retrieved = result.scalar_one_or_none()

        assert retrieved is not None
        assert retrieved.email == test_user.email

    @pytest.mark.asyncio
    async def test_get_user_by_email_not_found(
        self,
        session: AsyncSession,
    ) -> None:
        """Retrieve user by non-existent email returns None."""
        statement = select(User).where(User.email == "nonexistent@example.com")
        result = await session.execute(statement)
        retrieved = result.scalar_one_or_none()

        assert retrieved is None

    @pytest.mark.asyncio
    async def test_update_user(
        self,
        session: AsyncSession,
        test_user: User,
    ) -> None:
        """Update user fields."""
        test_user.full_name = "Updated Name"
        session.add(test_user)
        await session.commit()
        await session.refresh(test_user)

        assert test_user.full_name == "Updated Name"

    @pytest.mark.asyncio
    async def test_delete_user(
        self,
        session: AsyncSession,
    ) -> None:
        """Delete user from database."""
        user = User(
            id=uuid4(),
            email="todelete@example.com",
            hashed_password=hash_password("password123"),
        )
        session.add(user)
        await session.commit()

        user_id = user.id
        await session.delete(user)
        await session.commit()

        # Verify deletion
        deleted = await session.get(User, user_id)
        assert deleted is None


class TestUserQueryOperations:
    """Tests for complex query operations."""

    @pytest.fixture
    async def multiple_users(self, session: AsyncSession) -> list[User]:
        """Create multiple users for query testing."""
        users = [
            User(
                id=uuid4(),
                email="active1@example.com",
                hashed_password=hash_password("password"),
                is_active=True,
                is_verified=True,
                role=UserRole.PATIENT,
            ),
            User(
                id=uuid4(),
                email="active2@example.com",
                hashed_password=hash_password("password"),
                is_active=True,
                is_verified=False,
                role=UserRole.PATIENT,
            ),
            User(
                id=uuid4(),
                email="inactive@example.com",
                hashed_password=hash_password("password"),
                is_active=False,
                is_verified=True,
                role=UserRole.PATIENT,
            ),
            User(
                id=uuid4(),
                email="admin@example.com",
                hashed_password=hash_password("password"),
                is_active=True,
                is_verified=True,
                role=UserRole.ADMIN,
            ),
        ]
        for user in users:
            session.add(user)
        await session.commit()
        return users

    @pytest.mark.asyncio
    async def test_query_active_users(
        self,
        session: AsyncSession,
        multiple_users: list[User],
    ) -> None:
        """Query only active users."""
        statement = select(User).where(User.is_active == True)  # noqa: E712
        result = await session.execute(statement)
        active_users = result.scalars().all()

        assert all(u.is_active for u in active_users)
        assert len(active_users) >= 3

    @pytest.mark.asyncio
    async def test_query_verified_users(
        self,
        session: AsyncSession,
        multiple_users: list[User],
    ) -> None:
        """Query only verified users."""
        statement = select(User).where(User.is_verified == True)  # noqa: E712
        result = await session.execute(statement)
        verified_users = result.scalars().all()

        assert all(u.is_verified for u in verified_users)

    @pytest.mark.asyncio
    async def test_query_by_role(
        self,
        session: AsyncSession,
        multiple_users: list[User],
    ) -> None:
        """Query users by role."""
        statement = select(User).where(User.role == UserRole.ADMIN)
        result = await session.execute(statement)
        admin_users = result.scalars().all()

        assert all(u.role == UserRole.ADMIN for u in admin_users)
        assert len(admin_users) >= 1

    @pytest.mark.asyncio
    async def test_query_combined_filters(
        self,
        session: AsyncSession,
        multiple_users: list[User],
    ) -> None:
        """Query with combined filters."""
        statement = (
            select(User)
            .where(User.is_active == True)  # noqa: E712
            .where(User.is_verified == True)  # noqa: E712
            .where(User.role == UserRole.PATIENT)
        )
        result = await session.execute(statement)
        filtered_users = result.scalars().all()

        assert all(
            u.is_active and u.is_verified and u.role == UserRole.PATIENT
            for u in filtered_users
        )


class TestUserRepositoryConstraints:
    """Tests for database constraints."""

    @pytest.mark.asyncio
    async def test_email_uniqueness(
        self,
        session: AsyncSession,
        test_user: User,
    ) -> None:
        """Duplicate email raises error."""
        from sqlalchemy.exc import IntegrityError

        duplicate_user = User(
            id=uuid4(),
            email=test_user.email,  # Same email
            hashed_password=hash_password("password"),
        )
        session.add(duplicate_user)

        with pytest.raises(IntegrityError):
            await session.commit()

        await session.rollback()

    @pytest.mark.asyncio
    async def test_user_id_is_uuid(
        self,
        session: AsyncSession,
    ) -> None:
        """User ID is a valid UUID."""
        from uuid import UUID

        user = User(
            email="uuid_test@example.com",
            hashed_password=hash_password("password"),
        )
        session.add(user)
        await session.commit()
        await session.refresh(user)

        assert isinstance(user.id, UUID)

    @pytest.mark.asyncio
    async def test_created_at_is_set(
        self,
        session: AsyncSession,
    ) -> None:
        """Created_at timestamp is automatically set."""
        user = User(
            email="timestamp_test@example.com",
            hashed_password=hash_password("password"),
        )
        session.add(user)
        await session.commit()
        await session.refresh(user)

        assert user.created_at is not None

    @pytest.mark.asyncio
    async def test_default_values(
        self,
        session: AsyncSession,
    ) -> None:
        """Default values are applied correctly."""
        user = User(
            email="defaults_test@example.com",
            hashed_password=hash_password("password"),
        )
        session.add(user)
        await session.commit()
        await session.refresh(user)

        assert user.role == UserRole.PATIENT
        assert user.is_active is True
        assert user.is_verified is False
        assert user.full_name == ""
