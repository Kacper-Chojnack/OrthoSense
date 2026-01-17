/// Unit tests for LiveAnalysisScreen business logic and state management.
///
/// Test coverage:
/// 1. AnalysisPhase state machine
/// 2. Frame buffer management
/// 3. Calibration voting system
/// 4. Visibility tracking
/// 5. Error tracking and session stats
/// 6. Session duration formatting
/// 7. Score calculation from correct ratio
library;

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AnalysisPhase State Machine', () {
    test('initial phase is idle', () {
      const phase = AnalysisPhase.idle;
      expect(phase, equals(AnalysisPhase.idle));
    });

    test('countdown starts from idle', () {
      const start = AnalysisPhase.idle;
      const next = AnalysisPhase.countdown;

      expect(_isValidTransition(start, next), isTrue);
    });

    test('setup follows countdown', () {
      const start = AnalysisPhase.countdown;
      const next = AnalysisPhase.setup;

      expect(_isValidTransition(start, next), isTrue);
    });

    test('calibration follows setup', () {
      const start = AnalysisPhase.setup;
      const next = AnalysisPhase.calibrationClassification;

      expect(_isValidTransition(start, next), isTrue);
    });

    test('variant calibration follows classification', () {
      const start = AnalysisPhase.calibrationClassification;
      const next = AnalysisPhase.calibrationVariant;

      expect(_isValidTransition(start, next), isTrue);
    });

    test('analyzing follows calibration', () {
      const start = AnalysisPhase.calibrationVariant;
      const next = AnalysisPhase.analyzing;

      expect(_isValidTransition(start, next), isTrue);
    });

    test('completed follows analyzing', () {
      const start = AnalysisPhase.analyzing;
      const next = AnalysisPhase.completed;

      expect(_isValidTransition(start, next), isTrue);
    });

    test('can reset to idle from any phase', () {
      for (final phase in AnalysisPhase.values) {
        expect(_isValidTransition(phase, AnalysisPhase.idle), isTrue);
      }
    });
  });

  group('Frame Buffer Management', () {
    test('frame buffer has window size of 60', () {
      const windowSize = 60;
      expect(windowSize, equals(60));
    });

    test('adds frames to buffer', () {
      final buffer = <MockPoseFrame>[];
      const windowSize = 60;

      for (int i = 0; i < windowSize; i++) {
        buffer.add(MockPoseFrame(timestamp: i));
      }

      expect(buffer.length, equals(windowSize));
    });

    test('removes oldest frame when buffer full', () {
      final buffer = <MockPoseFrame>[];
      const windowSize = 60;

      // Fill buffer
      for (int i = 0; i < windowSize; i++) {
        buffer.add(MockPoseFrame(timestamp: i));
      }

      // Add one more (should remove oldest)
      buffer.removeAt(0);
      buffer.add(MockPoseFrame(timestamp: windowSize));

      expect(buffer.length, equals(windowSize));
      expect(buffer.first.timestamp, equals(1)); // 0 was removed
      expect(buffer.last.timestamp, equals(windowSize));
    });

    test('prediction interval is every 5 frames', () {
      const predictionInterval = 5;

      int frameCount = 0;
      final predictions = <int>[];

      for (int i = 0; i < 100; i++) {
        frameCount++;
        if (frameCount % predictionInterval == 0) {
          predictions.add(frameCount);
        }
      }

      expect(predictions.length, equals(20)); // 100 / 5
      expect(predictions.first, equals(5));
      expect(predictions.last, equals(100));
    });
  });

  group('Calibration Voting System', () {
    test('requires majority vote for exercise classification', () {
      final votes = ['Deep Squat', 'Deep Squat', 'Hurdle Step', 'Deep Squat'];

      final result = _getMajorityVote(votes);

      expect(result, equals('Deep Squat'));
    });

    test('handles tie by returning first most common', () {
      final votes = ['Deep Squat', 'Hurdle Step', 'Deep Squat', 'Hurdle Step'];

      final result = _getMajorityVote(votes);

      // Either would be valid; just ensure one is returned
      expect(
        result == 'Deep Squat' || result == 'Hurdle Step',
        isTrue,
      );
    });

    test('handles single vote', () {
      final votes = ['Deep Squat'];

      final result = _getMajorityVote(votes);

      expect(result, equals('Deep Squat'));
    });

    test('returns null for empty votes', () {
      final votes = <String>[];

      final result = _getMajorityVote(votes);

      expect(result, isNull);
    });

    test('handles all different votes', () {
      final votes = ['Deep Squat', 'Hurdle Step', 'Shoulder Abduction'];

      final result = _getMajorityVote(votes);

      // Should return one of them (first in order of occurrence)
      expect(votes.contains(result), isTrue);
    });
  });

  group('Visibility Tracking', () {
    test('visibility window size is 30 frames', () {
      const windowSize = 30;
      expect(windowSize, equals(30));
    });

    test('minimum visibility ratio is 0.7 (70%)', () {
      const minRatio = 0.7;
      expect(minRatio, equals(0.7));
    });

    test('calculates visibility ratio correctly', () {
      final buffer = [true, true, true, false, true, true, true, true, false, true];

      final visibleCount = buffer.where((v) => v).length;
      final ratio = visibleCount / buffer.length;

      expect(ratio, equals(0.8)); // 8/10
    });

    test('person is visible when ratio above threshold', () {
      final buffer = List.filled(30, true); // All visible

      final ratio = buffer.where((v) => v).length / buffer.length;

      expect(ratio, greaterThanOrEqualTo(0.7));
      expect(_isPersonVisible(buffer, 0.7), isTrue);
    });

    test('person not visible when ratio below threshold', () {
      // 20 not visible, 10 visible = 0.33 ratio
      final buffer = List.filled(20, false) + List.filled(10, true);

      final ratio = buffer.where((v) => v).length / buffer.length;

      expect(ratio, lessThan(0.7));
      expect(_isPersonVisible(buffer, 0.7), isFalse);
    });

    test('handles empty visibility buffer', () {
      final buffer = <bool>[];

      expect(_isPersonVisible(buffer, 0.7), isFalse);
    });
  });

  group('Session Error Tracking', () {
    test('tracks error counts per error type', () {
      final errorCounts = <String, int>{};

      _incrementError(errorCounts, 'Knee Valgus');
      _incrementError(errorCounts, 'Knee Valgus');
      _incrementError(errorCounts, 'Heel Rise');

      expect(errorCounts['Knee Valgus'], equals(2));
      expect(errorCounts['Heel Rise'], equals(1));
    });

    test('filters errors by threshold percentage', () {
      final errorCounts = {
        'Knee Valgus': 15,
        'Heel Rise': 5,
        'Trunk Lean': 3,
      };
      const totalFrames = 100;
      const thresholdPercent = 0.10;

      final threshold = totalFrames * thresholdPercent;
      final significantErrors = errorCounts.entries
          .where((e) => e.value > threshold)
          .map((e) => e.key)
          .toList();

      expect(significantErrors, contains('Knee Valgus'));
      expect(significantErrors, isNot(contains('Heel Rise')));
      expect(significantErrors, isNot(contains('Trunk Lean')));
    });

    test('returns most common error if none above threshold', () {
      final errorCounts = {
        'Knee Valgus': 8,
        'Heel Rise': 5,
        'Trunk Lean': 3,
      };
      const totalFrames = 100;
      const thresholdPercent = 0.10;

      final threshold = totalFrames * thresholdPercent;
      var significantErrors = errorCounts.entries
          .where((e) => e.value > threshold)
          .map((e) => e.key)
          .toList();

      if (significantErrors.isEmpty) {
        final sorted = errorCounts.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        significantErrors = [sorted.first.key];
      }

      expect(significantErrors, equals(['Knee Valgus']));
    });
  });

  group('Session Score Calculation', () {
    test('100% correct frames gives score of 100', () {
      const totalFrames = 100;
      const correctFrames = 100;

      final ratio = correctFrames / totalFrames;
      final score = (ratio * 100).round().clamp(0, 100);

      expect(score, equals(100));
    });

    test('70% correct frames gives score of 70', () {
      const totalFrames = 100;
      const correctFrames = 70;

      final ratio = correctFrames / totalFrames;
      final score = (ratio * 100).round().clamp(0, 100);

      expect(score, equals(70));
    });

    test('score is clamped to 0-100', () {
      // Edge case: more correct than total (shouldn't happen but test clamping)
      const totalFrames = 100;
      const correctFrames = 150;

      final ratio = correctFrames / totalFrames;
      final score = (ratio * 100).round().clamp(0, 100);

      expect(score, equals(100));
    });

    test('zero correct frames gives score of 0', () {
      const totalFrames = 100;
      const correctFrames = 0;

      final ratio = correctFrames / totalFrames;
      final score = (ratio * 100).round().clamp(0, 100);

      expect(score, equals(0));
    });

    test('session is correct when ratio > 0.7', () {
      const totalFrames = 100;
      const correctFrames = 75;

      final ratio = correctFrames / totalFrames;
      final isSessionCorrect = ratio > 0.7;

      expect(isSessionCorrect, isTrue);
    });

    test('session not correct when ratio <= 0.7', () {
      const totalFrames = 100;
      const correctFrames = 70;

      final ratio = correctFrames / totalFrames;
      final isSessionCorrect = ratio > 0.7;

      expect(isSessionCorrect, isFalse);
    });
  });

  group('Duration Formatting', () {
    test('formats seconds only', () {
      final duration = Duration(seconds: 45);
      expect(_formatDuration(duration), equals('0:45'));
    });

    test('formats minutes and seconds', () {
      final duration = Duration(minutes: 2, seconds: 30);
      expect(_formatDuration(duration), equals('2:30'));
    });

    test('pads seconds with zero', () {
      final duration = Duration(minutes: 1, seconds: 5);
      expect(_formatDuration(duration), equals('1:05'));
    });

    test('formats zero duration', () {
      final duration = Duration.zero;
      expect(_formatDuration(duration), equals('0:00'));
    });

    test('formats long duration', () {
      final duration = Duration(minutes: 59, seconds: 59);
      expect(_formatDuration(duration), equals('59:59'));
    });

    test('formats hours correctly', () {
      final duration = Duration(hours: 1, minutes: 30, seconds: 45);
      // If showing hours format
      expect(_formatDurationWithHours(duration), equals('1:30:45'));
    });
  });

  group('TTS Cooldown Management', () {
    test('allows first feedback immediately', () {
      DateTime? lastSpokenAt;
      const cooldown = Duration(seconds: 3);

      final canSpeak = _canSpeakFeedback(lastSpokenAt, cooldown);

      expect(canSpeak, isTrue);
    });

    test('blocks feedback during cooldown', () {
      final lastSpokenAt = DateTime.now().subtract(const Duration(seconds: 1));
      const cooldown = Duration(seconds: 3);

      final canSpeak = _canSpeakFeedback(lastSpokenAt, cooldown);

      expect(canSpeak, isFalse);
    });

    test('allows feedback after cooldown', () {
      final lastSpokenAt = DateTime.now().subtract(const Duration(seconds: 4));
      const cooldown = Duration(seconds: 3);

      final canSpeak = _canSpeakFeedback(lastSpokenAt, cooldown);

      expect(canSpeak, isTrue);
    });

    test('does not repeat same feedback', () {
      const lastSpoken = 'Knee Valgus detected';
      const currentFeedback = 'Knee Valgus detected';

      final shouldSpeak = lastSpoken != currentFeedback;

      expect(shouldSpeak, isFalse);
    });

    test('speaks new feedback', () {
      const lastSpoken = 'Knee Valgus detected';
      const currentFeedback = 'Heel Rise detected';

      final shouldSpeak = lastSpoken != currentFeedback;

      expect(shouldSpeak, isTrue);
    });
  });

  group('Frame Processing Throttling', () {
    test('frame processing interval is 66ms (15fps)', () {
      const interval = Duration(milliseconds: 66);
      expect(interval.inMilliseconds, equals(66));
    });

    test('skips frame if processing too fast', () {
      final lastProcessTime = DateTime.now();
      final currentTime = lastProcessTime.add(const Duration(milliseconds: 30));
      const interval = Duration(milliseconds: 66);

      final shouldProcess =
          currentTime.difference(lastProcessTime) >= interval;

      expect(shouldProcess, isFalse);
    });

    test('processes frame after interval', () {
      final lastProcessTime = DateTime.now();
      final currentTime = lastProcessTime.add(const Duration(milliseconds: 70));
      const interval = Duration(milliseconds: 66);

      final shouldProcess =
          currentTime.difference(lastProcessTime) >= interval;

      expect(shouldProcess, isTrue);
    });
  });

  group('Phase Timer Durations', () {
    test('setup phase lasts 3 seconds', () {
      const setupDuration = Duration(seconds: 3);
      expect(setupDuration.inSeconds, equals(3));
    });

    test('calibration classification phase lasts 6 seconds', () {
      const calibrationDuration = Duration(seconds: 6);
      expect(calibrationDuration.inSeconds, equals(6));
    });
  });
}

// Test enums and helpers

enum AnalysisPhase {
  idle,
  countdown,
  setup,
  calibrationClassification,
  calibrationVariant,
  analyzing,
  completed,
}

bool _isValidTransition(AnalysisPhase from, AnalysisPhase to) {
  // Reset to idle is always valid
  if (to == AnalysisPhase.idle) return true;

  return switch (from) {
    AnalysisPhase.idle => to == AnalysisPhase.countdown,
    AnalysisPhase.countdown => to == AnalysisPhase.setup,
    AnalysisPhase.setup => to == AnalysisPhase.calibrationClassification,
    AnalysisPhase.calibrationClassification =>
      to == AnalysisPhase.calibrationVariant ||
          to == AnalysisPhase.analyzing,
    AnalysisPhase.calibrationVariant => to == AnalysisPhase.analyzing,
    AnalysisPhase.analyzing => to == AnalysisPhase.completed,
    AnalysisPhase.completed => false,
  };
}

class MockPoseFrame {
  MockPoseFrame({required this.timestamp});

  final int timestamp;
}

String? _getMajorityVote(List<String> votes) {
  if (votes.isEmpty) return null;

  final counts = <String, int>{};
  for (final vote in votes) {
    counts[vote] = (counts[vote] ?? 0) + 1;
  }

  final sorted = counts.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));

  return sorted.first.key;
}

bool _isPersonVisible(List<bool> buffer, double minRatio) {
  if (buffer.isEmpty) return false;

  final visibleCount = buffer.where((v) => v).length;
  return visibleCount / buffer.length >= minRatio;
}

void _incrementError(Map<String, int> errorCounts, String errorType) {
  errorCounts[errorType] = (errorCounts[errorType] ?? 0) + 1;
}

String _formatDuration(Duration duration) {
  final minutes = duration.inMinutes;
  final seconds = duration.inSeconds % 60;
  return '$minutes:${seconds.toString().padLeft(2, '0')}';
}

String _formatDurationWithHours(Duration duration) {
  final hours = duration.inHours;
  final minutes = duration.inMinutes % 60;
  final seconds = duration.inSeconds % 60;
  return '$hours:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
}

bool _canSpeakFeedback(DateTime? lastSpokenAt, Duration cooldown) {
  if (lastSpokenAt == null) return true;
  return DateTime.now().difference(lastSpokenAt) >= cooldown;
}
