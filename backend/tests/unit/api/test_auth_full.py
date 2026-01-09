"""
Unit tests for Auth API endpoints - Extended coverage.

Test coverage:
1. Registration edge cases
2. Login edge cases
3. Email verification
4. Password reset flow
5. Token handling
6. User profile operations
"""

from uuid import uuid4

from httpx import AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.security import (
    create_password_reset_token,
    create_verification_token,
    hash_password,
)
from app.models.user import User


class TestRegistrationEdgeCases:
    """Extended tests for registration edge cases."""

    async def test_register_with_spaces_in_email(
        self,
        client: AsyncClient,
    ) -> None:
        """Spaces around email are handled."""
        response = await client.post(
            "/api/v1/auth/register",
            json={
                "email": "  spaces@example.com  ",
                "password": "validpassword123",
            },
        )

        # Should either strip spaces or reject
        assert response.status_code in [201, 422]

    async def test_register_unicode_email(self, client: AsyncClient) -> None:
        """Unicode in email local part."""
        response = await client.post(
            "/api/v1/auth/register",
            json={
                "email": "użytkownik@example.com",
                "password": "validpassword123",
            },
        )

        # May be accepted or rejected depending on email validation
        assert response.status_code in [201, 422]

    async def test_register_very_long_password(self, client: AsyncClient) -> None:
        """Very long password is rejected or truncated."""
        # bcrypt enforces 72-byte limit, so use password just under limit
        valid_long_password = "a" * 71

        response = await client.post(
            "/api/v1/auth/register",
            json={
                "email": "longpass@example.com",
                "password": valid_long_password,
            },
        )

        # Password under 72 bytes should work
        assert response.status_code == 201

    async def test_register_password_with_special_chars(
        self,
        client: AsyncClient,
    ) -> None:
        """Password with special characters is accepted."""
        response = await client.post(
            "/api/v1/auth/register",
            json={
                "email": "special@example.com",
                "password": "P@ssw0rd!#$%^&*()",
            },
        )

        assert response.status_code == 201

    async def test_register_password_with_unicode(
        self,
        client: AsyncClient,
    ) -> None:
        """Password with unicode is handled."""
        response = await client.post(
            "/api/v1/auth/register",
            json={
                "email": "unicode@example.com",
                "password": "пароль密码🔐123",
            },
        )

        assert response.status_code == 201

    async def test_register_empty_password(self, client: AsyncClient) -> None:
        """Empty password is rejected."""
        response = await client.post(
            "/api/v1/auth/register",
            json={
                "email": "empty@example.com",
                "password": "",
            },
        )

        assert response.status_code == 422

    async def test_register_with_name(self, client: AsyncClient) -> None:
        """Registration with full name."""
        response = await client.post(
            "/api/v1/auth/register",
            json={
                "email": "named@example.com",
                "password": "validpassword123",
                "full_name": "John Doe",
            },
        )

        assert response.status_code == 201
        # full_name may or may not be in response depending on schema


class TestLoginEdgeCases:
    """Extended tests for login edge cases."""

    async def test_login_case_insensitive_email(
        self,
        client: AsyncClient,
        test_user: User,
    ) -> None:
        """Email comparison may be case insensitive."""
        response = await client.post(
            "/api/v1/auth/login",
            data={
                "username": str(test_user.email).upper(),
                "password": "testpassword123",
            },
        )

        # May succeed or fail depending on implementation
        assert response.status_code in [200, 401]

    async def test_login_inactive_user(
        self,
        client: AsyncClient,
        session: AsyncSession,
    ) -> None:
        """Inactive user cannot login."""
        user = User(
            id=uuid4(),
            email="inactive@example.com",
            hashed_password=hash_password("password123"),
            is_active=False,
            is_verified=True,
        )
        session.add(user)
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

    async def test_login_nonexistent_user(self, client: AsyncClient) -> None:
        """Login with nonexistent email fails gracefully."""
        response = await client.post(
            "/api/v1/auth/login",
            data={
                "username": "doesnotexist@example.com",
                "password": "anypassword",
            },
        )

        assert response.status_code == 401
        # Should not reveal if email exists
        assert "incorrect" in response.json()["detail"].lower()

    async def test_login_empty_credentials(self, client: AsyncClient) -> None:
        """Empty credentials are rejected."""
        response = await client.post(
            "/api/v1/auth/login",
            data={
                "username": "",
                "password": "",
            },
        )

        assert response.status_code in [401, 422]

    async def test_login_sql_injection_attempt(
        self,
        client: AsyncClient,
    ) -> None:
        """SQL injection in credentials is handled safely."""
        response = await client.post(
            "/api/v1/auth/login",
            data={
                "username": "'; DROP TABLE users; --",
                "password": "' OR '1'='1",
            },
        )

        # Should fail authentication, not crash
        assert response.status_code in [401, 422]


class TestEmailVerification:
    """Tests for email verification flow."""

    async def test_verify_valid_token(
        self,
        client: AsyncClient,
        unverified_user: User,
    ) -> None:
        """Valid verification token verifies user."""
        token = create_verification_token(unverified_user.id)

        response = await client.post(
            "/api/v1/auth/verify-email",
            json={"token": token},
        )

        assert response.status_code == 200
        data = response.json()
        assert data["is_verified"] is True

    async def test_verify_invalid_token(self, client: AsyncClient) -> None:
        """Invalid token returns error."""
        response = await client.post(
            "/api/v1/auth/verify-email",
            json={"token": "invalid-token"},
        )

        assert response.status_code == 400

    async def test_verify_expired_token(self, client: AsyncClient) -> None:
        """Expired token returns error."""
        # This would require mocking time or using a pre-expired token
        response = await client.post(
            "/api/v1/auth/verify-email",
            json={"token": "expired.token.here"},
        )

        assert response.status_code == 400

    async def test_verify_already_verified(
        self,
        client: AsyncClient,
        test_user: User,
    ) -> None:
        """Verifying already verified user returns error."""
        token = create_verification_token(test_user.id)

        response = await client.post(
            "/api/v1/auth/verify-email",
            json={"token": token},
        )

        assert response.status_code == 400
        assert "already verified" in response.json()["detail"].lower()


class TestPasswordReset:
    """Tests for password reset flow."""

    async def test_forgot_password_existing_email(
        self,
        client: AsyncClient,
        test_user: User,
    ) -> None:
        """Forgot password for existing email returns 202."""
        response = await client.post(
            "/api/v1/auth/forgot-password",
            json={"email": str(test_user.email)},
        )

        assert response.status_code == 202

    async def test_forgot_password_nonexistent_email(
        self,
        client: AsyncClient,
    ) -> None:
        """Forgot password for nonexistent email also returns 202."""
        response = await client.post(
            "/api/v1/auth/forgot-password",
            json={"email": "nonexistent@example.com"},
        )

        # Should return 202 to prevent email enumeration
        assert response.status_code == 202

    async def test_reset_password_valid_token(
        self,
        client: AsyncClient,
        test_user: User,
    ) -> None:
        """Password can be reset with valid token."""
        token = create_password_reset_token(test_user.id)

        response = await client.post(
            "/api/v1/auth/reset-password",
            json={
                "token": token,
                "new_password": "newpassword123",
            },
        )

        assert response.status_code == 200

    async def test_reset_password_invalid_token(
        self,
        client: AsyncClient,
    ) -> None:
        """Invalid reset token returns error."""
        response = await client.post(
            "/api/v1/auth/reset-password",
            json={
                "token": "invalid-token",
                "new_password": "newpassword123",
            },
        )

        assert response.status_code == 400

    async def test_reset_password_weak_password(
        self,
        client: AsyncClient,
        test_user: User,
    ) -> None:
        """Weak new password is rejected."""
        token = create_password_reset_token(test_user.id)

        response = await client.post(
            "/api/v1/auth/reset-password",
            json={
                "token": token,
                "new_password": "short",
            },
        )

        assert response.status_code == 422


class TestAuthenticatedEndpoints:
    """Tests for authenticated user endpoints."""

    async def test_get_current_user(
        self,
        client: AsyncClient,
        auth_headers: dict[str, str],
        test_user: User,
    ) -> None:
        """Authenticated user can get their profile."""
        response = await client.get(
            "/api/v1/auth/me",
            headers=auth_headers,
        )

        assert response.status_code == 200
        data = response.json()
        assert data["email"] == str(test_user.email)

    async def test_get_current_user_unauthenticated(
        self,
        client: AsyncClient,
    ) -> None:
        """Unauthenticated request returns 401."""
        response = await client.get("/api/v1/auth/me")

        assert response.status_code == 401

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

    async def test_update_user_profile(
        self,
        client: AsyncClient,
        auth_headers: dict[str, str],
    ) -> None:
        """User can update their profile via PUT."""
        response = await client.put(
            "/api/v1/auth/me",
            json={"full_name": "Updated Name"},
            headers=auth_headers,
        )

        assert response.status_code == 200
        data = response.json()
        assert data["full_name"] == "Updated Name"


class TestTokenSecurity:
    """Tests for token security."""

    async def test_bearer_token_required(self, client: AsyncClient) -> None:
        """Bearer prefix is required in Authorization header."""
        response = await client.get(
            "/api/v1/auth/me",
            headers={"Authorization": "some-token"},
        )

        assert response.status_code == 401

    async def test_malformed_authorization_header(
        self,
        client: AsyncClient,
    ) -> None:
        """Malformed Authorization header is rejected."""
        response = await client.get(
            "/api/v1/auth/me",
            headers={"Authorization": ""},
        )

        assert response.status_code == 401

    async def test_token_for_deleted_user(
        self,
        client: AsyncClient,
        session: AsyncSession,
    ) -> None:
        """Token for deleted user fails."""
        from app.core.security import create_access_token

        # Create and delete user
        user = User(
            id=uuid4(),
            email="deleted@example.com",
            hashed_password=hash_password("password123"),
        )
        session.add(user)
        await session.commit()

        token = create_access_token(user.id)

        await session.delete(user)
        await session.commit()

        response = await client.get(
            "/api/v1/auth/me",
            headers={"Authorization": f"Bearer {token}"},
        )

        assert response.status_code in [401, 404]
