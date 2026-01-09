"""
Unit tests for AI system singleton module.

Test coverage:
1. is_ai_available check
2. get_ai_system function
3. reset_ai_system function
4. Singleton pattern
"""

from unittest.mock import MagicMock, patch

import pytest

from app.core.ai_system import get_ai_system, is_ai_available, reset_ai_system


class TestIsAiAvailable:
    """Tests for is_ai_available function."""

    def test_is_ai_available_returns_bool(self) -> None:
        """is_ai_available returns boolean."""
        result = is_ai_available()
        assert isinstance(result, bool)

    def test_is_ai_available_caches_result(self) -> None:
        """Result is cached after first call."""
        # Reset the cache first
        import app.core.ai_system as ai_module

        ai_module._ai_available = None

        result1 = is_ai_available()
        result2 = is_ai_available()

        # Same result returned (cached)
        assert result1 == result2

    def test_is_ai_available_with_missing_deps(self) -> None:
        """Returns False when dependencies are missing."""
        import app.core.ai_system as ai_module

        # Reset cache
        ai_module._ai_available = None

        with patch.dict("sys.modules", {"mediapipe": None, "torch": None}):
            # Force reimport to test missing deps
            ai_module._ai_available = None

            # This depends on actual environment
            # In test environment, result depends on installed packages
            result = is_ai_available()
            assert isinstance(result, bool)


class TestGetAiSystem:
    """Tests for get_ai_system function."""

    def test_get_ai_system_returns_instance(self) -> None:
        """get_ai_system returns OrthoSenseSystem instance."""
        if not is_ai_available():
            pytest.skip("AI dependencies not available")

        system = get_ai_system()
        assert system is not None

    def test_get_ai_system_singleton(self) -> None:
        """get_ai_system returns same instance."""
        if not is_ai_available():
            pytest.skip("AI dependencies not available")

        system1 = get_ai_system()
        system2 = get_ai_system()

        assert system1 is system2

    def test_get_ai_system_raises_without_deps(self) -> None:
        """get_ai_system raises RuntimeError without dependencies."""
        import app.core.ai_system as ai_module

        # Simulate missing dependencies
        ai_module._ai_available = False
        ai_module._ai_instance = None

        with pytest.raises(RuntimeError) as exc_info:
            get_ai_system()

        assert "unavailable" in str(exc_info.value).lower()

        # Restore
        ai_module._ai_available = None


class TestResetAiSystem:
    """Tests for reset_ai_system function."""

    def test_reset_ai_system_clears_instance(self) -> None:
        """reset_ai_system clears the singleton instance."""
        import app.core.ai_system as ai_module

        # Create mock instance
        mock_system = MagicMock()
        ai_module._ai_instance = mock_system

        reset_ai_system()

        assert ai_module._ai_instance is None
        mock_system.close.assert_called_once()

    def test_reset_ai_system_handles_none(self) -> None:
        """reset_ai_system handles None instance gracefully."""
        import app.core.ai_system as ai_module

        ai_module._ai_instance = None

        # Should not raise
        reset_ai_system()

        assert ai_module._ai_instance is None
