"""Exercise analysis endpoints.

Provides metadata about supported exercises and video file analysis.
Real-time WebSocket analysis is currently disabled for reimplementation.
"""

import os
from typing import Any

import aiofiles
from fastapi import (
    APIRouter,
    File,
    HTTPException,
    UploadFile,
    status,
)

from app.ai.core.config import EXERCISE_NAMES
from app.ai.core.system import OrthoSenseSystem
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
    import uuid
    from pathlib import Path

    if not file.filename:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST, detail="No filename provided"
        )

    # Whitelist mapping - use hardcoded extension values (not user input)
    allowed_extensions: dict[str, str] = {
        ".mp4": ".mp4",
        ".mov": ".mov",
        ".avi": ".avi",
        ".mkv": ".mkv",
    }

    # Extract and normalize extension from filename
    _, raw_ext = os.path.splitext(file.filename)
    normalized_ext = raw_ext.lower()

    # Get safe extension from whitelist (prevents tainted data flow)
    safe_ext = allowed_extensions.get(normalized_ext)
    if safe_ext is None:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Unsupported file format. Allowed: {', '.join(allowed_extensions.keys())}",
        )

    # Create upload directory
    upload_dir = Path(settings.upload_temp_dir).resolve()
    upload_dir.mkdir(parents=True, exist_ok=True)

    # Generate safe filename using UUID (no user input in path)
    safe_filename = f"temp_{uuid.uuid4().hex}{safe_ext}"
    temp_path = (upload_dir / safe_filename).resolve()

    # Defense in depth: verify path is within allowed directory
    if not temp_path.is_relative_to(upload_dir):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid file path",
        )

    try:
        async with aiofiles.open(temp_path, "wb") as buffer:
            content = await file.read()
            await buffer.write(content)

        system = OrthoSenseSystem()
        result = system.analyze_video_file(str(temp_path))

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
        if temp_path.exists():
            temp_path.unlink()


@router.get("/realtime/status")
async def realtime_status() -> dict[str, Any]:
    """Check if real-time analysis is available."""
    return {
        "available": False,
        "message": "Real-time analysis is currently being reimplemented. "
        "Please use video file analysis instead.",
    }
