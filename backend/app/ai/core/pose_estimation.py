import cv2
import mediapipe as mp
import numpy as np
import os
import sys
from pathlib import Path

sys.path.append(str(Path(__file__).parent.parent.parent))
from core.utils import resample_sequence

class VideoProcessor:
    def __init__(self, complexity=1):
        self.mp_pose = mp.solutions.pose
        self.pose = self.mp_pose.Pose(
            static_image_mode=False,
            model_complexity=complexity,
            smooth_landmarks=True,
            min_detection_confidence=0.5,
            min_tracking_confidence=0.7
        )

    def mediapipe_to_kinect(self, mp_landmarks):
        """
        Converts 33 MediaPipe (World Landmarks) points to 25 Kinect v2 points.
        """
        
        lm = mp_landmarks.landmark
        
        def get_pos(idx):
            return np.array([lm[idx].x, lm[idx].y, lm[idx].z])

        l_hip = get_pos(23)  
        r_hip = get_pos(24)  
        spine_base = (l_hip + r_hip) / 2.0  
        
        l_shoulder = get_pos(11)  
        r_shoulder = get_pos(12)  
        spine_shoulder = (l_shoulder + r_shoulder) / 2.0  
        
        spine_mid = (spine_base + spine_shoulder) / 2.0
        neck = spine_shoulder + (spine_shoulder - spine_mid) * 0.3
        head = (get_pos(7) + get_pos(8)) / 2.0

        kinect_joints = [
            spine_base,
            spine_mid,
            neck,
            head,

            l_shoulder,
            get_pos(13),
            get_pos(15),
            get_pos(19),

            r_shoulder,
            get_pos(14),
            get_pos(16),
            get_pos(20),

            l_hip,
            get_pos(25), #13 
            get_pos(27),
            get_pos(31),

            r_hip,
            get_pos(26), #17
            get_pos(28),
            get_pos(32),

            spine_shoulder,
            get_pos(17),     
            get_pos(21),     
            get_pos(18),     
            get_pos(22)   
        ]
        
        return np.array(kinect_joints)

    def _check_orientation(self, frame):
        """
        Checks the person's orientation in the current frame.
        """
        h, w, _ = frame.shape
        small_frame = cv2.resize(frame, (320, 240))
        img_rgb = cv2.cvtColor(small_frame, cv2.COLOR_BGR2RGB)
        
        results = self.pose.process(img_rgb)
        
        if results.pose_landmarks:
            lm = results.pose_landmarks.landmark
            
            nose = lm[0]
            hip_left = lm[23]
            hip_right = lm[24]
            mid_hip_x = (hip_left.x + hip_right.x) / 2
            mid_hip_y = (hip_left.y + hip_right.y) / 2

            diff_x = abs(nose.x - mid_hip_x) * w
            diff_y = abs(nose.y - mid_hip_y) * h
            
            if diff_x > diff_y:
                print("Auto-Rotation: Detected horizontal spine. Rotating video.")
                return True
            else:
                print("Auto-Rotation: Detected vertical spine. Keeping original.")
                return False
                
        return False

    def process_video_file(self, video_path, auto_rotate=True):
        """
        Processes video file and returns raw skeleton sequence.
        """
        if not os.path.exists(video_path):
            print(f"Error: File not found: {video_path}")
            return 

        cap = cv2.VideoCapture(video_path)
        
        last_valid_skeleton = None 

        rotation_checked = False
        needs_rotation = False

        while cap.isOpened():
            ret, frame = cap.read()
            if not ret:
                break
            
            if not rotation_checked:
                h, w = frame.shape[:2]
                if w > h:
                    needs_rotation = self._check_orientation(frame)
                rotation_checked = True

            if needs_rotation:
                frame = cv2.rotate(frame, cv2.ROTATE_90_CLOCKWISE)

            frame = cv2.resize(frame, (640, 480))
            image = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)

            image.flags.writeable = False
            results = self.pose.process(image)
            
            if results.pose_world_landmarks:
                kinect_skeleton = self.mediapipe_to_kinect(results.pose_world_landmarks)
                
                last_valid_skeleton = kinect_skeleton
                
                yield kinect_skeleton
            else:
                if last_valid_skeleton is not None:
                    yield last_valid_skeleton
                else:
                    yield np.zeros((25, 3))

        cap.release()

    def prepare_sequences_for_model(self, raw_data, window_size=60, stride=10):
        """
        Splits long recording into windows of 60 frames (Sliding Window).
        """
        num_frames = raw_data.shape[0]
        sequences = []
        
        if num_frames < window_size:
            seq = resample_sequence(raw_data, window_size)
            sequences.append(seq)
        else:
            for start in range(0, num_frames - window_size + 1, stride):
                end = start + window_size
                chunk = raw_data[start:end]
                sequences.append(chunk)
                
        return np.array(sequences)

