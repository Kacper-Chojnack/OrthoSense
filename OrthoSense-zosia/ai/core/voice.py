import threading
import time

class VoiceService:
    def __init__(self):
        self.engine = None
        self.active = False 
        self.last_message = ""
        self.last_speak_time = 0

        try:
            import pyttsx3
            self.engine = pyttsx3.init()
            
            try:
                self.engine.setProperty('rate', 170) 

                voices = self.engine.getProperty('voices')
                voice_found = False
                
                target_names = ["David", "Daniel"]
                
                for voice in voices:
                    for name in target_names:
                        if name in voice.name:
                            self.engine.setProperty('voice', voice.id)
                            voice_found = True
                            print(f"Voice set to: {voice.name}")
                            break
                    if voice_found:
                        break
                
                if not voice_found:
                    for voice in voices:
                        if "en_US" in voice.id or "en_GB" in voice.id or "English" in voice.name:
                            self.engine.setProperty('voice', voice.id)
                            print(f"Voice set to English fallback: {voice.name}")
                            break

            except Exception as e:
                print(f"Voice configuration warning: {e}")

            self.active = True
            print("Voice service initialized locally.")
            
        except ImportError:
            print("'pyttsx3' library not found. Voice disabled.")
        except OSError:
            print("Audio driver not found (Server/Docker mode). Voice disabled.")
        except Exception as e:
            print(f"Voice init failed ({str(e)}). Voice disabled.")

    def speak(self, text):
        """
        Speaks the given text in a separate thread so it doesn't block the main loop.
        """
        
        if not self.active or not self.engine:
            return

        current_time = time.time()
        if text == self.last_message and (current_time - self.last_speak_time < 4.0):
             return

        self.last_message = text
        self.last_speak_time = current_time

        threading.Thread(target=self._speak_worker, args=(text,), daemon=True).start()

    def _speak_worker(self, text):
        try:
            if self.engine:
                self.engine.say(text)
                self.engine.runAndWait()
        except Exception as e:
            print(f"Voice playback error: {e}")
            self.active = False