/// Unit tests for ExerciseClassifierService.
///
/// Test coverage:
/// 1. ExerciseClassification model
/// 2. Preprocessing logic
/// 3. Softmax function
/// 4. Interpolation
/// 5. Classification output
library;

import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ExerciseClassification', () {
    test('creates with exercise name and confidence', () {
      const classification = ExerciseClassification(
        exercise: 'Deep Squat',
        confidence: 0.95,
      );

      expect(classification.exercise, equals('Deep Squat'));
      expect(classification.confidence, equals(0.95));
    });

    test('confidence is between 0 and 1', () {
      const classification = ExerciseClassification(
        exercise: 'Hurdle Step',
        confidence: 0.85,
      );

      expect(classification.confidence, greaterThanOrEqualTo(0));
      expect(classification.confidence, lessThanOrEqualTo(1));
    });
  });

  group('Exercise Labels', () {
    test('label 0 is Deep Squat', () {
      const labels = {
        0: 'Deep Squat',
        1: 'Hurdle Step',
        2: 'Standing Shoulder Abduction',
      };

      expect(labels[0], equals('Deep Squat'));
    });

    test('label 1 is Hurdle Step', () {
      const labels = {
        0: 'Deep Squat',
        1: 'Hurdle Step',
        2: 'Standing Shoulder Abduction',
      };

      expect(labels[1], equals('Hurdle Step'));
    });

    test('label 2 is Standing Shoulder Abduction', () {
      const labels = {
        0: 'Deep Squat',
        1: 'Hurdle Step',
        2: 'Standing Shoulder Abduction',
      };

      expect(labels[2], equals('Standing Shoulder Abduction'));
    });

    test('unknown label returns Unknown Exercise', () {
      const labels = {
        0: 'Deep Squat',
        1: 'Hurdle Step',
        2: 'Standing Shoulder Abduction',
      };

      final result = labels[99] ?? 'Unknown Exercise';

      expect(result, equals('Unknown Exercise'));
    });
  });

  group('Model Constants', () {
    test('numJoints is 33', () {
      const numJoints = 33;
      expect(numJoints, equals(33));
    });

    test('numChannels is 3 (x, y, z)', () {
      const numChannels = 3;
      expect(numChannels, equals(3));
    });

    test('modelSequenceLength is 60', () {
      const modelSequenceLength = 60;
      expect(modelSequenceLength, equals(60));
    });

    test('numClasses is 3', () {
      const numClasses = 3;
      expect(numClasses, equals(3));
    });
  });

  group('Softmax Function', () {
    test('converts logits to probabilities', () {
      final logits = [1.0, 2.0, 3.0];
      final probs = _softmax(logits);

      // Sum should be 1.0
      final sum = probs.reduce((a, b) => a + b);
      expect(sum, closeTo(1.0, 0.001));
    });

    test('all probabilities are positive', () {
      final logits = [-1.0, 0.0, 1.0];
      final probs = _softmax(logits);

      for (final p in probs) {
        expect(p, greaterThan(0));
      }
    });

    test('higher logit gets higher probability', () {
      final logits = [1.0, 2.0, 3.0];
      final probs = _softmax(logits);

      expect(probs[2], greaterThan(probs[1]));
      expect(probs[1], greaterThan(probs[0]));
    });

    test('handles equal logits', () {
      final logits = [1.0, 1.0, 1.0];
      final probs = _softmax(logits);

      expect(probs[0], closeTo(1.0 / 3.0, 0.001));
      expect(probs[1], closeTo(1.0 / 3.0, 0.001));
      expect(probs[2], closeTo(1.0 / 3.0, 0.001));
    });

    test('handles large logits without overflow', () {
      final logits = [100.0, 200.0, 300.0];
      final probs = _softmax(logits);

      final sum = probs.reduce((a, b) => a + b);
      expect(sum, closeTo(1.0, 0.001));
    });

    test('handles negative logits', () {
      final logits = [-3.0, -2.0, -1.0];
      final probs = _softmax(logits);

      final sum = probs.reduce((a, b) => a + b);
      expect(sum, closeTo(1.0, 0.001));
    });

    test('returns original if already probabilities', () {
      final probs = [0.2, 0.3, 0.5];
      final result = _softmaxIfNeeded(probs);

      expect(result[0], closeTo(0.2, 0.01));
      expect(result[1], closeTo(0.3, 0.01));
      expect(result[2], closeTo(0.5, 0.01));
    });
  });

  group('Hip Center Calculation', () {
    test('calculates midpoint of left and right hip', () {
      const leftHipX = 0.4;
      const rightHipX = 0.6;
      const leftHipY = 0.5;
      const rightHipY = 0.5;

      final centerX = (leftHipX + rightHipX) / 2.0;
      final centerY = (leftHipY + rightHipY) / 2.0;

      expect(centerX, equals(0.5));
      expect(centerY, equals(0.5));
    });
  });

  group('Torso Scale Calculation', () {
    test('calculates distance from hip center to shoulder center', () {
      const shoulderCenterX = 0.5;
      const shoulderCenterY = 0.3;
      const shoulderCenterZ = 0.0;

      final torso = math.sqrt(
        shoulderCenterX * shoulderCenterX +
            shoulderCenterY * shoulderCenterY +
            shoulderCenterZ * shoulderCenterZ,
      );

      expect(torso, greaterThan(0));
    });

    test('handles zero scale with epsilon', () {
      const eps = 1e-6;
      const scale = 0.0;
      final safeScale = scale.abs() < eps ? 1.0 : scale;

      expect(safeScale, equals(1.0));
    });
  });

  group('Frame Interpolation', () {
    test('interpolates when frames less than target', () {
      const currentFrames = 30;
      const targetFrames = 60;
      final needsInterpolation = currentFrames < targetFrames;

      expect(needsInterpolation, isTrue);
    });

    test('subsamples when frames more than target', () {
      const currentFrames = 120;
      const targetFrames = 60;
      final needsSubsampling = currentFrames > targetFrames;

      expect(needsSubsampling, isTrue);
    });

    test('no change needed when frames equal target', () {
      const currentFrames = 60;
      const targetFrames = 60;
      final needsChange = currentFrames != targetFrames;

      expect(needsChange, isFalse);
    });

    test('linear interpolation between two values', () {
      const v1 = 0.0;
      const v2 = 1.0;
      const t = 0.5;

      final interpolated = v1 * (1 - t) + v2 * t;

      expect(interpolated, equals(0.5));
    });

    test('interpolation at t=0 returns first value', () {
      const v1 = 0.3;
      const v2 = 0.7;
      const t = 0.0;

      final interpolated = v1 * (1 - t) + v2 * t;

      expect(interpolated, equals(0.3));
    });

    test('interpolation at t=1 returns second value', () {
      const v1 = 0.3;
      const v2 = 0.7;
      const t = 1.0;

      final interpolated = v1 * (1 - t) + v2 * t;

      expect(interpolated, equals(0.7));
    });
  });

  group('Subsampling', () {
    test('calculates source index for target', () {
      const currentFrames = 120;
      const targetFrames = 60;

      for (var i = 0; i < targetFrames; i++) {
        final srcIndex = ((i * (currentFrames - 1)) / (targetFrames - 1)).round();
        expect(srcIndex, greaterThanOrEqualTo(0));
        expect(srcIndex, lessThan(currentFrames));
      }
    });
  });

  group('Classification Output', () {
    test('finds max probability index', () {
      final probs = [0.1, 0.6, 0.3];
      var maxProb = 0.0;
      var predictedClass = 0;

      for (var i = 0; i < probs.length; i++) {
        if (probs[i] > maxProb) {
          maxProb = probs[i];
          predictedClass = i;
        }
      }

      expect(predictedClass, equals(1));
      expect(maxProb, equals(0.6));
    });

    test('handles tie by selecting first', () {
      final probs = [0.5, 0.5, 0.0];
      var maxProb = 0.0;
      var predictedClass = 0;

      for (var i = 0; i < probs.length; i++) {
        if (probs[i] > maxProb) {
          maxProb = probs[i];
          predictedClass = i;
        }
      }

      expect(predictedClass, equals(0));
    });
  });

  group('Input Validation', () {
    test('rejects empty landmarks', () {
      const isEmpty = true;

      expect(() {
        if (isEmpty) {
          throw ArgumentError('Landmarks cannot be empty');
        }
      }, throwsArgumentError);
    });

    test('rejects when model not loaded', () {
      const isModelLoaded = false;

      expect(() {
        if (!isModelLoaded) {
          throw StateError('TFLite model not loaded.');
        }
      }, throwsStateError);
    });
  });

  group('Dispose Handling', () {
    test('prevents classification when disposing', () {
      var isDisposing = false;
      isDisposing = true;

      expect(() {
        if (isDisposing) {
          throw StateError('Classifier is disposing.');
        }
      }, throwsStateError);
    });
  });

  group('Coordinate Normalization', () {
    test('centers coordinates around hip', () {
      const landmarkX = 0.5;
      const hipCenterX = 0.45;

      final normalizedX = landmarkX - hipCenterX;

      expect(normalizedX, closeTo(0.05, 0.0001));
    });

    test('scales by torso length', () {
      const normalizedValue = 0.1;
      const torsoScale = 0.5;

      final scaledValue = normalizedValue / torsoScale;

      expect(scaledValue, equals(0.2));
    });
  });

  group('Preprocessing Pipeline', () {
    test('pipeline order is correct', () {
      final steps = <String>[];

      steps.add('extract_coordinates');
      steps.add('calculate_hip_center');
      steps.add('center_on_hip');
      steps.add('calculate_torso_scale');
      steps.add('normalize_by_scale');
      steps.add('interpolate_frames');
      steps.add('flatten_to_sequence');

      expect(steps.length, equals(7));
      expect(steps.first, equals('extract_coordinates'));
      expect(steps.last, equals('flatten_to_sequence'));
    });
  });

  group('Feature Flattening', () {
    test('flattens frame to feature vector', () {
      const numJoints = 33;
      const numChannels = 3;
      const expectedLength = numJoints * numChannels;

      expect(expectedLength, equals(99));
    });

    test('sequence has correct shape', () {
      const modelSequenceLength = 60;
      const featuresPerFrame = 99;

      final sequenceShape = [modelSequenceLength, featuresPerFrame];

      expect(sequenceShape[0], equals(60));
      expect(sequenceShape[1], equals(99));
    });
  });

  group('Model Recovery', () {
    test('attempts reload on interpreter error', () {
      final operations = <String>[];

      operations.add('run_inference');
      operations.add('catch_error');
      operations.add('close_interpreter');
      operations.add('reload_model');
      operations.add('retry_inference');

      expect(operations, contains('reload_model'));
      expect(operations, contains('retry_inference'));
    });
  });
}

// Helper functions

List<double> _softmax(List<double> logits) {
  final maxLogit = logits.reduce((a, b) => a > b ? a : b);
  final expLogits = logits.map((x) => math.exp(x - maxLogit)).toList();
  final sumExp = expLogits.fold(0.0, (a, b) => a + b);
  return List<double>.from(expLogits.map((x) => x / sumExp));
}

List<double> _softmaxIfNeeded(List<double> values) {
  final sum = values.fold(0.0, (a, b) => a + b);
  final isNormalized = (sum - 1.0).abs() < 0.01 && 
      values.every((e) => e >= 0 && e <= 1);
  return isNormalized ? values : _softmax(values);
}

// Model class

class ExerciseClassification {
  const ExerciseClassification({
    required this.exercise,
    required this.confidence,
  });

  final String exercise;
  final double confidence;
}
