import 'package:orthosense/features/camera/data/repositories/mock_camera_repository.dart';
import 'package:orthosense/features/camera/data/repositories/real_camera_repository.dart';
import 'package:orthosense/features/camera/domain/repositories/camera_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'camera_providers.g.dart';

/// Toggle between Mock and Real camera.
/// Set to true for simulator/testing, false for device.
const bool kUseMockCamera = true;

/// Provides [CameraRepository] implementation.
/// Override in tests to inject MockCameraRepository.
@Riverpod(keepAlive: true)
CameraRepository cameraRepository(CameraRepositoryRef ref) {
  final repository =
      kUseMockCamera ? MockCameraRepository() : RealCameraRepository();

  ref.onDispose(() async {
    await repository.dispose();
  });

  return repository;
}
