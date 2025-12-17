"""Email service for sending verification and password reset emails.

MOCK IMPLEMENTATION: Logs links to console instead of sending emails.
Replace with real SMTP integration when ready for production.
"""

from app.core.config import settings
from app.core.logging import get_logger

logger = get_logger(__name__)


async def send_verification_email(email: str, token: str) -> None:
    """Send email verification link.

    MOCK: Prints to console/logs for testing without SMTP.
    """
    verification_url = f"{settings.frontend_url}/verify-email?token={token}"

    logger.info(
        "verification_email_mock",
        email=email,
        action="COPY THIS LINK TO VERIFY EMAIL",
    )
    # Print prominently for easy testing
    print("\n" + "=" * 60)
    print("📧 VERIFICATION EMAIL (Mock)")
    print("=" * 60)
    print(f"To: {email}")
    print(f"Link: {verification_url}")
    print("=" * 60 + "\n")


async def send_password_reset_email(email: str, token: str) -> None:
    """Send password reset link.

    MOCK: Prints to console/logs for testing without SMTP.
    """
    reset_url = f"{settings.frontend_url}/reset-password?token={token}"

    logger.info(
        "password_reset_email_mock",
        email=email,
        action="COPY THIS LINK TO RESET PASSWORD",
    )
    # Print prominently for easy testing
    print("\n" + "=" * 60)
    print("🔐 PASSWORD RESET EMAIL (Mock)")
    print("=" * 60)
    print(f"To: {email}")
    print(f"Link: {reset_url}")
    print("=" * 60 + "\n")


async def send_welcome_email(email: str) -> None:
    """Send welcome email after verification.

    MOCK: Prints to console/logs for testing without SMTP.
    """
    logger.info(
        "welcome_email_mock",
        email=email,
    )
    print("\n" + "=" * 60)
    print("🎉 WELCOME EMAIL (Mock)")
    print("=" * 60)
    print(f"To: {email}")
    print("Welcome to OrthoSense!")
    print("=" * 60 + "\n")
