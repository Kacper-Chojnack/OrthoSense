import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orthosense/features/auth/data/token_storage.dart';

/// Callback function type for triggering logout.
typedef LogoutCallback = Future<void> Function();

/// Dio interceptor for handling authentication.
/// Automatically adds Bearer token to requests.
/// Handles 401 errors by triggering logout.
class AuthInterceptor extends Interceptor {
  AuthInterceptor({
    required this.ref,
    this.onUnauthorized,
  });

  final Ref ref;
  final LogoutCallback? onUnauthorized;

  /// Paths that don't require authentication.
  static const _publicPaths = <String>[
    '/api/v1/auth/login',
    '/api/v1/auth/register',
    '/api/v1/auth/forgot-password',
    '/api/v1/auth/reset-password',
    '/api/v1/auth/verify-email',
    '/health',
  ];

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Skip auth for public endpoints
    final isPublic = _publicPaths.any(
      (path) => options.path.contains(path),
    );

    if (!isPublic) {
      final tokenStorage = ref.read(tokenStorageProvider);
      final token = await tokenStorage.getAccessToken();

      if (token != null && !tokenStorage.isTokenExpired(token)) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }

    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    // Only clear tokens for 401 on authenticated endpoints (not login/register)
    final isPublic = _publicPaths.any(
      (path) => err.requestOptions.path.contains(path),
    );

    if (err.response?.statusCode == 401 && !isPublic) {
      // Token invalid or expired - trigger logout
      try {
        final tokenStorage = ref.read(tokenStorageProvider);
        await tokenStorage.clearAll();
      } catch (_) {
        // Ignore storage errors during cleanup
      }

      // Notify auth notifier about unauthorized state
      if (onUnauthorized != null) {
        await onUnauthorized!();
      }
    }

    handler.next(err);
  }
}
