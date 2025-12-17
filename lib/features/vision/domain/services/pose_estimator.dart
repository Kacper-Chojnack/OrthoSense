import 'package:orthosense/features/camera/domain/models/camera_frame.dart';
import 'package:orthosense/features/vision/domain/models/models.dart';

/// Abstract interface for pose estimation services.
/// Allows swapping Mock/Real implementations via DI.
abstract class PoseEstimator {
  /// Processes camera frames and emits pose detection results.
  ///
  /// The implementation may:
  /// - Process every frame (real-time)
  /// - Skip frames for performance
  /// - Generate synthetic data (mock)
  Stream<PoseResult> detect(Stream<CameraFrame> frames);

  /// Releases any resources held by the estimator.
  Future<void> dispose();
}
