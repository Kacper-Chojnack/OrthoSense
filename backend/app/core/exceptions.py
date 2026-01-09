"""Exception handling utilities for production safety.

Sanitizes error messages to prevent information leakage in production.
Exposes detailed errors only in debug mode.
"""

from typing import Any

from fastapi import HTTPException, Request, status
from fastapi.responses import JSONResponse

from app.core.config import settings
from app.core.logging import get_logger

logger = get_logger(__name__)


class InternalServerError(HTTPException):
    """Generic internal server error for production.

    Hides implementation details from clients while logging full error.
    """

    def __init__(
        self,
        original_error: Exception | None = None,
        request_id: str | None = None,
    ) -> None:
        self.original_error = original_error
        self.request_id = request_id

        # Log the full error for debugging
        if original_error:
            logger.error(
                "internal_server_error",
                error_type=type(original_error).__name__,
                error_message=str(original_error),
                request_id=request_id,
            )

        # Generic message for production
        detail = "An internal error occurred. Please try again later."
        if request_id:
            detail += f" (Reference: {request_id})"

        super().__init__(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=detail,
        )


def sanitize_error_message(error: Exception) -> str:
    """Sanitize error message for production.

    In debug mode, returns full error message.
    In production, returns generic message.
    """
    if settings.debug:
        return str(error)

    # Mapping of sensitive error patterns to generic messages
    sensitive_patterns = {
        "password": "Authentication error",
        "token": "Authentication error",
        "sql": "Database error",
        "database": "Database error",
        "connection": "Service unavailable",
        "timeout": "Request timed out",
        "permission": "Access denied",
        "file": "Resource error",
        "path": "Resource error",
    }

    error_str = str(error).lower()
    for pattern, generic_msg in sensitive_patterns.items():
        if pattern in error_str:
            return generic_msg

    return "An unexpected error occurred"


def create_error_response(
    status_code: int,
    message: str,
    *,
    debug_info: dict[str, Any] | None = None,
) -> dict[str, Any]:
    """Create standardized error response.

    Args:
        status_code: HTTP status code.
        message: Error message (sanitized for production).
        debug_info: Additional debug info (only included in debug mode).

    Returns:
        Error response dictionary.
    """
    response: dict[str, Any] = {
        "error": True,
        "status_code": status_code,
        "message": message,
    }

    if settings.debug and debug_info:
        response["debug"] = debug_info

    return response


async def global_exception_handler(
    request: Request,
    exc: Exception,
) -> JSONResponse:
    """Global exception handler for unhandled errors.

    Catches all exceptions not handled by specific handlers,
    logs them, and returns sanitized error response.
    """
    # Generate request ID for tracking
    request_id = request.headers.get("X-Request-ID", str(id(request)))

    # Log the full error
    logger.error(
        "unhandled_exception",
        error_type=type(exc).__name__,
        error_message=str(exc),
        request_id=request_id,
        path=request.url.path,
        method=request.method,
    )

    # Return sanitized response
    if settings.debug:
        # In debug mode, expose error details
        return JSONResponse(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            content={
                "error": True,
                "message": str(exc),
                "type": type(exc).__name__,
                "request_id": request_id,
            },
        )

    # In production, return generic error
    return JSONResponse(
        status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
        content={
            "error": True,
            "message": "An internal error occurred. Please try again later.",
            "request_id": request_id,
        },
    )


async def http_exception_handler(
    request: Request,
    exc: HTTPException,
) -> JSONResponse:
    """Handler for HTTPException with sanitization.

    For 500 errors, sanitizes the message in production.
    For other errors, preserves the original message.
    """
    request_id = request.headers.get("X-Request-ID", str(id(request)))

    # For 5xx errors, sanitize in production
    if exc.status_code >= 500 and not settings.debug:
        logger.error(
            "http_exception",
            status_code=exc.status_code,
            detail=exc.detail,
            request_id=request_id,
            path=request.url.path,
        )
        return JSONResponse(
            status_code=exc.status_code,
            content={
                "error": True,
                "message": "An internal error occurred. Please try again later.",
                "request_id": request_id,
            },
        )

    # For client errors (4xx), return original message
    return JSONResponse(
        status_code=exc.status_code,
        content={
            "detail": exc.detail,
        },
        headers=exc.headers,
    )
