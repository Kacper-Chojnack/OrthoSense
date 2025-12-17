import 'package:orthosense/features/camera/domain/models/camera_frame.dart';

/// Camera resolution presets.
enum CameraResolution {
  /// 352x288 on iOS, 240p on Android.
  low,

  /// 480p.
  medium,

  /// 720p.
  high,

  /// 1080p.
  veryHigh,

  /// 2160p (may not be supported).
  ultraHigh,

  /// Maximum available resolution.
  max,
}

/// Camera lens direction.
enum CameraLensDirection {
  front,
  back,
  external,
}

/// Camera initialization configuration.
class CameraConfig {
  const CameraConfig({
    this.resolution = CameraResolution.medium,
    this.lensDirection = CameraLensDirection.back,
    this.enableAudio = false,
  });

  final CameraResolution resolution;
  final CameraLensDirection lensDirection;
  final bool enableAudio;
}

/// Repository interface for camera operations.
/// Abstracts hardware details for testability.
abstract class CameraRepository {
  /// Initializes camera with given configuration.
  /// Throws [CameraException] on failure.
  Future<void> initialize([CameraConfig config = const CameraConfig()]);

  /// Stream of camera frames.
  /// Emits frames only after [initialize] completes successfully.
  Stream<CameraFrame> get frameStream;

  /// Current preview widget (platform-specific).
  /// Returns null if not initialized.
  Object? get previewWidget;

  /// Whether camera is currently initialized and streaming.
  bool get isInitialized;

  /// Disposes camera resources.
  /// Must be called to prevent memory leaks.
  Future<void> dispose();

  /// Switches between front and back camera.
  Future<void> switchCamera();

  /// Current lens direction.
  CameraLensDirection get currentLensDirection;
}

/// Exception thrown by camera operations.
class CameraException implements Exception {
  const CameraException(this.code, this.description);

  final String code;
  final String description;

  @override
  String toString() => 'CameraException($code): $description';
}
