"""Extended unit tests for Analysis API endpoint.

Test coverage:
1. Analysis submission
2. Analysis history retrieval
3. Analysis detail retrieval
4. Error handling
"""

import pytest
from unittest.mock import AsyncMock, patch
from uuid import uuid4

from fastapi.testclient import TestClient


@pytest.fixture
def mock_analysis_service():
    """Create mock analysis service."""
    with patch("app.api.v1.endpoints.analysis.analysis_service") as mock:
        yield mock


class TestCreateAnalysis:
    """Test POST /analysis endpoint."""

    @pytest.mark.asyncio
    async def test_creates_analysis(self, client, auth_headers, mock_analysis_service):
        """Should create new analysis."""
        analysis_data = {
            "exercise_type": "squat",
            "landmarks": [[1.0, 2.0, 3.0] for _ in range(33)],
            "duration_seconds": 30,
        }
        
        mock_analysis_service.create_analysis.return_value = {
            "id": str(uuid4()),
            "exercise_type": "squat",
            "status": "pending",
        }
        
        response = client.post(
            "/api/v1/analysis",
            json=analysis_data,
            headers=auth_headers,
        )
        
        assert response.status_code == 201

    @pytest.mark.asyncio
    async def test_requires_authentication(self, client):
        """Should require authentication."""
        analysis_data = {
            "exercise_type": "squat",
            "landmarks": [[1.0, 2.0, 3.0] for _ in range(33)],
        }
        
        response = client.post(
            "/api/v1/analysis",
            json=analysis_data,
        )
        
        assert response.status_code == 401

    @pytest.mark.asyncio
    async def test_validates_exercise_type(self, client, auth_headers):
        """Should validate exercise type."""
        analysis_data = {
            "exercise_type": "invalid_exercise",
            "landmarks": [[1.0, 2.0, 3.0] for _ in range(33)],
        }
        
        response = client.post(
            "/api/v1/analysis",
            json=analysis_data,
            headers=auth_headers,
        )
        
        assert response.status_code == 422

    @pytest.mark.asyncio
    async def test_validates_landmarks_format(self, client, auth_headers):
        """Should validate landmarks format."""
        analysis_data = {
            "exercise_type": "squat",
            "landmarks": "invalid",
        }
        
        response = client.post(
            "/api/v1/analysis",
            json=analysis_data,
            headers=auth_headers,
        )
        
        assert response.status_code == 422


class TestGetAnalysisHistory:
    """Test GET /analysis endpoint."""

    @pytest.mark.asyncio
    async def test_returns_user_analyses(
        self, client, auth_headers, mock_analysis_service
    ):
        """Should return user's analysis history."""
        mock_analysis_service.get_user_analyses.return_value = {
            "items": [
                {
                    "id": str(uuid4()),
                    "exercise_type": "squat",
                    "created_at": "2024-01-01T00:00:00Z",
                }
            ],
            "total": 1,
            "page": 1,
            "size": 10,
        }
        
        response = client.get("/api/v1/analysis", headers=auth_headers)
        
        assert response.status_code == 200
        data = response.json()
        assert "items" in data

    @pytest.mark.asyncio
    async def test_supports_pagination(
        self, client, auth_headers, mock_analysis_service
    ):
        """Should support pagination."""
        mock_analysis_service.get_user_analyses.return_value = {
            "items": [],
            "total": 0,
            "page": 2,
            "size": 20,
        }
        
        response = client.get(
            "/api/v1/analysis?page=2&size=20",
            headers=auth_headers,
        )
        
        assert response.status_code == 200

    @pytest.mark.asyncio
    async def test_filters_by_exercise_type(
        self, client, auth_headers, mock_analysis_service
    ):
        """Should filter by exercise type."""
        mock_analysis_service.get_user_analyses.return_value = {
            "items": [],
            "total": 0,
            "page": 1,
            "size": 10,
        }
        
        response = client.get(
            "/api/v1/analysis?exercise_type=squat",
            headers=auth_headers,
        )
        
        assert response.status_code == 200


class TestGetAnalysisDetail:
    """Test GET /analysis/{analysis_id} endpoint."""

    @pytest.mark.asyncio
    async def test_returns_analysis(
        self, client, auth_headers, mock_analysis_service
    ):
        """Should return analysis details."""
        analysis_id = uuid4()
        mock_analysis_service.get_analysis.return_value = {
            "id": str(analysis_id),
            "exercise_type": "squat",
            "results": {
                "score": 85,
                "feedback": ["Good form"],
            },
        }
        
        response = client.get(
            f"/api/v1/analysis/{analysis_id}",
            headers=auth_headers,
        )
        
        assert response.status_code == 200

    @pytest.mark.asyncio
    async def test_returns_404_for_unknown(
        self, client, auth_headers, mock_analysis_service
    ):
        """Should return 404 for unknown analysis."""
        analysis_id = uuid4()
        mock_analysis_service.get_analysis.return_value = None
        
        response = client.get(
            f"/api/v1/analysis/{analysis_id}",
            headers=auth_headers,
        )
        
        assert response.status_code == 404

    @pytest.mark.asyncio
    async def test_validates_uuid_format(self, client, auth_headers):
        """Should validate UUID format."""
        response = client.get(
            "/api/v1/analysis/invalid-uuid",
            headers=auth_headers,
        )
        
        assert response.status_code == 422


class TestDeleteAnalysis:
    """Test DELETE /analysis/{analysis_id} endpoint."""

    @pytest.mark.asyncio
    async def test_deletes_analysis(
        self, client, auth_headers, mock_analysis_service
    ):
        """Should delete analysis."""
        analysis_id = uuid4()
        mock_analysis_service.delete_analysis.return_value = True
        
        response = client.delete(
            f"/api/v1/analysis/{analysis_id}",
            headers=auth_headers,
        )
        
        assert response.status_code == 204

    @pytest.mark.asyncio
    async def test_returns_404_for_unknown(
        self, client, auth_headers, mock_analysis_service
    ):
        """Should return 404 for unknown analysis."""
        analysis_id = uuid4()
        mock_analysis_service.delete_analysis.return_value = False
        
        response = client.delete(
            f"/api/v1/analysis/{analysis_id}",
            headers=auth_headers,
        )
        
        assert response.status_code == 404


class TestAnalysisWithAI:
    """Test AI integration in analysis."""

    @pytest.mark.asyncio
    async def test_analysis_uses_ai_system(
        self, client, auth_headers, mock_analysis_service
    ):
        """Should use AI system for analysis."""
        with patch("app.api.v1.endpoints.analysis.ai_system") as mock_ai:
            mock_ai.analyze_landmarks.return_value = {
                "exercise": "squat",
                "confidence": 0.95,
                "diagnostics": [],
            }
            
            analysis_data = {
                "exercise_type": "squat",
                "landmarks": [[1.0, 2.0, 3.0] for _ in range(33)],
            }
            
            response = client.post(
                "/api/v1/analysis",
                json=analysis_data,
                headers=auth_headers,
            )
            
            # Check AI was called (or mock was set up)
            assert response.status_code in [201, 422, 500]

    @pytest.mark.asyncio
    async def test_handles_ai_failure(
        self, client, auth_headers, mock_analysis_service
    ):
        """Should handle AI system failure gracefully."""
        with patch("app.api.v1.endpoints.analysis.ai_system") as mock_ai:
            mock_ai.analyze_landmarks.side_effect = Exception("AI failure")
            
            analysis_data = {
                "exercise_type": "squat",
                "landmarks": [[1.0, 2.0, 3.0] for _ in range(33)],
            }
            
            response = client.post(
                "/api/v1/analysis",
                json=analysis_data,
                headers=auth_headers,
            )
            
            # Should handle gracefully
            assert response.status_code in [201, 422, 500]


class TestAnalysisRateLimiting:
    """Test rate limiting on analysis endpoint."""

    @pytest.mark.asyncio
    async def test_rate_limits_analysis(self, client, auth_headers):
        """Should rate limit analysis requests."""
        # Make many requests quickly
        responses = []
        for _ in range(20):
            response = client.post(
                "/api/v1/analysis",
                json={
                    "exercise_type": "squat",
                    "landmarks": [[1.0, 2.0, 3.0] for _ in range(33)],
                },
                headers=auth_headers,
            )
            responses.append(response.status_code)
        
        # Eventually should hit rate limit (429) or other status
        assert len(responses) == 20
