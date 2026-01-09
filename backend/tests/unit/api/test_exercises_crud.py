"""
Comprehensive unit tests for Exercise API endpoints.

Test coverage:
1. Full CRUD operations for exercises
2. Authorization (admin-only operations)
3. Filtering combinations
4. Pagination edge cases
5. Soft delete behavior
6. Update partial fields
"""

from uuid import uuid4

import pytest
from httpx import AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.security import create_access_token, hash_password
from app.models.exercise import (
    BodyPart,
    Exercise,
    ExerciseCategory,
)
from app.models.user import User, UserRole


class TestExerciseCRUD:
    """Full CRUD tests for exercises with proper authorization."""

    @pytest.fixture
    async def admin_user(self, session: AsyncSession) -> User:
        """Create admin user for protected operations."""
        user = User(
            id=uuid4(),
            email="admin@example.com",
            hashed_password=hash_password("adminpassword123"),
            is_active=True,
            is_verified=True,
            role=UserRole.ADMIN,
        )
        session.add(user)
        await session.commit()
        await session.refresh(user)
        return user

    @pytest.fixture
    def admin_headers(self, admin_user: User) -> dict[str, str]:
        """Authorization headers for admin user."""
        token = create_access_token(admin_user.id)
        return {"Authorization": f"Bearer {token}"}

    @pytest.fixture
    async def sample_exercise(self, session: AsyncSession) -> Exercise:
        """Create a sample exercise for testing."""
        exercise = Exercise(
            id=uuid4(),
            name="Sample Exercise",
            description="A test exercise",
            category=ExerciseCategory.MOBILITY,
            body_part=BodyPart.KNEE,
            difficulty_level=3,
            is_active=True,
        )
        session.add(exercise)
        await session.commit()
        await session.refresh(exercise)
        return exercise

    # CREATE Tests
    @pytest.mark.asyncio
    async def test_create_exercise_as_admin(
        self,
        client: AsyncClient,
        admin_headers: dict[str, str],
    ) -> None:
        """Admin can create new exercises."""
        response = await client.post(
            "/api/v1/exercises",
            headers=admin_headers,
            json={
                "name": "New Exercise",
                "description": "Test description",
                "category": "mobility",
                "body_part": "knee",
                "difficulty_level": 2,
            },
        )

        assert response.status_code == 201
        data = response.json()
        assert data["name"] == "New Exercise"
        assert data["category"] == "mobility"
        assert data["is_active"] is True

    @pytest.mark.asyncio
    async def test_create_exercise_as_regular_user(
        self,
        client: AsyncClient,
        auth_headers: dict[str, str],
    ) -> None:
        """Regular users cannot create exercises."""
        response = await client.post(
            "/api/v1/exercises",
            headers=auth_headers,
            json={
                "name": "Unauthorized Exercise",
                "category": "mobility",
                "body_part": "knee",
            },
        )

        assert response.status_code == 403

    @pytest.mark.asyncio
    async def test_create_exercise_without_auth(
        self,
        client: AsyncClient,
    ) -> None:
        """Unauthenticated users cannot create exercises."""
        response = await client.post(
            "/api/v1/exercises",
            json={
                "name": "No Auth Exercise",
                "category": "mobility",
                "body_part": "knee",
            },
        )

        assert response.status_code == 401

    # READ Tests
    @pytest.mark.asyncio
    async def test_get_exercise_by_id(
        self,
        client: AsyncClient,
        auth_headers: dict[str, str],
        sample_exercise: Exercise,
    ) -> None:
        """Get single exercise by ID."""
        response = await client.get(
            f"/api/v1/exercises/{sample_exercise.id}",
            headers=auth_headers,
        )

        assert response.status_code == 200
        data = response.json()
        assert data["name"] == sample_exercise.name
        assert data["id"] == str(sample_exercise.id)

    @pytest.mark.asyncio
    async def test_get_exercise_not_found(
        self,
        client: AsyncClient,
        auth_headers: dict[str, str],
    ) -> None:
        """Get non-existent exercise returns 404."""
        response = await client.get(
            f"/api/v1/exercises/{uuid4()}",
            headers=auth_headers,
        )

        assert response.status_code == 404

    # UPDATE Tests
    @pytest.mark.asyncio
    async def test_update_exercise_as_admin(
        self,
        client: AsyncClient,
        session: AsyncSession,
        admin_headers: dict[str, str],
        sample_exercise: Exercise,
    ) -> None:
        """Admin can update exercises."""
        response = await client.patch(
            f"/api/v1/exercises/{sample_exercise.id}",
            headers=admin_headers,
            json={
                "name": "Updated Exercise Name",
                "difficulty_level": 5,
            },
        )

        assert response.status_code == 200
        data = response.json()
        assert data["name"] == "Updated Exercise Name"
        assert data["difficulty_level"] == 5
        # Description should remain unchanged
        assert data["description"] == sample_exercise.description

    @pytest.mark.asyncio
    async def test_update_exercise_as_regular_user(
        self,
        client: AsyncClient,
        auth_headers: dict[str, str],
        sample_exercise: Exercise,
    ) -> None:
        """Regular users cannot update exercises."""
        response = await client.patch(
            f"/api/v1/exercises/{sample_exercise.id}",
            headers=auth_headers,
            json={"name": "Unauthorized Update"},
        )

        assert response.status_code == 403

    @pytest.mark.asyncio
    async def test_update_nonexistent_exercise(
        self,
        client: AsyncClient,
        admin_headers: dict[str, str],
    ) -> None:
        """Update non-existent exercise returns 404."""
        response = await client.patch(
            f"/api/v1/exercises/{uuid4()}",
            headers=admin_headers,
            json={"name": "Ghost Exercise"},
        )

        assert response.status_code == 404

    # DELETE Tests
    @pytest.mark.asyncio
    async def test_delete_exercise_as_admin(
        self,
        client: AsyncClient,
        session: AsyncSession,
        admin_headers: dict[str, str],
        sample_exercise: Exercise,
    ) -> None:
        """Admin can soft delete exercises."""
        response = await client.delete(
            f"/api/v1/exercises/{sample_exercise.id}",
            headers=admin_headers,
        )

        assert response.status_code == 204

        # Verify soft delete
        await session.refresh(sample_exercise)
        assert sample_exercise.is_active is False

    @pytest.mark.asyncio
    async def test_delete_exercise_as_regular_user(
        self,
        client: AsyncClient,
        auth_headers: dict[str, str],
        sample_exercise: Exercise,
    ) -> None:
        """Regular users cannot delete exercises."""
        response = await client.delete(
            f"/api/v1/exercises/{sample_exercise.id}",
            headers=auth_headers,
        )

        assert response.status_code == 403

    @pytest.mark.asyncio
    async def test_delete_nonexistent_exercise(
        self,
        client: AsyncClient,
        admin_headers: dict[str, str],
    ) -> None:
        """Delete non-existent exercise returns 404."""
        response = await client.delete(
            f"/api/v1/exercises/{uuid4()}",
            headers=admin_headers,
        )

        assert response.status_code == 404


class TestExerciseFiltering:
    """Tests for exercise filtering and pagination."""

    @pytest.fixture
    async def exercises_dataset(self, session: AsyncSession) -> list[Exercise]:
        """Create diverse dataset for filtering tests."""
        exercises = [
            Exercise(
                id=uuid4(),
                name="Knee Mobility",
                category=ExerciseCategory.MOBILITY,
                body_part=BodyPart.KNEE,
                difficulty_level=1,
                is_active=True,
            ),
            Exercise(
                id=uuid4(),
                name="Knee Strength",
                category=ExerciseCategory.STRENGTH,
                body_part=BodyPart.KNEE,
                difficulty_level=3,
                is_active=True,
            ),
            Exercise(
                id=uuid4(),
                name="Shoulder Mobility",
                category=ExerciseCategory.MOBILITY,
                body_part=BodyPart.SHOULDER,
                difficulty_level=2,
                is_active=True,
            ),
            Exercise(
                id=uuid4(),
                name="Hip Balance",
                category=ExerciseCategory.BALANCE,
                body_part=BodyPart.HIP,
                difficulty_level=4,
                is_active=True,
            ),
            Exercise(
                id=uuid4(),
                name="Inactive Exercise",
                category=ExerciseCategory.MOBILITY,
                body_part=BodyPart.KNEE,
                difficulty_level=1,
                is_active=False,
            ),
        ]
        for ex in exercises:
            session.add(ex)
        await session.commit()
        return exercises

    @pytest.mark.asyncio
    async def test_filter_by_category(
        self,
        client: AsyncClient,
        auth_headers: dict[str, str],
        exercises_dataset: list[Exercise],
    ) -> None:
        """Filter exercises by category."""
        response = await client.get(
            "/api/v1/exercises",
            headers=auth_headers,
            params={"category": "mobility"},
        )

        assert response.status_code == 200
        data = response.json()
        assert all(ex["category"] == "mobility" for ex in data)

    @pytest.mark.asyncio
    async def test_filter_by_body_part(
        self,
        client: AsyncClient,
        auth_headers: dict[str, str],
        exercises_dataset: list[Exercise],
    ) -> None:
        """Filter exercises by body part."""
        response = await client.get(
            "/api/v1/exercises",
            headers=auth_headers,
            params={"body_part": "knee"},
        )

        assert response.status_code == 200
        data = response.json()
        assert all(ex["body_part"] == "knee" for ex in data)

    @pytest.mark.asyncio
    async def test_filter_by_difficulty(
        self,
        client: AsyncClient,
        auth_headers: dict[str, str],
        exercises_dataset: list[Exercise],
    ) -> None:
        """Filter exercises by difficulty level."""
        response = await client.get(
            "/api/v1/exercises",
            headers=auth_headers,
            params={"difficulty": 3},
        )

        assert response.status_code == 200
        data = response.json()
        assert all(ex["difficulty_level"] == 3 for ex in data)

    @pytest.mark.asyncio
    async def test_combined_filters(
        self,
        client: AsyncClient,
        auth_headers: dict[str, str],
        exercises_dataset: list[Exercise],
    ) -> None:
        """Multiple filters work together."""
        response = await client.get(
            "/api/v1/exercises",
            headers=auth_headers,
            params={
                "category": "mobility",
                "body_part": "knee",
            },
        )

        assert response.status_code == 200
        data = response.json()
        assert all(
            ex["category"] == "mobility" and ex["body_part"] == "knee" for ex in data
        )

    @pytest.mark.asyncio
    async def test_inactive_exercises_not_listed(
        self,
        client: AsyncClient,
        auth_headers: dict[str, str],
        exercises_dataset: list[Exercise],
    ) -> None:
        """Inactive exercises are not returned in list."""
        response = await client.get(
            "/api/v1/exercises",
            headers=auth_headers,
        )

        assert response.status_code == 200
        data = response.json()
        assert all(ex.get("is_active", True) for ex in data)
        assert not any(ex["name"] == "Inactive Exercise" for ex in data)

    @pytest.mark.asyncio
    async def test_pagination_limit(
        self,
        client: AsyncClient,
        session: AsyncSession,
        auth_headers: dict[str, str],
    ) -> None:
        """Pagination limit is respected."""
        # Create 15 exercises
        for i in range(15):
            session.add(
                Exercise(
                    id=uuid4(),
                    name=f"Paginated Exercise {i:02d}",
                    category=ExerciseCategory.MOBILITY,
                    body_part=BodyPart.KNEE,
                    is_active=True,
                )
            )
        await session.commit()

        response = await client.get(
            "/api/v1/exercises",
            headers=auth_headers,
            params={"limit": 5},
        )

        assert response.status_code == 200
        data = response.json()
        assert len(data) == 5

    @pytest.mark.asyncio
    async def test_pagination_skip(
        self,
        client: AsyncClient,
        session: AsyncSession,
        auth_headers: dict[str, str],
    ) -> None:
        """Pagination skip works correctly."""
        # Create exercises with known names
        for i in range(10):
            session.add(
                Exercise(
                    id=uuid4(),
                    name=f"Alpha {i:02d}",
                    category=ExerciseCategory.MOBILITY,
                    body_part=BodyPart.KNEE,
                    is_active=True,
                )
            )
        await session.commit()

        response1 = await client.get(
            "/api/v1/exercises",
            headers=auth_headers,
            params={"skip": 0, "limit": 5},
        )
        response2 = await client.get(
            "/api/v1/exercises",
            headers=auth_headers,
            params={"skip": 5, "limit": 5},
        )

        data1 = response1.json()
        data2 = response2.json()

        # Should have no overlap
        ids1 = {ex["id"] for ex in data1}
        ids2 = {ex["id"] for ex in data2}
        assert ids1.isdisjoint(ids2)

    @pytest.mark.asyncio
    async def test_invalid_difficulty_range(
        self,
        client: AsyncClient,
        auth_headers: dict[str, str],
    ) -> None:
        """Invalid difficulty level returns validation error."""
        response = await client.get(
            "/api/v1/exercises",
            headers=auth_headers,
            params={"difficulty": 10},  # Max is 5
        )

        assert response.status_code == 422

    @pytest.mark.asyncio
    async def test_invalid_limit_range(
        self,
        client: AsyncClient,
        auth_headers: dict[str, str],
    ) -> None:
        """Invalid limit returns validation error."""
        response = await client.get(
            "/api/v1/exercises",
            headers=auth_headers,
            params={"limit": 200},  # Max is 100
        )

        assert response.status_code == 422
