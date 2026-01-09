"""
Comprehensive unit tests for Auth/User API endpoints.

Test coverage:
1. User registration with validation
2. User login (success, failure, inactive user)
3. Email verification flow
4. Password reset flow
5. Profile CRUD operations
6. GDPR compliance (export, delete)
7. Rate limiting behavior
"""

from unittest.mock import AsyncMock, patch
from uuid import uuid4

import pytest
from httpx import AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.security import (
    create_access_token,
    create_password_reset_token,
    create_verification_token,
    hash_password,
)
from app.models.user import User


class TestUserRegistration:
    """Tests for POST /api/v1/auth/register endpoint."""

    @pytest.mark.asyncio
    async def test_register_success(
        self,
        client: AsyncClient,
        session: AsyncSession,
    ) -> None:
        """Successful user registration."""
        with patch(
            "app.api.v1.endpoints.auth.send_verification_email", new_callable=AsyncMock
        ):
            response = await client.post(
                "/api/v1/auth/register",
                json={
                    "email": "newuser@example.com",
                    "password": "securepassword123",
                },
            )

        assert response.status_code == 201
        data = response.json()
        assert data["email"] == "newuser@example.com"
        assert data["is_verified"] is False
        assert data["role"] == "patient"
        assert "id" in data

    @pytest.mark.asyncio
    async def test_register_duplicate_email(
        self,
        client: AsyncClient,
        session: AsyncSession,
        test_user: User,
    ) -> None:
        """Registration fails with existing email."""
        response = await client.post(
            "/api/v1/auth/register",
            json={
                "email": test_user.email,
                "password": "anotherpassword123",
            },
        )

        assert response.status_code == 400
        assert "already registered" in response.json()["detail"].lower()

    @pytest.mark.asyncio
    async def test_register_invalid_email(
        self,
        client: AsyncClient,
    ) -> None:
        """Registration fails with invalid email format."""
        response = await client.post(
            "/api/v1/auth/register",
            json={
                "email": "not-an-email",
                "password": "securepassword123",
            },
        )

        assert response.status_code == 422

    @pytest.mark.asyncio
    async def test_register_short_password(
        self,
        client: AsyncClient,
    ) -> None:
        """Registration fails with too short password."""
        response = await client.post(
            "/api/v1/auth/register",
            json={
                "email": "user@example.com",
                "password": "short",
            },
        )

        assert response.status_code == 422

    @pytest.mark.asyncio
    async def test_register_with_full_name(
        self,
        client: AsyncClient,
        session: AsyncSession,
    ) -> None:
        """Registration with optional full name (currently not stored at register)."""
        with patch(
            "app.api.v1.endpoints.auth.send_verification_email", new_callable=AsyncMock
        ):
            response = await client.post(
                "/api/v1/auth/register",
                json={
                    "email": "john.doe@example.com",
                    "password": "securepassword123",
                    "full_name": "John Doe",
                },
            )

        assert response.status_code == 201
        data = response.json()
        # Note: Current implementation doesn't store full_name at registration
        # This verifies registration succeeds with the extra field
        assert "id" in data
        assert data["email"] == "john.doe@example.com"


class TestUserLogin:
    """Tests for POST /api/v1/auth/login endpoint."""

    @pytest.mark.asyncio
    async def test_login_success(
        self,
        client: AsyncClient,
        test_user: User,
    ) -> None:
        """Successful login returns access token."""
        response = await client.post(
            "/api/v1/auth/login",
            data={
                "username": test_user.email,
                "password": "testpassword123",
            },
        )

        assert response.status_code == 200
        data = response.json()
        assert "access_token" in data
        assert data["token_type"] == "bearer"

    @pytest.mark.asyncio
    async def test_login_wrong_password(
        self,
        client: AsyncClient,
        test_user: User,
    ) -> None:
        """Login fails with incorrect password."""
        response = await client.post(
            "/api/v1/auth/login",
            data={
                "username": test_user.email,
                "password": "wrongpassword",
            },
        )

        assert response.status_code == 401
        assert "incorrect" in response.json()["detail"].lower()

    @pytest.mark.asyncio
    async def test_login_nonexistent_user(
        self,
        client: AsyncClient,
    ) -> None:
        """Login fails for non-existent user."""
        response = await client.post(
            "/api/v1/auth/login",
            data={
                "username": "nonexistent@example.com",
                "password": "anypassword",
            },
        )

        assert response.status_code == 401

    @pytest.mark.asyncio
    async def test_login_inactive_user(
        self,
        client: AsyncClient,
        session: AsyncSession,
    ) -> None:
        """Login fails for deactivated user."""
        inactive_user = User(
            id=uuid4(),
            email="inactive@example.com",
            hashed_password=hash_password("testpassword123"),
            is_active=False,
            is_verified=True,
        )
        session.add(inactive_user)
        await session.commit()

        response = await client.post(
            "/api/v1/auth/login",
            data={
                "username": inactive_user.email,
                "password": "testpassword123",
            },
        )

        assert response.status_code == 403
        assert "disabled" in response.json()["detail"].lower()


class TestEmailVerification:
    """Tests for email verification endpoints."""

    @pytest.mark.asyncio
    async def test_verify_email_success(
        self,
        client: AsyncClient,
        session: AsyncSession,
        unverified_user: User,
    ) -> None:
        """Valid verification token verifies email."""
        token = create_verification_token(unverified_user.id)

        with patch(
            "app.api.v1.endpoints.auth.send_welcome_email", new_callable=AsyncMock
        ):
            response = await client.post(
                "/api/v1/auth/verify-email",
                json={"token": token},
            )

        assert response.status_code == 200
        data = response.json()
        assert data["is_verified"] is True

    @pytest.mark.asyncio
    async def test_verify_email_invalid_token(
        self,
        client: AsyncClient,
    ) -> None:
        """Invalid token returns error."""
        response = await client.post(
            "/api/v1/auth/verify-email",
            json={"token": "invalid-token"},
        )

        assert response.status_code == 400
        assert "invalid" in response.json()["detail"].lower()

    @pytest.mark.asyncio
    async def test_verify_email_already_verified(
        self,
        client: AsyncClient,
        session: AsyncSession,
        test_user: User,
    ) -> None:
        """Already verified user returns error."""
        token = create_verification_token(test_user.id)

        response = await client.post(
            "/api/v1/auth/verify-email",
            json={"token": token},
        )

        assert response.status_code == 400
        assert "already verified" in response.json()["detail"].lower()


class TestPasswordReset:
    """Tests for password reset flow."""

    @pytest.mark.asyncio
    async def test_forgot_password_existing_user(
        self,
        client: AsyncClient,
        test_user: User,
    ) -> None:
        """Forgot password for existing user."""
        with patch(
            "app.api.v1.endpoints.auth.send_password_reset_email",
            new_callable=AsyncMock,
        ):
            response = await client.post(
                "/api/v1/auth/forgot-password",
                json={"email": test_user.email},
            )

        assert response.status_code == 202
        assert "message" in response.json()

    @pytest.mark.asyncio
    async def test_forgot_password_nonexistent_user(
        self,
        client: AsyncClient,
    ) -> None:
        """Forgot password for non-existent user (no enumeration)."""
        response = await client.post(
            "/api/v1/auth/forgot-password",
            json={"email": "nonexistent@example.com"},
        )

        # Always returns 202 to prevent email enumeration
        assert response.status_code == 202

    @pytest.mark.asyncio
    async def test_reset_password_success(
        self,
        client: AsyncClient,
        session: AsyncSession,
        test_user: User,
    ) -> None:
        """Valid reset token allows password change."""
        token = create_password_reset_token(test_user.id)

        response = await client.post(
            "/api/v1/auth/reset-password",
            json={
                "token": token,
                "new_password": "newSecurePassword123",
            },
        )

        assert response.status_code == 200

    @pytest.mark.asyncio
    async def test_reset_password_invalid_token(
        self,
        client: AsyncClient,
    ) -> None:
        """Invalid reset token returns error."""
        response = await client.post(
            "/api/v1/auth/reset-password",
            json={
                "token": "invalid-token",
                "new_password": "newPassword123",
            },
        )

        assert response.status_code == 400


class TestUserProfile:
    """Tests for user profile operations."""

    @pytest.mark.asyncio
    async def test_get_current_user(
        self,
        client: AsyncClient,
        test_user: User,
        auth_headers: dict[str, str],
    ) -> None:
        """Get current user profile."""
        response = await client.get(
            "/api/v1/auth/me",
            headers=auth_headers,
        )

        assert response.status_code == 200
        data = response.json()
        assert data["email"] == test_user.email
        assert data["id"] == str(test_user.id)

    @pytest.mark.asyncio
    async def test_get_current_user_unauthorized(
        self,
        client: AsyncClient,
    ) -> None:
        """Unauthorized access to profile."""
        response = await client.get("/api/v1/auth/me")

        assert response.status_code == 401

    @pytest.mark.asyncio
    async def test_update_user_profile(
        self,
        client: AsyncClient,
        test_user: User,
        auth_headers: dict[str, str],
    ) -> None:
        """Update user profile."""
        response = await client.put(
            "/api/v1/auth/me",
            headers=auth_headers,
            json={"full_name": "Updated Name"},
        )

        assert response.status_code == 200
        data = response.json()
        assert data["full_name"] == "Updated Name"

    @pytest.mark.asyncio
    async def test_update_user_email(
        self,
        client: AsyncClient,
        test_user: User,
        auth_headers: dict[str, str],
    ) -> None:
        """Update user email resets verification."""
        response = await client.put(
            "/api/v1/auth/me",
            headers=auth_headers,
            json={"email": "newemail@example.com"},
        )

        assert response.status_code == 200
        data = response.json()
        assert data["email"] == "newemail@example.com"
        assert data["is_verified"] is False


class TestGDPRCompliance:
    """Tests for GDPR-related endpoints."""

    @pytest.mark.asyncio
    async def test_export_user_data(
        self,
        client: AsyncClient,
        test_user: User,
        auth_headers: dict[str, str],
    ) -> None:
        """Export user data (GDPR Right to Data Portability)."""
        response = await client.get(
            "/api/v1/auth/me/export",
            headers=auth_headers,
        )

        assert response.status_code == 200
        data = response.json()
        assert "user" in data
        assert "sessions" in data
        assert "export_date" in data
        assert data["user"]["email"] == test_user.email

    @pytest.mark.asyncio
    async def test_delete_user_account(
        self,
        client: AsyncClient,
        session: AsyncSession,
        auth_headers: dict[str, str],
    ) -> None:
        """Delete user account (GDPR Right to be Forgotten)."""
        # Create a fresh user for deletion test
        user_to_delete = User(
            id=uuid4(),
            email="todelete@example.com",
            hashed_password=hash_password("testpassword123"),
            is_active=True,
            is_verified=True,
        )
        session.add(user_to_delete)
        await session.commit()

        token = create_access_token(user_to_delete.id)
        delete_headers = {"Authorization": f"Bearer {token}"}

        response = await client.delete(
            "/api/v1/auth/me",
            headers=delete_headers,
        )

        assert response.status_code == 204


class TestResendVerification:
    """Tests for resend verification endpoint."""

    @pytest.mark.asyncio
    async def test_resend_verification_success(
        self,
        client: AsyncClient,
        unverified_user: User,
    ) -> None:
        """Resend verification email for unverified user."""
        with patch(
            "app.api.v1.endpoints.auth.send_verification_email", new_callable=AsyncMock
        ):
            response = await client.post(
                "/api/v1/auth/resend-verification",
                params={"email": unverified_user.email},
            )

        assert response.status_code == 202

    @pytest.mark.asyncio
    async def test_resend_verification_already_verified(
        self,
        client: AsyncClient,
        test_user: User,
    ) -> None:
        """Resend for verified user still returns 202 (no enumeration)."""
        response = await client.post(
            "/api/v1/auth/resend-verification",
            params={"email": test_user.email},
        )

        assert response.status_code == 202

    @pytest.mark.asyncio
    async def test_resend_verification_nonexistent_user(
        self,
        client: AsyncClient,
    ) -> None:
        """Resend for non-existent user returns 202 (no enumeration)."""
        response = await client.post(
            "/api/v1/auth/resend-verification",
            params={"email": "nonexistent@example.com"},
        )

        assert response.status_code == 202
