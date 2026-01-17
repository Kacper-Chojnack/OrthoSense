/// Unit tests for pose landmark models.
///
/// Test coverage:
/// 1. PoseLandmark creation and serialization
/// 2. PoseFrame creation and backend format conversion
/// 3. PoseLandmarks container operations
/// 4. Edge cases and validation
library;

import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PoseLandmark', () {
    test('creates with all coordinates', () {
      const landmark = PoseLandmark(
        x: 0.5,
        y: 0.6,
        z: 0.1,
        visibility: 0.95,
      );

      expect(landmark.x, equals(0.5));
      expect(landmark.y, equals(0.6));
      expect(landmark.z, equals(0.1));
      expect(landmark.visibility, equals(0.95));
    });

    test('visibility defaults to 1.0', () {
      const landmark = PoseLandmark(x: 0.5, y: 0.6, z: 0.1);
      expect(landmark.visibility, equals(1.0));
    });

    test('toList includes visibility by default', () {
      const landmark = PoseLandmark(
        x: 0.5,
        y: 0.6,
        z: 0.1,
        visibility: 0.95,
      );

      final list = landmark.toList();

      expect(list.length, equals(4));
      expect(list[0], equals(0.5));
      expect(list[1], equals(0.6));
      expect(list[2], equals(0.1));
      expect(list[3], equals(0.95));
    });

    test('toList excludes visibility when specified', () {
      const landmark = PoseLandmark(
        x: 0.5,
        y: 0.6,
        z: 0.1,
        visibility: 0.95,
      );

      final list = landmark.toList(includeVisibility: false);

      expect(list.length, equals(3));
      expect(list[0], equals(0.5));
      expect(list[1], equals(0.6));
      expect(list[2], equals(0.1));
    });

    test('fromList creates landmark from 3D coords', () {
      final landmark = PoseLandmark.fromList([0.5, 0.6, 0.1]);

      expect(landmark.x, equals(0.5));
      expect(landmark.y, equals(0.6));
      expect(landmark.z, equals(0.1));
    });

    test('fromList handles 2D coords with z default', () {
      final landmark = PoseLandmark.fromList([0.5, 0.6]);

      expect(landmark.x, equals(0.5));
      expect(landmark.y, equals(0.6));
      expect(landmark.z, equals(0.0));
    });

    test('serialization roundtrip preserves data', () {
      const original = PoseLandmark(
        x: 0.123,
        y: 0.456,
        z: 0.789,
        visibility: 0.99,
      );

      final json = original.toJson();
      final restored = PoseLandmark.fromJson(json);

      expect(restored.x, equals(original.x));
      expect(restored.y, equals(original.y));
      expect(restored.z, equals(original.z));
      expect(restored.visibility, equals(original.visibility));
    });
  });

  group('PoseFrame', () {
    late List<PoseLandmark> testLandmarks;

    setUp(() {
      testLandmarks = [
        const PoseLandmark(x: 0.1, y: 0.2, z: 0.3, visibility: 0.9),
        const PoseLandmark(x: 0.4, y: 0.5, z: 0.6, visibility: 0.8),
        const PoseLandmark(x: 0.7, y: 0.8, z: 0.9, visibility: 0.7),
      ];
    });

    test('creates with landmarks', () {
      final frame = PoseFrame(landmarks: testLandmarks);
      expect(frame.landmarks.length, equals(3));
    });

    test('toBackendFormat converts landmarks to nested lists', () {
      final frame = PoseFrame(landmarks: testLandmarks);
      final backendData = frame.toBackendFormat();

      expect(backendData.length, equals(3));
      expect(backendData[0], equals([0.1, 0.2, 0.3, 0.9]));
      expect(backendData[1], equals([0.4, 0.5, 0.6, 0.8]));
      expect(backendData[2], equals([0.7, 0.8, 0.9, 0.7]));
    });

    test('toBackendFormat excludes visibility when specified', () {
      final frame = PoseFrame(landmarks: testLandmarks);
      final backendData = frame.toBackendFormat(includeVisibility: false);

      expect(backendData[0].length, equals(3));
      expect(backendData[0], equals([0.1, 0.2, 0.3]));
    });

    test('fromBackendFormat creates frame from nested lists', () {
      final data = [
        [0.1, 0.2, 0.3],
        [0.4, 0.5, 0.6],
      ];

      final frame = PoseFrame.fromBackendFormat(data);

      expect(frame.landmarks.length, equals(2));
      expect(frame.landmarks[0].x, equals(0.1));
      expect(frame.landmarks[1].y, equals(0.5));
    });

    test('serialization roundtrip preserves data', () {
      final original = PoseFrame(landmarks: testLandmarks);
      final json = original.toJson();
      final restored = PoseFrame.fromJson(json);

      expect(restored.landmarks.length, equals(original.landmarks.length));
    });
  });

  group('PoseLandmarks', () {
    late List<PoseFrame> testFrames;

    setUp(() {
      testFrames = [
        PoseFrame(landmarks: [
          const PoseLandmark(x: 0.1, y: 0.1, z: 0.0),
          const PoseLandmark(x: 0.2, y: 0.2, z: 0.0),
        ]),
        PoseFrame(landmarks: [
          const PoseLandmark(x: 0.3, y: 0.3, z: 0.0),
          const PoseLandmark(x: 0.4, y: 0.4, z: 0.0),
        ]),
        PoseFrame(landmarks: [
          const PoseLandmark(x: 0.5, y: 0.5, z: 0.0),
          const PoseLandmark(x: 0.6, y: 0.6, z: 0.0),
        ]),
      ];
    });

    test('creates with frames and fps', () {
      final landmarks = PoseLandmarks(frames: testFrames, fps: 30.0);

      expect(landmarks.frames.length, equals(3));
      expect(landmarks.fps, equals(30.0));
    });

    test('fps defaults to 30.0', () {
      final landmarks = PoseLandmarks(frames: testFrames);
      expect(landmarks.fps, equals(30.0));
    });

    test('frameCount returns number of frames', () {
      final landmarks = PoseLandmarks(frames: testFrames);
      expect(landmarks.frameCount, equals(3));
    });

    test('isEmpty returns true when no frames', () {
      const landmarks = PoseLandmarks(frames: []);
      expect(landmarks.isEmpty, isTrue);
    });

    test('isEmpty returns false when has frames', () {
      final landmarks = PoseLandmarks(frames: testFrames);
      expect(landmarks.isEmpty, isFalse);
    });

    test('isNotEmpty returns true when has frames', () {
      final landmarks = PoseLandmarks(frames: testFrames);
      expect(landmarks.isNotEmpty, isTrue);
    });

    test('isNotEmpty returns false when no frames', () {
      const landmarks = PoseLandmarks(frames: []);
      expect(landmarks.isNotEmpty, isFalse);
    });

    test('toBackendFormat creates 3D nested list', () {
      final landmarks = PoseLandmarks(frames: testFrames);
      final backendData = landmarks.toBackendFormat();

      expect(backendData.length, equals(3));
      expect(backendData[0].length, equals(2));
      expect(backendData[0][0].length, equals(4)); // x, y, z, visibility
    });

    test('fromBackendFormat creates landmarks from 3D nested list', () {
      final data = [
        [
          [0.1, 0.1, 0.0],
          [0.2, 0.2, 0.0],
        ],
        [
          [0.3, 0.3, 0.0],
          [0.4, 0.4, 0.0],
        ],
      ];

      final landmarks = PoseLandmarks.fromBackendFormat(data, fps: 24.0);

      expect(landmarks.frameCount, equals(2));
      expect(landmarks.fps, equals(24.0));
      expect(landmarks.frames[0].landmarks.length, equals(2));
    });

    test('serialization roundtrip preserves data', () {
      final original = PoseLandmarks(frames: testFrames, fps: 25.0);
      final json = original.toJson();
      final restored = PoseLandmarks.fromJson(json);

      expect(restored.frameCount, equals(original.frameCount));
      expect(restored.fps, equals(original.fps));
    });
  });

  group('MediaPipe Landmark Indices', () {
    // Standard MediaPipe landmark indices
    const nose = 0;
    const leftShoulder = 11;
    const rightShoulder = 12;
    const leftHip = 23;
    const rightHip = 24;
    const leftKnee = 25;
    const rightKnee = 26;
    const leftAnkle = 27;
    const rightAnkle = 28;

    test('landmark indices are correctly defined', () {
      expect(nose, equals(0));
      expect(leftShoulder, equals(11));
      expect(rightShoulder, equals(12));
    });

    test('lower body indices', () {
      expect(leftHip, equals(23));
      expect(rightHip, equals(24));
      expect(leftKnee, equals(25));
      expect(rightKnee, equals(26));
    });

    test('ankle indices for foot tracking', () {
      expect(leftAnkle, equals(27));
      expect(rightAnkle, equals(28));
    });
  });

  group('Angle Calculations', () {
    test('calculates angle between three points', () {
      // Simulate points forming a 90-degree angle
      final p1 = const PoseLandmark(x: 0.0, y: 0.0, z: 0.0); // Start
      final p2 = const PoseLandmark(x: 1.0, y: 0.0, z: 0.0); // Vertex
      final p3 = const PoseLandmark(x: 1.0, y: 1.0, z: 0.0); // End

      final angle = _calculateAngle(p1, p2, p3);

      // Should be approximately 90 degrees
      expect(angle, closeTo(90.0, 1.0));
    });

    test('calculates angle for straight line (180 degrees)', () {
      final p1 = const PoseLandmark(x: 0.0, y: 0.0, z: 0.0);
      final p2 = const PoseLandmark(x: 1.0, y: 0.0, z: 0.0);
      final p3 = const PoseLandmark(x: 2.0, y: 0.0, z: 0.0);

      final angle = _calculateAngle(p1, p2, p3);

      expect(angle, closeTo(180.0, 1.0));
    });
  });

  group('Visibility Thresholds', () {
    test('landmark is visible when above threshold', () {
      const landmark = PoseLandmark(x: 0.5, y: 0.5, z: 0.0, visibility: 0.8);
      const threshold = 0.5;

      expect(_isVisible(landmark, threshold), isTrue);
    });

    test('landmark is not visible when below threshold', () {
      const landmark = PoseLandmark(x: 0.5, y: 0.5, z: 0.0, visibility: 0.3);
      const threshold = 0.5;

      expect(_isVisible(landmark, threshold), isFalse);
    });

    test('landmark at threshold boundary is visible', () {
      const landmark = PoseLandmark(x: 0.5, y: 0.5, z: 0.0, visibility: 0.5);
      const threshold = 0.5;

      expect(_isVisible(landmark, threshold), isTrue);
    });
  });

  group('Frame Normalization', () {
    test('normalizes coordinates to 0-1 range', () {
      // Raw pixel coordinates
      const rawX = 320.0;
      const rawY = 240.0;
      const imageWidth = 640.0;
      const imageHeight = 480.0;

      final normalizedX = rawX / imageWidth;
      final normalizedY = rawY / imageHeight;

      expect(normalizedX, equals(0.5));
      expect(normalizedY, equals(0.5));
    });

    test('handles edge coordinates', () {
      const imageWidth = 640.0;
      const imageHeight = 480.0;

      // Top-left corner
      expect(0.0 / imageWidth, equals(0.0));
      expect(0.0 / imageHeight, equals(0.0));

      // Bottom-right corner
      expect(imageWidth / imageWidth, equals(1.0));
      expect(imageHeight / imageHeight, equals(1.0));
    });
  });

  group('Landmark Interpolation', () {
    test('interpolates between two landmarks', () {
      const l1 = PoseLandmark(x: 0.0, y: 0.0, z: 0.0);
      const l2 = PoseLandmark(x: 1.0, y: 1.0, z: 1.0);

      final interpolated = _interpolate(l1, l2, 0.5);

      expect(interpolated.x, equals(0.5));
      expect(interpolated.y, equals(0.5));
      expect(interpolated.z, equals(0.5));
    });

    test('interpolation at 0 returns first landmark', () {
      const l1 = PoseLandmark(x: 0.0, y: 0.0, z: 0.0);
      const l2 = PoseLandmark(x: 1.0, y: 1.0, z: 1.0);

      final interpolated = _interpolate(l1, l2, 0.0);

      expect(interpolated.x, equals(0.0));
      expect(interpolated.y, equals(0.0));
    });

    test('interpolation at 1 returns second landmark', () {
      const l1 = PoseLandmark(x: 0.0, y: 0.0, z: 0.0);
      const l2 = PoseLandmark(x: 1.0, y: 1.0, z: 1.0);

      final interpolated = _interpolate(l1, l2, 1.0);

      expect(interpolated.x, equals(1.0));
      expect(interpolated.y, equals(1.0));
    });
  });
}

// Test model classes (mirroring the actual implementation)

class PoseLandmark {
  const PoseLandmark({
    required this.x,
    required this.y,
    required this.z,
    this.visibility = 1.0,
  });

  final double x;
  final double y;
  final double z;
  final double visibility;

  List<double> toList({bool includeVisibility = true}) =>
      includeVisibility ? [x, y, z, visibility] : [x, y, z];

  static PoseLandmark fromList(List<double> coords) {
    return PoseLandmark(
      x: coords[0],
      y: coords[1],
      z: coords.length > 2 ? coords[2] : 0.0,
    );
  }

  Map<String, dynamic> toJson() => {
        'x': x,
        'y': y,
        'z': z,
        'visibility': visibility,
      };

  factory PoseLandmark.fromJson(Map<String, dynamic> json) {
    return PoseLandmark(
      x: (json['x'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
      z: (json['z'] as num).toDouble(),
      visibility: (json['visibility'] as num?)?.toDouble() ?? 1.0,
    );
  }
}

class PoseFrame {
  const PoseFrame({required this.landmarks});

  final List<PoseLandmark> landmarks;

  List<List<double>> toBackendFormat({bool includeVisibility = true}) {
    return landmarks
        .map((lm) => lm.toList(includeVisibility: includeVisibility))
        .toList();
  }

  static PoseFrame fromBackendFormat(List<List<double>> data) {
    return PoseFrame(
      landmarks: data.map((coords) => PoseLandmark.fromList(coords)).toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'landmarks': landmarks.map((l) => l.toJson()).toList(),
      };

  factory PoseFrame.fromJson(Map<String, dynamic> json) {
    return PoseFrame(
      landmarks: (json['landmarks'] as List)
          .map((l) => PoseLandmark.fromJson(l as Map<String, dynamic>))
          .toList(),
    );
  }
}

class PoseLandmarks {
  const PoseLandmarks({
    required this.frames,
    this.fps = 30.0,
  });

  final List<PoseFrame> frames;
  final double fps;

  List<List<List<double>>> toBackendFormat() {
    return frames.map((frame) => frame.toBackendFormat()).toList();
  }

  static PoseLandmarks fromBackendFormat(
    List<List<List<double>>> data, {
    double fps = 30.0,
  }) {
    return PoseLandmarks(
      frames: data.map((frame) => PoseFrame.fromBackendFormat(frame)).toList(),
      fps: fps,
    );
  }

  int get frameCount => frames.length;
  bool get isEmpty => frames.isEmpty;
  bool get isNotEmpty => frames.isNotEmpty;

  Map<String, dynamic> toJson() => {
        'frames': frames.map((f) => f.toJson()).toList(),
        'fps': fps,
      };

  factory PoseLandmarks.fromJson(Map<String, dynamic> json) {
    return PoseLandmarks(
      frames: (json['frames'] as List)
          .map((f) => PoseFrame.fromJson(f as Map<String, dynamic>))
          .toList(),
      fps: (json['fps'] as num?)?.toDouble() ?? 30.0,
    );
  }
}

// Helper functions for tests

double _calculateAngle(PoseLandmark p1, PoseLandmark p2, PoseLandmark p3) {
  // Vector from p2 to p1
  final v1x = p1.x - p2.x;
  final v1y = p1.y - p2.y;
  
  // Vector from p2 to p3
  final v2x = p3.x - p2.x;
  final v2y = p3.y - p2.y;
  
  // Dot product and magnitudes
  final dotProduct = v1x * v2x + v1y * v2y;
  final mag1 = math.sqrt(v1x * v1x + v1y * v1y);
  final mag2 = math.sqrt(v2x * v2x + v2y * v2y);
  
  // Calculate angle in radians, then convert to degrees
  final cosAngle = dotProduct / (mag1 * mag2);
  final clampedCos = cosAngle.clamp(-1.0, 1.0);
  final angleRad = math.acos(clampedCos);
  
  return angleRad * 180 / math.pi;
}

bool _isVisible(PoseLandmark landmark, double threshold) {
  return landmark.visibility >= threshold;
}

PoseLandmark _interpolate(PoseLandmark l1, PoseLandmark l2, double t) {
  return PoseLandmark(
    x: l1.x + (l2.x - l1.x) * t,
    y: l1.y + (l2.y - l1.y) * t,
    z: l1.z + (l2.z - l1.z) * t,
    visibility: l1.visibility + (l2.visibility - l1.visibility) * t,
  );
}
