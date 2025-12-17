import 'dart:io' show Platform;

import 'package:orthosense/features/camera/domain/models/camera_frame.dart';
import 'package:orthosense/features/camera/domain/repositories/camera_repository.dart';
import 'package:orthosense/features/camera/presentation/providers/camera_providers.dart';
import 'package:orthosense/features/camera/presentation/providers/camera_state.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'camera_controller.g.dart';

/// Controller managing camera lifecycle and permissions.
@riverpod
class CameraController extends _$CameraController {
  CameraRepository get _repository => ref.read(cameraRepositoryProvider);

  @override
  CameraState build() {
    ref.onDispose(_handleDispose);
    return const CameraState.initial();
  }

  /// Initializes the camera with permission handling.
  Future<void> initialize([CameraConfig config = const CameraConfig()]) async {
    if (state is CameraStateReady || state is CameraStateInitializing) {
      return;
    }

    state = const CameraState.requestingPermission();

    // Skip permission check on desktop platforms (macOS, Windows, Linux)
    final isDesktop = Platform.isMacOS || Platform.isWindows || Platform.isLinux;
    final permissionStatus = isDesktop 
        ? CameraPermissionStatus.granted 
        : await _requestCameraPermission();

    if (permissionStatus != CameraPermissionStatus.granted) {
      state = CameraState.permissionDenied(status: permissionStatus);
      return;
    }

    state = const CameraState.initializing();

    try {
      await _repository.initialize(config);
      state = CameraState.ready(lensDirection: _repository.currentLensDirection);
    } on CameraException catch (e) {
      state = CameraState.error(message: e.description, code: e.code);
    } catch (e) {
      state = CameraState.error(message: e.toString());
    }
  }

  /// Switches between front and back camera.
  Future<void> switchCamera() async {
    if (state is! CameraStateReady) return;

    try {
      await _repository.switchCamera();
      state = CameraState.ready(lensDirection: _repository.currentLensDirection);
    } on CameraException catch (e) {
      state = CameraState.error(message: e.description, code: e.code);
    }
  }

  /// Stream of camera frames.
  Stream<CameraFrame> get frameStream => _repository.frameStream;

  /// Returns the preview widget if available (for real camera).
  Object? get previewWidget => _repository.previewWidget;

  /// Whether camera is ready for use.
  bool get isReady => state is CameraStateReady;

  /// Stops the camera and releases resources.
  Future<void> stop() async {
    await _repository.dispose();
    state = const CameraState.disposed();
  }

  Future<CameraPermissionStatus> _requestCameraPermission() async {
    final status = await Permission.camera.status;

    if (status.isGranted) {
      return CameraPermissionStatus.granted;
    }

    if (status.isPermanentlyDenied) {
      return CameraPermissionStatus.permanentlyDenied;
    }

    if (status.isRestricted) {
      return CameraPermissionStatus.restricted;
    }

    final result = await Permission.camera.request();

    if (result.isGranted) {
      return CameraPermissionStatus.granted;
    }

    if (result.isPermanentlyDenied) {
      return CameraPermissionStatus.permanentlyDenied;
    }

    return CameraPermissionStatus.denied;
  }

  void _handleDispose() {
    _repository.dispose();
  }
}
