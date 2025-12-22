import json
import os

import cv2
import pytest
from fastapi.testclient import TestClient

from app.core.config import settings
from app.main import app

# Base path for test videos
TEST_VIDEOS_DIR = os.path.join(os.path.dirname(__file__), "..", "app", "test")

# List of video files to test
VIDEO_FILES = [
    "Deep Squats.mp4",
    "standing-shoulder-abduction1.mp4",
    "standing-shoulder-abduction2.mp4",
    "standing-shoulder-abduction3.mp4",
]


@pytest.fixture(autouse=True)
def enable_server_side_analysis():
    """Temporarily enable server-side analysis for WebSocket tests.

    NOTE: Server-side video analysis is DISABLED by default for privacy.
    This fixture enables it ONLY for testing the internal WebSocket endpoint.
    """
    original_value = settings.enable_server_side_analysis
    settings.enable_server_side_analysis = True
    yield
    settings.enable_server_side_analysis = original_value


@pytest.mark.parametrize("video_filename", VIDEO_FILES)
def test_e2e_video_analysis_websocket(video_filename):
    """
    E2E test that simulates a client sending video frames to the analysis WebSocket.
    Runs for each video file in the list.
    """
    video_path = os.path.join(TEST_VIDEOS_DIR, video_filename)

    if not os.path.exists(video_path):
        pytest.skip(f"Test video not found: {video_path}")

    client = TestClient(app, base_url="http://localhost")

    # Open video file
    cap = cv2.VideoCapture(video_path)
    assert cap.isOpened(), f"Failed to open video file: {video_path}"

    frame_count = 0
    analyzed_count = 0

    # Determine exercise name from filename (simple heuristic)
    exercise_name = "Deep Squat" if "Squat" in video_filename else "Standing Shoulder Abduction"

    try:
        # Use a dummy client_id for the test
        client_id = "test_client_123"
        with client.websocket_connect(
            f"/api/v1/analysis/ws/{client_id}", headers={"Host": "localhost"}
        ) as websocket:
            
            # 1. Send START command
            start_payload = {
                "action": "start",
                "exercise": exercise_name
            }
            websocket.send_text(json.dumps(start_payload))
            
            # Receive start confirmation
            response = websocket.receive_json()
            assert response["status"] == "started"
            assert response["exercise"] == exercise_name

            while True:
                ret, frame = cap.read()
                if not ret:
                    break

                frame_count += 1

                # Encode frame to JPEG
                _, buffer = cv2.imencode(".jpg", frame)
                
                # Send BINARY frame
                websocket.send_bytes(buffer.tobytes())

                # Receive analysis result (Server responds to EVERY frame)
                response = websocket.receive_json()

                # Basic validation of the response
                if "error" in response:
                     # If frame too large or invalid, we might get error
                     pass
                else:
                    # Analysis result
                    assert "feedback" in response
                    assert "score" in response
                    analyzed_count += 1

                # Limit the test to a certain number of frames to avoid running too long
                # 30 frames is enough to verify flow
                if frame_count >= 30:
                    break
            
            # Send STOP command
            stop_payload = {"action": "stop"}
            websocket.send_text(json.dumps(stop_payload))
            response = websocket.receive_json()
            assert response["status"] == "stopped"

    finally:
        cap.release()

    print(
        f"\nProcessed {frame_count} frames from {video_filename}, received {analyzed_count} analysis results."
    )
    assert analyzed_count > 0, "Should have received at least one analysis result"
