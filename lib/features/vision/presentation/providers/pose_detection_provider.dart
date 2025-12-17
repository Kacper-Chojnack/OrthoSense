import 'dart:async';

import 'package:orthosense/features/camera/presentation/providers/camera_controller.dart';
import 'package:orthosense/features/vision/data/services/mock_pose_estimator.dart';
import 'package:orthosense/features/vision/domain/models/models.dart';
import 'package:orthosense/features/vision/domain/services/pose_estimator.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'pose_detection_provider.g.dart';

/// Toggle between Mock and Real pose estimator.
/// Set to false when real ML models are ready.
const bool kUseMockPoseEstimator = true;

/// Provides [PoseEstimator] implementation.
/// Override in tests to inject mock.
@Riverpod(keepAlive: true)
PoseEstimator poseEstimator(PoseEstimatorRef ref) {
  final estimator = kUseMockPoseEstimator
      ? MockPoseEstimator()
      : MockPoseEstimator(); // Replace with real implementation later

  ref.onDispose(() async {
    await estimator.dispose();
  });

  return estimator;
}

/// Provides stream of pose detection results.
/// Automatically starts when camera is ready.
@riverpod
Stream<PoseResult> poseDetection(PoseDetectionRef ref) {
  final cameraController = ref.watch(cameraControllerProvider.notifier);
  final estimator = ref.watch(poseEstimatorProvider);

  // Start detection with camera frame stream
  return estimator.detect(cameraController.frameStream);
}
