import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:orthosense/features/exercise/domain/models/pose_landmarks.dart';

class ExerciseClassification {
  const ExerciseClassification({
    required this.exercise,
    required this.confidence,
  });

  final String exercise;
  final double confidence;
}

class ExerciseClassifierService {
  ExerciseClassifierService() {
    _initialize();
  }

  Interpreter? _interpreter;
  bool _isModelLoaded = false;

  static const Map<int, String> _exerciseLabels = {
    0: 'Deep Squat',
    1: 'Hurdle Step',
    2: 'Standing Shoulder Abduction',
  };

  static const int _numJoints = 33;
  static const int _numChannels = 3;
  static const int _modelSequenceLength = 60;
  static const int _numClasses = 3;

  Future<void> _initialize() async {
    try {
      await _loadModel();
    } catch (e) {
      debugPrint('Error initializing ExerciseClassifierService: $e');
    }
  }

  Future<void> _loadModel() async {
    if (_isModelLoaded) return;

    try {
      final modelPath = 'assets/models/exercise_classifier.tflite';
      _interpreter = await Interpreter.fromAsset(modelPath);
      _isModelLoaded = true;
    } catch (e) {
      debugPrint('Failed to load TFLite model: $e');
      _isModelLoaded = false;
    }
  }

  bool get isModelLoaded => _isModelLoaded && _interpreter != null;

  List<List<List<double>>> _preprocessLandmarks(PoseLandmarks landmarks) {
    final frames = landmarks.frames;
    final T = frames.length;

    final data = List.generate(
      T,
      (t) => List.generate(
        _numJoints,
        (v) => List.generate(
          _numChannels,
          (c) {
            final landmark = frames[t].landmarks[v];
            switch (c) {
              case 0:
                return landmark.x;
              case 1:
                return landmark.y;
              case 2:
                return landmark.z;
              default:
                return 0.0;
            }
          },
        ),
      ),
    );

    final hipCenter = List.generate(
      T,
      (t) => List.generate(
        _numChannels,
        (c) {
          final leftHip = data[t][23][c];
          final rightHip = data[t][24][c];
          return (leftHip + rightHip) / 2.0;
        },
      ),
    );

    for (var t = 0; t < T; t++) {
      for (var v = 0; v < _numJoints; v++) {
        for (var c = 0; c < _numChannels; c++) {
          data[t][v][c] = data[t][v][c] - hipCenter[t][c];
        }
      }
    }

    List<List<List<double>>> interpolatedData = data;
    if (T != _modelSequenceLength) {
      interpolatedData = _interpolateFrames(data, T, _modelSequenceLength);
    }

    List<List<double>> sequence = [];

    for (var t = 0; t < _modelSequenceLength; t++) {
      List<double> frameFeatures = [];
      for (var v = 0; v < _numJoints; v++) {
        for (var c = 0; c < _numChannels; c++) {
          frameFeatures.add(interpolatedData[t][v][c]);
        }
      }
      sequence.add(frameFeatures);
    }

    return [sequence];
  }

  List<List<List<double>>> _interpolateFrames(
    List<List<List<double>>> data,
    int currentFrames,
    int targetFrames,
  ) {
    if (currentFrames == targetFrames) return data;

    final interpolated = List.generate(
      targetFrames,
      (t) => List.generate(
        _numJoints,
        (v) => List.generate(_numChannels, (c) => 0.0),
      ),
    );

    for (var v = 0; v < _numJoints; v++) {
      for (var c = 0; c < _numChannels; c++) {
        final sequence = List.generate(
          currentFrames,
          (t) => data[t][v][c],
        );

        if (targetFrames == 1) {
          final midIndex = (currentFrames / 2).floor();
          interpolated[0][v][c] =
              sequence[midIndex.clamp(0, currentFrames - 1)];
        } else {
          for (var t = 0; t < targetFrames; t++) {
            final ratio = t / (targetFrames - 1);
            final sourceIndex = ratio * (currentFrames - 1);
            final lower = sourceIndex.floor();
            final upper = sourceIndex.ceil().clamp(0, currentFrames - 1);
            final fraction = sourceIndex - lower;

            if (lower == upper) {
              interpolated[t][v][c] = sequence[lower];
            } else {
              interpolated[t][v][c] =
                  sequence[lower] * (1 - fraction) + sequence[upper] * fraction;
            }
          }
        }
      }
    }

    return interpolated;
  }

  List<double> _softmax(List<double> logits) {
    double sum = logits.fold(0, (p, c) => p + c);
    if ((sum - 1.0).abs() < 0.01 && logits.every((e) => e >= 0 && e <= 1)) {
      return logits;
    }

    final maxLogit = logits.reduce((a, b) => a > b ? a : b);
    final expLogits = logits.map((x) => math.exp(x - maxLogit)).toList();
    final sumExp = expLogits.fold(0.0, (a, b) => a + b);
    return List<double>.from(expLogits.map((x) => x / sumExp));
  }

  Future<ExerciseClassification> classify(PoseLandmarks landmarks) async {
    if (!isModelLoaded) {
      await _loadModel();
      if (!isModelLoaded) {
        throw StateError('TFLite model not loaded.');
      }
    }

    if (landmarks.isEmpty) {
      throw ArgumentError('Landmarks cannot be empty');
    }

    try {
      final input = _preprocessLandmarks(landmarks);
      var output = List.generate(1, (index) => List.filled(_numClasses, 0.0));
      _interpreter!.run(input, output);

      final rawOutput = output[0];
      final sum = rawOutput.fold(0.0, (a, b) => a + b);
      final isNormalized =
          (sum - 1.0).abs() < 0.01 && rawOutput.every((e) => e >= 0 && e <= 1);
      final probabilities = isNormalized ? rawOutput : _softmax(rawOutput);

      double maxProb = 0.0;
      int predictedClass = 0;

      for (var i = 0; i < probabilities.length; i++) {
        if (probabilities[i] > maxProb) {
          maxProb = probabilities[i];
          predictedClass = i;
        }
      }

      String exerciseName =
          _exerciseLabels[predictedClass] ?? 'Unknown Exercise';
      double finalConfidence = maxProb;

      return ExerciseClassification(
        exercise: exerciseName,
        confidence: finalConfidence,
      );
    } catch (e, stackTrace) {
      debugPrint('Error during classification: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<void> dispose() async {
    _interpreter?.close();
    _interpreter = null;
    _isModelLoaded = false;
  }
}
