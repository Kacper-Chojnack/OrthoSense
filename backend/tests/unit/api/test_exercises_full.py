"""
Unit tests for Exercises API endpoints.

Test coverage:
1. List exercises with filters
2. Get single exercise
3. Create exercise (admin only)
4. Update exercise (admin only)
5. Delete exercise (soft delete, admin only)
6. Edge cases and error handling
"""

from uuid import uuid4

import pytest
from httpx import AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.security import create_access_token, hash_password
from app.models.exercise import BodyPart, Exercise, ExerciseCategory
from app.models.user import User, UserRole


@pytest.fixture
async def admin_user(session: AsyncSession) -> User:
    """Create an admin user for testing."""
    user = User(
        id=uuid4(),
        email="admin@example.com",
        hashed_password=hash_password("adminpassword123"),
        role=UserRole.ADMIN,
        is_active=True,
        is_verified=True,
    )
    session.add(user)
    await session.commit()
    await session.refresh(user)
    return user


@pytest.fixture
def admin_headers(admin_user: User) -> dict[str, str]:
    """Generate authorization headers for admin user."""
    token = create_access_token(admin_user.id)
    return {"Authorization": f"Bearer {token}"}


@pytest.fixture
async def sample_exercise(session: AsyncSession) -> Exercise:
    """Create a sample exercise for testing."""
    exercise = Exercise(
        id=uuid4(),
        name="Test Shoulder Abduction",
        description="Raise arm sideways to shoulder height",
        instructions="Stand tall, raise arm slowly to 90 degrees",
        category=ExerciseCategory.MOBILITY,
        body_part=BodyPart.SHOULDER,
        difficulty_level=2,
        is_active=True,
    )
    session.add(exercise)
    await session.commit()
    await session.refresh(exercise)
    return exercise


@pytest.fixture
async def multiple_exercises(session: AsyncSession) -> list[Exercise]:
    """Create multiple exercises for filter testing."""
    exercises = [
        Exercise(
            id=uuid4(),
            name="Knee Flexion",
            category=ExerciseCategory.MOBILITY,
            body_part=BodyPart.KNEE,
            difficulty_level=1,
        ),
        Exercise(
            id=uuid4(),
            name="Hip Extension",
            category=ExerciseCategory.STRENGTH,
            body_part=BodyPart.HIP,
            difficulty_level=3,
        ),
        Exercise(
            id=uuid4(),
            name="Shoulder Rotation",
            category=ExerciseCategory.MOBILITY,
            body_part=BodyPart.SHOULDER,
            difficulty_level=2,
        ),
        Exercise(
            id=uuid4(),
            name="Ankle Balance",
            category=ExerciseCategory.BALANCE,
            body_part=BodyPart.ANKLE,
            difficulty_level=4,
        ),
        Exercise(
            id=uuid4(),
            name="Inactive Exercise",
            category=ExerciseCategory.MOBILITY,
            body_part=BodyPart.KNEE,
            is_active=False,
        ),
    ]
    for ex in exercises:
        session.add(ex)
    await session.commit()
    for ex in exercises:
        await session.refresh(ex)
    return exercises


class TestListExercises:
    """Tests for GET /exercises endpoint."""

    async def test_list_exercises_unauthenticated(
        self,
        client: AsyncClient,
    ) -> None:
        """Unauthenticated request returns 401."""
        response = await client.get("/api/v1/exercises")
        assert response.status_code == 401

    async def test_list_exercises_success(
        self,
        client: AsyncClient,
        auth_headers: dict[str, str],
        multiple_exercises: list[Exercise],
    ) -> None:
        """Authenticated user can list exercises."""
        response = await client.get(
            "/api/v1/exercises",
            headers=auth_headers,
        )

        assert response.status_code == 200
        data = response.json()
        assert isinstance(data, list)
        # Inactive exercises should not be returned
        names = [ex["name"] for ex in data]
        assert "Inactive Exercise" not in names

    async def test_list_exercises_filter_by_category(
        self,
        client: AsyncClient,
        auth_headers: dict[str, str],
        multiple_exercises: list[Exercise],
    ) -> None:
        """Exercises can be filtered by category."""
        response = await client.get(
            "/api/v1/exercises",
            params={"category": "mobility"},
            headers=auth_headers,
        )

        assert response.status_code == 200
        data = response.json()
        for ex in data:
            assert ex["category"] == "mobility"

    async def test_list_exercises_filter_by_body_part(
        self,
        client: AsyncClient,
        auth_headers: dict[str, str],
        multiple_exercises: list[Exercise],
    ) -> None:
        """Exercises can be filtered by body part."""
        response = await client.get(
            "/api/v1/exercises",
            params={"body_part": "shoulder"},
            headers=auth_headers,
        )

        assert response.status_code == 200
        data = response.json()
        for ex in data:
            assert ex["body_part"] == "shoulder"

    async def test_list_exercises_filter_by_difficulty(
        self,
        client: AsyncClient,
        auth_headers: dict[str, str],
        multiple_exercises: list[Exercise],
    ) -> None:
        """Exercises can be filtered by difficulty."""
        response = await client.get(
            "/api/v1/exercises",
            params={"difficulty": 2},
            headers=auth_headers,
        )

        assert response.status_code == 200
        data = response.json()
        for ex in data:
            assert ex["difficulty_level"] == 2

    async def test_list_exercises_pagination(
        self,
        client: AsyncClient,
        auth_headers: dict[str, str],
        multiple_exercises: list[Exercise],
    ) -> None:
        """Exercises list supports pagination."""
        response = await client.get(
            "/api/v1/exercises",
            params={"skip": 0, "limit": 2},
            headers=auth_headers,
        )

        assert response.status_code == 200
        data = response.json()
        assert len(data) <= 2

    async def test_list_exercises_combined_filters(
        self,
        client: AsyncClient,
        auth_headers: dict[str, str],
        multiple_exercises: list[Exercise],
    ) -> None:
        """Multiple filters can be combined."""
        response = await client.get(
            "/api/v1/exercises",
            params={"category": "mobility", "body_part": "knee"},
            headers=auth_headers,
        )

        assert response.status_code == 200
        data = response.json()
        for ex in data:
            assert ex["category"] == "mobility"
            assert ex["body_part"] == "knee"


class TestGetExercise:
    """Tests for GET /exercises/{exercise_id} endpoint."""

    async def test_get_exercise_success(
        self,
        client: AsyncClient,
        auth_headers: dict[str, str],
        sample_exercise: Exercise,
    ) -> None:
        """Single exercise can be retrieved by ID."""
        response = await client.get(
            f"/api/v1/exercises/{sample_exercise.id}",
            headers=auth_headers,
        )

        assert response.status_code == 200
        data = response.json()
        assert data["id"] == str(sample_exercise.id)
        assert data["name"] == sample_exercise.name

    async def test_get_exercise_not_found(
        self,
        client: AsyncClient,
        auth_headers: dict[str, str],
    ) -> None:
        """Nonexistent exercise returns 404."""
        response = await client.get(
            f"/api/v1/exercises/{uuid4()}",
            headers=auth_headers,
        )

        assert response.status_code == 404
        assert "not found" in response.json()["detail"].lower()

    async def test_get_exercise_unauthenticated(
        self,
        client: AsyncClient,
        sample_exercise: Exercise,
    ) -> None:
        """Unauthenticated request returns 401."""
        response = await client.get(
            f"/api/v1/exercises/{sample_exercise.id}",
        )

        assert response.status_code == 401


class TestCreateExercise:
    """Tests for POST /exercises endpoint."""

    async def test_create_exercise_admin_success(
        self,
        client: AsyncClient,
        admin_headers: dict[str, str],
    ) -> None:
        """Admin can create a new exercise."""
        exercise_data = {
            "name": "New Exercise",
            "description": "A new test exercise",
            "category": "strength",
            "body_part": "hip",
            "difficulty_level": 3,
        }

        response = await client.post(
            "/api/v1/exercises",
            json=exercise_data,
            headers=admin_headers,
        )

        assert response.status_code == 201
        data = response.json()
        assert data["name"] == "New Exercise"
        assert data["category"] == "strength"
        assert "id" in data

    async def test_create_exercise_patient_forbidden(
        self,
        client: AsyncClient,
        auth_headers: dict[str, str],
    ) -> None:
        """Non-admin user cannot create exercises."""
        exercise_data = {
            "name": "Unauthorized Exercise",
            "category": "mobility",
            "body_part": "knee",
        }

        response = await client.post(
            "/api/v1/exercises",
            json=exercise_data,
            headers=auth_headers,
        )

        assert response.status_code == 403

    async def test_create_exercise_invalid_category(
        self,
        client: AsyncClient,
        admin_headers: dict[str, str],
    ) -> None:
        """Invalid category returns validation error."""
        exercise_data = {
            "name": "Invalid Category",
            "category": "invalid_category",
            "body_part": "knee",
        }

        response = await client.post(
            "/api/v1/exercises",
            json=exercise_data,
            headers=admin_headers,
        )

        assert response.status_code == 422

    async def test_create_exercise_invalid_difficulty(
        self,
        client: AsyncClient,
        admin_headers: dict[str, str],
    ) -> None:
        """Difficulty outside 1-5 range returns error."""
        exercise_data = {
            "name": "Invalid Difficulty",
            "category": "mobility",
            "body_part": "knee",
            "difficulty_level": 10,
        }

        response = await client.post(
            "/api/v1/exercises",
            json=exercise_data,
            headers=admin_headers,
        )

        assert response.status_code == 422

    async def test_create_exercise_minimal_data(
        self,
        client: AsyncClient,
        admin_headers: dict[str, str],
    ) -> None:
        """Exercise can be created with minimal data."""
        exercise_data = {
            "name": "Minimal Exercise",
        }

        response = await client.post(
            "/api/v1/exercises",
            json=exercise_data,
            headers=admin_headers,
        )

        assert response.status_code == 201
        data = response.json()
        assert data["name"] == "Minimal Exercise"
        assert data["difficulty_level"] == 1  # default


class TestUpdateExercise:
    """Tests for PATCH /exercises/{exercise_id} endpoint."""

    async def test_update_exercise_admin_success(
        self,
        client: AsyncClient,
        admin_headers: dict[str, str],
        sample_exercise: Exercise,
    ) -> None:
        """Admin can update an exercise."""
        update_data = {
            "name": "Updated Exercise Name",
            "difficulty_level": 4,
        }

        response = await client.patch(
            f"/api/v1/exercises/{sample_exercise.id}",
            json=update_data,
            headers=admin_headers,
        )

        assert response.status_code == 200
        data = response.json()
        assert data["name"] == "Updated Exercise Name"
        assert data["difficulty_level"] == 4

    async def test_update_exercise_patient_forbidden(
        self,
        client: AsyncClient,
        auth_headers: dict[str, str],
        sample_exercise: Exercise,
    ) -> None:
        """Non-admin cannot update exercises."""
        update_data = {"name": "Hacked Name"}

        response = await client.patch(
            f"/api/v1/exercises/{sample_exercise.id}",
            json=update_data,
            headers=auth_headers,
        )

        assert response.status_code == 403

    async def test_update_exercise_not_found(
        self,
        client: AsyncClient,
        admin_headers: dict[str, str],
    ) -> None:
        """Updating nonexistent exercise returns 404."""
        response = await client.patch(
            f"/api/v1/exercises/{uuid4()}",
            json={"name": "Does Not Exist"},
            headers=admin_headers,
        )

        assert response.status_code == 404

    async def test_update_exercise_partial(
        self,
        client: AsyncClient,
        admin_headers: dict[str, str],
        sample_exercise: Exercise,
    ) -> None:
        """Partial update only changes specified fields."""
        original_name = sample_exercise.name
        update_data = {"difficulty_level": 5}

        response = await client.patch(
            f"/api/v1/exercises/{sample_exercise.id}",
            json=update_data,
            headers=admin_headers,
        )

        assert response.status_code == 200
        data = response.json()
        assert data["difficulty_level"] == 5
        # Name should remain unchanged
        assert data["name"] == original_name


class TestDeleteExercise:
    """Tests for DELETE /exercises/{exercise_id} endpoint."""

    async def test_delete_exercise_admin_success(
        self,
        client: AsyncClient,
        admin_headers: dict[str, str],
        sample_exercise: Exercise,
    ) -> None:
        """Admin can soft-delete an exercise."""
        response = await client.delete(
            f"/api/v1/exercises/{sample_exercise.id}",
            headers=admin_headers,
        )

        assert response.status_code == 204

    async def test_delete_exercise_patient_forbidden(
        self,
        client: AsyncClient,
        auth_headers: dict[str, str],
        sample_exercise: Exercise,
    ) -> None:
        """Non-admin cannot delete exercises."""
        response = await client.delete(
            f"/api/v1/exercises/{sample_exercise.id}",
            headers=auth_headers,
        )

        assert response.status_code == 403

    async def test_delete_exercise_not_found(
        self,
        client: AsyncClient,
        admin_headers: dict[str, str],
    ) -> None:
        """Deleting nonexistent exercise returns 404."""
        response = await client.delete(
            f"/api/v1/exercises/{uuid4()}",
            headers=admin_headers,
        )

        assert response.status_code == 404

    async def test_deleted_exercise_not_in_list(
        self,
        client: AsyncClient,
        admin_headers: dict[str, str],
        sample_exercise: Exercise,
    ) -> None:
        """Soft-deleted exercise doesn't appear in list."""
        # Delete the exercise
        await client.delete(
            f"/api/v1/exercises/{sample_exercise.id}",
            headers=admin_headers,
        )

        # List exercises
        response = await client.get(
            "/api/v1/exercises",
            headers=admin_headers,
        )

        assert response.status_code == 200
        ids = [ex["id"] for ex in response.json()]
        assert str(sample_exercise.id) not in ids


class TestExerciseEdgeCases:
    """Tests for edge cases and boundary conditions."""

    async def test_exercise_with_special_characters(
        self,
        client: AsyncClient,
        admin_headers: dict[str, str],
    ) -> None:
        """Exercise name can contain special characters."""
        exercise_data = {
            "name": "Exercise (Modified) - Version 2.0",
            "description": "Contains: special & characters <test>",
        }

        response = await client.post(
            "/api/v1/exercises",
            json=exercise_data,
            headers=admin_headers,
        )

        assert response.status_code == 201

    async def test_exercise_with_unicode(
        self,
        client: AsyncClient,
        admin_headers: dict[str, str],
    ) -> None:
        """Exercise can have unicode characters."""
        exercise_data = {
            "name": "Ćwiczenie rehabilitacyjne",
            "description": "Opis po polsku",
        }

        response = await client.post(
            "/api/v1/exercises",
            json=exercise_data,
            headers=admin_headers,
        )

        assert response.status_code == 201
        data = response.json()
        assert data["name"] == "Ćwiczenie rehabilitacyjne"

    async def test_exercise_with_video_url(
        self,
        client: AsyncClient,
        admin_headers: dict[str, str],
    ) -> None:
        """Exercise can include video URL."""
        exercise_data = {
            "name": "Video Exercise",
            "video_url": "https://example.com/videos/exercise.mp4",
            "thumbnail_url": "https://example.com/thumbs/exercise.jpg",
        }

        response = await client.post(
            "/api/v1/exercises",
            json=exercise_data,
            headers=admin_headers,
        )

        assert response.status_code == 201
        data = response.json()
        assert data["video_url"] == "https://example.com/videos/exercise.mp4"

    async def test_exercise_with_duration(
        self,
        client: AsyncClient,
        admin_headers: dict[str, str],
    ) -> None:
        """Exercise can specify duration."""
        exercise_data = {
            "name": "Timed Exercise",
            "duration_seconds": 300,
        }

        response = await client.post(
            "/api/v1/exercises",
            json=exercise_data,
            headers=admin_headers,
        )

        assert response.status_code == 201
        data = response.json()
        assert data["duration_seconds"] == 300

    async def test_list_exercises_limit_boundary(
        self,
        client: AsyncClient,
        auth_headers: dict[str, str],
    ) -> None:
        """List respects maximum limit."""
        response = await client.get(
            "/api/v1/exercises",
            params={"limit": 200},  # Above max 100
            headers=auth_headers,
        )

        # Should either return 422 or cap at 100
        assert response.status_code in [200, 422]
