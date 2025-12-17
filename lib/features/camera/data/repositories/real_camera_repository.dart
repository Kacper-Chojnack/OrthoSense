import 'dart:async';

import 'package:camera/camera.dart' as cam;
import 'package:flutter/foundation.dart';
import 'package:orthosense/features/camera/domain/models/camera_frame.dart';
import 'package:orthosense/features/camera/domain/repositories/camera_repository.dart';

/// Real implementation of [CameraRepository] using the camera package.
class RealCameraRepository implements CameraRepository {
  RealCameraRepository();

  cam.CameraController? _controller;
  List<cam.CameraDescription>? _cameras;

  final _frameController = StreamController<CameraFrame>.broadcast();
  bool _isStreaming = false;
  int _currentCameraIndex = 0;
  CameraConfig _config = const CameraConfig();

  @override
  bool get isInitialized => _controller?.value.isInitialized ?? false;

  @override
  Stream<CameraFrame> get frameStream => _frameController.stream;

  @override
  Object? get previewWidget {
    if (_controller == null || !isInitialized) return null;
    return cam.CameraPreview(_controller!);
  }

  @override
  CameraLensDirection get currentLensDirection {
    if (_cameras == null || _cameras!.isEmpty) {
      return CameraLensDirection.back;
    }
    return _mapLensDirection(_cameras![_currentCameraIndex].lensDirection);
  }

  @override
  Future<void> initialize([CameraConfig config = const CameraConfig()]) async {
    _config = config;

    try {
      _cameras = await cam.availableCameras();

      if (_cameras == null || _cameras!.isEmpty) {
        throw const CameraException(
          'NO_CAMERAS',
          'No cameras available on this device',
        );
      }

      _currentCameraIndex = _findCameraIndex(config.lensDirection);

      await _initializeController();
    } on cam.CameraException catch (e) {
      throw CameraException(e.code ?? 'UNKNOWN', e.description ?? 'Unknown');
    }
  }

  Future<void> _initializeController() async {
    await _controller?.dispose();

    _controller = cam.CameraController(
      _cameras![_currentCameraIndex],
      _mapResolution(_config.resolution),
      enableAudio: _config.enableAudio,
      imageFormatGroup: cam.ImageFormatGroup.yuv420,
    );

    await _controller!.initialize();
    await _startImageStream();
  }

  Future<void> _startImageStream() async {
    if (_isStreaming) return;

    _isStreaming = true;
    await _controller!.startImageStream(_processImage);
  }

  void _processImage(cam.CameraImage image) {
    if (_frameController.isClosed) return;

    final frame = CameraFrame(
      bytes: _concatenatePlanes(image.planes),
      width: image.width,
      height: image.height,
      timestamp: DateTime.now(),
      format: _mapImageFormat(image.format),
      rotation: _cameras![_currentCameraIndex].sensorOrientation,
    );

    _frameController.add(frame);
  }

  Uint8List _concatenatePlanes(List<cam.Plane> planes) {
    final allBytes = WriteBuffer();
    for (final plane in planes) {
      allBytes.putUint8List(plane.bytes);
    }
    return allBytes.done().buffer.asUint8List();
  }

  String _mapImageFormat(cam.ImageFormat format) {
    switch (format.group) {
      case cam.ImageFormatGroup.yuv420:
        return 'yuv420';
      case cam.ImageFormatGroup.bgra8888:
        return 'bgra8888';
      case cam.ImageFormatGroup.jpeg:
        return 'jpeg';
      case cam.ImageFormatGroup.nv21:
        return 'nv21';
      case cam.ImageFormatGroup.unknown:
        return 'unknown';
    }
  }

  @override
  Future<void> switchCamera() async {
    if (_cameras == null || _cameras!.length < 2) return;

    _currentCameraIndex = (_currentCameraIndex + 1) % _cameras!.length;
    _isStreaming = false;
    await _initializeController();
  }

  @override
  Future<void> dispose() async {
    _isStreaming = false;
    await _controller?.stopImageStream();
    await _controller?.dispose();
    _controller = null;
    await _frameController.close();
  }

  int _findCameraIndex(CameraLensDirection direction) {
    final targetDirection = _mapToPackageDirection(direction);
    final index =
        _cameras!.indexWhere((c) => c.lensDirection == targetDirection);
    return index >= 0 ? index : 0;
  }

  cam.CameraLensDirection _mapToPackageDirection(CameraLensDirection direction) {
    switch (direction) {
      case CameraLensDirection.front:
        return cam.CameraLensDirection.front;
      case CameraLensDirection.back:
        return cam.CameraLensDirection.back;
      case CameraLensDirection.external:
        return cam.CameraLensDirection.external;
    }
  }

  CameraLensDirection _mapLensDirection(cam.CameraLensDirection direction) {
    switch (direction) {
      case cam.CameraLensDirection.front:
        return CameraLensDirection.front;
      case cam.CameraLensDirection.back:
        return CameraLensDirection.back;
      case cam.CameraLensDirection.external:
        return CameraLensDirection.external;
    }
  }

  cam.ResolutionPreset _mapResolution(CameraResolution resolution) {
    switch (resolution) {
      case CameraResolution.low:
        return cam.ResolutionPreset.low;
      case CameraResolution.medium:
        return cam.ResolutionPreset.medium;
      case CameraResolution.high:
        return cam.ResolutionPreset.high;
      case CameraResolution.veryHigh:
        return cam.ResolutionPreset.veryHigh;
      case CameraResolution.ultraHigh:
        return cam.ResolutionPreset.ultraHigh;
      case CameraResolution.max:
        return cam.ResolutionPreset.max;
    }
  }
}
