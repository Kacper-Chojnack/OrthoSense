"""Unit tests for email service.

Tests cover:
- Verification email sending
- Password reset email sending
- Welcome email sending
- URL generation
- AWS SES integration (mocked)
"""

from unittest.mock import MagicMock, patch

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
    async def test_send_verification_email_calls_send_async(self) -> None:
        """Verification email calls internal send function with correct params."""
        email = "test@example.com"
        token = "test-verification-token"

        with patch("app.services.email._send_email_async") as mock_send:
            mock_send.return_value = True

            await send_verification_email(email, token)

            mock_send.assert_called_once()
            call_args = mock_send.call_args
            to_email, subject, html_body, text_body = call_args[0]

            assert to_email == email
            assert "OrthoSense" in subject
            assert token in html_body
            assert f"verify-email?token={token}" in html_body
            assert token in text_body

    @pytest.mark.asyncio
    async def test_send_verification_email_url_format(self) -> None:
        """Verification URL has correct format in email body."""
        email = "user@test.com"
        token = "abc123token"

        expected_url = f"{settings.frontend_url}/verify-email?token={token}"

        with patch("app.services.email._send_email_async") as mock_send:
            mock_send.return_value = True

            await send_verification_email(email, token)

            call_args = mock_send.call_args
            _, _, html_body, text_body = call_args[0]

            assert expected_url in html_body
            assert expected_url in text_body


class TestPasswordResetEmail:
    """Tests for password reset email sending."""

    @pytest.mark.asyncio
    async def test_send_password_reset_email_calls_send_async(self) -> None:
        """Password reset email calls internal send function with correct params."""
        email = "test@example.com"
        token = "test-reset-token"

        with patch("app.services.email._send_email_async") as mock_send:
            mock_send.return_value = True

            await send_password_reset_email(email, token)

            mock_send.assert_called_once()
            call_args = mock_send.call_args
            to_email, subject, html_body, text_body = call_args[0]

            assert to_email == email
            assert "hasła" in subject.lower() or "reset" in subject.lower()
            assert token in html_body
            assert f"reset-password?token={token}" in html_body
            assert token in text_body

    @pytest.mark.asyncio
    async def test_send_password_reset_email_url_format(self) -> None:
        """Password reset URL has correct format in email body."""
        email = "user@test.com"
        token = "reset-abc123"

        expected_url = f"{settings.frontend_url}/reset-password?token={token}"

        with patch("app.services.email._send_email_async") as mock_send:
            mock_send.return_value = True

            await send_password_reset_email(email, token)

            call_args = mock_send.call_args
            _, _, html_body, text_body = call_args[0]

            assert expected_url in html_body
            assert expected_url in text_body


class TestWelcomeEmail:
    """Tests for welcome email sending."""

    @pytest.mark.asyncio
    async def test_send_welcome_email_calls_send_async(self) -> None:
        """Welcome email calls internal send function with correct params."""
        email = "test@example.com"

        with patch("app.services.email._send_email_async") as mock_send:
            mock_send.return_value = True

            await send_welcome_email(email)

            mock_send.assert_called_once()
            call_args = mock_send.call_args
            to_email, subject, html_body, text_body = call_args[0]

            assert to_email == email
            assert "OrthoSense" in subject
            assert (
                "zweryfikowane" in html_body.lower() or "verified" in html_body.lower()
            )

    @pytest.mark.asyncio
    async def test_send_welcome_email_async_execution(self) -> None:
        """Welcome email executes asynchronously without blocking."""
        import asyncio

        email = "async_test@example.com"

        with patch("app.services.email._send_email_async") as mock_send:
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

        with patch("app.services.email._send_email_async") as mock_send:
            mock_send.return_value = True

            await send_verification_email(email, token)

            call_args = mock_send.call_args
            to_email = call_args[0][0]
            assert to_email == email

    @pytest.mark.asyncio
    async def test_verification_email_with_long_token(self) -> None:
        """Long tokens are handled correctly."""
        email = "test@example.com"
        token = "a" * 500  # Very long token

        with patch("app.services.email._send_email_async") as mock_send:
            mock_send.return_value = True

            await send_verification_email(email, token)

            call_args = mock_send.call_args
            _, _, html_body, _ = call_args[0]
            assert token in html_body

    @pytest.mark.asyncio
    async def test_password_reset_with_unicode_email(self) -> None:
        """Unicode in email domain is handled."""
        email = "user@münchen.example.com"
        token = "reset-token"

        with patch("app.services.email._send_email_async") as mock_send:
            mock_send.return_value = True

            await send_password_reset_email(email, token)

            call_args = mock_send.call_args
            to_email = call_args[0][0]
            assert to_email == email

    @pytest.mark.asyncio
    async def test_concurrent_email_sending(self) -> None:
        """Multiple emails can be sent concurrently."""
        import asyncio

        emails = [f"user{i}@example.com" for i in range(10)]
        tokens = [f"token{i}" for i in range(10)]

        with patch("app.services.email._send_email_async") as mock_send:
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

        with patch("app.services.email._send_email_async") as mock_send:
            mock_send.return_value = True

            await send_verification_email(email, "verify-token")
            await send_password_reset_email(email, "reset-token")
            await send_welcome_email(email)

            # All three should have been called
            assert mock_send.call_count == 3


class TestAWSSESIntegration:
    """Tests for AWS SES integration."""

    @pytest.mark.asyncio
    async def test_ses_send_email_success(self) -> None:
        """SES sends email successfully when enabled."""
        email = "test@example.com"
        token = "test-token"

        mock_ses_client = MagicMock()
        mock_ses_client.send_email.return_value = {"MessageId": "test-message-id"}

        with (
            patch("app.services.email.settings") as mock_settings,
            patch("app.services.email._get_ses_client", return_value=mock_ses_client),
            patch("app.services.email.logger"),
        ):
            mock_settings.email_enabled = True
            mock_settings.frontend_url = settings.frontend_url
            mock_settings.verification_token_expire_hours = 24
            mock_settings.ses_sender_name = "OrthoSense"
            mock_settings.ses_sender_email = "noreply@orthosense.app"
            mock_settings.aws_region = "eu-central-1"

            await send_verification_email(email, token)

            mock_ses_client.send_email.assert_called_once()
            call_kwargs = mock_ses_client.send_email.call_args.kwargs
            assert call_kwargs["Destination"]["ToAddresses"] == [email]

    @pytest.mark.asyncio
    async def test_ses_send_email_failure_logged(self) -> None:
        """SES failure is logged properly."""
        from botocore.exceptions import ClientError

        email = "test@example.com"
        token = "test-token"

        mock_ses_client = MagicMock()
        mock_ses_client.send_email.side_effect = ClientError(
            {"Error": {"Code": "MessageRejected", "Message": "Email rejected"}},
            "SendEmail",
        )

        with (
            patch("app.services.email.settings") as mock_settings,
            patch("app.services.email._get_ses_client", return_value=mock_ses_client),
            patch("app.services.email.logger") as mock_logger,
        ):
            mock_settings.email_enabled = True
            mock_settings.frontend_url = settings.frontend_url
            mock_settings.verification_token_expire_hours = 24
            mock_settings.ses_sender_name = "OrthoSense"
            mock_settings.ses_sender_email = "noreply@orthosense.app"
            mock_settings.aws_region = "eu-central-1"

            await send_verification_email(email, token)

            # Should log error
            mock_logger.error.assert_called_once()
            call_kwargs = mock_logger.error.call_args.kwargs
            assert call_kwargs["to"] == email
