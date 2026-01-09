"""
Integration tests for Exercise API with Videos.

Test coverage:
1. Create exercise with video
2. List exercises with videos
3. Exercise-video relationship integrity
4. Full CRUD workflow
"""

from uuid import uuid4

import pytest
from httpx import AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.security import create_access_token, hash_password
from app.models.exercise import BodyPart, Exercise, ExerciseCategory
from app.models.exercise_video import ExerciseVideo
from app.models.user import User, UserRole


@pytest.fixture
async def admin_user(session: AsyncSession) -> User:
    """Create an admin user."""
    admin = User(
        id=uuid4(),
        email="admin@example.com",
        hashed_password=hash_password("adminpassword123"),
        role=UserRole.ADMIN,
        is_active=True,
        is_verified=True,
    )
    session.add(admin)
    await session.commit()
    await session.refresh(admin)
    return admin


@pytest.fixture
def admin_headers(admin_user: User) -> dict[str, str]:
    """Auth headers for admin user."""
    token = create_access_token(admin_user.id)
    return {"Authorization": f"Bearer {token}"}


class TestExerciseVideoIntegration:
    """Integration tests for exercise-video relationship."""

    @pytest.mark.asyncio
    async def test_create_exercise_then_add_videos(
        self,
        client: AsyncClient,
        session: AsyncSession,
        admin_headers: dict[str, str],
        auth_headers: dict[str, str],
    ) -> None:
        """Create exercise as admin, then add videos."""
        # Step 1: Create exercise (admin only)
        exercise_response = await client.post(
            "/api/v1/exercises",
            headers=admin_headers,
            json={
                "name": "Shoulder Press",
                "description": "Overhead pressing movement",
                "instructions": "Press weight overhead with control",
                "category": "strength",
                "body_part": "shoulder",
                "difficulty_level": 3,
            },
        )

        assert exercise_response.status_code == 201
        exercise_data = exercise_response.json()
        exercise_id = exercise_data["id"]

        # Step 2: Add primary video
        video1_response = await client.post(
            "/api/v1/exercise-videos",
            headers=auth_headers,
            json={
                "exercise_id": exercise_id,
                "title": "Shoulder Press - Front View",
                "description": "Primary demonstration from the front",
                "video_url": "https://cdn.example.com/shoulder-press-front.mp4",
                "thumbnail_url": "https://cdn.example.com/thumb-front.jpg",
                "duration_seconds": 90,
                "view_angle": "front",
                "is_primary": True,
                "sort_order": 0,
            },
        )

        assert video1_response.status_code == 201
        video1_data = video1_response.json()
        assert video1_data["is_primary"] is True

        # Step 3: Add secondary video
        video2_response = await client.post(
            "/api/v1/exercise-videos",
            headers=auth_headers,
            json={
                "exercise_id": exercise_id,
                "title": "Shoulder Press - Side View",
                "description": "Alternative view from the side",
                "video_url": "https://cdn.example.com/shoulder-press-side.mp4",
                "duration_seconds": 90,
                "view_angle": "side",
                "is_primary": False,
                "sort_order": 1,
            },
        )

        assert video2_response.status_code == 201

        # Step 4: List videos for exercise
        list_response = await client.get(
            f"/api/v1/exercise-videos/exercise/{exercise_id}",
            headers=auth_headers,
        )

        assert list_response.status_code == 200
        videos = list_response.json()
        assert len(videos) == 2
        # Primary should be first
        assert videos[0]["is_primary"] is True

    @pytest.mark.asyncio
    async def test_get_primary_video_for_exercise(
        self,
        client: AsyncClient,
        session: AsyncSession,
        auth_headers: dict[str, str],
    ) -> None:
        """Get primary video endpoint returns correct video."""
        # Create exercise
        exercise = Exercise(
            id=uuid4(),
            name="Bicep Curl",
            category=ExerciseCategory.STRENGTH,
            body_part=BodyPart.ELBOW,
            is_active=True,
        )
        session.add(exercise)

        # Create videos
        primary_video = ExerciseVideo(
            exercise_id=exercise.id,
            title="Primary Bicep Demo",
            video_url="https://example.com/primary.mp4",
            duration_seconds=60,
            is_primary=True,
            sort_order=0,
            is_active=True,
        )
        secondary_video = ExerciseVideo(
            exercise_id=exercise.id,
            title="Secondary View",
            video_url="https://example.com/secondary.mp4",
            duration_seconds=60,
            is_primary=False,
            sort_order=1,
            is_active=True,
        )
        session.add(primary_video)
        session.add(secondary_video)
        await session.commit()

        # Get primary video
        response = await client.get(
            f"/api/v1/exercise-videos/exercise/{exercise.id}/primary",
            headers=auth_headers,
        )

        assert response.status_code == 200
        data = response.json()
        assert data["title"] == "Primary Bicep Demo"
        assert data["is_primary"] is True

    @pytest.mark.asyncio
    async def test_soft_delete_video_excludes_from_list(
        self,
        client: AsyncClient,
        session: AsyncSession,
        auth_headers: dict[str, str],
    ) -> None:
        """Soft-deleted videos are excluded from listing."""
        # Create exercise
        exercise = Exercise(
            id=uuid4(),
            name="Leg Raise",
            category=ExerciseCategory.STRENGTH,
            body_part=BodyPart.HIP,
            is_active=True,
        )
        session.add(exercise)

        # Create videos
        video1 = ExerciseVideo(
            id=uuid4(),
            exercise_id=exercise.id,
            title="Active Video",
            video_url="https://example.com/active.mp4",
            duration_seconds=60,
            is_active=True,
        )
        video2 = ExerciseVideo(
            id=uuid4(),
            exercise_id=exercise.id,
            title="Inactive Video",
            video_url="https://example.com/inactive.mp4",
            duration_seconds=60,
            is_active=True,
        )
        session.add(video1)
        session.add(video2)
        await session.commit()

        # Delete video2
        delete_response = await client.delete(
            f"/api/v1/exercise-videos/{video2.id}",
            headers=auth_headers,
        )
        assert delete_response.status_code == 204

        # List videos - should only show active
        list_response = await client.get(
            f"/api/v1/exercise-videos/exercise/{exercise.id}",
            headers=auth_headers,
        )

        assert list_response.status_code == 200
        videos = list_response.json()
        assert len(videos) == 1
        assert videos[0]["title"] == "Active Video"


class TestExerciseFilteringWithVideos:
    """Test exercise filtering when videos are attached."""

    @pytest.mark.asyncio
    async def test_list_exercises_with_various_filters(
        self,
        client: AsyncClient,
        session: AsyncSession,
        auth_headers: dict[str, str],
    ) -> None:
        """Exercises can be filtered while having videos."""
        # Create exercises with different attributes
        exercises = [
            Exercise(
                id=uuid4(),
                name="Knee Bend",
                category=ExerciseCategory.MOBILITY,
                body_part=BodyPart.KNEE,
                difficulty_level=1,
                is_active=True,
            ),
            Exercise(
                id=uuid4(),
                name="Hip Flexor Stretch",
                category=ExerciseCategory.STRETCHING,
                body_part=BodyPart.HIP,
                difficulty_level=2,
                is_active=True,
            ),
            Exercise(
                id=uuid4(),
                name="Shoulder Rotation",
                category=ExerciseCategory.MOBILITY,
                body_part=BodyPart.SHOULDER,
                difficulty_level=1,
                is_active=True,
            ),
        ]

        for ex in exercises:
            session.add(ex)
            # Add a video to each
            video = ExerciseVideo(
                exercise_id=ex.id,
                title=f"Demo for {ex.name}",
                video_url="https://example.com/video.mp4",
                duration_seconds=60,
                is_active=True,
            )
            session.add(video)

        await session.commit()

        # Filter by category
        response = await client.get(
            "/api/v1/exercises",
            headers=auth_headers,
            params={"category": "mobility"},
        )

        assert response.status_code == 200
        data = response.json()
        assert len(data) == 2
        names = [ex["name"] for ex in data]
        assert "Knee Bend" in names
        assert "Shoulder Rotation" in names

        # Filter by body_part
        response = await client.get(
            "/api/v1/exercises",
            headers=auth_headers,
            params={"body_part": "hip"},
        )

        assert response.status_code == 200
        data = response.json()
        assert len(data) == 1
        assert data[0]["name"] == "Hip Flexor Stretch"


class TestAdminOnlyOperations:
    """Test that admin-only operations are restricted."""

    @pytest.mark.asyncio
    async def test_non_admin_cannot_create_exercise(
        self,
        client: AsyncClient,
        auth_headers: dict[str, str],  # Regular user
    ) -> None:
        """Regular users cannot create exercises."""
        response = await client.post(
            "/api/v1/exercises",
            headers=auth_headers,
            json={
                "name": "Unauthorized Exercise",
                "category": "mobility",
                "body_part": "knee",
                "difficulty_level": 1,
            },
        )

        # Should be 403 Forbidden
        assert response.status_code == 403

    @pytest.mark.asyncio
    async def test_admin_can_create_exercise(
        self,
        client: AsyncClient,
        admin_headers: dict[str, str],
    ) -> None:
        """Admin users can create exercises."""
        response = await client.post(
            "/api/v1/exercises",
            headers=admin_headers,
            json={
                "name": "Admin Created Exercise",
                "description": "Created by admin",
                "category": "mobility",
                "body_part": "knee",
                "difficulty_level": 1,
            },
        )

        assert response.status_code == 201
        data = response.json()
        assert data["name"] == "Admin Created Exercise"

    @pytest.mark.asyncio
    async def test_non_admin_cannot_delete_exercise(
        self,
        client: AsyncClient,
        session: AsyncSession,
        auth_headers: dict[str, str],
    ) -> None:
        """Regular users cannot delete exercises."""
        # Create exercise
        exercise = Exercise(
            id=uuid4(),
            name="Cannot Delete",
            category=ExerciseCategory.MOBILITY,
            body_part=BodyPart.KNEE,
            is_active=True,
        )
        session.add(exercise)
        await session.commit()

        response = await client.delete(
            f"/api/v1/exercises/{exercise.id}",
            headers=auth_headers,
        )

        assert response.status_code == 403
