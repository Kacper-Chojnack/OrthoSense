"""
Unit tests for Exception handling module.

Test coverage:
1. InternalServerError class
2. sanitize_error_message function
3. create_error_response function
4. global_exception_handler function
5. http_exception_handler function
"""

from unittest.mock import MagicMock, patch

import pytest
from fastapi import HTTPException, status

from app.core.exceptions import (
    InternalServerError,
    create_error_response,
    global_exception_handler,
    http_exception_handler,
    sanitize_error_message,
)


class TestInternalServerError:
    """Tests for InternalServerError exception class."""

    def test_internal_server_error_basic(self) -> None:
        """InternalServerError creates with default message."""
        error = InternalServerError()

        assert error.status_code == status.HTTP_500_INTERNAL_SERVER_ERROR
        assert "internal error" in error.detail.lower()

    def test_internal_server_error_with_original_error(self) -> None:
        """InternalServerError logs original error."""
        original = ValueError("Something went wrong")
        error = InternalServerError(original_error=original)

        assert error.original_error == original
        assert error.status_code == 500

    def test_internal_server_error_with_request_id(self) -> None:
        """InternalServerError includes request ID in detail."""
        error = InternalServerError(request_id="req-12345")

        assert error.request_id == "req-12345"
        assert "req-12345" in error.detail

    def test_internal_server_error_with_both(self) -> None:
        """InternalServerError handles both original error and request ID."""
        original = RuntimeError("Database connection failed")
        error = InternalServerError(
            original_error=original,
            request_id="req-abcdef",
        )

        assert error.original_error == original
        assert error.request_id == "req-abcdef"
        assert "req-abcdef" in error.detail


class TestSanitizeErrorMessage:
    """Tests for sanitize_error_message function."""

    def test_sanitize_password_error(self) -> None:
        """Password-related errors are sanitized."""
        with patch("app.core.exceptions.settings") as mock_settings:
            mock_settings.debug = False

            result = sanitize_error_message(
                ValueError("Invalid password: bcrypt hash failed")
            )

            assert result == "Authentication error"

    def test_sanitize_token_error(self) -> None:
        """Token-related errors are sanitized."""
        with patch("app.core.exceptions.settings") as mock_settings:
            mock_settings.debug = False

            result = sanitize_error_message(ValueError("JWT token verification failed"))

            assert result == "Authentication error"

    def test_sanitize_sql_error(self) -> None:
        """SQL-related errors are sanitized."""
        with patch("app.core.exceptions.settings") as mock_settings:
            mock_settings.debug = False

            result = sanitize_error_message(
                ValueError("SQL syntax error in SELECT statement")
            )

            assert result == "Database error"

    def test_sanitize_database_error(self) -> None:
        """Database-related errors are sanitized."""
        with patch("app.core.exceptions.settings") as mock_settings:
            mock_settings.debug = False

            result = sanitize_error_message(ValueError("Database connection refused"))

            assert result == "Database error"

    def test_sanitize_connection_error(self) -> None:
        """Connection-related errors are sanitized."""
        with patch("app.core.exceptions.settings") as mock_settings:
            mock_settings.debug = False

            result = sanitize_error_message(ValueError("Connection refused to server"))

            assert result == "Service unavailable"

    def test_sanitize_timeout_error(self) -> None:
        """Timeout-related errors are sanitized."""
        with patch("app.core.exceptions.settings") as mock_settings:
            mock_settings.debug = False

            result = sanitize_error_message(ValueError("Request timeout after 30s"))

            assert result == "Request timed out"

    def test_sanitize_permission_error(self) -> None:
        """Permission-related errors are sanitized."""
        with patch("app.core.exceptions.settings") as mock_settings:
            mock_settings.debug = False

            result = sanitize_error_message(ValueError("Permission denied to access"))

            assert result == "Access denied"

    def test_sanitize_file_error(self) -> None:
        """File-related errors are sanitized."""
        with patch("app.core.exceptions.settings") as mock_settings:
            mock_settings.debug = False

            result = sanitize_error_message(ValueError("File not found: /etc/passwd"))

            assert result == "Resource error"

    def test_sanitize_path_error(self) -> None:
        """Path-related errors are sanitized."""
        with patch("app.core.exceptions.settings") as mock_settings:
            mock_settings.debug = False

            result = sanitize_error_message(ValueError("Invalid path traversal"))

            assert result == "Resource error"

    def test_sanitize_unknown_error(self) -> None:
        """Unknown errors get generic message."""
        with patch("app.core.exceptions.settings") as mock_settings:
            mock_settings.debug = False

            result = sanitize_error_message(ValueError("Something happened"))

            assert result == "An unexpected error occurred"

    def test_debug_mode_shows_full_error(self) -> None:
        """Debug mode shows full error message."""
        with patch("app.core.exceptions.settings") as mock_settings:
            mock_settings.debug = True

            error_msg = "Full error details: password=secret123"
            result = sanitize_error_message(ValueError(error_msg))

            assert result == error_msg


class TestCreateErrorResponse:
    """Tests for create_error_response function."""

    def test_create_error_response_basic(self) -> None:
        """Creates basic error response."""
        response = create_error_response(400, "Bad request")

        assert response["error"] is True
        assert response["status_code"] == 400
        assert response["message"] == "Bad request"
        assert "debug" not in response

    def test_create_error_response_without_debug_info_in_prod(self) -> None:
        """Debug info is not included in production."""
        with patch("app.core.exceptions.settings") as mock_settings:
            mock_settings.debug = False

            response = create_error_response(
                500,
                "Server error",
                debug_info={"traceback": "sensitive info"},
            )

            assert "debug" not in response

    def test_create_error_response_with_debug_info_in_debug(self) -> None:
        """Debug info is included in debug mode."""
        with patch("app.core.exceptions.settings") as mock_settings:
            mock_settings.debug = True

            response = create_error_response(
                500,
                "Server error",
                debug_info={"traceback": "detailed error info"},
            )

            assert "debug" in response
            assert response["debug"]["traceback"] == "detailed error info"

    def test_create_error_response_various_status_codes(self) -> None:
        """Works with various status codes."""
        codes = [400, 401, 403, 404, 422, 500, 502, 503]

        for code in codes:
            response = create_error_response(code, f"Error {code}")
            assert response["status_code"] == code


class TestGlobalExceptionHandler:
    """Tests for global_exception_handler function."""

    @pytest.mark.asyncio
    async def test_global_handler_debug_mode(self) -> None:
        """Global handler exposes details in debug mode."""
        with patch("app.core.exceptions.settings") as mock_settings:
            mock_settings.debug = True

            request = MagicMock()
            request.headers = {"X-Request-ID": "req-123"}
            request.url.path = "/api/test"
            request.method = "GET"

            exc = ValueError("Test error message")
            response = await global_exception_handler(request, exc)

            assert response.status_code == 500
            # Response body contains error details in debug mode
            import json

            body = json.loads(response.body.decode())
            assert body["error"] is True
            assert "Test error" in body["message"]
            assert body["type"] == "ValueError"
            assert body["request_id"] == "req-123"

    @pytest.mark.asyncio
    async def test_global_handler_production_mode(self) -> None:
        """Global handler sanitizes in production mode."""
        with patch("app.core.exceptions.settings") as mock_settings:
            mock_settings.debug = False

            request = MagicMock()
            request.headers = {}
            request.url.path = "/api/test"
            request.method = "POST"

            exc = ValueError("Password hash failed with secret data")
            response = await global_exception_handler(request, exc)

            assert response.status_code == 500
            import json

            body = json.loads(response.body.decode())
            assert body["error"] is True
            assert "internal error" in body["message"].lower()
            # Sensitive info not exposed
            assert "Password" not in body["message"]
            assert "secret" not in body["message"]

    @pytest.mark.asyncio
    async def test_global_handler_uses_header_request_id(self) -> None:
        """Global handler uses X-Request-ID from headers."""
        with patch("app.core.exceptions.settings") as mock_settings:
            mock_settings.debug = False

            request = MagicMock()
            request.headers = {"X-Request-ID": "custom-req-id-456"}
            request.url.path = "/api/test"
            request.method = "GET"

            exc = RuntimeError("Error")
            response = await global_exception_handler(request, exc)

            import json

            body = json.loads(response.body.decode())
            assert body["request_id"] == "custom-req-id-456"

    @pytest.mark.asyncio
    async def test_global_handler_generates_request_id(self) -> None:
        """Global handler generates request ID if not provided."""
        with patch("app.core.exceptions.settings") as mock_settings:
            mock_settings.debug = False

            request = MagicMock()
            request.headers = {}  # No X-Request-ID
            request.url.path = "/api/test"
            request.method = "GET"

            exc = RuntimeError("Error")
            response = await global_exception_handler(request, exc)

            import json

            body = json.loads(response.body.decode())
            assert "request_id" in body


class TestHttpExceptionHandler:
    """Tests for http_exception_handler function."""

    @pytest.mark.asyncio
    async def test_http_handler_4xx_preserves_detail(self) -> None:
        """HTTP handler preserves detail for 4xx errors."""
        request = MagicMock()
        request.headers = {}
        request.url.path = "/api/test"

        exc = HTTPException(
            status_code=400,
            detail="Invalid input data",
        )
        response = await http_exception_handler(request, exc)

        assert response.status_code == 400
        import json

        body = json.loads(response.body.decode())
        assert body["detail"] == "Invalid input data"

    @pytest.mark.asyncio
    async def test_http_handler_401_preserves_detail(self) -> None:
        """HTTP handler preserves detail for 401 errors."""
        request = MagicMock()
        request.headers = {}
        request.url.path = "/api/test"

        exc = HTTPException(
            status_code=401,
            detail="Not authenticated",
            headers={"WWW-Authenticate": "Bearer"},
        )
        response = await http_exception_handler(request, exc)

        assert response.status_code == 401
        import json

        body = json.loads(response.body.decode())
        assert body["detail"] == "Not authenticated"

    @pytest.mark.asyncio
    async def test_http_handler_5xx_sanitizes_in_prod(self) -> None:
        """HTTP handler sanitizes 5xx errors in production."""
        with patch("app.core.exceptions.settings") as mock_settings:
            mock_settings.debug = False

            request = MagicMock()
            request.headers = {"X-Request-ID": "req-500"}
            request.url.path = "/api/test"

            exc = HTTPException(
                status_code=500,
                detail="Database password exposure error",
            )
            response = await http_exception_handler(request, exc)

            assert response.status_code == 500
            import json

            body = json.loads(response.body.decode())
            assert body["error"] is True
            assert "internal error" in body["message"].lower()
            # Sensitive info not exposed
            assert "Database" not in body["message"]
            assert "password" not in body["message"]

    @pytest.mark.asyncio
    async def test_http_handler_502_sanitizes_in_prod(self) -> None:
        """HTTP handler sanitizes 502 errors in production."""
        with patch("app.core.exceptions.settings") as mock_settings:
            mock_settings.debug = False

            request = MagicMock()
            request.headers = {}
            request.url.path = "/api/test"

            exc = HTTPException(
                status_code=502,
                detail="Bad gateway - upstream server failed",
            )
            response = await http_exception_handler(request, exc)

            assert response.status_code == 502
            import json

            body = json.loads(response.body.decode())
            assert body["error"] is True

    @pytest.mark.asyncio
    async def test_http_handler_5xx_shows_detail_in_debug(self) -> None:
        """HTTP handler shows detail for 5xx in debug mode."""
        with patch("app.core.exceptions.settings") as mock_settings:
            mock_settings.debug = True

            request = MagicMock()
            request.headers = {}
            request.url.path = "/api/test"

            exc = HTTPException(
                status_code=500,
                detail="Detailed error info",
            )
            response = await http_exception_handler(request, exc)

            # In debug mode, 4xx-style response is returned
            import json

            body = json.loads(response.body.decode())
            assert body["detail"] == "Detailed error info"

    @pytest.mark.asyncio
    async def test_http_handler_preserves_headers(self) -> None:
        """HTTP handler preserves exception headers for 4xx."""
        request = MagicMock()
        request.headers = {}
        request.url.path = "/api/test"

        exc = HTTPException(
            status_code=401,
            detail="Unauthorized",
            headers={"WWW-Authenticate": "Bearer realm='api'"},
        )
        response = await http_exception_handler(request, exc)

        assert response.headers.get("WWW-Authenticate") == "Bearer realm='api'"

    @pytest.mark.asyncio
    async def test_http_handler_404_error(self) -> None:
        """HTTP handler handles 404 errors correctly."""
        request = MagicMock()
        request.headers = {}
        request.url.path = "/api/unknown"

        exc = HTTPException(
            status_code=404,
            detail="Resource not found",
        )
        response = await http_exception_handler(request, exc)

        assert response.status_code == 404
        import json

        body = json.loads(response.body.decode())
        assert body["detail"] == "Resource not found"

    @pytest.mark.asyncio
    async def test_http_handler_422_validation_error(self) -> None:
        """HTTP handler handles 422 validation errors correctly."""
        request = MagicMock()
        request.headers = {}
        request.url.path = "/api/test"

        exc = HTTPException(
            status_code=422,
            detail=[{"loc": ["body", "email"], "msg": "invalid email"}],
        )
        response = await http_exception_handler(request, exc)

        assert response.status_code == 422
        import json

        body = json.loads(response.body.decode())
        assert body["detail"] == [{"loc": ["body", "email"], "msg": "invalid email"}]
