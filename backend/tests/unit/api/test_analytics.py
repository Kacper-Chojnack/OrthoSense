"""
Unit tests for Analysis API endpoints.

Test coverage:
1. /analysis/exercises - List available exercises

Note: /analysis/landmarks endpoint was removed as part of the
offline-first architecture. All movement analysis is performed
client-side using Edge AI (ML Kit + TFLite).
"""

import pytest
from httpx import AsyncClient


class TestAnalysisExercisesEndpoint:
    """Test /analysis/exercises endpoint."""

    @pytest.mark.asyncio
    async def test_list_exercises_returns_available_exercises(
        self,
        client: AsyncClient,
    ) -> None:
        """List exercises endpoint returns available exercises."""
        response = await client.get("/api/v1/analysis/exercises")

        assert response.status_code == 200
        data = response.json()
        assert "exercises" in data
        assert "ai_available" in data
        assert isinstance(data["exercises"], list)

    @pytest.mark.asyncio
    async def test_list_exercises_has_expected_format(
        self,
        client: AsyncClient,
    ) -> None:
        """Each exercise has id and name."""
        response = await client.get("/api/v1/analysis/exercises")

        assert response.status_code == 200
        data = response.json()

        for exercise in data["exercises"]:
            assert "id" in exercise
            assert "name" in exercise
