/// Unit tests for TokenStorage implementation.
///
/// Test coverage:
/// 1. Token save/retrieve operations
/// 2. User info caching for offline-first
/// 3. Token expiration checking (JWT decode)
/// 4. Platform-specific storage (macOS vs iOS)
/// 5. Clear all functionality
///
/// Note: On macOS, SecureTokenStorage uses SharedPreferences instead of
/// FlutterSecureStorage due to platform limitations.
library;

import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:orthosense/features/auth/data/token_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ============================================================================
// Mocks
// ============================================================================

class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

class MockSharedPreferences extends Mock implements SharedPreferences {}

// ============================================================================
// Test Data
// ============================================================================

// Valid JWT with exp: 9999999999 (year ~2286)
const validToken =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJ1c2VyLTEyMyIsImV4cCI6OTk5OTk5OTk5OX0.signature';

// Expired JWT with exp: 1000000000 (year 2001)
const expiredToken =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJ1c2VyLTEyMyIsImV4cCI6MTAwMDAwMDAwMH0.signature';

// Malformed token
const malformedToken = 'not.a.valid.jwt';

/// Determine if we're on macOS for platform-specific test setup.
bool get _isMacOS => Platform.isMacOS;

void main() {
  late MockFlutterSecureStorage mockSecureStorage;
  late MockSharedPreferences mockSharedPrefs;
  late SecureTokenStorage tokenStorage;

  setUp(() {
    mockSecureStorage = MockFlutterSecureStorage();
    mockSharedPrefs = MockSharedPreferences();
    tokenStorage = SecureTokenStorage(mockSecureStorage, mockSharedPrefs);
  });

  group('TokenStorage - Access Token Operations', () {
    test('saveAccessToken stores token', () async {
      if (_isMacOS) {
        when(
          () => mockSharedPrefs.setString(StorageKeys.accessToken, validToken),
        ).thenAnswer((_) async => true);
      } else {
        when(
          () => mockSecureStorage.write(
            key: StorageKeys.accessToken,
            value: validToken,
          ),
        ).thenAnswer((_) async {});
      }

      await tokenStorage.saveAccessToken(validToken);

      if (_isMacOS) {
        verify(
          () => mockSharedPrefs.setString(StorageKeys.accessToken, validToken),
        ).called(1);
      } else {
        verify(
          () => mockSecureStorage.write(
            key: StorageKeys.accessToken,
            value: validToken,
          ),
        ).called(1);
      }
    });

    test('getAccessToken retrieves token', () async {
      if (_isMacOS) {
        when(
          () => mockSharedPrefs.getString(StorageKeys.accessToken),
        ).thenReturn(validToken);
      } else {
        when(
          () => mockSecureStorage.read(key: StorageKeys.accessToken),
        ).thenAnswer((_) async => validToken);
      }

      final result = await tokenStorage.getAccessToken();

      expect(result, equals(validToken));
    });

    test('getAccessToken returns null when no token stored', () async {
      if (_isMacOS) {
        when(
          () => mockSharedPrefs.getString(StorageKeys.accessToken),
        ).thenReturn(null);
      } else {
        when(
          () => mockSecureStorage.read(key: StorageKeys.accessToken),
        ).thenAnswer((_) async => null);
      }

      final result = await tokenStorage.getAccessToken();

      expect(result, isNull);
    });
  });

  group('TokenStorage - User Info Operations', () {
    test('saveUserInfo stores userId and email', () async {
      if (_isMacOS) {
        when(
          () => mockSharedPrefs.setString(StorageKeys.userId, 'user-123'),
        ).thenAnswer((_) async => true);
        when(
          () => mockSharedPrefs.setString(
            StorageKeys.userEmail,
            'test@example.com',
          ),
        ).thenAnswer((_) async => true);
      } else {
        when(
          () => mockSecureStorage.write(
            key: StorageKeys.userId,
            value: 'user-123',
          ),
        ).thenAnswer((_) async {});
        when(
          () => mockSecureStorage.write(
            key: StorageKeys.userEmail,
            value: 'test@example.com',
          ),
        ).thenAnswer((_) async {});
      }

      await tokenStorage.saveUserInfo(
        userId: 'user-123',
        email: 'test@example.com',
      );

      if (_isMacOS) {
        verify(
          () => mockSharedPrefs.setString(StorageKeys.userId, 'user-123'),
        ).called(1);
        verify(
          () => mockSharedPrefs.setString(
            StorageKeys.userEmail,
            'test@example.com',
          ),
        ).called(1);
      } else {
        verify(
          () => mockSecureStorage.write(
            key: StorageKeys.userId,
            value: 'user-123',
          ),
        ).called(1);
        verify(
          () => mockSecureStorage.write(
            key: StorageKeys.userEmail,
            value: 'test@example.com',
          ),
        ).called(1);
      }
    });

    test('getUserId retrieves cached user ID', () async {
      if (_isMacOS) {
        when(
          () => mockSharedPrefs.getString(StorageKeys.userId),
        ).thenReturn('user-123');
      } else {
        when(
          () => mockSecureStorage.read(key: StorageKeys.userId),
        ).thenAnswer((_) async => 'user-123');
      }

      final result = await tokenStorage.getUserId();

      expect(result, equals('user-123'));
    });

    test('getUserEmail retrieves cached email', () async {
      if (_isMacOS) {
        when(
          () => mockSharedPrefs.getString(StorageKeys.userEmail),
        ).thenReturn('test@example.com');
      } else {
        when(
          () => mockSecureStorage.read(key: StorageKeys.userEmail),
        ).thenAnswer((_) async => 'test@example.com');
      }

      final result = await tokenStorage.getUserEmail();

      expect(result, equals('test@example.com'));
    });
  });

  group('TokenStorage - Clear Operations', () {
    test('clearAll deletes all stored data', () async {
      if (_isMacOS) {
        when(
          () => mockSharedPrefs.remove(StorageKeys.accessToken),
        ).thenAnswer((_) async => true);
        when(
          () => mockSharedPrefs.remove(StorageKeys.userId),
        ).thenAnswer((_) async => true);
        when(
          () => mockSharedPrefs.remove(StorageKeys.userEmail),
        ).thenAnswer((_) async => true);
      } else {
        when(() => mockSecureStorage.deleteAll()).thenAnswer((_) async {});
      }

      await tokenStorage.clearAll();

      if (_isMacOS) {
        verify(() => mockSharedPrefs.remove(StorageKeys.accessToken)).called(1);
        verify(() => mockSharedPrefs.remove(StorageKeys.userId)).called(1);
        verify(() => mockSharedPrefs.remove(StorageKeys.userEmail)).called(1);
      } else {
        verify(() => mockSecureStorage.deleteAll()).called(1);
      }
    });
  });

  group('TokenStorage - Token Expiration', () {
    test('isTokenExpired returns false for valid non-expired token', () {
      final result = tokenStorage.isTokenExpired(validToken);

      expect(result, isFalse);
    });

    test('isTokenExpired returns true for expired token', () {
      final result = tokenStorage.isTokenExpired(expiredToken);

      expect(result, isTrue);
    });

    test('isTokenExpired returns true for malformed token', () {
      final result = tokenStorage.isTokenExpired(malformedToken);

      expect(result, isTrue);
    });

    test('isTokenExpired returns true for empty string', () {
      final result = tokenStorage.isTokenExpired('');

      expect(result, isTrue);
    });
  });

  group('TokenStorage - Token Decoding', () {
    test('decodeToken returns payload for valid token', () {
      final result = tokenStorage.decodeToken(validToken);

      expect(result, isNotNull);
      expect(result!['sub'], equals('user-123'));
    });

    test('decodeToken returns null for malformed token', () {
      final result = tokenStorage.decodeToken(malformedToken);

      expect(result, isNull);
    });

    test('getTokenExpiration returns expiration date for valid token', () {
      final result = tokenStorage.getTokenExpiration(validToken);

      expect(result, isNotNull);
      expect(result!.isAfter(DateTime.now()), isTrue);
    });

    test('getTokenExpiration returns null for malformed token', () {
      final result = tokenStorage.getTokenExpiration(malformedToken);

      expect(result, isNull);
    });
  });

  group('StorageKeys', () {
    test('has correct key values', () {
      expect(StorageKeys.accessToken, equals('access_token'));
      expect(StorageKeys.userId, equals('user_id'));
      expect(StorageKeys.userEmail, equals('user_email'));
    });
  });
}
