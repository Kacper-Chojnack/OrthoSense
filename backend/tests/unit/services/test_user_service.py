"""
Unit tests for User Service layer.

Test coverage:
1. User CRUD operations
2. Password hashing and verification
3. Email validation
4. Role management
5. User activation/deactivation
6. Edge cases and error handling
"""

from datetime import UTC, datetime
from uuid import uuid4

import pytest
from sqlalchemy.ext.asyncio import AsyncSession
from sqlmodel import select

from app.core.security import hash_password, verify_password
from app.models.user import User, UserRole


class TestUserCreation:
    """Tests for user creation logic."""

    @pytest.mark.asyncio
    async def test_create_user_defaults(self, session: AsyncSession) -> None:
        """New user has correct default values."""
        user = User(
            email="newuser@example.com",
            hashed_password=hash_password("securepassword123"),
        )
        session.add(user)
        await session.commit()
        await session.refresh(user)

        assert user.id is not None
        assert user.email == "newuser@example.com"
        assert user.role == UserRole.PATIENT
        assert user.is_active is True
        assert user.is_verified is False
        assert user.full_name == ""
        assert user.created_at is not None

    @pytest.mark.asyncio
    async def test_create_user_with_full_name(self, session: AsyncSession) -> None:
        """User can be created with full name."""
        user = User(
            email="john.doe@example.com",
            hashed_password=hash_password("securepassword123"),
            full_name="John Doe",
        )
        session.add(user)
        await session.commit()
        await session.refresh(user)

        assert user.full_name == "John Doe"

    @pytest.mark.asyncio
    async def test_create_admin_user(self, session: AsyncSession) -> None:
        """Admin user can be created with correct role."""
        user = User(
            email="admin@example.com",
            hashed_password=hash_password("adminpassword123"),
            role=UserRole.ADMIN,
        )
        session.add(user)
        await session.commit()
        await session.refresh(user)

        assert user.role == UserRole.ADMIN

    @pytest.mark.asyncio
    async def test_create_verified_user(self, session: AsyncSession) -> None:
        """User can be created as pre-verified."""
        user = User(
            email="verified@example.com",
            hashed_password=hash_password("password123"),
            is_verified=True,
        )
        session.add(user)
        await session.commit()
        await session.refresh(user)

        assert user.is_verified is True


class TestUserRetrieval:
    """Tests for user retrieval operations."""

    @pytest.mark.asyncio
    async def test_get_user_by_id(
        self,
        session: AsyncSession,
        test_user: User,
    ) -> None:
        """User can be retrieved by ID."""
        retrieved = await session.get(User, test_user.id)

        assert retrieved is not None
        assert retrieved.id == test_user.id
        assert retrieved.email == test_user.email

    @pytest.mark.asyncio
    async def test_get_user_by_email(
        self,
        session: AsyncSession,
        test_user: User,
    ) -> None:
        """User can be retrieved by email."""
        statement = select(User).where(User.email == test_user.email)
        result = await session.execute(statement)
        retrieved = result.scalar_one_or_none()

        assert retrieved is not None
        assert retrieved.id == test_user.id

    @pytest.mark.asyncio
    async def test_get_nonexistent_user(self, session: AsyncSession) -> None:
        """Retrieving nonexistent user returns None."""
        retrieved = await session.get(User, uuid4())

        assert retrieved is None

    @pytest.mark.asyncio
    async def test_get_user_by_nonexistent_email(
        self,
        session: AsyncSession,
    ) -> None:
        """Retrieving user by nonexistent email returns None."""
        statement = select(User).where(User.email == "nonexistent@example.com")
        result = await session.execute(statement)
        retrieved = result.scalar_one_or_none()

        assert retrieved is None


class TestUserUpdate:
    """Tests for user update operations."""

    @pytest.mark.asyncio
    async def test_update_user_email(
        self,
        session: AsyncSession,
        test_user: User,
    ) -> None:
        """User email can be updated."""
        test_user.email = "updated@example.com"
        test_user.updated_at = datetime.now(UTC)
        await session.commit()
        await session.refresh(test_user)

        assert test_user.email == "updated@example.com"
        assert test_user.updated_at is not None

    @pytest.mark.asyncio
    async def test_update_user_full_name(
        self,
        session: AsyncSession,
        test_user: User,
    ) -> None:
        """User full name can be updated."""
        test_user.full_name = "Updated Name"
        await session.commit()
        await session.refresh(test_user)

        assert test_user.full_name == "Updated Name"

    @pytest.mark.asyncio
    async def test_verify_user(
        self,
        session: AsyncSession,
        unverified_user: User,
    ) -> None:
        """User can be verified."""
        unverified_user.is_verified = True
        unverified_user.updated_at = datetime.now(UTC)
        await session.commit()
        await session.refresh(unverified_user)

        assert unverified_user.is_verified is True

    @pytest.mark.asyncio
    async def test_deactivate_user(
        self,
        session: AsyncSession,
        test_user: User,
    ) -> None:
        """User can be deactivated."""
        test_user.is_active = False
        await session.commit()
        await session.refresh(test_user)

        assert test_user.is_active is False

    @pytest.mark.asyncio
    async def test_change_user_role(
        self,
        session: AsyncSession,
        test_user: User,
    ) -> None:
        """User role can be changed."""
        assert test_user.role == UserRole.PATIENT

        test_user.role = UserRole.ADMIN
        await session.commit()
        await session.refresh(test_user)

        assert test_user.role == UserRole.ADMIN


class TestUserDeletion:
    """Tests for user deletion operations."""

    @pytest.mark.asyncio
    async def test_delete_user(self, session: AsyncSession) -> None:
        """User can be deleted."""
        user = User(
            email="todelete@example.com",
            hashed_password=hash_password("password123"),
        )
        session.add(user)
        await session.commit()
        user_id = user.id

        await session.delete(user)
        await session.commit()

        retrieved = await session.get(User, user_id)
        assert retrieved is None

    @pytest.mark.asyncio
    async def test_soft_delete_user(
        self,
        session: AsyncSession,
        test_user: User,
    ) -> None:
        """User can be soft deleted by deactivating."""
        test_user.is_active = False
        await session.commit()
        await session.refresh(test_user)

        # User still exists but is inactive
        retrieved = await session.get(User, test_user.id)
        assert retrieved is not None
        assert retrieved.is_active is False


class TestPasswordOperations:
    """Tests for password-related operations."""

    @pytest.mark.asyncio
    async def test_password_is_hashed(self, session: AsyncSession) -> None:
        """Password is stored as hash, not plaintext."""
        plain_password = "myplainpassword123"
        user = User(
            email="hashtest@example.com",
            hashed_password=hash_password(plain_password),
        )
        session.add(user)
        await session.commit()

        assert user.hashed_password != plain_password
        assert len(user.hashed_password) > 50  # bcrypt produces long hashes

    @pytest.mark.asyncio
    async def test_password_verification_success(
        self,
        session: AsyncSession,
    ) -> None:
        """Correct password verifies successfully."""
        plain_password = "correctpassword123"
        user = User(
            email="verifytest@example.com",
            hashed_password=hash_password(plain_password),
        )
        session.add(user)
        await session.commit()

        assert verify_password(plain_password, user.hashed_password) is True

    @pytest.mark.asyncio
    async def test_password_verification_failure(
        self,
        session: AsyncSession,
    ) -> None:
        """Incorrect password fails verification."""
        user = User(
            email="wrongpass@example.com",
            hashed_password=hash_password("correctpassword123"),
        )
        session.add(user)
        await session.commit()

        assert verify_password("wrongpassword123", user.hashed_password) is False

    @pytest.mark.asyncio
    async def test_password_change(
        self,
        session: AsyncSession,
        test_user: User,
    ) -> None:
        """User password can be changed."""
        new_password = "newpassword456"
        test_user.hashed_password = hash_password(new_password)
        await session.commit()
        await session.refresh(test_user)

        assert verify_password(new_password, test_user.hashed_password) is True
        assert verify_password("testpassword123", test_user.hashed_password) is False


class TestUserListOperations:
    """Tests for listing multiple users."""

    @pytest.mark.asyncio
    async def test_list_all_users(self, session: AsyncSession) -> None:
        """All users can be listed."""
        # Create multiple users
        users = [
            User(
                email=f"user{i}@example.com",
                hashed_password=hash_password("password123"),
            )
            for i in range(5)
        ]
        for user in users:
            session.add(user)
        await session.commit()

        statement = select(User)
        result = await session.execute(statement)
        all_users = result.scalars().all()

        assert len(all_users) >= 5

    @pytest.mark.asyncio
    async def test_list_active_users_only(self, session: AsyncSession) -> None:
        """Only active users can be listed."""
        # Create active and inactive users
        active_user = User(
            email="active@example.com",
            hashed_password=hash_password("password123"),
            is_active=True,
        )
        inactive_user = User(
            email="inactive@example.com",
            hashed_password=hash_password("password123"),
            is_active=False,
        )
        session.add(active_user)
        session.add(inactive_user)
        await session.commit()

        statement = select(User).where(User.is_active == True)  # noqa: E712
        result = await session.execute(statement)
        active_users = result.scalars().all()

        emails = [u.email for u in active_users]
        assert "active@example.com" in emails
        assert "inactive@example.com" not in emails

    @pytest.mark.asyncio
    async def test_list_users_by_role(self, session: AsyncSession) -> None:
        """Users can be filtered by role."""
        patient = User(
            email="patient@example.com",
            hashed_password=hash_password("password123"),
            role=UserRole.PATIENT,
        )
        admin = User(
            email="admin@example.com",
            hashed_password=hash_password("password123"),
            role=UserRole.ADMIN,
        )
        session.add(patient)
        session.add(admin)
        await session.commit()

        statement = select(User).where(User.role == UserRole.ADMIN)
        result = await session.execute(statement)
        admins = result.scalars().all()

        emails = [u.email for u in admins]
        assert "admin@example.com" in emails
        assert "patient@example.com" not in emails


class TestUserEdgeCases:
    """Tests for edge cases and boundary conditions."""

    @pytest.mark.asyncio
    async def test_user_with_long_email(self, session: AsyncSession) -> None:
        """User can have a reasonably long email."""
        long_local = "a" * 64
        email = f"{long_local}@example.com"
        user = User(
            email=email,
            hashed_password=hash_password("password123"),
        )
        session.add(user)
        await session.commit()
        await session.refresh(user)

        assert user.email == email

    @pytest.mark.asyncio
    async def test_user_with_special_characters_in_email(
        self,
        session: AsyncSession,
    ) -> None:
        """User email with special characters is handled."""
        special_emails = [
            "user+tag@example.com",
            "user.name@example.com",
            "user_name@example.com",
        ]

        for email in special_emails:
            user = User(
                email=email,
                hashed_password=hash_password("password123"),
            )
            session.add(user)
            await session.commit()
            await session.refresh(user)
            assert user.email == email

    @pytest.mark.asyncio
    async def test_user_created_at_is_set_automatically(
        self,
        session: AsyncSession,
    ) -> None:
        """created_at is set automatically on user creation."""
        before = datetime.now(UTC).replace(
            tzinfo=None
        )  # Make offset-naive for comparison

        user = User(
            email="timestamp@example.com",
            hashed_password=hash_password("password123"),
        )
        session.add(user)
        await session.commit()
        await session.refresh(user)

        after = datetime.now(UTC).replace(tzinfo=None)

        assert user.created_at is not None
        # Handle both offset-aware and offset-naive from DB
        created = (
            user.created_at.replace(tzinfo=None)
            if user.created_at.tzinfo
            else user.created_at
        )
        assert before <= created <= after

    @pytest.mark.asyncio
    async def test_concurrent_user_creation(self, session: AsyncSession) -> None:
        """Multiple users can be created in single transaction."""
        users = [
            User(
                email=f"concurrent{i}@example.com",
                hashed_password=hash_password("password123"),
            )
            for i in range(10)
        ]

        for user in users:
            session.add(user)
        await session.commit()

        for user in users:
            await session.refresh(user)
            assert user.id is not None

    @pytest.mark.asyncio
    async def test_user_with_unicode_name(self, session: AsyncSession) -> None:
        """User can have unicode characters in full name."""
        user = User(
            email="unicode@example.com",
            hashed_password=hash_password("password123"),
            full_name="日本語ユーザー",
        )
        session.add(user)
        await session.commit()
        await session.refresh(user)

        assert user.full_name == "日本語ユーザー"
