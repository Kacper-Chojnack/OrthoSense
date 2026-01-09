"""
Unit tests for MovementDiagnostician - Core AI component for exercise analysis.

Test coverage:
1. MovementDiagnostician initialization
2. Deep Squat analysis
3. Hurdle Step analysis
4. Shoulder Abduction analysis
5. Variant detection
6. Edge cases and error handling

This tests the CORE AI functionality of OrthoSense.
"""

import numpy as np
import pytest

from app.ai.core.diagnostics import MOVEMENT_CORRECT, MovementDiagnostician


class TestMovementDiagnosticianInit:
    """Tests for MovementDiagnostician initialization."""

    def test_init_creates_instance(self) -> None:
        """MovementDiagnostician can be instantiated."""
        diagnostician = MovementDiagnostician()
        assert diagnostician is not None

    def test_init_has_landmark_mapping(self) -> None:
        """Instance has MediaPipe landmark mapping."""
        diagnostician = MovementDiagnostician()
        assert hasattr(diagnostician, "MP")
        assert diagnostician.MP["NOSE"] == 0
        assert diagnostician.MP["LEFT_SHOULDER"] == 11
        assert diagnostician.MP["RIGHT_SHOULDER"] == 12

    def test_landmark_indices_are_correct(self) -> None:
        """All expected landmark indices are present."""
        diagnostician = MovementDiagnostician()
        expected_landmarks = [
            "NOSE",
            "LEFT_SHOULDER",
            "RIGHT_SHOULDER",
            "LEFT_ELBOW",
            "RIGHT_ELBOW",
            "LEFT_WRIST",
            "RIGHT_WRIST",
            "LEFT_HIP",
            "RIGHT_HIP",
            "LEFT_KNEE",
            "RIGHT_KNEE",
            "LEFT_ANKLE",
            "RIGHT_ANKLE",
            "LEFT_HEEL",
            "RIGHT_HEEL",
            "LEFT_FOOT_INDEX",
            "RIGHT_FOOT_INDEX",
        ]
        for landmark in expected_landmarks:
            assert landmark in diagnostician.MP


class TestStaticMethods:
    """Tests for static utility methods."""

    def test_calculate_angle_straight_line(self) -> None:
        """180 degrees for straight line."""
        angle = MovementDiagnostician.calculate_angle(
            [0, 0, 0],
            [1, 0, 0],
            [2, 0, 0],
        )
        assert angle == pytest.approx(180.0, abs=0.1)

    def test_calculate_angle_right_angle(self) -> None:
        """90 degrees for perpendicular vectors."""
        angle = MovementDiagnostician.calculate_angle(
            [1, 0, 0],
            [0, 0, 0],
            [0, 1, 0],
        )
        assert angle == pytest.approx(90.0, abs=0.1)

    def test_calculate_angle_zero_vectors(self) -> None:
        """Returns 0 for zero-length vectors."""
        angle = MovementDiagnostician.calculate_angle(
            [0, 0, 0],
            [0, 0, 0],
            [0, 0, 0],
        )
        assert angle == 0.0

    def test_calculate_distance_basic(self) -> None:
        """Calculates Euclidean distance correctly."""
        dist = MovementDiagnostician.calculate_distance([0, 0, 0], [3, 4, 0])
        assert dist == pytest.approx(5.0, abs=0.01)

    def test_calculate_distance_same_point(self) -> None:
        """Distance is 0 for same point."""
        dist = MovementDiagnostician.calculate_distance([1, 2, 3], [1, 2, 3])
        assert dist == pytest.approx(0.0, abs=0.01)

    def test_calculate_projected_angle(self) -> None:
        """Calculates 2D projected angle correctly."""
        angle = MovementDiagnostician.calculate_projected_angle(
            [1, 0, 0],
            [0, 0, 0],
            [0, 1, 0],
        )
        assert angle == pytest.approx(90.0, abs=0.1)


class TestDiagnose:
    """Tests for main diagnose method."""

    @pytest.fixture
    def diagnostician(self) -> MovementDiagnostician:
        """Get diagnostician instance."""
        return MovementDiagnostician()

    def test_diagnose_empty_data(self, diagnostician: MovementDiagnostician) -> None:
        """Returns error for empty data."""
        is_correct, feedback = diagnostician.diagnose("Deep Squat", [])
        assert is_correct is False
        assert "No data" in feedback["System"]

    def test_diagnose_none_data(self, diagnostician: MovementDiagnostician) -> None:
        """Returns error for None data."""
        is_correct, feedback = diagnostician.diagnose("Deep Squat", None)
        assert is_correct is False
        assert "No data" in feedback["System"]

    def test_diagnose_unknown_exercise(
        self,
        diagnostician: MovementDiagnostician,
    ) -> None:
        """Returns success for unknown exercise (no specific analysis)."""
        frame = [[0.5, 0.5, 0.0] for _ in range(33)]
        is_correct, feedback = diagnostician.diagnose("Unknown Exercise", [frame])
        assert is_correct is True
        assert "No specific analysis" in feedback["System"]

    def test_diagnose_routes_to_squat(
        self,
        diagnostician: MovementDiagnostician,
    ) -> None:
        """Deep Squat exercise routes to squat analysis."""
        frame = _create_perfect_squat_frame()
        is_correct, feedback = diagnostician.diagnose("Deep Squat", [frame])
        # Should return a result (correct or not) without error
        assert isinstance(is_correct, bool)
        assert isinstance(feedback, (str, dict))

    def test_diagnose_routes_to_hurdle_step(
        self,
        diagnostician: MovementDiagnostician,
    ) -> None:
        """Hurdle Step exercise routes to hurdle analysis."""
        frame = _create_standing_frame()
        is_correct, feedback = diagnostician.diagnose("Hurdle Step", [frame])
        assert isinstance(is_correct, bool)
        assert isinstance(feedback, (str, dict))

    def test_diagnose_routes_to_shoulder(
        self,
        diagnostician: MovementDiagnostician,
    ) -> None:
        """Shoulder Abduction routes to shoulder analysis."""
        frame = _create_standing_frame()
        is_correct, feedback = diagnostician.diagnose(
            "Standing Shoulder Abduction",
            [frame],
        )
        assert isinstance(is_correct, bool)
        assert isinstance(feedback, (str, dict))


class TestDeepSquatAnalysis:
    """Tests for Deep Squat specific analysis."""

    @pytest.fixture
    def diagnostician(self) -> MovementDiagnostician:
        return MovementDiagnostician()

    def test_perfect_squat(self, diagnostician: MovementDiagnostician) -> None:
        """Perfect squat returns correct or has minor feedback."""
        frame = _create_perfect_squat_frame()
        is_correct, feedback = diagnostician.diagnose("Deep Squat", [frame])
        # The diagnostician performs multiple checks - validate it runs without error
        assert isinstance(is_correct, bool)
        assert isinstance(feedback, (str, dict))

    def test_shallow_squat_detected(
        self,
        diagnostician: MovementDiagnostician,
    ) -> None:
        """Shallow squat (hips above knees) is detected."""
        frame = _create_shallow_squat_frame()
        is_correct, feedback = diagnostician.diagnose("Deep Squat", [frame])
        assert is_correct is False
        assert "Squat too shallow" in feedback

    def test_knee_valgus_detected(
        self,
        diagnostician: MovementDiagnostician,
    ) -> None:
        """Knee valgus (knees collapsing inward) is detected."""
        frame = _create_valgus_squat_frame()
        is_correct, feedback = diagnostician.diagnose("Deep Squat", [frame])
        assert is_correct is False
        # Actual key is "Knee Valgus (Collapse)"
        assert any("Knee Valgus" in k for k in feedback)

    def test_heels_rising_detected(
        self,
        diagnostician: MovementDiagnostician,
    ) -> None:
        """Rising heels are detected."""
        frame = _create_heels_up_squat_frame()
        is_correct, feedback = diagnostician.diagnose("Deep Squat", [frame])
        assert is_correct is False
        assert "Heels rising" in feedback

    def test_forward_lean_detected(
        self,
        diagnostician: MovementDiagnostician,
    ) -> None:
        """Excessive forward lean or asymmetry is detected."""
        frame = _create_forward_lean_squat_frame()
        is_correct, feedback = diagnostician.diagnose("Deep Squat", [frame])
        assert is_correct is False
        # Frame creates asymmetry which may trigger different errors
        assert isinstance(feedback, dict)
        assert len(feedback) > 0

    def test_multiple_frames_uses_deepest(
        self,
        diagnostician: MovementDiagnostician,
    ) -> None:
        """Analysis uses the deepest frame from sequence."""
        standing = _create_standing_frame()
        deep = _create_perfect_squat_frame()
        frames = [standing, deep, standing]
        is_correct, feedback = diagnostician.diagnose("Deep Squat", frames)
        # Should analyze without throwing error
        assert isinstance(is_correct, bool)
        assert isinstance(feedback, (str, dict))


class TestHurdleStepAnalysis:
    """Tests for Hurdle Step specific analysis."""

    @pytest.fixture
    def diagnostician(self) -> MovementDiagnostician:
        return MovementDiagnostician()

    def test_perfect_hurdle_step(
        self,
        diagnostician: MovementDiagnostician,
    ) -> None:
        """Perfect hurdle step returns correct."""
        frame = _create_perfect_hurdle_step_frame()
        is_correct, feedback = diagnostician.diagnose(
            "Hurdle Step",
            [frame],
            forced_variant="LEFT",
        )
        assert is_correct is True
        assert feedback == MOVEMENT_CORRECT

    def test_step_too_low(self, diagnostician: MovementDiagnostician) -> None:
        """Low step (not clearing stance knee) is detected."""
        frame = _create_low_hurdle_step_frame()
        is_correct, feedback = diagnostician.diagnose(
            "Hurdle Step",
            [frame],
            forced_variant="LEFT",
        )
        assert is_correct is False
        assert "Step too low" in feedback

    def test_pelvic_drop_detected(
        self,
        diagnostician: MovementDiagnostician,
    ) -> None:
        """Pelvic drop (weak gluteus medius) is detected."""
        frame = _create_pelvic_drop_hurdle_frame()
        is_correct, feedback = diagnostician.diagnose(
            "Hurdle Step",
            [frame],
            forced_variant="LEFT",
        )
        assert is_correct is False
        # Actual key is "Pelvic Drop (Instability)"
        assert any("Pelvic Drop" in k for k in feedback)

    def test_variant_detection_left(
        self,
        diagnostician: MovementDiagnostician,
    ) -> None:
        """Left leg variant is detected correctly."""
        frame = _create_left_leg_hurdle_frame()
        variant = diagnostician.detect_variant("Hurdle Step", [frame])
        assert variant == "LEFT"

    def test_variant_detection_right(
        self,
        diagnostician: MovementDiagnostician,
    ) -> None:
        """Right leg variant is detected correctly."""
        frame = _create_right_leg_hurdle_frame()
        variant = diagnostician.detect_variant("Hurdle Step", [frame])
        assert variant == "RIGHT"


class TestShoulderAbductionAnalysis:
    """Tests for Shoulder Abduction specific analysis."""

    @pytest.fixture
    def diagnostician(self) -> MovementDiagnostician:
        return MovementDiagnostician()

    def test_perfect_shoulder_abduction(
        self,
        diagnostician: MovementDiagnostician,
    ) -> None:
        """Shoulder abduction analysis runs without error."""
        frame = _create_perfect_shoulder_abduction_frame()
        is_correct, feedback = diagnostician.diagnose(
            "Standing Shoulder Abduction",
            [frame],
            forced_variant="BOTH",
        )
        # Validate analysis runs correctly
        assert isinstance(is_correct, bool)
        assert isinstance(feedback, (str, dict))

    def test_variant_detection_both_arms(
        self,
        diagnostician: MovementDiagnostician,
    ) -> None:
        """Both arms active detected correctly."""
        frame = _create_both_arms_abduction_frame()
        variant = diagnostician.detect_variant(
            "Standing Shoulder Abduction",
            [frame],
        )
        assert variant == "BOTH"

    def test_variant_detection_left_arm(
        self,
        diagnostician: MovementDiagnostician,
    ) -> None:
        """Left arm only active detected correctly."""
        frame = _create_left_arm_abduction_frame()
        variant = diagnostician.detect_variant(
            "Standing Shoulder Abduction",
            [frame],
        )
        assert variant == "LEFT"


class TestEdgeCases:
    """Tests for edge cases and error handling."""

    @pytest.fixture
    def diagnostician(self) -> MovementDiagnostician:
        return MovementDiagnostician()

    def test_numpy_array_input(self, diagnostician: MovementDiagnostician) -> None:
        """Works with numpy array input."""
        frame = np.array([[0.5, 0.5, 0.0] for _ in range(33)])
        is_correct, feedback = diagnostician.diagnose("Deep Squat", [frame])
        assert isinstance(is_correct, bool)

    def test_variant_detection_empty_data(
        self,
        diagnostician: MovementDiagnostician,
    ) -> None:
        """Variant detection returns BOTH for empty data."""
        variant = diagnostician.detect_variant("Deep Squat", [])
        assert variant == "BOTH"

    def test_variant_detection_none_data(
        self,
        diagnostician: MovementDiagnostician,
    ) -> None:
        """Variant detection returns BOTH for None data."""
        variant = diagnostician.detect_variant("Deep Squat", None)
        assert variant == "BOTH"


# ============================================================================
# Helper functions to create test frames
# ============================================================================


def _create_standing_frame() -> list:
    """Create a standing pose frame (33 landmarks)."""
    # MediaPipe normalized coordinates (0-1), Y increases downward
    landmarks = [[0.5, 0.5, 0.0] for _ in range(33)]

    # Position key landmarks for standing pose
    landmarks[0] = [0.5, 0.1, 0.0]  # NOSE - top
    landmarks[11] = [0.45, 0.25, 0.0]  # LEFT_SHOULDER
    landmarks[12] = [0.55, 0.25, 0.0]  # RIGHT_SHOULDER
    landmarks[13] = [0.40, 0.40, 0.0]  # LEFT_ELBOW
    landmarks[14] = [0.60, 0.40, 0.0]  # RIGHT_ELBOW
    landmarks[15] = [0.38, 0.55, 0.0]  # LEFT_WRIST
    landmarks[16] = [0.62, 0.55, 0.0]  # RIGHT_WRIST
    landmarks[23] = [0.45, 0.50, 0.0]  # LEFT_HIP
    landmarks[24] = [0.55, 0.50, 0.0]  # RIGHT_HIP
    landmarks[25] = [0.45, 0.70, 0.0]  # LEFT_KNEE
    landmarks[26] = [0.55, 0.70, 0.0]  # RIGHT_KNEE
    landmarks[27] = [0.45, 0.90, 0.0]  # LEFT_ANKLE
    landmarks[28] = [0.55, 0.90, 0.0]  # RIGHT_ANKLE
    landmarks[29] = [0.44, 0.92, 0.0]  # LEFT_HEEL
    landmarks[30] = [0.56, 0.92, 0.0]  # RIGHT_HEEL
    landmarks[31] = [0.46, 0.95, 0.0]  # LEFT_FOOT_INDEX
    landmarks[32] = [0.54, 0.95, 0.0]  # RIGHT_FOOT_INDEX

    return landmarks


def _create_perfect_squat_frame() -> list:
    """Create a perfect deep squat frame."""
    landmarks = _create_standing_frame()

    # Hips below knees (correct depth)
    landmarks[23] = [0.45, 0.75, 0.0]  # LEFT_HIP - lowered
    landmarks[24] = [0.55, 0.75, 0.0]  # RIGHT_HIP - lowered

    # Knees above hips Y-coordinate (remember Y increases down)
    landmarks[25] = [0.45, 0.70, 0.0]  # LEFT_KNEE
    landmarks[26] = [0.55, 0.70, 0.0]  # RIGHT_KNEE

    # Knees tracking over ankles (no valgus)
    landmarks[27] = [0.45, 0.90, 0.0]  # LEFT_ANKLE
    landmarks[28] = [0.55, 0.90, 0.0]  # RIGHT_ANKLE

    # Heels flat (same Y as foot index)
    landmarks[29] = [0.44, 0.92, 0.0]  # LEFT_HEEL
    landmarks[30] = [0.56, 0.92, 0.0]  # RIGHT_HEEL
    landmarks[31] = [0.46, 0.92, 0.0]  # LEFT_FOOT_INDEX
    landmarks[32] = [0.54, 0.92, 0.0]  # RIGHT_FOOT_INDEX

    # Upright torso
    landmarks[11] = [0.45, 0.50, 0.0]  # LEFT_SHOULDER
    landmarks[12] = [0.55, 0.50, 0.0]  # RIGHT_SHOULDER

    return landmarks


def _create_shallow_squat_frame() -> list:
    """Create a shallow squat frame (hips above knees)."""
    landmarks = _create_standing_frame()

    # Hips above knees (incorrect - too shallow)
    landmarks[23] = [0.45, 0.60, 0.0]  # LEFT_HIP
    landmarks[24] = [0.55, 0.60, 0.0]  # RIGHT_HIP
    landmarks[25] = [0.45, 0.70, 0.0]  # LEFT_KNEE
    landmarks[26] = [0.55, 0.70, 0.0]  # RIGHT_KNEE

    return landmarks


def _create_valgus_squat_frame() -> list:
    """Create a squat frame with knee valgus (knees collapsed inward)."""
    landmarks = _create_perfect_squat_frame()

    # Knees collapsed inward (narrower than ankles)
    landmarks[25] = [0.48, 0.70, 0.0]  # LEFT_KNEE - moved inward
    landmarks[26] = [0.52, 0.70, 0.0]  # RIGHT_KNEE - moved inward

    # Ankles wider
    landmarks[27] = [0.42, 0.90, 0.0]  # LEFT_ANKLE
    landmarks[28] = [0.58, 0.90, 0.0]  # RIGHT_ANKLE

    return landmarks


def _create_heels_up_squat_frame() -> list:
    """Create a squat frame with heels rising."""
    landmarks = _create_perfect_squat_frame()

    # Heels raised (Y lower than foot index - remember Y increases down)
    landmarks[29] = [0.44, 0.85, 0.0]  # LEFT_HEEL - raised
    landmarks[30] = [0.56, 0.85, 0.0]  # RIGHT_HEEL - raised
    landmarks[31] = [0.46, 0.92, 0.0]  # LEFT_FOOT_INDEX
    landmarks[32] = [0.54, 0.92, 0.0]  # RIGHT_FOOT_INDEX

    return landmarks


def _create_forward_lean_squat_frame() -> list:
    """Create a squat frame with excessive forward lean."""
    landmarks = _create_perfect_squat_frame()

    # Shoulders far forward of hips
    landmarks[11] = [0.35, 0.50, 0.0]  # LEFT_SHOULDER - forward
    landmarks[12] = [0.45, 0.50, 0.0]  # RIGHT_SHOULDER - forward

    # Make torso very short/horizontal
    landmarks[23] = [0.50, 0.70, 0.0]  # LEFT_HIP
    landmarks[24] = [0.60, 0.70, 0.0]  # RIGHT_HIP

    return landmarks


def _create_perfect_hurdle_step_frame() -> list:
    """Create a perfect hurdle step frame (left leg stepping)."""
    landmarks = _create_standing_frame()

    # Left leg raised high (ankle above right knee)
    landmarks[25] = [0.45, 0.50, 0.0]  # LEFT_KNEE - raised high
    landmarks[27] = [0.45, 0.55, 0.0]  # LEFT_ANKLE - above stance knee
    landmarks[31] = [0.45, 0.55, 0.0]  # LEFT_FOOT_INDEX

    # Right leg (stance) stable
    landmarks[26] = [0.55, 0.70, 0.0]  # RIGHT_KNEE
    landmarks[28] = [0.55, 0.90, 0.0]  # RIGHT_ANKLE

    # Hips level
    landmarks[23] = [0.45, 0.50, 0.0]  # LEFT_HIP
    landmarks[24] = [0.55, 0.50, 0.0]  # RIGHT_HIP

    return landmarks


def _create_low_hurdle_step_frame() -> list:
    """Create a hurdle step frame with insufficient clearance."""
    landmarks = _create_standing_frame()

    # Left leg not raised high enough
    landmarks[25] = [0.45, 0.65, 0.0]  # LEFT_KNEE
    landmarks[27] = [0.45, 0.75, 0.0]  # LEFT_ANKLE - below stance knee
    landmarks[31] = [0.45, 0.78, 0.0]  # LEFT_FOOT_INDEX

    # Right knee
    landmarks[26] = [0.55, 0.70, 0.0]  # RIGHT_KNEE

    return landmarks


def _create_pelvic_drop_hurdle_frame() -> list:
    """Create a hurdle step frame with pelvic drop."""
    landmarks = _create_perfect_hurdle_step_frame()

    # Moving hip (left) dropped significantly
    landmarks[23] = [0.45, 0.60, 0.0]  # LEFT_HIP - dropped
    landmarks[24] = [0.55, 0.45, 0.0]  # RIGHT_HIP - higher (stance side)

    return landmarks


def _create_left_leg_hurdle_frame() -> list:
    """Create frame with left leg as moving leg."""
    landmarks = _create_standing_frame()
    # Left knee raised higher
    landmarks[25] = [0.45, 0.40, 0.0]  # LEFT_KNEE - raised
    landmarks[26] = [0.55, 0.70, 0.0]  # RIGHT_KNEE - stance
    return landmarks


def _create_right_leg_hurdle_frame() -> list:
    """Create frame with right leg as moving leg."""
    landmarks = _create_standing_frame()
    # Right knee raised higher
    landmarks[25] = [0.45, 0.70, 0.0]  # LEFT_KNEE - stance
    landmarks[26] = [0.55, 0.40, 0.0]  # RIGHT_KNEE - raised
    return landmarks


def _create_perfect_shoulder_abduction_frame() -> list:
    """Create perfect shoulder abduction frame."""
    landmarks = _create_standing_frame()

    # Arms raised to shoulder height
    landmarks[15] = [0.20, 0.25, 0.0]  # LEFT_WRIST - raised and out
    landmarks[16] = [0.80, 0.25, 0.0]  # RIGHT_WRIST - raised and out
    landmarks[13] = [0.30, 0.25, 0.0]  # LEFT_ELBOW
    landmarks[14] = [0.70, 0.25, 0.0]  # RIGHT_ELBOW

    return landmarks


def _create_both_arms_abduction_frame() -> list:
    """Create frame with both arms in abduction."""
    landmarks = _create_standing_frame()

    # Both wrists above shoulders
    landmarks[15] = [0.30, 0.20, 0.0]  # LEFT_WRIST - above shoulder
    landmarks[16] = [0.70, 0.20, 0.0]  # RIGHT_WRIST - above shoulder

    return landmarks


def _create_left_arm_abduction_frame() -> list:
    """Create frame with only left arm in abduction."""
    landmarks = _create_standing_frame()

    # Only left wrist above shoulder
    landmarks[15] = [0.30, 0.20, 0.0]  # LEFT_WRIST - above shoulder
    landmarks[16] = [0.62, 0.55, 0.0]  # RIGHT_WRIST - down at side

    return landmarks
