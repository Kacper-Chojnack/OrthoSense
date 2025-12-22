"""Real-time exercise analysis endpoints via WebSockets.

Provides WebSocket endpoint for streaming video frames and receiving
real-time pose analysis feedback.

PRIVACY NOTE: Server-side video analysis is DISABLED by default.
The primary architecture uses Edge AI on mobile devices - video never leaves the device.
This endpoint exists ONLY for internal testing with explicit consent.
Enable via ENABLE_SERVER_SIDE_ANALYSIS=true environment variable.
"""

import contextlib
import json
from typing import Any

import cv2
import numpy as np
from fastapi import APIRouter, WebSocket, WebSocketDisconnect
from starlette import status as ws_status

from app.ai.core.config import EXERCISE_CLASSES
from app.core.ai_system import get_ai_system, is_ai_available
from app.core.config import settings
from app.core.logging import get_logger

router = APIRouter()
logger = get_logger(__name__)

# Security: Maximum message size for WebSocket (1MB)
MAX_WS_MESSAGE_SIZE = 1024 * 1024  # 1MB
MAX_JSON_SIZE = 1024 * 1024  # Increased to 1MB for tests sending base64 images in JSON


class ConnectionManager:
    """Manages active WebSocket connections."""

    def __init__(self) -> None:
        self.active_connections: dict[str, WebSocket] = {}

    async def connect(self, client_id: str, websocket: WebSocket) -> None:
        """Accept and register new connection."""
        await websocket.accept()
        self.active_connections[client_id] = websocket
        logger.info("client_connected", client_id=client_id)

    def disconnect(self, client_id: str) -> None:
        """Remove connection from registry."""
        self.active_connections.pop(client_id, None)
        logger.info("client_disconnected", client_id=client_id)

    async def send_json(self, client_id: str, data: dict[str, Any]) -> None:
        """Send JSON data to specific client."""
        websocket = self.active_connections.get(client_id)
        if websocket:
            await websocket.send_text(json.dumps(data))


manager = ConnectionManager()


@router.get("/exercises")
async def list_exercises() -> dict[str, Any]:
    """List available exercises for analysis."""
    return {
        "exercises": [
            {"id": idx, "name": name} for idx, name in EXERCISE_CLASSES.items()
        ],
        "ai_available": is_ai_available(),
    }


@router.get("/status")
async def get_ai_status() -> dict[str, Any]:
    """Get AI system status."""
    available = is_ai_available()

    result: dict[str, Any] = {
        "ai_available": available,
        "status": "ready" if available else "unavailable",
    }

    if available:
        try:
            system = get_ai_system()
            result["initialized"] = system.is_initialized
            result["current_exercise"] = system.current_exercise
        except Exception as e:
            result["error"] = str(e)

    return result


async def _handle_text_message(
    client_id: str,
    text_content: str,
    ai_system: Any,
    manager: ConnectionManager,
) -> None:
    """Handle text/JSON commands from WebSocket."""
    if len(text_content) > MAX_JSON_SIZE:
        logger.warning(
            "ws_json_too_large",
            client_id=client_id,
            size=len(text_content),
        )
        await manager.send_json(
            client_id,
            {"error": "JSON message too large", "max_size": MAX_JSON_SIZE},
        )
        return

    try:
        data = json.loads(text_content)
        action = data.get("action")

        if action == "start":
            exercise = data.get("exercise", "Deep Squat")
            if ai_system.set_exercise(exercise):
                await manager.send_json(
                    client_id,
                    {
                        "status": "started",
                        "exercise": exercise,
                        "feedback": f"Starting {exercise} analysis",
                        "voice_message": f"Get ready for {exercise}",
                    },
                )
            else:
                await manager.send_json(
                    client_id,
                    {
                        "error": f"Unknown exercise: {exercise}",
                        "supported": list(EXERCISE_CLASSES.values()),
                    },
                )

        elif action == "stop":
            ai_system.reset()
            await manager.send_json(
                client_id,
                {
                    "status": "stopped",
                    "feedback": "Analysis stopped",
                },
            )

        elif action == "reset":
            ai_system.reset()
            await manager.send_json(
                client_id,
                {
                    "status": "reset",
                    "feedback": "Buffer cleared",
                },
            )

        elif action == "ping":
            await manager.send_json(client_id, {"status": "pong"})

    except json.JSONDecodeError:
        logger.warning("invalid_json", client_id=client_id)


async def _handle_binary_message(
    client_id: str,
    frame_bytes: bytes,
    ai_system: Any,
    manager: ConnectionManager,
) -> None:
    """Handle binary video frame data."""
    if len(frame_bytes) > MAX_WS_MESSAGE_SIZE:
        logger.warning(
            "ws_frame_too_large",
            client_id=client_id,
            size=len(frame_bytes),
        )
        # We don't close the connection here to be more resilient, just warn
        await manager.send_json(
            client_id,
            {"error": "Frame too large", "max_size": MAX_WS_MESSAGE_SIZE},
        )
        return

    # Decode JPEG to numpy array
    nparr = np.frombuffer(frame_bytes, np.uint8)
    frame = cv2.imdecode(nparr, cv2.IMREAD_COLOR)

    if frame is None:
        await manager.send_json(
            client_id,
            {
                "error": "Invalid frame data",
                "feedback": "Camera error",
            },
        )
        return

    # Analyze frame using AI system
    result = ai_system.analyze_frame(frame)

    # Send result back
    await manager.send_json(client_id, result.to_dict())


@router.websocket("/ws/{client_id}")
async def websocket_analysis_endpoint(
    websocket: WebSocket,
    client_id: str,
) -> None:
    """WebSocket endpoint for real-time exercise analysis.

    PRIVACY: This endpoint is DISABLED by default (enable_server_side_analysis=false).
    The primary OrthoSense architecture uses Edge AI - video never leaves the device.
    Enable ONLY for internal testing with explicit user consent.
    """
    # Privacy gate: Reject connections if server-side analysis is disabled
    if not settings.enable_server_side_analysis:
        logger.warning(
            "server_side_analysis_rejected",
            client_id=client_id,
            reason="Feature disabled - use Edge AI on mobile device",
        )
        await websocket.close(
            code=ws_status.WS_1008_POLICY_VIOLATION,
            reason="Server-side video analysis is disabled. Use Edge AI on device.",
        )
        return

    await manager.connect(client_id, websocket)

    # Check AI availability
    if not is_ai_available():
        await websocket.send_text(
            json.dumps(
                {
                    "error": "AI system unavailable",
                    "feedback": "AI not loaded - contact support",
                    "voice_message": "",
                    "is_correct": False,
                    "score": 0,
                }
            )
        )
        await websocket.close()
        manager.disconnect(client_id)
        return

    ai_system = get_ai_system()

    try:
        while True:
            # Receive message (can be text command or binary frame)
            message = await websocket.receive()

            if message.get("type") == "websocket.disconnect":
                break

            if "text" in message:
                await _handle_text_message(
                    client_id, message["text"], ai_system, manager
                )

            elif "bytes" in message:
                await _handle_binary_message(
                    client_id, message["bytes"], ai_system, manager
                )

    except WebSocketDisconnect:
        logger.info("ws_client_disconnected", client_id=client_id)
    except Exception as e:
        logger.exception("ws_analysis_error", client_id=client_id, error=str(e))
        with contextlib.suppress(Exception):
            await websocket.send_text(
                json.dumps(
                    {
                        "status": "error",
                        "message": str(e),
                    }
                )
            )
    finally:
        manager.disconnect(client_id)
        ai_system.reset()
        with contextlib.suppress(Exception):
            await websocket.close()
