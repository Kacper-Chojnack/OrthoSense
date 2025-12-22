"""Email service for sending verification and password reset emails.

MOCK IMPLEMENTATION: Logs links to console instead of sending emails.
Replace with real SMTP integration when ready for production.
"""

import asyncio

from app.core.config import settings
from app.core.logging import get_logger

logger = get_logger(__name__)


async def send_verification_email(email: str, token: str) -> None:
    """Send email verification link.

    MOCK: Prints to console/logs for testing without SMTP.
    """
    # Simulate async I/O
    await asyncio.sleep(0)

    verification_url = f"{settings.frontend_url}/verify-email?token={token}"

    logger.info(
        "verification_email_mock",
        email=email,
        link=verification_url,
        action="COPY THIS LINK TO VERIFY EMAIL",
    )


async def send_password_reset_email(email: str, token: str) -> None:
    """Send password reset link.

    MOCK: Prints to console/logs for testing without SMTP.
    """
    # Simulate async I/O
    await asyncio.sleep(0)

    reset_url = f"{settings.frontend_url}/reset-password?token={token}"

    logger.info(
        "password_reset_email_mock",
        email=email,
        link=reset_url,
        action="COPY THIS LINK TO RESET PASSWORD",
    )


async def send_welcome_email(email: str) -> None:
    """Send welcome email after verification.

    MOCK: Prints to console/logs for testing without SMTP.
    """
    # Simulate async I/O
    await asyncio.sleep(0)

    logger.info(
        "welcome_email_mock",
        email=email,
        message="Welcome to OrthoSense!",
    )
