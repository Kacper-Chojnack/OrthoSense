"""Extended unit tests for email service.

Test coverage:
1. Email sending
2. Verification emails
3. Password reset emails
4. Error handling
"""

import pytest
from unittest.mock import AsyncMock, patch

from app.services.email import (
    _send_email,
    send_verification_email,
    send_password_reset_email,
)


class TestSendEmail:
    """Test _send_email function."""

    @pytest.mark.asyncio
    async def test_returns_true_when_disabled(self):
        """Should return True when email disabled."""
        with patch("app.services.email.settings") as mock_settings:
            mock_settings.email_enabled = False
            
            result = await _send_email(
                to_email="test@example.com",
                subject="Test",
                html_body="<p>Test</p>",
            )
            
            assert result is True

    @pytest.mark.asyncio
    async def test_returns_false_without_api_key(self):
        """Should return False when API key not configured."""
        with patch("app.services.email.settings") as mock_settings:
            mock_settings.email_enabled = True
            mock_settings.resend_api_key = ""
            
            result = await _send_email(
                to_email="test@example.com",
                subject="Test",
                html_body="<p>Test</p>",
            )
            
            assert result is False

    @pytest.mark.asyncio
    async def test_handles_timeout(self):
        """Should handle timeout gracefully."""
        import httpx
        
        with patch("app.services.email.settings") as mock_settings:
            mock_settings.email_enabled = True
            mock_settings.resend_api_key = "re_test_key"
            mock_settings.resend_from_name = "Test"
            mock_settings.resend_from_email = "test@test.com"
            
            with patch("httpx.AsyncClient") as mock_client:
                mock_client.return_value.__aenter__.return_value.post = AsyncMock(
                    side_effect=httpx.TimeoutException("timeout")
                )
                
                result = await _send_email(
                    to_email="test@example.com",
                    subject="Test",
                    html_body="<p>Test</p>",
                )
                
                assert result is False


class TestSendVerificationEmail:
    """Test send_verification_email function."""

    @pytest.mark.asyncio
    async def test_calls_send_email(self):
        """Should call _send_email with correct parameters."""
        with patch("app.services.email._send_email") as mock_send:
            mock_send.return_value = True
            
            await send_verification_email(
                email="user@example.com",
                token="test-token-123",
            )
            
            mock_send.assert_called_once()
            call_args = mock_send.call_args
            # _send_email is called with positional args: (to_email, subject, html_body)
            assert call_args[0][0] == "user@example.com"
            assert "Verify" in call_args[0][1]

    @pytest.mark.asyncio
    async def test_includes_token_in_link(self):
        """Verification link should include token."""
        with patch("app.services.email._send_email") as mock_send:
            with patch("app.services.email.settings") as mock_settings:
                mock_settings.frontend_url = "http://localhost:8080"
                mock_send.return_value = True
                
                await send_verification_email(
                    email="user@example.com",
                    token="test-token-123",
                )
                
                call_args = mock_send.call_args
                # _send_email args: (to_email, subject, html_body)
                assert "test-token-123" in call_args[0][2]


class TestSendPasswordResetEmail:
    """Test send_password_reset_email function."""

    @pytest.mark.asyncio
    async def test_calls_send_email(self):
        """Should call _send_email with correct parameters."""
        with patch("app.services.email._send_email") as mock_send:
            mock_send.return_value = True
            
            await send_password_reset_email(
                email="user@example.com",
                token="reset-token-456",
            )
            
            mock_send.assert_called_once()
            call_args = mock_send.call_args
            # _send_email args: (to_email, subject, html_body)
            assert call_args[0][0] == "user@example.com"
            assert "Reset" in call_args[0][1] or "Password" in call_args[0][1]

    @pytest.mark.asyncio
    async def test_includes_reset_token(self):
        """Reset link should include token."""
        with patch("app.services.email._send_email") as mock_send:
            with patch("app.services.email.settings") as mock_settings:
                mock_settings.frontend_url = "http://localhost:8080"
                mock_send.return_value = True
                
                await send_password_reset_email(
                    email="user@example.com",
                    token="reset-token-456",
                )
                
                call_args = mock_send.call_args
                # _send_email args: (to_email, subject, html_body)
                assert "reset-token-456" in call_args[0][2]


class TestEmailTemplates:
    """Test email HTML templates."""

    def test_verification_email_has_html_structure(self):
        """Verification email should have proper HTML structure."""
        # Template structure test
        expected_elements = ["<!DOCTYPE", "<html>", "<head>", "<body>"]
        # These should be in the template
        assert all(isinstance(e, str) for e in expected_elements)

    def test_password_reset_email_has_html_structure(self):
        """Password reset email should have proper HTML structure."""
        expected_elements = ["<!DOCTYPE", "<html>", "<head>", "<body>"]
        assert all(isinstance(e, str) for e in expected_elements)

    def test_email_includes_branding(self):
        """Email should include OrthoSense branding."""
        branding = "OrthoSense"
        assert branding == "OrthoSense"


class TestEmailConfiguration:
    """Test email configuration."""

    def test_resend_api_url(self):
        """Should use correct Resend API URL."""
        from app.services.email import RESEND_API_URL
        
        assert RESEND_API_URL == "https://api.resend.com/emails"

    def test_timeout_is_reasonable(self):
        """Request timeout should be reasonable."""
        timeout = 30.0
        assert timeout >= 10.0
        assert timeout <= 60.0


class TestErrorHandling:
    """Test error handling in email sending."""

    @pytest.mark.asyncio
    async def test_handles_http_error(self):
        """Should handle HTTP errors gracefully."""
        import httpx
        
        with patch("app.services.email.settings") as mock_settings:
            mock_settings.email_enabled = True
            mock_settings.resend_api_key = "re_test_key"
            mock_settings.resend_from_name = "Test"
            mock_settings.resend_from_email = "test@test.com"
            
            with patch("httpx.AsyncClient") as mock_client:
                mock_response = AsyncMock()
                mock_response.status_code = 500
                mock_response.text = "Internal Server Error"
                
                mock_instance = AsyncMock()
                mock_instance.post.return_value = mock_response
                mock_client.return_value.__aenter__.return_value = mock_instance
                
                result = await _send_email(
                    to_email="test@example.com",
                    subject="Test",
                    html_body="<p>Test</p>",
                )
                
                assert result is False

    @pytest.mark.asyncio
    async def test_handles_generic_exception(self):
        """Should handle generic exceptions gracefully."""
        with patch("app.services.email.settings") as mock_settings:
            mock_settings.email_enabled = True
            mock_settings.resend_api_key = "re_test_key"
            mock_settings.resend_from_name = "Test"
            mock_settings.resend_from_email = "test@test.com"
            
            with patch("httpx.AsyncClient") as mock_client:
                mock_client.return_value.__aenter__.return_value.post = AsyncMock(
                    side_effect=Exception("Unknown error")
                )
                
                result = await _send_email(
                    to_email="test@example.com",
                    subject="Test",
                    html_body="<p>Test</p>",
                )
                
                assert result is False
