import 'package:flutter/material.dart';
import 'package:orthosense/features/vision/domain/models/models.dart';

/// Custom painter that draws a skeleton overlay from pose landmarks.
/// Optimized for performance with minimal allocations during paint.
class SkeletonPainter extends CustomPainter {
  SkeletonPainter({
    required this.pose,
    this.jointColor = Colors.red,
    this.boneColor = Colors.green,
    this.jointRadius = 6.0,
    this.boneStrokeWidth = 3.0,
    this.mirrorHorizontally = true,
  });

  final PoseResult? pose;
  final Color jointColor;
  final Color boneColor;
  final double jointRadius;
  final double boneStrokeWidth;
  final bool mirrorHorizontally;

  // Pre-defined bone connections (pairs of landmark indices)
  static const List<(int, int)> _boneConnections = [
    // Face
    (PoseLandmarkIndex.leftEar, PoseLandmarkIndex.leftEye),
    (PoseLandmarkIndex.leftEye, PoseLandmarkIndex.nose),
    (PoseLandmarkIndex.nose, PoseLandmarkIndex.rightEye),
    (PoseLandmarkIndex.rightEye, PoseLandmarkIndex.rightEar),
    // Torso
    (PoseLandmarkIndex.leftShoulder, PoseLandmarkIndex.rightShoulder),
    (PoseLandmarkIndex.leftShoulder, PoseLandmarkIndex.leftHip),
    (PoseLandmarkIndex.rightShoulder, PoseLandmarkIndex.rightHip),
    (PoseLandmarkIndex.leftHip, PoseLandmarkIndex.rightHip),
    // Left arm
    (PoseLandmarkIndex.leftShoulder, PoseLandmarkIndex.leftElbow),
    (PoseLandmarkIndex.leftElbow, PoseLandmarkIndex.leftWrist),
    // Right arm
    (PoseLandmarkIndex.rightShoulder, PoseLandmarkIndex.rightElbow),
    (PoseLandmarkIndex.rightElbow, PoseLandmarkIndex.rightWrist),
    // Left leg
    (PoseLandmarkIndex.leftHip, PoseLandmarkIndex.leftKnee),
    (PoseLandmarkIndex.leftKnee, PoseLandmarkIndex.leftAnkle),
    // Right leg
    (PoseLandmarkIndex.rightHip, PoseLandmarkIndex.rightKnee),
    (PoseLandmarkIndex.rightKnee, PoseLandmarkIndex.rightAnkle),
  ];

  // Key joints to draw (skip minor landmarks for performance)
  static const List<int> _keyJoints = [
    PoseLandmarkIndex.nose,
    PoseLandmarkIndex.leftShoulder,
    PoseLandmarkIndex.rightShoulder,
    PoseLandmarkIndex.leftElbow,
    PoseLandmarkIndex.rightElbow,
    PoseLandmarkIndex.leftWrist,
    PoseLandmarkIndex.rightWrist,
    PoseLandmarkIndex.leftHip,
    PoseLandmarkIndex.rightHip,
    PoseLandmarkIndex.leftKnee,
    PoseLandmarkIndex.rightKnee,
    PoseLandmarkIndex.leftAnkle,
    PoseLandmarkIndex.rightAnkle,
  ];

  @override
  void paint(Canvas canvas, Size size) {
    if (pose == null || !pose!.isValid) return;

    final bonePaint = Paint()
      ..color = boneColor
      ..strokeWidth = boneStrokeWidth
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final jointPaint = Paint()
      ..color = jointColor
      ..style = PaintingStyle.fill;

    final jointBorderPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    // Draw bones first (underneath joints)
    _drawBones(canvas, size, bonePaint);

    // Draw joints on top
    _drawJoints(canvas, size, jointPaint, jointBorderPaint);
  }

  void _drawBones(Canvas canvas, Size size, Paint paint) {
    for (final connection in _boneConnections) {
      final start = pose!.landmarkAt(connection.$1);
      final end = pose!.landmarkAt(connection.$2);

      if (start == null || end == null) continue;
      if (!start.isVisible || !end.isVisible) continue;

      final startPoint = _toScreenPoint(start, size);
      final endPoint = _toScreenPoint(end, size);

      canvas.drawLine(startPoint, endPoint, paint);
    }
  }

  void _drawJoints(
    Canvas canvas,
    Size size,
    Paint fillPaint,
    Paint borderPaint,
  ) {
    for (final index in _keyJoints) {
      final landmark = pose!.landmarkAt(index);
      if (landmark == null || !landmark.isVisible) continue;

      final point = _toScreenPoint(landmark, size);

      // Draw white border for visibility
      canvas.drawCircle(point, jointRadius + 1, borderPaint);
      // Draw filled joint
      canvas.drawCircle(point, jointRadius, fillPaint);
    }
  }

  /// Converts normalized landmark coordinates to screen coordinates.
  Offset _toScreenPoint(PoseLandmark landmark, Size size) {
    final x = mirrorHorizontally ? (1.0 - landmark.x) : landmark.x;
    return Offset(x * size.width, landmark.y * size.height);
  }

  @override
  bool shouldRepaint(covariant SkeletonPainter oldDelegate) {
    // Repaint only when pose changes
    return pose != oldDelegate.pose ||
        jointColor != oldDelegate.jointColor ||
        boneColor != oldDelegate.boneColor;
  }
}
