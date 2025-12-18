"""Unit tests for email service.

Tests cover:
- Verification email sending
- Password reset email sending
- Welcome email sending
- URL generation
"""

from unittest.mock import patch

import pytest

from app.core.config import settings
from app.services.email import (
    send_password_reset_email,
    send_verification_email,
    send_welcome_email,
)


class TestVerificationEmail:
    """Tests for verification email sending."""

    @pytest.mark.asyncio
    async def test_send_verification_email_logs_correct_url(self) -> None:
        """Verification email logs URL with correct token."""
        email = "test@example.com"
        token = "test-verification-token"

        with patch("app.services.email.logger") as mock_logger:
            await send_verification_email(email, token)

            mock_logger.info.assert_called_once()
            call_kwargs = mock_logger.info.call_args.kwargs

            assert call_kwargs["email"] == email
            assert token in call_kwargs["link"]
            assert settings.frontend_url in call_kwargs["link"]
            assert "verify-email" in call_kwargs["link"]

    @pytest.mark.asyncio
    async def test_send_verification_email_url_format(self) -> None:
        """Verification URL has correct format."""
        email = "user@test.com"
        token = "abc123token"

        expected_url = f"{settings.frontend_url}/verify-email?token={token}"

        with patch("app.services.email.logger") as mock_logger:
            await send_verification_email(email, token)

            call_kwargs = mock_logger.info.call_args.kwargs
            assert call_kwargs["link"] == expected_url


class TestPasswordResetEmail:
    """Tests for password reset email sending."""

    @pytest.mark.asyncio
    async def test_send_password_reset_email_logs_correct_url(self) -> None:
        """Password reset email logs URL with correct token."""
        email = "test@example.com"
        token = "test-reset-token"

        with patch("app.services.email.logger") as mock_logger:
            await send_password_reset_email(email, token)

            mock_logger.info.assert_called_once()
            call_kwargs = mock_logger.info.call_args.kwargs

            assert call_kwargs["email"] == email
            assert token in call_kwargs["link"]
            assert settings.frontend_url in call_kwargs["link"]
            assert "reset-password" in call_kwargs["link"]

    @pytest.mark.asyncio
    async def test_send_password_reset_email_url_format(self) -> None:
        """Password reset URL has correct format."""
        email = "user@test.com"
        token = "reset-abc123"

        expected_url = f"{settings.frontend_url}/reset-password?token={token}"

        with patch("app.services.email.logger") as mock_logger:
            await send_password_reset_email(email, token)

            call_kwargs = mock_logger.info.call_args.kwargs
            assert call_kwargs["link"] == expected_url


class TestWelcomeEmail:
    """Tests for welcome email sending."""

    @pytest.mark.asyncio
    async def test_send_welcome_email_logs_message(self) -> None:
        """Welcome email logs correct email and message."""
        email = "test@example.com"

        with patch("app.services.email.logger") as mock_logger:
            await send_welcome_email(email)

            mock_logger.info.assert_called_once()
            call_kwargs = mock_logger.info.call_args.kwargs

            assert call_kwargs["email"] == email
            assert "OrthoSense" in call_kwargs["message"]
