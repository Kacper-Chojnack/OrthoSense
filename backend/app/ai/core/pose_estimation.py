import os
from pathlib import Path

import cv2
import mediapipe as mp
import numpy as np
from mediapipe import ImageFormat
from mediapipe.tasks import python
from mediapipe.tasks.python import vision


class VideoProcessor:
    def __init__(self, complexity=0):
        """
        Initialize MediaPipe Pose using Tasks API.
        complexity: 0=Lite, 1=Full, 2=Heavy
        """

        model_name = "pose_landmarker_lite.task"
        if complexity == 1:
            model_name = "pose_landmarker_full.task"
        elif complexity == 2:
            model_name = "pose_landmarker_heavy.task"

        ai_dir = Path(__file__).parent.parent
        script_dir = Path(__file__).parent.parent.parent.parent

        possible_paths = [
            ai_dir / "models" / model_name,
            script_dir / "app" / "ai" / "models" / model_name,
            script_dir / "models" / model_name,
            Path(model_name),
        ]

        model_path = None
        for path in possible_paths:
            if path.exists():
                model_path = str(path)
                break

        if model_path is None:
            raise FileNotFoundError(
                f"MediaPipe model '{model_name}' not found.\n"
                f"Download from: https://developers.google.com/mediapipe/solutions/vision/pose_landmarker\n"
                f"Place in: {script_dir / 'models' / model_name}"
            )

        print(f"[VideoProcessor] Using model: {model_path}")

        self.model_path = model_path
        self.frame_timestamp_ms = 0

    def get_raw_landmarks(self, world_landmarks):
        """
        Extract RAW MediaPipe landmarks (33 joints × 3 coords).
        """
        landmarks = np.zeros((33, 3), dtype=np.float32)
        for i, lm in enumerate(world_landmarks):
            landmarks[i, 0] = lm.x
            landmarks[i, 1] = lm.y
            landmarks[i, 2] = lm.z

        return landmarks

    def check_visibility(self, pose_landmarks, min_visibility=0.5):
        """
        Check if enough key body parts are visible.
        """
        if not pose_landmarks or len(pose_landmarks) == 0:
            return False, 0, 0

        key_indices = [11, 12, 23, 24, 25, 26, 27, 28]  # shoulders, hips, knees, ankles

        visible_count = 0
        for idx in key_indices:
            if idx < len(pose_landmarks):
                lm = pose_landmarks[idx]
                visibility = getattr(lm, "visibility", 1.0)
                if visibility >= min_visibility:
                    visible_count += 1

        is_valid = visible_count >= 6
        return is_valid, visible_count, len(key_indices)

    def _check_orientation(self, frame):
        """
        Checks the person's orientation in the current frame.
        """
        small_frame = cv2.resize(frame, (320, 240))
        img_rgb = cv2.cvtColor(small_frame, cv2.COLOR_BGR2RGB)

        base_options = python.BaseOptions(model_asset_path=self.model_path)
        temp_options = vision.PoseLandmarkerOptions(
            base_options=base_options, running_mode=vision.RunningMode.IMAGE
        )
        temp_landmarker = vision.PoseLandmarker.create_from_options(temp_options)

        mp_image = mp.Image(image_format=ImageFormat.SRGB, data=img_rgb)
        results = temp_landmarker.detect(mp_image)

        if results.pose_landmarks and len(results.pose_landmarks) > 0:
            lm = results.pose_landmarks[0]

            nose = lm[0]
            hip_left = lm[23]
            hip_right = lm[24]

            nose_x = nose.x
            nose_y = nose.y
            hip_x = (hip_left.x + hip_right.x) / 2.0
            hip_y = (hip_left.y + hip_right.y) / 2.0

            diff_x = abs(nose_x - hip_x)
            diff_y = abs(nose_y - hip_y)

            if diff_x > diff_y * 1.5:
                print("Auto-Rotation: Detected horizontal spine. Rotating video.")
                return True
            else:
                print("Auto-Rotation: Detected vertical spine. Keeping original.")
                return False

        return False

    def process_video_file(self, video_path, auto_rotate=True):
        """
        Processes video file and returns RAW MediaPipe landmarks (33 joints).
        """

        if not os.path.exists(video_path):
            print(f"Error: File not found: {video_path}")
            return

        cap = cv2.VideoCapture(video_path)
        fps = cap.get(cv2.CAP_PROP_FPS) or 30.0
        frame_duration_ms = int(1000 / fps)

        last_valid_skeleton = None
        rotation_checked = False
        needs_rotation = False
        self.frame_timestamp_ms = 0

        # Create a fresh landmarker for this video to ensure clean state and timestamps
        base_options = python.BaseOptions(model_asset_path=self.model_path)
        options = vision.PoseLandmarkerOptions(
            base_options=base_options,
            output_segmentation_masks=False,
            min_pose_detection_confidence=0.5,
            min_pose_presence_confidence=0.5,
            min_tracking_confidence=0.5,
            running_mode=vision.RunningMode.VIDEO,
        )

        with vision.PoseLandmarker.create_from_options(options) as landmarker:
            while cap.isOpened():
                ret, frame = cap.read()
                if not ret:
                    break

                if not rotation_checked and auto_rotate:
                    h, w = frame.shape[:2]
                    if w > h:
                        needs_rotation = self._check_orientation(frame)
                        if needs_rotation:
                            print("[WARN] Auto-rotation will be applied.")
                    rotation_checked = True

                if needs_rotation and auto_rotate:
                    frame = cv2.rotate(frame, cv2.ROTATE_90_CLOCKWISE)

                frame = cv2.resize(frame, (640, 480))
                image_rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)

                mp_image = mp.Image(image_format=ImageFormat.SRGB, data=image_rgb)

                results = landmarker.detect_for_video(mp_image, self.frame_timestamp_ms)
                self.frame_timestamp_ms += frame_duration_ms

                if (
                    results.pose_world_landmarks
                    and len(results.pose_world_landmarks) > 0
                ):
                    skeleton = self.get_raw_landmarks(results.pose_world_landmarks[0])
                    last_valid_skeleton = skeleton

                    pose_landmarks = (
                        results.pose_landmarks[0] if results.pose_landmarks else None
                    )
                    is_visible, _, _ = self.check_visibility(pose_landmarks)

                    yield skeleton, is_visible
                else:
                    if last_valid_skeleton is not None:
                        yield last_valid_skeleton, False
                    else:
                        yield np.zeros((33, 3), dtype=np.float32), False

        cap.release()

