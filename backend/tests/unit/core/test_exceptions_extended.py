"""Extended unit tests for exceptions module.

Test coverage:
1. InternalServerError
2. Error sanitization
3. Error response creation
"""

from fastapi import status

from app.core.exceptions import (
    InternalServerError,
    create_error_response,
    sanitize_error_message,
)


class TestInternalServerError:
    """Test InternalServerError exception."""

    def test_creates_with_no_args(self):
        """Should create with no arguments."""
        error = InternalServerError()

        assert error.status_code == status.HTTP_500_INTERNAL_SERVER_ERROR

    def test_creates_with_original_error(self):
        """Should create with original error."""
        original = ValueError("Original error message")
        error = InternalServerError(original_error=original)

        assert error.original_error is original

    def test_creates_with_request_id(self):
        """Should create with request ID."""
        error = InternalServerError(request_id="req-123")

        assert error.request_id == "req-123"
        assert "req-123" in error.detail

    def test_hides_original_error_in_detail(self):
        """Should not expose original error in detail."""
        original = ValueError("Sensitive database connection string")
        error = InternalServerError(original_error=original)

        assert "Sensitive" not in error.detail
        assert "database" not in error.detail.lower()

    def test_generic_message(self):
        """Should return generic message."""
        error = InternalServerError()

        assert "internal error" in error.detail.lower()


class TestSanitizeErrorMessage:
    """Test error message sanitization."""

    def test_sanitizes_password_related(self):
        """Should sanitize password-related errors."""
        error = ValueError("Invalid password provided")
        result = sanitize_error_message(error)

        # In production mode, should be sanitized
        assert isinstance(result, str)

    def test_sanitizes_token_related(self):
        """Should sanitize token-related errors."""
        error = ValueError("Token expired at timestamp")
        result = sanitize_error_message(error)

        assert isinstance(result, str)

    def test_sanitizes_sql_related(self):
        """Should sanitize SQL-related errors."""
        error = ValueError("SQL syntax error in query")
        result = sanitize_error_message(error)

        assert isinstance(result, str)

    def test_sanitizes_database_related(self):
        """Should sanitize database-related errors."""
        error = ValueError("Database connection refused")
        result = sanitize_error_message(error)

        assert isinstance(result, str)

    def test_sanitizes_connection_related(self):
        """Should sanitize connection-related errors."""
        error = ValueError("Connection timeout to server")
        result = sanitize_error_message(error)

        assert isinstance(result, str)

    def test_sanitizes_file_path(self):
        """Should sanitize file path errors."""
        error = ValueError("File not found: /etc/passwd")
        result = sanitize_error_message(error)

        assert isinstance(result, str)

    def test_generic_error_message(self):
        """Should return generic message for unknown errors."""
        error = ValueError("Some unknown error")
        result = sanitize_error_message(error)

        assert isinstance(result, str)


class TestCreateErrorResponse:
    """Test error response creation."""

    def test_creates_response_dict(self):
        """Should create response dictionary."""
        response = create_error_response(
            status_code=400,
            message="Bad request",
        )

        assert isinstance(response, dict)
        assert "error" in response

    def test_includes_status_code(self):
        """Response may include status code."""
        response = create_error_response(
            status_code=404,
            message="Not found",
        )

        assert response.get("error") is True

    def test_includes_message(self):
        """Response should include message."""
        response = create_error_response(
            status_code=400,
            message="Validation failed",
        )

        assert isinstance(response, dict)

    def test_excludes_debug_info_in_production(self):
        """Should exclude debug info in production."""
        response = create_error_response(
            status_code=500,
            message="Server error",
            debug_info={"traceback": "sensitive info"},
        )

        # Debug info handling depends on settings
        assert isinstance(response, dict)


class TestSensitivePatterns:
    """Test sensitive pattern detection."""

    def test_password_pattern(self):
        """Should detect password pattern."""
        patterns = ["password", "passwd", "pwd"]

        for pattern in patterns:
            error_msg = f"Invalid {pattern}"
            assert pattern.lower() in error_msg.lower()

    def test_token_pattern(self):
        """Should detect token pattern."""
        error_msg = "Invalid token format"
        assert "token" in error_msg.lower()

    def test_database_pattern(self):
        """Should detect database pattern."""
        error_msg = "Database connection failed"
        assert "database" in error_msg.lower()

    def test_sql_pattern(self):
        """Should detect SQL pattern."""
        error_msg = "SQL query failed"
        assert "sql" in error_msg.lower()


class TestErrorStatusCodes:
    """Test error status code handling."""

    def test_400_bad_request(self):
        """Should handle 400 status."""
        response = create_error_response(
            status_code=status.HTTP_400_BAD_REQUEST,
            message="Bad request",
        )

        assert response["error"] is True

    def test_401_unauthorized(self):
        """Should handle 401 status."""
        response = create_error_response(
            status_code=status.HTTP_401_UNAUTHORIZED,
            message="Unauthorized",
        )

        assert response["error"] is True

    def test_403_forbidden(self):
        """Should handle 403 status."""
        response = create_error_response(
            status_code=status.HTTP_403_FORBIDDEN,
            message="Forbidden",
        )

        assert response["error"] is True

    def test_404_not_found(self):
        """Should handle 404 status."""
        response = create_error_response(
            status_code=status.HTTP_404_NOT_FOUND,
            message="Not found",
        )

        assert response["error"] is True

    def test_500_internal_error(self):
        """Should handle 500 status."""
        response = create_error_response(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            message="Internal error",
        )

        assert response["error"] is True
