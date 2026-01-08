import httpx
import pytest

BASE_URL = "http://localhost:8000"
API_PREFIX = "/api/v1"
TEST_USER = "testuser@example.com"
TEST_PASSWORD = "testpassword123"


@pytest.fixture(scope="function")
async def access_token():
    async with httpx.AsyncClient(base_url=BASE_URL) as client:
        register_data = {
            "email": TEST_USER,
            "password": TEST_PASSWORD,
            "is_active": True,
            "is_superuser": False,
            "is_verified": False,
        }

        reg_response = await client.post(
            f"{API_PREFIX}/auth/register", json=register_data
        )
        if reg_response.status_code not in [201, 400]:
            pytest.fail(f"Registration failed: {reg_response.text}")

        login_data = {
            "username": TEST_USER,
            "password": TEST_PASSWORD,
        }

        response = await client.post(
            f"{API_PREFIX}/auth/login",
            data=login_data,
            headers={"Content-Type": "application/x-www-form-urlencoded"},
        )

        assert response.status_code == 200, f"Login failed: {response.text}"

        return response.json()["access_token"]


@pytest.mark.asyncio
async def test_analysis_endpoints(access_token):
    endpoints = [
        {"path": "/analysis/exercises", "method": "GET", "auth": False},
        {"path": "/analysis/realtime/status", "method": "GET", "auth": False},
        {"path": "/analysis/video", "method": "POST", "auth": True},
        {"path": "/analysis/landmarks", "method": "POST", "auth": True},
    ]

    headers = {"Authorization": f"Bearer {access_token}"}

    async with httpx.AsyncClient(base_url=f"{BASE_URL}{API_PREFIX}") as client:
        for endpoint in endpoints:
            method = endpoint["method"].lower()
            request_headers = headers if endpoint["auth"] else {}

            request_kwargs = {"headers": request_headers}

            if method == "post":
                request_kwargs["json"] = {}

            response = await getattr(client, method)(endpoint["path"], **request_kwargs)

            allowed_statuses = [200, 201, 400, 422]
            if not endpoint["auth"]:
                allowed_statuses.append(401)

            assert response.status_code in allowed_statuses, (
                f"Issue with endpoint {endpoint['path']}. "
                f"Method: {endpoint['method'].upper()}. "
                f"Status: {response.status_code}. "
                f"Response: {response.text[:200]}"
            )
