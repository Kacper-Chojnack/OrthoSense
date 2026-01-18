"""
E2E Tests for Exercise Session Flow.

Complete end-to-end tests for exercise session creation, recording,
analysis submission, and completion workflows.
"""

import random
from datetime import UTC, datetime
from uuid import uuid4

import pytest
from httpx import AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.security import hash_password
from app.models.exercise import BodyPart, Exercise, ExerciseCategory
from app.models.session import Session, SessionStatus
from app.models.user import User, UserRole

pytestmark = pytest.mark.asyncio


def _generate_fake_pose_landmarks(quality: int = 95) -> dict:
    """
    Generate fake MediaPipe pose landmarks for testing.

    Args:
        quality: Quality percentage (0-100), affects noise and visibility.

    Returns:
        Dictionary with list of 33 landmarks (BlazePose topology).
    """
    landmarks = []
    noise_factor = (100 - quality) / 100

    for i in range(33):
        noise = random.uniform(0, noise_factor * 0.1)
        landmarks.append(
            {
                "x": 0.5 + (0.02 * (i % 10)) - noise,
                "y": 0.2 + (0.025 * i) - noise,
                "z": random.uniform(-0.1, 0.1),
                "visibility": quality / 100 - random.uniform(0, noise_factor * 0.2),
            }
        )

    return {"landmarks": landmarks}


class TestExerciseSessionFlowE2E:
    """E2E tests: Complete exercise session workflows."""

    async def test_complete_exercise_session_flow(
        self,
        client: AsyncClient,
        session: AsyncSession,
    ) -> None:
        """
        E2E: Complete exercise session flow.

        Flow:
        1. User authenticates
        2. User views available exercises
        3. User creates exercise session
        4. User starts the session
        5. User submits exercise results
        6. User completes the session
        7. User views session details
        """
        # === SETUP ===
        user = User(
            id=uuid4(),
            email="e2e_exercise@test.com",
            hashed_password=hash_password("SecurePass123!"),
            role=UserRole.PATIENT,
            is_active=True,
            is_verified=True,
        )
        session.add(user)

        exercise = Exercise(
            id=uuid4(),
            name="E2E Test Squat",
            category=ExerciseCategory.MOBILITY,
            body_part=BodyPart.KNEE,
            difficulty_level=3,
            is_active=True,
        )
        session.add(exercise)
        await session.commit()

        # === STEP 1: AUTHENTICATE ===
        login_response = await client.post(
            "/api/v1/auth/login",
            data={
                "username": "e2e_exercise@test.com",
                "password": "SecurePass123!",
            },
        )
        assert login_response.status_code == 200
        token = login_response.json()["access_token"]
        auth_headers = {"Authorization": f"Bearer {token}"}

        # === STEP 2: VIEW EXERCISES ===
        exercises_response = await client.get(
            "/api/v1/exercises",
            headers=auth_headers,
        )
        assert exercises_response.status_code == 200
        exercises_data = exercises_response.json()
        assert len(exercises_data) >= 1
        assert any(e["name"] == "E2E Test Squat" for e in exercises_data)

        # === STEP 3: CREATE SESSION ===
        scheduled_date = datetime.now(UTC).isoformat()
        create_response = await client.post(
            "/api/v1/sessions",
            headers=auth_headers,
            json={
                "scheduled_date": scheduled_date,
                "notes": "E2E test session for exercise flow",
            },
        )
        assert create_response.status_code == 201
        session_data = create_response.json()
        session_id = session_data["id"]
        assert session_data["status"] == "in_progress"

        # === STEP 4: START SESSION ===
        start_response = await client.post(
            f"/api/v1/sessions/{session_id}/start",
            headers=auth_headers,
            json={
                "pain_level_before": 3,
                "device_info": {
                    "os": "Android",
                    "version": "14",
                    "model": "E2E Test Device",
                },
            },
        )
        assert start_response.status_code == 200
        started_session = start_response.json()
        assert started_session["pain_level_before"] == 3
        assert started_session["started_at"] is not None

        # === STEP 5: SUBMIT EXERCISE RESULT ===
        result_response = await client.post(
            f"/api/v1/sessions/{session_id}/results",
            headers=auth_headers,
            json={
                "exercise_id": str(exercise.id),
                "sets_completed": 3,
                "reps_completed": 12,
                "score": 92.5,
            },
        )
        assert result_response.status_code == 201
        result_data = result_response.json()
        assert result_data["score"] == 92.5
        assert result_data["reps_completed"] == 12

        # === STEP 6: COMPLETE SESSION ===
        complete_response = await client.post(
            f"/api/v1/sessions/{session_id}/complete",
            headers=auth_headers,
            json={
                "pain_level_after": 2,
                "notes": "Felt good after exercises!",
            },
        )
        assert complete_response.status_code == 200
        completed_session = complete_response.json()
        assert completed_session["status"] == "completed"
        assert completed_session["pain_level_after"] == 2
        assert completed_session["overall_score"] == 92.5

        # === STEP 7: VIEW SESSION DETAILS ===
        detail_response = await client.get(
            f"/api/v1/sessions/{session_id}",
            headers=auth_headers,
        )
        assert detail_response.status_code == 200
        detail_data = detail_response.json()
        assert detail_data["status"] == "completed"
        assert "exercise_results" in detail_data
        assert len(detail_data["exercise_results"]) == 1

    async def test_session_history_listing(
        self,
        client: AsyncClient,
        session: AsyncSession,
    ) -> None:
        """E2E: User can view their session history."""
        # SETUP
        user = User(
            id=uuid4(),
            email="e2e_history@test.com",
            hashed_password=hash_password("SecurePass123!"),
            role=UserRole.PATIENT,
            is_active=True,
            is_verified=True,
        )
        session.add(user)

        # Create multiple sessions
        for i in range(5):
            sess = Session(
                id=uuid4(),
                patient_id=user.id,
                scheduled_date=datetime.now(UTC),
                status=SessionStatus.COMPLETED if i < 3 else SessionStatus.IN_PROGRESS,
                overall_score=80.0 + i * 3,
            )
            session.add(sess)

        await session.commit()

        # Authenticate
        login_response = await client.post(
            "/api/v1/auth/login",
            data={
                "username": "e2e_history@test.com",
                "password": "SecurePass123!",
            },
        )
        token = login_response.json()["access_token"]
        headers = {"Authorization": f"Bearer {token}"}

        # STEP: Get session list
        list_response = await client.get(
            "/api/v1/sessions",
            headers=headers,
        )

        # VERIFY
        assert list_response.status_code == 200
        sessions_list = list_response.json()
        assert len(sessions_list) == 5

        # STEP: Filter by status
        completed_response = await client.get(
            "/api/v1/sessions?status_filter=completed",
            headers=headers,
        )
        assert completed_response.status_code == 200
        completed_sessions = completed_response.json()
        assert len(completed_sessions) == 3

    async def test_cannot_access_other_users_session(
        self,
        client: AsyncClient,
        session: AsyncSession,
    ) -> None:
        """E2E: Users cannot access sessions belonging to other users."""
        # SETUP: Create two users
        user1 = User(
            id=uuid4(),
            email="e2e_user1@test.com",
            hashed_password=hash_password("SecurePass123!"),
            role=UserRole.PATIENT,
            is_active=True,
            is_verified=True,
        )
        user2 = User(
            id=uuid4(),
            email="e2e_user2@test.com",
            hashed_password=hash_password("SecurePass123!"),
            role=UserRole.PATIENT,
            is_active=True,
            is_verified=True,
        )
        session.add_all([user1, user2])

        # User1's session
        user1_session = Session(
            id=uuid4(),
            patient_id=user1.id,
            scheduled_date=datetime.now(UTC),
            status=SessionStatus.IN_PROGRESS,
        )
        session.add(user1_session)
        await session.commit()

        # STEP: User2 tries to access User1's session
        login_response = await client.post(
            "/api/v1/auth/login",
            data={
                "username": "e2e_user2@test.com",
                "password": "SecurePass123!",
            },
        )
        token = login_response.json()["access_token"]
        headers = {"Authorization": f"Bearer {token}"}

        access_response = await client.get(
            f"/api/v1/sessions/{user1_session.id}",
            headers=headers,
        )

        # VERIFY: Access denied
        assert access_response.status_code == 403

    async def test_skip_session_flow(
        self,
        client: AsyncClient,
        session: AsyncSession,
    ) -> None:
        """E2E: User can skip a session with a reason."""
        # SETUP
        user = User(
            id=uuid4(),
            email="e2e_skip@test.com",
            hashed_password=hash_password("SecurePass123!"),
            role=UserRole.PATIENT,
            is_active=True,
            is_verified=True,
        )
        session.add(user)

        sess = Session(
            id=uuid4(),
            patient_id=user.id,
            scheduled_date=datetime.now(UTC),
            status=SessionStatus.IN_PROGRESS,
        )
        session.add(sess)
        await session.commit()

        # Authenticate
        login_response = await client.post(
            "/api/v1/auth/login",
            data={
                "username": "e2e_skip@test.com",
                "password": "SecurePass123!",
            },
        )
        token = login_response.json()["access_token"]
        headers = {"Authorization": f"Bearer {token}"}

        # STEP: Skip session
        skip_response = await client.post(
            f"/api/v1/sessions/{sess.id}/skip?reason=Feeling%20unwell",
            headers=headers,
        )

        # VERIFY
        assert skip_response.status_code == 200
        skipped_session = skip_response.json()
        assert skipped_session["status"] == "skipped"
        assert "unwell" in skipped_session["notes"].lower()


class TestExerciseAnalysisE2E:
    """E2E tests: Exercise analysis endpoints.

    Note: /analysis/landmarks endpoint was removed as part of the
    offline-first architecture. All movement analysis is performed
    client-side using Edge AI (ML Kit + TFLite).
    """

    async def test_list_available_exercises(
        self,
        client: AsyncClient,
    ) -> None:
        """E2E: Can list available exercises for analysis."""
        response = await client.get("/api/v1/analysis/exercises")

        assert response.status_code == 200
        data = response.json()
        assert "exercises" in data
        assert len(data["exercises"]) > 0


class TestMultipleExerciseResultsE2E:
    """E2E tests: Sessions with multiple exercises."""

    async def test_submit_multiple_exercise_results(
        self,
        client: AsyncClient,
        session: AsyncSession,
    ) -> None:
        """E2E: User can submit results for multiple exercises in one session."""
        # SETUP
        user = User(
            id=uuid4(),
            email="e2e_multi@test.com",
            hashed_password=hash_password("SecurePass123!"),
            role=UserRole.PATIENT,
            is_active=True,
            is_verified=True,
        )
        session.add(user)

        exercises = [
            Exercise(
                id=uuid4(),
                name=f"E2E Exercise {i}",
                category=ExerciseCategory.MOBILITY,
                body_part=BodyPart.KNEE,
                difficulty_level=i + 1,
                is_active=True,
            )
            for i in range(3)
        ]
        session.add_all(exercises)
        await session.commit()

        # Authenticate
        login_response = await client.post(
            "/api/v1/auth/login",
            data={
                "username": "e2e_multi@test.com",
                "password": "SecurePass123!",
            },
        )
        token = login_response.json()["access_token"]
        headers = {"Authorization": f"Bearer {token}"}

        # Create session
        create_response = await client.post(
            "/api/v1/sessions",
            headers=headers,
            json={
                "scheduled_date": datetime.now(UTC).isoformat(),
                "notes": "Multi-exercise session",
            },
        )
        session_id = create_response.json()["id"]

        # Start session
        await client.post(
            f"/api/v1/sessions/{session_id}/start",
            headers=headers,
            json={"pain_level_before": 2, "device_info": {}},
        )

        # STEP: Submit results for each exercise
        scores = []
        for i, exercise in enumerate(exercises):
            score = 85.0 + (i * 5)
            scores.append(score)

            result_response = await client.post(
                f"/api/v1/sessions/{session_id}/results",
                headers=headers,
                json={
                    "exercise_id": str(exercise.id),
                    "sets_completed": 3,
                    "reps_completed": 10 + i,
                    "score": score,
                },
            )
            assert result_response.status_code == 201

        # Complete session
        complete_response = await client.post(
            f"/api/v1/sessions/{session_id}/complete",
            headers=headers,
            json={"pain_level_after": 1, "notes": "Great session!"},
        )

        # VERIFY: Overall score is average
        assert complete_response.status_code == 200
        completed = complete_response.json()
        expected_avg = sum(scores) / len(scores)
        assert completed["overall_score"] == pytest.approx(expected_avg, rel=0.01)

        # VERIFY: All results in session detail
        detail_response = await client.get(
            f"/api/v1/sessions/{session_id}",
            headers=headers,
        )
        detail = detail_response.json()
        assert len(detail["exercise_results"]) == 3


class TestPaginationE2E:
    """E2E tests: Pagination and filtering."""

    async def test_session_pagination(
        self,
        client: AsyncClient,
        session: AsyncSession,
    ) -> None:
        """E2E: Session listing supports pagination."""
        # SETUP: Create user with many sessions
        user = User(
            id=uuid4(),
            email="e2e_pagination@test.com",
            hashed_password=hash_password("SecurePass123!"),
            role=UserRole.PATIENT,
            is_active=True,
            is_verified=True,
        )
        session.add(user)

        # Create 25 sessions
        for i in range(25):
            sess = Session(
                id=uuid4(),
                patient_id=user.id,
                scheduled_date=datetime.now(UTC),
                status=SessionStatus.COMPLETED,
                overall_score=70.0 + i,
            )
            session.add(sess)
        await session.commit()

        # Authenticate
        login_response = await client.post(
            "/api/v1/auth/login",
            data={
                "username": "e2e_pagination@test.com",
                "password": "SecurePass123!",
            },
        )
        token = login_response.json()["access_token"]
        headers = {"Authorization": f"Bearer {token}"}

        # STEP: Get first page
        page1_response = await client.get(
            "/api/v1/sessions?skip=0&limit=10",
            headers=headers,
        )
        assert page1_response.status_code == 200
        page1 = page1_response.json()
        assert len(page1) == 10

        # STEP: Get second page
        page2_response = await client.get(
            "/api/v1/sessions?skip=10&limit=10",
            headers=headers,
        )
        assert page2_response.status_code == 200
        page2 = page2_response.json()
        assert len(page2) == 10

        # VERIFY: Different sessions on different pages
        page1_ids = {s["id"] for s in page1}
        page2_ids = {s["id"] for s in page2}
        assert page1_ids.isdisjoint(page2_ids)
