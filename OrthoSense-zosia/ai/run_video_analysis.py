"""
Test script for video analysis with LSTM + MediaPipe 33 landmarks.
"""

import os
os.environ["CUDA_VISIBLE_DEVICES"] = "-1"  

import sys
from pathlib import Path

BASE_DIR = Path(__file__).parent
if str(BASE_DIR) not in sys.path:
    sys.path.insert(0, str(BASE_DIR))

from core.system import OrthoSenseSystem


def main():
    VIDEO_FILE = "/Users/zosia/Documents/GitHub/OrthoSense/test/standing-shoulder-abduction.mp4"
    # VIDEO_FILE = "/Users/zosia/Documents/GitHub/OrthoSense/test/deep-squats.mp4"
    # VIDEO_FILE = "/Users/zosia/Documents/GitHub/OrthoSense/test/hurdle-step2.mp4"
    
    if not os.path.exists(VIDEO_FILE):
        print(f"ERROR: Video file not found: {VIDEO_FILE}")
        return

    print("="*60)
    print("OrthoSense Video Analysis")
    print("Model: LSTM with MediaPipe 33 landmarks")
    print("Classes: Deep Squat, Shoulder Abduction")
    print("="*60)
    
    system = OrthoSenseSystem()
    result = system.analyze_video_file(VIDEO_FILE)
    
    if "error" in result:
        print(f"\nError: {result['error']}")
        return

    print("\n" + "="*60)
    print(" FINAL RESULT")
    print("="*60)
    print(f" Exercise:   {result.get('exercise', 'N/A')}")
    print(f" Confidence: {result.get('confidence', 0.0)*100:.1f}%")
    print(f" Correct:    {result.get('is_correct', 'N/A')}")
    print(f" Feedback:   {result.get('feedback', 'N/A')}")
    
    if "text_report" in result:
        print("\n--- REPORT ---")
        print(result["text_report"])
        
    print("="*60)


if __name__ == "__main__":
    main()
