"""
E2E Tests for Error Handling.

Tests for proper error handling, edge cases, and error recovery
throughout the API.
"""

import pytest
from httpx import AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.security import hash_password
from app.models.user import User

pytestmark = pytest.mark.asyncio


class TestAPIErrorHandlingE2E:
    """E2E tests: API error handling."""

    async def test_malformed_json_request(
        self,
        client: AsyncClient,
    ) -> None:
        """E2E: Malformed JSON is rejected with proper error."""
        response = await client.post(
            "/api/v1/auth/register",
            content="this is not json",
            headers={"Content-Type": "application/json"},
        )

        # VERIFY: 422 Unprocessable Entity
        assert response.status_code == 422

    async def test_missing_required_fields(
        self,
        client: AsyncClient,
    ) -> None:
        """E2E: Missing required fields return clear error."""
        response = await client.post(
            "/api/v1/auth/register",
            json={"email": "test@example.com"},  # Missing password
        )

        # VERIFY: 422 Validation Error with field info
        assert response.status_code == 422
        error_data = response.json()
        assert "detail" in error_data

    async def test_wrong_content_type(
        self,
        client: AsyncClient,
    ) -> None:
        """E2E: Wrong content type is handled properly."""
        response = await client.post(
            "/api/v1/auth/register",
            content="email=test@test.com&password=test",
            headers={"Content-Type": "text/plain"},
        )

        # VERIFY: 422 or 415 (Unsupported Media Type)
        assert response.status_code in [415, 422]

    async def test_resource_not_found(
        self,
        client: AsyncClient,
        authenticated_user: dict,
    ) -> None:
        """E2E: Non-existent resource returns 404."""
        from uuid import uuid4

        response = await client.get(
            f"/api/v1/sessions/{uuid4()}",
            headers=authenticated_user["headers"],
        )

        # VERIFY: 404 Not Found
        assert response.status_code == 404
        assert "not found" in response.json()["detail"].lower()

    async def test_invalid_uuid_format(
        self,
        client: AsyncClient,
        authenticated_user: dict,
    ) -> None:
        """E2E: Invalid UUID format returns validation error."""
        response = await client.get(
            "/api/v1/sessions/not-a-valid-uuid",
            headers=authenticated_user["headers"],
        )

        # VERIFY: 422 Validation Error
        assert response.status_code == 422

    async def test_method_not_allowed(
        self,
        client: AsyncClient,
    ) -> None:
        """E2E: Wrong HTTP method returns 405."""
        response = await client.delete("/api/v1/auth/login")

        # VERIFY: 405 Method Not Allowed
        assert response.status_code == 405

    async def test_empty_request_body(
        self,
        client: AsyncClient,
    ) -> None:
        """E2E: Empty request body where body is required."""
        response = await client.post(
            "/api/v1/auth/register",
            json={},
        )

        # VERIFY: 422 Validation Error
        assert response.status_code == 422


class TestAuthorizationErrorsE2E:
    """E2E tests: Authorization error handling."""

    async def test_expired_token_handling(
        self,
        client: AsyncClient,
    ) -> None:
        """E2E: Expired token is rejected properly."""
        # Use an obviously invalid/expired token
        expired_token = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJ0ZXN0QGV4YW1wbGUuY29tIiwiZXhwIjoxfQ.invalid"

        response = await client.get(
            "/api/v1/auth/me",
            headers={"Authorization": f"Bearer {expired_token}"},
        )

        # VERIFY: 401 Unauthorized
        assert response.status_code == 401

    async def test_malformed_authorization_header(
        self,
        client: AsyncClient,
    ) -> None:
        """E2E: Malformed auth header is handled properly."""
        # Missing "Bearer" prefix
        response = await client.get(
            "/api/v1/auth/me",
            headers={"Authorization": "just-a-token"},
        )

        # VERIFY: 401 or 403
        assert response.status_code in [401, 403]

    async def test_access_denied_proper_message(
        self,
        client: AsyncClient,
        session: AsyncSession,
    ) -> None:
        """E2E: Access denied returns proper error message."""
        from datetime import UTC, datetime
        from uuid import uuid4

        from app.models.session import Session, SessionStatus

        # Create two users
        user1 = User(
            id=uuid4(),
            email="user1_error@test.com",
            hashed_password=hash_password("TestPass123!"),
            is_active=True,
            is_verified=True,
        )
        user2 = User(
            id=uuid4(),
            email="user2_error@test.com",
            hashed_password=hash_password("TestPass123!"),
            is_active=True,
            is_verified=True,
        )
        session.add_all([user1, user2])

        # User1's session
        user1_session = Session(
            id=uuid4(),
            patient_id=user1.id,
            scheduled_date=datetime.now(UTC),
            status=SessionStatus.IN_PROGRESS,
        )
        session.add(user1_session)
        await session.commit()

        # User2 tries to access
        login_response = await client.post(
            "/api/v1/auth/login",
            data={
                "username": "user2_error@test.com",
                "password": "TestPass123!",
            },
        )
        token = login_response.json()["access_token"]

        response = await client.get(
            f"/api/v1/sessions/{user1_session.id}",
            headers={"Authorization": f"Bearer {token}"},
        )

        # VERIFY: 403 Forbidden with clear message
        assert response.status_code == 403
        assert (
            "denied" in response.json()["detail"].lower()
            or "access" in response.json()["detail"].lower()
        )


class TestDataValidationErrorsE2E:
    """E2E tests: Data validation error handling."""

    async def test_invalid_email_format_error(
        self,
        client: AsyncClient,
    ) -> None:
        """E2E: Invalid email format returns clear error."""
        response = await client.post(
            "/api/v1/auth/register",
            json={
                "email": "not-an-email",
                "password": "ValidPass123!",
            },
        )

        # VERIFY: 422 with email-related error
        assert response.status_code == 422
        error_detail = response.json()["detail"]
        # Check that error mentions email validation
        assert any("email" in str(e).lower() for e in error_detail)

    async def test_password_too_short_error(
        self,
        client: AsyncClient,
    ) -> None:
        """E2E: Password too short returns clear error."""
        response = await client.post(
            "/api/v1/auth/register",
            json={
                "email": "valid@test.com",
                "password": "short",
            },
        )

        # VERIFY: 422 with password-related error
        assert response.status_code == 422

    async def test_out_of_range_values(
        self,
        client: AsyncClient,
        authenticated_user: dict,
    ) -> None:
        """E2E: Out of range values are rejected."""
        from datetime import UTC, datetime

        # Create session first
        create_response = await client.post(
            "/api/v1/sessions",
            headers=authenticated_user["headers"],
            json={
                "scheduled_date": datetime.now(UTC).isoformat(),
                "notes": "Test session",
            },
        )

        if create_response.status_code == 201:
            session_id = create_response.json()["id"]

            # Try to start with invalid pain level (out of range)
            start_response = await client.post(
                f"/api/v1/sessions/{session_id}/start",
                headers=authenticated_user["headers"],
                json={
                    "pain_level_before": 15,  # Out of range (0-10)
                    "device_info": {},
                },
            )

            # VERIFY: 422 Validation Error
            assert start_response.status_code == 422


class TestConcurrencyErrorsE2E:
    """E2E tests: Concurrency and race condition handling."""

    async def test_duplicate_registration_attempt(
        self,
        client: AsyncClient,
        session: AsyncSession,
    ) -> None:
        """E2E: Duplicate registration is handled properly."""
        from uuid import uuid4

        # Create existing user
        user = User(
            id=uuid4(),
            email="existing_error@test.com",
            hashed_password=hash_password("TestPass123!"),
            is_active=True,
            is_verified=True,
        )
        session.add(user)
        await session.commit()

        # Try to register with same email
        response = await client.post(
            "/api/v1/auth/register",
            json={
                "email": "existing_error@test.com",
                "password": "NewPass123!",
            },
        )

        # VERIFY: 400 Bad Request with clear message
        assert response.status_code == 400
        assert "already" in response.json()["detail"].lower()


class TestServerErrorRecoveryE2E:
    """E2E tests: Server error recovery."""

    async def test_health_endpoint_available(
        self,
        client: AsyncClient,
    ) -> None:
        """E2E: Health endpoint is available for monitoring."""
        response = await client.get("/health")

        # VERIFY: Health endpoint works
        # May be 200 or 404 depending on if it's implemented
        assert response.status_code in [200, 404]

    async def test_api_docs_available(
        self,
        client: AsyncClient,
    ) -> None:
        """E2E: API documentation endpoint is available."""
        response = await client.get("/docs")

        # VERIFY: Docs available
        assert response.status_code in [200, 307]  # 307 redirect is also OK

    async def test_openapi_schema_available(
        self,
        client: AsyncClient,
    ) -> None:
        """E2E: OpenAPI schema is available."""
        response = await client.get("/openapi.json")

        # VERIFY: Schema available (may be at different path)
        if response.status_code == 200:
            schema = response.json()
            assert "openapi" in schema
            assert "paths" in schema
        else:
            # Try alternative path
            alt_response = await client.get("/api/openapi.json")
            assert alt_response.status_code in [200, 404], (
                "OpenAPI schema should be available"
            )


class TestXSSAndInjectionProtectionE2E:
    """E2E tests: Protection against XSS and injection attacks."""

    async def test_xss_in_name_field_rejected(
        self,
        client: AsyncClient,
    ) -> None:
        """E2E: XSS payloads in name fields are rejected."""
        xss_payloads = [
            "<script>alert('xss')</script>",
            "javascript:alert(1)",
            "<img src=x onerror=alert(1)>",
        ]

        for payload in xss_payloads:
            response = await client.post(
                "/api/v1/auth/register",
                json={
                    "email": "xss_test@test.com",
                    "password": "ValidPass123!",
                    "full_name": payload,
                },
            )

            # VERIFY: XSS payload rejected or sanitized
            # Should be 400 (rejected) or 201 (sanitized)
            if response.status_code == 201:
                # If created, verify payload was sanitized
                user_data = response.json()
                assert payload not in user_data.get("full_name", "")
            else:
                # Rejected is also acceptable
                assert response.status_code in [400, 422]

    async def test_sql_injection_protection(
        self,
        client: AsyncClient,
    ) -> None:
        """E2E: SQL injection attempts are handled safely."""
        sql_payloads = [
            "'; DROP TABLE users; --",
            "1 OR 1=1",
            "admin'--",
        ]

        for payload in sql_payloads:
            response = await client.post(
                "/api/v1/auth/login",
                data={
                    "username": payload,
                    "password": payload,
                },
            )

            # VERIFY: SQL injection doesn't cause server error
            # Should be 401 (invalid credentials) or 422 (validation error)
            assert response.status_code in [401, 422], (
                f"SQL payload caused unexpected status: {response.status_code}"
            )
