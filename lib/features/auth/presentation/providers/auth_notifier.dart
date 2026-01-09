import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:orthosense/features/auth/data/auth_repository.dart';
import 'package:orthosense/features/auth/data/token_storage.dart';
import 'package:orthosense/features/auth/domain/models/models.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'auth_notifier.g.dart';

/// Auth state notifier managing authentication flow.
@Riverpod(keepAlive: true)
class AuthNotifier extends _$AuthNotifier {
  late AuthRepository _authRepository;
  late TokenStorage _tokenStorage;

  @override
  AuthState build() {
    _authRepository = ref.watch(authRepositoryProvider);
    _tokenStorage = ref.watch(tokenStorageProvider);

    // Check auth status on initialization
    Future.microtask(_checkAuthStatus);

    return const AuthState.initial();
  }

  /// Check authentication status on app start.
  /// Implements optimistic auth for offline-first support.
  Future<void> _checkAuthStatus() async {
    state = const AuthState.loading();

    try {
      final token = await _tokenStorage.getAccessToken();

      if (token == null) {
        state = const AuthState.unauthenticated();
        return;
      }

      // Check if token is expired
      if (_tokenStorage.isTokenExpired(token)) {
        await _tokenStorage.clearAll();
        state = const AuthState.unauthenticated(
          message: 'Session expired. Please login again.',
        );
        return;
      }

      // Try to get current user from API
      try {
        final user = await _authRepository.getCurrentUser();
        state = AuthState.authenticated(
          user: user,
          accessToken: token,
        );
      } on DioException catch (e) {
        // Network error - use optimistic auth with cached data
        if (_isNetworkError(e)) {
          final offlineUser = await _authRepository.getOfflineUser();
          if (offlineUser != null) {
            state = AuthState.authenticated(
              user: offlineUser,
              accessToken: token,
            );
            return;
          }
        }

        // Auth error (401) or no cached data
        if (e.response?.statusCode == 401) {
          await _tokenStorage.clearAll();
          state = const AuthState.unauthenticated(
            message: 'Session expired. Please login again.',
          );
          return;
        }

        // Other network errors with cached user
        final offlineUser = await _authRepository.getOfflineUser();
        if (offlineUser != null) {
          state = AuthState.authenticated(
            user: offlineUser,
            accessToken: token,
          );
          return;
        }

        state = const AuthState.unauthenticated();
      }
    } catch (e) {
      state = AuthState.error(message: e.toString());
    }
  }

  /// Login with email and password.
  Future<void> login({
    required String email,
    required String password,
  }) async {
    state = const AuthState.loading();

    try {
      final tokens = await _authRepository.login(
        email: email,
        password: password,
      );

      // Fetch user profile
      final user = await _authRepository.getCurrentUser();

      state = AuthState.authenticated(
        user: user,
        accessToken: tokens.accessToken,
      );
    } on DioException catch (e) {
      final message = _extractErrorMessage(e);
      state = AuthState.unauthenticated(message: message);
    } catch (e, stackTrace) {
      // Log unexpected errors for debugging
      debugPrint('Login error: $e');
      debugPrint('Stack trace: $stackTrace');
      state = AuthState.error(message: e.toString());
    }
  }

  /// Register new user.
  Future<void> register({
    required String email,
    required String password,
  }) async {
    state = const AuthState.loading();

    try {
      await _authRepository.register(
        email: email,
        password: password,
      );

      // Auto-login after registration
      await login(email: email, password: password);
    } on DioException catch (e) {
      final message = _extractErrorMessage(e);
      state = AuthState.unauthenticated(message: message);
    } catch (e) {
      state = AuthState.error(message: e.toString());
    }
  }

  /// Logout user.
  Future<void> logout() async {
    state = const AuthState.loading();

    try {
      await _authRepository.logout();
      state = const AuthState.unauthenticated();
    } catch (e) {
      // Even if logout fails, clear local state
      state = const AuthState.unauthenticated();
    }
  }

  /// Request password reset.
  Future<bool> forgotPassword(String email) async {
    try {
      await _authRepository.forgotPassword(email);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Refresh auth status.
  Future<void> refreshAuthStatus() async {
    await _checkAuthStatus();
  }

  bool _isNetworkError(DioException e) {
    return e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout;
  }

  String _extractErrorMessage(DioException e) {
    // Handle network errors first (no response)
    if (_isNetworkError(e)) {
      return 'Unable to connect to server. Please check your internet connection.';
    }

    // Handle server response errors
    final data = e.response?.data;
    if (data is Map<String, dynamic> && data.containsKey('detail')) {
      final detail = data['detail'];
      // Handle validation errors array
      if (detail is List) {
        return detail.map((e) => e['msg'] ?? e.toString()).join(', ');
      }
      return detail.toString();
    }

    // Handle specific status codes
    return switch (e.response?.statusCode) {
      401 => 'Invalid email or password',
      400 => 'Invalid request. Please check your input.',
      403 => 'Access denied. Please try again.',
      404 => 'Service not found. Please try again later.',
      500 => 'Server error. Please try again later.',
      502 ||
      503 ||
      504 => 'Server is temporarily unavailable. Please try again.',
      _ => 'An error occurred. Please try again.',
    };
  }
}

/// Helper provider to check if user is authenticated.
@riverpod
bool isAuthenticated(Ref ref) {
  final authState = ref.watch(authProvider);
  return authState is AuthStateAuthenticated;
}

/// Helper provider to get current user.
@riverpod
UserModel? currentUser(Ref ref) {
  final authState = ref.watch(authProvider);
  return switch (authState) {
    AuthStateAuthenticated(:final user) => user,
    _ => null,
  };
}

/// Helper provider to get current access token.
@riverpod
String? accessToken(Ref ref) {
  final authState = ref.watch(authProvider);
  return switch (authState) {
    AuthStateAuthenticated(:final accessToken) => accessToken,
    _ => null,
  };
}
