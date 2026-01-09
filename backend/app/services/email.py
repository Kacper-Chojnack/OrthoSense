"""Email service using Resend HTTP API.

Production implementation using Resend.com API (3000 emails/month free).
Falls back to logging when email_enabled=False.
"""

import httpx

from app.core.config import settings
from app.core.logging import get_logger

logger = get_logger(__name__)

RESEND_API_URL = "https://api.resend.com/emails"


async def _send_email(
    to_email: str,
    subject: str,
    html_body: str,
) -> bool:
    """Send email via Resend HTTP API."""
    if not settings.email_enabled:
        logger.info(
            "email_disabled_mock",
            to=to_email,
            subject=subject,
        )
        return True

    if not settings.resend_api_key:
        logger.warning(
            "resend_not_configured",
            to=to_email,
            subject=subject,
        )
        return False

    try:
        async with httpx.AsyncClient(timeout=30.0) as client:
            response = await client.post(
                RESEND_API_URL,
                headers={
                    "Authorization": f"Bearer {settings.resend_api_key}",
                    "Content-Type": "application/json",
                },
                json={
                    "from": f"{settings.resend_from_name} <{settings.resend_from_email}>",
                    "to": [to_email],
                    "subject": subject,
                    "html": html_body,
                },
            )

            if response.status_code == 200:
                data = response.json()
                logger.info(
                    "email_sent",
                    to=to_email,
                    subject=subject,
                    message_id=data.get("id"),
                )
                return True
            else:
                logger.error(
                    "email_send_failed",
                    to=to_email,
                    subject=subject,
                    status_code=response.status_code,
                    response=response.text,
                )
                return False

    except httpx.TimeoutException:
        logger.warning(
            "email_send_timeout",
            to=to_email,
            subject=subject,
        )
        return False
    except Exception as e:
        logger.error(
            "email_send_error",
            to=to_email,
            subject=subject,
            error=str(e),
        )
        return False


async def send_verification_email(email: str, token: str) -> None:
    """Send email verification link."""
    verification_url = f"{settings.frontend_url}/verify-email?token={token}"

    subject = "Verify Your Email - OrthoSense"

    html_body = f"""
    <!DOCTYPE html>
    <html>
    <head>
        <meta charset="UTF-8">
        <style>
            body {{ font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; line-height: 1.6; }}
            .container {{ max-width: 600px; margin: 0 auto; padding: 40px 20px; }}
            .logo {{ font-size: 28px; font-weight: bold; color: #4F46E5; margin-bottom: 30px; }}
            .button {{ 
                display: inline-block; 
                background-color: #4F46E5; 
                color: white !important; 
                padding: 14px 28px; 
                text-decoration: none; 
                border-radius: 8px;
                font-weight: 600;
            }}
            .footer {{ margin-top: 40px; font-size: 13px; color: #6B7280; border-top: 1px solid #E5E7EB; padding-top: 20px; }}
        </style>
    </head>
    <body>
        <div class="container">
            <div class="logo">OrthoSense</div>
            <h1 style="color: #111827;">Welcome! 👋</h1>
            <p>Thank you for signing up for OrthoSense. Click the button below to verify your email address and get started:</p>
            <p style="margin: 30px 0;">
                <a href="{verification_url}" class="button">Verify Email Address</a>
            </p>
            <p style="font-size: 14px; color: #6B7280;">Or copy this link to your browser:</p>
            <p style="word-break: break-all; color: #4F46E5; font-size: 14px;">{verification_url}</p>
            <div class="footer">
                <p>This link expires in {settings.verification_token_expire_hours} hours.</p>
                <p>If you didn't create an OrthoSense account, please ignore this email.</p>
                <p style="margin-top: 20px;">© 2026 OrthoSense. All rights reserved.</p>
            </div>
        </div>
    </body>
    </html>
    """

    await _send_email(email, subject, html_body)


async def send_password_reset_email(email: str, token: str) -> None:
    """Send password reset link."""
    reset_url = f"{settings.frontend_url}/reset-password?token={token}"

    subject = "Reset Your Password - OrthoSense"

    html_body = f"""
    <!DOCTYPE html>
    <html>
    <head>
        <meta charset="UTF-8">
        <style>
            body {{ font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; line-height: 1.6; }}
            .container {{ max-width: 600px; margin: 0 auto; padding: 40px 20px; }}
            .logo {{ font-size: 28px; font-weight: bold; color: #4F46E5; margin-bottom: 30px; }}
            .button {{ 
                display: inline-block; 
                background-color: #DC2626; 
                color: white !important; 
                padding: 14px 28px; 
                text-decoration: none; 
                border-radius: 8px;
                font-weight: 600;
            }}
            .warning {{ background-color: #FEF3C7; padding: 16px; border-radius: 8px; margin: 20px 0; }}
            .footer {{ margin-top: 40px; font-size: 13px; color: #6B7280; border-top: 1px solid #E5E7EB; padding-top: 20px; }}
        </style>
    </head>
    <body>
        <div class="container">
            <div class="logo">OrthoSense</div>
            <h1 style="color: #111827;">Password Reset 🔐</h1>
            <p>We received a request to reset the password for your OrthoSense account.</p>
            <p style="margin: 30px 0;">
                <a href="{reset_url}" class="button">Reset Password</a>
            </p>
            <p style="font-size: 14px; color: #6B7280;">Or copy this link to your browser:</p>
            <p style="word-break: break-all; color: #DC2626; font-size: 14px;">{reset_url}</p>
            <div class="warning">
                ⚠️ <strong>Important:</strong> This link expires in {settings.password_reset_token_expire_hours} hour.
            </div>
            <div class="footer">
                <p>If you didn't request a password reset, please ignore this email. Your password will remain unchanged.</p>
                <p style="margin-top: 20px;">© 2026 OrthoSense. All rights reserved.</p>
            </div>
        </div>
    </body>
    </html>
    """

    await _send_email(email, subject, html_body)


async def send_welcome_email(email: str) -> None:
    """Send welcome email after verification."""
    subject = "Welcome to OrthoSense! 🎉"

    html_body = """
    <!DOCTYPE html>
    <html>
    <head>
        <meta charset="UTF-8">
        <style>
            body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; line-height: 1.6; }
            .container { max-width: 600px; margin: 0 auto; padding: 40px 20px; }
            .logo { font-size: 28px; font-weight: bold; color: #4F46E5; margin-bottom: 30px; }
            .highlight { background-color: #EEF2FF; padding: 24px; border-radius: 12px; margin: 24px 0; }
            .footer { margin-top: 40px; font-size: 13px; color: #6B7280; border-top: 1px solid #E5E7EB; padding-top: 20px; }
        </style>
    </head>
    <body>
        <div class="container">
            <div class="logo">OrthoSense</div>
            <h1 style="color: #111827;">You're All Set! 🎉</h1>
            <p>Thank you for verifying your email address. Your OrthoSense account is now fully active.</p>
            <div class="highlight">
                <h3 style="margin-top: 0; color: #4F46E5;">What you can do now:</h3>
                <ul style="color: #374151;">
                    <li>📱 Log in to the mobile app</li>
                    <li>💪 Start your personalized rehabilitation plan</li>
                    <li>📊 Track your progress with AI-powered analysis</li>
                    <li>🎯 Achieve your recovery goals</li>
                </ul>
            </div>
            <div class="footer">
                <p>Have questions? We're here to help!</p>
                <p style="margin-top: 20px;">© 2026 OrthoSense. All rights reserved.</p>
            </div>
        </div>
    </body>
    </html>
    """

    await _send_email(email, subject, html_body)
