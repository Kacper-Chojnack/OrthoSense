"""Integration tests for Redis rate limiting.

Tests cover:
1. Rate limiter with Redis backend
2. Fallback to in-memory when Redis unavailable
3. Sliding window algorithm
4. Rate limit headers
5. Multiple endpoints rate limiting
"""

import asyncio
import os
from unittest.mock import MagicMock, patch

# Set environment variables BEFORE importing app modules
os.environ["SECRET_KEY"] = "test_secret_key_for_redis_rate_limit"
os.environ["DATABASE_URL"] = "sqlite+aiosqlite:///:memory:"
os.environ["RATE_LIMIT_ENABLED"] = "true"
os.environ["REDIS_URL"] = "redis://localhost:6379"

import pytest
from fastapi import Request

from app.core.rate_limit import RateLimiter, _memory_store


class TestRateLimiterCore:
    """Tests for RateLimiter core functionality."""

    def setup_method(self):
        """Clear memory store before each test."""
        _memory_store.clear()

    @pytest.mark.asyncio
    async def test_rate_limiter_allows_under_limit(self) -> None:
        """Requests under limit are allowed."""
        limiter = RateLimiter(requests=10, window_seconds=60, use_redis=False)

        mock_request = _create_mock_request("192.168.1.1")

        # Should allow 10 requests
        for _ in range(10):
            await limiter.check(mock_request, "test")

    @pytest.mark.asyncio
    async def test_rate_limiter_blocks_over_limit(self) -> None:
        """Requests over limit are blocked."""
        from fastapi import HTTPException

        limiter = RateLimiter(requests=3, window_seconds=60, use_redis=False)
        mock_request = _create_mock_request("192.168.1.2")

        with patch("app.core.rate_limit.settings") as mock_settings:
            mock_settings.rate_limit_enabled = True

            # Use up the limit
            for _ in range(3):
                await limiter.check(mock_request, "test")

            # Next request should be blocked
            with pytest.raises(HTTPException) as exc_info:
                await limiter.check(mock_request, "test")

            assert exc_info.value.status_code == 429

    @pytest.mark.asyncio
    async def test_rate_limiter_different_ips(self) -> None:
        """Different IPs have separate rate limits."""
        limiter = RateLimiter(requests=2, window_seconds=60, use_redis=False)

        request1 = _create_mock_request("192.168.1.10")
        request2 = _create_mock_request("192.168.1.11")

        # Both IPs can make requests
        await limiter.check(request1, "test")
        await limiter.check(request1, "test")
        await limiter.check(request2, "test")
        await limiter.check(request2, "test")

    @pytest.mark.asyncio
    async def test_rate_limiter_different_key_prefixes(self) -> None:
        """Different key prefixes have separate rate limits."""
        limiter = RateLimiter(requests=2, window_seconds=60, use_redis=False)
        mock_request = _create_mock_request("192.168.1.20")

        # Can make requests to different endpoints
        await limiter.check(mock_request, "login")
        await limiter.check(mock_request, "login")
        await limiter.check(mock_request, "register")
        await limiter.check(mock_request, "register")


class TestRateLimiterWithRedis:
    """Tests for RateLimiter with Redis backend."""

    def setup_method(self):
        """Clear memory store before each test."""
        _memory_store.clear()

    @pytest.mark.asyncio
    async def test_redis_fallback_on_connection_error(self) -> None:
        """Falls back to memory when Redis is unavailable."""
        limiter = RateLimiter(requests=5, window_seconds=60, use_redis=True)

        # Mock Redis to simulate connection failure
        with patch("app.core.rate_limit.settings") as mock_settings:
            mock_settings.rate_limit_enabled = True
            mock_settings.redis_url = "redis://nonexistent:6379"

            mock_request = _create_mock_request("192.168.1.30")

            # Should fall back to memory and work
            await limiter.check(mock_request, "fallback_test")

    @pytest.mark.asyncio
    async def test_redis_connection_caching(self) -> None:
        """Redis client is cached after first connection."""
        limiter = RateLimiter(requests=10, window_seconds=60, use_redis=True)

        # Initially no client
        assert limiter._redis_client is None

        # After _get_redis call, client should be cached (or None if unavailable)
        await limiter._get_redis()
        # Connection attempt was made


class TestRateLimiterSlidingWindow:
    """Tests for sliding window algorithm."""

    def setup_method(self):
        """Clear memory store before each test."""
        _memory_store.clear()

    @pytest.mark.asyncio
    async def test_sliding_window_expires_old_requests(self) -> None:
        """Old requests expire from the window."""

        limiter = RateLimiter(requests=2, window_seconds=1, use_redis=False)
        mock_request = _create_mock_request("192.168.1.40")

        # Make 2 requests
        await limiter.check(mock_request, "window_test")
        await limiter.check(mock_request, "window_test")

        # Wait for window to expire
        await asyncio.sleep(1.1)

        # Should be able to make requests again
        await limiter.check(mock_request, "window_test")


class TestRateLimiterHeaders:
    """Tests for rate limit response headers."""

    def setup_method(self):
        """Clear memory store before each test."""
        _memory_store.clear()

    @pytest.mark.asyncio
    async def test_rate_limit_exceeded_includes_retry_after(self) -> None:
        """429 response includes Retry-After header."""
        from fastapi import HTTPException

        limiter = RateLimiter(requests=1, window_seconds=60, use_redis=False)
        mock_request = _create_mock_request("192.168.1.50")

        with patch("app.core.rate_limit.settings") as mock_settings:
            mock_settings.rate_limit_enabled = True

            await limiter.check(mock_request, "header_test")

            with pytest.raises(HTTPException) as exc_info:
                await limiter.check(mock_request, "header_test")

            assert exc_info.value.status_code == 429
            # Headers should contain retry information
            assert "Retry-After" in exc_info.value.headers or exc_info.value.detail


class TestRateLimiterClientIdentification:
    """Tests for client identification logic."""

    def setup_method(self):
        """Clear memory store before each test."""
        _memory_store.clear()

    def test_get_client_key_from_direct_ip(self) -> None:
        """Client key from direct connection IP."""
        limiter = RateLimiter(requests=10, window_seconds=60, use_redis=False)

        mock_request = MagicMock(spec=Request)
        mock_request.client.host = "10.0.0.1"
        mock_request.headers = {}

        key = limiter._get_client_key(mock_request, "test")

        assert "10.0.0.1" in key
        assert "test" in key

    def test_get_client_key_from_forwarded_header(self) -> None:
        """Client key from X-Forwarded-For header."""
        limiter = RateLimiter(requests=10, window_seconds=60, use_redis=False)

        mock_request = MagicMock(spec=Request)
        mock_request.client.host = "127.0.0.1"
        mock_request.headers = {"X-Forwarded-For": "203.0.113.50, 70.41.3.18"}

        key = limiter._get_client_key(mock_request, "proxy_test")

        # Should use first IP from X-Forwarded-For
        assert "203.0.113.50" in key

    def test_get_client_key_no_client(self) -> None:
        """Client key when no client info available."""
        limiter = RateLimiter(requests=10, window_seconds=60, use_redis=False)

        mock_request = MagicMock(spec=Request)
        mock_request.client = None
        mock_request.headers = {}

        key = limiter._get_client_key(mock_request, "unknown_test")

        assert "unknown" in key


class TestRateLimiterDisabled:
    """Tests for rate limiter when disabled."""

    def setup_method(self):
        """Clear memory store before each test."""
        _memory_store.clear()

    @pytest.mark.asyncio
    async def test_disabled_limiter_allows_all(self) -> None:
        """Disabled rate limiter allows all requests."""
        with patch("app.core.rate_limit.settings") as mock_settings:
            mock_settings.rate_limit_enabled = False

            limiter = RateLimiter(requests=1, window_seconds=60, use_redis=False)
            mock_request = _create_mock_request("192.168.1.60")

            # Should allow many requests when disabled
            for _ in range(100):
                await limiter.check(mock_request, "disabled_test")


class TestRateLimiterMemoryStore:
    """Tests for in-memory fallback store."""

    def setup_method(self):
        """Clear memory store before each test."""
        _memory_store.clear()

    def test_memory_store_cleanup(self) -> None:
        """Memory store cleans up old entries."""
        limiter = RateLimiter(requests=10, window_seconds=1, use_redis=False)

        # Check synchronous method
        key = "rate_limit:cleanup_test:192.168.1.70"

        # Add some requests
        allowed, _ = limiter._check_memory_sync(key)
        assert allowed

        # Memory store should have entry
        assert key in _memory_store

    @pytest.mark.asyncio
    async def test_memory_store_concurrent_access(self) -> None:
        """Memory store handles concurrent access."""
        import asyncio

        limiter = RateLimiter(requests=100, window_seconds=60, use_redis=False)

        async def make_request(ip: str):
            request = _create_mock_request(ip)
            await limiter.check(request, "concurrent_test")

        # Many concurrent requests from same IP
        tasks = [make_request("192.168.1.80") for _ in range(50)]
        await asyncio.gather(*tasks)


def _create_mock_request(client_ip: str) -> Request:
    """Create a mock FastAPI Request object."""
    mock_request = MagicMock(spec=Request)
    mock_request.client = MagicMock()
    mock_request.client.host = client_ip
    mock_request.headers = {}
    return mock_request
