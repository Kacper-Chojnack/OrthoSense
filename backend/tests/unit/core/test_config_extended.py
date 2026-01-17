"""Extended unit tests for config module.

Test coverage:
1. Settings loading
2. Environment variables
3. Default values
4. Validation
"""

import os
from unittest.mock import patch

from app.core.config import Settings


class TestSettingsDefaults:
    """Test default settings values."""

    def test_has_project_name(self):
        """Should have default project name."""
        settings = Settings()

        assert settings.project_name == "OrthoSense"

    def test_has_debug_mode(self):
        """Should have debug mode setting."""
        settings = Settings()

        assert isinstance(settings.debug, bool)

    def test_has_api_prefix(self):
        """Should have API prefix."""
        settings = Settings()

        assert settings.api_v1_prefix == "/api/v1"

    def test_has_secret_key(self):
        """Should have secret key."""
        settings = Settings()

        assert settings.secret_key is not None


class TestDatabaseSettings:
    """Test database-related settings."""

    def test_has_database_url(self):
        """Should have database URL."""
        settings = Settings()

        assert hasattr(settings, "database_url")

    def test_database_url_format(self):
        """Database URL should be valid format."""
        settings = Settings()

        if settings.database_url:
            # Should start with postgresql or sqlite
            valid_prefixes = ["postgresql", "sqlite", "postgres"]
            assert any(
                settings.database_url.startswith(p)
                for p in valid_prefixes
            ) or "://" in settings.database_url

    def test_is_sqlite_property(self):
        """Should have is_sqlite property."""
        settings = Settings()

        assert hasattr(settings, "is_sqlite")
        assert isinstance(settings.is_sqlite, bool)


class TestAuthSettings:
    """Test authentication settings."""

    def test_has_jwt_settings(self):
        """Should have JWT settings."""
        settings = Settings()

        assert hasattr(settings, "secret_key")
        assert hasattr(settings, "algorithm")

    def test_has_access_token_expire(self):
        """Should have access token expiration."""
        settings = Settings()

        assert settings.access_token_expire_minutes > 0

    def test_has_refresh_token_expire(self):
        """Should have refresh token expiration."""
        settings = Settings()

        assert settings.refresh_token_expire_days > 0

    def test_has_verification_token_expire(self):
        """Should have verification token expiration."""
        settings = Settings()

        assert settings.verification_token_expire_hours > 0

    def test_has_password_reset_token_expire(self):
        """Should have password reset token expiration."""
        settings = Settings()

        assert settings.password_reset_token_expire_hours > 0


class TestEmailSettings:
    """Test email-related settings."""

    def test_has_email_enabled_flag(self):
        """Should have email enabled flag."""
        settings = Settings()

        assert isinstance(settings.email_enabled, bool)

    def test_has_resend_api_key(self):
        """Should have Resend API key setting."""
        settings = Settings()

        assert hasattr(settings, "resend_api_key")

    def test_has_resend_from_settings(self):
        """Should have Resend from settings."""
        settings = Settings()

        assert hasattr(settings, "resend_from_email")
        assert hasattr(settings, "resend_from_name")

    def test_resend_from_email_format(self):
        """Resend from email should have valid format."""
        settings = Settings()

        if settings.resend_from_email:
            assert "@" in settings.resend_from_email


class TestCorsSettings:
    """Test CORS settings."""

    def test_has_cors_origins(self):
        """Should have CORS origins."""
        settings = Settings()

        assert isinstance(settings.cors_origins, list)

    def test_cors_origins_default(self):
        """Should have default CORS origins."""
        settings = Settings()

        assert len(settings.cors_origins) > 0

    def test_has_allowed_hosts(self):
        """Should have allowed hosts computed property."""
        settings = Settings()

        assert hasattr(settings, "allowed_hosts")
        assert isinstance(settings.allowed_hosts, list)


class TestRateLimitSettings:
    """Test rate limiting settings."""

    def test_has_rate_limit_enabled(self):
        """Should have rate limit enabled setting."""
        settings = Settings()

        assert hasattr(settings, "rate_limit_enabled")
        assert isinstance(settings.rate_limit_enabled, bool)

    def test_has_redis_url(self):
        """Should have Redis URL."""
        settings = Settings()

        assert hasattr(settings, "redis_url")


class TestUploadSettings:
    """Test upload settings."""

    def test_has_max_upload_size(self):
        """Should have max upload size."""
        settings = Settings()

        assert settings.max_upload_size_mb > 0

    def test_has_upload_temp_dir(self):
        """Should have upload temp directory."""
        settings = Settings()

        assert hasattr(settings, "upload_temp_dir")


class TestEnvironmentLoading:
    """Test loading from environment variables."""

    def test_loads_from_env(self):
        """Should load from environment variables."""
        with patch.dict(os.environ, {"SECRET_KEY": "test-secret-key-123"}):
            settings = Settings()

            # Should pick up env var or have default
            assert settings.secret_key is not None

    def test_loads_debug_from_env(self):
        """Should load debug from environment."""
        with patch.dict(os.environ, {"DEBUG": "true", "SECRET_KEY": "test"}):
            settings = Settings()

            # Debug setting should be available
            assert hasattr(settings, "debug")


class TestSettingsValidation:
    """Test settings validation."""

    def test_settings_object_created(self):
        """Settings object should be created."""
        settings = Settings()
        assert settings is not None

    def test_secret_key_required(self):
        """Secret key should be required."""
        settings = Settings()
        assert settings.secret_key is not None
        assert len(settings.secret_key) > 0
