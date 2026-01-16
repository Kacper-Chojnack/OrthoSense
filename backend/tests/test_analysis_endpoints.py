"""Tests for analysis endpoints.

Comprehensive test coverage for:
1. GET /exercises - List available exercises
2. POST /landmarks - Analyze exercise from landmarks
3. Input validation
4. Error handling
"""

import os
from unittest.mock import MagicMock, patch

import pytest
import pytest_asyncio
from httpx import ASGITransport, AsyncClient

# Set environment variables BEFORE importing app
os.environ["SECRET_KEY"] = "test_secret_key_for_pytest_12345"
os.environ["DATABASE_URL"] = "sqlite+aiosqlite:///:memory:"

from app.core.config import settings
from app.main import app


@pytest_asyncio.fixture
async def async_client() -> AsyncClient:
    """Async test client."""
    async with AsyncClient(
        transport=ASGITransport(app=app),
        base_url="http://localhost",
    ) as client:
        yield client


class TestListExercises:
    """Tests for GET /exercises endpoint."""

    @pytest.mark.asyncio
    async def test_list_exercises_returns_200(
        self,
        async_client: AsyncClient,
    ) -> None:
        """Endpoint returns 200 status code."""
        response = await async_client.get(
            f"{settings.api_v1_prefix}/analysis/exercises",
        )
        assert response.status_code == 200

    @pytest.mark.asyncio
    async def test_list_exercises_returns_exercises_array(
        self,
        async_client: AsyncClient,
    ) -> None:
        """Response contains exercises array."""
        response = await async_client.get(
            f"{settings.api_v1_prefix}/analysis/exercises",
        )
        data = response.json()
        assert "exercises" in data
        assert isinstance(data["exercises"], list)

    @pytest.mark.asyncio
    async def test_list_exercises_has_ai_available_flag(
        self,
        async_client: AsyncClient,
    ) -> None:
        """Response contains AI availability flag."""
        response = await async_client.get(
            f"{settings.api_v1_prefix}/analysis/exercises",
        )
        data = response.json()
        assert "ai_available" in data
        assert isinstance(data["ai_available"], bool)

    @pytest.mark.asyncio
    async def test_list_exercises_each_has_id_and_name(
        self,
        async_client: AsyncClient,
    ) -> None:
        """Each exercise has id and name fields."""
        response = await async_client.get(
            f"{settings.api_v1_prefix}/analysis/exercises",
        )
        data = response.json()

        for exercise in data["exercises"]:
            assert "id" in exercise
            assert "name" in exercise
            assert isinstance(exercise["id"], int)
            assert isinstance(exercise["name"], str)


class TestLandmarksAnalysis:
    """Tests for POST /landmarks endpoint."""

    @pytest.fixture
    def valid_landmarks(self) -> list:
        """Generate valid landmarks for testing (33 joints × 3 coords per frame)."""
        return [[[0.5, 0.5, 0.0] for _ in range(33)]]

    @pytest.fixture
    def valid_request_body(self, valid_landmarks: list) -> dict:
        """Valid request body for landmarks analysis."""
        return {
            "landmarks": valid_landmarks,
            "exercise_name": "Deep Squat",
            "fps": 30.0,
        }

    @pytest.mark.asyncio
    async def test_landmarks_empty_array_returns_400(
        self,
        async_client: AsyncClient,
    ) -> None:
        """Empty landmarks array returns 400."""
        response = await async_client.post(
            f"{settings.api_v1_prefix}/analysis/landmarks",
            json={"landmarks": [], "exercise_name": "Deep Squat"},
        )
        assert response.status_code == 400
        assert "No landmarks provided" in response.json()["detail"]

    @pytest.mark.asyncio
    async def test_landmarks_wrong_joint_count_returns_400(
        self,
        async_client: AsyncClient,
    ) -> None:
        """Wrong number of joints (not 33) returns 400."""
        bad_landmarks = [[[0.5, 0.5, 0.0] for _ in range(32)]]
        response = await async_client.post(
            f"{settings.api_v1_prefix}/analysis/landmarks",
            json={"landmarks": bad_landmarks, "exercise_name": "Deep Squat"},
        )
        assert response.status_code == 400
        assert "expected 33" in response.json()["detail"]

    @pytest.mark.asyncio
    async def test_landmarks_wrong_coord_count_returns_400(
        self,
        async_client: AsyncClient,
    ) -> None:
        """Wrong number of coordinates per joint returns 400."""
        bad_landmarks = [[[0.5, 0.5] for _ in range(33)]]
        response = await async_client.post(
            f"{settings.api_v1_prefix}/analysis/landmarks",
            json={"landmarks": bad_landmarks, "exercise_name": "Deep Squat"},
        )
        assert response.status_code == 400
        assert "joint format invalid" in response.json()["detail"]

    @pytest.mark.asyncio
    @patch("app.api.v1.endpoints.analysis.OrthoSenseSystem")
    async def test_landmarks_accepts_4_coordinates(
        self,
        mock_system: MagicMock,
        async_client: AsyncClient,
    ) -> None:
        """Landmarks with 4 coordinates (x, y, z, visibility) are accepted."""
        mock_instance = MagicMock()
        mock_instance.analyze_landmarks.return_value = {
            "exercise": "Deep Squat",
            "is_correct": True,
            "confidence": 0.95,
            "feedback": {},
            "text_report": "Good form",
        }
        mock_system.return_value = mock_instance

        landmarks_with_visibility = [[[0.5, 0.5, 0.0, 0.9] for _ in range(33)]]
        response = await async_client.post(
            f"{settings.api_v1_prefix}/analysis/landmarks",
            json={
                "landmarks": landmarks_with_visibility,
                "exercise_name": "Deep Squat",
            },
        )
        assert response.status_code == 200

    @pytest.mark.asyncio
    @patch("app.api.v1.endpoints.analysis.OrthoSenseSystem")
    async def test_landmarks_valid_request_calls_ai_system(
        self,
        mock_system: MagicMock,
        async_client: AsyncClient,
        valid_request_body: dict,
    ) -> None:
        """Valid request invokes AI system."""
        mock_instance = MagicMock()
        mock_instance.analyze_landmarks.return_value = {
            "exercise": "Deep Squat",
            "is_correct": True,
            "confidence": 0.95,
            "feedback": {},
            "text_report": "Good form",
        }
        mock_system.return_value = mock_instance

        response = await async_client.post(
            f"{settings.api_v1_prefix}/analysis/landmarks",
            json=valid_request_body,
        )

        assert response.status_code == 200
        mock_instance.analyze_landmarks.assert_called_once()

    @pytest.mark.asyncio
    @patch("app.api.v1.endpoints.analysis.OrthoSenseSystem")
    async def test_landmarks_returns_analysis_result(
        self,
        mock_system: MagicMock,
        async_client: AsyncClient,
        valid_request_body: dict,
    ) -> None:
        """Valid request returns analysis result."""
        expected_result = {
            "exercise": "Deep Squat",
            "is_correct": True,
            "confidence": 0.95,
            "feedback": {"form": "Good form detected"},
            "text_report": "Good form",
        }
        mock_instance = MagicMock()
        mock_instance.analyze_landmarks.return_value = expected_result
        mock_system.return_value = mock_instance

        response = await async_client.post(
            f"{settings.api_v1_prefix}/analysis/landmarks",
            json=valid_request_body,
        )

        assert response.status_code == 200
        data = response.json()
        assert data["exercise"] == "Deep Squat"
        assert data["is_correct"] is True
        assert data["confidence"] == 0.95

    @pytest.mark.asyncio
    @patch("app.api.v1.endpoints.analysis.OrthoSenseSystem")
    async def test_landmarks_ai_error_returns_400(
        self,
        mock_system: MagicMock,
        async_client: AsyncClient,
        valid_request_body: dict,
    ) -> None:
        """AI system returning error returns 400."""
        mock_instance = MagicMock()
        mock_instance.analyze_landmarks.return_value = {
            "error": "Insufficient frames for analysis",
        }
        mock_system.return_value = mock_instance

        response = await async_client.post(
            f"{settings.api_v1_prefix}/analysis/landmarks",
            json=valid_request_body,
        )

        assert response.status_code == 400
        assert "Insufficient frames" in response.json()["detail"]

    @pytest.mark.asyncio
    @patch("app.api.v1.endpoints.analysis.OrthoSenseSystem")
    async def test_landmarks_ai_exception_returns_500(
        self,
        mock_system: MagicMock,
        async_client: AsyncClient,
        valid_request_body: dict,
    ) -> None:
        """Unexpected AI system exception returns 500."""
        mock_instance = MagicMock()
        mock_instance.analyze_landmarks.side_effect = RuntimeError("Model not loaded")
        mock_system.return_value = mock_instance

        response = await async_client.post(
            f"{settings.api_v1_prefix}/analysis/landmarks",
            json=valid_request_body,
        )

        assert response.status_code == 500
        # In production mode, 500 errors return generic message, not detailed 'detail'
        response_json = response.json()
        assert (
            "error" in response_json
            or "message" in response_json
            or "detail" in response_json
        )

    @pytest.mark.asyncio
    async def test_landmarks_missing_exercise_name_returns_422(
        self,
        async_client: AsyncClient,
    ) -> None:
        """Missing exercise_name returns 422 validation error."""
        landmarks = [[[0.5, 0.5, 0.0] for _ in range(33)]]
        response = await async_client.post(
            f"{settings.api_v1_prefix}/analysis/landmarks",
            json={"landmarks": landmarks},
        )
        assert response.status_code == 422

    @pytest.mark.asyncio
    async def test_landmarks_invalid_fps_returns_422(
        self,
        async_client: AsyncClient,
    ) -> None:
        """Invalid FPS value returns 422."""
        landmarks = [[[0.5, 0.5, 0.0] for _ in range(33)]]
        response = await async_client.post(
            f"{settings.api_v1_prefix}/analysis/landmarks",
            json={
                "landmarks": landmarks,
                "exercise_name": "Deep Squat",
                "fps": 0.5,
            },
        )
        assert response.status_code == 422

    @pytest.mark.asyncio
    @patch("app.api.v1.endpoints.analysis.OrthoSenseSystem")
    async def test_landmarks_multiple_frames(
        self,
        mock_system: MagicMock,
        async_client: AsyncClient,
    ) -> None:
        """Multiple frames are processed correctly."""
        multi_frame_landmarks = [
            [[0.5, 0.5, 0.0] for _ in range(33)] for _ in range(10)
        ]

        mock_instance = MagicMock()
        mock_instance.analyze_landmarks.return_value = {
            "exercise": "Deep Squat",
            "is_correct": True,
            "confidence": 0.85,
            "feedback": {},
            "text_report": "Good form",
        }
        mock_system.return_value = mock_instance

        response = await async_client.post(
            f"{settings.api_v1_prefix}/analysis/landmarks",
            json={
                "landmarks": multi_frame_landmarks,
                "exercise_name": "Deep Squat",
            },
        )

        assert response.status_code == 200
        call_args = mock_instance.analyze_landmarks.call_args
        assert len(call_args[0][0]) == 10


class TestAnalysisInputValidation:
    """Edge cases and input validation tests."""

    @pytest.mark.asyncio
    async def test_non_json_body_returns_422(
        self,
        async_client: AsyncClient,
    ) -> None:
        """Non-JSON body returns 422."""
        response = await async_client.post(
            f"{settings.api_v1_prefix}/analysis/landmarks",
            content="not json",
            headers={"Content-Type": "application/json"},
        )
        assert response.status_code == 422

    @pytest.mark.asyncio
    async def test_invalid_json_structure_returns_422(
        self,
        async_client: AsyncClient,
    ) -> None:
        """Invalid JSON structure returns 422."""
        response = await async_client.post(
            f"{settings.api_v1_prefix}/analysis/landmarks",
            json={"wrong_field": "value"},
        )
        assert response.status_code == 422

    @pytest.mark.asyncio
    async def test_landmarks_not_array_returns_422(
        self,
        async_client: AsyncClient,
    ) -> None:
        """Landmarks as non-array returns 422."""
        response = await async_client.post(
            f"{settings.api_v1_prefix}/analysis/landmarks",
            json={
                "landmarks": "not an array",
                "exercise_name": "Deep Squat",
            },
        )
        assert response.status_code == 422

    @pytest.mark.asyncio
    @patch("app.api.v1.endpoints.analysis.OrthoSenseSystem")
    async def test_exercise_name_empty_string_handled(
        self,
        mock_system: MagicMock,
        async_client: AsyncClient,
    ) -> None:
        """Empty exercise name is passed to AI system."""
        mock_instance = MagicMock()
        mock_instance.analyze_landmarks.return_value = {
            "exercise": "",
            "is_correct": False,
            "confidence": 0.0,
            "feedback": {"error": "Unknown exercise"},
            "text_report": "Unknown exercise",
        }
        mock_system.return_value = mock_instance

        landmarks = [[[0.5, 0.5, 0.0] for _ in range(33)]]
        response = await async_client.post(
            f"{settings.api_v1_prefix}/analysis/landmarks",
            json={
                "landmarks": landmarks,
                "exercise_name": "",
            },
        )
        # AI will handle empty name
        assert response.status_code == 200
