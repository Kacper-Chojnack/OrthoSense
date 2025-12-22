from unittest.mock import MagicMock, patch

import pytest
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


def test_get_status():
    """Test GET /status endpoint."""
    with (
        patch("app.api.v1.endpoints.analysis.is_ai_available", return_value=True),
        patch("app.api.v1.endpoints.analysis.get_ai_system") as mock_get,
    ):
        mock_system = MagicMock()
        mock_system.is_initialized = True
        mock_system.current_exercise = "Test"
        mock_get.return_value = mock_system

        response = client.get(f"{settings.api_v1_prefix}/analysis/status")
        assert response.status_code == 200
        data = response.json()
        assert data["ai_available"] is True
        assert data["status"] == "ready"


def test_websocket_rejected_when_disabled():
    """Test WebSocket connection rejected when feature flag is off."""
    # Save original setting
    original_setting = settings.enable_server_side_analysis
    settings.enable_server_side_analysis = False

    try:
        with (
            client.websocket_connect(
                f"{settings.api_v1_prefix}/analysis/ws/test_client"
            ) as websocket,
            pytest.raises(Exception),
        ):  # noqa: B017
            # Should be closed immediately
            websocket.receive_text()
    except Exception:
        # Expected connection close
        pass
    finally:
        settings.enable_server_side_analysis = original_setting


def test_websocket_flow():
    """Test WebSocket interaction."""
    original_setting = settings.enable_server_side_analysis
    settings.enable_server_side_analysis = True

    try:
        with (
            patch("app.api.v1.endpoints.analysis.is_ai_available", return_value=True),
            patch("app.api.v1.endpoints.analysis.get_ai_system") as mock_get,
        ):
            mock_system = MagicMock()
            mock_system.set_exercise.return_value = True
            mock_get.return_value = mock_system

            with client.websocket_connect(
                f"{settings.api_v1_prefix}/analysis/ws/test_client"
            ) as websocket:
                # Test text message (Start)
                websocket.send_json({"action": "start", "exercise": "Deep Squat"})
                data = websocket.receive_json()
                assert data["status"] == "started"

                # Test text message (Ping)
                websocket.send_json({"action": "ping"})
                data = websocket.receive_json()
                assert data["status"] == "pong"

                # Test binary message (Mock Frame)
                # Create a small dummy JPEG
                import cv2
                import numpy as np

                img = np.zeros((100, 100, 3), dtype=np.uint8)
                _, img_encoded = cv2.imencode(".jpg", img)
                websocket.send_bytes(img_encoded.tobytes())

                # Should receive analysis result
                # We need to mock analyze_frame return
                mock_result = MagicMock()
                mock_result.to_dict.return_value = {"feedback": "Good"}
                mock_system.analyze_frame.return_value = mock_result

                data = websocket.receive_json()
                assert data["feedback"] == "Good"

    finally:
        settings.enable_server_side_analysis = original_setting
