import 'dart:typed_data';

import 'package:freezed_annotation/freezed_annotation.dart';

part 'camera_frame.freezed.dart';

/// Represents a single frame from the camera stream.
/// Abstracts platform-specific image formats for testability.
@Freezed(toJson: false, fromJson: false)
class CameraFrame with _$CameraFrame {
  const factory CameraFrame({
    /// Raw image bytes (platform-agnostic).
    required Uint8List bytes,

    /// Frame width in pixels.
    required int width,

    /// Frame height in pixels.
    required int height,

    /// Timestamp when frame was captured.
    required DateTime timestamp,

    /// Image format identifier (e.g., 'yuv420', 'bgra8888').
    required String format,

    /// Rotation in degrees (0, 90, 180, 270).
    @Default(0) int rotation,
  }) = _CameraFrame;

  const CameraFrame._();

  /// Aspect ratio of the frame.
  double get aspectRatio => width / height;

  /// Whether this is a valid frame with data.
  bool get isValid => bytes.isNotEmpty && width > 0 && height > 0;
}
