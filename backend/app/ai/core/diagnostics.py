import numpy as np
from collections import Counter

class MovementDiagnostician:
    def __init__(self):
        self.J = {
            'SPINE_BASE': 0, 'SPINE_MID': 1, 'NECK': 2, 'HEAD': 3,
            'SHOULDER_L': 4, 'ELBOW_L': 5, 'WRIST_L': 6, 'HAND_L': 7,
            'SHOULDER_R': 8, 'ELBOW_R': 9, 'WRIST_R': 10, 'HAND_R': 11,
            'HIP_L': 12, 'KNEE_L': 13, 'ANKLE_L': 14, 'FOOT_L': 15,
            'HIP_R': 16, 'KNEE_R': 17, 'ANKLE_R': 18, 'FOOT_R': 19,
            'SPINE_SHOULDER': 20
        }

    def _get_coords(self, frame, joint_name):
        """
        Helper function to get joint coordinates.
        """
        return np.array(frame[self.J[joint_name]])

    @staticmethod
    def calculate_angle(a, b, c):
        """
        Calculates angle (in degrees) at point b.
        """
        a = np.array(a)
        b = np.array(b) 
        c = np.array(c)
        
        ba = a - b
        bc = c - b
        
        numerator = np.dot(ba, bc)
        denominator = np.linalg.norm(ba) * np.linalg.norm(bc)
        
        if denominator == 0: return 0.0
        
        cosine_angle = numerator / denominator
        
        cosine_angle = np.clip(cosine_angle, -1.0, 1.0)
        
        angle = np.degrees(np.arccos(cosine_angle))
        
        return angle

    @staticmethod
    def calculate_distance(a, b):
        """
        Calculates Euclidean distance between points.
        """
        return np.linalg.norm(a - b)

    def diagnose(self, exercise_name, skeleton_data, buffer=None):
        """
        Main diagnostic logic.
        """
        # --- SPECJALNA OBSŁUGA DLA PRZYSIADU (SMOOTHING) ---
        # Przysiad wymaga analizy trendu, a nie pojedynczych klatek.
        if exercise_name == "Deep Squat":
            return self._analyze_squat(skeleton_data, buffer)

        # --- OBSŁUGA POZOSTAŁYCH ĆWICZEŃ (KLATKA PO KLATCE) ---
        errors = []
        
        for frame in skeleton_data:
            if exercise_name == "Hurdle Step":
                # lateral tilt - FMS
                spine_x_diff = abs(self._get_coords(frame, 'SPINE_SHOULDER')[0] - self._get_coords(frame, 'SPINE_BASE')[0])
                if spine_x_diff > 0.12:
                    errors.append("Stability loss of the torso.")

            elif exercise_name == "Inline Lunge":
                # torso not vertical - FMS
                spine_top_x = self._get_coords(frame, 'SPINE_SHOULDER')[0]
                spine_bot_x = self._get_coords(frame, 'SPINE_BASE')[0]
                if abs(spine_top_x - spine_bot_x) > 0.15:
                    errors.append("Torso is not vertical.")

            elif exercise_name == "Side Lunge":
                # trailing leg flexion - NASM Guidelines
                ang_l = self.calculate_angle(self._get_coords(frame, 'HIP_L'), self._get_coords(frame, 'KNEE_L'), self._get_coords(frame, 'ANKLE_L'))
                ang_r = self.calculate_angle(self._get_coords(frame, 'HIP_R'), self._get_coords(frame, 'KNEE_R'), self._get_coords(frame, 'ANKLE_R'))
                
                if ang_l < 110 and ang_r < 150:
                    errors.append("Stance leg (straight leg) bent at knee.")
                elif ang_r < 110 and ang_l < 150:
                    errors.append("Stance leg (straight leg) bent at knee.")

            elif exercise_name == "Sit to Stand":
                # hands on knees - Bohannon (2006)
                dist_l = self.calculate_distance(self._get_coords(frame, 'HAND_L'), self._get_coords(frame, 'KNEE_L'))
                dist_r = self.calculate_distance(self._get_coords(frame, 'HAND_R'), self._get_coords(frame, 'KNEE_R'))
                if dist_l < 0.15 or dist_r < 0.15:
                    errors.append("Do not push off with hands from knees.")

            elif exercise_name == "Standing Active Straight Leg Raise":
                # active leg knee flexion - FMS
                if self._get_coords(frame, 'ANKLE_L')[1] > self._get_coords(frame, 'ANKLE_R')[1]:
                    active_knee = self.calculate_angle(self._get_coords(frame, 'HIP_L'), self._get_coords(frame, 'KNEE_L'), self._get_coords(frame, 'ANKLE_L'))
                else:
                    active_knee = self.calculate_angle(self._get_coords(frame, 'HIP_R'), self._get_coords(frame, 'KNEE_R'), self._get_coords(frame, 'ANKLE_R'))
                
                if active_knee < 150:
                    errors.append("Raised leg bent at knee.")

            elif exercise_name == "Standing Shoulder Abduction":
                # scapular Hiking - AAOS
                sh_l_y = self._get_coords(frame, 'SHOULDER_L')[1]
                dist_ear_sh = self.calculate_distance(self._get_coords(frame, 'HEAD'), self._get_coords(frame, 'SHOULDER_L'))
                if dist_ear_sh < 0.12:
                     errors.append("Do not shrug shoulders.")

                # arms asymmetry - NASM Guidelines
                wr_l = self._get_coords(frame, 'WRIST_L')[1]
                wr_r = self._get_coords(frame, 'WRIST_R')[1]
                if abs(wr_l - wr_r) > 0.15 and wr_l > sh_l_y: 
                    errors.append("Arm asymmetry.")

            elif exercise_name == "Standing Shoulder Extension":
                # anterior tilt - Compensatory Motion
                spine_x_diff = abs(self._get_coords(frame, 'SPINE_SHOULDER')[0] - self._get_coords(frame, 'SPINE_BASE')[0])
                if spine_x_diff > 0.15:
                    errors.append("Do not lean forward.")
                
                # elbow flexion - AAOS
                elb_l = self.calculate_angle(self._get_coords(frame, 'SHOULDER_L'), self._get_coords(frame, 'ELBOW_L'), self._get_coords(frame, 'WRIST_L'))
                if elb_l < 140:
                    errors.append("Keep elbows straight.")

            elif exercise_name == "Standing Shoulder Int/Ext Rotation":
                # abduction compensation - AAOS
                dist_el_spine = self.calculate_distance(self._get_coords(frame, 'ELBOW_L'), self._get_coords(frame, 'SPINE_MID'))
                if dist_el_spine > 0.35:
                    errors.append("Keep elbows close to body.")

            elif exercise_name == "Standing Shoulder Scaption":
                # elbow flexion - AAOS
                elb_r = self.calculate_angle(self._get_coords(frame, 'SHOULDER_R'), self._get_coords(frame, 'ELBOW_R'), self._get_coords(frame, 'WRIST_R'))
                if elb_r < 150:
                    errors.append("Straighten elbows.")

        if not errors:
            return True, "Movement correct (consistent with clinical pattern)."
        else:
            all_unique_errors = ", ".join(set(errors))
            return False, f"ERRORS: {all_unique_errors}"

    def _analyze_squat(self, skeleton_data, buffer):
        """
        Dedicated, improved squat analysis.
        """
        errors = []
        knee_depths = []
        
        for frame in skeleton_data:
            angle_knee = self.calculate_angle(
                self._get_coords(frame, 'HIP_L'), 
                self._get_coords(frame, 'KNEE_L'), 
                self._get_coords(frame, 'ANKLE_L')
            )
            knee_depths.append(angle_knee)

        min_knee_angle = min(knee_depths) if knee_depths else 180
        
        deepest_idx = knee_depths.index(min_knee_angle) if knee_depths else 0
        deepest_frame = skeleton_data[deepest_idx]

        if min_knee_angle > 100: 
            errors.append("Squat too shallow.")
            
        knee_dist = self.calculate_distance(self._get_coords(deepest_frame, 'KNEE_L'), self._get_coords(deepest_frame, 'KNEE_R'))
        ankle_dist = self.calculate_distance(self._get_coords(deepest_frame, 'ANKLE_L'), self._get_coords(deepest_frame, 'ANKLE_R'))
        
        if knee_dist < ankle_dist * 0.75:
             errors.append("Keep knees wide!")

        spine_top = self._get_coords(deepest_frame, 'SPINE_SHOULDER')
        spine_bot = self._get_coords(deepest_frame, 'SPINE_BASE')
        spine_len = self.calculate_distance(spine_top, spine_bot)
        
        lean_value = 0.0
        if spine_len > 0:
            lean_value = abs(spine_top[0] - spine_bot[0]) / spine_len

        # print(f"DEBUG: Knee Angle: {min_knee_angle:.1f} | Torso Lean: {lean_value:.2f}")

        final_lean = lean_value
        if buffer is not None:
            buffer.append(lean_value)
            final_lean = sum(buffer) / len(buffer)
        
        if final_lean > 0.70:
            errors.append("Excessive torso lean.")

        if not errors:
            return True, "Movement correct."
        else:
            return False, f"ERRORS: {', '.join(set(errors))}"

from collections import Counter

class ReportGenerator:
    def generate_report(self, analysis_results):
        """
        Generates a text summary based on a list of frame analysis results.
        """

        if not analysis_results:
            return "No exercise detected."

        total_frames = len(analysis_results)
        correct_frames = 0
        all_feedbacks = []
        exercises_detected = []

        for res in analysis_results:
            if res.get('exercise'):
                exercises_detected.append(res['exercise'])
            
            if res['is_correct']:
                correct_frames += 1
            else:
                raw_msg = res.get('feedback', "")
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
            most_common_issue, count = issue_counts.most_common(1)[0]
            main_issue = most_common_issue

        report = f"Exercise Analysis: {main_exercise}\n"
        report += f"Technique Score: {score_percent:.1f}% correct form.\n\n"

        if score_percent > 90:
            report += "Conclusion: Excellent form! Your technique is solid. Keep it up!"
        elif score_percent > 60:
            if main_issue:
                report += f"Main Issue: While your form is generally good, the most frequent error was: '{main_issue}'.\n"
                report += "Recommendation: Focus on stabilizing this specific element."
            else:
                report += "Conclusion: Good form with minor inconsistencies."
        else:
            if main_issue:
                report += f"Conclusion: Significant technique issues detected.\n"
                report += f"Primary Error: '{main_issue}'.\n"
                report += "Recommendation: We recommend lowering the weight/intensity and practicing the movement pattern in front of a mirror."
            else:
                report += "Conclusion: Technique needs improvement. Please review the exercise instructions."

        return report