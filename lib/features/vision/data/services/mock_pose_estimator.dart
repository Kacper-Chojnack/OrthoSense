import 'dart:async';
import 'dart:math' as math;

import 'package:orthosense/features/camera/domain/models/camera_frame.dart';
import 'package:orthosense/features/vision/domain/models/models.dart';
import 'package:orthosense/features/vision/domain/services/pose_estimator.dart';

/// Mock implementation of [PoseEstimator] for prototyping.
/// Generates a stickman performing squats using sine-wave animation.
class MockPoseEstimator implements PoseEstimator {
  MockPoseEstimator({
    this.frameIntervalMs = 33, // ~30 FPS
    this.squatCycleDurationMs = 2000, // 2 seconds per squat cycle
  });

  final int frameIntervalMs;
  final int squatCycleDurationMs;

  Timer? _timer;
  final _poseController = StreamController<PoseResult>.broadcast();
  bool _isDisposed = false;

  @override
  Stream<PoseResult> detect(Stream<CameraFrame> frames) {
    // Mock ignores input frames - generates synthetic poses
    _startPoseGeneration();
    return _poseController.stream;
  }

  void _startPoseGeneration() {
    _timer?.cancel();
    _timer = Timer.periodic(
      Duration(milliseconds: frameIntervalMs),
      (_) => _emitPose(),
    );
  }

  void _emitPose() {
    if (_isDisposed || _poseController.isClosed) return;

    final pose = _generateSquatPose();
    _poseController.add(pose);
  }

  /// Generates a stickman pose performing squats.
  /// Uses sine wave to animate hip/knee positions.
  PoseResult _generateSquatPose() {
    final now = DateTime.now();
    final cycleProgress = (now.millisecondsSinceEpoch % squatCycleDurationMs) /
        squatCycleDurationMs;

    // Sine wave for smooth up/down motion (0 = standing, 1 = squatting)
    final squatDepth =
        (math.sin(cycleProgress * 2 * math.pi - math.pi / 2) + 1) / 2;

    final landmarks = _buildSquatLandmarks(squatDepth);

    return PoseResult(
      landmarks: landmarks,
      timestamp: now,
      confidence: 0.95,
    );
  }

  /// Builds 33 landmarks for a squatting stickman.
  /// [squatDepth] ranges from 0.0 (standing) to 1.0 (deep squat).
  List<PoseLandmark> _buildSquatLandmarks(double squatDepth) {
    // Base positions (standing pose, normalized 0-1)
    // Centered horizontally at 0.5

    // Head drops slightly during squat
    final headY = 0.15 + squatDepth * 0.08;

    // Shoulders drop during squat
    final shoulderY = 0.25 + squatDepth * 0.12;
    const shoulderWidth = 0.12;

    // Elbows - arms swing forward during squat for balance
    final elbowY = 0.35 + squatDepth * 0.05;
    final elbowX = 0.08 + squatDepth * 0.03;

    // Wrists - extend forward during squat
    final wristY = 0.38 + squatDepth * 0.02;
    final wristX = 0.06 + squatDepth * 0.05;

    // Hips drop significantly during squat
    final hipY = 0.50 + squatDepth * 0.18;
    const hipWidth = 0.08;

    // Knees move forward and down during squat
    final kneeY = 0.68 + squatDepth * 0.08;
    final kneeX = hipWidth + squatDepth * 0.04;

    // Ankles stay relatively fixed
    const ankleY = 0.88;
    const ankleWidth = 0.08;

    // Build all 33 landmarks
    return [
      // 0: Nose
      PoseLandmark(x: 0.5, y: headY),
      // 1-6: Eyes (simplified)
      PoseLandmark(x: 0.47, y: headY - 0.02),
      PoseLandmark(x: 0.47, y: headY - 0.02),
      PoseLandmark(x: 0.46, y: headY - 0.02),
      PoseLandmark(x: 0.53, y: headY - 0.02),
      PoseLandmark(x: 0.53, y: headY - 0.02),
      PoseLandmark(x: 0.54, y: headY - 0.02),
      // 7-8: Ears
      PoseLandmark(x: 0.44, y: headY - 0.01),
      PoseLandmark(x: 0.56, y: headY - 0.01),
      // 9-10: Mouth
      PoseLandmark(x: 0.48, y: headY + 0.03),
      PoseLandmark(x: 0.52, y: headY + 0.03),
      // 11-12: Shoulders
      PoseLandmark(x: 0.5 - shoulderWidth, y: shoulderY),
      PoseLandmark(x: 0.5 + shoulderWidth, y: shoulderY),
      // 13-14: Elbows
      PoseLandmark(x: 0.5 - shoulderWidth - elbowX, y: elbowY),
      PoseLandmark(x: 0.5 + shoulderWidth + elbowX, y: elbowY),
      // 15-16: Wrists
      PoseLandmark(x: 0.5 - shoulderWidth - wristX, y: wristY),
      PoseLandmark(x: 0.5 + shoulderWidth + wristX, y: wristY),
      // 17-22: Fingers (simplified, same as wrists)
      PoseLandmark(x: 0.5 - shoulderWidth - wristX - 0.02, y: wristY + 0.02),
      PoseLandmark(x: 0.5 + shoulderWidth + wristX + 0.02, y: wristY + 0.02),
      PoseLandmark(x: 0.5 - shoulderWidth - wristX, y: wristY + 0.03),
      PoseLandmark(x: 0.5 + shoulderWidth + wristX, y: wristY + 0.03),
      PoseLandmark(x: 0.5 - shoulderWidth - wristX + 0.02, y: wristY + 0.01),
      PoseLandmark(x: 0.5 + shoulderWidth + wristX - 0.02, y: wristY + 0.01),
      // 23-24: Hips
      PoseLandmark(x: 0.5 - hipWidth, y: hipY),
      PoseLandmark(x: 0.5 + hipWidth, y: hipY),
      // 25-26: Knees
      PoseLandmark(x: 0.5 - kneeX, y: kneeY),
      PoseLandmark(x: 0.5 + kneeX, y: kneeY),
      // 27-28: Ankles
      const PoseLandmark(x: 0.5 - ankleWidth, y: ankleY),
      const PoseLandmark(x: 0.5 + ankleWidth, y: ankleY),
      // 29-30: Heels
      const PoseLandmark(x: 0.5 - ankleWidth - 0.01, y: ankleY + 0.03),
      const PoseLandmark(x: 0.5 + ankleWidth + 0.01, y: ankleY + 0.03),
      // 31-32: Foot index
      const PoseLandmark(x: 0.5 - ankleWidth + 0.02, y: ankleY + 0.05),
      const PoseLandmark(x: 0.5 + ankleWidth - 0.02, y: ankleY + 0.05),
    ];
  }

  @override
  Future<void> dispose() async {
    _isDisposed = true;
    _timer?.cancel();
    _timer = null;
    await _poseController.close();
  }
}
