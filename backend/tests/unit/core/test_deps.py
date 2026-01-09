"""
Unit tests for dependency injection module.

Test coverage:
1. get_current_user dependency
2. get_current_active_user dependency
3. get_current_verified_user dependency
4. get_current_admin dependency
5. Authorization error scenarios
"""

from uuid import uuid4

import pytest
from fastapi import HTTPException
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.deps import (
    get_current_active_user,
    get_current_admin,
    get_current_user,
    get_current_verified_user,
)
from app.core.security import create_access_token, hash_password
from app.models.user import User, UserRole


class TestGetCurrentUser:
    """Tests for get_current_user dependency."""

    @pytest.mark.asyncio
    async def test_valid_token_returns_user(
        self,
        session: AsyncSession,
        test_user: User,
    ) -> None:
        """Valid access token returns the user."""
        token = create_access_token(test_user.id)

        user = await get_current_user(session, token)

        assert user is not None
        assert user.id == test_user.id
        assert user.email == test_user.email

    @pytest.mark.asyncio
    async def test_invalid_token_raises_401(
        self,
        session: AsyncSession,
    ) -> None:
        """Invalid token raises 401 Unauthorized."""
        with pytest.raises(HTTPException) as exc_info:
            await get_current_user(session, "invalid-token")

        assert exc_info.value.status_code == 401
        assert "Could not validate credentials" in exc_info.value.detail

    @pytest.mark.asyncio
    async def test_expired_token_raises_401(
        self,
        session: AsyncSession,
    ) -> None:
        """Expired token raises 401 Unauthorized."""
        from datetime import timedelta

        from app.core.security import create_token

        user_id = uuid4()
        expired_token = create_token(
            user_id, "access", expires_delta=timedelta(seconds=-1)
        )

        with pytest.raises(HTTPException) as exc_info:
            await get_current_user(session, expired_token)

        assert exc_info.value.status_code == 401

    @pytest.mark.asyncio
    async def test_wrong_token_type_raises_401(
        self,
        session: AsyncSession,
        test_user: User,
    ) -> None:
        """Non-access token raises 401 Unauthorized."""
        from app.core.security import create_verification_token

        token = create_verification_token(test_user.id)

        with pytest.raises(HTTPException) as exc_info:
            await get_current_user(session, token)

        assert exc_info.value.status_code == 401

    @pytest.mark.asyncio
    async def test_nonexistent_user_raises_401(
        self,
        session: AsyncSession,
    ) -> None:
        """Token for nonexistent user raises 401."""
        fake_user_id = uuid4()
        token = create_access_token(fake_user_id)

        with pytest.raises(HTTPException) as exc_info:
            await get_current_user(session, token)

        assert exc_info.value.status_code == 401

    @pytest.mark.asyncio
    async def test_invalid_uuid_in_token_raises_401(
        self,
        session: AsyncSession,
    ) -> None:
        """Token with invalid UUID raises 401."""
        token = create_access_token("not-a-valid-uuid")

        with pytest.raises(HTTPException) as exc_info:
            await get_current_user(session, token)

        assert exc_info.value.status_code == 401


class TestGetCurrentActiveUser:
    """Tests for get_current_active_user dependency."""

    def test_active_user_passes(self, test_user: User) -> None:
        """Active user is returned."""
        test_user.is_active = True

        result = get_current_active_user(test_user)

        assert result == test_user

    def test_inactive_user_raises_403(self) -> None:
        """Inactive user raises 403 Forbidden."""
        inactive_user = User(
            id=uuid4(),
            email="inactive@example.com",
            hashed_password=hash_password("password"),
            is_active=False,
        )

        with pytest.raises(HTTPException) as exc_info:
            get_current_active_user(inactive_user)

        assert exc_info.value.status_code == 403
        assert "Inactive user" in exc_info.value.detail


class TestGetCurrentVerifiedUser:
    """Tests for get_current_verified_user dependency."""

    def test_verified_user_passes(self, test_user: User) -> None:
        """Verified user is returned."""
        test_user.is_verified = True
        test_user.is_active = True

        result = get_current_verified_user(test_user)

        assert result == test_user

    def test_unverified_user_raises_403(self) -> None:
        """Unverified user raises 403 Forbidden."""
        unverified_user = User(
            id=uuid4(),
            email="unverified@example.com",
            hashed_password=hash_password("password"),
            is_active=True,
            is_verified=False,
        )

        with pytest.raises(HTTPException) as exc_info:
            get_current_verified_user(unverified_user)

        assert exc_info.value.status_code == 403
        assert "Email not verified" in exc_info.value.detail


class TestGetCurrentAdmin:
    """Tests for get_current_admin dependency."""

    def test_admin_user_passes(self) -> None:
        """Admin user is returned."""
        admin_user = User(
            id=uuid4(),
            email="admin@example.com",
            hashed_password=hash_password("password"),
            is_active=True,
            role=UserRole.ADMIN,
        )

        result = get_current_admin(admin_user)

        assert result == admin_user

    def test_non_admin_raises_403(self, test_user: User) -> None:
        """Non-admin user raises 403 Forbidden."""
        test_user.role = UserRole.PATIENT

        with pytest.raises(HTTPException) as exc_info:
            get_current_admin(test_user)

        assert exc_info.value.status_code == 403
        assert "Admin access required" in exc_info.value.detail


class TestAuthorizationChain:
    """Tests for authorization dependency chain."""

    def test_admin_must_be_active(self) -> None:
        """Admin check requires active user."""
        inactive_admin = User(
            id=uuid4(),
            email="admin@example.com",
            hashed_password=hash_password("password"),
            is_active=False,
            role=UserRole.ADMIN,
        )

        # First check: active user
        with pytest.raises(HTTPException) as exc_info:
            get_current_active_user(inactive_admin)

        assert exc_info.value.status_code == 403

    def test_verified_must_be_active(self) -> None:
        """Verified check requires active user."""
        inactive_verified = User(
            id=uuid4(),
            email="verified@example.com",
            hashed_password=hash_password("password"),
            is_active=False,
            is_verified=True,
        )

        # First check: active user
        with pytest.raises(HTTPException) as exc_info:
            get_current_active_user(inactive_verified)

        assert exc_info.value.status_code == 403
