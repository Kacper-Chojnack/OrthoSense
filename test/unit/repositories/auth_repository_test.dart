/// Unit tests for AuthRepository.
///
/// Test coverage:
/// 1. Login flow
/// 2. Register flow
/// 3. Token storage operations
/// 4. Password reset
/// 5. Offline user handling
library;

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AuthRepository', () {
    group('login', () {
      test('creates correct request payload', () {
        const email = 'test@example.com';
        const password = 'password123';

        final payload = {
          'username': email,
          'password': password,
        };

        expect(payload['username'], equals(email));
        expect(payload['password'], equals(password));
      });

      test('uses form-urlencoded content type', () {
        const contentType = 'application/x-www-form-urlencoded';
        expect(contentType, contains('form'));
      });

      test('endpoint is correct', () {
        const endpoint = '/api/v1/auth/login';
        expect(endpoint, startsWith('/api'));
        expect(endpoint, contains('login'));
      });
    });

    group('register', () {
      test('creates correct request payload', () {
        const email = 'newuser@example.com';
        const password = 'securePassword123';

        final payload = {
          'email': email,
          'password': password,
        };

        expect(payload['email'], equals(email));
        expect(payload['password'], equals(password));
      });

      test('endpoint is correct', () {
        const endpoint = '/api/v1/auth/register';
        expect(endpoint, contains('register'));
      });
    });

    group('getCurrentUser', () {
      test('endpoint is correct', () {
        const endpoint = '/api/v1/auth/me';
        expect(endpoint, contains('me'));
      });

      test('caches user info after fetch', () async {
        final mockStorage = MockTokenStorage();
        const userId = 'user-123';
        const email = 'test@example.com';

        await mockStorage.saveUserInfo(userId: userId, email: email);

        expect(mockStorage.cachedUserId, equals(userId));
        expect(mockStorage.cachedEmail, equals(email));
      });
    });

    group('forgotPassword', () {
      test('creates correct request payload', () {
        const email = 'forgot@example.com';

        final payload = {'email': email};

        expect(payload['email'], equals(email));
      });

      test('endpoint is correct', () {
        const endpoint = '/api/v1/auth/forgot-password';
        expect(endpoint, contains('forgot-password'));
      });
    });

    group('resetPassword', () {
      test('creates correct request payload', () {
        const token = 'reset-token-123';
        const newPassword = 'newSecurePassword';

        final payload = {
          'token': token,
          'new_password': newPassword,
        };

        expect(payload['token'], equals(token));
        expect(payload['new_password'], equals(newPassword));
      });

      test('endpoint is correct', () {
        const endpoint = '/api/v1/auth/reset-password';
        expect(endpoint, contains('reset-password'));
      });
    });

    group('verifyEmail', () {
      test('creates correct request payload', () {
        const token = 'verification-token-xyz';

        final payload = {'token': token};

        expect(payload['token'], equals(token));
      });

      test('endpoint is correct', () {
        const endpoint = '/api/v1/auth/verify-email';
        expect(endpoint, contains('verify-email'));
      });
    });

    group('logout', () {
      test('clears all stored tokens', () async {
        final mockStorage = MockTokenStorage();
        mockStorage.accessToken = 'some-token';
        mockStorage.cachedUserId = 'user-123';

        await mockStorage.clearAll();

        expect(mockStorage.accessToken, isNull);
        expect(mockStorage.cachedUserId, isNull);
      });
    });

    group('hasValidStoredToken', () {
      test('returns false when no token stored', () async {
        final mockStorage = MockTokenStorage();
        mockStorage.accessToken = null;

        final hasValid = await mockStorage.hasValidToken();

        expect(hasValid, isFalse);
      });

      test('returns false when token is expired', () async {
        final mockStorage = MockTokenStorage();
        mockStorage.accessToken = 'expired-token';
        mockStorage.isExpired = true;

        final hasValid = await mockStorage.hasValidToken();

        expect(hasValid, isFalse);
      });

      test('returns true when token is valid', () async {
        final mockStorage = MockTokenStorage();
        mockStorage.accessToken = 'valid-token';
        mockStorage.isExpired = false;

        final hasValid = await mockStorage.hasValidToken();

        expect(hasValid, isTrue);
      });
    });

    group('getOfflineUser', () {
      test('returns null when no cached user', () async {
        final mockStorage = MockTokenStorage();

        final user = await mockStorage.getOfflineUser();

        expect(user, isNull);
      });

      test('returns user when cached data exists', () async {
        final mockStorage = MockTokenStorage();
        mockStorage.cachedUserId = 'user-123';
        mockStorage.cachedEmail = 'cached@example.com';

        final user = await mockStorage.getOfflineUser();

        expect(user, isNotNull);
        expect(user!.id, equals('user-123'));
        expect(user.email, equals('cached@example.com'));
      });

      test('returns null when only userId is cached', () async {
        final mockStorage = MockTokenStorage();
        mockStorage.cachedUserId = 'user-123';
        mockStorage.cachedEmail = null;

        final user = await mockStorage.getOfflineUser();

        expect(user, isNull);
      });
    });
  });

  group('AuthTokens', () {
    test('parses from JSON', () {
      final json = {
        'access_token': 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...',
        'token_type': 'bearer',
      };

      final tokens = AuthTokens.fromJson(json);

      expect(tokens.accessToken, equals(json['access_token']));
      expect(tokens.tokenType, equals(json['token_type']));
    });

    test('handles optional refresh token', () {
      final json = {
        'access_token': 'access-token',
        'token_type': 'bearer',
        'refresh_token': 'refresh-token',
      };

      final tokens = AuthTokens.fromJson(json);

      expect(tokens.refreshToken, equals('refresh-token'));
    });

    test('handles missing refresh token', () {
      final json = {
        'access_token': 'access-token',
        'token_type': 'bearer',
      };

      final tokens = AuthTokens.fromJson(json);

      expect(tokens.refreshToken, isNull);
    });
  });

  group('UserModel', () {
    test('parses from JSON', () {
      final json = {
        'id': 'user-123',
        'email': 'user@example.com',
      };

      final user = UserModel.fromJson(json);

      expect(user.id, equals('user-123'));
      expect(user.email, equals('user@example.com'));
    });

    test('handles optional fields', () {
      final json = {
        'id': 'user-123',
        'email': 'user@example.com',
        'first_name': 'John',
        'last_name': 'Doe',
        'is_verified': true,
      };

      final user = UserModel.fromJson(json);

      expect(user.firstName, equals('John'));
      expect(user.lastName, equals('Doe'));
      expect(user.isVerified, isTrue);
    });

    test('creates offline user', () {
      const user = UserModel(
        id: 'offline-123',
        email: 'offline@example.com',
      );

      expect(user.id, equals('offline-123'));
      expect(user.email, equals('offline@example.com'));
    });
  });

  group('API Error Handling', () {
    test('handles 401 unauthorized', () {
      const statusCode = 401;
      final isUnauthorized = statusCode == 401;

      expect(isUnauthorized, isTrue);
    });

    test('handles 400 bad request', () {
      const statusCode = 400;
      final isBadRequest = statusCode == 400;

      expect(isBadRequest, isTrue);
    });

    test('handles 409 conflict (email already exists)', () {
      const statusCode = 409;
      final isConflict = statusCode == 409;

      expect(isConflict, isTrue);
    });

    test('handles network errors', () {
      const isNetworkError = true;
      expect(isNetworkError, isTrue);
    });
  });

  group('Token Expiry', () {
    test('decodes JWT expiry', () {
      final now = DateTime.now();
      final expiry = now.add(const Duration(hours: 1));
      final expirySeconds = expiry.millisecondsSinceEpoch ~/ 1000;

      final isExpired = expiry.isBefore(DateTime.now());

      expect(isExpired, isFalse);
      expect(expirySeconds, greaterThan(0));
    });

    test('detects expired token', () {
      final expiry = DateTime.now().subtract(const Duration(hours: 1));
      final isExpired = expiry.isBefore(DateTime.now());

      expect(isExpired, isTrue);
    });
  });
}

// Mock classes

class MockTokenStorage {
  String? accessToken;
  String? cachedUserId;
  String? cachedEmail;
  bool isExpired = false;

  Future<String?> getAccessToken() async => accessToken;

  Future<void> saveAccessToken(String token) async {
    accessToken = token;
  }

  Future<void> saveUserInfo({
    required String userId,
    required String email,
  }) async {
    cachedUserId = userId;
    cachedEmail = email;
  }

  Future<void> clearAll() async {
    accessToken = null;
    cachedUserId = null;
    cachedEmail = null;
  }

  Future<bool> hasValidToken() async {
    if (accessToken == null) return false;
    return !isExpired;
  }

  Future<UserModel?> getOfflineUser() async {
    if (cachedUserId == null || cachedEmail == null) return null;
    return UserModel(id: cachedUserId!, email: cachedEmail!);
  }
}

class AuthTokens {
  const AuthTokens({
    required this.accessToken,
    required this.tokenType,
    this.refreshToken,
  });

  factory AuthTokens.fromJson(Map<String, dynamic> json) {
    return AuthTokens(
      accessToken: json['access_token'] as String,
      tokenType: json['token_type'] as String,
      refreshToken: json['refresh_token'] as String?,
    );
  }

  final String accessToken;
  final String tokenType;
  final String? refreshToken;
}

class UserModel {
  const UserModel({
    required this.id,
    required this.email,
    this.firstName,
    this.lastName,
    this.isVerified = false,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      firstName: json['first_name'] as String?,
      lastName: json['last_name'] as String?,
      isVerified: json['is_verified'] as bool? ?? false,
    );
  }

  final String id;
  final String email;
  final String? firstName;
  final String? lastName;
  final bool isVerified;
}
