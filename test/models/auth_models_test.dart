/// Unit tests for Auth Domain Models.
///
/// Test coverage:
/// 1. UserModel serialization/deserialization
/// 2. AuthState variants
/// 3. AuthTokens model
/// 4. Model equality
/// 5. JSON conversion
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:orthosense/features/auth/domain/models/auth_state.dart';
import 'package:orthosense/features/auth/domain/models/auth_tokens.dart';
import 'package:orthosense/features/auth/domain/models/user_model.dart';

void main() {
  group('UserModel', () {
    test('creates user with required fields', () {
      const user = UserModel(
        id: 'user-123',
        email: 'test@example.com',
      );

      expect(user.id, equals('user-123'));
      expect(user.email, equals('test@example.com'));
      expect(user.fullName, equals(''));
      expect(user.role, equals(UserRole.patient));
      expect(user.isActive, isTrue);
      expect(user.isVerified, isFalse);
    });

    test('creates user with all fields', () {
      final user = UserModel(
        id: 'user-456',
        email: 'admin@example.com',
        fullName: 'Admin User',
        role: UserRole.admin,
        isActive: true,
        isVerified: true,
        createdAt: DateTime(2024, 1, 1),
      );

      expect(user.fullName, equals('Admin User'));
      expect(user.role, equals(UserRole.admin));
      expect(user.isVerified, isTrue);
      expect(user.createdAt, equals(DateTime(2024, 1, 1)));
    });

    test('serializes to JSON correctly', () {
      const user = UserModel(
        id: 'user-789',
        email: 'json@example.com',
        fullName: 'JSON User',
      );

      final json = user.toJson();

      expect(json['id'], equals('user-789'));
      expect(json['email'], equals('json@example.com'));
      expect(json['full_name'], equals('JSON User'));
    });

    test('deserializes from JSON correctly', () {
      final json = {
        'id': 'from-json',
        'email': 'from@json.com',
        'full_name': 'From JSON',
        'role': 'admin',
        'is_active': true,
        'is_verified': true,
      };

      final user = UserModel.fromJson(json);

      expect(user.id, equals('from-json'));
      expect(user.email, equals('from@json.com'));
      expect(user.fullName, equals('From JSON'));
      expect(user.role, equals(UserRole.admin));
      expect(user.isVerified, isTrue);
    });

    test('equality works correctly', () {
      const user1 = UserModel(id: 'same-id', email: 'same@email.com');
      const user2 = UserModel(id: 'same-id', email: 'same@email.com');
      const user3 = UserModel(id: 'diff-id', email: 'same@email.com');

      expect(user1, equals(user2));
      expect(user1, isNot(equals(user3)));
    });

    test('copyWith works correctly', () {
      const original = UserModel(
        id: 'original',
        email: 'original@example.com',
        fullName: 'Original',
      );

      final updated = original.copyWith(fullName: 'Updated');

      expect(updated.id, equals('original'));
      expect(updated.email, equals('original@example.com'));
      expect(updated.fullName, equals('Updated'));
    });
  });

  group('UserRole', () {
    test('patient role JSON value', () {
      expect(UserRole.patient.name, equals('patient'));
    });

    test('admin role JSON value', () {
      expect(UserRole.admin.name, equals('admin'));
    });
  });

  group('AuthState', () {
    test('initial state', () {
      const state = AuthState.initial();
      expect(state, isA<AuthStateInitial>());
    });

    test('loading state', () {
      const state = AuthState.loading();
      expect(state, isA<AuthStateLoading>());
    });

    test('authenticated state contains user and token', () {
      const user = UserModel(id: 'auth-user', email: 'auth@example.com');
      const state = AuthState.authenticated(
        user: user,
        accessToken: 'valid.token.here',
      );

      expect(state, isA<AuthStateAuthenticated>());
      if (state case AuthStateAuthenticated(:final user, :final accessToken)) {
        expect(user.id, equals('auth-user'));
        expect(accessToken, equals('valid.token.here'));
      }
    });

    test('unauthenticated state with message', () {
      const state = AuthState.unauthenticated(message: 'Session expired');

      expect(state, isA<AuthStateUnauthenticated>());
      if (state case AuthStateUnauthenticated(:final message)) {
        expect(message, equals('Session expired'));
      }
    });

    test('unauthenticated state without message', () {
      const state = AuthState.unauthenticated();

      expect(state, isA<AuthStateUnauthenticated>());
      if (state case AuthStateUnauthenticated(:final message)) {
        expect(message, isNull);
      }
    });

    test('error state contains message', () {
      const state = AuthState.error(message: 'Network error');

      expect(state, isA<AuthStateError>());
      if (state case AuthStateError(:final message)) {
        expect(message, equals('Network error'));
      }
    });
  });

  group('AuthTokens', () {
    test('creates with access token', () {
      const tokens = AuthTokens(accessToken: 'access.token.value');

      expect(tokens.accessToken, equals('access.token.value'));
    });

    test('serializes to JSON correctly', () {
      const tokens = AuthTokens(accessToken: 'my.access.token');

      final json = tokens.toJson();

      expect(json['access_token'], equals('my.access.token'));
    });

    test('deserializes from JSON correctly', () {
      final json = {'access_token': 'from.json.token'};

      final tokens = AuthTokens.fromJson(json);

      expect(tokens.accessToken, equals('from.json.token'));
    });

    test('equality works correctly', () {
      const tokens1 = AuthTokens(accessToken: 'same.token');
      const tokens2 = AuthTokens(accessToken: 'same.token');
      const tokens3 = AuthTokens(accessToken: 'different.token');

      expect(tokens1, equals(tokens2));
      expect(tokens1, isNot(equals(tokens3)));
    });
  });
}
