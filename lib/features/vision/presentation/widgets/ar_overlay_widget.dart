import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orthosense/features/vision/domain/models/models.dart';
import 'package:orthosense/features/vision/presentation/painters/skeleton_painter.dart';
import 'package:orthosense/features/vision/presentation/providers/pose_detection_provider.dart';

/// AR overlay widget that displays skeleton on top of camera preview.
/// Transparent and passes touch events through.
class AROverlayWidget extends ConsumerWidget {
  const AROverlayWidget({
    super.key,
    this.jointColor = Colors.red,
    this.boneColor = Colors.green,
    this.showDebugInfo = false,
  });

  final Color jointColor;
  final Color boneColor;
  final bool showDebugInfo;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final poseAsync = ref.watch(poseDetectionProvider);

    return poseAsync.when(
      data: (pose) => _buildOverlay(context, pose),
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildOverlay(BuildContext context, PoseResult? pose) {
    return IgnorePointer(
      // Allow touch events to pass through to camera controls
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Skeleton painter
          RepaintBoundary(
            child: CustomPaint(
              painter: SkeletonPainter(
                pose: pose,
                jointColor: jointColor,
                boneColor: boneColor,
              ),
              willChange: true,
            ),
          ),
          // Debug info overlay
          if (showDebugInfo && pose != null) _buildDebugInfo(context, pose),
        ],
      ),
    );
  }

  Widget _buildDebugInfo(BuildContext context, PoseResult pose) {
    return Positioned(
      top: 16,
      left: 16,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black54,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Landmarks: ${pose.landmarks.length}',
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
            Text(
              'Confidence: ${(pose.confidence * 100).toStringAsFixed(1)}%',
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
            const Text(
              'FPS: ~30 (Mock)',
              style: TextStyle(color: Colors.white, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
