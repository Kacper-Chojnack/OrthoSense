"""
Unit tests for ExerciseVideo model.

Test coverage:
1. ExerciseVideo model creation and defaults
2. ExerciseVideoCreate schema validation
3. ExerciseVideoRead schema serialization
4. ExerciseVideoUpdate schema
5. Field constraints
"""

from datetime import UTC, datetime
from uuid import uuid4

from app.models.exercise_video import (
    ExerciseVideo,
    ExerciseVideoBase,
    ExerciseVideoCreate,
    ExerciseVideoRead,
    ExerciseVideoUpdate,
)


class TestExerciseVideoModel:
    """Tests for ExerciseVideo SQLModel."""

    def test_exercise_video_creation_with_required_fields(self) -> None:
        """ExerciseVideo can be created with required fields."""
        exercise_id = uuid4()

        video = ExerciseVideo(
            exercise_id=exercise_id,
            title="Knee Extension Demo",
            video_url="https://example.com/video.mp4",
            duration_seconds=120,
        )

        assert video.exercise_id == exercise_id
        assert video.title == "Knee Extension Demo"
        assert video.video_url == "https://example.com/video.mp4"
        assert video.duration_seconds == 120
        assert video.description == ""
        assert video.thumbnail_url is None
        assert video.view_angle == "front"
        assert video.is_primary is False
        assert video.sort_order == 0
        assert video.is_active is True

    def test_exercise_video_creation_with_all_fields(self) -> None:
        """ExerciseVideo can be created with all fields."""
        video_id = uuid4()
        exercise_id = uuid4()
        now = datetime.now(UTC).replace(tzinfo=None)

        video = ExerciseVideo(
            id=video_id,
            exercise_id=exercise_id,
            title="Hip Flexor Stretch - Side View",
            description="Detailed demonstration from the side",
            video_url="https://cdn.example.com/hip-stretch.mp4",
            thumbnail_url="https://cdn.example.com/hip-stretch-thumb.jpg",
            duration_seconds=180,
            view_angle="side",
            is_primary=True,
            sort_order=1,
            is_active=True,
            created_at=now,
        )

        assert video.id == video_id
        assert video.view_angle == "side"
        assert video.is_primary is True
        assert video.sort_order == 1
        assert video.thumbnail_url == "https://cdn.example.com/hip-stretch-thumb.jpg"

    def test_exercise_video_id_auto_generated(self) -> None:
        """Video ID is auto-generated if not provided."""
        video = ExerciseVideo(
            exercise_id=uuid4(),
            title="Test",
            video_url="https://example.com/test.mp4",
            duration_seconds=60,
        )

        assert video.id is not None

    def test_exercise_video_created_at_auto_generated(self) -> None:
        """created_at is auto-generated."""
        video = ExerciseVideo(
            exercise_id=uuid4(),
            title="Test",
            video_url="https://example.com/test.mp4",
            duration_seconds=60,
        )

        assert video.created_at is not None


class TestExerciseVideoBaseSchema:
    """Tests for ExerciseVideoBase schema."""

    def test_video_base_valid(self) -> None:
        """Valid ExerciseVideoBase schema."""
        data = ExerciseVideoBase(
            title="Shoulder Rotation Exercise",
            description="Proper form demonstration",
            video_url="https://example.com/shoulder.mp4",
            duration_seconds=90,
            view_angle="front",
        )

        assert data.title == "Shoulder Rotation Exercise"
        assert data.duration_seconds == 90

    def test_video_base_defaults(self) -> None:
        """ExerciseVideoBase applies defaults."""
        data = ExerciseVideoBase(
            title="Test Video",
            video_url="https://example.com/test.mp4",
            duration_seconds=60,
        )

        assert data.description == ""
        assert data.thumbnail_url is None
        assert data.view_angle == "front"
        assert data.is_primary is False
        assert data.sort_order == 0


class TestExerciseVideoCreateSchema:
    """Tests for ExerciseVideoCreate schema."""

    def test_video_create_valid(self) -> None:
        """Valid ExerciseVideoCreate schema."""
        exercise_id = uuid4()

        data = ExerciseVideoCreate(
            exercise_id=exercise_id,
            title="New Exercise Video",
            video_url="https://example.com/new.mp4",
            duration_seconds=150,
        )

        assert data.exercise_id == exercise_id
        assert data.title == "New Exercise Video"

    def test_video_create_with_all_fields(self) -> None:
        """ExerciseVideoCreate with all fields."""
        data = ExerciseVideoCreate(
            exercise_id=uuid4(),
            title="Complete Demo",
            description="Full demonstration with instructions",
            video_url="https://cdn.example.com/complete.mp4",
            thumbnail_url="https://cdn.example.com/thumb.jpg",
            duration_seconds=300,
            view_angle="isometric",
            is_primary=True,
            sort_order=0,
        )

        assert data.view_angle == "isometric"
        assert data.is_primary is True


class TestExerciseVideoReadSchema:
    """Tests for ExerciseVideoRead schema."""

    def test_video_read_serialization(self) -> None:
        """ExerciseVideoRead serializes all fields."""
        video_id = uuid4()
        exercise_id = uuid4()
        now = datetime.now(UTC)

        data = ExerciseVideoRead(
            id=video_id,
            exercise_id=exercise_id,
            title="Read Test Video",
            description="Test description",
            video_url="https://example.com/read.mp4",
            thumbnail_url="https://example.com/thumb.jpg",
            duration_seconds=240,
            view_angle="back",
            is_primary=False,
            sort_order=2,
            is_active=True,
            created_at=now,
            updated_at=None,
        )

        assert data.id == video_id
        assert data.view_angle == "back"
        assert data.sort_order == 2
        assert data.is_active is True


class TestExerciseVideoUpdateSchema:
    """Tests for ExerciseVideoUpdate schema."""

    def test_video_update_partial(self) -> None:
        """ExerciseVideoUpdate allows partial updates."""
        data = ExerciseVideoUpdate(title="Updated Title")

        assert data.title == "Updated Title"
        assert data.description is None
        assert data.video_url is None
        assert data.duration_seconds is None

    def test_video_update_all_fields(self) -> None:
        """ExerciseVideoUpdate with all fields."""
        data = ExerciseVideoUpdate(
            title="Completely Updated",
            description="New description",
            video_url="https://example.com/updated.mp4",
            thumbnail_url="https://example.com/new-thumb.jpg",
            duration_seconds=180,
            view_angle="overhead",
            is_primary=True,
            sort_order=5,
            is_active=False,
        )

        assert data.title == "Completely Updated"
        assert data.view_angle == "overhead"
        assert data.is_active is False

    def test_video_update_empty(self) -> None:
        """ExerciseVideoUpdate can be empty (no changes)."""
        data = ExerciseVideoUpdate()

        assert data.title is None
        assert data.description is None
        assert data.video_url is None


class TestExerciseVideoViewAngles:
    """Tests for view_angle field values."""

    def test_common_view_angles(self) -> None:
        """Common view angles are accepted."""
        angles = ["front", "side", "back", "overhead", "isometric", "detail"]

        for angle in angles:
            video = ExerciseVideo(
                exercise_id=uuid4(),
                title=f"{angle.title()} View",
                video_url=f"https://example.com/{angle}.mp4",
                duration_seconds=60,
                view_angle=angle,
            )
            assert video.view_angle == angle


class TestExerciseVideoSortOrder:
    """Tests for sort_order behavior."""

    def test_sort_order_default(self) -> None:
        """Default sort_order is 0."""
        video = ExerciseVideo(
            exercise_id=uuid4(),
            title="Test",
            video_url="https://example.com/test.mp4",
            duration_seconds=60,
        )

        assert video.sort_order == 0

    def test_sort_order_can_be_set(self) -> None:
        """sort_order can be set to any non-negative value."""
        for order in [0, 1, 5, 10, 100]:
            video = ExerciseVideo(
                exercise_id=uuid4(),
                title=f"Video {order}",
                video_url="https://example.com/test.mp4",
                duration_seconds=60,
                sort_order=order,
            )
            assert video.sort_order == order
