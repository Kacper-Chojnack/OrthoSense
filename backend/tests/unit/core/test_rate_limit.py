"""
Unit tests for rate limiting module.

Test coverage:
1. RateLimiter initialization
2. Client key generation
3. Memory-based rate limiting
4. Rate limit checking
5. Pre-configured limiters
6. Decorator functionality
"""

from datetime import datetime
from unittest.mock import AsyncMock, MagicMock, patch

import pytest
from fastapi import HTTPException, Request

from app.core.rate_limit import (
    RateLimiter,
    _memory_store,
    api_limiter,
    auth_limiter,
    rate_limit,
    strict_limiter,
)


class TestRateLimiterInit:
    """Tests for RateLimiter initialization."""

    def test_init_with_defaults(self) -> None:
        """RateLimiter initializes with correct parameters."""
        limiter = RateLimiter(requests=10, window_seconds=60)

        assert limiter.requests == 10
        assert limiter.window_seconds == 60
        # use_redis depends on settings.rate_limit_enabled
        assert isinstance(limiter.use_redis, bool)

    def test_init_without_redis(self) -> None:
        """RateLimiter can be initialized without Redis."""
        limiter = RateLimiter(requests=10, window_seconds=60, use_redis=False)

        assert limiter.use_redis is False


class TestClientKeyGeneration:
    """Tests for client key generation."""

    def test_get_client_key_from_direct_ip(self) -> None:
        """Client key is generated from direct client IP."""
        limiter = RateLimiter(requests=10, window_seconds=60)
        request = MagicMock(spec=Request)
        request.headers = {}
        request.client = MagicMock()
        request.client.host = "192.168.1.1"

        key = limiter._get_client_key(request, "test")

        assert key == "rate_limit:test:192.168.1.1"

    def test_get_client_key_from_forwarded_header(self) -> None:
        """Client key uses X-Forwarded-For header when present."""
        limiter = RateLimiter(requests=10, window_seconds=60)
        request = MagicMock(spec=Request)
        request.headers = {"X-Forwarded-For": "10.0.0.1, 192.168.1.1"}
        request.client = MagicMock()
        request.client.host = "192.168.1.1"

        key = limiter._get_client_key(request, "test")

        assert key == "rate_limit:test:10.0.0.1"

    def test_get_client_key_no_client(self) -> None:
        """Client key handles missing client info."""
        limiter = RateLimiter(requests=10, window_seconds=60)
        request = MagicMock(spec=Request)
        request.headers = {}
        request.client = None

        key = limiter._get_client_key(request, "test")

        assert key == "rate_limit:test:unknown"


class TestMemoryRateLimiting:
    """Tests for in-memory rate limiting fallback."""

    def test_memory_sync_allows_within_limit(self) -> None:
        """Memory limiter allows requests within limit."""
        limiter = RateLimiter(requests=3, window_seconds=60, use_redis=False)
        key = f"test_key_{datetime.now().timestamp()}"

        # Clear memory store for this key
        _memory_store.pop(key, None)

        allowed1, remaining1 = limiter._check_memory_sync(key)
        allowed2, remaining2 = limiter._check_memory_sync(key)
        allowed3, remaining3 = limiter._check_memory_sync(key)

        assert allowed1 is True
        assert allowed2 is True
        assert allowed3 is True

    def test_memory_sync_blocks_over_limit(self) -> None:
        """Memory limiter blocks requests over limit."""
        limiter = RateLimiter(requests=2, window_seconds=60, use_redis=False)
        key = f"test_key_block_{datetime.now().timestamp()}"

        # Clear memory store for this key
        _memory_store.pop(key, None)

        limiter._check_memory_sync(key)
        limiter._check_memory_sync(key)
        allowed, remaining = limiter._check_memory_sync(key)

        assert allowed is False
        assert remaining == 0

    @pytest.mark.asyncio
    async def test_memory_async_wrapper(self) -> None:
        """Async memory check wrapper works."""
        limiter = RateLimiter(requests=5, window_seconds=60, use_redis=False)
        key = f"test_key_async_{datetime.now().timestamp()}"

        _memory_store.pop(key, None)

        allowed, remaining = await limiter._check_memory(key)

        assert allowed is True


class TestRateLimitCheck:
    """Tests for rate limit checking."""

    @pytest.mark.asyncio
    async def test_check_passes_within_limit(self) -> None:
        """Check passes for requests within limit."""
        with patch.object(RateLimiter, "_check_redis", new_callable=AsyncMock) as mock:
            mock.return_value = (True, 5)

            limiter = RateLimiter(requests=10, window_seconds=60)
            request = MagicMock(spec=Request)
            request.headers = {}
            request.client = MagicMock()
            request.client.host = "192.168.1.1"

            # Should not raise
            await limiter.check(request, "test")

    @pytest.mark.asyncio
    async def test_check_raises_when_exceeded(self) -> None:
        """Check raises HTTPException when limit exceeded (only if enabled)."""
        with (
            patch.object(RateLimiter, "_check_redis", new_callable=AsyncMock) as mock,
            patch("app.core.rate_limit.settings") as mock_settings,
        ):
            mock_settings.rate_limit_enabled = True
            mock.return_value = (False, 0)

            limiter = RateLimiter(requests=10, window_seconds=60)
            request = MagicMock(spec=Request)
            request.headers = {}
            request.client = MagicMock()
            request.client.host = "192.168.1.1"

            with pytest.raises(HTTPException) as exc_info:
                await limiter.check(request, "test")

            assert exc_info.value.status_code == 429
            assert "Rate limit exceeded" in exc_info.value.detail

    @pytest.mark.asyncio
    async def test_check_skipped_when_disabled(self) -> None:
        """Check is skipped when rate limiting is disabled."""
        with patch("app.core.rate_limit.settings") as mock_settings:
            mock_settings.rate_limit_enabled = False

            limiter = RateLimiter(requests=10, window_seconds=60)
            request = MagicMock(spec=Request)

            # Should not raise even without proper request setup
            await limiter.check(request, "test")


class TestPreConfiguredLimiters:
    """Tests for pre-configured rate limiters."""

    def test_auth_limiter_config(self) -> None:
        """Auth limiter has correct configuration."""
        assert auth_limiter.requests == 5
        assert auth_limiter.window_seconds == 60

    def test_api_limiter_config(self) -> None:
        """API limiter has correct configuration."""
        assert api_limiter.requests == 100
        assert api_limiter.window_seconds == 60

    def test_strict_limiter_config(self) -> None:
        """Strict limiter has correct configuration."""
        assert strict_limiter.requests == 3
        assert strict_limiter.window_seconds == 300


class TestRateLimitDecorator:
    """Tests for rate_limit decorator."""

    @pytest.mark.asyncio
    async def test_decorator_applies_rate_limiting(self) -> None:
        """Decorator applies rate limiting to function."""

        @rate_limit(requests=5, window_seconds=60)
        async def test_endpoint(request: Request) -> str:
            return "success"

        with patch.object(RateLimiter, "check", new_callable=AsyncMock) as mock:
            request = MagicMock(spec=Request)
            result = await test_endpoint(request=request)

            assert result == "success"
            mock.assert_called_once()

    @pytest.mark.asyncio
    async def test_decorator_finds_request_in_args(self) -> None:
        """Decorator finds Request in positional args."""

        @rate_limit(requests=5, window_seconds=60)
        async def test_endpoint(request: Request, data: str) -> str:
            return f"success: {data}"

        with patch.object(RateLimiter, "check", new_callable=AsyncMock) as mock:
            request = MagicMock(spec=Request)
            result = await test_endpoint(request, "test_data")

            assert "success" in result
            mock.assert_called_once()

    @pytest.mark.asyncio
    async def test_decorator_uses_custom_prefix(self) -> None:
        """Decorator uses custom key prefix."""

        @rate_limit(requests=5, window_seconds=60, key_prefix="custom_prefix")
        async def test_endpoint(request: Request) -> str:
            return "success"

        with patch.object(RateLimiter, "check", new_callable=AsyncMock) as mock:
            request = MagicMock(spec=Request)
            await test_endpoint(request=request)

            mock.assert_called_once()
            call_args = mock.call_args
            assert call_args[0][1] == "custom_prefix"
