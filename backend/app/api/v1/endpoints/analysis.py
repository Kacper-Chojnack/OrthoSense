"""Exercise analysis endpoints.

Provides metadata about supported exercises, video file analysis,
and real-time WebSocket analysis with session-based architecture.
"""

import contextlib
import json
import os
from typing import Any

import aiofiles
import cv2
import numpy as np
from fastapi import (
    APIRouter,
    File,
    HTTPException,
    UploadFile,
    WebSocket,
    WebSocketDisconnect,
    status,
)

from app.ai.core.config import EXERCISE_NAMES
from app.ai.core.system import AnalysisSession, OrthoSenseSystem
from app.core.config import settings
from app.core.logging import get_logger

router = APIRouter()
logger = get_logger(__name__)


@router.get("/exercises")
async def list_exercises() -> dict[str, Any]:
    """List available exercises for analysis."""
    return {
        "exercises": [
            {"id": idx, "name": name} for idx, name in EXERCISE_NAMES.items()
        ],
        "ai_available": True,
    }


@router.post("/video", status_code=status.HTTP_200_OK)
async def analyze_video_file(
    file: UploadFile = File(...),
) -> dict[str, Any]:
    """
    Upload and analyze a pre-recorded video file.

    Accepts video formats: MP4, MOV, AVI, MKV.
    Returns exercise classification, correctness assessment, and feedback.
    """
    if not file.filename:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST, detail="No filename provided"
        )

    allowed_extensions = {".mp4", ".mov", ".avi", ".mkv"}
    file_ext = os.path.splitext(file.filename)[1].lower()
    if file_ext not in allowed_extensions:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Unsupported file format. Allowed: {', '.join(allowed_extensions)}",
        )

    os.makedirs(settings.upload_temp_dir, exist_ok=True)

    temp_path = os.path.join(settings.upload_temp_dir, f"temp_{file.filename}")

    try:
        async with aiofiles.open(temp_path, "wb") as buffer:
            content = await file.read()
            await buffer.write(content)

        system = OrthoSenseSystem()
        result = system.analyze_video_file(temp_path)

        if "error" in result:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST, detail=result["error"]
            )

        return result

    except HTTPException:
        raise
    except Exception as e:
        logger.error("video_analysis_failed", error=str(e))
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Analysis failed: {e!s}",
        ) from e
    finally:
        if os.path.exists(temp_path):
            os.remove(temp_path)


@router.websocket("/ws/{client_id}")
async def websocket_endpoint(websocket: WebSocket, client_id: str) -> None:
    """
    Real-time exercise analysis WebSocket endpoint.

    Architecture:
    - Creates a unique AnalysisSession for each connection.
    - Uses the shared OrthoSenseSystem for inference.
    - Ensures isolation between concurrent users (no race conditions).

    Protocol:
    - Send JSON: {"action": "start", "exercise": "Deep Squat"} to begin session
    - Send binary: JPEG/PNG encoded frame for analysis
    - Send JSON: {"action": "stop"} to end session

    Receives:
    - JSON: Analysis results with feedback and classification
    """
    await websocket.accept()

    system = OrthoSenseSystem()
    if not system.is_initialized:
        system.initialize()

    # Create isolated session for this user
    session: AnalysisSession = system.create_session()
    session.session_id = client_id

    logger.info("websocket_connected", client_id=client_id)

    try:
        while True:
            message = await websocket.receive()

            # Handle text commands
            if "text" in message and message["text"]:
                await _handle_text_command(websocket, system, session, message["text"])

            # Handle binary frame data
            elif "bytes" in message and message["bytes"]:
                await _handle_frame(websocket, system, session, message["bytes"])

    except WebSocketDisconnect:
        logger.info("websocket_disconnected", client_id=client_id)
    except Exception as e:
        logger.error("websocket_error", client_id=client_id, error=str(e))
        with contextlib.suppress(Exception):
            await websocket.close(code=status.WS_1011_INTERNAL_ERROR)


async def _handle_text_command(
    websocket: WebSocket,
    system: OrthoSenseSystem,
    session: AnalysisSession,
    text: str,
) -> None:
    """Handle JSON control commands from WebSocket."""
    try:
        data = json.loads(text)
        action = data.get("action")

        if action == "start":
            exercise = data.get("exercise", "Deep Squat")
            system.set_exercise(session, exercise)
            await websocket.send_json(
                {
                    "status": "started",
                    "exercise": exercise,
                    "message": "Session initialized",
                }
            )

        elif action == "stop":
            session.reset()
            await websocket.send_json({"status": "stopped"})

    except json.JSONDecodeError:
        await websocket.send_json({"error": "Invalid JSON"})


async def _handle_frame(
    websocket: WebSocket,
    system: OrthoSenseSystem,
    session: AnalysisSession,
    frame_bytes: bytes,
) -> None:
    """Handle binary frame data from WebSocket."""
    nparr = np.frombuffer(frame_bytes, np.uint8)
    frame = cv2.imdecode(nparr, cv2.IMREAD_COLOR)

    if frame is None:
        await websocket.send_json({"error": "Invalid frame data"})
        return

    result = system.analyze_frame(frame, session)
    await websocket.send_json(result.to_dict())
