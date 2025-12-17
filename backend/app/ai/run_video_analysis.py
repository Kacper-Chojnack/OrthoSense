import os
os.environ["CUDA_VISIBLE_DEVICES"] = "-1"

import sys
from pathlib import Path

BASE_DIR = Path(__file__).parent
sys.path.insert(0, str(BASE_DIR))

from core.system import OrthoSenseSystem 

def main():
    VIDEO_FILE = "/Users/zosia/Documents/GitHub/OrthoSense/test/IMG_8343.mov"

    system = OrthoSenseSystem()
    result = system.analyze_video_file(VIDEO_FILE)
    
    if "error" in result:
        print(f"Error: {result['error']}")
        return

    print("\n" + "="*50)
    print(" FINAL RESULT")
    print("="*50)
    print(f" Exercise:   {result.get('exercise', 'N/A')}")
    print(f" Confidence: {result.get('confidence', 0.0)*100:.1f}%")
    
    if "text_report" in result:
        print("\n--- REPORT ---\n")
        print(result["text_report"])
        
    print("="*50 + "\n")

if __name__ == "__main__":
    main()