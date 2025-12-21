"""Rate limiting using Token Bucket algorithm with Redis backend.

Provides decorator-based rate limiting for FastAPI endpoints.
Falls back to in-memory limiter when Redis is unavailable.
"""

from collections.abc import Callable
from datetime import datetime
from functools import wraps
from typing import Any

from fastapi import HTTPException, Request, status

from app.core.config import settings
from app.core.logging import get_logger

logger = get_logger(__name__)

# In-memory fallback storage (for dev/testing without Redis)
_memory_store: dict[str, list[float]] = {}


class RateLimiter:
    """Token Bucket rate limiter with Redis/memory backend."""

    def __init__(
        self,
        requests: int,
        window_seconds: int,
        *,
        use_redis: bool = True,
    ) -> None:
        """Initialize rate limiter.

        Args:
            requests: Maximum requests allowed in window.
            window_seconds: Time window in seconds.
            use_redis: Whether to use Redis (falls back to memory if unavailable).
        """
        self.requests = requests
        self.window_seconds = window_seconds
        self.use_redis = use_redis and settings.rate_limit_enabled
        self._redis_client: Any = None

    async def _get_redis(self) -> Any:
        """Lazy load Redis client."""
        if self._redis_client is None and self.use_redis:
            try:
                import redis.asyncio as redis

                self._redis_client = redis.from_url(
                    settings.redis_url,
                    encoding="utf-8",
                    decode_responses=True,
                )
                # Test connection
                await self._redis_client.ping()
                logger.info("rate_limiter_redis_connected")
            except Exception as e:
                logger.warning("rate_limiter_redis_unavailable", error=str(e))
                self._redis_client = None
        return self._redis_client

    def _get_client_key(self, request: Request, key_prefix: str) -> str:
        """Generate unique key for client identification."""
        # Use X-Forwarded-For header for clients behind proxy, fallback to client IP
        forwarded = request.headers.get("X-Forwarded-For")
        if forwarded:
            client_ip = forwarded.split(",")[0].strip()
        else:
            client_ip = request.client.host if request.client else "unknown"

        return f"rate_limit:{key_prefix}:{client_ip}"

    async def _check_redis(self, key: str) -> tuple[bool, int]:
        """Check rate limit using Redis with sliding window."""
        redis_client = await self._get_redis()
        if redis_client is None:
            return await self._check_memory(key)

        try:
            now = datetime.now().timestamp()
            window_start = now - self.window_seconds

            # Use Redis sorted set for sliding window
            pipe = redis_client.pipeline()
            pipe.zremrangebyscore(key, 0, window_start)
            pipe.zadd(key, {str(now): now})
            pipe.zcard(key)
            pipe.expire(key, self.window_seconds)
            results = await pipe.execute()

            current_requests = results[2]
            remaining = max(0, self.requests - current_requests)

            if current_requests > self.requests:
                # Remove the request we just added since it's over limit
                await redis_client.zrem(key, str(now))
                return False, 0

            return True, remaining
        except Exception as e:
            logger.warning("rate_limit_redis_error", error=str(e))
            return await self._check_memory(key)

    def _check_memory_sync(self, key: str) -> tuple[bool, int]:
        """Fallback in-memory rate limiting (synchronous)."""
        now = datetime.now().timestamp()
        window_start = now - self.window_seconds

        if key not in _memory_store:
            _memory_store[key] = []

        # Clean old entries
        _memory_store[key] = [t for t in _memory_store[key] if t > window_start]

        current_requests = len(_memory_store[key])
        remaining = max(0, self.requests - current_requests)

        if current_requests >= self.requests:
            return False, 0

        _memory_store[key].append(now)
        return True, remaining - 1

    async def _check_memory(self, key: str) -> tuple[bool, int]:
        """Async wrapper for in-memory rate limiting."""
        return self._check_memory_sync(key)

    async def check(self, request: Request, key_prefix: str = "default") -> bool:
        """Check if request is within rate limit.

        Args:
            request: FastAPI request object.
            key_prefix: Prefix for rate limit key (e.g., endpoint name).

        Returns:
            True if request is allowed, raises HTTPException otherwise.
        """
        if not settings.rate_limit_enabled:
            return True

        key = self._get_client_key(request, key_prefix)
        allowed, _ = await self._check_redis(key)

        if not allowed:
            logger.warning(
                "rate_limit_exceeded",
                key=key,
                limit=self.requests,
                window=self.window_seconds,
            )
            raise HTTPException(
                status_code=status.HTTP_429_TOO_MANY_REQUESTS,
                detail=f"Rate limit exceeded. Try again in {self.window_seconds} seconds.",
                headers={"Retry-After": str(self.window_seconds)},
            )

        return True


# Pre-configured limiters for common use cases
auth_limiter = RateLimiter(requests=5, window_seconds=60)  # 5 req/min for auth
api_limiter = RateLimiter(
    requests=100, window_seconds=60
)  # 100 req/min for general API
strict_limiter = RateLimiter(
    requests=3, window_seconds=300
)  # 3 req/5min for sensitive ops


def rate_limit(
    requests: int = 10,
    window_seconds: int = 60,
    key_prefix: str | None = None,
) -> Callable[..., Any]:
    """Decorator for rate limiting endpoints.

    Usage:
        @router.post("/login")
        @rate_limit(requests=5, window_seconds=60)
        async def login(request: Request, ...):
            ...

    Args:
        requests: Maximum requests allowed in window.
        window_seconds: Time window in seconds.
        key_prefix: Custom key prefix (defaults to function name).
    """
    limiter = RateLimiter(requests=requests, window_seconds=window_seconds)

    def decorator(func: Callable[..., Any]) -> Callable[..., Any]:
        @wraps(func)
        async def wrapper(*args: Any, **kwargs: Any) -> Any:
            # Find Request object in args/kwargs
            request = kwargs.get("request")
            if request is None:
                for arg in args:
                    if isinstance(arg, Request):
                        request = arg
                        break

            if request is not None:
                prefix = key_prefix or func.__name__
                await limiter.check(request, prefix)

            return await func(*args, **kwargs)

        return wrapper

    return decorator
