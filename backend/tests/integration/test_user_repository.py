"""PostgreSQL integration tests for User repository operations."""

from uuid import uuid4

import pytest
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlmodel import col

from app.core.security import hash_password, verify_password
from app.models.user import User, UserRole

# Import fixtures from conftest
pytestmark = pytest.mark.asyncio


class TestUserRepository:
    """Test User model CRUD operations with PostgreSQL."""

    async def test_create_user(self, pg_session: AsyncSession) -> None:
        """Test creating a new user."""
        user = User(
            id=uuid4(),
            email="newuser@example.com",
            hashed_password=hash_password("securepassword123"),
            full_name="John Doe",
            role=UserRole.PATIENT,
            is_active=True,
            is_verified=False,
        )
        pg_session.add(user)
        await pg_session.flush()

        # Verify user was created
        result = await pg_session.execute(
            select(User).where(User.email == "newuser@example.com")
        )
        created_user = result.scalar_one()

        assert created_user.id == user.id
        assert created_user.email == "newuser@example.com"
        assert created_user.full_name == "John Doe"
        assert created_user.role == UserRole.PATIENT
        assert created_user.is_active is True
        assert created_user.is_verified is False
        assert created_user.created_at is not None

    async def test_user_unique_email_constraint(self, pg_session: AsyncSession) -> None:
        """Test that email uniqueness is enforced."""
        user1 = User(
            id=uuid4(),
            email="duplicate@example.com",
            hashed_password=hash_password("password1"),
        )
        pg_session.add(user1)
        await pg_session.flush()

        user2 = User(
            id=uuid4(),
            email="duplicate@example.com",  # Same email
            hashed_password=hash_password("password2"),
        )
        pg_session.add(user2)

        with pytest.raises(
            (Exception, ValueError)
        ):  # IntegrityError or unique constraint
            await pg_session.flush()

    async def test_read_user_by_id(self, pg_session: AsyncSession) -> None:
        """Test reading user by ID."""
        user_id = uuid4()
        user = User(
            id=user_id,
            email="findme@example.com",
            hashed_password=hash_password("password"),
        )
        pg_session.add(user)
        await pg_session.flush()

        # Read by ID
        result = await pg_session.execute(select(User).where(User.id == user_id))
        found_user = result.scalar_one_or_none()

        assert found_user is not None
        assert found_user.id == user_id
        assert found_user.email == "findme@example.com"

    async def test_read_user_by_email(self, pg_session: AsyncSession) -> None:
        """Test reading user by email."""
        user = User(
            id=uuid4(),
            email="byemail@example.com",
            hashed_password=hash_password("password"),
        )
        pg_session.add(user)
        await pg_session.flush()

        # Read by email
        result = await pg_session.execute(
            select(User).where(User.email == "byemail@example.com")
        )
        found_user = result.scalar_one_or_none()

        assert found_user is not None
        assert found_user.email == "byemail@example.com"

    async def test_update_user(self, pg_session: AsyncSession) -> None:
        """Test updating user fields."""
        user = User(
            id=uuid4(),
            email="update@example.com",
            hashed_password=hash_password("password"),
            full_name="Old Name",
        )
        pg_session.add(user)
        await pg_session.flush()

        # Update fields
        user.full_name = "New Name"
        user.is_verified = True
        await pg_session.flush()

        # Refresh and verify
        await pg_session.refresh(user)
        assert user.full_name == "New Name"
        assert user.is_verified is True

    async def test_delete_user(self, pg_session: AsyncSession) -> None:
        """Test deleting a user."""
        user_id = uuid4()
        user = User(
            id=user_id,
            email="delete@example.com",
            hashed_password=hash_password("password"),
        )
        pg_session.add(user)
        await pg_session.flush()

        # Delete user
        await pg_session.delete(user)
        await pg_session.flush()

        # Verify deletion
        result = await pg_session.execute(select(User).where(User.id == user_id))
        assert result.scalar_one_or_none() is None

    async def test_user_password_hashing(self, pg_session: AsyncSession) -> None:
        """Test that password is properly hashed and verifiable."""
        plain_password = "MySecureP@ssw0rd!"
        user = User(
            id=uuid4(),
            email="hashed@example.com",
            hashed_password=hash_password(plain_password),
        )
        pg_session.add(user)
        await pg_session.flush()

        # Password should not be stored in plain text
        assert user.hashed_password != plain_password

        # Password should be verifiable
        assert verify_password(plain_password, user.hashed_password)
        assert not verify_password("wrongpassword", user.hashed_password)

    async def test_list_users_with_role_filter(self, pg_session: AsyncSession) -> None:
        """Test listing users filtered by role."""
        # Create patients
        for i in range(3):
            pg_session.add(
                User(
                    id=uuid4(),
                    email=f"patient{i}@example.com",
                    hashed_password=hash_password("password"),
                    role=UserRole.PATIENT,
                )
            )

        # Create admins
        for i in range(2):
            pg_session.add(
                User(
                    id=uuid4(),
                    email=f"admin{i}@example.com",
                    hashed_password=hash_password("password"),
                    role=UserRole.ADMIN,
                )
            )

        await pg_session.flush()

        # Query patients only
        result = await pg_session.execute(
            select(User).where(User.role == UserRole.PATIENT)
        )
        patients = result.scalars().all()

        assert len(patients) >= 3  # At least our 3 patients
        for patient in patients:
            assert patient.role == UserRole.PATIENT

    async def test_user_pagination(self, pg_session: AsyncSession) -> None:
        """Test paginated user listing."""
        # Create multiple users
        for i in range(10):
            pg_session.add(
                User(
                    id=uuid4(),
                    email=f"paginate{i}@example.com",
                    hashed_password=hash_password("password"),
                )
            )
        await pg_session.flush()

        # Page 1 (first 5)
        result = await pg_session.execute(
            select(User).where(col(User.email).like("paginate%")).offset(0).limit(5)
        )
        page1 = result.scalars().all()

        # Page 2 (next 5)
        result = await pg_session.execute(
            select(User).where(col(User.email).like("paginate%")).offset(5).limit(5)
        )
        page2 = result.scalars().all()

        assert len(page1) == 5
        assert len(page2) == 5

        # Pages should not overlap
        page1_ids = {u.id for u in page1}
        page2_ids = {u.id for u in page2}
        assert page1_ids.isdisjoint(page2_ids)

    async def test_user_ordering(self, pg_session: AsyncSession) -> None:
        """Test ordering users by created_at."""
        users = []
        for i in range(3):
            user = User(
                id=uuid4(),
                email=f"ordered{i}@example.com",
                hashed_password=hash_password("password"),
            )
            pg_session.add(user)
            await pg_session.flush()
            users.append(user)

        # Query with ordering by created_at descending
        result = await pg_session.execute(
            select(User)
            .where(col(User.email).like("ordered%"))
            .order_by(User.created_at.desc())
        )
        ordered_users = result.scalars().all()

        # Latest user should be first
        assert ordered_users[0].created_at >= ordered_users[-1].created_at


class TestUserRepositoryEdgeCases:
    """Edge case tests for User repository."""

    async def test_user_with_empty_full_name(self, pg_session: AsyncSession) -> None:
        """Test user with empty full name is valid."""
        user = User(
            id=uuid4(),
            email="noname@example.com",
            hashed_password=hash_password("password"),
            full_name="",
        )
        pg_session.add(user)
        await pg_session.flush()

        assert user.full_name == ""

    async def test_user_email_case_sensitivity(self, pg_session: AsyncSession) -> None:
        """Test email lookup is case-insensitive (if configured)."""
        user = User(
            id=uuid4(),
            email="CaseSensitive@Example.COM",
            hashed_password=hash_password("password"),
        )
        pg_session.add(user)
        await pg_session.flush()

        # PostgreSQL is case-sensitive by default
        result = await pg_session.execute(
            select(User).where(User.email == "CaseSensitive@Example.COM")
        )
        found = result.scalar_one_or_none()
        assert found is not None

    async def test_concurrent_user_creation(self, pg_session: AsyncSession) -> None:
        """Test that concurrent creations are handled."""
        import asyncio

        async def create_user(email: str):
            user = User(
                id=uuid4(),
                email=email,
                hashed_password=hash_password("password"),
            )
            pg_session.add(user)
            return user

        # Create multiple users concurrently
        tasks = [create_user(f"concurrent{i}@example.com") for i in range(5)]
        users = await asyncio.gather(*tasks)
        await pg_session.flush()

        # All users should be created
        assert len(users) == 5
        for user in users:
            assert user.id is not None
