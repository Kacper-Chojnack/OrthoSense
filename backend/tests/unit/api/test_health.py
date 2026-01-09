"""
Unit tests for Health Check endpoint.

Test coverage:
1. Health check returns healthy status
2. Response format validation
3. No authentication required
"""

import pytest
from httpx import AsyncClient


class TestHealthCheck:
    """Tests for GET /health endpoint."""

    @pytest.mark.asyncio
    async def test_health_check_returns_healthy(
        self,
        client: AsyncClient,
    ) -> None:
        """Health check returns healthy status."""
        response = await client.get("/health")

        assert response.status_code == 200
        data = response.json()
        assert data["status"] == "healthy"

    @pytest.mark.asyncio
    async def test_health_check_no_auth_required(
        self,
        client: AsyncClient,
    ) -> None:
        """Health check does not require authentication."""
        response = await client.get("/health")

        # Should succeed without any auth headers
        assert response.status_code == 200

    @pytest.mark.asyncio
    async def test_health_check_response_format(
        self,
        client: AsyncClient,
    ) -> None:
        """Health check response has correct format."""
        response = await client.get("/health")

        assert response.status_code == 200
        data = response.json()

        # Should have status field
        assert "status" in data
        assert isinstance(data["status"], str)

    @pytest.mark.asyncio
    async def test_health_check_is_fast(
        self,
        client: AsyncClient,
    ) -> None:
        """Health check responds quickly (for load balancers)."""
        import time

        start = time.monotonic()
        response = await client.get("/health")
        elapsed = time.monotonic() - start

        assert response.status_code == 200
        # Should respond within 100ms
        assert elapsed < 0.1
