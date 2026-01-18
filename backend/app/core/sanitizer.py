"""Input sanitization utilities for XSS prevention.

This module provides sanitization functions to prevent XSS attacks
by removing or escaping potentially dangerous HTML/JavaScript content.
"""

import html
import re
from typing import Annotated, Any

from pydantic import AfterValidator

# Patterns for detecting XSS payloads
XSS_PATTERNS: list[re.Pattern[str]] = [
    # Script tags
    re.compile(r"<script[^>]*>.*?</script>", re.IGNORECASE | re.DOTALL),
    re.compile(r"<script[^>]*>", re.IGNORECASE),
    re.compile(r"</script>", re.IGNORECASE),
    # Event handlers
    re.compile(r"\bon\w+\s*=", re.IGNORECASE),
    # JavaScript protocol
    re.compile(r"javascript\s*:", re.IGNORECASE),
    re.compile(r"vbscript\s*:", re.IGNORECASE),
    re.compile(r"data\s*:", re.IGNORECASE),
    # HTML tags that can execute scripts
    re.compile(r"<\s*img[^>]*>", re.IGNORECASE),
    re.compile(r"<\s*svg[^>]*>", re.IGNORECASE),
    re.compile(r"<\s*iframe[^>]*>", re.IGNORECASE),
    re.compile(r"<\s*object[^>]*>", re.IGNORECASE),
    re.compile(r"<\s*embed[^>]*>", re.IGNORECASE),
    re.compile(r"<\s*link[^>]*>", re.IGNORECASE),
    re.compile(r"<\s*style[^>]*>", re.IGNORECASE),
    re.compile(r"<\s*meta[^>]*>", re.IGNORECASE),
    re.compile(r"<\s*base[^>]*>", re.IGNORECASE),
    re.compile(r"<\s*form[^>]*>", re.IGNORECASE),
    re.compile(r"<\s*input[^>]*>", re.IGNORECASE),
    re.compile(r"<\s*button[^>]*>", re.IGNORECASE),
    # Expression injection
    re.compile(r"expression\s*\(", re.IGNORECASE),
    re.compile(r"eval\s*\(", re.IGNORECASE),
    # Generic HTML tags
    re.compile(r"<[^>]+>"),
]


def contains_xss(value: str) -> bool:
    """Check if a string contains potential XSS payloads.

    Args:
        value: String to check for XSS content.

    Returns:
        True if XSS pattern detected, False otherwise.
    """
    if not value:
        return False

    # Check against all XSS patterns
    for pattern in XSS_PATTERNS:
        if pattern.search(value):
            return True

    # Check for HTML entities that could be decoded to XSS
    decoded = html.unescape(value)
    if decoded != value:
        for pattern in XSS_PATTERNS:
            if pattern.search(decoded):
                return True

    return False


def sanitize_string(value: str) -> str:
    """Sanitize a string by HTML-escaping dangerous characters.

    Args:
        value: String to sanitize.

    Returns:
        Sanitized string with HTML entities escaped.
    """
    if not value:
        return value

    # HTML escape special characters
    sanitized = html.escape(value, quote=True)

    # Remove null bytes
    sanitized = sanitized.replace("\x00", "")

    return sanitized


def validate_no_xss(value: str) -> str:
    """Pydantic validator that rejects strings containing XSS payloads.

    Args:
        value: String to validate.

    Returns:
        The original string if valid.

    Raises:
        ValueError: If XSS payload detected.
    """
    if contains_xss(value):
        raise ValueError("Input contains potentially dangerous content")
    return value


# Type annotation for Pydantic fields that should reject XSS
SafeString = Annotated[str, AfterValidator(validate_no_xss)]


def sanitize_dict(data: dict[str, Any]) -> dict[str, Any]:
    """Recursively sanitize all string values in a dictionary.

    Args:
        data: Dictionary to sanitize.

    Returns:
        Dictionary with all string values sanitized.
    """
    result: dict[str, Any] = {}
    for key, value in data.items():
        if isinstance(value, str):
            result[key] = sanitize_string(value)
        elif isinstance(value, dict):
            result[key] = sanitize_dict(value)
        elif isinstance(value, list):
            sanitized_list: list[Any] = [
                sanitize_dict(item)
                if isinstance(item, dict)
                else sanitize_string(item)
                if isinstance(item, str)
                else item
                for item in value
            ]
            result[key] = sanitized_list
        else:
            result[key] = value
    return result
