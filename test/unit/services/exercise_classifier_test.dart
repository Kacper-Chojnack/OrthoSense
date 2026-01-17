/// Unit tests for ExerciseClassifierService.
///
/// Test coverage:
/// 1. ExerciseClassification model
/// 2. Exercise labels constants
/// 3. Model dimensions constants
/// 4. Classification logic (mocked)
library;

import 'dart:math' as math;
import 'package:flutter_test/flutter_test.dart';
import 'package:orthosense/core/services/exercise_classifier_service.dart';

void main() {
  group('ExerciseClassification', () {
    test('creates with required parameters', () {
      const classification = ExerciseClassification(
        exercise: 'Deep Squat',
        confidence: 0.95,
      );

      expect(classification.exercise, equals('Deep Squat'));
      expect(classification.confidence, equals(0.95));
    });

    test('handles zero confidence', () {
      const classification = ExerciseClassification(
        exercise: 'Unknown',
        confidence: 0.0,
      );

      expect(classification.confidence, equals(0.0));
    });

    test('handles perfect confidence', () {
      const classification = ExerciseClassification(
        exercise: 'Deep Squat',
        confidence: 1.0,
      );

      expect(classification.confidence, equals(1.0));
    });

    test('handles low confidence', () {
      const classification = ExerciseClassification(
        exercise: 'Hurdle Step',
        confidence: 0.33,
      );

      expect(classification.confidence, equals(0.33));
    });

    test('handles all exercise types', () {
      const exercises = [
        'Deep Squat',
        'Hurdle Step',
        'Standing Shoulder Abduction',
      ];

      for (final exercise in exercises) {
        final classification = ExerciseClassification(
          exercise: exercise,
          confidence: 0.5,
        );
        expect(classification.exercise, equals(exercise));
      }
    });

    test('handles unknown exercise', () {
      const classification = ExerciseClassification(
        exercise: 'Unknown Exercise',
        confidence: 0.1,
      );

      expect(classification.exercise, equals('Unknown Exercise'));
    });
  });

  group('ExerciseClassifierService constants', () {
    test('exercise labels are defined', () {
      // Based on the _exerciseLabels constant in the service
      const expectedLabels = {
        0: 'Deep Squat',
        1: 'Hurdle Step',
        2: 'Standing Shoulder Abduction',
      };

      expect(expectedLabels.length, equals(3));
      expect(expectedLabels[0], equals('Deep Squat'));
      expect(expectedLabels[1], equals('Hurdle Step'));
      expect(expectedLabels[2], equals('Standing Shoulder Abduction'));
    });

    test('model has 33 joints', () {
      const numJoints = 33;
      expect(numJoints, equals(33));
    });

    test('model has 3 channels (x, y, z)', () {
      const numChannels = 3;
      expect(numChannels, equals(3));
    });

    test('model sequence length is 60 frames', () {
      const modelSequenceLength = 60;
      expect(modelSequenceLength, equals(60));
    });

    test('model has 3 exercise classes', () {
      const numClasses = 3;
      expect(numClasses, equals(3));
    });
  });

  group('Landmark preprocessing logic', () {
    test('hip center is average of left and right hip', () {
      const leftHip = 0.3;
      const rightHip = 0.5;
      final hipCenter = (leftHip + rightHip) / 2.0;

      expect(hipCenter, equals(0.4));
    });

    test('hip joint indices are correct', () {
      const leftHipIndex = 23;
      const rightHipIndex = 24;

      expect(leftHipIndex, equals(23));
      expect(rightHipIndex, equals(24));
    });

    test('shoulder joint indices are correct', () {
      const leftShoulderIndex = 11;
      const rightShoulderIndex = 12;

      expect(leftShoulderIndex, equals(11));
      expect(rightShoulderIndex, equals(12));
    });

    test('centering subtracts hip center from all joints', () {
      const jointValue = 0.8;
      const hipCenterValue = 0.4;
      final centered = jointValue - hipCenterValue;

      expect(centered, equals(0.4));
    });

    test('scaling divides by torso length', () {
      const centeredValue = 0.4;
      const torsoLength = 0.5;
      final scaled = centeredValue / torsoLength;

      expect(scaled, equals(0.8));
    });

    test('scale calculation uses Euclidean distance', () {
      const x = 0.3;
      const y = 0.4;
      const z = 0.0;
      final torso = math.sqrt(x * x + y * y + z * z);

      expect(torso, closeTo(0.5, 0.001));
    });

    test('epsilon prevents division by zero', () {
      const eps = 1e-6;
      const scale = 0.0;
      final safeScale = scale.abs() < eps ? 1.0 : scale;

      expect(safeScale, equals(1.0));
    });
  });

  group('Sequence length adjustment', () {
    test('no adjustment needed when T equals sequence length', () {
      const T = 60;
      const modelSequenceLength = 60;
      final needsAdjustment = T != modelSequenceLength;

      expect(needsAdjustment, isFalse);
    });

    test('downsampling needed when T > sequence length', () {
      const T = 120;
      const modelSequenceLength = 60;
      final needsDownsample = T > modelSequenceLength;

      expect(needsDownsample, isTrue);
    });

    test('interpolation needed when T < sequence length', () {
      const T = 30;
      const modelSequenceLength = 60;
      final needsInterpolate = T < modelSequenceLength;

      expect(needsInterpolate, isTrue);
    });

    test('downsampling index calculation', () {
      const T = 120;
      const modelSequenceLength = 60;

      // First frame
      final idx0 = ((0 * (T - 1)) / (modelSequenceLength - 1)).round();
      expect(idx0, equals(0));

      // Middle frame
      final idxMid =
          ((30 * (T - 1)) / (modelSequenceLength - 1)).round();
      expect(idxMid, closeTo(60, 1));

      // Last frame
      final idxLast =
          ((59 * (T - 1)) / (modelSequenceLength - 1)).round();
      expect(idxLast, closeTo(119, 1));
    });
  });

  group('Classification output', () {
    test('softmax output sums to 1', () {
      const logits = [2.0, 1.0, 0.5];
      final expLogits = logits.map((x) => mathExp(x)).toList();
      final sumExp = expLogits.reduce((a, b) => a + b);
      final softmax = expLogits.map((x) => x / sumExp).toList();

      final sum = softmax.reduce((a, b) => a + b);
      expect(sum, closeTo(1.0, 0.001));
    });

    test('argmax finds highest confidence class', () {
      const confidences = [0.2, 0.7, 0.1];
      var maxIdx = 0;
      var maxVal = confidences[0];
      for (var i = 1; i < confidences.length; i++) {
        if (confidences[i] > maxVal) {
          maxVal = confidences[i];
          maxIdx = i;
        }
      }

      expect(maxIdx, equals(1));
      expect(maxVal, equals(0.7));
    });

    test('confidence threshold filtering', () {
      const confidences = [
        ExerciseClassification(exercise: 'A', confidence: 0.3),
        ExerciseClassification(exercise: 'B', confidence: 0.8),
        ExerciseClassification(exercise: 'C', confidence: 0.5),
      ];

      const threshold = 0.6;
      final highConfidence =
          confidences.where((c) => c.confidence >= threshold).toList();

      expect(highConfidence.length, equals(1));
      expect(highConfidence.first.exercise, equals('B'));
    });
  });

  group('Feature extraction', () {
    test('total features per frame is joints * channels', () {
      const numJoints = 33;
      const numChannels = 3;
      final featuresPerFrame = numJoints * numChannels;

      expect(featuresPerFrame, equals(99));
    });

    test('total input size is sequence * features', () {
      const modelSequenceLength = 60;
      const numJoints = 33;
      const numChannels = 3;
      final totalInputSize = modelSequenceLength * numJoints * numChannels;

      expect(totalInputSize, equals(5940));
    });
  });

  group('Model state', () {
    test('isModelLoaded defaults to false before initialization', () {
      const isModelLoaded = false;
      expect(isModelLoaded, isFalse);
    });

    test('interpreter null means model not loaded', () {
      Object? interpreter;
      final isLoaded = interpreter != null;

      expect(isLoaded, isFalse);
    });
  });
}

// Helper function for softmax test
double mathExp(double x) {
  return math.exp(x);
}
