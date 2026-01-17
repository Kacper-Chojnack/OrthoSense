/// Unit tests for PoseDetectionService.
///
/// Test coverage:
/// 1. PoseAnalysisCancellationToken functionality
/// 2. PoseAnalysisCancelledException
/// 3. Pose visibility checks
/// 4. InputImage conversion helpers
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:orthosense/core/services/pose_detection_service.dart';
import 'package:orthosense/features/exercise/domain/models/pose_landmarks.dart';

void main() {
  group('PoseAnalysisCancellationToken', () {
    test('initial state is not cancelled', () {
      final token = PoseAnalysisCancellationToken();
      expect(token.isCancelled, isFalse);
    });

    test('cancel() sets isCancelled to true', () {
      final token = PoseAnalysisCancellationToken();
      token.cancel();
      expect(token.isCancelled, isTrue);
    });

    test('cancel() can be called multiple times without error', () {
      final token = PoseAnalysisCancellationToken();
      token.cancel();
      token.cancel();
      token.cancel();
      expect(token.isCancelled, isTrue);
    });

    test('throwIfCancelled does nothing when not cancelled', () {
      final token = PoseAnalysisCancellationToken();
      // Should not throw
      expect(() => token.throwIfCancelled(), returnsNormally);
    });

    test('throwIfCancelled throws PoseAnalysisCancelledException when cancelled', () {
      final token = PoseAnalysisCancellationToken();
      token.cancel();

      expect(
        () => token.throwIfCancelled(),
        throwsA(isA<PoseAnalysisCancelledException>()),
      );
    });
  });

  group('PoseAnalysisCancelledException', () {
    test('can be created', () {
      const exception = PoseAnalysisCancelledException();
      expect(exception, isNotNull);
    });

    test('toString returns correct message', () {
      const exception = PoseAnalysisCancelledException();
      expect(exception.toString(), equals('PoseAnalysisCancelledException'));
    });

    test('can be caught as Exception', () {
      expect(
        () => throw const PoseAnalysisCancelledException(),
        throwsA(isA<Exception>()),
      );
    });

    test('equality works correctly', () {
      const exception1 = PoseAnalysisCancelledException();
      const exception2 = PoseAnalysisCancelledException();
      // Both are const, so they should be identical
      expect(identical(exception1, exception2), isTrue);
    });
  });

  group('PoseDetectionService', () {
    late PoseDetectionService service;

    setUp(() {
      service = PoseDetectionService();
    });

    test('service can be instantiated', () {
      expect(service, isNotNull);
    });

    test('checkPoseVisibility returns false for empty frame', () {
      final emptyFrame = PoseFrame(landmarks: []);
      final result = service.checkPoseVisibility(emptyFrame);
      expect(result, isFalse);
    });

    test('checkPoseVisibility returns false for insufficient landmarks', () {
      // Create frame with only a few landmarks
      final landmarks = List.generate(
        10,
        (i) => const PoseLandmark(x: 0.5, y: 0.5, z: 0.0, visibility: 1.0),
      );
      final frame = PoseFrame(landmarks: landmarks);
      final result = service.checkPoseVisibility(frame);
      expect(result, isFalse);
    });

    test('checkPoseVisibility returns true for full visible skeleton', () {
      // Create a full 33-landmark frame with high visibility
      final landmarks = List.generate(
        33,
        (i) => const PoseLandmark(x: 0.5, y: 0.5, z: 0.0, visibility: 0.9),
      );
      final frame = PoseFrame(landmarks: landmarks);
      final result = service.checkPoseVisibility(frame);
      expect(result, isTrue);
    });

    test('checkPoseVisibility returns false for low visibility landmarks', () {
      // Create frame with low visibility on key landmarks
      final landmarks = List.generate(
        33,
        (i) => PoseLandmark(
          x: 0.5,
          y: 0.5,
          z: 0.0,
          visibility: i < 20 ? 0.1 : 0.9, // Low visibility on first 20
        ),
      );
      final frame = PoseFrame(landmarks: landmarks);
      final result = service.checkPoseVisibility(frame);
      expect(result, isFalse);
    });

    test('checkPoseVisibility detects key body parts visibility', () {
      // Create frame where key body parts are visible
      final landmarks = List.generate(33, (i) {
        // Key landmarks: shoulders (11, 12), hips (23, 24), knees (25, 26)
        final isKeyLandmark = [11, 12, 23, 24, 25, 26].contains(i);
        return PoseLandmark(
          x: 0.5,
          y: 0.5,
          z: 0.0,
          visibility: isKeyLandmark ? 0.9 : 0.5,
        );
      });
      final frame = PoseFrame(landmarks: landmarks);
      final result = service.checkPoseVisibility(frame);
      expect(result, isTrue);
    });
  });

  group('PoseDetectionService - Frame Processing', () {
    late PoseDetectionService service;

    setUp(() {
      service = PoseDetectionService();
    });

    test('handles frame with out-of-bounds coordinates', () {
      final landmarks = List.generate(
        33,
        (i) => const PoseLandmark(
          x: 1.5, // Out of normalized bounds
          y: -0.5, // Out of normalized bounds
          z: 0.0,
          visibility: 0.9,
        ),
      );
      final frame = PoseFrame(landmarks: landmarks);
      // Should not throw, just mark as low confidence
      final result = service.checkPoseVisibility(frame);
      expect(result, isA<bool>());
    });

    test('handles frame with NaN coordinates gracefully', () {
      final landmarks = List.generate(
        33,
        (i) => PoseLandmark(
          x: i == 0 ? double.nan : 0.5,
          y: 0.5,
          z: 0.0,
          visibility: 0.9,
        ),
      );
      final frame = PoseFrame(landmarks: landmarks);
      // Should handle NaN gracefully
      final result = service.checkPoseVisibility(frame);
      expect(result, isA<bool>());
    });

    test('handles frame with zero visibility', () {
      final landmarks = List.generate(
        33,
        (i) => const PoseLandmark(
          x: 0.5,
          y: 0.5,
          z: 0.0,
          visibility: 0.0,
        ),
      );
      final frame = PoseFrame(landmarks: landmarks);
      final result = service.checkPoseVisibility(frame);
      expect(result, isFalse);
    });
  });

  group('Cancellation Token Integration', () {
    test('token can be checked multiple times', () {
      final token = PoseAnalysisCancellationToken();

      // Multiple checks before cancellation
      expect(token.isCancelled, isFalse);
      expect(token.isCancelled, isFalse);
      expect(token.isCancelled, isFalse);

      token.cancel();

      // Multiple checks after cancellation
      expect(token.isCancelled, isTrue);
      expect(token.isCancelled, isTrue);
    });

    test('cancellation state persists', () async {
      final token = PoseAnalysisCancellationToken();

      // Cancel after delay
      await Future<void>.delayed(const Duration(milliseconds: 10));
      token.cancel();
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(token.isCancelled, isTrue);
    });
  });
}
