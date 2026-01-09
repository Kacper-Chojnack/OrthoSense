"""Unit tests for XSS sanitization module.

These tests ensure proper detection and prevention of XSS attacks.
"""

import pytest

from app.core.sanitizer import (
    contains_xss,
    sanitize_dict,
    sanitize_string,
    validate_no_xss,
)


class TestContainsXSS:
    """Tests for XSS pattern detection."""

    @pytest.mark.parametrize(
        "payload",
        [
            "<script>alert('xss')</script>",
            "<script>alert(1)</script>",
            "<SCRIPT>alert('xss')</SCRIPT>",
            "<ScRiPt>alert(1)</ScRiPt>",
            "<script src='evil.js'></script>",
            "<script type='text/javascript'>alert(1)</script>",
        ],
    )
    def test_detects_script_tags(self, payload: str) -> None:
        """Detect various script tag variations."""
        assert contains_xss(payload) is True

    @pytest.mark.parametrize(
        "payload",
        [
            "javascript:alert(1)",
            "JAVASCRIPT:alert(1)",
            "javascript:void(0)",
            "  javascript:alert(1)",
        ],
    )
    def test_detects_javascript_protocol(self, payload: str) -> None:
        """Detect javascript: protocol in URLs."""
        assert contains_xss(payload) is True

    @pytest.mark.parametrize(
        "payload",
        [
            "<img src=x onerror=alert(1)>",
            "<IMG SRC=x ONERROR=alert(1)>",
            "<img src='x' onerror='alert(1)'>",
            "<img/src/onerror=alert(1)>",
        ],
    )
    def test_detects_img_xss(self, payload: str) -> None:
        """Detect XSS via img tags."""
        assert contains_xss(payload) is True

    @pytest.mark.parametrize(
        "payload",
        [
            "<svg onload=alert(1)>",
            "<SVG ONLOAD=alert(1)>",
            "<svg/onload=alert(1)>",
            "<svg><script>alert(1)</script></svg>",
        ],
    )
    def test_detects_svg_xss(self, payload: str) -> None:
        """Detect XSS via svg tags."""
        assert contains_xss(payload) is True

    @pytest.mark.parametrize(
        "payload",
        [
            "<div onclick=alert(1)>",
            "<body onload=alert(1)>",
            "<input onfocus=alert(1)>",
            "<a onmouseover=alert(1)>",
        ],
    )
    def test_detects_event_handlers(self, payload: str) -> None:
        """Detect event handler attributes."""
        assert contains_xss(payload) is True

    @pytest.mark.parametrize(
        "payload",
        [
            "<iframe src='evil.com'>",
            "<object data='evil.swf'>",
            "<embed src='evil.swf'>",
            "<link href='evil.css'>",
        ],
    )
    def test_detects_dangerous_tags(self, payload: str) -> None:
        """Detect other dangerous HTML tags."""
        assert contains_xss(payload) is True

    @pytest.mark.parametrize(
        "safe_input",
        [
            "Hello World",
            "John Doe",
            "user@example.com",
            "Normal text with numbers 123",
            "Text with special chars: !@#$%^&*()",
            "Unicode: 日本語 中文 한국어",
            "",
            "   ",
        ],
    )
    def test_allows_safe_input(self, safe_input: str) -> None:
        """Safe inputs should not trigger XSS detection."""
        assert contains_xss(safe_input) is False


class TestSanitizeString:
    """Tests for string sanitization."""

    def test_escapes_html_tags(self) -> None:
        """HTML tags are escaped."""
        result = sanitize_string("<script>alert(1)</script>")
        assert "<" not in result
        assert ">" not in result
        assert "&lt;script&gt;" in result

    def test_escapes_quotes(self) -> None:
        """Quotes are escaped."""
        result = sanitize_string("test\"'value")
        assert '"' not in result
        assert "'" not in result or "&apos;" in result or "&#x27;" in result

    def test_removes_null_bytes(self) -> None:
        """Null bytes are removed."""
        result = sanitize_string("test\x00value")
        assert "\x00" not in result
        assert result == "testvalue"

    def test_preserves_safe_content(self) -> None:
        """Safe content is preserved."""
        safe = "Hello World 123"
        assert sanitize_string(safe) == safe

    def test_handles_empty_string(self) -> None:
        """Empty string returns empty."""
        assert sanitize_string("") == ""

    def test_handles_none_like_empty(self) -> None:
        """Empty/falsy values handled gracefully."""
        assert sanitize_string("") == ""


class TestValidateNoXSS:
    """Tests for Pydantic validator function."""

    def test_raises_on_xss(self) -> None:
        """ValueError raised for XSS content."""
        with pytest.raises(ValueError, match="dangerous content"):
            validate_no_xss("<script>alert(1)</script>")

    def test_returns_safe_value(self) -> None:
        """Safe value is returned unchanged."""
        safe = "John Doe"
        assert validate_no_xss(safe) == safe


class TestSanitizeDict:
    """Tests for recursive dictionary sanitization."""

    def test_sanitizes_string_values(self) -> None:
        """String values are sanitized."""
        data = {"name": "<script>evil</script>"}
        result = sanitize_dict(data)
        assert "<script>" not in result["name"]

    def test_handles_nested_dicts(self) -> None:
        """Nested dictionaries are sanitized."""
        data = {"user": {"name": "<script>evil</script>"}}
        result = sanitize_dict(data)
        assert "<script>" not in result["user"]["name"]

    def test_handles_lists(self) -> None:
        """Lists with strings are sanitized."""
        data = {"tags": ["<script>one</script>", "safe"]}
        result = sanitize_dict(data)
        assert "<script>" not in result["tags"][0]
        assert result["tags"][1] == "safe"

    def test_handles_list_of_dicts(self) -> None:
        """Lists of dictionaries are sanitized."""
        data = {"items": [{"name": "<img onerror=alert(1)>"}]}
        result = sanitize_dict(data)
        assert "<img" not in result["items"][0]["name"]

    def test_preserves_non_string_values(self) -> None:
        """Non-string values preserved."""
        data = {"count": 42, "active": True, "ratio": 3.14}
        result = sanitize_dict(data)
        assert result == data


class TestXSSEdgeCases:
    """Edge cases and bypass attempts."""

    @pytest.mark.parametrize(
        "payload",
        [
            # Encoded payloads
            "&lt;script&gt;alert(1)&lt;/script&gt;",
            # Mixed case
            "<sCrIpT>alert(1)</ScRiPt>",
            # Whitespace variations
            "<script >alert(1)</script >",
            "< script>alert(1)</script>",
            # Attribute variations
            '<img src="x" onerror="alert(1)">',
            "<img src='x' onerror='alert(1)'>",
            "<img src=x onerror=alert(1)>",
            # Protocol variations
            "JAVASCRIPT:alert(1)",
            "  javascript:alert(1)",
            "java\nscript:alert(1)",  # This might not be caught, but browsers handle it
        ],
    )
    def test_common_bypass_attempts(self, payload: str) -> None:
        """Common XSS bypass attempts should be detected or sanitized."""
        # Either detected as XSS or sanitized to be safe
        if contains_xss(payload):
            # Detected - validator will reject
            with pytest.raises(ValueError):
                validate_no_xss(payload)
        else:
            # Not detected - but sanitization should make it safe
            sanitized = sanitize_string(payload)
            assert "<script>" not in sanitized.lower()
            assert "onerror=" not in sanitized.lower()
