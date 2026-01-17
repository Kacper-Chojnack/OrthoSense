/// Unit tests for auth domain models.
///
/// Test coverage:
/// 1. AuthTokens model
/// 2. UserModel model  
/// 3. UserRole enum
/// 4. AuthState sealed class
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:orthosense/features/auth/domain/models/models.dart';

void main() {
  group('AuthTokens', () {
    test('creates with required accessToken', () {
      const tokens = AuthTokens(accessToken: 'test-token-123');

      expect(tokens.accessToken, equals('test-token-123'));
    });

    test('tokenType defaults to bearer', () {
      const tokens = AuthTokens(accessToken: 'test');

      expect(tokens.tokenType, equals('bearer'));
    });

    test('accepts custom tokenType', () {
      const tokens = AuthTokens(
        accessToken: 'test',
        tokenType: 'custom',
      );

      expect(tokens.tokenType, equals('custom'));
    });

    test('fromJson parses access_token', () {
      final json = {
        'access_token': 'my-token',
        'token_type': 'bearer',
      };

      final tokens = AuthTokens.fromJson(json);

      expect(tokens.accessToken, equals('my-token'));
    });

    test('fromJson handles missing token_type', () {
      final json = {
        'access_token': 'my-token',
      };

      final tokens = AuthTokens.fromJson(json);

      expect(tokens.tokenType, equals('bearer'));
    });

    test('toJson produces correct keys', () {
      const tokens = AuthTokens(
        accessToken: 'test-token',
        tokenType: 'bearer',
      );

      final json = tokens.toJson();

      expect(json['access_token'], equals('test-token'));
      expect(json['token_type'], equals('bearer'));
    });

    test('roundtrip serialization', () {
      const original = AuthTokens(
        accessToken: 'roundtrip-token',
        tokenType: 'jwt',
      );

      final json = original.toJson();
      final restored = AuthTokens.fromJson(json);

      expect(restored.accessToken, equals(original.accessToken));
      expect(restored.tokenType, equals(original.tokenType));
    });

    test('equality works correctly', () {
      const tokens1 = AuthTokens(accessToken: 'same');
      const tokens2 = AuthTokens(accessToken: 'same');

      expect(tokens1, equals(tokens2));
    });

    test('different tokens are not equal', () {
      const tokens1 = AuthTokens(accessToken: 'one');
      const tokens2 = AuthTokens(accessToken: 'two');

      expect(tokens1, isNot(equals(tokens2)));
    });
  });

  group('UserRole', () {
    test('patient value exists', () {
      expect(UserRole.patient, isA<UserRole>());
    });

    test('admin value exists', () {
      expect(UserRole.admin, isA<UserRole>());
    });

    test('has exactly 2 values', () {
      expect(UserRole.values.length, equals(2));
    });

    test('values are distinct', () {
      expect(UserRole.patient, isNot(equals(UserRole.admin)));
    });
  });

  group('UserModel', () {
    test('creates with required fields', () {
      const user = UserModel(
        id: 'user-123',
        email: 'test@example.com',
      );

      expect(user.id, equals('user-123'));
      expect(user.email, equals('test@example.com'));
    });

    test('fullName defaults to empty string', () {
      const user = UserModel(
        id: 'user-123',
        email: 'test@example.com',
      );

      expect(user.fullName, equals(''));
    });

    test('role defaults to patient', () {
      const user = UserModel(
        id: 'user-123',
        email: 'test@example.com',
      );

      expect(user.role, equals(UserRole.patient));
    });

    test('isActive defaults to true', () {
      const user = UserModel(
        id: 'user-123',
        email: 'test@example.com',
      );

      expect(user.isActive, isTrue);
    });

    test('isVerified defaults to false', () {
      const user = UserModel(
        id: 'user-123',
        email: 'test@example.com',
      );

      expect(user.isVerified, isFalse);
    });

    test('createdAt is nullable', () {
      const user = UserModel(
        id: 'user-123',
        email: 'test@example.com',
      );

      expect(user.createdAt, isNull);
    });

    test('accepts all optional fields', () {
      final createdAt = DateTime(2024, 1, 15);

      final user = UserModel(
        id: 'user-456',
        email: 'admin@example.com',
        fullName: 'Admin User',
        role: UserRole.admin,
        isActive: true,
        isVerified: true,
        createdAt: createdAt,
      );

      expect(user.fullName, equals('Admin User'));
      expect(user.role, equals(UserRole.admin));
      expect(user.isActive, isTrue);
      expect(user.isVerified, isTrue);
      expect(user.createdAt, equals(createdAt));
    });

    test('fromJson parses all fields', () {
      final json = {
        'id': 'json-user',
        'email': 'json@example.com',
        'full_name': 'JSON User',
        'role': 'admin',
        'is_active': true,
        'is_verified': true,
        'created_at': '2024-01-15T10:30:00Z',
      };

      final user = UserModel.fromJson(json);

      expect(user.id, equals('json-user'));
      expect(user.email, equals('json@example.com'));
      expect(user.fullName, equals('JSON User'));
      expect(user.role, equals(UserRole.admin));
      expect(user.isActive, isTrue);
      expect(user.isVerified, isTrue);
    });

    test('fromJson handles patient role', () {
      final json = {
        'id': 'patient-user',
        'email': 'patient@example.com',
        'role': 'patient',
      };

      final user = UserModel.fromJson(json);

      expect(user.role, equals(UserRole.patient));
    });

    test('toJson produces correct keys', () {
      const user = UserModel(
        id: 'user-123',
        email: 'test@example.com',
        fullName: 'Test User',
        role: UserRole.admin,
        isActive: true,
        isVerified: false,
      );

      final json = user.toJson();

      expect(json['id'], equals('user-123'));
      expect(json['email'], equals('test@example.com'));
      expect(json['full_name'], equals('Test User'));
      expect(json['role'], equals('admin'));
      expect(json['is_active'], isTrue);
      expect(json['is_verified'], isFalse);
    });

    test('roundtrip serialization', () {
      const original = UserModel(
        id: 'roundtrip-user',
        email: 'roundtrip@example.com',
        fullName: 'Roundtrip User',
        role: UserRole.patient,
        isActive: true,
        isVerified: true,
      );

      final json = original.toJson();
      final restored = UserModel.fromJson(json);

      expect(restored.id, equals(original.id));
      expect(restored.email, equals(original.email));
      expect(restored.fullName, equals(original.fullName));
      expect(restored.role, equals(original.role));
      expect(restored.isActive, equals(original.isActive));
      expect(restored.isVerified, equals(original.isVerified));
    });

    test('equality works correctly', () {
      const user1 = UserModel(id: 'same', email: 'same@example.com');
      const user2 = UserModel(id: 'same', email: 'same@example.com');

      expect(user1, equals(user2));
    });

    test('copyWith creates modified copy', () {
      const original = UserModel(
        id: 'user-123',
        email: 'original@example.com',
        fullName: 'Original',
      );

      final modified = original.copyWith(
        fullName: 'Modified',
        isVerified: true,
      );

      expect(modified.id, equals(original.id));
      expect(modified.email, equals(original.email));
      expect(modified.fullName, equals('Modified'));
      expect(modified.isVerified, isTrue);
    });
  });

  group('AuthState', () {
    test('initial state can be created', () {
      const state = AuthState.initial();

      expect(state, isA<AuthStateInitial>());
    });

    test('loading state can be created', () {
      const state = AuthState.loading();

      expect(state, isA<AuthStateLoading>());
    });

    test('authenticated state requires user and token', () {
      const user = UserModel(id: 'user-1', email: 'test@example.com');
      const state = AuthState.authenticated(
        user: user,
        accessToken: 'token-123',
      );

      expect(state, isA<AuthStateAuthenticated>());

      final authenticated = state as AuthStateAuthenticated;
      expect(authenticated.user, equals(user));
      expect(authenticated.accessToken, equals('token-123'));
    });

    test('unauthenticated state has optional message', () {
      const state = AuthState.unauthenticated();

      expect(state, isA<AuthStateUnauthenticated>());

      final unauthenticated = state as AuthStateUnauthenticated;
      expect(unauthenticated.message, isNull);
    });

    test('unauthenticated state accepts message', () {
      const state = AuthState.unauthenticated(message: 'Session expired');

      final unauthenticated = state as AuthStateUnauthenticated;
      expect(unauthenticated.message, equals('Session expired'));
    });

    test('error state requires message', () {
      const state = AuthState.error(message: 'Network error');

      expect(state, isA<AuthStateError>());

      final error = state as AuthStateError;
      expect(error.message, equals('Network error'));
    });

    test('pattern matching works with map', () {
      const states = <AuthState>[
        AuthState.initial(),
        AuthState.loading(),
        AuthState.authenticated(
          user: UserModel(id: '1', email: 'test@example.com'),
          accessToken: 'token',
        ),
        AuthState.unauthenticated(),
        AuthState.error(message: 'Error'),
      ];

      for (final state in states) {
        final result = state.map(
          initial: (_) => 'initial',
          loading: (_) => 'loading',
          authenticated: (_) => 'authenticated',
          unauthenticated: (_) => 'unauthenticated',
          error: (_) => 'error',
        );

        expect(result, isA<String>());
      }
    });

    test('maybeMap returns null for unmatched state', () {
      const state = AuthState.initial();

      final result = state.maybeMap(
        authenticated: (_) => 'auth',
        orElse: () => 'other',
      );

      expect(result, equals('other'));
    });

    test('when pattern matching', () {
      const state = AuthState.authenticated(
        user: UserModel(id: '1', email: 'test@example.com'),
        accessToken: 'token',
      );

      final isAuthenticated = state.maybeMap(
        authenticated: (_) => true,
        orElse: () => false,
      );

      expect(isAuthenticated, isTrue);
    });
  });

  group('Auth model integration', () {
    test('successful login flow data types', () {
      // Simulate login response
      final tokensJson = {
        'access_token': 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...',
        'token_type': 'bearer',
      };
      final tokens = AuthTokens.fromJson(tokensJson);

      // Simulate user fetch
      final userJson = {
        'id': 'user-uuid-123',
        'email': 'user@orthosense.com',
        'full_name': 'Test Patient',
        'role': 'patient',
        'is_active': true,
        'is_verified': true,
      };
      final user = UserModel.fromJson(userJson);

      // Create authenticated state
      final state = AuthState.authenticated(
        user: user,
        accessToken: tokens.accessToken,
      );

      final authenticated = state as AuthStateAuthenticated;
      expect(authenticated.user.email, equals('user@orthosense.com'));
      expect(authenticated.accessToken, contains('eyJ'));
    });
  });
}
