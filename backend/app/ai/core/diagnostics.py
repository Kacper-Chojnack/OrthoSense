from collections import Counter

import numpy as np

MOVEMENT_CORRECT = "Movement correct."

class MovementDiagnostician:
    """
    Diagnoses movement quality using MediaPipe 33 landmarks.
    """

    def __init__(self):
        self.MP = {
            "NOSE": 0, "LEFT_SHOULDER": 11, "RIGHT_SHOULDER": 12,
            "LEFT_ELBOW": 13, "RIGHT_ELBOW": 14, "LEFT_WRIST": 15, "RIGHT_WRIST": 16,
            "LEFT_HIP": 23, "RIGHT_HIP": 24, "LEFT_KNEE": 25, "RIGHT_KNEE": 26,
            "LEFT_ANKLE": 27, "RIGHT_ANKLE": 28, "LEFT_HEEL": 29, "RIGHT_HEEL": 30,
            "LEFT_FOOT_INDEX": 31, "RIGHT_FOOT_INDEX": 32
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

    def detect_variant(self, exercise_name, buffer_data):
        """
        Analyzes a buffer of frames (e.g., from the first 5 seconds) 
        to determine active side.
        """
        if buffer_data is None or len(buffer_data) == 0:
            return "BOTH"

        if exercise_name == "Standing Shoulder Abduction":
            min_l = float('inf'); min_r = float('inf')
            ref_l = float('inf'); ref_r = float('inf')

            for frame in buffer_data:
                ly = float(frame[self.MP["LEFT_WRIST"]][1])
                ry = float(frame[self.MP["RIGHT_WRIST"]][1])
                ls = float(frame[self.MP["LEFT_SHOULDER"]][1])
                rs = float(frame[self.MP["RIGHT_SHOULDER"]][1])
                if ly < min_l: min_l = ly
                if ry < min_r: min_r = ry
                if ls < ref_l: ref_l = ls
                if rs < ref_r: ref_r = rs

            l_active = min_l < ref_l
            r_active = min_r < ref_r

            if l_active and r_active: return "BOTH"
            if l_active: return "LEFT"
            if r_active: return "RIGHT"
            return "BOTH" 

        elif exercise_name == "Hurdle Step":
            min_l_knee = float('inf')
            min_r_knee = float('inf')
            for frame in buffer_data:
                ly = float(frame[self.MP["LEFT_KNEE"]][1])
                ry = float(frame[self.MP["RIGHT_KNEE"]][1])
                if ly < min_l_knee: min_l_knee = ly
                if ry < min_r_knee: min_r_knee = ry
            
            if min_l_knee < min_r_knee: return "LEFT"
            else: return "RIGHT"

        return "BOTH" 

    def diagnose(self, exercise_name, skeleton_data, forced_variant=None):
        """
        Real-time analysis entry point.
        If 'forced_variant' is provided (from calibration), it skips detection.
        'skeleton_data' can be a single frame (list of 1) or a batch.
        """
        if skeleton_data is None or len(skeleton_data) == 0:
            return False, {"System": "No data."}

        current_variant = forced_variant
        if current_variant is None:
            current_variant = self.detect_variant(exercise_name, skeleton_data)

        if exercise_name == "Deep Squat":
            return self._analyze_squat(skeleton_data)
        elif exercise_name == "Standing Shoulder Abduction":
            return self._analyze_shoulder_abduction(skeleton_data, current_variant)
        elif exercise_name == "Hurdle Step":
            return self._analyze_hurdle_step(skeleton_data, current_variant)

        return True, {"System": "No specific analysis."}

    def _analyze_squat(self, skeleton_data):
        """
        Analyzes the Deep Squat movement based on NASM and FMS standards.
        Assumes Frontal View.

        Medical & Biomechanical References:
        1. Cook, G., et al. (2010). "Functional Movement Systems".
           - Criteria: Femur below horizontal, heels flat, knees aligned over feet.
           - Foot alignment: Excessive external rotation (>30 deg) indicates ankle restriction.
        2. Myer, G. D., et al. (2014). "The mechanism of the valgus collapse".
           - ACL injury risk assessment via knee kinematics.
        3. Schoenfeld, B. J. (2010). "Squatting kinematics and kinetics".
           - Importance of maintaining an upright torso (parallel to tibia).

        Key Analysis Points:
        - Depth: Hips below knees.
        - Alignment: Knees tracking over toes (No Valgus).
        - Stability: Heels flat, Torso upright (not collapsing forward), No excessive foot turnout.
        """
        errors = {}
        
        max_hip_y = float("-inf")
        deepest_frame = None

        for frame in skeleton_data:
            hip_y = float((frame[self.MP["LEFT_HIP"]][1] + frame[self.MP["RIGHT_HIP"]][1]) / 2)
            if hip_y > max_hip_y:
                max_hip_y = hip_y
                deepest_frame = frame

        if deepest_frame is None:
            return False, "No movement detected"

        hip_l = self._get_coords(deepest_frame, "LEFT_HIP")
        hip_r = self._get_coords(deepest_frame, "RIGHT_HIP")
        knee_l = self._get_coords(deepest_frame, "LEFT_KNEE")
        knee_r = self._get_coords(deepest_frame, "RIGHT_KNEE")
        ankle_l = self._get_coords(deepest_frame, "LEFT_ANKLE")
        ankle_r = self._get_coords(deepest_frame, "RIGHT_ANKLE")
        heel_l = self._get_coords(deepest_frame, "LEFT_HEEL")
        heel_r = self._get_coords(deepest_frame, "RIGHT_HEEL")
        foot_l = self._get_coords(deepest_frame, "LEFT_FOOT_INDEX") 
        foot_r = self._get_coords(deepest_frame, "RIGHT_FOOT_INDEX")
        sh_l = self._get_coords(deepest_frame, "LEFT_SHOULDER")
        sh_r = self._get_coords(deepest_frame, "RIGHT_SHOULDER")

        #depth analysis
        hips_y_avg = float((hip_l[1] + hip_r[1]) / 2)
        knees_y_avg = float((knee_l[1] + knee_r[1]) / 2)
        
        if hips_y_avg < knees_y_avg:
            errors["Squat too shallow"] = "Hips did not descend below knees"

        #knee valgus
        knee_width = float(abs(knee_l[0] - knee_r[0]))
        ankle_width = float(abs(ankle_l[0] - ankle_r[0]))
        
        if knee_width < (ankle_width * 0.9):
            errors["Knee Valgus (Collapse)"] = True

        #heels rising
        heels_up = []
        if float(heel_l[1]) < (float(foot_l[1]) - 0.03): heels_up.append("L")
        if float(heel_r[1]) < (float(foot_r[1]) - 0.03): heels_up.append("R")
            
        if heels_up:
            errors["Heels rising"] = ", ".join(heels_up)

        #asymmetrical Shift
        shoulder_mid_x = float((sh_l[0] + sh_r[0]) / 2)
        hip_mid_x = float((hip_l[0] + hip_r[0]) / 2)
        shift = float(shoulder_mid_x - hip_mid_x)
        
        if abs(shift) > 0.06:
            direction = "Right" if shift > 0 else "Left"
            errors["Asymmetrical Shift"] = direction

        #duck feet
        def get_foot_angle(heel, toe, side="left"):
            vec = np.array([float(toe[0]) - float(heel[0]), float(toe[1]) - float(heel[1])])
            vertical = np.array([0, 1])
            norm = np.linalg.norm(vec)
            if norm == 0: return 0.0
            cos_angle = np.dot(vec, vertical) / norm
            angle = np.degrees(np.arccos(np.clip(cos_angle, -1.0, 1.0)))
            return float(angle)

        angle_foot_l = get_foot_angle(heel_l, foot_l, "left")
        angle_foot_r = get_foot_angle(heel_r, foot_r, "right")

        duck_feet_msgs = []
        if angle_foot_l > 35: 
            duck_feet_msgs.append(f"Left: {int(angle_foot_l)}°")
        if angle_foot_r > 35: 
            duck_feet_msgs.append(f"Right: {int(angle_foot_r)}°")

        if duck_feet_msgs:
            errors["Excessive Foot Turn-Out (Limit ~30°)"] = ", ".join(duck_feet_msgs)

        #forward lean check
        torso_vertical_len = float((hip_l[1] + hip_r[1]) / 2 - (sh_l[1] + sh_r[1]) / 2)
        shin_len = float(self.calculate_distance(knee_l, ankle_l))

        if shin_len > 0 and torso_vertical_len < (shin_len * 0.6):
            errors["Excessive Forward Lean"] = True

        if not errors:
            return True, MOVEMENT_CORRECT
            
        return False, errors

    def _analyze_hurdle_step(self, skeleton_data, variant="LEFT"):
        """
        Analyzes the Hurdle Step movement based on FMS (Functional Movement Systems) guidelines 
        and biomechanical standards for single-leg stability.

        Medical & Biomechanical References:
        1. Cook, G. (2010). "Movement: Functional Movement Systems".
           - Defines the standard hurdle height (tibial tuberosity).
           - Criteria for "Hip Hiking" vs "Hip Drop" and external rotation compensation.
        2. Powers, C. M. (2010). "The influence of altered lower-extremity kinematics on patellofemoral joint dysfunction".
           - Basis for Dynamic Knee Valgus detection (medial collapse).
        3. Hardman, J., et al. (2009). "The effect of the Trendelenburg position on pelvic stability".
           - Basis for Pelvic Drop analysis (Gluteus Medius weakness).

        Key Analysis Points:
        - Clearance: Ankle must rise above the stance leg knee (Tibial Tuberosity).
        - Alignment: Dynamic Valgus check, Foot External Rotation.
        - Stability: Pelvic Tilt (Trendelenburg/Hiking) and Torso control.
        """
        
        peak_frame = None
        min_knee_y = float("inf")

        if variant == "LEFT":
            moving_knee_idx = self.MP["LEFT_KNEE"]
            moving_hip_idx = self.MP["LEFT_HIP"]
            moving_ankle_idx = self.MP["LEFT_ANKLE"]
            moving_foot_idx = self.MP["LEFT_FOOT_INDEX"] 
            
            stance_knee_idx = self.MP["RIGHT_KNEE"]
            stance_hip_idx = self.MP["RIGHT_HIP"]
            stance_ankle_idx = self.MP["RIGHT_ANKLE"]
        else: 
            moving_knee_idx = self.MP["RIGHT_KNEE"]
            moving_hip_idx = self.MP["RIGHT_HIP"]
            moving_ankle_idx = self.MP["RIGHT_ANKLE"]
            moving_foot_idx = self.MP["RIGHT_FOOT_INDEX"]
            
            stance_knee_idx = self.MP["LEFT_KNEE"]
            stance_hip_idx = self.MP["LEFT_HIP"]
            stance_ankle_idx = self.MP["LEFT_ANKLE"]

        found_peak = False
        for frame in skeleton_data:
            m_knee_y = float(frame[moving_knee_idx][1])
            if m_knee_y < min_knee_y:
                min_knee_y = m_knee_y
                peak_frame = frame
                found_peak = True

        if not found_peak or peak_frame is None:
             return False, {"System": "No movement detected"}

        s_hip = np.array(peak_frame[stance_hip_idx])
        s_knee = np.array(peak_frame[stance_knee_idx])
        s_ankle = np.array(peak_frame[stance_ankle_idx])
        
        m_hip = np.array(peak_frame[moving_hip_idx])
        m_knee = np.array(peak_frame[moving_knee_idx])
        m_ankle = np.array(peak_frame[moving_ankle_idx])
        m_foot = np.array(peak_frame[moving_foot_idx]) 

        sh_l = self._get_coords(peak_frame, "LEFT_SHOULDER")
        sh_r = self._get_coords(peak_frame, "RIGHT_SHOULDER")
        sh_mid = (sh_l + sh_r) / 2
        hip_mid = (s_hip + m_hip) / 2

        final_errors = {}

        #pelvic stability
        pelvis_vec = m_hip - s_hip
        pelvis_width = float(abs(pelvis_vec[0]))
        if pelvis_width > 0:
            tilt_ratio = float((s_hip[1] - m_hip[1]) / pelvis_width)
            if tilt_ratio > 0.15: 
                final_errors["Pelvic Hike (Compensation)"] = True
            elif tilt_ratio < -0.15:
                final_errors["Pelvic Drop (Instability)"] = True
        

        #knee valgus (stance leg)
        ankle_hip_diff = float(abs(s_ankle[1] - s_hip[1]))
        if ankle_hip_diff > 0:
            ratio_y = float((s_knee[1] - s_hip[1]) / (s_ankle[1] - s_hip[1]))
            expected_knee_x = float(s_hip[0] + ratio_y * (s_ankle[0] - s_hip[0]))
            
            diff = float(s_knee[0] - expected_knee_x)
            valgus_dev = 0.0

            if variant == "LEFT": 
                if diff < -0.03: valgus_dev = float(abs(diff))
            else: 
                if diff > 0.03: valgus_dev = float(abs(diff))

            if valgus_dev > 0:
                final_errors["Knee Valgus"] = True

        #torso lean
        spine_vec = sh_mid - hip_mid
        spine_vec_2d = spine_vec[:2]
        norm_spine = float(np.linalg.norm(spine_vec_2d))
        if norm_spine > 0:
            cosine = float(np.dot(spine_vec_2d, np.array([0, -1])) / norm_spine)
            angle_trunk = float(np.degrees(np.arccos(np.clip(cosine, -1.0, 1.0))))
            if angle_trunk > 10:
                final_errors["Torso Instability"] = f"{int(angle_trunk)}°"

        #clearance check
        if float(m_ankle[1]) > (float(s_knee[1]) + 0.02):
            final_errors["Step too low"] = True

        #foot alignment
        foot_out_diff = 0
        if variant == "LEFT": 
            if float(m_ankle[0]) > (float(m_knee[0]) + 0.04): 
                 final_errors["Foot External Rotation"] = True
        else: 
            if float(m_ankle[0]) < (float(m_knee[0]) - 0.04):
                 final_errors["Foot External Rotation"] = True

        #dorsiflexion check
        if float(m_foot[1]) > (float(m_ankle[1]) + 0.02):
            final_errors["Lack of Dorsiflexion (Toes down)"] = True

        if not final_errors:
            return True, MOVEMENT_CORRECT
            
        return False, final_errors

    def _analyze_shoulder_abduction(self, skeleton_data, variant="BOTH"):
        """
        Analyzes Standing Shoulder Abduction for rehabilitation compliance.
        Focuses on Scapulohumeral Rhythm and avoidance of Subacromial Impingement.

        Medical & Biomechanical References:
        1. Kisner, C., & Colby, L. A. (2012). "Therapeutic Exercise: Foundations and Techniques".
           - Defines correct abduction mechanics vs trunk lateral flexion (compensation).
        2. Neumann, D. A. (2010). "Kinesiology of the Musculoskeletal System".
           - Scapulohumeral rhythm mechanics.
        3. Kibler, W. B., et al. (2013). "Clinical implications of scapular dyskinesis".
           - Standards for detecting scapular elevation (Shrugging).
        4. Neer, C. S. (1983). "Impingement lesions".
           - Basis for limiting ROM to <100 deg to avoid impingement zone in early rehab.

        Key Analysis Points:
        - Safety: Alerts if arm > 100 deg (Impingement Zone).
        - Efficacy: Alerts if arm < 80 deg (Insufficient ROM).
        - Quality: Detects Shrugging (Upper Trapezius dominance) and Trunk Lean.
        """

        error_counts = Counter()
        frames_analyzed = 0
        
        max_angle_l = 0
        max_angle_r = 0
        max_trunk_angle = 0

        for frame in skeleton_data:
            wrist_l_y = float(frame[self.MP["LEFT_WRIST"]][1])
            elbow_l_y = float(frame[self.MP["LEFT_ELBOW"]][1])
            wrist_r_y = float(frame[self.MP["RIGHT_WRIST"]][1])
            elbow_r_y = float(frame[self.MP["RIGHT_ELBOW"]][1])

            is_active = False
            if variant == "LEFT":
                if wrist_l_y < elbow_l_y: is_active = True
            elif variant == "RIGHT":
                if wrist_r_y < elbow_r_y: is_active = True
            elif variant == "BOTH":
                if wrist_l_y < elbow_l_y and wrist_r_y < elbow_r_y: is_active = True

            if not is_active:
                continue

            frames_analyzed += 1

            nose = self._get_coords(frame, "NOSE")
            sh_l = self._get_coords(frame, "LEFT_SHOULDER")
            sh_r = self._get_coords(frame, "RIGHT_SHOULDER")
            hip_mid = (self._get_coords(frame, "LEFT_HIP") + self._get_coords(frame, "RIGHT_HIP")) / 2
            sh_mid = (sh_l + sh_r) / 2
            shoulder_width = float(self.calculate_distance(sh_l, sh_r))

            #shrugging
            check_left = variant in ["LEFT", "BOTH"]
            check_right = variant in ["RIGHT", "BOTH"]
            
            if shoulder_width > 0:
                dist_ratio_left = float(self.calculate_distance(nose, sh_l) / shoulder_width)
                dist_ratio_right = float(self.calculate_distance(nose, sh_r) / shoulder_width)
                if check_left and dist_ratio_left < 0.40:
                    error_counts["Shoulder elevation (Shrugging)"] += 1
                if check_right and dist_ratio_right < 0.40:
                    error_counts["Shoulder elevation (Shrugging)"] += 1

            #trunk lean
            spine_vec = sh_mid - hip_mid
            spine_vec_2d = spine_vec[:2]
            norm_spine = float(np.linalg.norm(spine_vec_2d))
            if norm_spine > 0:
                cosine = float(np.dot(spine_vec_2d, np.array([0, -1])) / norm_spine)
                angle_trunk = float(np.degrees(np.arccos(np.clip(cosine, -1.0, 1.0))))
                
                if angle_trunk > max_trunk_angle:
                    max_trunk_angle = angle_trunk

                if angle_trunk > 15:
                    error_counts["Excessive trunk lean"] += 1

            #non-working arm movement
            if variant == "LEFT" and wrist_r_y < elbow_r_y:
                error_counts["Unstable non-working arm"] += 1
            elif variant == "RIGHT" and wrist_l_y < elbow_l_y:
                error_counts["Unstable non-working arm"] += 1

            #arm asymmetry
            if variant == "BOTH":
                wr_l = self._get_coords(frame, "LEFT_WRIST")
                wr_r = self._get_coords(frame, "RIGHT_WRIST")
                if float(abs(wr_l[1] - wr_r[1])) > 0.15:
                    error_counts["Arm asymmetry"] += 1

            #range of motion safety check
            vertical_down = np.array([0, 1]) 

            if check_left:
                arm_vec_l = self._get_coords(frame, "LEFT_ELBOW") - sh_l
                norm_l = float(np.linalg.norm(arm_vec_l[:2]))
                if norm_l > 0:
                    cos_l = float(np.dot(arm_vec_l[:2], vertical_down) / norm_l)
                    angle_l = float(np.degrees(np.arccos(np.clip(cos_l, -1.0, 1.0))))
                    
                    if angle_l > max_angle_l:
                        max_angle_l = angle_l
                    
                    if angle_l > 100:
                        error_counts["Arm raised too high (>100°)"] += 1

            if check_right:
                arm_vec_r = self._get_coords(frame, "RIGHT_ELBOW") - sh_r
                norm_r = float(np.linalg.norm(arm_vec_r[:2]))
                if norm_r > 0:
                    cos_r = float(np.dot(arm_vec_r[:2], vertical_down) / norm_r)
                    angle_r = float(np.degrees(np.arccos(np.clip(cos_r, -1.0, 1.0))))
                    
                    if angle_r > max_angle_r:
                        max_angle_r = angle_r
                    
                    if angle_r > 100:
                        error_counts["Arm raised too high (>100°)"] += 1

        if frames_analyzed == 0:
            return False, {"System": "No movement detected"}
        
        threshold = frames_analyzed * 0.3
        final_errors = {}

        if error_counts["Shoulder elevation (Shrugging)"] > threshold:
            final_errors["Shoulder elevation (Shrugging)"] = True

        if error_counts["Excessive trunk lean"] > threshold:
            final_errors["Excessive trunk lean"] = f"{int(max_trunk_angle)}°"

        if error_counts["Unstable non-working arm"] > threshold:
            final_errors["Unstable non-working arm"] = True

        if error_counts["Arm asymmetry"] > threshold:
            final_errors["Arm asymmetry"] = True

        if error_counts["Arm raised too high (>100°)"] > threshold:
            vals = []
            if variant in ["LEFT", "BOTH"]:
                vals.append(f"L:{int(max_angle_l)}°")
            if variant in ["RIGHT", "BOTH"]:
                vals.append(f"R:{int(max_angle_r)}°")
            final_errors["Arm raised too high (>100°)"] = ", ".join(vals)

        rom_too_shallow = False
        vals_shallow = []
        if variant == "LEFT" and max_angle_l < 80:
            rom_too_shallow = True
            vals_shallow.append(f"L:{int(max_angle_l)}°")
        elif variant == "RIGHT" and max_angle_r < 80:
            rom_too_shallow = True
            vals_shallow.append(f"R:{int(max_angle_r)}°")
        elif variant == "BOTH":
            if max_angle_l < 80:
                rom_too_shallow = True
                vals_shallow.append(f"L:{int(max_angle_l)}°")
            if max_angle_r < 80:
                rom_too_shallow = True
                vals_shallow.append(f"R:{int(max_angle_r)}°")
        
        if rom_too_shallow:
            final_errors["Movement too shallow (<80°)"] = ", ".join(vals_shallow)

        if not final_errors:
            return True, MOVEMENT_CORRECT
        
        return False, final_errors
            
class ReportGenerator:
    """
    Generates text reports based on diagnostic results.
    Adapted to handle (is_correct, feedback_dict) tuples returned by MovementDiagnostician.
    """
    def generate_report(self, analysis_result_tuple, exercise_name):
        if not analysis_result_tuple:
            return "No result provided."

        is_correct, feedback = analysis_result_tuple
        
        report = f"Exercise Analysis: {exercise_name}\n"
        
        if is_correct:
            report += f"Status: {MOVEMENT_CORRECT}\n"
            report += "Conclusion: Excellent form! Keep it up."
        else:
            report += "Status: Technique needs improvement.\n\n"
            report += "DETECTED ERRORS:\n"
            
            if isinstance(feedback, dict):
                for error_name, details in feedback.items():
                    if details is True:
                        report += f"- {error_name}\n"
                    else:
                        report += f"- {error_name}: {details}\n"
            
            elif isinstance(feedback, str):
                report += f"- {feedback}\n"
            
            report += "\nRecommendation: Lower intensity and focus on correcting these specific patterns."

        return report
