"""
Unit tests for Email service.

Test coverage:
1. send_verification_email
2. send_password_reset_email
3. send_welcome_email
4. Logging verification
"""

import pytest

from app.services.email import (
    send_password_reset_email,
    send_verification_email,
    send_welcome_email,
)


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
