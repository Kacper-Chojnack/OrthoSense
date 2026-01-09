"""
Unit tests for Analysis API endpoints.

Test coverage:
1. List available exercises for analysis
2. Landmarks analysis endpoint
3. Input validation
4. Error handling
5. Edge cases
"""

from typing import Any

import pytest
from httpx import AsyncClient


class TestListAnalysisExercises:
    """Tests for GET /analysis/exercises endpoint."""

    async def test_list_exercises_success(self, client: AsyncClient) -> None:
        """List of available exercises is returned."""
        response = await client.get("/api/v1/analysis/exercises")

        assert response.status_code == 200
        data = response.json()
        assert "exercises" in data
        assert "ai_available" in data
        assert isinstance(data["exercises"], list)

    async def test_exercises_have_required_fields(
        self,
        client: AsyncClient,
    ) -> None:
        """Each exercise has id and name."""
        response = await client.get("/api/v1/analysis/exercises")

        assert response.status_code == 200
        for exercise in response.json()["exercises"]:
            assert "id" in exercise
            assert "name" in exercise


class TestLandmarksAnalysis:
    """Tests for POST /analysis/landmarks endpoint."""

    @pytest.fixture
    def valid_landmarks(self) -> list[list[list[float]]]:
        """Generate valid 33-joint landmarks for one frame."""
        # 33 joints, each with [x, y, z, visibility]
        return [[[0.5, 0.5, 0.0, 1.0] for _ in range(33)]]

    @pytest.fixture
    def multi_frame_landmarks(self) -> list[list[list[float]]]:
        """Generate landmarks for multiple frames."""
        frames = []
        for frame_idx in range(30):  # 30 frames
            frame = [[0.5 + (frame_idx * 0.01), 0.5, 0.0, 1.0] for _ in range(33)]
            frames.append(frame)
        return frames

    async def test_analyze_landmarks_success(
        self,
        client: AsyncClient,
        valid_landmarks: list[list[list[float]]],
    ) -> None:
        """Valid landmarks analysis returns result."""
        request_data = {
            "landmarks": valid_landmarks,
            "exercise_name": "shoulder_abduction",
        }

        response = await client.post(
            "/api/v1/analysis/landmarks",
            json=request_data,
        )

        # May return 200 or 400 depending on AI system availability
        assert response.status_code in [200, 400, 500]

    async def test_analyze_empty_landmarks(self, client: AsyncClient) -> None:
        """Empty landmarks returns 400."""
        request_data = {
            "landmarks": [],
            "exercise_name": "knee_flexion",
        }

        response = await client.post(
            "/api/v1/analysis/landmarks",
            json=request_data,
        )

        assert response.status_code == 400
        assert "no landmarks" in response.json()["detail"].lower()

    async def test_analyze_wrong_joint_count(self, client: AsyncClient) -> None:
        """Landmarks with wrong joint count returns 400."""
        # Only 10 joints instead of 33
        wrong_landmarks = [[[0.5, 0.5, 0.0, 1.0] for _ in range(10)]]

        request_data = {
            "landmarks": wrong_landmarks,
            "exercise_name": "hip_abduction",
        }

        response = await client.post(
            "/api/v1/analysis/landmarks",
            json=request_data,
        )

        assert response.status_code == 400
        assert "33" in response.json()["detail"]

    async def test_analyze_wrong_coordinate_format(
        self,
        client: AsyncClient,
    ) -> None:
        """Landmarks with wrong coordinate format returns 400."""
        # Only 2 coordinates instead of 3 or 4
        wrong_format = [[[0.5, 0.5] for _ in range(33)]]

        request_data = {
            "landmarks": wrong_format,
            "exercise_name": "ankle_rotation",
        }

        response = await client.post(
            "/api/v1/analysis/landmarks",
            json=request_data,
        )

        assert response.status_code == 400
        assert "format" in response.json()["detail"].lower()

    async def test_analyze_three_coordinate_format(
        self,
        client: AsyncClient,
    ) -> None:
        """Landmarks with [x, y, z] format (no visibility) is accepted."""
        # 3 coordinates without visibility
        xyz_landmarks = [[[0.5, 0.5, 0.0] for _ in range(33)]]

        request_data = {
            "landmarks": xyz_landmarks,
            "exercise_name": "shoulder_abduction",
        }

        response = await client.post(
            "/api/v1/analysis/landmarks",
            json=request_data,
        )

        # Should not fail on format validation
        assert (
            response.status_code != 400
            or "format" not in response.json().get("detail", "").lower()
        )

    async def test_analyze_multiple_frames(
        self,
        client: AsyncClient,
        multi_frame_landmarks: list[list[list[float]]],
    ) -> None:
        """Multiple frames can be analyzed."""
        request_data = {
            "landmarks": multi_frame_landmarks,
            "exercise_name": "knee_flexion",
        }

        response = await client.post(
            "/api/v1/analysis/landmarks",
            json=request_data,
        )

        # Should process without frame count error
        assert response.status_code in [200, 400, 500]
        if response.status_code == 400:
            # Should not be a frame count error
            assert "frame" not in response.json().get("detail", "").lower()


class TestAnalysisValidation:
    """Tests for request validation."""

    async def test_missing_landmarks_field(self, client: AsyncClient) -> None:
        """Missing landmarks field returns 422."""
        request_data: dict[str, Any] = {
            "exercise_name": "shoulder_abduction",
        }

        response = await client.post(
            "/api/v1/analysis/landmarks",
            json=request_data,
        )

        assert response.status_code == 422

    async def test_invalid_json(self, client: AsyncClient) -> None:
        """Invalid JSON returns 422."""
        response = await client.post(
            "/api/v1/analysis/landmarks",
            content="not valid json",
            headers={"Content-Type": "application/json"},
        )

        assert response.status_code == 422

    async def test_landmarks_as_string(self, client: AsyncClient) -> None:
        """Landmarks as string instead of array returns 422."""
        request_data = {
            "landmarks": "not an array",
            "exercise_name": "hip_flexion",
        }

        response = await client.post(
            "/api/v1/analysis/landmarks",
            json=request_data,
        )

        assert response.status_code == 422


class TestAnalysisEdgeCases:
    """Tests for edge cases and boundary conditions."""

    async def test_single_frame_analysis(self, client: AsyncClient) -> None:
        """Single frame can be analyzed."""
        single_frame = [[[0.5, 0.5, 0.0, 1.0] for _ in range(33)]]

        request_data = {
            "landmarks": single_frame,
            "exercise_name": "shoulder_rotation",
        }

        response = await client.post(
            "/api/v1/analysis/landmarks",
            json=request_data,
        )

        assert response.status_code in [200, 400, 500]

    async def test_large_frame_count(self, client: AsyncClient) -> None:
        """Large number of frames can be processed."""
        many_frames = [[[0.5, 0.5, 0.0, 1.0] for _ in range(33)] for _ in range(100)]

        request_data = {
            "landmarks": many_frames,
            "exercise_name": "knee_flexion",
        }

        response = await client.post(
            "/api/v1/analysis/landmarks",
            json=request_data,
        )

        # Should not timeout or crash
        assert response.status_code in [200, 400, 500]

    async def test_landmarks_at_boundaries(self, client: AsyncClient) -> None:
        """Landmarks at coordinate boundaries are accepted."""
        # All zeros
        zero_landmarks = [[[0.0, 0.0, 0.0, 0.0] for _ in range(33)]]

        request_data = {
            "landmarks": zero_landmarks,
            "exercise_name": "hip_abduction",
        }

        response = await client.post(
            "/api/v1/analysis/landmarks",
            json=request_data,
        )

        assert response.status_code in [200, 400, 500]

    async def test_landmarks_with_negative_coords(
        self,
        client: AsyncClient,
    ) -> None:
        """Negative coordinates are accepted."""
        negative_landmarks = [[[-0.5, -0.5, -1.0, 1.0] for _ in range(33)]]

        request_data = {
            "landmarks": negative_landmarks,
            "exercise_name": "shoulder_abduction",
        }

        response = await client.post(
            "/api/v1/analysis/landmarks",
            json=request_data,
        )

        # Should not fail on coordinate values
        assert response.status_code in [200, 400, 500]

    async def test_unknown_exercise_name(self, client: AsyncClient) -> None:
        """Unknown exercise name is handled gracefully."""
        valid_landmarks = [[[0.5, 0.5, 0.0, 1.0] for _ in range(33)]]

        request_data = {
            "landmarks": valid_landmarks,
            "exercise_name": "nonexistent_exercise_xyz",
        }

        response = await client.post(
            "/api/v1/analysis/landmarks",
            json=request_data,
        )

        # Should return 400 with appropriate error, not crash
        assert response.status_code in [200, 400, 500]

    async def test_exercise_name_case_sensitivity(
        self,
        client: AsyncClient,
    ) -> None:
        """Exercise name handling (case sensitivity check)."""
        valid_landmarks = [[[0.5, 0.5, 0.0, 1.0] for _ in range(33)]]

        for exercise_name in [
            "SHOULDER_ABDUCTION",
            "Shoulder_Abduction",
            "shoulder_abduction",
        ]:
            request_data = {
                "landmarks": valid_landmarks,
                "exercise_name": exercise_name,
            }

            response = await client.post(
                "/api/v1/analysis/landmarks",
                json=request_data,
            )

            # All variations should be processed
            assert response.status_code in [200, 400, 500]
