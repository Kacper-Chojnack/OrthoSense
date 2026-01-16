"""Unit tests for email service.

Tests cover:
- Verification email sending
- Password reset email sending
- Welcome email sending
- URL generation
- Resend API integration (mocked)
"""

from unittest.mock import AsyncMock, MagicMock, patch

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
    async def test_send_verification_email_calls_send(self) -> None:
        """Verification email calls internal send function with correct params."""
        email = "test@example.com"
        token = "test-verification-token"

        with patch(
            "app.services.email._send_email", new_callable=AsyncMock
        ) as mock_send:
            mock_send.return_value = True

            await send_verification_email(email, token)

            mock_send.assert_called_once()
            call_args = mock_send.call_args[0]
            to_email, subject, html_body = call_args

            assert to_email == email
            assert "OrthoSense" in subject
            assert token in html_body
            assert f"verify-email?token={token}" in html_body

    @pytest.mark.asyncio
    async def test_send_verification_email_url_format(self) -> None:
        """Verification URL has correct format in email body."""
        email = "user@test.com"
        token = "abc123token"

        expected_url = f"{settings.frontend_url}/verify-email?token={token}"

        with patch(
            "app.services.email._send_email", new_callable=AsyncMock
        ) as mock_send:
            mock_send.return_value = True

            await send_verification_email(email, token)

            call_args = mock_send.call_args[0]
            _, _, html_body = call_args

            assert expected_url in html_body


class TestPasswordResetEmail:
    """Tests for password reset email sending."""

    @pytest.mark.asyncio
    async def test_send_password_reset_email_calls_send(self) -> None:
        """Password reset email calls internal send function with correct params."""
        email = "test@example.com"
        token = "test-reset-token"

        with patch(
            "app.services.email._send_email", new_callable=AsyncMock
        ) as mock_send:
            mock_send.return_value = True

            await send_password_reset_email(email, token)

            mock_send.assert_called_once()
            call_args = mock_send.call_args[0]
            to_email, subject, html_body = call_args

            assert to_email == email
            assert "reset" in subject.lower() or "password" in subject.lower()
            assert token in html_body
            assert f"reset-password?token={token}" in html_body

    @pytest.mark.asyncio
    async def test_send_password_reset_email_url_format(self) -> None:
        """Password reset URL has correct format in email body."""
        email = "user@test.com"
        token = "reset-abc123"

        expected_url = f"{settings.frontend_url}/reset-password?token={token}"

        with patch(
            "app.services.email._send_email", new_callable=AsyncMock
        ) as mock_send:
            mock_send.return_value = True

            await send_password_reset_email(email, token)

            call_args = mock_send.call_args[0]
            _, _, html_body = call_args

            assert expected_url in html_body


class TestWelcomeEmail:
    """Tests for welcome email sending."""

    @pytest.mark.asyncio
    async def test_send_welcome_email_calls_send(self) -> None:
        """Welcome email calls internal send function with correct params."""
        email = "test@example.com"

        with patch(
            "app.services.email._send_email", new_callable=AsyncMock
        ) as mock_send:
            mock_send.return_value = True

            await send_welcome_email(email)

            mock_send.assert_called_once()
            call_args = mock_send.call_args[0]
            to_email, subject, html_body = call_args

            assert to_email == email
            assert "OrthoSense" in subject or "Welcome" in subject
            # Check for verification confirmation content
            assert "verified" in html_body.lower() or "active" in html_body.lower()

    @pytest.mark.asyncio
    async def test_send_welcome_email_async_execution(self) -> None:
        """Welcome email executes asynchronously without blocking."""
        import asyncio

        email = "async_test@example.com"

        with patch(
            "app.services.email._send_email", new_callable=AsyncMock
        ) as mock_send:
            mock_send.return_value = True
            await asyncio.wait_for(
                send_welcome_email(email),
                timeout=1.0,
            )


class TestEmailEdgeCases:
    """Edge case tests for email service."""

    @pytest.mark.asyncio
    async def test_verification_email_with_special_characters_in_email(self) -> None:
        """Email with special characters is handled correctly."""
        email = "test+special@example.com"
        token = "token123"

        with patch(
            "app.services.email._send_email", new_callable=AsyncMock
        ) as mock_send:
            mock_send.return_value = True

            await send_verification_email(email, token)

            call_args = mock_send.call_args[0]
            to_email = call_args[0]
            assert to_email == email

    @pytest.mark.asyncio
    async def test_verification_email_with_long_token(self) -> None:
        """Long tokens are handled correctly."""
        email = "test@example.com"
        token = "a" * 500  # Very long token

        with patch(
            "app.services.email._send_email", new_callable=AsyncMock
        ) as mock_send:
            mock_send.return_value = True

            await send_verification_email(email, token)

            call_args = mock_send.call_args[0]
            _, _, html_body = call_args
            assert token in html_body

    @pytest.mark.asyncio
    async def test_password_reset_with_unicode_email(self) -> None:
        """Unicode in email domain is handled."""
        email = "user@münchen.example.com"
        token = "reset-token"

        with patch(
            "app.services.email._send_email", new_callable=AsyncMock
        ) as mock_send:
            mock_send.return_value = True

            await send_password_reset_email(email, token)

            call_args = mock_send.call_args[0]
            to_email = call_args[0]
            assert to_email == email

    @pytest.mark.asyncio
    async def test_concurrent_email_sending(self) -> None:
        """Multiple emails can be sent concurrently."""
        import asyncio

        emails = [f"user{i}@example.com" for i in range(10)]
        tokens = [f"token{i}" for i in range(10)]

        with patch(
            "app.services.email._send_email", new_callable=AsyncMock
        ) as mock_send:
            mock_send.return_value = True

            tasks = [
                send_verification_email(email, token)
                for email, token in zip(emails, tokens, strict=False)
            ]
            await asyncio.gather(*tasks)

            assert mock_send.call_count == 10

    @pytest.mark.asyncio
    async def test_email_functions_are_independent(self) -> None:
        """Email functions don't share state."""
        email = "test@example.com"

        with patch(
            "app.services.email._send_email", new_callable=AsyncMock
        ) as mock_send:
            mock_send.return_value = True

            await send_verification_email(email, "verify-token")
            await send_password_reset_email(email, "reset-token")
            await send_welcome_email(email)

            # All three should have been called
            assert mock_send.call_count == 3


class TestResendAPIIntegration:
    """Tests for Resend API integration."""

    @pytest.mark.asyncio
    async def test_send_email_when_disabled_logs_mock(self) -> None:
        """When email_enabled=False, logs mock instead of sending."""
        email = "test@example.com"
        token = "test-token"

        with (
            patch("app.services.email.settings") as mock_settings,
            patch("app.services.email.logger") as mock_logger,
        ):
            mock_settings.email_enabled = False
            mock_settings.frontend_url = settings.frontend_url
            mock_settings.verification_token_expire_hours = 24

            await send_verification_email(email, token)

            # Should log info about mock
            mock_logger.info.assert_called()

    @pytest.mark.asyncio
    async def test_send_email_without_api_key_logs_warning(self) -> None:
        """When resend_api_key is not set, logs warning."""
        email = "test@example.com"
        token = "test-token"

        with (
            patch("app.services.email.settings") as mock_settings,
            patch("app.services.email.logger") as mock_logger,
        ):
            mock_settings.email_enabled = True
            mock_settings.resend_api_key = None
            mock_settings.frontend_url = settings.frontend_url
            mock_settings.verification_token_expire_hours = 24

            await send_verification_email(email, token)

            # Should log warning
            mock_logger.warning.assert_called()

    @pytest.mark.asyncio
    async def test_send_email_success_logs_info(self) -> None:
        """Successful email send logs info with message_id."""
        email = "test@example.com"
        token = "test-token"

        mock_response = MagicMock()
        mock_response.status_code = 200
        mock_response.json.return_value = {"id": "test-message-id"}

        with (
            patch("app.services.email.settings") as mock_settings,
            patch("app.services.email.logger") as mock_logger,
            patch("httpx.AsyncClient") as mock_client_class,
        ):
            mock_settings.email_enabled = True
            mock_settings.resend_api_key = "test-api-key"
            mock_settings.resend_from_name = "OrthoSense"
            mock_settings.resend_from_email = "noreply@orthosense.app"
            mock_settings.frontend_url = settings.frontend_url
            mock_settings.verification_token_expire_hours = 24

            mock_client = AsyncMock()
            mock_client.post.return_value = mock_response
            mock_client.__aenter__.return_value = mock_client
            mock_client_class.return_value = mock_client

            await send_verification_email(email, token)

            # Should log info about successful send
            mock_logger.info.assert_called()
            call_kwargs = mock_logger.info.call_args.kwargs
            assert call_kwargs.get("to") == email or "to" in str(
                mock_logger.info.call_args
            )

    @pytest.mark.asyncio
    async def test_send_email_failure_logs_error(self) -> None:
        """Failed email send logs error with status code."""
        email = "test@example.com"
        token = "test-token"

        mock_response = MagicMock()
        mock_response.status_code = 400
        mock_response.text = "Bad Request"

        with (
            patch("app.services.email.settings") as mock_settings,
            patch("app.services.email.logger") as mock_logger,
            patch("httpx.AsyncClient") as mock_client_class,
        ):
            mock_settings.email_enabled = True
            mock_settings.resend_api_key = "test-api-key"
            mock_settings.resend_from_name = "OrthoSense"
            mock_settings.resend_from_email = "noreply@orthosense.app"
            mock_settings.frontend_url = settings.frontend_url
            mock_settings.verification_token_expire_hours = 24

            mock_client = AsyncMock()
            mock_client.post.return_value = mock_response
            mock_client.__aenter__.return_value = mock_client
            mock_client_class.return_value = mock_client

            await send_verification_email(email, token)

            # Should log error
            mock_logger.error.assert_called()
