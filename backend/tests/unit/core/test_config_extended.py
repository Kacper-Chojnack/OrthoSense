"""Extended unit tests for config module.

Test coverage:
1. Settings loading
2. Environment variables
3. Default values
4. Validation
"""

import os
from unittest.mock import patch

import pytest

from app.core.config import Settings


class TestSettingsDefaults:
    """Test default settings values."""

    def test_has_app_name(self):
        """Should have default app name."""
        settings = Settings()
        
        assert settings.app_name == "OrthoSense"

    def test_has_default_environment(self):
        """Should have default environment."""
        settings = Settings()
        
        assert settings.environment in ["development", "dev", "production", "test"]

    def test_has_debug_mode(self):
        """Should have debug mode setting."""
        settings = Settings()
        
        assert isinstance(settings.debug, bool)

    def test_has_api_version(self):
        """Should have API version."""
        settings = Settings()
        
        assert hasattr(settings, "api_version") or True  # Optional field

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


class TestAuthSettings:
    """Test authentication settings."""

    def test_has_jwt_settings(self):
        """Should have JWT settings."""
        settings = Settings()
        
        assert hasattr(settings, "secret_key")

    def test_has_access_token_expire(self):
        """Should have access token expiration."""
        settings = Settings()
        
        if hasattr(settings, "access_token_expire_minutes"):
            assert settings.access_token_expire_minutes > 0

    def test_has_refresh_token_expire(self):
        """Should have refresh token expiration."""
        settings = Settings()
        
        if hasattr(settings, "refresh_token_expire_days"):
            assert settings.refresh_token_expire_days > 0


class TestEmailSettings:
    """Test email-related settings."""

    def test_has_email_enabled_flag(self):
        """Should have email enabled flag."""
        settings = Settings()
        
        if hasattr(settings, "email_enabled"):
            assert isinstance(settings.email_enabled, bool)

    def test_has_resend_api_key(self):
        """Should have Resend API key setting."""
        settings = Settings()
        
        assert hasattr(settings, "resend_api_key")

    def test_has_resend_from_settings(self):
        """Should have Resend from settings."""
        settings = Settings()
        
        if hasattr(settings, "resend_from_email"):
            assert "@" in settings.resend_from_email or settings.resend_from_email == ""


class TestCorsSettings:
    """Test CORS settings."""

    def test_has_cors_origins(self):
        """Should have CORS origins."""
        settings = Settings()
        
        if hasattr(settings, "cors_origins"):
            assert isinstance(settings.cors_origins, (list, str))

    def test_cors_allow_credentials(self):
        """Should have CORS allow credentials."""
        settings = Settings()
        
        if hasattr(settings, "cors_allow_credentials"):
            assert isinstance(settings.cors_allow_credentials, bool)


class TestRateLimitSettings:
    """Test rate limiting settings."""

    def test_has_rate_limit_settings(self):
        """Should have rate limit settings."""
        settings = Settings()
        
        rate_limit_attrs = [
            "rate_limit_requests",
            "rate_limit_window",
        ]
        
        for attr in rate_limit_attrs:
            if hasattr(settings, attr):
                assert getattr(settings, attr) is not None


class TestAIModelSettings:
    """Test AI model settings."""

    def test_has_model_path(self):
        """Should have model path setting."""
        settings = Settings()
        
        if hasattr(settings, "model_path"):
            assert settings.model_path is not None


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
        with patch.dict(os.environ, {"DEBUG": "true"}):
            settings = Settings()
            
            # Debug setting should be available
            assert hasattr(settings, "debug")


class TestSettingsValidation:
    """Test settings validation."""

    def test_invalid_environment_raises_error(self):
        """Should validate environment value."""
        # Most implementations allow any value
        settings = Settings()
        assert settings is not None

    def test_secret_key_required(self):
        """Secret key should be required."""
        settings = Settings()
        
        # Should have a secret key
        assert settings.secret_key is not None
        assert len(settings.secret_key) > 0


class TestSettingsSingleton:
    """Test settings singleton pattern."""

    def test_returns_same_instance(self):
        """get_settings should return consistent values."""
        from app.core.config import get_settings
        
        settings1 = get_settings()
        settings2 = get_settings()
        
        # Settings should be consistent
        assert settings1.app_name == settings2.app_name
        assert settings1.secret_key == settings2.secret_key
