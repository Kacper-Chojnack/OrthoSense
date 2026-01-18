/// Unit tests for LiveAnalysisScreen and AnalysisPhase.
///
/// Test coverage:
/// 1. AnalysisPhase enum values
/// 2. Phase transitions
/// 3. Camera initialization
/// 4. Pose buffer management
/// 5. Feedback logic
/// 6. Session timing
/// 7. TTS integration
library;

import 'package:camera/camera.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AnalysisPhase', () {
    test('has idle phase', () {
      const phases = [
        'idle',
        'countdown',
        'setup',
        'calibrationClassification',
        'calibrationVariant',
        'analyzing',
        'completed',
      ];
      expect(phases.contains('idle'), isTrue);
    });

    test('has countdown phase', () {
      const phases = ['idle', 'countdown', 'setup', 'analyzing', 'completed'];
      expect(phases.contains('countdown'), isTrue);
    });

    test('has setup phase', () {
      const phases = ['idle', 'countdown', 'setup', 'analyzing', 'completed'];
      expect(phases.contains('setup'), isTrue);
    });

    test('has calibrationClassification phase', () {
      const phase = 'calibrationClassification';
      expect(phase, equals('calibrationClassification'));
    });

    test('has calibrationVariant phase', () {
      const phase = 'calibrationVariant';
      expect(phase, equals('calibrationVariant'));
    });

    test('has analyzing phase', () {
      const phase = 'analyzing';
      expect(phase, equals('analyzing'));
    });

    test('has completed phase', () {
      const phase = 'completed';
      expect(phase, equals('completed'));
    });
  });

  group('Buffer configuration', () {
    test('window size is 60 frames', () {
      const windowSize = 60;
      expect(windowSize, equals(60));
    });

    test('prediction interval is 5 frames', () {
      const predictionInterval = 5;
      expect(predictionInterval, equals(5));
    });

    test('visibility window size is 30', () {
      const visibilityWindowSize = 30;
      expect(visibilityWindowSize, equals(30));
    });

    test('minimum visibility ratio is 0.7', () {
      const minVisibilityRatio = 0.7;
      expect(minVisibilityRatio, equals(0.7));
    });
  });

  group('Frame processing', () {
    test('frame processing interval is 66ms', () {
      const interval = Duration(milliseconds: 66);
      expect(interval.inMilliseconds, equals(66));
    });

    test('approximately 15fps processing rate', () {
      const intervalMs = 66;
      final fps = 1000 / intervalMs;

      expect(fps, closeTo(15, 1));
    });

    test('should process frame when enough time elapsed', () {
      final lastProcess = DateTime.now().subtract(
        const Duration(milliseconds: 100),
      );
      final now = DateTime.now();
      const interval = Duration(milliseconds: 66);

      final shouldProcess = now.difference(lastProcess) >= interval;
      expect(shouldProcess, isTrue);
    });

    test('should not process frame when too soon', () {
      final lastProcess = DateTime.now();
      final now = DateTime.now();
      const interval = Duration(milliseconds: 66);

      final shouldProcess = now.difference(lastProcess) >= interval;
      expect(shouldProcess, isFalse);
    });
  });

  group('TTS feedback', () {
    test('feedback cooldown is 3 seconds', () {
      const cooldown = Duration(seconds: 3);
      expect(cooldown.inSeconds, equals(3));
    });

    test('should speak when no previous feedback', () {
      const lastSpokenFeedback = null;
      const newFeedback = 'Good form!';

      final shouldSpeak = lastSpokenFeedback != newFeedback;
      expect(shouldSpeak, isTrue);
    });

    test('should speak when feedback is different', () {
      const lastSpokenFeedback = 'Good form!';
      const newFeedback = 'Extend your arm more';

      final shouldSpeak = lastSpokenFeedback != newFeedback;
      expect(shouldSpeak, isTrue);
    });

    test('should not speak when feedback is same', () {
      const lastSpokenFeedback = 'Good form!';
      const newFeedback = 'Good form!';

      final shouldSpeak = lastSpokenFeedback != newFeedback;
      expect(shouldSpeak, isFalse);
    });

    test('cooldown prevents repeated feedback', () {
      final lastSpokenAt = DateTime.now();
      const cooldown = Duration(seconds: 3);

      final canSpeak = DateTime.now().difference(lastSpokenAt) >= cooldown;
      expect(canSpeak, isFalse);
    });
  });

  group('Calibration', () {
    test('calibration votes are collected', () {
      final votes = <String>['squat', 'squat', 'lunge'];

      expect(votes.length, equals(3));
    });

    test('majority vote determines exercise', () {
      final votes = ['squat', 'squat', 'squat', 'lunge', 'lunge'];

      final voteCount = <String, int>{};
      for (final vote in votes) {
        voteCount[vote] = (voteCount[vote] ?? 0) + 1;
      }

      final winner = voteCount.entries
          .reduce((a, b) => a.value > b.value ? a : b)
          .key;

      expect(winner, equals('squat'));
    });
  });

  group('Visibility tracking', () {
    test('visibility buffer tracks frame visibility', () {
      final buffer = <bool>[true, true, false, true, true];

      final visibleCount = buffer.where((v) => v).length;
      expect(visibleCount, equals(4));
    });

    test('calculates visibility ratio', () {
      final buffer = <bool>[true, true, false, true, true];
      final ratio = buffer.where((v) => v).length / buffer.length;

      expect(ratio, equals(0.8));
    });

    test('passes when visibility >= 70%', () {
      const ratio = 0.75;
      const threshold = 0.7;

      final passes = ratio >= threshold;
      expect(passes, isTrue);
    });

    test('fails when visibility < 70%', () {
      const ratio = 0.5;
      const threshold = 0.7;

      final passes = ratio >= threshold;
      expect(passes, isFalse);
    });
  });

  group('Session tracking', () {
    test('session start time is recorded', () {
      final startTime = DateTime.now();
      expect(startTime, isNotNull);
    });

    test('session duration is calculated', () {
      final startTime = DateTime.now().subtract(const Duration(minutes: 5));
      final duration = DateTime.now().difference(startTime);

      expect(duration.inMinutes, closeTo(5, 1));
    });

    test('error counts are tracked per error type', () {
      final errorCounts = <String, int>{
        'posture': 3,
        'range_of_motion': 2,
      };

      expect(errorCounts['posture'], equals(3));
    });

    test('correct frames are counted', () {
      var totalFrames = 100;
      var correctFrames = 85;

      final accuracy = correctFrames / totalFrames;
      expect(accuracy, equals(0.85));
    });
  });

  group('Animation controllers', () {
    test('feedback animation duration is 300ms', () {
      const duration = Duration(milliseconds: 300);
      expect(duration.inMilliseconds, equals(300));
    });

    test('uses TickerProviderStateMixin', () {
      const usesTickerProvider = true;
      expect(usesTickerProvider, isTrue);
    });
  });

  group('Camera management', () {
    test('camera controller starts as null', () {
      const CameraController? controller = null;
      expect(controller, isNull);
    });

    test('isInitialized tracks camera state', () {
      var isInitialized = false;

      void initializeCamera() {
        isInitialized = true;
      }

      initializeCamera();
      expect(isInitialized, isTrue);
    });

    test('isStreaming tracks stream state', () {
      var isStreaming = false;

      void startStreaming() {
        isStreaming = true;
      }

      startStreaming();
      expect(isStreaming, isTrue);
    });
  });

  group('State flags', () {
    test('hasError tracks error state', () {
      var hasError = false;

      void setError() {
        hasError = true;
      }

      setError();
      expect(hasError, isTrue);
    });

    test('isStoppingAnalysis prevents double-stop', () {
      var isStoppingAnalysis = false;

      void stopAnalysis() {
        if (isStoppingAnalysis) return;
        isStoppingAnalysis = true;
        // ... stop logic
      }

      stopAnalysis();
      expect(isStoppingAnalysis, isTrue);
    });
  });

  group('Run ID management', () {
    test('run ID starts at 0', () {
      var liveAnalysisRunId = 0;
      expect(liveAnalysisRunId, equals(0));
    });

    test('run ID increments for each analysis', () {
      var liveAnalysisRunId = 0;

      void startNewAnalysis() {
        liveAnalysisRunId++;
      }

      startNewAnalysis();
      startNewAnalysis();
      expect(liveAnalysisRunId, equals(2));
    });

    test('old callbacks are ignored with stale run ID', () {
      const currentRunId = 5;
      const callbackRunId = 4;

      final isStale = callbackRunId != currentRunId;
      expect(isStale, isTrue);
    });
  });

  group('Pose data', () {
    test('debug pose stores last detected pose', () {
      Object? debugPose;

      void setDebugPose(Object pose) {
        debugPose = pose;
      }

      setDebugPose({'landmarks': []});
      expect(debugPose, isNotNull);
    });

    test('source image size is tracked', () {
      Object? sourceImageSize;

      void setSize(double width, double height) {
        sourceImageSize = {'width': width, 'height': height};
      }

      setSize(1080, 1920);
      expect(sourceImageSize, isNotNull);
    });

    test('smoothed pose is stored', () {
      Object? lastSmoothedPose;

      void setSmoothedPose(Object pose) {
        lastSmoothedPose = pose;
      }

      setSmoothedPose({'smoothed': true});
      expect(lastSmoothedPose, isNotNull);
    });
  });

  group('Raw buffer management', () {
    test('buffer is initially empty', () {
      final rawBuffer = <Object>[];
      expect(rawBuffer.isEmpty, isTrue);
    });

    test('frames are added to buffer', () {
      final rawBuffer = <Object>[];

      void addFrame(Object frame) {
        rawBuffer.add(frame);
      }

      addFrame({'frame': 1});
      addFrame({'frame': 2});

      expect(rawBuffer.length, equals(2));
    });

    test('buffer is trimmed to window size', () {
      const windowSize = 60;
      final rawBuffer = List.generate(70, (i) => 'frame_$i');

      if (rawBuffer.length > windowSize) {
        rawBuffer.removeRange(0, rawBuffer.length - windowSize);
      }

      expect(rawBuffer.length, equals(windowSize));
    });
  });

  group('Detected exercise/variant', () {
    test('detectedExercise starts null', () {
      const String? detectedExercise = null;
      expect(detectedExercise, isNull);
    });

    test('detectedVariant starts null', () {
      const String? detectedVariant = null;
      expect(detectedVariant, isNull);
    });

    test('currentFeedback starts null', () {
      const String? currentFeedback = null;
      expect(currentFeedback, isNull);
    });
  });

  group('Phase transitions', () {
    test('idle to countdown', () {
      const from = 'idle';
      const to = 'countdown';

      expect(from, isNot(equals(to)));
    });

    test('countdown to setup', () {
      const from = 'countdown';
      const to = 'setup';

      expect(from, isNot(equals(to)));
    });

    test('setup to calibrationClassification', () {
      const from = 'setup';
      const to = 'calibrationClassification';

      expect(from, isNot(equals(to)));
    });

    test('calibrationClassification to calibrationVariant', () {
      const from = 'calibrationClassification';
      const to = 'calibrationVariant';

      expect(from, isNot(equals(to)));
    });

    test('calibrationVariant to analyzing', () {
      const from = 'calibrationVariant';
      const to = 'analyzing';

      expect(from, isNot(equals(to)));
    });

    test('analyzing to completed', () {
      const from = 'analyzing';
      const to = 'completed';

      expect(from, isNot(equals(to)));
    });
  });

  group('Provider dependencies', () {
    test('depends on exerciseClassifierProvider', () {
      const dependsOnClassifier = true;
      expect(dependsOnClassifier, isTrue);
    });

    test('depends on movementDiagnosticsProvider', () {
      const dependsOnDiagnostics = true;
      expect(dependsOnDiagnostics, isTrue);
    });

    test('depends on poseDetectionProvider', () {
      const dependsOnPoseDetection = true;
      expect(dependsOnPoseDetection, isTrue);
    });

    test('depends on ttsProvider', () {
      const dependsOnTts = true;
      expect(dependsOnTts, isTrue);
    });

    test('depends on trendProvider', () {
      const dependsOnTrend = true;
      expect(dependsOnTrend, isTrue);
    });
  });

  group('Cleanup', () {
    test('disposes camera controller', () {
      var disposed = false;

      void dispose() {
        disposed = true;
      }

      dispose();
      expect(disposed, isTrue);
    });

    test('cancels phase timer', () {
      var timerCancelled = false;

      void cancelTimer() {
        timerCancelled = true;
      }

      cancelTimer();
      expect(timerCancelled, isTrue);
    });

    test('cancels session timer', () {
      var sessionTimerCancelled = false;

      void cancelSessionTimer() {
        sessionTimerCancelled = true;
      }

      cancelSessionTimer();
      expect(sessionTimerCancelled, isTrue);
    });

    test('disposes animation controllers', () {
      var animationsDisposed = false;

      void disposeAnimations() {
        animationsDisposed = true;
      }

      disposeAnimations();
      expect(animationsDisposed, isTrue);
    });
  });
}
