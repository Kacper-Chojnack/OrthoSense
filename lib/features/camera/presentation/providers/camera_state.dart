import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:orthosense/features/camera/domain/repositories/camera_repository.dart';

part 'camera_state.freezed.dart';

/// Permission status for camera access.
enum CameraPermissionStatus {
  /// Permission not yet requested.
  initial,

  /// Permission granted.
  granted,

  /// Permission denied by user.
  denied,

  /// Permission permanently denied (must open settings).
  permanentlyDenied,

  /// Permission restricted by system (parental controls, etc).
  restricted,
}

/// Represents the current state of the camera system.
@freezed
class CameraState with _$CameraState {
  /// Initial state before any action.
  const factory CameraState.initial() = CameraStateInitial;

  /// Requesting camera permission.
  const factory CameraState.requestingPermission() =
      CameraStateRequestingPermission;

  /// Permission denied, camera cannot be used.
  const factory CameraState.permissionDenied({
    required CameraPermissionStatus status,
  }) = CameraStatePermissionDenied;

  /// Camera is initializing.
  const factory CameraState.initializing() = CameraStateInitializing;

  /// Camera ready and streaming.
  const factory CameraState.ready({
    required CameraLensDirection lensDirection,
  }) = CameraStateReady;

  /// Camera error occurred.
  const factory CameraState.error({
    required String message,
    String? code,
  }) = CameraStateError;

  /// Camera disposed/stopped.
  const factory CameraState.disposed() = CameraStateDisposed;
}
