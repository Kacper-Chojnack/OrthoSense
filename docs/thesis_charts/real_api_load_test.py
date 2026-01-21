#!/usr/bin/env python3
"""
OrthoSense - Real AWS API Performance Tester

This script performs load testing against the live AWS API endpoint
and collects real performance metrics for thesis documentation.

Features:
- Measures real latency to AWS App Runner
- Tests concurrent user scenarios
- Collects p50, p95, p99 percentiles
- Generates JSON reports for chart generation

Usage:
    # First, set your API URL
    export ORTHOSENSE_API_URL="https://your-app.awsapprunner.com"
    
    # Or for local testing
    export ORTHOSENSE_API_URL="http://localhost:8000"
    
    # Run the tests
    cd backend
    pip install httpx asyncio
    python scripts/real_api_load_test.py

Results saved to: backend/.benchmarks/real_api_results_TIMESTAMP.json
"""

import asyncio
import json
import os
import statistics
import sys
import time
from dataclasses import dataclass, asdict
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

try:
    import httpx
except ImportError:
    print("Installing httpx...")
    os.system(f"{sys.executable} -m pip install httpx")
    import httpx


# Configuration
API_URL = os.environ.get("ORTHOSENSE_API_URL", "http://localhost:8000")
OUTPUT_DIR = Path(__file__).parent.parent / ".benchmarks"


@dataclass
class TestResult:
    """Single test result."""
    endpoint: str
    method: str
    status_code: int
    latency_ms: float
    success: bool
    timestamp: str
    error: str | None = None


@dataclass
class EndpointStats:
    """Statistics for an endpoint."""
    endpoint: str
    method: str
    total_requests: int
    successful: int
    failed: int
    min_ms: float
    max_ms: float
    mean_ms: float
    median_ms: float
    p95_ms: float
    p99_ms: float
    std_dev_ms: float
    success_rate: float
    throughput_rps: float


def calculate_percentile(data: list[float], percentile: float) -> float:
    """Calculate percentile from sorted data."""
    if not data:
        return 0.0
    sorted_data = sorted(data)
    index = (len(sorted_data) - 1) * percentile / 100
    lower = int(index)
    upper = lower + 1
    if upper >= len(sorted_data):
        return sorted_data[-1]
    return sorted_data[lower] + (sorted_data[upper] - sorted_data[lower]) * (index - lower)


def calculate_stats(results: list[TestResult], total_time: float) -> EndpointStats | None:
    """Calculate statistics from test results."""
    if not results:
        return None
    
    successful_latencies = [r.latency_ms for r in results if r.success]
    failed_count = sum(1 for r in results if not r.success)
    
    if not successful_latencies:
        return None
    
    return EndpointStats(
        endpoint=results[0].endpoint,
        method=results[0].method,
        total_requests=len(results),
        successful=len(successful_latencies),
        failed=failed_count,
        min_ms=round(min(successful_latencies), 2),
        max_ms=round(max(successful_latencies), 2),
        mean_ms=round(statistics.mean(successful_latencies), 2),
        median_ms=round(statistics.median(successful_latencies), 2),
        p95_ms=round(calculate_percentile(successful_latencies, 95), 2),
        p99_ms=round(calculate_percentile(successful_latencies, 99), 2),
        std_dev_ms=round(statistics.stdev(successful_latencies), 2) if len(successful_latencies) > 1 else 0,
        success_rate=round(len(successful_latencies) / len(results) * 100, 2),
        throughput_rps=round(len(successful_latencies) / total_time, 2) if total_time > 0 else 0,
    )


class RealAPITester:
    """Tests the real AWS API endpoint."""
    
    def __init__(self, base_url: str):
        self.base_url = base_url.rstrip("/")
        self.results: list[dict[str, Any]] = []
        self.auth_token: str | None = None
        
    async def _make_request(
        self,
        client: httpx.AsyncClient,
        method: str,
        path: str,
        **kwargs
    ) -> TestResult:
        """Make a single request and measure latency."""
        url = f"{self.base_url}{path}"
        start = time.perf_counter()
        
        try:
            if method.upper() == "GET":
                response = await client.get(url, **kwargs)
            elif method.upper() == "POST":
                response = await client.post(url, **kwargs)
            else:
                response = await client.request(method, url, **kwargs)
            
            end = time.perf_counter()
            latency_ms = (end - start) * 1000
            
            return TestResult(
                endpoint=path,
                method=method.upper(),
                status_code=response.status_code,
                latency_ms=round(latency_ms, 2),
                success=200 <= response.status_code < 300,
                timestamp=datetime.now(timezone.utc).isoformat(),
            )
        except Exception as e:
            end = time.perf_counter()
            return TestResult(
                endpoint=path,
                method=method.upper(),
                status_code=0,
                latency_ms=round((end - start) * 1000, 2),
                success=False,
                timestamp=datetime.now(timezone.utc).isoformat(),
                error=str(e),
            )

    async def test_health_endpoint(self, num_requests: int = 100) -> EndpointStats | None:
        """Test health endpoint latency."""
        print(f"\n📊 Testing health endpoint ({num_requests} requests)...")
        
        results: list[TestResult] = []
        start_time = time.perf_counter()
        
        async with httpx.AsyncClient(timeout=30.0) as client:
            for i in range(num_requests):
                result = await self._make_request(client, "GET", "/health")
                results.append(result)
                
                if (i + 1) % 20 == 0:
                    print(f"  Progress: {i + 1}/{num_requests}")
        
        total_time = time.perf_counter() - start_time
        stats = calculate_stats(results, total_time)
        
        if stats:
            print(f"  ✓ Mean: {stats.mean_ms}ms, P95: {stats.p95_ms}ms, P99: {stats.p99_ms}ms")
            self.results.append({
                "test_name": "health_endpoint",
                "stats": asdict(stats),
                "raw_latencies": [r.latency_ms for r in results if r.success],
            })
        
        return stats

    async def test_concurrent_requests(
        self,
        concurrent_levels: list[int] = [5, 10, 20, 30, 50]
    ) -> list[dict]:
        """Test concurrent request handling."""
        print(f"\n📊 Testing concurrent requests: {concurrent_levels}")
        
        concurrent_results: list[dict] = []
        
        for level in concurrent_levels:
            print(f"\n  Testing {level} concurrent requests...")
            
            async with httpx.AsyncClient(timeout=30.0) as client:
                start_time = time.perf_counter()
                
                tasks = [
                    self._make_request(client, "GET", "/health")
                    for _ in range(level)
                ]
                
                results = await asyncio.gather(*tasks)
                total_time = time.perf_counter() - start_time
            
            successful = [r for r in results if r.success]
            latencies = [r.latency_ms for r in successful]
            
            result = {
                "concurrent_users": level,
                "successful": len(successful),
                "failed": level - len(successful),
                "success_rate": round(len(successful) / level * 100, 1),
                "total_time_ms": round(total_time * 1000, 2),
                "throughput_rps": round(len(successful) / total_time, 2) if total_time > 0 else 0,
                "mean_latency_ms": round(statistics.mean(latencies), 2) if latencies else 0,
                "p95_latency_ms": round(calculate_percentile(latencies, 95), 2) if latencies else 0,
            }
            
            concurrent_results.append(result)
            print(f"    ✓ Success: {result['success_rate']}%, Throughput: {result['throughput_rps']} rps")
            
            # Cool down between tests
            await asyncio.sleep(1)
        
        self.results.append({
            "test_name": "concurrent_load",
            "results": concurrent_results,
        })
        
        return concurrent_results

    async def test_sustained_load(self, duration_seconds: int = 30) -> dict:
        """Test sustained load over time."""
        print(f"\n📊 Testing sustained load for {duration_seconds} seconds...")
        
        time_series: list[dict] = []
        
        async with httpx.AsyncClient(timeout=30.0) as client:
            start_time = time.perf_counter()
            interval = 1.0  # Measure every second
            
            while (time.perf_counter() - start_time) < duration_seconds:
                interval_start = time.perf_counter()
                elapsed = interval_start - start_time
                
                # Make batch of requests
                batch_size = 10
                tasks = [
                    self._make_request(client, "GET", "/health")
                    for _ in range(batch_size)
                ]
                
                results = await asyncio.gather(*tasks)
                interval_end = time.perf_counter()
                
                successful = [r for r in results if r.success]
                latencies = [r.latency_ms for r in successful]
                
                time_series.append({
                    "time_seconds": round(elapsed, 2),
                    "requests": len(successful),
                    "mean_latency_ms": round(statistics.mean(latencies), 2) if latencies else 0,
                    "throughput_rps": round(len(successful) / (interval_end - interval_start), 2),
                })
                
                # Progress
                if int(elapsed) % 5 == 0 and int(elapsed) > 0:
                    print(f"  Progress: {int(elapsed)}/{duration_seconds}s")
                
                # Wait for next interval
                sleep_time = interval - (time.perf_counter() - interval_start)
                if sleep_time > 0:
                    await asyncio.sleep(sleep_time)
        
        total_requests = sum(ts["requests"] for ts in time_series)
        avg_throughput = statistics.mean(ts["throughput_rps"] for ts in time_series)
        avg_latency = statistics.mean(ts["mean_latency_ms"] for ts in time_series)
        
        result = {
            "test_name": "sustained_load",
            "duration_seconds": duration_seconds,
            "total_requests": total_requests,
            "avg_throughput_rps": round(avg_throughput, 2),
            "avg_latency_ms": round(avg_latency, 2),
            "time_series": time_series,
        }
        
        print(f"  ✓ Total: {total_requests} requests, Avg throughput: {avg_throughput:.1f} rps")
        
        self.results.append(result)
        return result

    async def test_authenticated_endpoints(self, email: str, password: str) -> dict | None:
        """Test authenticated API endpoints with real business logic."""
        print(f"\n📊 Testing authenticated endpoints...")
        
        async with httpx.AsyncClient(timeout=30.0) as client:
            # Login
            print("  Logging in...")
            response = await client.post(
                f"{self.base_url}/api/v1/auth/login",
                data={"username": email, "password": password}
            )
            
            if response.status_code != 200:
                print(f"  ✗ Login failed: {response.status_code} - {response.text}")
                return None
            
            token_data = response.json()
            token = token_data.get("access_token")
            
            if not token:
                print("  ✗ No token in response")
                return None
            
            print("  ✓ Login successful")
            headers = {"Authorization": f"Bearer {token}"}
            
            # Test authenticated endpoints - real business logic
            endpoints = [
                ("GET", "/api/v1/exercises", "Lista ćwiczeń"),
                ("GET", "/api/v1/sessions", "Historia sesji"),
                ("GET", "/api/v1/auth/me", "Profil użytkownika"),
            ]
            
            auth_results: list[dict] = []
            
            for method, path, name in endpoints:
                print(f"  Testing {name} ({method} {path})...")
                latencies: list[float] = []
                
                for _ in range(50):  # 50 requests per endpoint
                    result = await self._make_request(
                        client, method, path, headers=headers
                    )
                    if result.success:
                        latencies.append(result.latency_ms)
                
                if latencies:
                    auth_results.append({
                        "endpoint": path,
                        "name": name,
                        "method": method,
                        "requests": len(latencies),
                        "mean_ms": round(statistics.mean(latencies), 2),
                        "median_ms": round(statistics.median(latencies), 2),
                        "p95_ms": round(calculate_percentile(latencies, 95), 2),
                        "p99_ms": round(calculate_percentile(latencies, 99), 2),
                        "min_ms": round(min(latencies), 2),
                        "max_ms": round(max(latencies), 2),
                        "raw_latencies": latencies,
                    })
                    print(f"    ✓ Mean: {auth_results[-1]['mean_ms']}ms, P95: {auth_results[-1]['p95_ms']}ms")
            
            self.results.append({
                "test_name": "authenticated_endpoints",
                "results": auth_results,
            })
            
            return {"results": auth_results}

    def save_results(self) -> Path:
        """Save all results to JSON file."""
        OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
        
        timestamp = datetime.now(timezone.utc).strftime("%Y%m%d_%H%M%S")
        filename = OUTPUT_DIR / f"real_api_results_{timestamp}.json"
        
        report = {
            "timestamp": datetime.now(timezone.utc).isoformat(),
            "api_url": self.base_url,
            "tests": self.results,
        }
        
        with open(filename, "w", encoding="utf-8") as f:
            json.dump(report, f, indent=2, ensure_ascii=False)
        
        print(f"\n💾 Results saved to: {filename}")
        return filename


async def main():
    """Main entry point."""
    print("=" * 60)
    print("OrthoSense - Real AWS API Performance Tester")
    print("=" * 60)
    print(f"Target API: {API_URL}")
    print("-" * 60)
    
    # Check if API is reachable
    try:
        async with httpx.AsyncClient(timeout=10.0) as client:
            response = await client.get(f"{API_URL}/health")
            if response.status_code != 200:
                print(f"⚠️  API returned status {response.status_code}")
            else:
                print("✓ API is reachable")
    except Exception as e:
        print(f"✗ Cannot reach API: {e}")
        print("\nMake sure to set ORTHOSENSE_API_URL environment variable:")
        print('  export ORTHOSENSE_API_URL="https://your-app.awsapprunner.com"')
        return
    
    tester = RealAPITester(API_URL)
    
    # Run tests
    await tester.test_health_endpoint(num_requests=100)
    await tester.test_concurrent_requests([5, 10, 20, 30, 50])
    await tester.test_sustained_load(duration_seconds=30)
    
    # Test authenticated endpoints with real business logic
    await tester.test_authenticated_endpoints(
        email="loadtest.thesis2026@gmail.com",
        password="LoadTest123!"
    )
    
    # Save results
    output_file = tester.save_results()
    
    print("\n" + "=" * 60)
    print("✓ All tests completed!")
    print(f"Results saved to: {output_file}")
    print("\nTo generate charts, run:")
    print("  python docs/thesis_charts/generate_charts.py")
    print("=" * 60)


if __name__ == "__main__":
    asyncio.run(main())
