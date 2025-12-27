"""Application configuration using pydantic-settings.

Environment variables override defaults. Use .env file for local development.
"""

import os
import tempfile
from functools import lru_cache

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

    # Security
    allowed_hosts: list[str] = [
        "localhost",
        "127.0.0.1",
        "orthosense.app",
        "testserver",
        "192.168.1.103",  # Old local network IP
        "172.20.10.12",  # Current local network IP for mobile testing
    ]

    # Rate Limiting (Redis)
    redis_url: str = "redis://localhost:6379"
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
