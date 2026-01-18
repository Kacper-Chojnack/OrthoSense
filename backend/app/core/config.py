"""Application configuration using pydantic-settings.

Environment variables override defaults. Use .env file for local development.
"""

import os
import tempfile
from functools import lru_cache

from pydantic import computed_field
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    """Application settings loaded from environment variables."""

    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=False,
        extra="ignore",
    )

    # API Configuration
    api_v1_prefix: str = "/api/v1"
    project_name: str = "OrthoSense"
    debug: bool = False

    # Database - SQLite for local dev, Postgres for production
    # Format: postgresql+asyncpg://user:pass@host:port/db
    database_url: str = "sqlite+aiosqlite:///./orthosense.db"

    # CORS - Secure origins for production
    # Override in production with specific domains
    cors_origins: list[str] = ["http://localhost:8080", "http://localhost:3000"]

    # Additional allowed host for local mobile testing (set via env var)
    local_test_ip: str = ""

    # Security
    # Use "*" in production behind AWS App Runner (which handles host validation)
    @computed_field  # type: ignore[prop-decorator]
    @property
    def allowed_hosts(self) -> list[str]:
        hosts = [
            "localhost",
            "127.0.0.1",
            "orthosense.app",
            "testserver",
            "*.eu-central-1.awsapprunner.com",  # AWS App Runner domains
            "*",  # Allow all hosts when behind reverse proxy (App Runner validates)
        ]
        # Add local test IP if configured (for mobile testing via LOCAL_TEST_IP env var)
        if self.local_test_ip:
            hosts.insert(4, self.local_test_ip)
        return hosts

    # Rate Limiting (Redis)
    redis_url: str = "redis://localhost:6379/0"
    rate_limit_enabled: bool = True

    # JWT Authentication
    # SONARQUBE FIX: Removed hardcoded default secret to prevent security hotspots.
    # Value must be provided via .env file or environment variable.
    secret_key: str
    algorithm: str = "HS256"
    access_token_expire_minutes: int = 30
    refresh_token_expire_days: int = 7
    verification_token_expire_hours: int = 24
    password_reset_token_expire_hours: int = 1

    # Frontend URL for email links
    frontend_url: str = "http://localhost:8080"

    # Resend Email Configuration (HTTP API)
    resend_api_key: str = ""  # Resend API key (re_...)
    resend_from_email: str = "onboarding@resend.dev"  # Verified sender
    resend_from_name: str = "OrthoSense"
    email_enabled: bool = True  # Set to False to use mock (logging only)

    max_upload_size_mb: int = 100
    upload_temp_dir: str = os.path.join(tempfile.gettempdir(), "orthosense_uploads")

    @property
    def is_sqlite(self) -> bool:
        """Check if using SQLite (for conditional async driver selection)."""
        return self.database_url.startswith("sqlite")


@lru_cache
def get_settings() -> Settings:
    """Cached settings instance - loaded once per process."""
    return Settings()  # type: ignore[call-arg]


settings = get_settings()
