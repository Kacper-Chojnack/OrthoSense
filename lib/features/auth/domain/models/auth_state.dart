import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:orthosense/features/auth/domain/models/user_model.dart';

part 'auth_state.freezed.dart';

/// Authentication state for the app.
@freezed
sealed class AuthState with _$AuthState {
  /// Initial state before auth check.
  const factory AuthState.initial() = AuthStateInitial;

  /// Checking auth status (reading token).
  const factory AuthState.loading() = AuthStateLoading;

  /// User is authenticated.
  const factory AuthState.authenticated({
    required UserModel user,
    required String accessToken,
  }) = AuthStateAuthenticated;

  /// User is not authenticated.
  const factory AuthState.unauthenticated({
    String? message,
  }) = AuthStateUnauthenticated;

  /// Auth error occurred.
  const factory AuthState.error({
    required String message,
  }) = AuthStateError;
}
