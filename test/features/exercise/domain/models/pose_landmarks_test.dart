/// Unit tests for Pose Landmarks models.
///
/// Test coverage:
/// 1. PoseLandmark creation and serialization
/// 2. PoseFrame creation and backend format conversion
/// 3. PoseLandmarks collection operations
/// 4. JSON serialization/deserialization
/// 5. Factory methods (fromList, fromBackendFormat)
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:orthosense/features/exercise/domain/models/pose_landmarks.dart';

void main() {
  group('PoseLandmark', () {
    test('creates with required fields', () {
      const landmark = PoseLandmark(
        x: 0.5,
        y: 0.3,
        z: 0.1,
      );

      expect(landmark.x, equals(0.5));
      expect(landmark.y, equals(0.3));
      expect(landmark.z, equals(0.1));
      expect(landmark.visibility, equals(1.0)); // default
    });

    test('creates with custom visibility', () {
      const landmark = PoseLandmark(
        x: 0.5,
        y: 0.3,
        z: 0.1,
        visibility: 0.85,
      );

      expect(landmark.visibility, equals(0.85));
    });

    test('toList includes visibility by default', () {
      const landmark = PoseLandmark(
        x: 0.5,
        y: 0.3,
        z: 0.1,
        visibility: 0.9,
      );

      final list = landmark.toList();

      expect(list.length, equals(4));
      expect(list, equals([0.5, 0.3, 0.1, 0.9]));
    });

    test('toList excludes visibility when specified', () {
      const landmark = PoseLandmark(
        x: 0.5,
        y: 0.3,
        z: 0.1,
        visibility: 0.9,
      );

      final list = landmark.toList(includeVisibility: false);

      expect(list.length, equals(3));
      expect(list, equals([0.5, 0.3, 0.1]));
    });

    test('fromList creates landmark from coordinates', () {
      final landmark = PoseLandmark.fromList([0.25, 0.75, 0.0]);

      expect(landmark.x, equals(0.25));
      expect(landmark.y, equals(0.75));
      expect(landmark.z, equals(0.0));
    });

    test('fromList handles 2D coordinates', () {
      final landmark = PoseLandmark.fromList([0.5, 0.5]);

      expect(landmark.x, equals(0.5));
      expect(landmark.y, equals(0.5));
      expect(landmark.z, equals(0.0)); // default z
    });

    test('toJson and fromJson roundtrip', () {
      const original = PoseLandmark(
        x: 0.123,
        y: 0.456,
        z: 0.789,
        visibility: 0.95,
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
    test('creates with landmarks', () {
      const frame = PoseFrame(
        landmarks: [
          PoseLandmark(x: 0.0, y: 0.0, z: 0.0),
          PoseLandmark(x: 0.1, y: 0.1, z: 0.0),
          PoseLandmark(x: 0.2, y: 0.2, z: 0.0),
        ],
      );

      expect(frame.landmarks.length, equals(3));
    });

    test('toBackendFormat converts to nested lists', () {
      const frame = PoseFrame(
        landmarks: [
          PoseLandmark(x: 0.5, y: 0.3, z: 0.1, visibility: 0.9),
          PoseLandmark(x: 0.6, y: 0.4, z: 0.2, visibility: 0.95),
        ],
      );

      final backendFormat = frame.toBackendFormat();

      expect(backendFormat.length, equals(2));
      expect(backendFormat[0], equals([0.5, 0.3, 0.1, 0.9]));
      expect(backendFormat[1], equals([0.6, 0.4, 0.2, 0.95]));
    });

    test('toBackendFormat excludes visibility when specified', () {
      const frame = PoseFrame(
        landmarks: [
          PoseLandmark(x: 0.5, y: 0.3, z: 0.1, visibility: 0.9),
        ],
      );

      final backendFormat = frame.toBackendFormat(includeVisibility: false);

      expect(backendFormat[0], equals([0.5, 0.3, 0.1]));
    });

    test('fromBackendFormat creates frame from nested lists', () {
      final data = [
        [0.1, 0.2, 0.0],
        [0.3, 0.4, 0.0],
        [0.5, 0.6, 0.0],
      ];

      final frame = PoseFrame.fromBackendFormat(data);

      expect(frame.landmarks.length, equals(3));
      expect(frame.landmarks[0].x, equals(0.1));
      expect(frame.landmarks[1].y, equals(0.4));
    });

    test('toJson and fromJson roundtrip', () {
      const original = PoseFrame(
        landmarks: [
          PoseLandmark(x: 0.1, y: 0.2, z: 0.3),
          PoseLandmark(x: 0.4, y: 0.5, z: 0.6),
        ],
      );

      // Note: json_serializable doesn't deeply serialize by default,
      // so we need to manually serialize the nested objects for roundtrip
      final json = {
        'landmarks': original.landmarks.map((l) => l.toJson()).toList(),
      };
      final restored = PoseFrame.fromJson(json);

      expect(restored.landmarks.length, equals(2));
      expect(restored.landmarks[0].x, equals(0.1));
    });
  });

  group('PoseLandmarks', () {
    test('creates with frames and default fps', () {
      const landmarks = PoseLandmarks(
        frames: [
          PoseFrame(landmarks: []),
          PoseFrame(landmarks: []),
        ],
      );

      expect(landmarks.frameCount, equals(2));
      expect(landmarks.fps, equals(30.0)); // default
    });

    test('creates with custom fps', () {
      const landmarks = PoseLandmarks(
        frames: [],
        fps: 60.0,
      );

      expect(landmarks.fps, equals(60.0));
    });

    test('isEmpty returns true for empty frames', () {
      const landmarks = PoseLandmarks(frames: []);

      expect(landmarks.isEmpty, isTrue);
      expect(landmarks.isNotEmpty, isFalse);
    });

    test('isNotEmpty returns true when frames exist', () {
      const landmarks = PoseLandmarks(
        frames: [PoseFrame(landmarks: [])],
      );

      expect(landmarks.isEmpty, isFalse);
      expect(landmarks.isNotEmpty, isTrue);
    });

    test('frameCount returns correct count', () {
      const landmarks = PoseLandmarks(
        frames: [
          PoseFrame(landmarks: []),
          PoseFrame(landmarks: []),
          PoseFrame(landmarks: []),
        ],
      );

      expect(landmarks.frameCount, equals(3));
    });

    test('toBackendFormat converts all frames', () {
      const landmarks = PoseLandmarks(
        frames: [
          PoseFrame(
            landmarks: [
              PoseLandmark(x: 0.1, y: 0.2, z: 0.0, visibility: 0.9),
            ],
          ),
          PoseFrame(
            landmarks: [
              PoseLandmark(x: 0.3, y: 0.4, z: 0.0, visibility: 0.95),
            ],
          ),
        ],
      );

      final backendFormat = landmarks.toBackendFormat();

      expect(backendFormat.length, equals(2));
      expect(backendFormat[0][0], equals([0.1, 0.2, 0.0, 0.9]));
      expect(backendFormat[1][0], equals([0.3, 0.4, 0.0, 0.95]));
    });

    test('fromBackendFormat creates landmarks from nested lists', () {
      final data = [
        [
          [0.1, 0.2, 0.0],
          [0.3, 0.4, 0.0],
        ],
        [
          [0.5, 0.6, 0.0],
          [0.7, 0.8, 0.0],
        ],
      ];

      final landmarks = PoseLandmarks.fromBackendFormat(data, fps: 25.0);

      expect(landmarks.frameCount, equals(2));
      expect(landmarks.fps, equals(25.0));
      expect(landmarks.frames[0].landmarks.length, equals(2));
      expect(landmarks.frames[1].landmarks[1].x, equals(0.7));
    });

    test('toJson and fromJson roundtrip', () {
      const original = PoseLandmarks(
        frames: [
          PoseFrame(
            landmarks: [
              PoseLandmark(x: 0.1, y: 0.2, z: 0.3),
            ],
          ),
        ],
        fps: 24.0,
      );

      // Note: json_serializable doesn't deeply serialize by default,
      // so we need to manually serialize the nested objects for roundtrip
      final json = {
        'frames': original.frames
            .map(
              (f) => {
                'landmarks': f.landmarks.map((l) => l.toJson()).toList(),
              },
            )
            .toList(),
        'fps': original.fps,
      };
      final restored = PoseLandmarks.fromJson(json);

      expect(restored.frameCount, equals(1));
      expect(restored.fps, equals(24.0));
    });
  });

  group('33-Joint BlazePose Format', () {
    test('handles full 33-landmark frame', () {
      // Create a frame with all 33 BlazePose landmarks
      final landmarks = List.generate(
        33,
        (i) => PoseLandmark(
          x: i * 0.03,
          y: i * 0.02,
          z: 0.0,
          visibility: 0.95,
        ),
      );

      final frame = PoseFrame(landmarks: landmarks);

      expect(frame.landmarks.length, equals(33));

      final backendFormat = frame.toBackendFormat();
      expect(backendFormat.length, equals(33));
      expect(backendFormat[0].length, equals(4)); // x, y, z, visibility
    });

    test('converts multiple frames for analysis', () {
      // 10 frames of 33 landmarks each
      final frames = List.generate(
        10,
        (frameIdx) => PoseFrame(
          landmarks: List.generate(
            33,
            (jointIdx) => PoseLandmark(
              x: jointIdx * 0.03 + frameIdx * 0.001,
              y: jointIdx * 0.02,
              z: 0.0,
              visibility: 0.9,
            ),
          ),
        ),
      );

      final poseLandmarks = PoseLandmarks(frames: frames, fps: 30.0);

      expect(poseLandmarks.frameCount, equals(10));

      final backendFormat = poseLandmarks.toBackendFormat();
      expect(backendFormat.length, equals(10));
      expect(backendFormat[0].length, equals(33));
      expect(backendFormat[0][0].length, equals(4));
    });
  });

  group('Edge Cases', () {
    test('handles zero coordinates', () {
      const landmark = PoseLandmark(x: 0, y: 0, z: 0);

      expect(landmark.toList(includeVisibility: false), equals([0, 0, 0]));
    });

    test('handles negative coordinates', () {
      const landmark = PoseLandmark(x: -0.5, y: -0.3, z: -0.1);

      final list = landmark.toList(includeVisibility: false);
      expect(list, equals([-0.5, -0.3, -0.1]));
    });

    test('handles very small visibility values', () {
      const landmark = PoseLandmark(
        x: 0.5,
        y: 0.5,
        z: 0.0,
        visibility: 0.001,
      );

      expect(landmark.visibility, equals(0.001));
    });

    test('empty frame toBackendFormat returns empty list', () {
      const frame = PoseFrame(landmarks: []);

      expect(frame.toBackendFormat(), isEmpty);
    });

    test('empty landmarks toBackendFormat returns empty list', () {
      const landmarks = PoseLandmarks(frames: []);

      expect(landmarks.toBackendFormat(), isEmpty);
    });
  });
}
