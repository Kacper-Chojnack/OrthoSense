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
