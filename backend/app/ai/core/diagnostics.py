from collections import Counter

import numpy as np

# Constants for feedback messages
MOVEMENT_CORRECT = "Movement correct."


class MovementDiagnostician:
    """
    Diagnoses movement quality using MediaPipe 33 landmarks.
    """

    def __init__(self):
        self.MP = {
            "NOSE": 0,
            "LEFT_SHOULDER": 11,
            "RIGHT_SHOULDER": 12,
            "LEFT_ELBOW": 13,
            "RIGHT_ELBOW": 14,
            "LEFT_WRIST": 15,
            "RIGHT_WRIST": 16,
            "LEFT_HIP": 23,
            "RIGHT_HIP": 24,
            "LEFT_KNEE": 25,
            "RIGHT_KNEE": 26,
            "LEFT_ANKLE": 27,
            "RIGHT_ANKLE": 28,
        }

    def _get_coords(self, frame, joint_name):
        return np.array(frame[self.MP[joint_name]])

    @staticmethod
    def calculate_angle(a, b, c):
        a, b, c = np.array(a), np.array(b), np.array(c)
        ba = a - b
        bc = c - b

        denom = np.linalg.norm(ba) * np.linalg.norm(bc)
        if denom == 0:
            return 0.0

        cosine = np.clip(np.dot(ba, bc) / denom, -1.0, 1.0)
        return np.degrees(np.arccos(cosine))

    @staticmethod
    def calculate_distance(a, b):
        return np.linalg.norm(np.array(a) - np.array(b))

    @staticmethod
    def calculate_projected_angle(a, b, c):
        """
        Calculates angle in 2D plane (ignoring depth) usually for Frontal Plane Projection Angle (FPPA).
        Points are [x, y, z]. We use x, y.
        """
        a = np.array([a[0], a[1]])
        b = np.array([b[0], b[1]])
        c = np.array([c[0], c[1]])

        ba = a - b
        bc = c - b

        cosine_angle = np.dot(ba, bc) / (np.linalg.norm(ba) * np.linalg.norm(bc))
        angle = np.degrees(np.arccos(np.clip(cosine_angle, -1.0, 1.0)))
        return angle

    def diagnose(self, exercise_name, skeleton_data):
        if skeleton_data is None or len(skeleton_data) == 0:
            return True, "No data to analyze."

        if exercise_name == "Deep Squat":
            return self._analyze_squat(skeleton_data)

        if exercise_name == "Standing Shoulder Abduction":
            return self._analyze_shoulder_abduction(skeleton_data)

        if exercise_name == "Hurdle Step":
            return self._analyze_hurdle_step(skeleton_data)

        return True, "Movement recorded."

    def _analyze_squat(self, skeleton_data):
        """
        Deep Squat Analysis based on:
        1. Depth (Hip crease below knee top)
        2. Dynamic Knee Valgus (FPPA) - Munro et al.
        3. Trunk Flexion (Torso Lean)
        """
        errors = []
        max_hip_y = float("-inf")
        deepest_frame_idx = 0

        for i, frame in enumerate(skeleton_data):
            hip_y = (frame[self.MP["LEFT_HIP"]][1] + frame[self.MP["RIGHT_HIP"]][1]) / 2
            if hip_y > max_hip_y:
                max_hip_y = hip_y
                deepest_frame_idx = i

        deepest_frame = skeleton_data[deepest_frame_idx]

        knee_angle_l = self.calculate_angle(
            self._get_coords(deepest_frame, "LEFT_HIP"),
            self._get_coords(deepest_frame, "LEFT_KNEE"),
            self._get_coords(deepest_frame, "LEFT_ANKLE"),
        )
        knee_angle_r = self.calculate_angle(
            self._get_coords(deepest_frame, "RIGHT_HIP"),
            self._get_coords(deepest_frame, "RIGHT_KNEE"),
            self._get_coords(deepest_frame, "RIGHT_ANKLE"),
        )

        min_knee_angle = min(knee_angle_l, knee_angle_r)

        if min_knee_angle > 100:
            errors.append("Squat too shallow (hips not low enough).")

        # dynamic valgus
        valgus_angle_l = self.calculate_projected_angle(
            self._get_coords(deepest_frame, "LEFT_HIP"),
            self._get_coords(deepest_frame, "LEFT_KNEE"),
            self._get_coords(deepest_frame, "LEFT_ANKLE"),
        )
        valgus_angle_r = self.calculate_projected_angle(
            self._get_coords(deepest_frame, "RIGHT_HIP"),
            self._get_coords(deepest_frame, "RIGHT_KNEE"),
            self._get_coords(deepest_frame, "RIGHT_ANKLE"),
        )

        if valgus_angle_l < 165 or valgus_angle_r < 165:
            errors.append("Knee Valgus detected (knees caving in).")

        # torso lean
        shoulder_mid = (
            self._get_coords(deepest_frame, "LEFT_SHOULDER")
            + self._get_coords(deepest_frame, "RIGHT_SHOULDER")
        ) / 2
        hip_mid = (
            self._get_coords(deepest_frame, "LEFT_HIP")
            + self._get_coords(deepest_frame, "RIGHT_HIP")
        ) / 2

        spine_len = self.calculate_distance(shoulder_mid, hip_mid)
        if spine_len > 0:
            lean_ratio = abs(shoulder_mid[0] - hip_mid[0]) / spine_len  # lateral shift
            if lean_ratio > 0.15:
                errors.append("Torso instability (lateral shift).")

        if not errors:
            return True, MOVEMENT_CORRECT
        return False, f"ERRORS: {', '.join(set(errors))}"

    def _analyze_hurdle_step(self, skeleton_data):
        """
        Analyzes Hurdle Step at the point of maximum hip flexion (highest knee point).
        Focuses on: Pelvic Stability (Trendelenburg) and Torso Stability.
        """
        errors = []

        min_knee_y = float("inf")
        peak_frame_idx = 0

        for i, frame in enumerate(skeleton_data):
            knee_l_y = frame[self.MP["LEFT_KNEE"]][1]
            knee_r_y = frame[self.MP["RIGHT_KNEE"]][1]
            current_min = min(knee_l_y, knee_r_y)

            if current_min < min_knee_y:
                min_knee_y = current_min
                peak_frame_idx = i

        peak_frame = skeleton_data[peak_frame_idx]

        hip_l = self._get_coords(peak_frame, "LEFT_HIP")
        hip_r = self._get_coords(peak_frame, "RIGHT_HIP")

        # pelvic stability
        pelvis_width = abs(hip_l[0] - hip_r[0])
        if pelvis_width > 0:
            tilt = abs(hip_l[1] - hip_r[1]) / pelvis_width
            if tilt > 0.15:
                errors.append("Pelvic instability.")

        # torso lean
        shoulder_mid = (
            self._get_coords(peak_frame, "LEFT_SHOULDER")
            + self._get_coords(peak_frame, "RIGHT_SHOULDER")
        ) / 2
        hip_mid = (hip_l + hip_r) / 2
        spine_x_diff = abs(shoulder_mid[0] - hip_mid[0])

        if pelvis_width > 0 and (spine_x_diff / pelvis_width) > 0.20:
            errors.append("Torso lean.")

        if not errors:
            return True, MOVEMENT_CORRECT
        return False, f"ERRORS: {', '.join(set(errors))}"

    def _analyze_shoulder_abduction(self, skeleton_data):
        error_counts = Counter()
        frames_analyzed = 0

        for frame in skeleton_data:
            wrist_l_y = frame[self.MP["LEFT_WRIST"]][1]
            elbow_l_y = frame[self.MP["LEFT_ELBOW"]][1]
            if wrist_l_y > elbow_l_y:
                continue

            frames_analyzed += 1

            nose = self._get_coords(frame, "NOSE")
            sh_l = self._get_coords(frame, "LEFT_SHOULDER")
            sh_r = self._get_coords(frame, "RIGHT_SHOULDER")
            hip_mid = (
                self._get_coords(frame, "LEFT_HIP")
                + self._get_coords(frame, "RIGHT_HIP")
            ) / 2
            sh_mid = (sh_l + sh_r) / 2

            # shrugging
            shoulder_width = self.calculate_distance(sh_l, sh_r)
            dist_nose_sh_l = self.calculate_distance(nose, sh_l)
            dist_nose_sh_r = self.calculate_distance(nose, sh_r)

            if shoulder_width > 0 and (
                (dist_nose_sh_l / shoulder_width) < 0.40
                or (dist_nose_sh_r / shoulder_width) < 0.40
            ):
                error_counts["Shoulder elevation (Shrugging)"] += 1

            # trunk compensation (lateral lean)
            spine_vec = sh_mid - hip_mid
            spine_vec_2d = spine_vec[:2]

            vertical_vec = np.array([0, -1])
            norm_spine = np.linalg.norm(spine_vec_2d)

            if norm_spine > 0:
                cosine = np.dot(spine_vec_2d, vertical_vec) / norm_spine
                angle_trunk = np.degrees(np.arccos(np.clip(cosine, -1.0, 1.0)))

                if angle_trunk > 15:
                    error_counts["Excessive trunk lean"] += 1

            # arm asymmetry
            wr_l = self._get_coords(frame, "LEFT_WRIST")
            wr_r = self._get_coords(frame, "RIGHT_WRIST")
            if abs(wr_l[1] - wr_r[1]) > 0.15 and wr_l[1] < sh_l[1]:
                error_counts["Arm asymmetry"] += 1

        threshold = frames_analyzed * 0.3
        final_errors = [k for k, v in error_counts.items() if v > threshold]

        if not final_errors:
            return True, MOVEMENT_CORRECT
        return False, f"ERRORS: {', '.join(final_errors)}"


class ReportGenerator:
    def generate_report(self, analysis_results):
        if not analysis_results:
            return "No exercise detected."

        total_frames = len(analysis_results)
        correct_frames = 0
        all_feedbacks = []
        exercises_detected = []

        for res in analysis_results:
            if res.get("exercise"):
                exercises_detected.append(res["exercise"])

            if res["is_correct"]:
                correct_frames += 1
            else:
                raw_msg = res.get("feedback", "")
                clean_msg = raw_msg.replace("ERRORS:", "").strip()
                if clean_msg:
                    all_feedbacks.append(clean_msg)

        if total_frames == 0:
            return "Insufficient data for analysis."

        score_percent = (correct_frames / total_frames) * 100

        if exercises_detected:
            main_exercise = Counter(exercises_detected).most_common(1)[0][0]
        else:
            main_exercise = "Unknown Exercise"

        main_issue = None
        if all_feedbacks:
            issue_counts = Counter(all_feedbacks)
            main_issue = issue_counts.most_common(1)[0][0]

        report = f"Exercise Analysis: {main_exercise}\n"
        report += f"Technique Score: {score_percent:.1f}% correct form.\n\n"

        if score_percent > 90:
            report += "Conclusion: Excellent form!"
        elif score_percent > 60:
            if main_issue:
                report += f"Main Issue: '{main_issue}'.\n"
                report += "Focus on stabilizing this element."
            else:
                report += "Good form with minor inconsistencies."
        else:
            if main_issue:
                report += f"Primary Error: '{main_issue}'.\n"
                report += "Lower intensity and practice the pattern."
            else:
                report += "Technique needs improvement."

        return report
