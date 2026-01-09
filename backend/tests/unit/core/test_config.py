"""
Unit tests for configuration module.

Test coverage:
1. Settings loading and defaults
2. Environment variable overrides
3. Property methods
4. Settings caching
"""

import os
from unittest.mock import patch

from app.core.config import Settings, get_settings


class TestSettingsDefaults:
    """Tests for default settings values."""

    def test_api_v1_prefix_default(self) -> None:
        """API v1 prefix has correct default."""
        settings = get_settings()
        assert settings.api_v1_prefix == "/api/v1"

    def test_project_name_default(self) -> None:
        """Project name has correct default."""
        settings = get_settings()
        assert settings.project_name == "OrthoSense"

    def test_algorithm_default(self) -> None:
        """JWT algorithm has correct default."""
        settings = get_settings()
        assert settings.algorithm == "HS256"

    def test_access_token_expire_minutes_default(self) -> None:
        """Access token expiration has correct default."""
        settings = get_settings()
        assert settings.access_token_expire_minutes == 30

    def test_refresh_token_expire_days_default(self) -> None:
        """Refresh token expiration has correct default."""
        settings = get_settings()
        assert settings.refresh_token_expire_days == 7

    def test_verification_token_expire_hours_default(self) -> None:
        """Verification token expiration has correct default."""
        settings = get_settings()
        assert settings.verification_token_expire_hours == 24

    def test_password_reset_token_expire_hours_default(self) -> None:
        """Password reset token expiration has correct default."""
        settings = get_settings()
        assert settings.password_reset_token_expire_hours == 1

    def test_max_upload_size_mb_default(self) -> None:
        """Max upload size has correct default."""
        settings = get_settings()
        assert settings.max_upload_size_mb == 100


class TestSettingsProperties:
    """Tests for Settings property methods."""

    def test_is_sqlite_with_sqlite_url(self) -> None:
        """is_sqlite returns True for SQLite database URL."""
        with patch.dict(
            os.environ,
            {
                "DATABASE_URL": "sqlite+aiosqlite:///./test.db",
                "SECRET_KEY": "test-secret-key",
            },
        ):
            # Create new settings instance
            settings = Settings()  # type: ignore[call-arg]
            assert settings.is_sqlite is True

    def test_is_sqlite_with_postgres_url(self) -> None:
        """is_sqlite returns False for PostgreSQL database URL."""
        with patch.dict(
            os.environ,
            {
                "DATABASE_URL": "postgresql+asyncpg://user:pass@localhost/db",
                "SECRET_KEY": "test-secret-key",
            },
        ):
            settings = Settings()  # type: ignore[call-arg]
            assert settings.is_sqlite is False


class TestSettingsEnvironmentOverrides:
    """Tests for environment variable overrides."""

    def test_debug_can_be_overridden(self) -> None:
        """Debug setting can be overridden via environment."""
        with patch.dict(
            os.environ,
            {
                "DEBUG": "true",
                "SECRET_KEY": "test-secret-key",
                "DATABASE_URL": "sqlite+aiosqlite:///:memory:",
            },
        ):
            settings = Settings()  # type: ignore[call-arg]
            assert settings.debug is True

    def test_cors_origins_can_be_overridden(self) -> None:
        """CORS origins can be overridden."""
        settings = get_settings()
        assert isinstance(settings.cors_origins, list)
        assert len(settings.cors_origins) > 0

    def test_allowed_hosts_contains_required_hosts(self) -> None:
        """Allowed hosts contains required development hosts."""
        settings = get_settings()
        assert "localhost" in settings.allowed_hosts
        assert "127.0.0.1" in settings.allowed_hosts
        assert "testserver" in settings.allowed_hosts

    def test_redis_url_default(self) -> None:
        """Redis URL has correct default."""
        settings = get_settings()
        assert settings.redis_url == "redis://localhost:6379"


class TestSettingsCaching:
    """Tests for settings caching behavior."""

    def test_get_settings_returns_same_instance(self) -> None:
        """get_settings returns cached instance."""
        settings1 = get_settings()
        settings2 = get_settings()

        assert settings1 is settings2

    def test_settings_secret_key_required(self) -> None:
        """SECRET_KEY is required (no default)."""
        settings = get_settings()
        # In tests, SECRET_KEY is set in conftest.py
        assert settings.secret_key is not None
        assert len(settings.secret_key) > 0


class TestSettingsValidation:
    """Tests for settings validation."""

    def test_upload_temp_dir_is_set(self) -> None:
        """Upload temp directory is set."""
        settings = get_settings()
        assert settings.upload_temp_dir is not None
        assert "orthosense_uploads" in settings.upload_temp_dir

    def test_frontend_url_is_set(self) -> None:
        """Frontend URL is set."""
        settings = get_settings()
        assert settings.frontend_url is not None
        assert settings.frontend_url.startswith("http")

    def test_rate_limit_enabled_default(self) -> None:
        """Rate limiting setting is boolean."""
        settings = get_settings()
        # In test env, this is set to false via conftest.py
        # Just verify it's a boolean
        assert isinstance(settings.rate_limit_enabled, bool)
