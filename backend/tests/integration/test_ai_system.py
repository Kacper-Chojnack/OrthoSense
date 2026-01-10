"""
Integration tests for AI System.

Test coverage:
1. Full landmark analysis workflow
2. System initialization and cleanup
3. Various exercise types analysis
4. Error handling for malformed input
5. Report generation integration
"""

import numpy as np
import pytest

from app.ai.core.system import OrthoSenseSystem


class TestAISystemInitialization:
    """Tests for OrthoSenseSystem initialization."""

    def test_system_is_singleton(self) -> None:
        """OrthoSenseSystem is a singleton."""
        system1 = OrthoSenseSystem()
        system2 = OrthoSenseSystem()

        assert system1 is system2

    def test_system_initialization(self) -> None:
        """System can be initialized."""
        system = OrthoSenseSystem()

        # Initialize without model verification (for tests)
        result = system.initialize(verify_models=False)

        assert result is True
        assert system.is_initialized is True

    def test_system_close(self) -> None:
        """System can be closed and re-initialized."""
        system = OrthoSenseSystem()
        system.initialize(verify_models=False)

        system.close()

        assert system.is_initialized is False

        # Can re-initialize
        system.initialize(verify_models=False)
        assert system.is_initialized is True

    def test_system_has_engine_and_reporter(self) -> None:
        """System has engine and reporter components."""
        system = OrthoSenseSystem()

        assert system.engine is not None
        assert system.reporter is not None


class TestAnalyzeLandmarks:
    """Tests for landmark analysis workflow."""

    @pytest.fixture
    def system(self) -> OrthoSenseSystem:
        """Get initialized system."""
        system = OrthoSenseSystem()
        system.initialize(verify_models=False)
        return system

    @pytest.fixture
    def valid_landmarks(self) -> list[list[list[float]]]:
        """Create valid 33-landmark data (10 frames)."""
        # 10 frames, 33 landmarks per frame, 4 values per landmark (x, y, z, visibility)
        return [
            [[float(j * 0.01 + i * 0.001), float(j * 0.02), 0.0, 0.95]
             for j in range(33)]
            for i in range(10)
        ]

    def test_analyze_returns_expected_structure(
        self,
        system: OrthoSenseSystem,
        valid_landmarks: list[list[list[float]]],
    ) -> None:
        """Analysis returns dict with expected keys."""
        result = system.analyze_landmarks(
            valid_landmarks,
            "Standing Shoulder Abduction",
        )

        assert isinstance(result, dict)
        assert "exercise" in result
        assert "confidence" in result
        assert "is_correct" in result
        assert "feedback" in result
        assert "text_report" in result

    def test_exercise_name_preserved(
        self,
        system: OrthoSenseSystem,
        valid_landmarks: list[list[list[float]]],
    ) -> None:
        """Exercise name is preserved in output."""
        exercise_name = "Seated Knee Extension"

        result = system.analyze_landmarks(valid_landmarks, exercise_name)

        assert result["exercise"] == exercise_name

    def test_empty_landmarks_returns_error(
        self,
        system: OrthoSenseSystem,
    ) -> None:
        """Empty landmarks returns error dict."""
        result = system.analyze_landmarks([], "Any Exercise")

        assert "error" in result
        assert result["error"] == "No landmarks provided"

    def test_invalid_frame_size_handled(
        self,
        system: OrthoSenseSystem,
    ) -> None:
        """Frames with wrong number of landmarks are filtered out."""
        # Frames with only 10 landmarks instead of 33
        invalid_landmarks = [
            [[float(j * 0.01), float(j * 0.02), 0.0, 0.95] for j in range(10)]
            for i in range(5)
        ]

        result = system.analyze_landmarks(
            invalid_landmarks,
            "Standing Shoulder Abduction",
        )

        # Should return error since no valid frames
        assert "error" in result

    def test_confidence_is_numeric(
        self,
        system: OrthoSenseSystem,
        valid_landmarks: list[list[list[float]]],
    ) -> None:
        """Confidence score is numeric."""
        result = system.analyze_landmarks(
            valid_landmarks,
            "Standing Shoulder Abduction",
        )

        assert isinstance(result["confidence"], (int, float))
        assert 0.0 <= result["confidence"] <= 1.0

    def test_is_correct_is_boolean(
        self,
        system: OrthoSenseSystem,
        valid_landmarks: list[list[list[float]]],
    ) -> None:
        """is_correct is a boolean."""
        result = system.analyze_landmarks(
            valid_landmarks,
            "Standing Shoulder Abduction",
        )

        assert isinstance(result["is_correct"], bool)

    def test_feedback_is_dict(
        self,
        system: OrthoSenseSystem,
        valid_landmarks: list[list[list[float]]],
    ) -> None:
        """Feedback is a dictionary."""
        result = system.analyze_landmarks(
            valid_landmarks,
            "Standing Shoulder Abduction",
        )

        assert isinstance(result["feedback"], dict)

    def test_text_report_is_string(
        self,
        system: OrthoSenseSystem,
        valid_landmarks: list[list[list[float]]],
    ) -> None:
        """Text report is a string."""
        result = system.analyze_landmarks(
            valid_landmarks,
            "Standing Shoulder Abduction",
        )

        assert isinstance(result["text_report"], str)
        assert len(result["text_report"]) > 0


class TestExerciseTypeAnalysis:
    """Tests for different exercise types."""

    @pytest.fixture
    def system(self) -> OrthoSenseSystem:
        system = OrthoSenseSystem()
        system.initialize(verify_models=False)
        return system

    @pytest.fixture
    def realistic_pose(self) -> list[list[list[float]]]:
        """Create realistic standing pose data."""
        # Standing position - simplified but representative
        landmarks_per_frame = []

        # Create 30 frames of standing pose
        for frame_idx in range(30):
            frame = []
            for joint_idx in range(33):
                # Base position + slight variation per frame
                x = 0.5 + (joint_idx % 5) * 0.05 + frame_idx * 0.001
                y = 0.3 + (joint_idx // 5) * 0.1
                z = 0.0
                visibility = 0.95 if joint_idx < 25 else 0.7
                frame.append([x, y, z, visibility])
            landmarks_per_frame.append(frame)

        return landmarks_per_frame

    def test_shoulder_abduction_analysis(
        self,
        system: OrthoSenseSystem,
        realistic_pose: list[list[list[float]]],
    ) -> None:
        """Shoulder abduction exercise can be analyzed."""
        result = system.analyze_landmarks(
            realistic_pose,
            "Standing Shoulder Abduction",
        )

        assert "error" not in result
        assert result["exercise"] == "Standing Shoulder Abduction"

    def test_knee_extension_analysis(
        self,
        system: OrthoSenseSystem,
        realistic_pose: list[list[list[float]]],
    ) -> None:
        """Knee extension exercise can be analyzed."""
        result = system.analyze_landmarks(
            realistic_pose,
            "Seated Knee Extension",
        )

        assert "error" not in result
        assert result["exercise"] == "Seated Knee Extension"

    def test_hip_flexion_analysis(
        self,
        system: OrthoSenseSystem,
        realistic_pose: list[list[list[float]]],
    ) -> None:
        """Hip flexion exercise can be analyzed."""
        result = system.analyze_landmarks(
            realistic_pose,
            "Standing Hip Flexion",
        )

        assert "error" not in result
        assert result["exercise"] == "Standing Hip Flexion"

    def test_unknown_exercise_handled(
        self,
        system: OrthoSenseSystem,
        realistic_pose: list[list[list[float]]],
    ) -> None:
        """Unknown exercise name is handled gracefully."""
        result = system.analyze_landmarks(
            realistic_pose,
            "Unknown Exercise Type XYZ",
        )

        # Should not crash, returns some result
        assert "exercise" in result
        assert result["exercise"] == "Unknown Exercise Type XYZ"


class TestVisibilityHandling:
    """Tests for landmark visibility handling."""

    @pytest.fixture
    def system(self) -> OrthoSenseSystem:
        system = OrthoSenseSystem()
        system.initialize(verify_models=False)
        return system

    def test_low_visibility_landmarks_handled(
        self,
        system: OrthoSenseSystem,
    ) -> None:
        """Frames with low visibility joints are handled."""
        # All landmarks have low visibility
        low_vis_landmarks = [
            [[float(j * 0.01), float(j * 0.02), 0.0, 0.3]  # Low visibility
             for j in range(33)]
            for i in range(10)
        ]

        result = system.analyze_landmarks(
            low_vis_landmarks,
            "Standing Shoulder Abduction",
        )

        # Should still process (may have reduced accuracy)
        assert isinstance(result, dict)

    def test_mixed_visibility_landmarks(
        self,
        system: OrthoSenseSystem,
    ) -> None:
        """Frames with mixed visibility are processed."""
        mixed_landmarks = []
        for i in range(10):
            frame = []
            for j in range(33):
                # Key joints (11, 12, 23, 24, 25, 26, 27, 28) have high visibility
                vis = 0.95 if j in [11, 12, 23, 24, 25, 26, 27, 28] else 0.3
                frame.append([float(j * 0.01), float(j * 0.02), 0.0, vis])
            mixed_landmarks.append(frame)

        result = system.analyze_landmarks(
            mixed_landmarks,
            "Standing Shoulder Abduction",
        )

        assert "error" not in result


class TestSlidingWindowAnalysis:
    """Tests for sliding window frame analysis."""

    @pytest.fixture
    def system(self) -> OrthoSenseSystem:
        system = OrthoSenseSystem()
        system.initialize(verify_models=False)
        return system

    def test_short_sequence_analyzed(
        self,
        system: OrthoSenseSystem,
    ) -> None:
        """Short sequences (< window size) are analyzed."""
        # Only 5 frames (less than typical window of 60)
        short_landmarks = [
            [[float(j * 0.01), float(j * 0.02), 0.0, 0.95]
             for j in range(33)]
            for i in range(5)
        ]

        result = system.analyze_landmarks(
            short_landmarks,
            "Standing Shoulder Abduction",
        )

        assert "error" not in result

    def test_long_sequence_analyzed(
        self,
        system: OrthoSenseSystem,
    ) -> None:
        """Long sequences are analyzed via sliding windows."""
        # 100 frames (more than window size)
        long_landmarks = [
            [[float(j * 0.01 + i * 0.001), float(j * 0.02), 0.0, 0.95]
             for j in range(33)]
            for i in range(100)
        ]

        result = system.analyze_landmarks(
            long_landmarks,
            "Standing Shoulder Abduction",
        )

        assert "error" not in result
        assert result["exercise"] == "Standing Shoulder Abduction"
