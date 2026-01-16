"""
Unit tests for Email service.

Test coverage:
1. _send_email internal function
2. send_verification_email
3. send_password_reset_email
4. send_welcome_email
5. Error handling scenarios
6. API key and configuration scenarios
"""

from unittest.mock import AsyncMock, MagicMock, patch

import httpx
import pytest

from app.services.email import (
    _send_email,
    send_password_reset_email,
    send_verification_email,
    send_welcome_email,
)


class TestSendEmailInternal:
    """Tests for _send_email internal function."""

    @pytest.mark.asyncio
    async def test_send_email_disabled_returns_true(self) -> None:
        """When email is disabled, returns True without sending."""
        with patch("app.services.email.settings") as mock_settings:
            mock_settings.email_enabled = False

            result = await _send_email(
                "test@example.com",
                "Test Subject",
                "<p>Test body</p>",
            )

            assert result is True

    @pytest.mark.asyncio
    async def test_send_email_no_api_key_returns_false(self) -> None:
        """When API key is not configured, returns False."""
        with patch("app.services.email.settings") as mock_settings:
            mock_settings.email_enabled = True
            mock_settings.resend_api_key = None

            result = await _send_email(
                "test@example.com",
                "Test Subject",
                "<p>Test body</p>",
            )

            assert result is False

    @pytest.mark.asyncio
    async def test_send_email_empty_api_key_returns_false(self) -> None:
        """When API key is empty string, returns False."""
        with patch("app.services.email.settings") as mock_settings:
            mock_settings.email_enabled = True
            mock_settings.resend_api_key = ""

            result = await _send_email(
                "test@example.com",
                "Test Subject",
                "<p>Test body</p>",
            )

            assert result is False

    @pytest.mark.asyncio
    async def test_send_email_success(self) -> None:
        """Successful email send returns True."""
        with patch("app.services.email.settings") as mock_settings:
            mock_settings.email_enabled = True
            mock_settings.resend_api_key = "re_test_api_key"
            mock_settings.resend_from_name = "OrthoSense"
            mock_settings.resend_from_email = "noreply@orthosense.com"

            mock_response = MagicMock()
            mock_response.status_code = 200
            mock_response.json.return_value = {"id": "msg_123"}

            with patch("httpx.AsyncClient") as mock_client_class:
                mock_client = AsyncMock()
                mock_client.post.return_value = mock_response
                mock_client.__aenter__.return_value = mock_client
                mock_client.__aexit__.return_value = None
                mock_client_class.return_value = mock_client

                result = await _send_email(
                    "recipient@example.com",
                    "Test Subject",
                    "<p>Test HTML body</p>",
                )

                assert result is True
                mock_client.post.assert_called_once()

    @pytest.mark.asyncio
    async def test_send_email_api_error(self) -> None:
        """API error returns False."""
        with patch("app.services.email.settings") as mock_settings:
            mock_settings.email_enabled = True
            mock_settings.resend_api_key = "re_test_api_key"
            mock_settings.resend_from_name = "OrthoSense"
            mock_settings.resend_from_email = "noreply@orthosense.com"

            mock_response = MagicMock()
            mock_response.status_code = 400
            mock_response.text = "Bad Request"

            with patch("httpx.AsyncClient") as mock_client_class:
                mock_client = AsyncMock()
                mock_client.post.return_value = mock_response
                mock_client.__aenter__.return_value = mock_client
                mock_client.__aexit__.return_value = None
                mock_client_class.return_value = mock_client

                result = await _send_email(
                    "recipient@example.com",
                    "Test Subject",
                    "<p>Test body</p>",
                )

                assert result is False

    @pytest.mark.asyncio
    async def test_send_email_timeout(self) -> None:
        """Timeout returns False."""
        with patch("app.services.email.settings") as mock_settings:
            mock_settings.email_enabled = True
            mock_settings.resend_api_key = "re_test_api_key"
            mock_settings.resend_from_name = "OrthoSense"
            mock_settings.resend_from_email = "noreply@orthosense.com"

            with patch("httpx.AsyncClient") as mock_client_class:
                mock_client = AsyncMock()
                mock_client.post.side_effect = httpx.TimeoutException("Connection timed out")
                mock_client.__aenter__.return_value = mock_client
                mock_client.__aexit__.return_value = None
                mock_client_class.return_value = mock_client

                result = await _send_email(
                    "recipient@example.com",
                    "Test Subject",
                    "<p>Test body</p>",
                )

                assert result is False

    @pytest.mark.asyncio
    async def test_send_email_generic_exception(self) -> None:
        """Generic exception returns False."""
        with patch("app.services.email.settings") as mock_settings:
            mock_settings.email_enabled = True
            mock_settings.resend_api_key = "re_test_api_key"
            mock_settings.resend_from_name = "OrthoSense"
            mock_settings.resend_from_email = "noreply@orthosense.com"

            with patch("httpx.AsyncClient") as mock_client_class:
                mock_client = AsyncMock()
                mock_client.post.side_effect = RuntimeError("Unexpected error")
                mock_client.__aenter__.return_value = mock_client
                mock_client.__aexit__.return_value = None
                mock_client_class.return_value = mock_client

                result = await _send_email(
                    "recipient@example.com",
                    "Test Subject",
                    "<p>Test body</p>",
                )

                assert result is False


class TestSendVerificationEmail:
    """Tests for send_verification_email function."""

    @pytest.mark.asyncio
    async def test_send_verification_email_success(self) -> None:
        """Verification email is sent (logged) without error."""
        # Mock implementation logs to console - should not raise
        await send_verification_email("test@example.com", "verification-token-123")

    @pytest.mark.asyncio
    async def test_send_verification_email_constructs_url(self) -> None:
        """Verification URL is constructed correctly."""
        # This test verifies the function runs without error
        # In production, would verify actual email content
        await send_verification_email("user@domain.com", "abc123xyz")

    @pytest.mark.asyncio
    async def test_send_verification_email_calls_send_email(self) -> None:
        """send_verification_email calls _send_email with correct params."""
        with patch("app.services.email._send_email", new_callable=AsyncMock) as mock:
            mock.return_value = True

            await send_verification_email("user@test.com", "token123")

            mock.assert_called_once()
            call_args = mock.call_args
            assert call_args[0][0] == "user@test.com"
            assert "Verify" in call_args[0][1]  # Subject contains "Verify"
            assert "token123" in call_args[0][2]  # Body contains token


class TestSendPasswordResetEmail:
    """Tests for send_password_reset_email function."""

    @pytest.mark.asyncio
    async def test_send_password_reset_email_success(self) -> None:
        """Password reset email is sent (logged) without error."""
        await send_password_reset_email("test@example.com", "reset-token-456")

    @pytest.mark.asyncio
    async def test_send_password_reset_email_different_emails(self) -> None:
        """Password reset works with various email formats."""
        emails = [
            "user@example.com",
            "user.name@example.com",
            "user+tag@example.com",
            "user@subdomain.example.com",
        ]

        for email in emails:
            await send_password_reset_email(email, "token")

    @pytest.mark.asyncio
    async def test_send_password_reset_email_calls_send_email(self) -> None:
        """send_password_reset_email calls _send_email with correct params."""
        with patch("app.services.email._send_email", new_callable=AsyncMock) as mock:
            mock.return_value = True

            await send_password_reset_email("user@test.com", "reset-token")

            mock.assert_called_once()
            call_args = mock.call_args
            assert call_args[0][0] == "user@test.com"
            assert "Reset" in call_args[0][1] or "Password" in call_args[0][1]
            assert "reset-token" in call_args[0][2]


class TestSendWelcomeEmail:
    """Tests for send_welcome_email function."""

    @pytest.mark.asyncio
    async def test_send_welcome_email_success(self) -> None:
        """Welcome email is sent (logged) without error."""
        await send_welcome_email("test@example.com")

    @pytest.mark.asyncio
    async def test_send_welcome_email_various_domains(self) -> None:
        """Welcome email works with various domains."""
        emails = [
            "user@gmail.com",
            "user@outlook.com",
            "user@company.co.uk",
        ]

        for email in emails:
            await send_welcome_email(email)

    @pytest.mark.asyncio
    async def test_send_welcome_email_calls_send_email(self) -> None:
        """send_welcome_email calls _send_email with correct params."""
        with patch("app.services.email._send_email", new_callable=AsyncMock) as mock:
            mock.return_value = True

            await send_welcome_email("user@test.com")

            mock.assert_called_once()
            call_args = mock.call_args
            assert call_args[0][0] == "user@test.com"
            assert "Welcome" in call_args[0][1]  # Subject contains "Welcome"


class TestEmailServiceAsync:
    """Tests for async behavior of email service."""

    @pytest.mark.asyncio
    async def test_emails_are_async(self) -> None:
        """Email functions are properly async."""
        import asyncio

        # All should complete without blocking
        await asyncio.gather(
            send_verification_email("a@example.com", "token1"),
            send_password_reset_email("b@example.com", "token2"),
            send_welcome_email("c@example.com"),
        )

    @pytest.mark.asyncio
    async def test_concurrent_email_sends(self) -> None:
        """Multiple emails can be sent concurrently."""
        import asyncio

        with patch("app.services.email._send_email", new_callable=AsyncMock) as mock:
            mock.return_value = True

            await asyncio.gather(
                send_verification_email("user1@test.com", "t1"),
                send_verification_email("user2@test.com", "t2"),
                send_password_reset_email("user3@test.com", "t3"),
            )

            assert mock.call_count == 3
