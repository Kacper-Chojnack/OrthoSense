import os
from unittest.mock import MagicMock, patch

import pytest
from fastapi import FastAPI, HTTPException, Request
from fastapi.testclient import TestClient

from app.core.rate_limit import RateLimiter, rate_limit

# Skip tests when rate limiting is disabled
pytestmark = pytest.mark.skipif(
    os.environ.get("RATE_LIMIT_ENABLED", "true").lower() == "false",
    reason="Rate limiting is disabled in test environment",
)

# Setup a dummy app for testing decorator
app = FastAPI()


@app.get("/test-limit")
@rate_limit(requests=2, window_seconds=1)
async def endpoint_for_limit_test(request: Request):
    return {"status": "ok"}


client = TestClient(app)


def test_rate_limiter_memory_logic():
    """Test the in-memory rate limiting logic directly."""
    limiter = RateLimiter(requests=2, window_seconds=1)
    limiter.use_redis = False  # Force memory

    key = "test_key"

    # 1st request
    allowed, remaining = limiter._check_memory_sync(key)
    assert allowed
    assert remaining == 1

    # 2nd request
    allowed, remaining = limiter._check_memory_sync(key)
    assert allowed
    assert remaining == 0

    # 3rd request (should fail)
    allowed, remaining = limiter._check_memory_sync(key)
    assert not allowed
    assert remaining == 0


@pytest.mark.asyncio
async def test_rate_limiter_check_async():
    """Test the async check method."""
    limiter = RateLimiter(requests=1, window_seconds=1)
    limiter.use_redis = False

    mock_request = MagicMock()
    mock_request.client.host = "127.0.0.1"
    mock_request.headers = {}

    with patch("app.core.rate_limit.settings") as mock_settings:
        mock_settings.rate_limit_enabled = True

        # Should pass
        await limiter.check(mock_request, "test")

        # Should fail
        with pytest.raises(HTTPException) as exc:
            await limiter.check(mock_request, "test")
        assert exc.value.status_code == 429


def test_decorator_integration():
    """Test the rate_limit decorator via TestClient."""
    from app.core.rate_limit import _memory_store

    # Clear state before test
    _memory_store.clear()

    with patch("app.core.rate_limit.settings") as mock_settings:
        mock_settings.rate_limit_enabled = True

        # 1st request
        resp = client.get("/test-limit")
        assert resp.status_code == 200

        # 2nd request
        resp = client.get("/test-limit")
        assert resp.status_code == 200

        # 3rd request (blocked)
        resp = client.get("/test-limit")
        assert resp.status_code == 429
        assert "Retry-After" in resp.headers
