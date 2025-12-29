import 'package:orthosense/core/services/pose_detection_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'pose_detection_provider.g.dart';

@Riverpod(keepAlive: true)
PoseDetectionService poseDetectionService(Ref ref) {
  final service = PoseDetectionService();
  ref.onDispose(service.dispose);
  return service;
}

