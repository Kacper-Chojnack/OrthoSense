"""Tests for authentication endpoints."""

from httpx import AsyncClient

from app.core.security import (
    create_password_reset_token,
    create_verification_token,
)
from app.models.user import User


class TestUserRegistration:
    """Test user registration flow."""

    async def test_register_success(self, client: AsyncClient) -> None:
        """POST /auth/register creates new user."""
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
        assert data["is_active"] is True
        assert data["is_verified"] is False
        assert "id" in data

    async def test_register_duplicate_email(
        self,
        client: AsyncClient,
        test_user: User,
    ) -> None:
        """POST /auth/register fails for existing email."""
        response = await client.post(
            "/api/v1/auth/register",
            json={
                "email": str(test_user.email),
                "password": "anotherpassword123",
            },
        )

        assert response.status_code == 400
        assert "already registered" in response.json()["detail"]

    async def test_register_weak_password(self, client: AsyncClient) -> None:
        """POST /auth/register rejects weak passwords."""
        response = await client.post(
            "/api/v1/auth/register",
            json={
                "email": "weak@example.com",
                "password": "short",
            },
        )

        assert response.status_code == 422

    async def test_register_invalid_email(self, client: AsyncClient) -> None:
        """POST /auth/register rejects invalid emails."""
        response = await client.post(
            "/api/v1/auth/register",
            json={
                "email": "not-an-email",
                "password": "validpassword123",
            },
        )

        assert response.status_code == 422


class TestUserLogin:
    """Test user login flow."""

    async def test_login_success(
        self,
        client: AsyncClient,
        test_user: User,
    ) -> None:
        """POST /auth/login returns access token."""
        response = await client.post(
            "/api/v1/auth/login",
            data={
                "username": str(test_user.email),
                "password": "testpassword123",
            },
        )

        assert response.status_code == 200
        data = response.json()
        assert "access_token" in data
        assert data["token_type"] == "bearer"

    async def test_login_wrong_password(
        self,
        client: AsyncClient,
        test_user: User,
    ) -> None:
        """POST /auth/login fails with wrong password."""
        response = await client.post(
            "/api/v1/auth/login",
            data={
                "username": str(test_user.email),
                "password": "wrongpassword",
            },
        )

        assert response.status_code == 401
        assert "Incorrect" in response.json()["detail"]

    async def test_login_nonexistent_user(self, client: AsyncClient) -> None:
        """POST /auth/login fails for unknown email."""
        response = await client.post(
            "/api/v1/auth/login",
            data={
                "username": "nobody@example.com",
                "password": "somepassword123",
            },
        )

        assert response.status_code == 401


class TestEmailVerification:
    """Test email verification flow."""

    async def test_verify_email_success(
        self,
        client: AsyncClient,
        unverified_user: User,
    ) -> None:
        """POST /auth/verify-email activates user."""
        token = create_verification_token(unverified_user.id)

        response = await client.post(
            "/api/v1/auth/verify-email",
            json={"token": token},
        )

        assert response.status_code == 200
        data = response.json()
        assert data["is_verified"] is True

    async def test_verify_email_invalid_token(self, client: AsyncClient) -> None:
        """POST /auth/verify-email rejects invalid token."""
        response = await client.post(
            "/api/v1/auth/verify-email",
            json={"token": "invalid-token"},
        )

        assert response.status_code == 400

    async def test_verify_email_already_verified(
        self,
        client: AsyncClient,
        test_user: User,
    ) -> None:
        """POST /auth/verify-email fails if already verified."""
        token = create_verification_token(test_user.id)

        response = await client.post(
            "/api/v1/auth/verify-email",
            json={"token": token},
        )

        assert response.status_code == 400
        assert "already verified" in response.json()["detail"]


class TestPasswordReset:
    """Test password reset flow."""

    async def test_forgot_password_existing_user(
        self,
        client: AsyncClient,
        test_user: User,
    ) -> None:
        """POST /auth/forgot-password succeeds for existing user."""
        response = await client.post(
            "/api/v1/auth/forgot-password",
            json={"email": str(test_user.email)},
        )

        assert response.status_code == 202

    async def test_forgot_password_nonexistent_user(
        self,
        client: AsyncClient,
    ) -> None:
        """POST /auth/forgot-password returns same response for unknown email."""
        response = await client.post(
            "/api/v1/auth/forgot-password",
            json={"email": "nobody@example.com"},
        )

        # Same response to prevent email enumeration
        assert response.status_code == 202

    async def test_reset_password_success(
        self,
        client: AsyncClient,
        test_user: User,
    ) -> None:
        """POST /auth/reset-password updates password."""
        token = create_password_reset_token(test_user.id)

        response = await client.post(
            "/api/v1/auth/reset-password",
            json={
                "token": token,
                "new_password": "newpassword123",
            },
        )

        assert response.status_code == 200

        # Verify new password works
        login_response = await client.post(
            "/api/v1/auth/login",
            data={
                "username": str(test_user.email),
                "password": "newpassword123",
            },
        )
        assert login_response.status_code == 200

    async def test_reset_password_invalid_token(self, client: AsyncClient) -> None:
        """POST /auth/reset-password rejects invalid token."""
        response = await client.post(
            "/api/v1/auth/reset-password",
            json={
                "token": "invalid-token",
                "new_password": "newpassword123",
            },
        )

        assert response.status_code == 400


class TestCurrentUser:
    """Test current user endpoint."""

    async def test_get_me_authenticated(
        self,
        client: AsyncClient,
        test_user: User,
        auth_headers: dict[str, str],
    ) -> None:
        """GET /auth/me returns current user."""
        response = await client.get(
            "/api/v1/auth/me",
            headers=auth_headers,
        )

        assert response.status_code == 200
        data = response.json()
        assert data["email"] == str(test_user.email)
        assert data["id"] == str(test_user.id)

    async def test_get_me_unauthenticated(self, client: AsyncClient) -> None:
        """GET /auth/me fails without token."""
        response = await client.get("/api/v1/auth/me")

        assert response.status_code == 401

    async def test_get_me_invalid_token(self, client: AsyncClient) -> None:
        """GET /auth/me fails with invalid token."""
        response = await client.get(
            "/api/v1/auth/me",
            headers={"Authorization": "Bearer invalid-token"},
        )

        assert response.status_code == 401
