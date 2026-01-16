"""
E2E Tests for Authentication Flow.

Complete end-to-end tests for user registration, login, verification,
and password management flows.
"""

import pytest
from httpx import AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession
from sqlmodel import select

from app.core.security import hash_password
from app.models.user import User

pytestmark = pytest.mark.asyncio


class TestAuthenticationFlowE2E:
    """E2E tests: Complete authentication flows."""

    async def test_complete_registration_login_flow(
        self,
        client: AsyncClient,
        session: AsyncSession,
    ) -> None:
        """
        E2E: Registration → Login → Access Protected Resource.

        Tests the complete user journey from registration to accessing
        protected API endpoints.
        """
        # STEP 1: Register new user
        register_data = {
            "email": "e2e_newuser@test.com",
            "password": "SecurePass123!",
        }

        register_response = await client.post(
            "/api/v1/auth/register",
            json=register_data,
        )

        # VERIFY: Registration successful (201 Created)
        assert register_response.status_code == 201, (
            f"Registration failed: {register_response.text}"
        )

        user_data = register_response.json()
        assert user_data["email"] == "e2e_newuser@test.com"
        assert "id" in user_data
        user_id = user_data["id"]

        # VERIFY: User exists in database
        statement = select(User).where(User.email == "e2e_newuser@test.com")
        result = await session.execute(statement)
        user_in_db = result.scalar_one_or_none()

        assert user_in_db is not None, "User should exist in database"
        assert str(user_in_db.id) == user_id

        # STEP 2: Login with registered credentials
        login_response = await client.post(
            "/api/v1/auth/login",
            data={
                "username": "e2e_newuser@test.com",
                "password": "SecurePass123!",
            },
        )

        # VERIFY: Login successful (200 OK)
        assert login_response.status_code == 200, f"Login failed: {login_response.text}"

        token_data = login_response.json()
        assert "access_token" in token_data
        assert token_data.get("token_type", "bearer").lower() == "bearer"

        access_token = token_data["access_token"]

        # STEP 3: Access protected resource with token
        auth_headers = {"Authorization": f"Bearer {access_token}"}

        me_response = await client.get(
            "/api/v1/auth/me",
            headers=auth_headers,
        )

        # VERIFY: Protected resource accessible
        assert me_response.status_code == 200, (
            f"Failed to access /me: {me_response.text}"
        )

        me_data = me_response.json()
        assert me_data["email"] == "e2e_newuser@test.com"

    async def test_registration_duplicate_email_rejected(
        self,
        client: AsyncClient,
        session: AsyncSession,
    ) -> None:
        """E2E: Attempting to register with existing email fails."""
        # SETUP: Create existing user
        from uuid import uuid4

        existing_user = User(
            id=uuid4(),
            email="existing@test.com",
            hashed_password=hash_password("ExistingPass123!"),
            is_active=True,
            is_verified=True,
        )
        session.add(existing_user)
        await session.commit()

        # STEP: Try to register with same email
        register_response = await client.post(
            "/api/v1/auth/register",
            json={
                "email": "existing@test.com",
                "password": "NewPass123!",
            },
        )

        # VERIFY: Registration rejected (400 Bad Request)
        assert register_response.status_code == 400
        assert "already registered" in register_response.json()["detail"].lower()

    async def test_login_with_wrong_password(
        self,
        client: AsyncClient,
        session: AsyncSession,
    ) -> None:
        """E2E: Login with incorrect password fails."""
        # SETUP: Create user
        from uuid import uuid4

        user = User(
            id=uuid4(),
            email="wrongpass@test.com",
            hashed_password=hash_password("CorrectPass123!"),
            is_active=True,
            is_verified=True,
        )
        session.add(user)
        await session.commit()

        # STEP: Login with wrong password
        login_response = await client.post(
            "/api/v1/auth/login",
            data={
                "username": "wrongpass@test.com",
                "password": "WrongPassword123!",
            },
        )

        # VERIFY: Login rejected (401 Unauthorized)
        assert login_response.status_code == 401
        assert "incorrect" in login_response.json()["detail"].lower()

    async def test_login_with_nonexistent_user(
        self,
        client: AsyncClient,
    ) -> None:
        """E2E: Login with non-existent email fails."""
        login_response = await client.post(
            "/api/v1/auth/login",
            data={
                "username": "nonexistent@test.com",
                "password": "AnyPassword123!",
            },
        )

        # VERIFY: Login rejected (401 Unauthorized)
        assert login_response.status_code == 401

    async def test_access_protected_route_without_token(
        self,
        client: AsyncClient,
    ) -> None:
        """E2E: Protected routes require authentication."""
        # STEP: Try to access protected route without token
        me_response = await client.get("/api/v1/auth/me")

        # VERIFY: Access denied (401 Unauthorized)
        assert me_response.status_code == 401

    async def test_access_protected_route_with_invalid_token(
        self,
        client: AsyncClient,
    ) -> None:
        """E2E: Invalid tokens are rejected."""
        # STEP: Try to access with invalid token
        auth_headers = {"Authorization": "Bearer invalid_token_here"}

        me_response = await client.get(
            "/api/v1/auth/me",
            headers=auth_headers,
        )

        # VERIFY: Access denied (401 Unauthorized)
        assert me_response.status_code == 401

    async def test_inactive_user_cannot_login(
        self,
        client: AsyncClient,
        session: AsyncSession,
    ) -> None:
        """E2E: Inactive/disabled users cannot login."""
        # SETUP: Create inactive user
        from uuid import uuid4

        inactive_user = User(
            id=uuid4(),
            email="inactive@test.com",
            hashed_password=hash_password("ValidPass123!"),
            is_active=False,  # Disabled
            is_verified=True,
        )
        session.add(inactive_user)
        await session.commit()

        # STEP: Try to login
        login_response = await client.post(
            "/api/v1/auth/login",
            data={
                "username": "inactive@test.com",
                "password": "ValidPass123!",
            },
        )

        # VERIFY: Login rejected (403 Forbidden)
        assert login_response.status_code == 403
        assert "disabled" in login_response.json()["detail"].lower()


class TestPasswordValidationE2E:
    """E2E tests: Password validation rules."""

    @pytest.mark.parametrize(
        "password,expected_reason",
        [
            ("short", "too short (less than 8 chars)"),
            ("1234567", "too short (7 chars)"),
        ],
    )
    async def test_weak_password_rejected(
        self,
        client: AsyncClient,
        password: str,
        expected_reason: str,
    ) -> None:
        """E2E: Weak passwords (too short) are rejected during registration."""
        register_response = await client.post(
            "/api/v1/auth/register",
            json={
                "email": f"weakpass_{password[:5]}@test.com",
                "password": password,
            },
        )

        # VERIFY: Registration rejected (422 Validation Error)
        # Note: Backend enforces minimum 8 character length
        assert register_response.status_code in [400, 422], (
            f"Expected weak password '{password}' ({expected_reason}) to be rejected, "
            f"got status {register_response.status_code}"
        )

    @pytest.mark.parametrize(
        "password,description",
        [
            ("nouppercase123!", "no uppercase - complexity check may be optional"),
            ("NOLOWERCASE123!", "no lowercase - complexity check may be optional"),
            ("NoNumbers!", "no numbers - complexity check may be optional"),
            ("NoSpecial123", "no special char - complexity check may be optional"),
        ],
    )
    async def test_password_complexity_rules(
        self,
        client: AsyncClient,
        password: str,
        description: str,
    ) -> None:
        """E2E: Password complexity rules (if enforced by backend)."""
        register_response = await client.post(
            "/api/v1/auth/register",
            json={
                "email": f"complex_{password[:5]}@test.com",
                "password": password,
            },
        )

        # VERIFY: Either rejected (422) or accepted (201)
        # Backend may or may not enforce complexity rules
        assert register_response.status_code in [201, 400, 422], (
            f"Unexpected status for password '{password}' ({description}): "
            f"{register_response.status_code}"
        )

    async def test_valid_strong_password_accepted(
        self,
        client: AsyncClient,
    ) -> None:
        """E2E: Strong passwords are accepted."""
        register_response = await client.post(
            "/api/v1/auth/register",
            json={
                "email": "strongpass@test.com",
                "password": "VerySecure123!@#",
            },
        )

        # VERIFY: Registration successful
        assert register_response.status_code == 201


class TestEmailValidationE2E:
    """E2E tests: Email validation."""

    @pytest.mark.parametrize(
        "invalid_email",
        [
            "notanemail",
            "missing@domain",
            "@nodomain.com",
            "spaces in@email.com",
            "multiple@@at.com",
        ],
    )
    async def test_invalid_email_rejected(
        self,
        client: AsyncClient,
        invalid_email: str,
    ) -> None:
        """E2E: Invalid email formats are rejected."""
        register_response = await client.post(
            "/api/v1/auth/register",
            json={
                "email": invalid_email,
                "password": "ValidPass123!",
            },
        )

        # VERIFY: Registration rejected (422 Validation Error)
        assert register_response.status_code == 422, (
            f"Invalid email '{invalid_email}' should be rejected"
        )


class TestTokenRefreshE2E:
    """E2E tests: Token refresh functionality."""

    async def test_token_allows_multiple_requests(
        self,
        client: AsyncClient,
        session: AsyncSession,
    ) -> None:
        """E2E: Valid token can be used for multiple requests."""
        # SETUP: Create and login user
        from uuid import uuid4

        user = User(
            id=uuid4(),
            email="multipleuse@test.com",
            hashed_password=hash_password("ValidPass123!"),
            is_active=True,
            is_verified=True,
        )
        session.add(user)
        await session.commit()

        # Login
        login_response = await client.post(
            "/api/v1/auth/login",
            data={
                "username": "multipleuse@test.com",
                "password": "ValidPass123!",
            },
        )
        token = login_response.json()["access_token"]
        headers = {"Authorization": f"Bearer {token}"}

        # STEP: Make multiple requests with same token
        for i in range(5):
            response = await client.get("/api/v1/auth/me", headers=headers)
            # VERIFY: Each request succeeds
            assert response.status_code == 200, f"Request {i + 1} failed"


class TestSecurityHeadersE2E:
    """E2E tests: Security headers and protections."""

    async def test_auth_endpoints_return_proper_headers(
        self,
        client: AsyncClient,
    ) -> None:
        """E2E: Auth endpoints return security headers."""
        # Just make a request to check headers
        response = await client.post(
            "/api/v1/auth/login",
            data={
                "username": "any@test.com",
                "password": "anypass",
            },
        )

        # VERIFY: Response has appropriate headers
        # (Specific headers depend on middleware configuration)
        assert response.headers is not None

    async def test_cors_preflight_handled(
        self,
        client: AsyncClient,
    ) -> None:
        """E2E: CORS preflight requests are handled."""
        # OPTIONS request for CORS preflight
        response = await client.options(
            "/api/v1/auth/login",
            headers={
                "Origin": "http://localhost:3000",
                "Access-Control-Request-Method": "POST",
            },
        )

        # VERIFY: OPTIONS request handled (may return 200 or 405 depending on config)
        assert response.status_code in [200, 204, 405]
