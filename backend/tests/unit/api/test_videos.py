"""
Unit tests for Exercise Videos API endpoints.

Test coverage:
1. List videos for an exercise
2. Get primary video
3. Get single video by ID
4. Create video (authenticated)
5. Update video
6. Delete video (soft delete)
7. Error handling (404, validation)
"""

from uuid import uuid4

import pytest
from httpx import AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.exercise import BodyPart, Exercise, ExerciseCategory
from app.models.exercise_video import ExerciseVideo
from app.models.user import User


@pytest.fixture
async def test_exercise(session: AsyncSession) -> Exercise:
    """Create a test exercise."""
    exercise = Exercise(
        id=uuid4(),
        name="Test Exercise for Videos",
        category=ExerciseCategory.MOBILITY,
        body_part=BodyPart.KNEE,
        difficulty_level=2,
        is_active=True,
    )
    session.add(exercise)
    await session.commit()
    await session.refresh(exercise)
    return exercise


@pytest.fixture
async def test_videos(
    session: AsyncSession,
    test_exercise: Exercise,
) -> list[ExerciseVideo]:
    """Create test videos for an exercise."""
    videos = [
        ExerciseVideo(
            id=uuid4(),
            exercise_id=test_exercise.id,
            title="Primary Front View",
            description="Main demonstration video",
            video_url="https://example.com/video1.mp4",
            thumbnail_url="https://example.com/thumb1.jpg",
            duration_seconds=120,
            view_angle="front",
            is_primary=True,
            sort_order=0,
            is_active=True,
        ),
        ExerciseVideo(
            id=uuid4(),
            exercise_id=test_exercise.id,
            title="Side View",
            description="Alternative angle",
            video_url="https://example.com/video2.mp4",
            duration_seconds=90,
            view_angle="side",
            is_primary=False,
            sort_order=1,
            is_active=True,
        ),
        ExerciseVideo(
            id=uuid4(),
            exercise_id=test_exercise.id,
            title="Inactive Video",
            description="Archived video",
            video_url="https://example.com/video3.mp4",
            duration_seconds=60,
            view_angle="back",
            is_primary=False,
            sort_order=2,
            is_active=False,  # Inactive
        ),
    ]
    for video in videos:
        session.add(video)
    await session.commit()
    return videos


class TestListExerciseVideos:
    """Test GET /api/v1/exercise-videos/exercise/{exercise_id} endpoint."""

    @pytest.mark.asyncio
    async def test_list_videos_authenticated(
        self,
        client: AsyncClient,
        session: AsyncSession,
        test_user: User,
        auth_headers: dict[str, str],
        test_exercise: Exercise,
        test_videos: list[ExerciseVideo],
    ) -> None:
        """Authenticated users can list videos for an exercise."""
        response = await client.get(
            f"/api/v1/exercise-videos/exercise/{test_exercise.id}",
            headers=auth_headers,
        )

        assert response.status_code == 200
        data = response.json()
        # Should only return active videos
        assert len(data) == 2
        # Primary video should be first
        assert data[0]["is_primary"] is True

    @pytest.mark.asyncio
    async def test_list_videos_unauthenticated(
        self,
        client: AsyncClient,
        test_exercise: Exercise,
    ) -> None:
        """Unauthenticated users cannot list videos."""
        response = await client.get(
            f"/api/v1/exercise-videos/exercise/{test_exercise.id}",
        )
        assert response.status_code == 401

    @pytest.mark.asyncio
    async def test_list_videos_nonexistent_exercise(
        self,
        client: AsyncClient,
        auth_headers: dict[str, str],
    ) -> None:
        """Listing videos for nonexistent exercise returns empty list."""
        response = await client.get(
            f"/api/v1/exercise-videos/exercise/{uuid4()}",
            headers=auth_headers,
        )

        assert response.status_code == 200
        data = response.json()
        assert data == []

    @pytest.mark.asyncio
    async def test_list_videos_sorted_by_primary_and_order(
        self,
        client: AsyncClient,
        session: AsyncSession,
        auth_headers: dict[str, str],
        test_exercise: Exercise,
        test_videos: list[ExerciseVideo],
    ) -> None:
        """Videos are sorted by primary flag descending, then sort_order."""
        response = await client.get(
            f"/api/v1/exercise-videos/exercise/{test_exercise.id}",
            headers=auth_headers,
        )

        assert response.status_code == 200
        data = response.json()
        # First should be primary
        assert data[0]["is_primary"] is True
        assert data[0]["title"] == "Primary Front View"
        # Second should be side view with sort_order 1
        assert data[1]["is_primary"] is False


class TestGetPrimaryVideo:
    """Test GET /api/v1/exercise-videos/exercise/{exercise_id}/primary endpoint."""

    @pytest.mark.asyncio
    async def test_get_primary_video(
        self,
        client: AsyncClient,
        auth_headers: dict[str, str],
        test_exercise: Exercise,
        test_videos: list[ExerciseVideo],
    ) -> None:
        """Get the primary video for an exercise."""
        response = await client.get(
            f"/api/v1/exercise-videos/exercise/{test_exercise.id}/primary",
            headers=auth_headers,
        )

        assert response.status_code == 200
        data = response.json()
        assert data["is_primary"] is True
        assert data["title"] == "Primary Front View"

    @pytest.mark.asyncio
    async def test_get_primary_video_none_exists(
        self,
        client: AsyncClient,
        session: AsyncSession,
        auth_headers: dict[str, str],
    ) -> None:
        """Returns null when no primary video exists."""
        # Create exercise without primary video
        exercise = Exercise(
            id=uuid4(),
            name="No Primary Video Exercise",
            category=ExerciseCategory.BALANCE,
            body_part=BodyPart.ANKLE,
            is_active=True,
        )
        session.add(exercise)

        video = ExerciseVideo(
            exercise_id=exercise.id,
            title="Non-Primary",
            video_url="https://example.com/test.mp4",
            duration_seconds=60,
            is_primary=False,
            is_active=True,
        )
        session.add(video)
        await session.commit()

        response = await client.get(
            f"/api/v1/exercise-videos/exercise/{exercise.id}/primary",
            headers=auth_headers,
        )

        assert response.status_code == 200
        assert response.json() is None


class TestGetVideo:
    """Test GET /api/v1/exercise-videos/{video_id} endpoint."""

    @pytest.mark.asyncio
    async def test_get_video_by_id(
        self,
        client: AsyncClient,
        auth_headers: dict[str, str],
        test_videos: list[ExerciseVideo],
    ) -> None:
        """Get a single video by ID."""
        video = test_videos[0]

        response = await client.get(
            f"/api/v1/exercise-videos/{video.id}",
            headers=auth_headers,
        )

        assert response.status_code == 200
        data = response.json()
        assert data["id"] == str(video.id)
        assert data["title"] == video.title

    @pytest.mark.asyncio
    async def test_get_video_not_found(
        self,
        client: AsyncClient,
        auth_headers: dict[str, str],
    ) -> None:
        """Returns 404 for nonexistent video."""
        response = await client.get(
            f"/api/v1/exercise-videos/{uuid4()}",
            headers=auth_headers,
        )

        assert response.status_code == 404
        assert "Video not found" in response.json()["detail"]

    @pytest.mark.asyncio
    async def test_get_inactive_video_still_accessible(
        self,
        client: AsyncClient,
        auth_headers: dict[str, str],
        test_videos: list[ExerciseVideo],
    ) -> None:
        """Inactive videos can still be fetched by ID."""
        inactive_video = test_videos[2]  # The inactive one
        assert inactive_video.is_active is False

        response = await client.get(
            f"/api/v1/exercise-videos/{inactive_video.id}",
            headers=auth_headers,
        )

        # Direct access by ID should work
        assert response.status_code == 200


class TestCreateVideo:
    """Test POST /api/v1/exercise-videos endpoint."""

    @pytest.mark.asyncio
    async def test_create_video(
        self,
        client: AsyncClient,
        auth_headers: dict[str, str],
        test_exercise: Exercise,
    ) -> None:
        """Authenticated users can create videos."""
        video_data = {
            "exercise_id": str(test_exercise.id),
            "title": "New Demo Video",
            "description": "A new demonstration",
            "video_url": "https://example.com/new.mp4",
            "thumbnail_url": "https://example.com/new-thumb.jpg",
            "duration_seconds": 180,
            "view_angle": "overhead",
            "is_primary": False,
            "sort_order": 5,
        }

        response = await client.post(
            "/api/v1/exercise-videos",
            headers=auth_headers,
            json=video_data,
        )

        assert response.status_code == 201
        data = response.json()
        assert data["title"] == "New Demo Video"
        assert data["view_angle"] == "overhead"
        assert data["duration_seconds"] == 180
        assert "id" in data

    @pytest.mark.asyncio
    async def test_create_video_nonexistent_exercise(
        self,
        client: AsyncClient,
        auth_headers: dict[str, str],
    ) -> None:
        """Cannot create video for nonexistent exercise."""
        video_data = {
            "exercise_id": str(uuid4()),
            "title": "Orphan Video",
            "video_url": "https://example.com/orphan.mp4",
            "duration_seconds": 60,
        }

        response = await client.post(
            "/api/v1/exercise-videos",
            headers=auth_headers,
            json=video_data,
        )

        assert response.status_code == 404
        assert "Exercise not found" in response.json()["detail"]

    @pytest.mark.asyncio
    async def test_create_video_unauthenticated(
        self,
        client: AsyncClient,
        test_exercise: Exercise,
    ) -> None:
        """Unauthenticated users cannot create videos."""
        video_data = {
            "exercise_id": str(test_exercise.id),
            "title": "Unauthorized Video",
            "video_url": "https://example.com/unauth.mp4",
            "duration_seconds": 60,
        }

        response = await client.post(
            "/api/v1/exercise-videos",
            json=video_data,
        )

        assert response.status_code == 401


class TestUpdateVideo:
    """Test PATCH /api/v1/exercise-videos/{video_id} endpoint."""

    @pytest.mark.asyncio
    async def test_update_video(
        self,
        client: AsyncClient,
        auth_headers: dict[str, str],
        test_videos: list[ExerciseVideo],
    ) -> None:
        """Update video fields."""
        video = test_videos[1]  # Non-primary video

        response = await client.patch(
            f"/api/v1/exercise-videos/{video.id}",
            headers=auth_headers,
            json={
                "title": "Updated Side View",
                "description": "Updated description",
                "is_primary": True,
            },
        )

        assert response.status_code == 200
        data = response.json()
        assert data["title"] == "Updated Side View"
        assert data["description"] == "Updated description"
        assert data["is_primary"] is True

    @pytest.mark.asyncio
    async def test_update_video_partial(
        self,
        client: AsyncClient,
        auth_headers: dict[str, str],
        test_videos: list[ExerciseVideo],
    ) -> None:
        """Partial update only changes specified fields."""
        video = test_videos[0]
        original_title = video.title

        response = await client.patch(
            f"/api/v1/exercise-videos/{video.id}",
            headers=auth_headers,
            json={"sort_order": 99},
        )

        assert response.status_code == 200
        data = response.json()
        assert data["sort_order"] == 99
        assert data["title"] == original_title  # Unchanged

    @pytest.mark.asyncio
    async def test_update_video_not_found(
        self,
        client: AsyncClient,
        auth_headers: dict[str, str],
    ) -> None:
        """Returns 404 for nonexistent video."""
        response = await client.patch(
            f"/api/v1/exercise-videos/{uuid4()}",
            headers=auth_headers,
            json={"title": "Ghost Video"},
        )

        assert response.status_code == 404


class TestDeleteVideo:
    """Test DELETE /api/v1/exercise-videos/{video_id} endpoint."""

    @pytest.mark.asyncio
    async def test_delete_video_soft_delete(
        self,
        client: AsyncClient,
        session: AsyncSession,
        auth_headers: dict[str, str],
        test_videos: list[ExerciseVideo],
    ) -> None:
        """Deleting a video performs soft delete (sets is_active=False)."""
        video = test_videos[0]
        assert video.is_active is True

        response = await client.delete(
            f"/api/v1/exercise-videos/{video.id}",
            headers=auth_headers,
        )

        assert response.status_code == 204

        # Refresh from database
        await session.refresh(video)
        assert video.is_active is False

    @pytest.mark.asyncio
    async def test_delete_video_not_found(
        self,
        client: AsyncClient,
        auth_headers: dict[str, str],
    ) -> None:
        """Returns 404 for nonexistent video."""
        response = await client.delete(
            f"/api/v1/exercise-videos/{uuid4()}",
            headers=auth_headers,
        )

        assert response.status_code == 404

    @pytest.mark.asyncio
    async def test_delete_video_unauthenticated(
        self,
        client: AsyncClient,
        test_videos: list[ExerciseVideo],
    ) -> None:
        """Unauthenticated users cannot delete videos."""
        response = await client.delete(
            f"/api/v1/exercise-videos/{test_videos[0].id}",
        )

        assert response.status_code == 401


class TestVideoPagination:
    """Test pagination for video listing."""

    @pytest.mark.asyncio
    async def test_list_videos_pagination(
        self,
        client: AsyncClient,
        session: AsyncSession,
        auth_headers: dict[str, str],
    ) -> None:
        """Pagination parameters work correctly."""
        # Create exercise with many videos
        exercise = Exercise(
            id=uuid4(),
            name="Exercise with Many Videos",
            category=ExerciseCategory.MOBILITY,
            body_part=BodyPart.HIP,
            is_active=True,
        )
        session.add(exercise)

        for i in range(25):
            video = ExerciseVideo(
                exercise_id=exercise.id,
                title=f"Video {i}",
                video_url=f"https://example.com/v{i}.mp4",
                duration_seconds=60,
                sort_order=i,
                is_active=True,
            )
            session.add(video)
        await session.commit()

        # First page
        response = await client.get(
            f"/api/v1/exercise-videos/exercise/{exercise.id}",
            headers=auth_headers,
            params={"skip": 0, "limit": 10},
        )

        assert response.status_code == 200
        data = response.json()
        assert len(data) == 10

        # Second page
        response = await client.get(
            f"/api/v1/exercise-videos/exercise/{exercise.id}",
            headers=auth_headers,
            params={"skip": 10, "limit": 10},
        )

        assert response.status_code == 200
        data = response.json()
        assert len(data) == 10

        # Third page (only 5 remaining)
        response = await client.get(
            f"/api/v1/exercise-videos/exercise/{exercise.id}",
            headers=auth_headers,
            params={"skip": 20, "limit": 10},
        )

        assert response.status_code == 200
        data = response.json()
        assert len(data) == 5
