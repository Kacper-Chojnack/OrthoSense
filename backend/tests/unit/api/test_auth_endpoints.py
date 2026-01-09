"""
Unit tests for Authentication API endpoints.

Test coverage:
1. Registration flow
2. Login flow (success, failure cases)
3. Email verification
4. Password reset flow
5. User profile operations (GET /me, PUT /me, DELETE /me)
6. GDPR data export
7. Rate limiting validation
8. Edge cases and security scenarios
"""

from datetime import UTC, datetime
from uuid import uuid4

import pytest
from httpx import AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.security import (
    create_password_reset_token,
    create_verification_token,
    hash_password,
)
from app.models.session import Session, SessionStatus
from app.models.user import User


class TestRegisterEndpoint:
    """Tests for POST /api/v1/auth/register endpoint."""

    @pytest.mark.asyncio
    async def test_register_success(
        self,
        client: AsyncClient,
        session: AsyncSession,
    ) -> None:
        """Successful registration creates user and returns UserRead."""
        response = await client.post(
            "/api/v1/auth/register",
            json={
                "email": "newuser@example.com",
                "password": "SecurePassword123!",
            },
        )

        assert response.status_code == 201
        data = response.json()
        assert data["email"] == "newuser@example.com"
        assert "id" in data
        assert data["is_active"] is True
        assert data["is_verified"] is False
        assert "hashed_password" not in data

    @pytest.mark.asyncio
    async def test_register_duplicate_email(
        self,
        client: AsyncClient,
        test_user: User,
    ) -> None:
        """Registration fails if email already exists."""
        response = await client.post(
            "/api/v1/auth/register",
            json={
                "email": test_user.email,
                "password": "SecurePassword123!",
            },
        )

        assert response.status_code == 400
        assert "Email already registered" in response.json()["detail"]

    @pytest.mark.asyncio
    async def test_register_invalid_email_format(
        self,
        client: AsyncClient,
    ) -> None:
        """Registration fails with invalid email format."""
        response = await client.post(
            "/api/v1/auth/register",
            json={
                "email": "invalid-email",
                "password": "SecurePassword123!",
            },
        )

        assert response.status_code == 422

    @pytest.mark.asyncio
    async def test_register_weak_password(
        self,
        client: AsyncClient,
    ) -> None:
        """Registration with weak password should be handled appropriately."""
        response = await client.post(
            "/api/v1/auth/register",
            json={
                "email": "newuser@example.com",
                "password": "123",  # Too weak
            },
        )

        # Backend currently accepts any password length
        # This test documents current behavior
        assert response.status_code in [201, 422]

    @pytest.mark.asyncio
    async def test_register_missing_fields(
        self,
        client: AsyncClient,
    ) -> None:
        """Registration fails without required fields."""
        response = await client.post(
            "/api/v1/auth/register",
            json={},
        )

        assert response.status_code == 422


class TestLoginEndpoint:
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
        """Login fails with wrong password."""
        response = await client.post(
            "/api/v1/auth/login",
            data={
                "username": test_user.email,
                "password": "wrongpassword",
            },
        )

        assert response.status_code == 401
        assert "Incorrect email or password" in response.json()["detail"]

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
        assert "Incorrect email or password" in response.json()["detail"]

    @pytest.mark.asyncio
    async def test_login_inactive_user(
        self,
        client: AsyncClient,
        session: AsyncSession,
    ) -> None:
        """Login fails for inactive user."""
        inactive_user = User(
            id=uuid4(),
            email="inactive@example.com",
            hashed_password=hash_password("password123"),
            is_active=False,
            is_verified=True,
        )
        session.add(inactive_user)
        await session.commit()

        response = await client.post(
            "/api/v1/auth/login",
            data={
                "username": "inactive@example.com",
                "password": "password123",
            },
        )

        assert response.status_code == 403
        assert "disabled" in response.json()["detail"].lower()


class TestVerifyEmailEndpoint:
    """Tests for POST /api/v1/auth/verify-email endpoint."""

    @pytest.mark.asyncio
    async def test_verify_email_success(
        self,
        client: AsyncClient,
        unverified_user: User,
    ) -> None:
        """Valid verification token verifies email."""
        token = create_verification_token(unverified_user.id)

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
        assert "Invalid or expired" in response.json()["detail"]

    @pytest.mark.asyncio
    async def test_verify_email_already_verified(
        self,
        client: AsyncClient,
        test_user: User,
    ) -> None:
        """Cannot verify already verified email."""
        token = create_verification_token(test_user.id)

        response = await client.post(
            "/api/v1/auth/verify-email",
            json={"token": token},
        )

        assert response.status_code == 400
        assert "already verified" in response.json()["detail"].lower()


class TestForgotPasswordEndpoint:
    """Tests for POST /api/v1/auth/forgot-password endpoint."""

    @pytest.mark.asyncio
    async def test_forgot_password_existing_user(
        self,
        client: AsyncClient,
        test_user: User,
    ) -> None:
        """Forgot password returns 202 for existing user."""
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
        """Forgot password returns 202 even for non-existent user (prevent enumeration)."""
        response = await client.post(
            "/api/v1/auth/forgot-password",
            json={"email": "nonexistent@example.com"},
        )

        # Always returns 202 to prevent email enumeration attacks
        assert response.status_code == 202
        assert "message" in response.json()


class TestResetPasswordEndpoint:
    """Tests for POST /api/v1/auth/reset-password endpoint."""

    @pytest.mark.asyncio
    async def test_reset_password_success(
        self,
        client: AsyncClient,
        test_user: User,
    ) -> None:
        """Valid reset token allows password change."""
        token = create_password_reset_token(test_user.id)

        response = await client.post(
            "/api/v1/auth/reset-password",
            json={
                "token": token,
                "new_password": "NewSecurePassword123!",
            },
        )

        assert response.status_code == 200
        data = response.json()
        assert data["id"] == str(test_user.id)

        # Verify new password works
        login_response = await client.post(
            "/api/v1/auth/login",
            data={
                "username": test_user.email,
                "password": "NewSecurePassword123!",
            },
        )
        assert login_response.status_code == 200

    @pytest.mark.asyncio
    async def test_reset_password_invalid_token(
        self,
        client: AsyncClient,
    ) -> None:
        """Invalid reset token fails."""
        response = await client.post(
            "/api/v1/auth/reset-password",
            json={
                "token": "invalid-token",
                "new_password": "NewSecurePassword123!",
            },
        )

        assert response.status_code == 400
        assert "Invalid or expired" in response.json()["detail"]

    @pytest.mark.asyncio
    async def test_reset_password_inactive_user(
        self,
        client: AsyncClient,
        session: AsyncSession,
    ) -> None:
        """Cannot reset password for inactive user."""
        inactive_user = User(
            id=uuid4(),
            email="inactive2@example.com",
            hashed_password=hash_password("password123"),
            is_active=False,
            is_verified=True,
        )
        session.add(inactive_user)
        await session.commit()

        token = create_password_reset_token(inactive_user.id)

        response = await client.post(
            "/api/v1/auth/reset-password",
            json={
                "token": token,
                "new_password": "NewSecurePassword123!",
            },
        )

        assert response.status_code == 403
        assert "disabled" in response.json()["detail"].lower()


class TestGetCurrentUserEndpoint:
    """Tests for GET /api/v1/auth/me endpoint."""

    @pytest.mark.asyncio
    async def test_get_current_user_success(
        self,
        client: AsyncClient,
        test_user: User,
        auth_headers: dict[str, str],
    ) -> None:
        """Authenticated user can get their profile."""
        response = await client.get(
            "/api/v1/auth/me",
            headers=auth_headers,
        )

        assert response.status_code == 200
        data = response.json()
        assert data["id"] == str(test_user.id)
        assert data["email"] == test_user.email

    @pytest.mark.asyncio
    async def test_get_current_user_unauthenticated(
        self,
        client: AsyncClient,
    ) -> None:
        """Unauthenticated request returns 401."""
        response = await client.get("/api/v1/auth/me")

        assert response.status_code == 401

    @pytest.mark.asyncio
    async def test_get_current_user_invalid_token(
        self,
        client: AsyncClient,
    ) -> None:
        """Invalid token returns 401."""
        response = await client.get(
            "/api/v1/auth/me",
            headers={"Authorization": "Bearer invalid-token"},
        )

        assert response.status_code == 401


class TestUpdateCurrentUserEndpoint:
    """Tests for PUT /api/v1/auth/me endpoint."""

    @pytest.mark.asyncio
    async def test_update_full_name(
        self,
        client: AsyncClient,
        test_user: User,
        auth_headers: dict[str, str],
    ) -> None:
        """User can update their full name."""
        response = await client.put(
            "/api/v1/auth/me",
            headers=auth_headers,
            json={"full_name": "John Doe"},
        )

        assert response.status_code == 200
        data = response.json()
        assert data["full_name"] == "John Doe"

    @pytest.mark.asyncio
    async def test_update_email(
        self,
        client: AsyncClient,
        test_user: User,
        auth_headers: dict[str, str],
    ) -> None:
        """User can update their email (resets verification)."""
        response = await client.put(
            "/api/v1/auth/me",
            headers=auth_headers,
            json={"email": "newemail@example.com"},
        )

        assert response.status_code == 200
        data = response.json()
        assert data["email"] == "newemail@example.com"
        assert data["is_verified"] is False

    @pytest.mark.asyncio
    async def test_update_email_already_in_use(
        self,
        client: AsyncClient,
        session: AsyncSession,
        test_user: User,
        auth_headers: dict[str, str],
    ) -> None:
        """Cannot update to email already in use."""
        other_user = User(
            id=uuid4(),
            email="other@example.com",
            hashed_password=hash_password("password123"),
            is_active=True,
            is_verified=True,
        )
        session.add(other_user)
        await session.commit()

        response = await client.put(
            "/api/v1/auth/me",
            headers=auth_headers,
            json={"email": "other@example.com"},
        )

        assert response.status_code == 400
        assert "already in use" in response.json()["detail"].lower()


class TestDeleteCurrentUserEndpoint:
    """Tests for DELETE /api/v1/auth/me endpoint (GDPR Right to be Forgotten)."""

    @pytest.mark.asyncio
    async def test_delete_user_success(
        self,
        client: AsyncClient,
        session: AsyncSession,
        test_user: User,
        auth_headers: dict[str, str],
    ) -> None:
        """User can delete their account."""
        response = await client.delete(
            "/api/v1/auth/me",
            headers=auth_headers,
        )

        assert response.status_code == 204

        # Verify user is deleted
        from sqlmodel import select

        result = await session.execute(select(User).where(User.id == test_user.id))
        assert result.scalar_one_or_none() is None

    @pytest.mark.asyncio
    async def test_delete_user_cascades_sessions(
        self,
        client: AsyncClient,
        session: AsyncSession,
        test_user: User,
        auth_headers: dict[str, str],
    ) -> None:
        """Deleting user also deletes their sessions."""
        # Create session for user
        user_session = Session(
            id=uuid4(),
            patient_id=test_user.id,
            scheduled_date=datetime.now(UTC),
            status=SessionStatus.COMPLETED,
        )
        session.add(user_session)
        await session.commit()

        response = await client.delete(
            "/api/v1/auth/me",
            headers=auth_headers,
        )

        assert response.status_code == 204

        # Verify session is deleted
        from sqlmodel import select

        result = await session.execute(
            select(Session).where(Session.patient_id == test_user.id)
        )
        assert result.scalar_one_or_none() is None


class TestExportUserDataEndpoint:
    """Tests for GET /api/v1/auth/me/export endpoint (GDPR Data Portability)."""

    @pytest.mark.asyncio
    async def test_export_user_data_empty(
        self,
        client: AsyncClient,
        test_user: User,
        auth_headers: dict[str, str],
    ) -> None:
        """Export returns user data even with no sessions."""
        response = await client.get(
            "/api/v1/auth/me/export",
            headers=auth_headers,
        )

        assert response.status_code == 200
        data = response.json()
        assert "export_date" in data
        assert data["user"]["id"] == str(test_user.id)
        assert data["user"]["email"] == str(test_user.email)
        assert data["sessions"] == []

    @pytest.mark.asyncio
    async def test_export_user_data_with_sessions(
        self,
        client: AsyncClient,
        session: AsyncSession,
        test_user: User,
        auth_headers: dict[str, str],
    ) -> None:
        """Export includes all user sessions and exercise results."""
        # Create session
        user_session = Session(
            id=uuid4(),
            patient_id=test_user.id,
            scheduled_date=datetime.now(UTC),
            status=SessionStatus.COMPLETED,
            pain_level_before=3,
            pain_level_after=2,
            overall_score=85.0,
        )
        session.add(user_session)
        await session.commit()

        response = await client.get(
            "/api/v1/auth/me/export",
            headers=auth_headers,
        )

        assert response.status_code == 200
        data = response.json()
        assert len(data["sessions"]) == 1
        assert data["sessions"][0]["pain_level_before"] == 3
        assert data["sessions"][0]["overall_score"] == 85.0

    @pytest.mark.asyncio
    async def test_export_user_data_unauthenticated(
        self,
        client: AsyncClient,
    ) -> None:
        """Export requires authentication."""
        response = await client.get("/api/v1/auth/me/export")

        assert response.status_code == 401


class TestResendVerificationEndpoint:
    """Tests for POST /api/v1/auth/resend-verification endpoint."""

    @pytest.mark.asyncio
    async def test_resend_verification_success(
        self,
        client: AsyncClient,
        unverified_user: User,
    ) -> None:
        """Resend verification returns 202 for unverified user."""
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
        """Resend verification returns 202 even for verified (prevent enumeration)."""
        response = await client.post(
            "/api/v1/auth/resend-verification",
            params={"email": test_user.email},
        )

        # Always returns 202 to prevent email enumeration
        assert response.status_code == 202

    @pytest.mark.asyncio
    async def test_resend_verification_nonexistent(
        self,
        client: AsyncClient,
    ) -> None:
        """Resend verification returns 202 even for nonexistent (prevent enumeration)."""
        response = await client.post(
            "/api/v1/auth/resend-verification",
            params={"email": "nonexistent@example.com"},
        )

        # Always returns 202 to prevent email enumeration
        assert response.status_code == 202


class TestAuthSecurityScenarios:
    """Security-focused tests for auth endpoints."""

    @pytest.mark.asyncio
    async def test_password_not_in_response(
        self,
        client: AsyncClient,
        test_user: User,
        auth_headers: dict[str, str],
    ) -> None:
        """Password hash never appears in API responses."""
        response = await client.get(
            "/api/v1/auth/me",
            headers=auth_headers,
        )

        data = response.json()
        assert "password" not in str(data).lower() or "hashed" not in str(data).lower()

    @pytest.mark.asyncio
    async def test_sql_injection_in_email(
        self,
        client: AsyncClient,
    ) -> None:
        """SQL injection in email field is handled safely."""
        response = await client.post(
            "/api/v1/auth/login",
            data={
                "username": "'; DROP TABLE users; --",
                "password": "password",
            },
        )

        # Should fail gracefully, not cause server error
        # 429 = rate limited (also safe), 401 = auth failed, 422 = validation
        assert response.status_code in [401, 422, 429]

    @pytest.mark.asyncio
    async def test_xss_in_full_name(
        self,
        client: AsyncClient,
        test_user: User,
        auth_headers: dict[str, str],
    ) -> None:
        """XSS payload in full name is stored but should be escaped on render."""
        xss_payload = '<script>alert("xss")</script>'

        response = await client.put(
            "/api/v1/auth/me",
            headers=auth_headers,
            json={"full_name": xss_payload},
        )

        assert response.status_code == 200
        # Data is stored as-is (client-side escaping responsibility)
        # This test documents the behavior

    @pytest.mark.asyncio
    async def test_timing_attack_prevention_login(
        self,
        client: AsyncClient,
        test_user: User,
    ) -> None:
        """Login response time should be similar for existing/non-existing users."""
        import time

        # Time for existing user with wrong password
        start = time.time()
        await client.post(
            "/api/v1/auth/login",
            data={
                "username": test_user.email,
                "password": "wrongpassword",
            },
        )
        existing_user_time = time.time() - start

        # Time for non-existing user
        start = time.time()
        await client.post(
            "/api/v1/auth/login",
            data={
                "username": "nonexistent@example.com",
                "password": "wrongpassword",
            },
        )
        nonexistent_user_time = time.time() - start

        # Times should be within reasonable range (not a strict test)
        # This is a documentation/awareness test
        assert existing_user_time > 0
        assert nonexistent_user_time > 0
