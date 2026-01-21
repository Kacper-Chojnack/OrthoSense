"""
API Performance Tests for OrthoSense Backend.

This module contains performance benchmarks that measure:
- API endpoint latency (p50, p95, p99)
- Throughput under concurrent load
- Response time degradation

Results are exported to JSON for visualization.

Run with: pytest backend/tests/test_performance.py -v --tb=short
"""

import asyncio
import json
import os
import statistics
import time
from datetime import UTC, datetime
from pathlib import Path
from typing import TypedDict
from uuid import uuid4

import pytest
import pytest_asyncio
from httpx import ASGITransport, AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession, create_async_engine
from sqlalchemy.orm import sessionmaker
from sqlmodel import SQLModel

# Set environment variables BEFORE importing app modules
os.environ.setdefault("SECRET_KEY", "test_secret_key_for_performance_tests")
os.environ.setdefault("DATABASE_URL", "sqlite+aiosqlite:///:memory:")

from app.core.database import get_session
from app.core.security import create_access_token, hash_password
from app.main import app
from app.models.exercise import BodyPart, Exercise, ExerciseCategory
from app.models.user import User


class LatencyResult(TypedDict):
    """Structure for latency measurement results."""

    endpoint: str
    method: str
    requests: int
    min_ms: float
    max_ms: float
    mean_ms: float
    median_ms: float
    p95_ms: float
    p99_ms: float
    std_dev_ms: float
    success_rate: float
    throughput_rps: float


RESULTS_DIR = Path(__file__).parent.parent / ".benchmarks"


@pytest_asyncio.fixture
async def async_engine():
    """Create in-memory SQLite engine for tests."""
    engine = create_async_engine(
        "sqlite+aiosqlite:///:memory:",
        echo=False,
        connect_args={"check_same_thread": False},
    )
    async with engine.begin() as conn:
        await conn.run_sync(SQLModel.metadata.create_all)
    yield engine
    await engine.dispose()


@pytest_asyncio.fixture
async def session(async_engine) -> AsyncSession:
    """Provide test database session."""
    async_session_factory = sessionmaker(
        async_engine,
        class_=AsyncSession,
        expire_on_commit=False,
    )
    async with async_session_factory() as db_session:
        yield db_session


@pytest_asyncio.fixture
async def client(session: AsyncSession) -> AsyncClient:
    """Provide test HTTP client with overridden dependencies."""

    async def override_get_session():
        yield session

    app.dependency_overrides[get_session] = override_get_session

    async with AsyncClient(
        transport=ASGITransport(app=app),
        base_url="http://localhost",
        timeout=30.0,
    ) as test_client:
        yield test_client

    app.dependency_overrides.clear()


@pytest_asyncio.fixture
async def test_user(session: AsyncSession) -> User:
    """Create verified test user."""
    user = User(
        id=uuid4(),
        email="perf_test@example.com",
        hashed_password=hash_password("testpassword123"),
        is_active=True,
        is_verified=True,
    )
    session.add(user)
    await session.commit()
    await session.refresh(user)
    return user


@pytest.fixture
def auth_headers(test_user: User) -> dict[str, str]:
    """Generate auth headers for test user."""
    token = create_access_token(test_user.id)
    return {"Authorization": f"Bearer {token}"}


@pytest_asyncio.fixture
async def test_exercises(session: AsyncSession) -> list[Exercise]:
    """Create multiple test exercises."""
    exercises = []
    for i in range(10):
        exercise = Exercise(
            id=uuid4(),
            name=f"Performance Test Exercise {i}",
            description=f"Test exercise {i} for performance benchmarks",
            category=ExerciseCategory.MOBILITY,
            body_part=BodyPart.KNEE,
            difficulty_level=i % 3 + 1,
        )
        session.add(exercise)
        exercises.append(exercise)
    await session.commit()
    return exercises


def calculate_percentile(data: list[float], percentile: float) -> float:
    """Calculate the given percentile from a list of values."""
    if not data:
        return 0.0
    sorted_data = sorted(data)
    index = (len(sorted_data) - 1) * percentile / 100
    lower = int(index)
    upper = lower + 1
    if upper >= len(sorted_data):
        return sorted_data[-1]
    return sorted_data[lower] + (sorted_data[upper] - sorted_data[lower]) * (
        index - lower
    )


def save_results(test_name: str, data: dict) -> None:
    """Save test results to JSON file."""
    RESULTS_DIR.mkdir(parents=True, exist_ok=True)
    filename = RESULTS_DIR / f"{test_name}_{datetime.now(UTC).strftime('%Y%m%d_%H%M%S')}.json"
    with open(filename, "w", encoding="utf-8") as f:
        json.dump(data, f, indent=2, ensure_ascii=False)
    print(f"\n📊 Results saved to: {filename}")


class TestAPILatencyBenchmarks:
    """API endpoint latency benchmarks for thesis charts."""

    @pytest.mark.asyncio
    async def test_health_endpoint_latency(
        self,
        client: AsyncClient,
    ) -> None:
        """Benchmark health check endpoint latency."""
        latencies: list[float] = []
        num_requests = 100

        for _ in range(num_requests):
            start = time.perf_counter()
            response = await client.get("/api/v1/health")
            end = time.perf_counter()

            latencies.append((end - start) * 1000)
            assert response.status_code == 200

        result = {
            "endpoint": "GET /api/v1/health",
            "requests": num_requests,
            "min_ms": round(min(latencies), 2),
            "max_ms": round(max(latencies), 2),
            "mean_ms": round(statistics.mean(latencies), 2),
            "median_ms": round(statistics.median(latencies), 2),
            "p95_ms": round(calculate_percentile(latencies, 95), 2),
            "p99_ms": round(calculate_percentile(latencies, 99), 2),
            "std_dev_ms": round(statistics.stdev(latencies), 2),
            "all_latencies": [round(l, 2) for l in latencies],
        }

        save_results("health_latency", {
            "timestamp": datetime.now(UTC).isoformat(),
            "result": result,
        })

        assert result["p95_ms"] < 50, f"P95 latency {result['p95_ms']}ms exceeds 50ms"

    @pytest.mark.asyncio
    async def test_exercises_list_latency(
        self,
        client: AsyncClient,
        auth_headers: dict[str, str],
        test_exercises: list[Exercise],
    ) -> None:
        """Benchmark exercise listing endpoint latency."""
        latencies: list[float] = []
        num_requests = 50

        for _ in range(num_requests):
            start = time.perf_counter()
            response = await client.get(
                "/api/v1/exercises",
                headers=auth_headers,
            )
            end = time.perf_counter()

            latencies.append((end - start) * 1000)
            assert response.status_code == 200

        result = {
            "endpoint": "GET /api/v1/exercises",
            "requests": num_requests,
            "min_ms": round(min(latencies), 2),
            "max_ms": round(max(latencies), 2),
            "mean_ms": round(statistics.mean(latencies), 2),
            "median_ms": round(statistics.median(latencies), 2),
            "p95_ms": round(calculate_percentile(latencies, 95), 2),
            "p99_ms": round(calculate_percentile(latencies, 99), 2),
            "std_dev_ms": round(statistics.stdev(latencies), 2) if len(latencies) > 1 else 0,
            "all_latencies": [round(l, 2) for l in latencies],
        }

        save_results("exercises_latency", {
            "timestamp": datetime.now(UTC).isoformat(),
            "result": result,
        })

        assert result["p95_ms"] < 100

    @pytest.mark.asyncio
    async def test_session_creation_latency(
        self,
        client: AsyncClient,
        auth_headers: dict[str, str],
    ) -> None:
        """Benchmark session creation endpoint latency."""
        latencies: list[float] = []
        num_requests = 30

        for _ in range(num_requests):
            start = time.perf_counter()
            response = await client.post(
                "/api/v1/sessions",
                headers=auth_headers,
                json={
                    "scheduled_date": datetime.now(UTC).isoformat(),
                    "notes": "Performance test session",
                },
            )
            end = time.perf_counter()

            latencies.append((end - start) * 1000)
            assert response.status_code == 201

        result = {
            "endpoint": "POST /api/v1/sessions",
            "requests": num_requests,
            "min_ms": round(min(latencies), 2),
            "max_ms": round(max(latencies), 2),
            "mean_ms": round(statistics.mean(latencies), 2),
            "median_ms": round(statistics.median(latencies), 2),
            "p95_ms": round(calculate_percentile(latencies, 95), 2),
            "p99_ms": round(calculate_percentile(latencies, 99), 2),
            "std_dev_ms": round(statistics.stdev(latencies), 2) if len(latencies) > 1 else 0,
            "all_latencies": [round(l, 2) for l in latencies],
        }

        save_results("session_creation_latency", {
            "timestamp": datetime.now(UTC).isoformat(),
            "result": result,
        })

        assert result["p95_ms"] < 200


class TestConcurrentLoadBenchmarks:
    """Concurrent load tests for thesis charts."""

    @pytest.mark.asyncio
    async def test_concurrent_sessions(
        self,
        client: AsyncClient,
        auth_headers: dict[str, str],
    ) -> None:
        """Test concurrent session creation - simulates multiple users."""
        concurrent_levels = [5, 10, 20, 30, 50]
        results: list[dict] = []

        for num_concurrent in concurrent_levels:
            latencies: list[float] = []
            errors = 0

            async def make_request() -> float | None:
                try:
                    start = time.perf_counter()
                    response = await client.post(
                        "/api/v1/sessions",
                        headers=auth_headers,
                        json={
                            "scheduled_date": datetime.now(UTC).isoformat(),
                            "notes": f"Concurrent test {num_concurrent}",
                        },
                    )
                    end = time.perf_counter()
                    if response.status_code == 201:
                        return (end - start) * 1000
                    return None
                except Exception:
                    return None

            start_total = time.perf_counter()
            tasks = [make_request() for _ in range(num_concurrent)]
            task_results = await asyncio.gather(*tasks)
            end_total = time.perf_counter()

            for r in task_results:
                if r is not None:
                    latencies.append(r)
                else:
                    errors += 1

            total_duration = end_total - start_total

            results.append({
                "concurrent_users": num_concurrent,
                "successful": len(latencies),
                "errors": errors,
                "total_duration_ms": round(total_duration * 1000, 2),
                "throughput_rps": round(len(latencies) / total_duration, 2) if total_duration > 0 else 0,
                "mean_latency_ms": round(statistics.mean(latencies), 2) if latencies else 0,
                "p95_latency_ms": round(calculate_percentile(latencies, 95), 2) if latencies else 0,
                "success_rate": round(len(latencies) / num_concurrent * 100, 1),
            })

            await asyncio.sleep(0.5)  # Cool down between levels

        save_results("concurrent_load", {
            "timestamp": datetime.now(UTC).isoformat(),
            "results": results,
        })

        # At least 80% success rate at highest load
        assert results[-1]["success_rate"] >= 80

    @pytest.mark.asyncio
    async def test_sustained_throughput(
        self,
        client: AsyncClient,
    ) -> None:
        """Test sustained throughput over time - for time series chart."""
        duration_seconds = 10
        batch_size = 5
        time_series: list[dict] = []

        start_time = time.perf_counter()

        while (time.perf_counter() - start_time) < duration_seconds:
            batch_start = time.perf_counter()
            elapsed = batch_start - start_time

            batch_latencies = []
            for _ in range(batch_size):
                req_start = time.perf_counter()
                response = await client.get("/api/v1/health")
                req_end = time.perf_counter()
                if response.status_code == 200:
                    batch_latencies.append((req_end - req_start) * 1000)

            batch_end = time.perf_counter()
            batch_duration = batch_end - batch_start

            time_series.append({
                "time_seconds": round(elapsed, 2),
                "requests": len(batch_latencies),
                "mean_latency_ms": round(statistics.mean(batch_latencies), 2) if batch_latencies else 0,
                "throughput_rps": round(len(batch_latencies) / batch_duration, 2) if batch_duration > 0 else 0,
            })

            await asyncio.sleep(0.2)

        save_results("sustained_throughput", {
            "timestamp": datetime.now(UTC).isoformat(),
            "duration_seconds": duration_seconds,
            "total_requests": sum(ts["requests"] for ts in time_series),
            "time_series": time_series,
        })


class TestEndpointComparison:
    """Compare different endpoint performance for bar charts."""

    @pytest.mark.asyncio
    async def test_all_endpoints_comparison(
        self,
        client: AsyncClient,
        auth_headers: dict[str, str],
        session: AsyncSession,
        test_exercises: list[Exercise],
    ) -> None:
        """Compare latency across all major endpoints."""
        num_requests = 20
        endpoints_results: list[dict] = []

        # Test endpoints configuration
        endpoints = [
            {"name": "Health Check", "method": "GET", "path": "/api/v1/health", "auth": False},
            {"name": "List Exercises", "method": "GET", "path": "/api/v1/exercises", "auth": True},
            {"name": "Create Session", "method": "POST", "path": "/api/v1/sessions",
             "auth": True, "json": {"scheduled_date": datetime.now(UTC).isoformat()}},
        ]

        for endpoint in endpoints:
            latencies = []

            for _ in range(num_requests):
                headers = auth_headers if endpoint.get("auth") else {}
                start = time.perf_counter()

                if endpoint["method"] == "GET":
                    response = await client.get(endpoint["path"], headers=headers)
                else:
                    response = await client.post(
                        endpoint["path"],
                        headers=headers,
                        json=endpoint.get("json", {}),
                    )

                end = time.perf_counter()

                if response.status_code in [200, 201]:
                    latencies.append((end - start) * 1000)

            if latencies:
                endpoints_results.append({
                    "name": endpoint["name"],
                    "method": endpoint["method"],
                    "path": endpoint["path"],
                    "requests": len(latencies),
                    "mean_ms": round(statistics.mean(latencies), 2),
                    "median_ms": round(statistics.median(latencies), 2),
                    "p95_ms": round(calculate_percentile(latencies, 95), 2),
                    "min_ms": round(min(latencies), 2),
                    "max_ms": round(max(latencies), 2),
                })

        save_results("endpoints_comparison", {
            "timestamp": datetime.now(UTC).isoformat(),
            "results": endpoints_results,
        })
