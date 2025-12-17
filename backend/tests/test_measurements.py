"""Tests for measurement sync endpoints with authentication."""

from uuid import uuid4

from httpx import AsyncClient

from app.models.user import User


class TestMeasurementSync:
    """Test measurement sync operations."""

    async def test_create_measurement_success(
        self,
        client: AsyncClient,
        measurement_data: dict,
        auth_headers: dict[str, str],
    ) -> None:
        """POST /measurements creates measurement and returns success."""
        response = await client.post(
            "/api/v1/measurements",
            json=measurement_data,
            headers=auth_headers,
        )

        assert response.status_code == 201
        data = response.json()
        assert data["success"] is True
        assert data["backendId"] == measurement_data["id"]
        assert data["errorMessage"] is None

    async def test_create_measurement_unauthenticated(
        self,
        client: AsyncClient,
        measurement_data: dict,
    ) -> None:
        """POST /measurements fails without authentication."""
        response = await client.post(
            "/api/v1/measurements",
            json=measurement_data,
        )

        assert response.status_code == 401

    async def test_create_measurement_idempotent(
        self,
        client: AsyncClient,
        measurement_data: dict,
        auth_headers: dict[str, str],
    ) -> None:
        """Duplicate POST with same ID returns success without error."""
        # First sync
        response1 = await client.post(
            "/api/v1/measurements",
            json=measurement_data,
            headers=auth_headers,
        )
        assert response1.status_code == 201

        # Retry with same ID (idempotent)
        response2 = await client.post(
            "/api/v1/measurements",
            json=measurement_data,
            headers=auth_headers,
        )
        assert response2.status_code == 201
        assert response2.json()["success"] is True

    async def test_batch_sync_measurements(
        self,
        client: AsyncClient,
        auth_headers: dict[str, str],
    ) -> None:
        """POST /measurements/batch processes multiple measurements."""
        batch = [
            {
                "id": str(uuid4()),
                "user_id": "batch_user",
                "type": "pose_analysis",
                "json_data": {"angle": i * 10},
                "created_at": "2024-01-15T10:30:00Z",
            }
            for i in range(3)
        ]

        response = await client.post(
            "/api/v1/measurements/batch",
            json=batch,
            headers=auth_headers,
        )

        assert response.status_code == 201
        results = response.json()
        assert len(results) == 3
        assert all(r["success"] for r in results)

    async def test_get_measurement_by_id(
        self,
        client: AsyncClient,
        measurement_data: dict,
        auth_headers: dict[str, str],
    ) -> None:
        """GET /measurements/{id} retrieves saved measurement."""
        # Create first
        await client.post(
            "/api/v1/measurements",
            json=measurement_data,
            headers=auth_headers,
        )

        # Retrieve
        response = await client.get(
            f"/api/v1/measurements/{measurement_data['id']}",
            headers=auth_headers,
        )

        assert response.status_code == 200
        data = response.json()
        assert data["id"] == measurement_data["id"]
        assert data["user_id"] == measurement_data["user_id"]
        assert data["type"] == measurement_data["type"]

    async def test_get_measurement_not_found(
        self,
        client: AsyncClient,
        auth_headers: dict[str, str],
    ) -> None:
        """GET /measurements/{id} returns 404 for missing ID."""
        response = await client.get(
            f"/api/v1/measurements/{uuid4()}",
            headers=auth_headers,
        )
        assert response.status_code == 404

    async def test_get_user_measurements(
        self,
        client: AsyncClient,
        measurement_data: dict,
        auth_headers: dict[str, str],
    ) -> None:
        """GET /measurements/user/{user_id} returns user's measurements."""
        # Create measurement
        await client.post(
            "/api/v1/measurements",
            json=measurement_data,
            headers=auth_headers,
        )

        # Get by user
        response = await client.get(
            f"/api/v1/measurements/user/{measurement_data['user_id']}",
            headers=auth_headers,
        )

        assert response.status_code == 200
        data = response.json()
        assert len(data) == 1
        assert data[0]["user_id"] == measurement_data["user_id"]

    async def test_get_my_measurements(
        self,
        client: AsyncClient,
        measurement_data: dict,
        auth_headers: dict[str, str],
    ) -> None:
        """GET /measurements/my returns user's own measurements."""
        # Create measurement
        await client.post(
            "/api/v1/measurements",
            json=measurement_data,
            headers=auth_headers,
        )

        # Get my measurements
        response = await client.get(
            "/api/v1/measurements/my",
            headers=auth_headers,
        )

        assert response.status_code == 200
        data = response.json()
        assert len(data) >= 1


class TestHealthCheck:
    """Test health endpoint."""

    async def test_health_check(self, client: AsyncClient) -> None:
        """GET /health returns healthy status."""
        response = await client.get("/health")
        assert response.status_code == 200
        assert response.json() == {"status": "healthy"}
