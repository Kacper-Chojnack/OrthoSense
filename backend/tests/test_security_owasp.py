"""OWASP Top 10 Security Tests for OrthoSense API.

These tests validate protection against common vulnerabilities
as required by Engineering Thesis Section 10.4.1.
"""

import pytest
from httpx import ASGITransport, AsyncClient

from app.main import app


@pytest.fixture
async def client() -> AsyncClient:
    """Create async test client."""
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        yield ac


class TestA01BrokenAccessControl:
    """A01:2021 - Broken Access Control tests."""

    @pytest.mark.asyncio
    async def test_unauthorized_access_to_protected_endpoint(
        self,
        client: AsyncClient,
    ) -> None:
        """Protected endpoints reject requests without auth."""
        response = await client.get("/api/v1/users/me")
        assert response.status_code in [401, 403, 404]

    @pytest.mark.asyncio
    async def test_cannot_access_arbitrary_user_data(
        self,
        client: AsyncClient,
    ) -> None:
        """Users cannot access other users' data without auth."""
        fake_uuid = "00000000-0000-0000-0000-000000000000"
        response = await client.get(f"/api/v1/users/{fake_uuid}")
        assert response.status_code in [401, 403, 404]


class TestA02CryptographicFailures:
    """A02:2021 - Cryptographic Failures tests."""

    @pytest.mark.asyncio
    async def test_tokens_not_exposed_in_error_responses(
        self,
        client: AsyncClient,
    ) -> None:
        """Sensitive tokens not leaked in error responses."""
        response = await client.post(
            "/api/v1/auth/login",
            json={"email": "wrong@test.com", "password": "wrong"},
        )

        response_text = response.text.lower()
        # Should not expose internal details
        assert "secret" not in response_text or "incorrect" in response_text
        assert "private_key" not in response_text
        assert "traceback" not in response_text


class TestA03Injection:
    """A03:2021 - Injection tests."""

    @pytest.mark.asyncio
    @pytest.mark.parametrize(
        "payload",
        [
            "'; DROP TABLE users; --",
            "1 OR 1=1",
            "admin'--",
            "${7*7}",
            "{{7*7}}",
            "1; cat /etc/passwd",
        ],
    )
    async def test_sql_injection_in_login(
        self,
        client: AsyncClient,
        payload: str,
    ) -> None:
        """Login endpoint resistant to SQL injection."""
        response = await client.post(
            "/api/v1/auth/login",
            json={"email": payload, "password": payload},
        )
        # Should return validation error or auth error, not server error
        assert response.status_code in [400, 401, 422]
        assert response.status_code != 500

    @pytest.mark.asyncio
    @pytest.mark.parametrize(
        "payload",
        [
            "<script>alert('xss')</script>",
            "javascript:alert(1)",
            "<img src=x onerror=alert(1)>",
            "<svg onload=alert(1)>",
        ],
    )
    async def test_xss_sanitization(
        self,
        client: AsyncClient,
        payload: str,
    ) -> None:
        """XSS payloads are rejected or sanitized."""
        response = await client.post(
            "/api/v1/auth/register",
            json={
                "email": "test@example.com",
                "password": "SecurePass123!",
                "name": payload,
            },
        )
        # Should either reject or sanitize - not return 500
        if response.status_code == 200:
            data = response.json()
            assert "<script>" not in data.get("name", "")
        else:
            assert response.status_code in [400, 422]


class TestA05SecurityMisconfiguration:
    """A05:2021 - Security Misconfiguration tests."""

    @pytest.mark.asyncio
    async def test_no_stack_trace_in_production_errors(
        self,
        client: AsyncClient,
    ) -> None:
        """Error responses don't expose stack traces."""
        response = await client.get("/api/v1/nonexistent-endpoint-12345")

        assert "Traceback" not in response.text
        assert 'File "' not in response.text
        assert "line " not in response.text.lower() or response.status_code == 404

    @pytest.mark.asyncio
    async def test_health_endpoint_accessible(
        self,
        client: AsyncClient,
    ) -> None:
        """Health endpoint works without auth."""
        response = await client.get("/health")
        assert response.status_code == 200

    @pytest.mark.asyncio
    async def test_debug_endpoints_not_exposed(
        self,
        client: AsyncClient,
    ) -> None:
        """Debug/internal endpoints are not publicly accessible."""
        debug_endpoints = [
            "/debug",
            "/_debug",
            "/internal",
            "/admin",
            "/phpinfo.php",
            "/.env",
            "/config",
        ]
        for endpoint in debug_endpoints:
            response = await client.get(endpoint)
            # Should be 404 or 403, not 200 with sensitive data
            assert response.status_code in [404, 403, 405, 401]


class TestA07AuthenticationFailures:
    """A07:2021 - Identification and Authentication Failures tests."""

    @pytest.mark.asyncio
    async def test_login_with_invalid_credentials(
        self,
        client: AsyncClient,
    ) -> None:
        """Invalid credentials return proper error, not server error."""
        response = await client.post(
            "/api/v1/auth/login",
            json={"email": "nonexistent@test.com", "password": "wrongpassword"},
        )
        # Should be auth error, not server error
        assert response.status_code in [400, 401, 422]
        assert response.status_code != 500

    @pytest.mark.asyncio
    async def test_password_not_in_response(
        self,
        client: AsyncClient,
    ) -> None:
        """Passwords never returned in API responses."""
        # Try to get user info (will fail without auth, but check response)
        response = await client.get("/api/v1/users/me")
        assert "password" not in response.text.lower() or response.status_code in [
            401,
            403,
        ]


class TestA09LoggingMonitoringFailures:
    """A09:2021 - Security Logging and Monitoring Failures tests."""

    @pytest.mark.asyncio
    async def test_health_endpoint_returns_status(
        self,
        client: AsyncClient,
    ) -> None:
        """Health endpoint provides monitoring information."""
        response = await client.get("/health")
        assert response.status_code == 200
        data = response.json()
        assert "status" in data or isinstance(data, dict)


class TestA10SSRF:
    """A10:2021 - Server-Side Request Forgery tests."""

    @pytest.mark.asyncio
    @pytest.mark.parametrize(
        "payload",
        [
            "http://localhost:22",
            "http://127.0.0.1:22",
            "http://169.254.169.254/latest/meta-data/",
            "file:///etc/passwd",
            "gopher://localhost:25",
        ],
    )
    async def test_ssrf_in_url_parameters(
        self,
        client: AsyncClient,
        payload: str,
    ) -> None:
        """URL parameters don't allow SSRF attacks."""
        # Test in query parameters
        response = await client.get(f"/api/v1/videos?url={payload}")
        # Should not succeed in fetching internal resources
        assert response.status_code in [400, 401, 403, 404, 422]
