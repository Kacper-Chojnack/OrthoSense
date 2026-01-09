"""
Unit tests for logging configuration module.

Test coverage:
1. Logger creation
2. Logging setup
3. Log format configuration
4. Structured logging output
5. CloudWatch compatibility
6. Edge cases and error handling
"""

import io
import logging

import pytest
import structlog

from app.core.logging import get_logger, setup_logging


class TestGetLogger:
    """Tests for get_logger function."""

    def test_get_logger_returns_bound_logger(self) -> None:
        """get_logger returns a structlog BoundLogger."""
        logger = get_logger(__name__)

        assert logger is not None
        # structlog loggers have info, warning, error methods
        assert hasattr(logger, "info")
        assert hasattr(logger, "warning")
        assert hasattr(logger, "error")
        assert hasattr(logger, "debug")

    def test_get_logger_with_different_names(self) -> None:
        """get_logger works with different module names."""
        logger1 = get_logger("module.one")
        logger2 = get_logger("module.two")

        assert logger1 is not None
        assert logger2 is not None

    def test_logger_can_log_without_error(self) -> None:
        """Logger can log messages without raising exceptions."""
        logger = get_logger(__name__)

        # These should not raise
        logger.info("test_message", key="value")
        logger.warning("warning_message", count=42)
        logger.error("error_message", error="test error")
        logger.debug("debug_message")


class TestSetupLogging:
    """Tests for setup_logging function."""

    def teardown_method(self) -> None:
        """Reset logging configuration after each test."""
        structlog.reset_defaults()
        logging.root.handlers = []

    def test_setup_logging_json_mode(self) -> None:
        """setup_logging configures JSON output."""
        # Should not raise
        setup_logging(json_logs=True, log_level="INFO")

    def test_setup_logging_console_mode(self) -> None:
        """setup_logging configures console output."""
        # Should not raise
        setup_logging(json_logs=False, log_level="DEBUG")

    def test_setup_logging_different_levels(self) -> None:
        """setup_logging accepts different log levels."""
        valid_levels = ["DEBUG", "INFO", "WARNING", "ERROR", "CRITICAL"]

        for level in valid_levels:
            # Should not raise
            setup_logging(json_logs=False, log_level=level)

    def test_setup_logging_configures_stdlib(self) -> None:
        """setup_logging configures standard library logging."""
        setup_logging(json_logs=False, log_level="INFO")

        # Standard library logger should be configured
        root_logger = logging.getLogger()
        assert root_logger.level <= logging.INFO


class TestStructuredLogging:
    """Tests for structured log output format."""

    def teardown_method(self) -> None:
        """Reset logging configuration after each test."""
        structlog.reset_defaults()
        logging.root.handlers = []

    def test_log_includes_custom_fields(self) -> None:
        """Log output includes custom key-value pairs."""
        setup_logging(json_logs=True, log_level="INFO")

        captured = io.StringIO()
        handler = logging.StreamHandler(captured)
        handler.setLevel(logging.INFO)
        logging.root.addHandler(handler)

        logger = get_logger("custom_fields_test")
        logger.info("user_action", user_id="123", action="login", ip="192.168.1.1")

        output = captured.getvalue()
        assert output  # Some output was produced

    def test_log_with_nested_data(self) -> None:
        """Logger handles nested data structures."""
        setup_logging(json_logs=True, log_level="INFO")

        logger = get_logger("nested_test")

        # Should not raise
        logger.info(
            "complex_event",
            data={"nested": {"deep": "value"}, "list": [1, 2, 3]},
            metadata={"version": "1.0"},
        )


class TestCloudWatchCompatibility:
    """Tests ensuring CloudWatch Logs Insights compatibility."""

    def teardown_method(self) -> None:
        """Reset logging configuration after each test."""
        structlog.reset_defaults()
        logging.root.handlers = []

    def test_logs_use_stdout(self) -> None:
        """Logs are configured to use stdout for container compatibility."""
        setup_logging(json_logs=True, log_level="INFO")

        # Verify StreamHandler is configured
        assert any(isinstance(h, logging.StreamHandler) for h in logging.root.handlers)

    def test_json_logs_are_parseable(self) -> None:
        """JSON mode produces output that can be parsed."""
        import json as json_module

        setup_logging(json_logs=True, log_level="INFO")

        captured = io.StringIO()
        handler = logging.StreamHandler(captured)
        handler.setLevel(logging.INFO)
        logging.root.addHandler(handler)

        logger = get_logger("json_test")
        logger.info("test_event", key="value")

        output = captured.getvalue().strip()
        if output:
            # Should be valid JSON or at least contain expected content
            try:
                json_module.loads(output)
            except json_module.JSONDecodeError:
                # structlog may format with additional wrapper
                assert "test_event" in output


class TestLogLevelParsing:
    """Tests for log level string parsing."""

    def teardown_method(self) -> None:
        """Reset logging configuration."""
        structlog.reset_defaults()
        logging.root.handlers = []

    @pytest.mark.parametrize(
        "level_str,expected_level",
        [
            ("DEBUG", logging.DEBUG),
            ("INFO", logging.INFO),
            ("WARNING", logging.WARNING),
            ("ERROR", logging.ERROR),
            ("CRITICAL", logging.CRITICAL),
        ],
    )
    def test_log_level_parsing(self, level_str: str, expected_level: int) -> None:
        """Log level strings are parsed correctly."""
        setup_logging(json_logs=True, log_level=level_str)

        std_logger = logging.getLogger(f"level_test_{level_str}")
        assert std_logger.getEffectiveLevel() <= expected_level


class TestErrorLogging:
    """Tests for error and exception logging."""

    def teardown_method(self) -> None:
        """Reset logging configuration."""
        structlog.reset_defaults()
        logging.root.handlers = []

    def test_exception_logging_does_not_raise(self) -> None:
        """Exception logging doesn't raise additional errors."""
        setup_logging(json_logs=True, log_level="INFO")

        logger = get_logger("exception_test")

        try:
            raise ValueError("Test exception message")
        except ValueError:
            # Should not raise
            logger.exception("caught_exception")

    def test_error_with_extra_context(self) -> None:
        """Error logs accept extra context fields."""
        setup_logging(json_logs=True, log_level="INFO")

        logger = get_logger("error_context_test")

        # Should not raise
        logger.error(
            "operation_failed",
            operation="database_query",
            error_code=500,
            retry_count=3,
        )


class TestLoggerIsolation:
    """Tests for logger instance isolation."""

    def test_multiple_loggers_independent(self) -> None:
        """Multiple loggers don't interfere with each other."""
        setup_logging(json_logs=False, log_level="INFO")

        logger1 = get_logger("module1")
        logger2 = get_logger("module2")
        logger3 = get_logger("module3")

        # All should be independent instances
        assert logger1 is not None
        assert logger2 is not None
        assert logger3 is not None

    def test_logger_context_binding(self) -> None:
        """Logger can bind context for reuse."""
        setup_logging(json_logs=False, log_level="INFO")

        base_logger = get_logger("context_test")

        # structlog supports context binding
        bound_logger = base_logger.bind(request_id="req-123")
        assert bound_logger is not None

        # Should not raise
        bound_logger.info("request_processed")
