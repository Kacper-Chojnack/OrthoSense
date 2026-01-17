"""Extended unit tests for Analysis API endpoint.

Test coverage:
1. Exercise listing
2. Landmarks analysis
3. Input validation
4. Error handling
"""

from unittest.mock import MagicMock, patch

import pytest
from httpx import AsyncClient


class TestListExercises:
    """Test GET /api/v1/analysis/exercises endpoint."""

    @pytest.mark.asyncio
    async def test_returns_exercises_list(self, client: AsyncClient):
        """Should return list of exercises."""
        response = await client.get("/api/v1/analysis/exercises")

        assert response.status_code == 200
        data = response.json()
        assert "exercises" in data
        assert isinstance(data["exercises"], list)

    @pytest.mark.asyncio
    async def test_includes_ai_available_flag(self, client: AsyncClient):
        """Should include AI availability flag."""
        response = await client.get("/api/v1/analysis/exercises")

        assert response.status_code == 200
        data = response.json()
        assert "ai_available" in data
        assert isinstance(data["ai_available"], bool)

    @pytest.mark.asyncio
    async def test_exercises_have_id_and_name(self, client: AsyncClient):
        """Each exercise should have id and name."""
        response = await client.get("/api/v1/analysis/exercises")

        assert response.status_code == 200
        data = response.json()

        if data["exercises"]:
            exercise = data["exercises"][0]
            assert "id" in exercise
            assert "name" in exercise


class TestAnalyzeLandmarks:
    """Test POST /api/v1/analysis/landmarks endpoint."""

    @pytest.mark.asyncio
    async def test_empty_landmarks_returns_400(self, client: AsyncClient):
        """Empty landmarks should return 400."""
        response = await client.post(
            "/api/v1/analysis/landmarks",
            json={
                "landmarks": [],
                "exercise_name": "Deep Squat",
            },
        )

        assert response.status_code == 400
        assert "No landmarks" in response.json()["detail"]

    @pytest.mark.asyncio
    async def test_wrong_joint_count_returns_400(self, client: AsyncClient):
        """Landmarks with wrong joint count should return 400."""
        invalid_frame = [[0.0, 0.0, 0.0] for _ in range(25)]

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
    async def test_wrong_joint_format_returns_400(self, client: AsyncClient):
        """Landmarks with wrong joint format should return 400."""
        invalid_frame = [[0.0, 0.0] for _ in range(33)]

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
    async def test_valid_landmarks_returns_analysis(self, client: AsyncClient):
        """Valid landmarks should return analysis result."""
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
                    "landmarks": [valid_frame] * 10,
                    "exercise_name": "Deep Squat",
                },
            )

            assert response.status_code == 200
            data = response.json()
            assert "exercise" in data

    @pytest.mark.asyncio
    async def test_accepts_visibility_in_landmarks(self, client: AsyncClient):
        """Landmarks with visibility should be accepted."""
        valid_frame = [[0.5, 0.5, 0.0, 1.0] for _ in range(33)]

        with patch("app.api.v1.endpoints.analysis.OrthoSenseSystem") as mock_system:
            mock_instance = MagicMock()
            mock_instance.analyze_landmarks.return_value = {
                "exercise": "Deep Squat",
                "confidence": 0.95,
                "is_correct": True,
                "feedback": {},
            }
            mock_system.return_value = mock_instance

            response = await client.post(
                "/api/v1/analysis/landmarks",
                json={
                    "landmarks": [valid_frame] * 5,
                    "exercise_name": "Deep Squat",
                },
            )

            assert response.status_code == 200


class TestLandmarksInputValidation:
    """Test landmarks input validation."""

    @pytest.mark.asyncio
    async def test_validates_frame_structure(self, client: AsyncClient):
        """Should validate frame structure."""
        response = await client.post(
            "/api/v1/analysis/landmarks",
            json={
                "landmarks": "invalid",
                "exercise_name": "Deep Squat",
            },
        )

        assert response.status_code == 422

    @pytest.mark.asyncio
    async def test_handles_missing_exercise_name(self, client: AsyncClient):
        """Should handle missing exercise name."""
        valid_frame = [[0.5, 0.5, 0.0] for _ in range(33)]

        # Missing exercise_name should use default or return error
        response = await client.post(
            "/api/v1/analysis/landmarks",
            json={
                "landmarks": [valid_frame] * 5,
            },
        )

        # Should either succeed with default or fail validation
        assert response.status_code in [200, 422]


class TestAnalysisErrorHandling:
    """Test error handling in analysis."""

    @pytest.mark.asyncio
    async def test_handles_system_error(self, client: AsyncClient):
        """Should handle system errors gracefully."""
        valid_frame = [[0.5, 0.5, 0.0] for _ in range(33)]

        with patch("app.api.v1.endpoints.analysis.OrthoSenseSystem") as mock_system:
            mock_instance = MagicMock()
            mock_instance.analyze_landmarks.return_value = {
                "error": "System error occurred"
            }
            mock_system.return_value = mock_instance

            response = await client.post(
                "/api/v1/analysis/landmarks",
                json={
                    "landmarks": [valid_frame] * 5,
                    "exercise_name": "Deep Squat",
                },
            )

            assert response.status_code == 400

    @pytest.mark.asyncio
    async def test_handles_exception_in_analysis(self, client: AsyncClient):
        """Should handle exceptions in analysis."""
        valid_frame = [[0.5, 0.5, 0.0] for _ in range(33)]

        with patch("app.api.v1.endpoints.analysis.OrthoSenseSystem") as mock_system:
            mock_instance = MagicMock()
            mock_instance.analyze_landmarks.side_effect = Exception("Analysis failed")
            mock_system.return_value = mock_instance

            response = await client.post(
                "/api/v1/analysis/landmarks",
                json={
                    "landmarks": [valid_frame] * 5,
                    "exercise_name": "Deep Squat",
                },
            )

            # Should handle gracefully (500 or similar)
            assert response.status_code in [400, 500]


class TestMultipleFrames:
    """Test handling of multiple frames."""

    @pytest.mark.asyncio
    async def test_handles_single_frame(self, client: AsyncClient):
        """Should handle single frame."""
        valid_frame = [[0.5, 0.5, 0.0] for _ in range(33)]

        with patch("app.api.v1.endpoints.analysis.OrthoSenseSystem") as mock_system:
            mock_instance = MagicMock()
            mock_instance.analyze_landmarks.return_value = {
                "exercise": "Deep Squat",
                "confidence": 0.9,
                "is_correct": True,
                "feedback": {},
            }
            mock_system.return_value = mock_instance

            response = await client.post(
                "/api/v1/analysis/landmarks",
                json={
                    "landmarks": [valid_frame],
                    "exercise_name": "Deep Squat",
                },
            )

            assert response.status_code == 200

    @pytest.mark.asyncio
    async def test_handles_many_frames(self, client: AsyncClient):
        """Should handle many frames."""
        valid_frame = [[0.5, 0.5, 0.0] for _ in range(33)]

        with patch("app.api.v1.endpoints.analysis.OrthoSenseSystem") as mock_system:
            mock_instance = MagicMock()
            mock_instance.analyze_landmarks.return_value = {
                "exercise": "Deep Squat",
                "confidence": 0.95,
                "is_correct": True,
                "feedback": {},
            }
            mock_system.return_value = mock_instance

            response = await client.post(
                "/api/v1/analysis/landmarks",
                json={
                    "landmarks": [valid_frame] * 100,
                    "exercise_name": "Deep Squat",
                },
            )

            assert response.status_code == 200
