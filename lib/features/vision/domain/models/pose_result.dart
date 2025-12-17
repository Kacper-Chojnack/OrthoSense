import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:orthosense/features/vision/domain/models/pose_landmark.dart';

part 'pose_result.freezed.dart';

/// Result of pose estimation containing all detected landmarks.
@freezed
class PoseResult with _$PoseResult {
  const factory PoseResult({
    /// List of detected landmarks (33 for full body).
    required List<PoseLandmark> landmarks,

    /// Timestamp when this pose was detected.
    required DateTime timestamp,

    /// Overall confidence score for the detection.
    @Default(1.0) double confidence,
  }) = _PoseResult;

  const PoseResult._();

  /// Whether a valid pose was detected.
  bool get isValid => landmarks.isNotEmpty && confidence > 0.5;

  /// Gets landmark by index, returns null if out of bounds.
  PoseLandmark? landmarkAt(int index) {
    if (index < 0 || index >= landmarks.length) return null;
    return landmarks[index];
  }

  /// Convenience getters for common landmarks.
  PoseLandmark? get nose => landmarkAt(PoseLandmarkIndex.nose);
  PoseLandmark? get leftShoulder => landmarkAt(PoseLandmarkIndex.leftShoulder);
  PoseLandmark? get rightShoulder =>
      landmarkAt(PoseLandmarkIndex.rightShoulder);
  PoseLandmark? get leftElbow => landmarkAt(PoseLandmarkIndex.leftElbow);
  PoseLandmark? get rightElbow => landmarkAt(PoseLandmarkIndex.rightElbow);
  PoseLandmark? get leftWrist => landmarkAt(PoseLandmarkIndex.leftWrist);
  PoseLandmark? get rightWrist => landmarkAt(PoseLandmarkIndex.rightWrist);
  PoseLandmark? get leftHip => landmarkAt(PoseLandmarkIndex.leftHip);
  PoseLandmark? get rightHip => landmarkAt(PoseLandmarkIndex.rightHip);
  PoseLandmark? get leftKnee => landmarkAt(PoseLandmarkIndex.leftKnee);
  PoseLandmark? get rightKnee => landmarkAt(PoseLandmarkIndex.rightKnee);
  PoseLandmark? get leftAnkle => landmarkAt(PoseLandmarkIndex.leftAnkle);
  PoseLandmark? get rightAnkle => landmarkAt(PoseLandmarkIndex.rightAnkle);
}
