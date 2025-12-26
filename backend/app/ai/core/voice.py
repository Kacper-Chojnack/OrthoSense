import contextlib
import queue
import threading
import time


class VoiceService:
    def __init__(self):
        self.engine = None
        self.active = False
        self.last_message = ""
        self.last_speak_time = 0
        self.message_queue = queue.Queue()
        self.worker_thread = None
        self.is_speaking = False
        self.lock = threading.Lock()

        try:
            import pyttsx3

            self.engine = pyttsx3.init()

            try:
                self.engine.setProperty("rate", 170)

                voices = self.engine.getProperty("voices")
                voice_found = False

                target_names = ["David", "Daniel"]

                for voice in voices:
                    for name in target_names:
                        if name in voice.name:
                            self.engine.setProperty("voice", voice.id)
                            voice_found = True
                            print(f"Voice set to: {voice.name}")
                            break
                    if voice_found:
                        break

                if not voice_found:
                    for voice in voices:
                        if (
                            "en_US" in voice.id
                            or "en_GB" in voice.id
                            or "English" in voice.name
                        ):
                            self.engine.setProperty("voice", voice.id)
                            print(f"Voice set to English fallback: {voice.name}")
                            break

            except Exception as e:
                print(f"Voice configuration warning: {e}")

            self.active = True
            self.worker_thread = threading.Thread(
                target=self._queue_worker, daemon=True
            )
            self.worker_thread.start()
            print("Voice service initialized locally.")

        except ImportError:
            print("'pyttsx3' library not found. Voice disabled.")
        except OSError:
            print("Audio driver not found (Server/Docker mode). Voice disabled.")
        except Exception as e:
            print(f"Voice init failed ({str(e)}). Voice disabled.")

    def speak(self, text):
        """
        Adds text to the queue to be spoken. Messages are processed sequentially.
        """

        if not self.active or not self.engine or not text:
            return

        current_time = time.time()
        if text == self.last_message and (current_time - self.last_speak_time < 4.0):
            return

        self.last_message = text
        self.last_speak_time = current_time

        with contextlib.suppress(queue.Full):
            self.message_queue.put_nowait(text)

    def _queue_worker(self):
        """
        Worker thread that processes messages from the queue sequentially.
        Each message is spoken completely before the next one starts.
        """
        while True:
            try:
                text = self.message_queue.get(timeout=1.0)

                with self.lock:
                    if not self.active or not self.engine:
                        self.message_queue.task_done()
                        continue
                    self.is_speaking = True

                try:
                    self.engine.say(text)
                    self.engine.runAndWait()

                except Exception as e:
                    print(f"Voice playback error: {e}")

                with self.lock:
                    self.is_speaking = False

                self.message_queue.task_done()

            except queue.Empty:
                continue
            except Exception as e:
                print(f"Voice queue worker error: {e}")
                with self.lock:
                    self.is_speaking = False
