"""Real-time exercise analysis via WebSockets.

Handles live video frame analysis using the OrthoSense AI system.
Phone sends image bytes -> Server processes -> Returns JSON feedback.
"""

import contextlib
import json
from typing import Any

import cv2
import numpy as np
from fastapi import APIRouter, WebSocket, WebSocketDisconnect

from app.core.ai_system import (
    LiveAnalysisSession,
    get_ai_system,
    get_available_exercises,
    is_ai_available,
)
from app.core.logging import get_logger

router = APIRouter()
logger = get_logger(__name__)

active_sessions: dict[str, LiveAnalysisSession] = {}


@router.get("/exercises")
async def list_exercises() -> dict[str, Any]:
    """List available exercises for analysis."""
    exercises = get_available_exercises()
    return {
        "exercises": [{"id": idx, "name": name} for idx, name in exercises.items()],
        "ai_available": is_ai_available(),
    }


@router.websocket("/ws/{client_id}")
async def websocket_analysis_endpoint(
    websocket: WebSocket,
    client_id: str,
) -> None:
    """WebSocket endpoint for real-time exercise analysis.

    Protocol:
    1. Client connects
    2. Client sends JSON: {"action": "start", "exercise": "Deep Squat"}
    3. Client sends binary image frames (JPEG bytes)
    4. Server responds with JSON: {"feedback": "...", "voice_message": "...", "score": 0-100}
    5. Client sends JSON: {"action": "stop"} to end session

    Args:
        websocket: WebSocket connection
        client_id: Unique client identifier
    """
    await websocket.accept()
    logger.info("ws_client_connected", client_id=client_id)

    session: LiveAnalysisSession | None = None

    try:
        ai_system = get_ai_system()
        processor = ai_system.processor

        while True:
            message = await websocket.receive()

            if message.get("type") == "websocket.disconnect":
                break

            if "text" in message:
                data = json.loads(message["text"])
                action = data.get("action")

                if action == "start":
                    exercise_name = data.get("exercise", "Deep Squat")
                    session = LiveAnalysisSession(exercise_name)
                    active_sessions[client_id] = session
                    logger.info(
                        "analysis_session_started",
                        client_id=client_id,
                        exercise=exercise_name,
                    )
                    await websocket.send_json(
                        {
                            "status": "started",
                            "exercise": exercise_name,
                            "message": f"Ready to analyze {exercise_name}",
                        }
                    )

                elif action == "stop":
                    if client_id in active_sessions:
                        del active_sessions[client_id]
                    session = None
                    logger.info("analysis_session_stopped", client_id=client_id)
                    await websocket.send_json(
                        {
                            "status": "stopped",
                            "message": "Session ended",
                        }
                    )

                elif action == "ping":
                    await websocket.send_json({"status": "pong"})

            elif "bytes" in message and session is not None:
                frame_bytes = message["bytes"]

                nparr = np.frombuffer(frame_bytes, np.uint8)
                frame = cv2.imdecode(nparr, cv2.IMREAD_COLOR)

                if frame is None:
                    continue

                frame_rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
                frame_rgb = cv2.resize(frame_rgb, (640, 480))

                world_landmarks, _ = processor.process_frame(frame_rgb)

                if world_landmarks is not None:
                    session.add_frame(world_landmarks)

                    if session.can_analyze():
                        window = session.get_window()
                        result = ai_system.analyze_live_frame(
                            window,
                            forced_exercise=session.exercise_name,
                        )

                        feedback = result.get("feedback", "")
                        is_correct = result.get("is_correct", True)

                        voice_message = ""
                        if feedback and feedback != session.last_feedback:
                            session.last_feedback = feedback
                            session.last_is_correct = is_correct

                            if not is_correct and "ERRORS:" in feedback:
                                errors = feedback.replace("ERRORS:", "").strip()
                                voice_message = errors.split(",")[0].strip()
                            elif is_correct:
                                voice_message = "Good form!"

                        score = 100 if is_correct else 50

                        await websocket.send_json(
                            {
                                "feedback": feedback,
                                "voice_message": voice_message,
                                "is_correct": is_correct,
                                "score": score,
                                "frames_buffered": len(session.frame_buffer),
                            }
                        )
                    else:
                        await websocket.send_json(
                            {
                                "status": "buffering",
                                "frames_buffered": len(session.frame_buffer),
                                "frames_needed": session.MIN_FRAMES,
                            }
                        )
                else:
                    await websocket.send_json(
                        {
                            "status": "no_pose",
                            "message": "No person detected in frame",
                        }
                    )

    except WebSocketDisconnect:
        logger.info("ws_client_disconnected", client_id=client_id)
    except Exception as e:
        logger.exception("ws_analysis_error", client_id=client_id, error=str(e))
        with contextlib.suppress(Exception):
            await websocket.send_json(
                {
                    "status": "error",
                    "message": str(e),
                }
            )
    finally:
        if client_id in active_sessions:
            del active_sessions[client_id]
        with contextlib.suppress(Exception):
            await websocket.close()
