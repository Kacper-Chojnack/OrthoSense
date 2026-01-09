"""E2E tests for Analysis Pipeline.

Tests the complete flow:
1. Submit landmarks → Pose Analysis → Diagnostics → Report
2. Edge cases and error handling
3. Different exercise types
"""

import os
from uuid import uuid4

# Set environment variables BEFORE importing app modules
os.environ["SECRET_KEY"] = "test_secret_key_for_e2e_analysis_pipeline"
os.environ["DATABASE_URL"] = "sqlite+aiosqlite:///:memory:"
os.environ["RATE_LIMIT_ENABLED"] = "false"

import pytest
import pytest_asyncio
from httpx import ASGITransport, AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession, create_async_engine
from sqlalchemy.orm import sessionmaker
from sqlmodel import SQLModel

from app.core.database import get_session
from app.core.security import create_access_token, hash_password
from app.main import app
from app.models.user import User


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
    async with async_session_factory() as session:
        yield session


@pytest_asyncio.fixture
async def client(session: AsyncSession) -> AsyncClient:
    """Provide test HTTP client with overridden dependencies."""

    async def override_get_session():
        yield session

    app.dependency_overrides[get_session] = override_get_session

    async with AsyncClient(
        transport=ASGITransport(app=app),
        base_url="http://localhost",
    ) as client:
        yield client

    app.dependency_overrides.clear()


@pytest_asyncio.fixture
async def test_user(session: AsyncSession) -> User:
    """Create verified test user."""
    user = User(
        id=uuid4(),
        email="analysis_test@example.com",
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


def _create_valid_landmarks(num_frames: int = 30) -> list[list[list[float]]]:
    """Create valid landmark data for testing."""
    # 33 landmarks per frame, each with x, y, z, visibility
    landmarks = []
    for frame_idx in range(num_frames):
        frame = []
        for joint_idx in range(33):
            # Create realistic-ish coordinates
            x = 0.5 + (joint_idx % 10) * 0.05
            y = 0.3 + (joint_idx // 10) * 0.2
            z = 0.0 + (frame_idx * 0.01)
            visibility = 0.95
            frame.append([x, y, z, visibility])
        landmarks.append(frame)
    return landmarks


def _create_squat_landmarks() -> list[list[list[float]]]:
    """Create landmarks simulating a deep squat movement."""
    landmarks = []
    # Simulate descent and ascent phases
    for phase in range(20):
        frame = [[0.5, 0.5, 0.0, 0.95] for _ in range(33)]

        # Key joints for squat analysis
        # Shoulders (11, 12)
        frame[11] = [0.4, 0.3, 0.0, 0.95]
        frame[12] = [0.6, 0.3, 0.0, 0.95]

        # Hips (23, 24) - descend and ascend
        hip_y = 0.5 + (0.15 if phase < 10 else 0.15 - ((phase - 10) * 0.015))
        frame[23] = [0.45, hip_y, 0.0, 0.95]
        frame[24] = [0.55, hip_y, 0.0, 0.95]

        # Knees (25, 26)
        knee_y = 0.65
        frame[25] = [0.45, knee_y, 0.0, 0.95]
        frame[26] = [0.55, knee_y, 0.0, 0.95]

        # Ankles (27, 28)
        frame[27] = [0.45, 0.85, 0.0, 0.95]
        frame[28] = [0.55, 0.85, 0.0, 0.95]

        # Heels (29, 30)
        frame[29] = [0.43, 0.88, 0.0, 0.95]
        frame[30] = [0.57, 0.88, 0.0, 0.95]

        # Foot index (31, 32)
        frame[31] = [0.47, 0.88, 0.0, 0.95]
        frame[32] = [0.53, 0.88, 0.0, 0.95]

        landmarks.append(frame)

    return landmarks


class TestAnalysisPipelineE2E:
    """E2E tests for the full analysis pipeline."""

    @pytest.mark.asyncio
    async def test_list_available_exercises(self, client: AsyncClient) -> None:
        """Test listing available exercises for analysis."""
        response = await client.get("/api/v1/analysis/exercises")

        assert response.status_code == 200
        data = response.json()
        assert "exercises" in data
        assert "ai_available" in data
        assert data["ai_available"] is True
        assert len(data["exercises"]) > 0

    @pytest.mark.asyncio
    async def test_analyze_landmarks_deep_squat(self, client: AsyncClient) -> None:
        """Test full analysis pipeline for Deep Squat."""
        landmarks = _create_squat_landmarks()

        response = await client.post(
            "/api/v1/analysis/landmarks",
            json={
                "landmarks": landmarks,
                "exercise_name": "Deep Squat",
            },
        )

        assert response.status_code == 200
        data = response.json()

        # Verify response structure
        assert "exercise" in data or "is_correct" in data
        if "exercise" in data:
            assert data["exercise"] == "Deep Squat"

    @pytest.mark.asyncio
    async def test_analyze_landmarks_shoulder_abduction(
        self, client: AsyncClient
    ) -> None:
        """Test analysis for Standing Shoulder Abduction."""
        landmarks = _create_valid_landmarks(25)

        response = await client.post(
            "/api/v1/analysis/landmarks",
            json={
                "landmarks": landmarks,
                "exercise_name": "Standing Shoulder Abduction",
            },
        )

        assert response.status_code == 200
        data = response.json()
        assert isinstance(data, dict)

    @pytest.mark.asyncio
    async def test_analyze_landmarks_hurdle_step(self, client: AsyncClient) -> None:
        """Test analysis for Hurdle Step."""
        landmarks = _create_valid_landmarks(20)

        response = await client.post(
            "/api/v1/analysis/landmarks",
            json={
                "landmarks": landmarks,
                "exercise_name": "Hurdle Step",
            },
        )

        assert response.status_code == 200

    @pytest.mark.asyncio
    async def test_analyze_landmarks_empty_returns_error(
        self, client: AsyncClient
    ) -> None:
        """Test that empty landmarks returns 400 error."""
        response = await client.post(
            "/api/v1/analysis/landmarks",
            json={
                "landmarks": [],
                "exercise_name": "Deep Squat",
            },
        )

        assert response.status_code == 400
        assert "No landmarks" in response.json()["detail"]

    @pytest.mark.asyncio
    async def test_analyze_landmarks_invalid_frame_format(
        self, client: AsyncClient
    ) -> None:
        """Test that invalid frame format returns 400 error."""
        # Only 10 joints instead of 33
        invalid_landmarks = [[[0.5, 0.5, 0.0] for _ in range(10)] for _ in range(5)]

        response = await client.post(
            "/api/v1/analysis/landmarks",
            json={
                "landmarks": invalid_landmarks,
                "exercise_name": "Deep Squat",
            },
        )

        assert response.status_code == 400
        assert "expected 33" in response.json()["detail"]

    @pytest.mark.asyncio
    async def test_analyze_landmarks_invalid_joint_format(
        self, client: AsyncClient
    ) -> None:
        """Test that invalid joint format returns 400 error."""
        # 2D coordinates instead of 3D
        invalid_landmarks = [[[0.5, 0.5] for _ in range(33)] for _ in range(5)]

        response = await client.post(
            "/api/v1/analysis/landmarks",
            json={
                "landmarks": invalid_landmarks,
                "exercise_name": "Deep Squat",
            },
        )

        assert response.status_code == 400
        assert "joint format invalid" in response.json()["detail"]


class TestAnalysisPipelineWithAuth:
    """Tests for analysis pipeline with authentication."""

    @pytest.mark.asyncio
    async def test_analysis_works_without_auth(self, client: AsyncClient) -> None:
        """Analysis endpoint doesn't require authentication (public API)."""
        landmarks = _create_valid_landmarks(10)

        response = await client.post(
            "/api/v1/analysis/landmarks",
            json={
                "landmarks": landmarks,
                "exercise_name": "Deep Squat",
            },
        )

        # Should work without auth
        assert response.status_code == 200

    @pytest.mark.asyncio
    async def test_exercises_list_works_without_auth(self, client: AsyncClient) -> None:
        """Exercise list endpoint doesn't require authentication."""
        response = await client.get("/api/v1/analysis/exercises")

        assert response.status_code == 200


class TestAnalysisPipelinePerformance:
    """Performance-related tests for analysis pipeline."""

    @pytest.mark.asyncio
    async def test_analyze_large_landmark_set(self, client: AsyncClient) -> None:
        """Test analysis with large number of frames."""
        # 100 frames (about 3+ seconds of video at 30fps)
        landmarks = _create_valid_landmarks(100)

        response = await client.post(
            "/api/v1/analysis/landmarks",
            json={
                "landmarks": landmarks,
                "exercise_name": "Deep Squat",
            },
        )

        assert response.status_code == 200

    @pytest.mark.asyncio
    async def test_analyze_minimal_frames(self, client: AsyncClient) -> None:
        """Test analysis with minimal frames."""
        # Just 5 frames
        landmarks = _create_valid_landmarks(5)

        response = await client.post(
            "/api/v1/analysis/landmarks",
            json={
                "landmarks": landmarks,
                "exercise_name": "Deep Squat",
            },
        )

        assert response.status_code == 200


class TestAnalysisPipelineEdgeCases:
    """Edge case tests for analysis pipeline."""

    @pytest.mark.asyncio
    async def test_unknown_exercise_name(self, client: AsyncClient) -> None:
        """Test analysis with unknown exercise name."""
        landmarks = _create_valid_landmarks(10)

        response = await client.post(
            "/api/v1/analysis/landmarks",
            json={
                "landmarks": landmarks,
                "exercise_name": "Unknown Exercise Type",
            },
        )

        # Should handle gracefully
        assert response.status_code == 200
        data = response.json()
        assert isinstance(data, dict)

    @pytest.mark.asyncio
    async def test_landmarks_with_low_visibility(self, client: AsyncClient) -> None:
        """Test analysis with low visibility landmarks."""
        landmarks = []
        for _ in range(10):
            frame = []
            for j in range(33):
                # Low visibility for most joints
                visibility = 0.3 if j not in [11, 12, 23, 24, 25, 26, 27, 28] else 0.95
                frame.append([0.5, 0.5, 0.0, visibility])
            landmarks.append(frame)

        response = await client.post(
            "/api/v1/analysis/landmarks",
            json={
                "landmarks": landmarks,
                "exercise_name": "Deep Squat",
            },
        )

        # Should handle gracefully
        assert response.status_code in [200, 400]

    @pytest.mark.asyncio
    async def test_landmarks_without_visibility(self, client: AsyncClient) -> None:
        """Test analysis with 3D-only landmarks (no visibility)."""
        # Only x, y, z - no visibility flag
        landmarks = [[[0.5, 0.5, 0.0] for _ in range(33)] for _ in range(10)]

        response = await client.post(
            "/api/v1/analysis/landmarks",
            json={
                "landmarks": landmarks,
                "exercise_name": "Deep Squat",
            },
        )

        assert response.status_code == 200
