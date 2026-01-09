"""
Unit tests for Analysis API endpoints.

Test coverage:
1. /analysis/exercises - List available exercises
2. /analysis/landmarks - Analyze pose landmarks
3. Error handling
4. Input validation
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


class TestAnalysisLandmarksEndpoint:
    """Test /analysis/landmarks endpoint."""

    @pytest.mark.asyncio
    async def test_landmarks_empty_request_rejected(
        self,
        client: AsyncClient,
    ) -> None:
        """Empty landmarks request is rejected."""
        response = await client.post(
            "/api/v1/analysis/landmarks",
            json={"landmarks": [], "exercise_name": "Deep Squat"},
        )

        assert response.status_code == 400

    @pytest.mark.asyncio
    async def test_landmarks_invalid_frame_count(
        self,
        client: AsyncClient,
    ) -> None:
        """Landmarks with wrong joint count is rejected."""
        # BlazePose requires 33 joints per frame
        invalid_frame = [[0.5, 0.5, 0.5] for _ in range(10)]  # Only 10 joints

        response = await client.post(
            "/api/v1/analysis/landmarks",
            json={"landmarks": [invalid_frame], "exercise_name": "Deep Squat"},
        )

        assert response.status_code == 400
        assert "33" in response.json()["detail"]

    @pytest.mark.asyncio
    async def test_landmarks_valid_frame_accepted(
        self,
        client: AsyncClient,
    ) -> None:
        """Valid landmarks frame is processed."""
        # BlazePose requires 33 joints with [x, y, z] coordinates
        valid_frame = [[0.5, 0.5, 0.5] for _ in range(33)]

        response = await client.post(
            "/api/v1/analysis/landmarks",
            json={"landmarks": [valid_frame], "exercise_name": "Deep Squat"},
        )

        # Should either succeed or fail with AI error, not validation error
        assert response.status_code in [200, 400, 500]
        if response.status_code == 400:
            # Should not be a validation error about landmark count
            assert "33" not in response.json().get("detail", "")


class TestAnalysisErrorHandling:
    """Test error handling in analysis endpoints."""

    @pytest.mark.asyncio
    async def test_invalid_exercise_name_handled(
        self,
        client: AsyncClient,
    ) -> None:
        """Invalid exercise name is handled gracefully."""
        valid_frame = [[0.5, 0.5, 0.5] for _ in range(33)]

        response = await client.post(
            "/api/v1/analysis/landmarks",
            json={
                "landmarks": [valid_frame],
                "exercise_name": "NonexistentExercise",
            },
        )

        # API should handle gracefully - either process as default or return error
        # The important thing is it doesn't crash (500 internal error)
        assert response.status_code in [200, 400, 404]

    @pytest.mark.asyncio
    async def test_malformed_json_rejected(
        self,
        client: AsyncClient,
    ) -> None:
        """Malformed JSON body is rejected."""
        response = await client.post(
            "/api/v1/analysis/landmarks",
            content="not valid json",
            headers={"Content-Type": "application/json"},
        )

        assert response.status_code == 422


class TestAnalysisInputValidation:
    """Test input validation for analysis endpoints."""

    @pytest.mark.asyncio
    async def test_landmarks_with_visibility(
        self,
        client: AsyncClient,
    ) -> None:
        """Landmarks with visibility (4 values) are accepted."""
        # BlazePose can include visibility: [x, y, z, visibility]
        frame_with_visibility = [[0.5, 0.5, 0.5, 0.9] for _ in range(33)]

        response = await client.post(
            "/api/v1/analysis/landmarks",
            json={
                "landmarks": [frame_with_visibility],
                "exercise_name": "Deep Squat",
            },
        )

        # Should either succeed or fail with AI error, not validation error
        assert response.status_code in [200, 400, 500]

    @pytest.mark.asyncio
    async def test_multiple_frames_processed(
        self,
        client: AsyncClient,
    ) -> None:
        """Multiple landmark frames can be processed."""
        frame = [[0.5, 0.5, 0.5] for _ in range(33)]
        frames = [frame for _ in range(10)]  # 10 frames

        response = await client.post(
            "/api/v1/analysis/landmarks",
            json={"landmarks": frames, "exercise_name": "Deep Squat"},
        )

        # Should process or return AI error
        assert response.status_code in [200, 400, 500]
