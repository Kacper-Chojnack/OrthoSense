"""
Unit tests for Analysis API endpoints.

Test coverage:
1. List available exercises
2. Landmarks analysis endpoint
3. Input validation
4. Error handling
"""

from unittest.mock import MagicMock, patch

import pytest
from httpx import AsyncClient


class TestListAnalysisExercises:
    """Test GET /api/v1/analysis/exercises endpoint."""

    @pytest.mark.asyncio
    async def test_list_exercises_returns_exercises(
        self,
        client: AsyncClient,
    ) -> None:
        """List exercises endpoint returns exercise list."""
        response = await client.get("/api/v1/analysis/exercises")

        assert response.status_code == 200
        data = response.json()
        assert "exercises" in data
        assert "ai_available" in data
        assert isinstance(data["exercises"], list)


class TestAnalyzeLandmarks:
    """Test POST /api/v1/analysis/landmarks endpoint."""

    @pytest.mark.asyncio
    async def test_analyze_landmarks_empty_request(
        self,
        client: AsyncClient,
    ) -> None:
        """Empty landmarks returns 400."""
        response = await client.post(
            "/api/v1/analysis/landmarks",
            json={
                "landmarks": [],
                "exercise_name": "Deep Squat",
            },
        )

        assert response.status_code == 400
        assert "No landmarks provided" in response.json()["detail"]

    @pytest.mark.asyncio
    async def test_analyze_landmarks_invalid_frame_count(
        self,
        client: AsyncClient,
    ) -> None:
        """Landmarks with wrong joint count returns 400."""
        # Create frame with wrong number of joints (should be 33)
        invalid_frame = [[0.0, 0.0, 0.0] for _ in range(25)]  # Only 25 joints

        response = await client.post(
            "/api/v1/analysis/landmarks",
            json={
                "landmarks": [invalid_frame],
                "exercise_name": "Deep Squat",
            },
        )

        assert response.status_code == 400
        assert "expected 33" in response.json()["detail"].lower()

    @pytest.mark.asyncio
    async def test_analyze_landmarks_invalid_joint_format(
        self,
        client: AsyncClient,
    ) -> None:
        """Landmarks with wrong joint format returns 400."""
        # Create frame with wrong joint format (should be [x, y, z] or [x, y, z, visibility])
        invalid_frame = [[0.0, 0.0] for _ in range(33)]  # Only 2 values per joint

        response = await client.post(
            "/api/v1/analysis/landmarks",
            json={
                "landmarks": [invalid_frame],
                "exercise_name": "Deep Squat",
            },
        )

        assert response.status_code == 400
        assert "joint format invalid" in response.json()["detail"].lower()

    @pytest.mark.asyncio
    async def test_analyze_landmarks_valid_request(
        self,
        client: AsyncClient,
    ) -> None:
        """Valid landmarks request returns analysis result."""
        # Create valid frame with 33 joints, each with [x, y, z]
        valid_frame = [[0.5, 0.5, 0.0] for _ in range(33)]

        with patch("app.api.v1.endpoints.analysis.OrthoSenseSystem") as mock_system:
            mock_instance = MagicMock()
            mock_instance.analyze_landmarks.return_value = {
                "exercise": "Deep Squat",
                "confidence": 0.95,
                "is_correct": True,
                "feedback": {},
                "text_report": "Good form!",
            }
            mock_system.return_value = mock_instance

            response = await client.post(
                "/api/v1/analysis/landmarks",
                json={
                    "landmarks": [valid_frame] * 10,  # 10 frames
                    "exercise_name": "Deep Squat",
                    "fps": 30.0,
                },
            )

            assert response.status_code == 200
            data = response.json()
            assert "exercise" in data
            assert "confidence" in data

    @pytest.mark.asyncio
    async def test_analyze_landmarks_with_visibility(
        self,
        client: AsyncClient,
    ) -> None:
        """Landmarks with visibility data are accepted."""
        # Create valid frame with 33 joints, each with [x, y, z, visibility]
        valid_frame = [[0.5, 0.5, 0.0, 0.9] for _ in range(33)]

        with patch("app.api.v1.endpoints.analysis.OrthoSenseSystem") as mock_system:
            mock_instance = MagicMock()
            mock_instance.analyze_landmarks.return_value = {
                "exercise": "Deep Squat",
                "confidence": 0.95,
                "is_correct": True,
                "feedback": {},
                "text_report": "Good form!",
            }
            mock_system.return_value = mock_instance

            response = await client.post(
                "/api/v1/analysis/landmarks",
                json={
                    "landmarks": [valid_frame] * 10,
                    "exercise_name": "Deep Squat",
                },
            )

            assert response.status_code == 200

    @pytest.mark.asyncio
    async def test_analyze_landmarks_ai_error(
        self,
        client: AsyncClient,
    ) -> None:
        """AI system error returns error response."""
        valid_frame = [[0.5, 0.5, 0.0] for _ in range(33)]

        with patch("app.api.v1.endpoints.analysis.OrthoSenseSystem") as mock_system:
            mock_instance = MagicMock()
            mock_instance.analyze_landmarks.return_value = {
                "error": "Unable to analyze landmarks",
            }
            mock_system.return_value = mock_instance

            response = await client.post(
                "/api/v1/analysis/landmarks",
                json={
                    "landmarks": [valid_frame] * 10,
                    "exercise_name": "Deep Squat",
                },
            )

            assert response.status_code == 400
            assert "Unable to analyze" in response.json()["detail"]

    @pytest.mark.asyncio
    async def test_analyze_landmarks_fps_validation(
        self,
        client: AsyncClient,
    ) -> None:
        """FPS value is validated."""
        valid_frame = [[0.5, 0.5, 0.0] for _ in range(33)]

        # FPS too low
        response = await client.post(
            "/api/v1/analysis/landmarks",
            json={
                "landmarks": [valid_frame],
                "exercise_name": "Deep Squat",
                "fps": 0.5,  # Below minimum of 1.0
            },
        )

        assert response.status_code == 422

        # FPS too high
        response = await client.post(
            "/api/v1/analysis/landmarks",
            json={
                "landmarks": [valid_frame],
                "exercise_name": "Deep Squat",
                "fps": 150.0,  # Above maximum of 120.0
            },
        )

        assert response.status_code == 422


class TestAnalysisInputValidation:
    """Tests for input validation."""

    @pytest.mark.asyncio
    async def test_missing_exercise_name(
        self,
        client: AsyncClient,
    ) -> None:
        """Missing exercise_name returns validation error."""
        valid_frame = [[0.5, 0.5, 0.0] for _ in range(33)]

        response = await client.post(
            "/api/v1/analysis/landmarks",
            json={
                "landmarks": [valid_frame],
                # exercise_name missing
            },
        )

        assert response.status_code == 422

    @pytest.mark.asyncio
    async def test_missing_landmarks(
        self,
        client: AsyncClient,
    ) -> None:
        """Missing landmarks returns validation error."""
        response = await client.post(
            "/api/v1/analysis/landmarks",
            json={
                "exercise_name": "Deep Squat",
                # landmarks missing
            },
        )

        assert response.status_code == 422

    @pytest.mark.asyncio
    async def test_invalid_json(
        self,
        client: AsyncClient,
    ) -> None:
        """Invalid JSON returns error."""
        response = await client.post(
            "/api/v1/analysis/landmarks",
            content="not valid json",
            headers={"Content-Type": "application/json"},
        )

        assert response.status_code == 422
