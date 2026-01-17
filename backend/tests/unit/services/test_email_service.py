"""
Comprehensive unit tests for email service.

Test coverage:
1. Email sending success/failure paths
2. Configuration checks
3. Timeout handling
4. Template generation
"""

from unittest.mock import AsyncMock, MagicMock, patch

import pytest
from httpx import Response

from app.services.email import (
    _send_email,
    send_password_reset_email,
    send_verification_email,
)


class TestSendEmailDisabled:
    """Tests when email is disabled."""

    @pytest.mark.asyncio
    async def test_returns_true_when_disabled(self) -> None:
        """Email returns success when disabled."""
        with patch("app.services.email.settings") as mock_settings:
            mock_settings.email_enabled = False
            
            result = await _send_email(
                "test@example.com",
                "Test Subject",
                "<p>Body</p>",
            )
            
            assert result is True

    @pytest.mark.asyncio
    async def test_logs_mock_when_disabled(self) -> None:
        """Email logs mock when disabled."""
        with (
            patch("app.services.email.settings") as mock_settings,
            patch("app.services.email.logger") as mock_logger,
        ):
            mock_settings.email_enabled = False
            
            await _send_email(
                "test@example.com",
                "Test Subject",
                "<p>Body</p>",
            )
            
            mock_logger.info.assert_called()


class TestSendEmailMissingConfig:
    """Tests when Resend API key is missing."""

    @pytest.mark.asyncio
    async def test_returns_false_without_api_key(self) -> None:
        """Returns false when API key is missing."""
        with patch("app.services.email.settings") as mock_settings:
            mock_settings.email_enabled = True
            mock_settings.resend_api_key = None
            
            result = await _send_email(
                "test@example.com",
                "Test Subject",
                "<p>Body</p>",
            )
            
            assert result is False

    @pytest.mark.asyncio
    async def test_logs_warning_without_api_key(self) -> None:
        """Logs warning when API key is missing."""
        with (
            patch("app.services.email.settings") as mock_settings,
            patch("app.services.email.logger") as mock_logger,
        ):
            mock_settings.email_enabled = True
            mock_settings.resend_api_key = None
            
            await _send_email(
                "test@example.com",
                "Test Subject",
                "<p>Body</p>",
            )
            
            mock_logger.warning.assert_called()


class TestSendEmailSuccess:
    """Tests for successful email sending."""

    @pytest.mark.asyncio
    async def test_returns_true_on_success(self) -> None:
        """Returns true on successful send."""
        mock_response = MagicMock(spec=Response)
        mock_response.status_code = 200
        mock_response.json.return_value = {"id": "test-id"}
        
        mock_client = AsyncMock()
        mock_client.__aenter__.return_value.post.return_value = mock_response
        
        with (
            patch("app.services.email.settings") as mock_settings,
            patch("app.services.email.httpx.AsyncClient", return_value=mock_client),
        ):
            mock_settings.email_enabled = True
            mock_settings.resend_api_key = "test-key"
            mock_settings.resend_from_name = "OrthoSense"
            mock_settings.resend_from_email = "no-reply@orthosense.com"
            
            result = await _send_email(
                "test@example.com",
                "Test Subject",
                "<p>Body</p>",
            )
            
            assert result is True

    @pytest.mark.asyncio
    async def test_logs_success_with_message_id(self) -> None:
        """Logs success with message ID."""
        mock_response = MagicMock(spec=Response)
        mock_response.status_code = 200
        mock_response.json.return_value = {"id": "msg-12345"}
        
        mock_client = AsyncMock()
        mock_client.__aenter__.return_value.post.return_value = mock_response
        
        with (
            patch("app.services.email.settings") as mock_settings,
            patch("app.services.email.httpx.AsyncClient", return_value=mock_client),
            patch("app.services.email.logger") as mock_logger,
        ):
            mock_settings.email_enabled = True
            mock_settings.resend_api_key = "test-key"
            mock_settings.resend_from_name = "OrthoSense"
            mock_settings.resend_from_email = "no-reply@orthosense.com"
            
            await _send_email(
                "test@example.com",
                "Test Subject",
                "<p>Body</p>",
            )
            
            mock_logger.info.assert_called_once()


class TestSendEmailFailure:
    """Tests for failed email sending."""

    @pytest.mark.asyncio
    async def test_returns_false_on_api_error(self) -> None:
        """Returns false on API error response."""
        mock_response = MagicMock(spec=Response)
        mock_response.status_code = 400
        mock_response.text = "Bad Request"
        
        mock_client = AsyncMock()
        mock_client.__aenter__.return_value.post.return_value = mock_response
        
        with (
            patch("app.services.email.settings") as mock_settings,
            patch("app.services.email.httpx.AsyncClient", return_value=mock_client),
        ):
            mock_settings.email_enabled = True
            mock_settings.resend_api_key = "test-key"
            mock_settings.resend_from_name = "OrthoSense"
            mock_settings.resend_from_email = "no-reply@orthosense.com"
            
            result = await _send_email(
                "test@example.com",
                "Test Subject",
                "<p>Body</p>",
            )
            
            assert result is False


class TestSendEmailTimeout:
    """Tests for timeout handling."""

    @pytest.mark.asyncio
    async def test_returns_false_on_timeout(self) -> None:
        """Returns false on timeout."""
        import httpx
        
        mock_client = AsyncMock()
        mock_client.__aenter__.return_value.post.side_effect = httpx.TimeoutException("Timeout")
        
        with (
            patch("app.services.email.settings") as mock_settings,
            patch("app.services.email.httpx.AsyncClient", return_value=mock_client),
        ):
            mock_settings.email_enabled = True
            mock_settings.resend_api_key = "test-key"
            mock_settings.resend_from_name = "OrthoSense"
            mock_settings.resend_from_email = "no-reply@orthosense.com"
            
            result = await _send_email(
                "test@example.com",
                "Test Subject",
                "<p>Body</p>",
            )
            
            assert result is False

    @pytest.mark.asyncio
    async def test_logs_warning_on_timeout(self) -> None:
        """Logs warning on timeout."""
        import httpx
        
        mock_client = AsyncMock()
        mock_client.__aenter__.return_value.post.side_effect = httpx.TimeoutException("Timeout")
        
        with (
            patch("app.services.email.settings") as mock_settings,
            patch("app.services.email.httpx.AsyncClient", return_value=mock_client),
            patch("app.services.email.logger") as mock_logger,
        ):
            mock_settings.email_enabled = True
            mock_settings.resend_api_key = "test-key"
            mock_settings.resend_from_name = "OrthoSense"
            mock_settings.resend_from_email = "no-reply@orthosense.com"
            
            await _send_email(
                "test@example.com",
                "Test Subject",
                "<p>Body</p>",
            )
            
            mock_logger.warning.assert_called()


class TestSendEmailException:
    """Tests for generic exception handling."""

    @pytest.mark.asyncio
    async def test_returns_false_on_exception(self) -> None:
        """Returns false on general exception."""
        mock_client = AsyncMock()
        mock_client.__aenter__.return_value.post.side_effect = Exception("Network error")
        
        with (
            patch("app.services.email.settings") as mock_settings,
            patch("app.services.email.httpx.AsyncClient", return_value=mock_client),
        ):
            mock_settings.email_enabled = True
            mock_settings.resend_api_key = "test-key"
            mock_settings.resend_from_name = "OrthoSense"
            mock_settings.resend_from_email = "no-reply@orthosense.com"
            
            result = await _send_email(
                "test@example.com",
                "Test Subject",
                "<p>Body</p>",
            )
            
            assert result is False


class TestVerificationEmailTemplate:
    """Tests for verification email template."""

    @pytest.mark.asyncio
    async def test_verification_email_calls_send_email(self) -> None:
        """Verification email function calls _send_email."""
        with (
            patch("app.services.email._send_email", new_callable=AsyncMock) as mock_send,
            patch("app.services.email.settings") as mock_settings,
        ):
            mock_settings.frontend_url = "https://app.orthosense.com"
            mock_settings.verification_token_expire_hours = 24
            
            await send_verification_email("user@example.com", "test-token-123")
            
            mock_send.assert_called_once()
            call_args = mock_send.call_args
            assert call_args[0][0] == "user@example.com"
            assert "Verify" in call_args[0][1]
            assert "test-token-123" in call_args[0][2]


class TestPasswordResetEmailTemplate:
    """Tests for password reset email template."""

    @pytest.mark.asyncio
    async def test_password_reset_email_calls_send_email(self) -> None:
        """Password reset email function calls _send_email."""
        with (
            patch("app.services.email._send_email", new_callable=AsyncMock) as mock_send,
            patch("app.services.email.settings") as mock_settings,
        ):
            mock_settings.frontend_url = "https://app.orthosense.com"
            mock_settings.reset_token_expire_hours = 1
            
            await send_password_reset_email("user@example.com", "reset-token-456")
            
            mock_send.assert_called_once()
            call_args = mock_send.call_args
            assert call_args[0][0] == "user@example.com"
            assert "Reset" in call_args[0][1] or "Password" in call_args[0][1]
            assert "reset-token-456" in call_args[0][2]
