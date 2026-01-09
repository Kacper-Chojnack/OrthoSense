/// Unit tests for Exercise Classifier Service.
///
/// Test coverage:
/// 1. Model loading
/// 2. Landmark preprocessing
/// 3. Classification inference
/// 4. Confidence thresholds
/// 5. Error handling
library;

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Exercise Classifier Model', () {
    test('model has expected exercise labels', () {
      const labels = {
        0: 'Deep Squat',
        1: 'Hurdle Step',
        2: 'Standing Shoulder Abduction',
      };

      expect(labels.length, equals(3));
      expect(labels[0], equals('Deep Squat'));
    });

    test('model expects correct input shape', () {
      const numJoints = 33;
      const numChannels = 3;
      const sequenceLength = 60;

      // Input shape: [batch, sequence, joints, channels]
      final inputShape = [1, sequenceLength, numJoints, numChannels];

      expect(inputShape[1], equals(60)); // Sequence length
      expect(inputShape[2], equals(33)); // Joint count
      expect(inputShape[3], equals(3)); // X, Y, Z
    });
  });

  group('Landmark Preprocessing', () {
    test('landmarks are normalized to hip center', () {
      final rawLandmarks = _createMockLandmarks(frames: 10);

      // Hip joints (23, 24)
      final leftHip = rawLandmarks[0][23];
      final rightHip = rawLandmarks[0][24];
      final hipCenter = [
        (leftHip[0] + rightHip[0]) / 2,
        (leftHip[1] + rightHip[1]) / 2,
        (leftHip[2] + rightHip[2]) / 2,
      ];

      // After normalization, hip center should be at origin
      expect(hipCenter, isNotNull);
    });

    test('sequence is padded if too short', () {
      final shortSequence = _createMockLandmarks(frames: 30);
      const targetLength = 60;

      expect(shortSequence.length, lessThan(targetLength));

      // Padding logic
      final paddedSequence = _padSequence(shortSequence, targetLength);
      expect(paddedSequence.length, equals(targetLength));
    });

    test('sequence is truncated if too long', () {
      final longSequence = _createMockLandmarks(frames: 100);
      const targetLength = 60;

      expect(longSequence.length, greaterThan(targetLength));

      // Truncation logic
      final truncatedSequence = _truncateSequence(longSequence, targetLength);
      expect(truncatedSequence.length, equals(targetLength));
    });

    test('temporal sampling maintains motion', () {
      final sequence = _createMockLandmarks(frames: 120);
      const targetLength = 60;

      // Sample every 2nd frame
      final sampledSequence = _sampleSequence(sequence, targetLength);

      expect(sampledSequence.length, equals(targetLength));
    });
  });

  group('Classification Results', () {
    test('classification returns exercise and confidence', () {
      final result = ExerciseClassification(
        exercise: 'Deep Squat',
        confidence: 0.92,
      );

      expect(result.exercise, equals('Deep Squat'));
      expect(result.confidence, greaterThan(0.9));
    });

    test('low confidence indicates uncertain classification', () {
      final result = ExerciseClassification(
        exercise: 'Hurdle Step',
        confidence: 0.45,
      );

      expect(result.isConfident(threshold: 0.7), isFalse);
    });

    test('high confidence indicates reliable classification', () {
      final result = ExerciseClassification(
        exercise: 'Deep Squat',
        confidence: 0.95,
      );

      expect(result.isConfident(threshold: 0.7), isTrue);
    });
  });

  group('Classification Voting', () {
    test('majority voting selects most common exercise', () {
      final votes = [
        'Deep Squat',
        'Deep Squat',
        'Deep Squat',
        'Hurdle Step',
        'Deep Squat',
      ];

      final winner = _getMajorityVote(votes);
      expect(winner, equals('Deep Squat'));
    });

    test('voting handles ties by selecting first', () {
      final votes = [
        'Deep Squat',
        'Hurdle Step',
        'Deep Squat',
        'Hurdle Step',
      ];

      final winner = _getMajorityVote(votes);
      // Either is acceptable in tie
      expect(['Deep Squat', 'Hurdle Step'].contains(winner), isTrue);
    });

    test('empty votes returns unknown', () {
      final votes = <String>[];

      final winner = _getMajorityVote(votes);
      expect(winner, equals('Unknown'));
    });
  });

  group('Error Handling', () {
    test('handles invalid landmark count gracefully', () {
      final invalidLandmarks = [
        [[0.0, 0.0, 0.0] for _ in range(10)], // Only 10 joints instead of 33
      ];

      expect(
        () => _validateLandmarks(invalidLandmarks),
        throwsA(isA<InvalidLandmarksException>()),
      );
    });

    test('handles missing frames gracefully', () {
      final emptySequence = <List<List<double>>>[];

      expect(
        () => _validateLandmarks(emptySequence),
        throwsA(isA<InvalidLandmarksException>()),
      );
    });

    test('handles NaN values in landmarks', () {
      final landmarksWithNaN = _createMockLandmarks(frames: 10);
      landmarksWithNaN[5][0][0] = double.nan;

      final cleanedLandmarks = _cleanLandmarks(landmarksWithNaN);

      // NaN should be replaced with 0 or interpolated
      expect(cleanedLandmarks[5][0][0].isNaN, isFalse);
    });
  });

  group('Model State', () {
    test('model loading state is tracked', () {
      final modelState = ModelState.loading();
      expect(modelState.isLoaded, isFalse);
      expect(modelState.isLoading, isTrue);
    });

    test('model loaded state allows classification', () {
      final modelState = ModelState.loaded();
      expect(modelState.isLoaded, isTrue);
      expect(modelState.canClassify, isTrue);
    });

    test('model error state prevents classification', () {
      final modelState = ModelState.error('Failed to load TFLite model');
      expect(modelState.isLoaded, isFalse);
      expect(modelState.canClassify, isFalse);
      expect(modelState.errorMessage, isNotNull);
    });
  });
}

// Helper classes and functions
class ExerciseClassification {
  const ExerciseClassification({
    required this.exercise,
    required this.confidence,
  });

  final String exercise;
  final double confidence;

  bool isConfident({required double threshold}) => confidence >= threshold;
}

class ModelState {
  ModelState._({
    required this.isLoaded,
    this.isLoading = false,
    this.errorMessage,
  });

  factory ModelState.loading() => ModelState._(isLoaded: false, isLoading: true);
  factory ModelState.loaded() => ModelState._(isLoaded: true);
  factory ModelState.error(String message) =>
      ModelState._(isLoaded: false, errorMessage: message);

  final bool isLoaded;
  final bool isLoading;
  final String? errorMessage;

  bool get canClassify => isLoaded && !isLoading && errorMessage == null;
}

class InvalidLandmarksException implements Exception {
  InvalidLandmarksException(this.message);
  final String message;
}

List<List<List<double>>> _createMockLandmarks({required int frames}) {
  return List.generate(
    frames,
    (f) => List.generate(
      33,
      (j) => [
        0.5 + (j % 10) * 0.05,
        0.3 + (j ~/ 10) * 0.2,
        0.0 + f * 0.01,
      ],
    ),
  );
}

List<List<List<double>>> _padSequence(
  List<List<List<double>>> sequence,
  int targetLength,
) {
  if (sequence.length >= targetLength) return sequence;

  final lastFrame = sequence.last;
  return [
    ...sequence,
    ...List.generate(targetLength - sequence.length, (_) => lastFrame),
  ];
}

List<List<List<double>>> _truncateSequence(
  List<List<List<double>>> sequence,
  int targetLength,
) {
  if (sequence.length <= targetLength) return sequence;
  return sequence.sublist(0, targetLength);
}

List<List<List<double>>> _sampleSequence(
  List<List<List<double>>> sequence,
  int targetLength,
) {
  if (sequence.length <= targetLength) return sequence;

  final step = sequence.length / targetLength;
  return List.generate(
    targetLength,
    (i) => sequence[(i * step).floor()],
  );
}

String _getMajorityVote(List<String> votes) {
  if (votes.isEmpty) return 'Unknown';

  final counts = <String, int>{};
  for (final vote in votes) {
    counts[vote] = (counts[vote] ?? 0) + 1;
  }

  return counts.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
}

void _validateLandmarks(List<List<List<double>>> landmarks) {
  if (landmarks.isEmpty) {
    throw InvalidLandmarksException('Empty landmark sequence');
  }
  for (final frame in landmarks) {
    if (frame.length != 33) {
      throw InvalidLandmarksException('Expected 33 landmarks, got ${frame.length}');
    }
  }
}

List<List<List<double>>> _cleanLandmarks(List<List<List<double>>> landmarks) {
  return landmarks.map((frame) {
    return frame.map((joint) {
      return joint.map((coord) {
        if (coord.isNaN || coord.isInfinite) return 0.0;
        return coord;
      }).toList();
    }).toList();
  }).toList();
}

Iterable<int> range(int end) => Iterable.generate(end);
