/// Unit tests for Pose Landmarks models.
///
/// Test coverage:
/// 1. PoseLandmark creation and conversion
/// 2. PoseFrame construction
/// 3. PoseLandmarks operations
/// 4. Backend format conversion
/// 5. JSON serialization
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:orthosense/features/exercise/domain/models/pose_landmarks.dart';

void main() {
  group('PoseLandmark', () {
    test('creates with required coordinates', () {
      const landmark = PoseLandmark(
        x: 0.5,
        y: 0.3,
        z: 0.1,
      );

      expect(landmark.x, equals(0.5));
      expect(landmark.y, equals(0.3));
      expect(landmark.z, equals(0.1));
      expect(landmark.visibility, equals(1.0));
    });

    test('creates with visibility', () {
      const landmark = PoseLandmark(
        x: 0.5,
        y: 0.5,
        z: 0.0,
        visibility: 0.8,
      );

      expect(landmark.visibility, equals(0.8));
    });

    test('toList includes visibility by default', () {
      const landmark = PoseLandmark(
        x: 0.1,
        y: 0.2,
        z: 0.3,
        visibility: 0.9,
      );

      final list = landmark.toList();

      expect(list, equals([0.1, 0.2, 0.3, 0.9]));
    });

    test('toList excludes visibility when specified', () {
      const landmark = PoseLandmark(
        x: 0.1,
        y: 0.2,
        z: 0.3,
        visibility: 0.9,
      );

      final list = landmark.toList(includeVisibility: false);

      expect(list, equals([0.1, 0.2, 0.3]));
    });

    test('fromList creates landmark', () {
      final landmark = PoseLandmark.fromList([0.4, 0.5, 0.6]);

      expect(landmark.x, equals(0.4));
      expect(landmark.y, equals(0.5));
      expect(landmark.z, equals(0.6));
    });

    test('fromList handles 2D coordinates', () {
      final landmark = PoseLandmark.fromList([0.4, 0.5]);

      expect(landmark.x, equals(0.4));
      expect(landmark.y, equals(0.5));
      expect(landmark.z, equals(0.0));
    });

    test('serializes to JSON correctly', () {
      const landmark = PoseLandmark(
        x: 0.25,
        y: 0.75,
        z: 0.0,
        visibility: 0.95,
      );

      final json = landmark.toJson();

      expect(json['x'], equals(0.25));
      expect(json['y'], equals(0.75));
      expect(json['z'], equals(0.0));
      expect(json['visibility'], equals(0.95));
    });

    test('deserializes from JSON correctly', () {
      final json = {
        'x': 0.33,
        'y': 0.66,
        'z': 0.1,
        'visibility': 0.88,
      };

      final landmark = PoseLandmark.fromJson(json);

      expect(landmark.x, equals(0.33));
      expect(landmark.y, equals(0.66));
      expect(landmark.z, equals(0.1));
      expect(landmark.visibility, equals(0.88));
    });
  });

  group('PoseFrame', () {
    test('creates with landmarks list', () {
      final frame = PoseFrame(
        landmarks: [
          const PoseLandmark(x: 0.1, y: 0.1, z: 0.0),
          const PoseLandmark(x: 0.2, y: 0.2, z: 0.0),
          const PoseLandmark(x: 0.3, y: 0.3, z: 0.0),
        ],
      );

      expect(frame.landmarks.length, equals(3));
    });

    test('toBackendFormat converts correctly', () {
      final frame = PoseFrame(
        landmarks: [
          const PoseLandmark(x: 0.1, y: 0.2, z: 0.3, visibility: 0.9),
          const PoseLandmark(x: 0.4, y: 0.5, z: 0.6, visibility: 0.8),
        ],
      );

      final backendFormat = frame.toBackendFormat();

      expect(backendFormat.length, equals(2));
      expect(backendFormat[0], equals([0.1, 0.2, 0.3, 0.9]));
      expect(backendFormat[1], equals([0.4, 0.5, 0.6, 0.8]));
    });

    test('toBackendFormat without visibility', () {
      final frame = PoseFrame(
        landmarks: [
          const PoseLandmark(x: 0.1, y: 0.2, z: 0.3),
        ],
      );

      final backendFormat = frame.toBackendFormat(includeVisibility: false);

      expect(backendFormat[0], equals([0.1, 0.2, 0.3]));
    });

    test('fromBackendFormat creates frame', () {
      final backendData = [
        [0.1, 0.2, 0.3],
        [0.4, 0.5, 0.6],
      ];

      final frame = PoseFrame.fromBackendFormat(backendData);

      expect(frame.landmarks.length, equals(2));
      expect(frame.landmarks[0].x, equals(0.1));
      expect(frame.landmarks[1].y, equals(0.5));
    });

    test('serializes to JSON correctly', () {
      final frame = PoseFrame(
        landmarks: [const PoseLandmark(x: 0.5, y: 0.5, z: 0.0)],
      );

      final json = frame.toJson();

      expect(json['landmarks'], isA<List>());
    });
  });

  group('PoseLandmarks', () {
    test('creates with frames and fps', () {
      final landmarks = PoseLandmarks(
        frames: [
          PoseFrame(landmarks: [const PoseLandmark(x: 0.1, y: 0.2, z: 0.3)]),
          PoseFrame(landmarks: [const PoseLandmark(x: 0.2, y: 0.3, z: 0.4)]),
        ],
        fps: 30.0,
      );

      expect(landmarks.frames.length, equals(2));
      expect(landmarks.fps, equals(30.0));
    });

    test('default fps is 30', () {
      final landmarks = PoseLandmarks(
        frames: [],
      );

      expect(landmarks.fps, equals(30.0));
    });

    test('frameCount returns correct count', () {
      final landmarks = PoseLandmarks(
        frames: [
          PoseFrame(landmarks: []),
          PoseFrame(landmarks: []),
          PoseFrame(landmarks: []),
        ],
      );

      expect(landmarks.frameCount, equals(3));
    });

    test('isEmpty is true for empty frames', () {
      final landmarks = PoseLandmarks(frames: []);

      expect(landmarks.isEmpty, isTrue);
      expect(landmarks.isNotEmpty, isFalse);
    });

    test('isNotEmpty is true for non-empty frames', () {
      final landmarks = PoseLandmarks(
        frames: [PoseFrame(landmarks: [])],
      );

      expect(landmarks.isEmpty, isFalse);
      expect(landmarks.isNotEmpty, isTrue);
    });

    test('toBackendFormat converts all frames', () {
      final landmarks = PoseLandmarks(
        frames: [
          PoseFrame(
            landmarks: [
              const PoseLandmark(x: 0.1, y: 0.2, z: 0.3),
            ],
          ),
          PoseFrame(
            landmarks: [
              const PoseLandmark(x: 0.4, y: 0.5, z: 0.6),
            ],
          ),
        ],
      );

      final backendFormat = landmarks.toBackendFormat();

      expect(backendFormat.length, equals(2));
      expect(backendFormat[0][0], equals([0.1, 0.2, 0.3, 1.0]));
      expect(backendFormat[1][0], equals([0.4, 0.5, 0.6, 1.0]));
    });

    test('fromBackendFormat creates landmarks', () {
      final backendData = [
        [
          [0.1, 0.2, 0.3],
          [0.4, 0.5, 0.6],
        ],
        [
          [0.7, 0.8, 0.9],
          [0.2, 0.3, 0.4],
        ],
      ];

      final landmarks = PoseLandmarks.fromBackendFormat(backendData, fps: 60.0);

      expect(landmarks.frameCount, equals(2));
      expect(landmarks.fps, equals(60.0));
      expect(landmarks.frames[0].landmarks.length, equals(2));
    });

    test('serializes to JSON correctly', () {
      final landmarks = PoseLandmarks(
        frames: [PoseFrame(landmarks: [])],
        fps: 30.0,
      );

      final json = landmarks.toJson();

      expect(json['frames'], isA<List>());
      expect(json['fps'], equals(30.0));
    });
  });
}
