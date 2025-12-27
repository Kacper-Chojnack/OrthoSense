"""Tests for analysis endpoints.

Note: WebSocket tests have been removed as real-time analysis
is disabled for reimplementation.
"""

from fastapi.testclient import TestClient

from app.core.config import settings
from app.main import app

client = TestClient(app)


def test_list_exercises():
    """Test GET /exercises endpoint."""
    response = client.get(f"{settings.api_v1_prefix}/analysis/exercises")
    assert response.status_code == 200
    data = response.json()
    assert "exercises" in data
    assert isinstance(data["exercises"], list)
    assert "ai_available" in data
    assert "realtime_available" in data
    assert data["realtime_available"] is False


def test_realtime_status():
    """Test GET /realtime/status endpoint."""
    response = client.get(f"{settings.api_v1_prefix}/analysis/realtime/status")
    assert response.status_code == 200
    data = response.json()
    assert data["available"] is False
    assert "message" in data
