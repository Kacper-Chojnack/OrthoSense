"""Singleton wrapper for OrthoSense AI System.

Provides global access to AI system with lazy initialization.
The system is heavy (loads ML models), so we use singleton pattern.
"""

from typing import TYPE_CHECKING

from app.core.logging import get_logger

if TYPE_CHECKING:
    from app.ai.core.system import AnalysisSession, OrthoSenseSystem

logger = get_logger(__name__)

_ai_instance: "OrthoSenseSystem | None" = None
_ai_available: bool | None = None


def is_ai_available() -> bool:
    """Check if AI dependencies are available.

    Returns:
        True if mediapipe and torch are installed.
    """
    global _ai_available

    if _ai_available is not None:
        return _ai_available

    try:
        import mediapipe  # type: ignore[import-untyped]  # noqa: F401
        import torch  # noqa: F401

        _ai_available = True
    except ImportError:
        _ai_available = False
        logger.warning(
            "ai_dependencies_missing",
            hint="Install with: pip install mediapipe torch",
        )

    return _ai_available


def get_ai_system() -> "OrthoSenseSystem":
    """Get the global AI system instance.

    Lazy initialization - creates instance on first call.

    Returns:
        Initialized OrthoSenseSystem instance.

    Raises:
        RuntimeError: If AI dependencies are not available.
    """
    global _ai_instance

    if not is_ai_available():
        raise RuntimeError(
            "AI system unavailable. Install dependencies: pip install mediapipe torch"
        )

    if _ai_instance is None:
        from app.ai.core.system import OrthoSenseSystem

        _ai_instance = OrthoSenseSystem()
        _ai_instance.initialize()
        logger.info("ai_system_singleton_created")

    return _ai_instance


def create_analysis_session(exercise: str = "Deep Squat") -> "AnalysisSession":
    """Create a new analysis session for a user.

    Args:
        exercise: Initial exercise for the session.

    Returns:
        New isolated AnalysisSession instance.

    Raises:
        RuntimeError: If AI dependencies are not available.
    """
    system = get_ai_system()
    return system.create_session(exercise=exercise)


def reset_ai_system() -> None:
    """Reset the AI system (for testing)."""
    global _ai_instance

    if _ai_instance is not None:
        _ai_instance.close()
        _ai_instance = None
