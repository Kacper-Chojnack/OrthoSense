import 'package:dio/dio.dart';
import 'package:orthosense/features/auth/data/token_storage.dart';
import 'package:orthosense/features/auth/domain/models/models.dart';
import 'package:orthosense/infrastructure/networking/dio_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'auth_repository.g.dart';

/// Authentication repository handling all auth operations.
class AuthRepository {
  AuthRepository({
    required Dio dio,
    required TokenStorage tokenStorage,
  })  : _dio = dio,
        _tokenStorage = tokenStorage;

  final Dio _dio;
  final TokenStorage _tokenStorage;

  /// Register new user.
  Future<UserModel> register({
    required String email,
    required String password,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/v1/auth/register',
      data: {
        'email': email,
        'password': password,
      },
    );

    return UserModel.fromJson(response.data!);
  }

  /// Login user and return tokens.
  Future<AuthTokens> login({
    required String email,
    required String password,
  }) async {
    // OAuth2 password flow uses form data
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/v1/auth/login',
      data: {
        'username': email,
        'password': password,
      },
      options: Options(
        contentType: Headers.formUrlEncodedContentType,
      ),
    );

    final tokens = AuthTokens.fromJson(response.data!);

    // Persist token
    await _tokenStorage.saveAccessToken(tokens.accessToken);

    return tokens;
  }

  /// Get current authenticated user.
  Future<UserModel> getCurrentUser() async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/v1/auth/me',
    );

    final user = UserModel.fromJson(response.data!);

    // Cache user info for offline access
    await _tokenStorage.saveUserInfo(
      userId: user.id,
      email: user.email,
    );

    return user;
  }

  /// Request password reset email.
  Future<void> forgotPassword(String email) async {
    await _dio.post<void>(
      '/api/v1/auth/forgot-password',
      data: {'email': email},
    );
  }

  /// Reset password with token.
  Future<void> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    await _dio.post<void>(
      '/api/v1/auth/reset-password',
      data: {
        'token': token,
        'new_password': newPassword,
      },
    );
  }

  /// Verify email with token.
  Future<UserModel> verifyEmail(String token) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/v1/auth/verify-email',
      data: {'token': token},
    );

    return UserModel.fromJson(response.data!);
  }

  /// Logout - clear all stored tokens.
  Future<void> logout() async {
    await _tokenStorage.clearAll();
  }

  /// Check if user has valid stored token (for optimistic auth).
  Future<bool> hasValidStoredToken() async {
    final token = await _tokenStorage.getAccessToken();
    if (token == null) return false;
    return !_tokenStorage.isTokenExpired(token);
  }

  /// Get stored token.
  Future<String?> getStoredToken() async {
    return _tokenStorage.getAccessToken();
  }

  /// Build offline user from cached data.
  Future<UserModel?> getOfflineUser() async {
    final userId = await _tokenStorage.getUserId();
    final email = await _tokenStorage.getUserEmail();

    if (userId == null || email == null) return null;

    return UserModel(
      id: userId,
      email: email,
    );
  }
}

@Riverpod(keepAlive: true)
AuthRepository authRepository(Ref ref) {
  return AuthRepository(
    dio: ref.watch(dioProvider),
    tokenStorage: ref.watch(tokenStorageProvider),
  );
}
