import cv2
import numpy as np
import time
from collections import deque, Counter

from core.system import OrthoSenseSystem
from core.voice import VoiceService

WINDOW_SIZE = 60
PREDICTION_INTERVAL = 5 
TIME_SETUP = 5
TIME_CALIBRATION = 10

def draw_overlay(frame, text, subtext="", color=(0, 255, 0)):
    h, w, _ = frame.shape
    overlay = frame.copy()
    cv2.rectangle(overlay, (0, h//2 - 60), (w, h//2 + 60), (0, 0, 0), -1)
    cv2.addWeighted(overlay, 0.6, frame, 0.4, 0, frame)
    font = cv2.FONT_HERSHEY_SIMPLEX
    (text_w, text_h), baseline = cv2.getTextSize(text, font, 1.5, 3)
    text_x = (w - text_w) // 2
    if subtext:
        text_y = h // 2 - 10 
        (sub_w, sub_h), _ = cv2.getTextSize(subtext, font, 0.8, 2)
        cv2.putText(frame, subtext, ((w - sub_w) // 2, h // 2 + 40), font, 0.8, (200, 200, 200), 2)
    else:
        text_y = h // 2 + (text_h // 2)
    cv2.putText(frame, text, (text_x, text_y), font, 1.5, color, 3)

def main():
    print("Starting OrthoSense System...")
    
    system = OrthoSenseSystem()
    voice = VoiceService()
    cap = cv2.VideoCapture(0)
    
    sequence_buffer = deque(maxlen=WINDOW_SIZE)
    raw_buffer = deque(maxlen=WINDOW_SIZE) 
    
    start_time = time.time()
    locked_exercise = None
    calibration_votes = []
    
    current_feedback = {
        "exercise": "Waiting...",
        "confidence": 0.0,
        "is_correct": True,
        "feedback": ""
    }
    
    frame_count = 0
    
    while cap.isOpened():
        ret, frame = cap.read()
        if not ret:
            break
            
        frame = cv2.flip(frame, 1)
        h, w, _ = frame.shape
        current_time = time.time()
        elapsed_time = current_time - start_time
        
        phase = "TRAINING"
        remaining = 0
        if elapsed_time < TIME_SETUP:
            phase = "SETUP"
            remaining = int(TIME_SETUP - elapsed_time) + 1
        elif elapsed_time < TIME_CALIBRATION:
            phase = "CALIBRATION"
            remaining = int(TIME_CALIBRATION - elapsed_time) + 1

        frame_rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
        
        results = system.processor.pose.process(frame_rgb)
        
        if results.pose_world_landmarks:
            skeleton = system.processor.mediapipe_to_kinect(results.pose_world_landmarks)
            
            sequence_buffer.append(skeleton)
            raw_buffer.append(skeleton)
            
            for lm in results.pose_landmarks.landmark:
                cx, cy = int(lm.x * w), int(lm.y * h)
                cv2.circle(frame, (cx, cy), 3, (0, 255, 0), -1)

            if len(sequence_buffer) == WINDOW_SIZE and frame_count % PREDICTION_INTERVAL == 0:
                raw_array = np.array(list(raw_buffer))

                if phase == "CALIBRATION":
                    analysis = system.analyze_live_frame(raw_array)
                    
                    ex_name = analysis['exercise']
                    if ex_name != "No Exercise Detected" and analysis['confidence'] > 0.0:
                        calibration_votes.append(ex_name)
                    current_feedback = analysis

                elif phase == "TRAINING":
                    if locked_exercise is None:
                        if calibration_votes:
                            most_common = Counter(calibration_votes).most_common(1)
                            locked_exercise = most_common[0][0]
                        else:
                            start_time = time.time() 
                            calibration_votes = []
                            continue

                    analysis = system.analyze_live_frame(raw_array, forced_exercise=locked_exercise)
                    current_feedback = analysis

        frame_count += 1
        
        if phase == "SETUP":
            draw_overlay(frame, f"GET READY: {remaining}", "Align your body", (0, 255, 255))
            
        elif phase == "CALIBRATION":
            draw_overlay(frame, f"ANALYZING: {remaining}", "", (0, 165, 255))
            
        elif phase == "TRAINING":
            cv2.rectangle(frame, (0, 0), (w, 120), (0, 0, 0), -1)
            cv2.putText(frame, f"{locked_exercise}", (20, 40), cv2.FONT_HERSHEY_SIMPLEX, 1.0, (255, 255, 255), 2)
            
            if current_feedback['is_correct']:
                cv2.putText(frame, "CORRECT", (20, 90), cv2.FONT_HERSHEY_SIMPLEX, 1.2, (0, 255, 0), 3)
                voice.speak("Good job")
            else:
                raw_msg = current_feedback.get('feedback', "")
                clean_msg = raw_msg.replace("ERRORS:", "").strip()
                cv2.putText(frame, f"FIX FORM: {clean_msg}", (20, 90), cv2.FONT_HERSHEY_SIMPLEX, 0.8, (0, 0, 255), 2)
                voice.speak(clean_msg)

        cv2.imshow('OrthoSense Session', frame)
        if (cv2.waitKey(1) & 0xFF) == ord('q'):
            break

    cap.release()
    cv2.destroyAllWindows()

if __name__ == "__main__":
    main()