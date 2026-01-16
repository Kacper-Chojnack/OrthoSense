"""
Unit tests for rate limiting module.

Test coverage:
1. RateLimiter initialization
2. Client key generation
3. Memory-based rate limiting
4. Redis-based rate limiting
5. Rate limit checking
6. Pre-configured limiters
7. Decorator functionality
8. Redis connection handling
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
    auth_strict_limiter,
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

    def test_init_redis_client_is_none(self) -> None:
        """RateLimiter initializes with None Redis client."""
        limiter = RateLimiter(requests=10, window_seconds=60)

        assert limiter._redis_client is None


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

    def test_get_client_key_single_forwarded_ip(self) -> None:
        """Client key handles single X-Forwarded-For IP."""
        limiter = RateLimiter(requests=10, window_seconds=60)
        request = MagicMock(spec=Request)
        request.headers = {"X-Forwarded-For": "10.0.0.1"}
        request.client = MagicMock()
        request.client.host = "192.168.1.1"

        key = limiter._get_client_key(request, "test")

        assert key == "rate_limit:test:10.0.0.1"

    def test_get_client_key_with_different_prefixes(self) -> None:
        """Client key changes with different prefixes."""
        limiter = RateLimiter(requests=10, window_seconds=60)
        request = MagicMock(spec=Request)
        request.headers = {}
        request.client = MagicMock()
        request.client.host = "192.168.1.1"

        key1 = limiter._get_client_key(request, "login")
        key2 = limiter._get_client_key(request, "register")

        assert key1 == "rate_limit:login:192.168.1.1"
        assert key2 == "rate_limit:register:192.168.1.1"
        assert key1 != key2


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

    @pytest.mark.asyncio
    async def test_decorator_without_request(self) -> None:
        """Decorator handles case when no Request object is found."""

        @rate_limit(requests=5, window_seconds=60)
        async def test_endpoint(data: str) -> str:
            return f"success: {data}"

        # Should not raise - just skips rate limiting if no Request
        result = await test_endpoint(data="test_data")

        assert "success" in result

    @pytest.mark.asyncio
    async def test_decorator_uses_function_name_as_prefix(self) -> None:
        """Decorator uses function name as default key prefix."""

        @rate_limit(requests=5, window_seconds=60)
        async def my_unique_endpoint(request: Request) -> str:
            return "success"

        with patch.object(RateLimiter, "check", new_callable=AsyncMock) as mock:
            request = MagicMock(spec=Request)
            await my_unique_endpoint(request=request)

            mock.assert_called_once()
            call_args = mock.call_args
            assert call_args[0][1] == "my_unique_endpoint"


class TestRedisRateLimiting:
    """Tests for Redis-based rate limiting."""

    @pytest.mark.asyncio
    async def test_get_redis_returns_none_when_disabled(self) -> None:
        """_get_redis returns None when Redis is disabled."""
        limiter = RateLimiter(requests=10, window_seconds=60, use_redis=False)

        result = await limiter._get_redis()

        assert result is None

    @pytest.mark.asyncio
    async def test_get_redis_handles_connection_error(self) -> None:
        """_get_redis handles connection errors gracefully."""
        with patch("app.core.rate_limit.settings") as mock_settings:
            mock_settings.rate_limit_enabled = True
            mock_settings.redis_url = "redis://invalid:6379"

            limiter = RateLimiter(requests=10, window_seconds=60, use_redis=True)
            limiter.use_redis = True

            # Mock Redis import to simulate connection failure
            with patch.dict("sys.modules", {"redis.asyncio": MagicMock()}):
                import sys

                mock_redis = sys.modules["redis.asyncio"]
                mock_client = AsyncMock()
                mock_client.ping.side_effect = Exception("Connection refused")
                mock_redis.from_url.return_value = mock_client

                result = await limiter._get_redis()

                assert result is None

    @pytest.mark.asyncio
    async def test_check_redis_falls_back_to_memory(self) -> None:
        """_check_redis falls back to memory on Redis error."""
        limiter = RateLimiter(requests=10, window_seconds=60, use_redis=False)
        key = f"test_redis_fallback_{datetime.now().timestamp()}"

        _memory_store.pop(key, None)

        # Should use memory fallback
        allowed, remaining = await limiter._check_redis(key)

        assert allowed is True

    @pytest.mark.asyncio
    async def test_check_redis_exception_falls_back(self) -> None:
        """_check_redis falls back to memory on exception."""
        limiter = RateLimiter(requests=10, window_seconds=60, use_redis=True)
        key = f"test_exception_fallback_{datetime.now().timestamp()}"

        _memory_store.pop(key, None)

        # Mock _get_redis to return a mock that raises exception
        mock_redis = MagicMock()
        mock_redis.pipeline.side_effect = RuntimeError("Redis error")

        with patch.object(limiter, "_get_redis", new_callable=AsyncMock) as mock_get:
            mock_get.return_value = mock_redis

            allowed, remaining = await limiter._check_redis(key)

            # Should fall back to memory and succeed
            assert allowed is True


class TestAuthStrictLimiter:
    """Tests for auth_strict_limiter configuration."""

    def test_auth_strict_limiter_config(self) -> None:
        """Auth strict limiter has correct brute force protection config."""
        assert auth_strict_limiter.requests == 3
        assert auth_strict_limiter.window_seconds == 300  # 5 minutes


class TestRateLimitRetryAfter:
    """Tests for Retry-After header in rate limit responses."""

    @pytest.mark.asyncio
    async def test_rate_limit_includes_retry_after_header(self) -> None:
        """Rate limit exception includes Retry-After header."""
        with (
            patch.object(RateLimiter, "_check_redis", new_callable=AsyncMock) as mock,
            patch("app.core.rate_limit.settings") as mock_settings,
        ):
            mock_settings.rate_limit_enabled = True
            mock.return_value = (False, 0)

            limiter = RateLimiter(requests=10, window_seconds=120)
            request = MagicMock(spec=Request)
            request.headers = {}
            request.client = MagicMock()
            request.client.host = "192.168.1.1"

            with pytest.raises(HTTPException) as exc_info:
                await limiter.check(request, "test")

            assert exc_info.value.headers is not None
            assert "Retry-After" in exc_info.value.headers
            assert exc_info.value.headers["Retry-After"] == "120"


class TestMemoryStoreCleanup:
    """Tests for memory store entry cleanup."""

    def test_memory_store_cleans_old_entries(self) -> None:
        """Memory store removes entries outside the time window."""
        limiter = RateLimiter(requests=10, window_seconds=1, use_redis=False)
        key = f"test_cleanup_{datetime.now().timestamp()}"

        _memory_store.pop(key, None)

        # Add some old entries manually
        import time

        old_time = datetime.now().timestamp() - 10  # 10 seconds ago
        _memory_store[key] = [old_time, old_time + 0.1, old_time + 0.2]

        # Now check - old entries should be cleaned
        allowed, remaining = limiter._check_memory_sync(key)

        assert allowed is True
        # Old entries should be removed, only new entry remains
        assert len(_memory_store[key]) == 1
