"""
Unit tests for Exercise API endpoints.

Test coverage:
1. CRUD operations with proper authorization
2. Filtering and pagination
3. Admin-only operations
4. Error handling
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


class TestListExercises:
    """Test GET /api/v1/exercises endpoint."""

    async def test_list_exercises_authenticated(
        self,
        client: AsyncClient,
        session: AsyncSession,
        test_user: User,
        auth_headers: dict[str, str],
    ) -> None:
        """Authenticated users can list exercises."""
        # Create test exercises
        exercises = [
            Exercise(
                id=uuid4(),
                name=f"Exercise {i}",
                category=ExerciseCategory.MOBILITY,
                body_part=BodyPart.KNEE,
                difficulty_level=i % 5 + 1,
                is_active=True,
            )
            for i in range(5)
        ]
        for ex in exercises:
            session.add(ex)
        await session.commit()

        response = await client.get(
            "/api/v1/exercises",
            headers=auth_headers,
        )

        assert response.status_code == 200
        data = response.json()
        assert len(data) == 5

    async def test_list_exercises_unauthenticated(
        self,
        client: AsyncClient,
    ) -> None:
        """Unauthenticated users cannot list exercises."""
        response = await client.get("/api/v1/exercises")
        assert response.status_code == 401

    async def test_list_exercises_filter_by_category(
        self,
        client: AsyncClient,
        session: AsyncSession,
        test_user: User,
        auth_headers: dict[str, str],
    ) -> None:
        """Filter exercises by category."""
        # Create exercises with different categories
        mobility_ex = Exercise(
            id=uuid4(),
            name="Mobility Exercise",
            category=ExerciseCategory.MOBILITY,
            body_part=BodyPart.KNEE,
            is_active=True,
        )
        strength_ex = Exercise(
            id=uuid4(),
            name="Strength Exercise",
            category=ExerciseCategory.STRENGTH,
            body_part=BodyPart.KNEE,
            is_active=True,
        )
        session.add(mobility_ex)
        session.add(strength_ex)
        await session.commit()

        response = await client.get(
            "/api/v1/exercises",
            headers=auth_headers,
            params={"category": "mobility"},
        )

        assert response.status_code == 200
        data = response.json()
        assert all(ex["category"] == "mobility" for ex in data)

    async def test_list_exercises_filter_by_body_part(
        self,
        client: AsyncClient,
        session: AsyncSession,
        test_user: User,
        auth_headers: dict[str, str],
    ) -> None:
        """Filter exercises by body part."""
        knee_ex = Exercise(
            id=uuid4(),
            name="Knee Exercise",
            category=ExerciseCategory.MOBILITY,
            body_part=BodyPart.KNEE,
            is_active=True,
        )
        shoulder_ex = Exercise(
            id=uuid4(),
            name="Shoulder Exercise",
            category=ExerciseCategory.MOBILITY,
            body_part=BodyPart.SHOULDER,
            is_active=True,
        )
        session.add(knee_ex)
        session.add(shoulder_ex)
        await session.commit()

        response = await client.get(
            "/api/v1/exercises",
            headers=auth_headers,
            params={"body_part": "shoulder"},
        )

        assert response.status_code == 200
        data = response.json()
        assert all(ex["body_part"] == "shoulder" for ex in data)

    async def test_list_exercises_filter_by_difficulty(
        self,
        client: AsyncClient,
        session: AsyncSession,
        test_user: User,
        auth_headers: dict[str, str],
    ) -> None:
        """Filter exercises by difficulty level."""
        easy_ex = Exercise(
            id=uuid4(),
            name="Easy Exercise",
            category=ExerciseCategory.MOBILITY,
            body_part=BodyPart.KNEE,
            difficulty_level=1,
            is_active=True,
        )
        hard_ex = Exercise(
            id=uuid4(),
            name="Hard Exercise",
            category=ExerciseCategory.MOBILITY,
            body_part=BodyPart.KNEE,
            difficulty_level=5,
            is_active=True,
        )
        session.add(easy_ex)
        session.add(hard_ex)
        await session.commit()

        response = await client.get(
            "/api/v1/exercises",
            headers=auth_headers,
            params={"difficulty": 1},
        )

        assert response.status_code == 200
        data = response.json()
        assert all(ex["difficulty_level"] == 1 for ex in data)

    async def test_list_exercises_pagination(
        self,
        client: AsyncClient,
        session: AsyncSession,
        test_user: User,
        auth_headers: dict[str, str],
    ) -> None:
        """Pagination works correctly."""
        # Create 10 exercises
        for i in range(10):
            session.add(
                Exercise(
                    id=uuid4(),
                    name=f"Exercise {i:02d}",
                    category=ExerciseCategory.MOBILITY,
                    body_part=BodyPart.KNEE,
                    is_active=True,
                )
            )
        await session.commit()

        # Get first page
        response = await client.get(
            "/api/v1/exercises",
            headers=auth_headers,
            params={"skip": 0, "limit": 5},
        )

        assert response.status_code == 200
        data = response.json()
        assert len(data) == 5

        # Get second page
        response = await client.get(
            "/api/v1/exercises",
            headers=auth_headers,
            params={"skip": 5, "limit": 5},
        )

        assert response.status_code == 200
        data = response.json()
        assert len(data) == 5

    async def test_list_exercises_excludes_inactive(
        self,
        client: AsyncClient,
        session: AsyncSession,
        test_user: User,
        auth_headers: dict[str, str],
    ) -> None:
        """Inactive exercises are not listed."""
        active_ex = Exercise(
            id=uuid4(),
            name="Active Exercise",
            category=ExerciseCategory.MOBILITY,
            body_part=BodyPart.KNEE,
            is_active=True,
        )
        inactive_ex = Exercise(
            id=uuid4(),
            name="Inactive Exercise",
            category=ExerciseCategory.MOBILITY,
            body_part=BodyPart.KNEE,
            is_active=False,
        )
        session.add(active_ex)
        session.add(inactive_ex)
        await session.commit()

        response = await client.get(
            "/api/v1/exercises",
            headers=auth_headers,
        )

        assert response.status_code == 200
        data = response.json()
        assert len(data) == 1
        assert data[0]["name"] == "Active Exercise"


class TestGetExercise:
    """Test GET /api/v1/exercises/{exercise_id} endpoint."""

    async def test_get_exercise_success(
        self,
        client: AsyncClient,
        session: AsyncSession,
        test_user: User,
        auth_headers: dict[str, str],
    ) -> None:
        """Get single exercise by ID."""
        exercise = Exercise(
            id=uuid4(),
            name="Test Exercise",
            description="Test description",
            category=ExerciseCategory.STRENGTH,
            body_part=BodyPart.SHOULDER,
            difficulty_level=3,
            is_active=True,
        )
        session.add(exercise)
        await session.commit()

        response = await client.get(
            f"/api/v1/exercises/{exercise.id}",
            headers=auth_headers,
        )

        assert response.status_code == 200
        data = response.json()
        assert data["id"] == str(exercise.id)
        assert data["name"] == "Test Exercise"
        assert data["description"] == "Test description"

    async def test_get_exercise_not_found(
        self,
        client: AsyncClient,
        test_user: User,
        auth_headers: dict[str, str],
    ) -> None:
        """Non-existent exercise returns 404."""
        response = await client.get(
            f"/api/v1/exercises/{uuid4()}",
            headers=auth_headers,
        )

        assert response.status_code == 404
        assert "not found" in response.json()["detail"].lower()


class TestCreateExercise:
    """Test POST /api/v1/exercises endpoint."""

    @pytest.fixture
    async def admin_user(self, session: AsyncSession) -> User:
        """Create an admin user."""
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
        """Generate auth headers for admin user."""
        token = create_access_token(admin_user.id)
        return {"Authorization": f"Bearer {token}"}

    async def test_create_exercise_as_admin(
        self,
        client: AsyncClient,
        admin_user: User,
        admin_headers: dict[str, str],
    ) -> None:
        """Admin can create exercises."""
        response = await client.post(
            "/api/v1/exercises",
            headers=admin_headers,
            json={
                "name": "New Exercise",
                "description": "A new exercise",
                "instructions": "Do this exercise",
                "category": "mobility",
                "body_part": "knee",
                "difficulty_level": 2,
            },
        )

        assert response.status_code == 201
        data = response.json()
        assert data["name"] == "New Exercise"
        assert data["category"] == "mobility"

    async def test_create_exercise_as_non_admin(
        self,
        client: AsyncClient,
        test_user: User,
        auth_headers: dict[str, str],
    ) -> None:
        """Non-admin users cannot create exercises."""
        response = await client.post(
            "/api/v1/exercises",
            headers=auth_headers,
            json={
                "name": "New Exercise",
                "description": "A new exercise",
                "category": "mobility",
                "body_part": "knee",
            },
        )

        assert response.status_code == 403

    async def test_create_exercise_invalid_difficulty(
        self,
        client: AsyncClient,
        admin_user: User,
        admin_headers: dict[str, str],
    ) -> None:
        """Invalid difficulty level is rejected."""
        response = await client.post(
            "/api/v1/exercises",
            headers=admin_headers,
            json={
                "name": "New Exercise",
                "category": "mobility",
                "body_part": "knee",
                "difficulty_level": 10,  # Max is 5
            },
        )

        assert response.status_code == 422

    async def test_create_exercise_invalid_category(
        self,
        client: AsyncClient,
        admin_user: User,
        admin_headers: dict[str, str],
    ) -> None:
        """Invalid category is rejected."""
        response = await client.post(
            "/api/v1/exercises",
            headers=admin_headers,
            json={
                "name": "New Exercise",
                "category": "invalid_category",
                "body_part": "knee",
            },
        )

        assert response.status_code == 422


class TestUpdateExercise:
    """Test PATCH /api/v1/exercises/{exercise_id} endpoint."""

    @pytest.fixture
    async def admin_user(self, session: AsyncSession) -> User:
        """Create an admin user."""
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
        """Generate auth headers for admin user."""
        token = create_access_token(admin_user.id)
        return {"Authorization": f"Bearer {token}"}

    async def test_update_exercise_as_admin(
        self,
        client: AsyncClient,
        session: AsyncSession,
        admin_user: User,
        admin_headers: dict[str, str],
    ) -> None:
        """Admin can update exercises."""
        exercise = Exercise(
            id=uuid4(),
            name="Original Name",
            category=ExerciseCategory.MOBILITY,
            body_part=BodyPart.KNEE,
            is_active=True,
        )
        session.add(exercise)
        await session.commit()

        response = await client.patch(
            f"/api/v1/exercises/{exercise.id}",
            headers=admin_headers,
            json={"name": "Updated Name", "difficulty_level": 4},
        )

        assert response.status_code == 200
        data = response.json()
        assert data["name"] == "Updated Name"
        assert data["difficulty_level"] == 4

    async def test_update_exercise_as_non_admin(
        self,
        client: AsyncClient,
        session: AsyncSession,
        test_user: User,
        auth_headers: dict[str, str],
    ) -> None:
        """Non-admin users cannot update exercises."""
        exercise = Exercise(
            id=uuid4(),
            name="Test Exercise",
            category=ExerciseCategory.MOBILITY,
            body_part=BodyPart.KNEE,
            is_active=True,
        )
        session.add(exercise)
        await session.commit()

        response = await client.patch(
            f"/api/v1/exercises/{exercise.id}",
            headers=auth_headers,
            json={"name": "Hacked Name"},
        )

        assert response.status_code == 403

    async def test_update_exercise_not_found(
        self,
        client: AsyncClient,
        admin_user: User,
        admin_headers: dict[str, str],
    ) -> None:
        """Update non-existent exercise returns 404."""
        response = await client.patch(
            f"/api/v1/exercises/{uuid4()}",
            headers=admin_headers,
            json={"name": "New Name"},
        )

        assert response.status_code == 404


class TestDeleteExercise:
    """Test DELETE /api/v1/exercises/{exercise_id} endpoint."""

    @pytest.fixture
    async def admin_user(self, session: AsyncSession) -> User:
        """Create an admin user."""
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
        """Generate auth headers for admin user."""
        token = create_access_token(admin_user.id)
        return {"Authorization": f"Bearer {token}"}

    async def test_delete_exercise_soft_delete(
        self,
        client: AsyncClient,
        session: AsyncSession,
        admin_user: User,
        admin_headers: dict[str, str],
    ) -> None:
        """Delete performs soft delete (sets is_active=False)."""
        exercise = Exercise(
            id=uuid4(),
            name="To Delete",
            category=ExerciseCategory.MOBILITY,
            body_part=BodyPart.KNEE,
            is_active=True,
        )
        session.add(exercise)
        await session.commit()

        response = await client.delete(
            f"/api/v1/exercises/{exercise.id}",
            headers=admin_headers,
        )

        assert response.status_code == 204

        # Verify soft delete
        await session.refresh(exercise)
        assert exercise.is_active is False

    async def test_delete_exercise_as_non_admin(
        self,
        client: AsyncClient,
        session: AsyncSession,
        test_user: User,
        auth_headers: dict[str, str],
    ) -> None:
        """Non-admin users cannot delete exercises."""
        exercise = Exercise(
            id=uuid4(),
            name="Test Exercise",
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

    async def test_delete_exercise_not_found(
        self,
        client: AsyncClient,
        admin_user: User,
        admin_headers: dict[str, str],
    ) -> None:
        """Delete non-existent exercise returns 404."""
        response = await client.delete(
            f"/api/v1/exercises/{uuid4()}",
            headers=admin_headers,
        )

        assert response.status_code == 404
