import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'package:orthosense/features/camera/domain/models/camera_frame.dart';
import 'package:orthosense/features/camera/domain/repositories/camera_repository.dart';

/// Mock implementation of [CameraRepository] for testing and simulators.
/// Emits synthetic frames at specified intervals.
class MockCameraRepository implements CameraRepository {
  MockCameraRepository({
    this.frameIntervalMs = 33, // ~30 fps
    this.simulatedWidth = 640,
    this.simulatedHeight = 480,
  });

  final int frameIntervalMs;
  final int simulatedWidth;
  final int simulatedHeight;

  final _frameController = StreamController<CameraFrame>.broadcast();
  Timer? _frameTimer;
  bool _isInitialized = false;
  CameraLensDirection _lensDirection = CameraLensDirection.back;
  final _random = Random();

  @override
  bool get isInitialized => _isInitialized;

  @override
  Stream<CameraFrame> get frameStream => _frameController.stream;

  @override
  Object? get previewWidget => null; // Mock has no native preview

  @override
  CameraLensDirection get currentLensDirection => _lensDirection;

  @override
  Future<void> initialize([CameraConfig config = const CameraConfig()]) async {
    _lensDirection = config.lensDirection;

    // Simulate initialization delay
    await Future<void>.delayed(const Duration(milliseconds: 500));

    _isInitialized = true;
    _startFrameEmission();
  }

  void _startFrameEmission() {
    _frameTimer?.cancel();
    _frameTimer = Timer.periodic(
      Duration(milliseconds: frameIntervalMs),
      (_) => _emitFrame(),
    );
  }

  void _emitFrame() {
    if (_frameController.isClosed || !_isInitialized) return;

    // Generate synthetic frame with gradient pattern
    final bytes = _generateSyntheticFrame();

    final frame = CameraFrame(
      bytes: bytes,
      width: simulatedWidth,
      height: simulatedHeight,
      timestamp: DateTime.now(),
      format: 'mock_rgb',
    );

    _frameController.add(frame);
  }

  Uint8List _generateSyntheticFrame() {
    // Generate a simple gradient pattern with time-based variation
    final frameSize = simulatedWidth * simulatedHeight * 3; // RGB
    final bytes = Uint8List(frameSize);

    final timeOffset = DateTime.now().millisecondsSinceEpoch % 1000;
    final hueShift = (timeOffset / 1000 * 255).toInt();

    for (var y = 0; y < simulatedHeight; y++) {
      for (var x = 0; x < simulatedWidth; x++) {
        final index = (y * simulatedWidth + x) * 3;

        // Create animated gradient
        bytes[index] = ((x * 255 ~/ simulatedWidth) + hueShift) % 256; // R
        bytes[index + 1] =
            ((y * 255 ~/ simulatedHeight) + hueShift ~/ 2) % 256; // G
        bytes[index + 2] = (128 + _random.nextInt(20)) % 256; // B with noise
      }
    }

    return bytes;
  }

  @override
  Future<void> switchCamera() async {
    _lensDirection = _lensDirection == CameraLensDirection.back
        ? CameraLensDirection.front
        : CameraLensDirection.back;
  }

  @override
  Future<void> dispose() async {
    _frameTimer?.cancel();
    _frameTimer = null;
    _isInitialized = false;
    await _frameController.close();
  }
}
