import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'token_storage.g.dart';

/// Keys for secure storage.
abstract class StorageKeys {
  static const accessToken = 'access_token';
  static const userId = 'user_id';
  static const userEmail = 'user_email';
}

/// Abstract interface for token storage.
abstract class TokenStorage {
  Future<void> saveAccessToken(String token);
  Future<String?> getAccessToken();
  Future<void> saveUserInfo({required String userId, required String email});
  Future<String?> getUserId();
  Future<String?> getUserEmail();
  Future<void> clearAll();
  bool isTokenExpired(String token);
  Map<String, dynamic>? decodeToken(String token);
  DateTime? getTokenExpiration(String token);
}

/// Secure token storage using FlutterSecureStorage (iOS/Android).
class SecureTokenStorage implements TokenStorage {
  SecureTokenStorage(this._storage);

  final FlutterSecureStorage _storage;

  @override
  Future<void> saveAccessToken(String token) async {
    await _storage.write(key: StorageKeys.accessToken, value: token);
  }

  @override
  Future<String?> getAccessToken() async {
    return _storage.read(key: StorageKeys.accessToken);
  }

  @override
  Future<void> saveUserInfo({
    required String userId,
    required String email,
  }) async {
    await _storage.write(key: StorageKeys.userId, value: userId);
    await _storage.write(key: StorageKeys.userEmail, value: email);
  }

  @override
  Future<String?> getUserId() async {
    return _storage.read(key: StorageKeys.userId);
  }

  @override
  Future<String?> getUserEmail() async {
    return _storage.read(key: StorageKeys.userEmail);
  }

  @override
  Future<void> clearAll() async {
    await _storage.deleteAll();
  }

  @override
  bool isTokenExpired(String token) {
    try {
      return JwtDecoder.isExpired(token);
    } catch (_) {
      return true;
    }
  }

  @override
  Map<String, dynamic>? decodeToken(String token) {
    try {
      return JwtDecoder.decode(token);
    } catch (_) {
      return null;
    }
  }

  @override
  DateTime? getTokenExpiration(String token) {
    try {
      return JwtDecoder.getExpirationDate(token);
    } catch (_) {
      return null;
    }
  }
}

@Riverpod(keepAlive: true)
FlutterSecureStorage flutterSecureStorage(Ref ref) {
  return const FlutterSecureStorage(
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );
}

/// Secure token storage provider.
@Riverpod(keepAlive: true)
TokenStorage tokenStorage(Ref ref) {
  return SecureTokenStorage(ref.watch(flutterSecureStorageProvider));
}
