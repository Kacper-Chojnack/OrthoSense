import 'package:flutter_test/flutter_test.dart';
import 'package:orthosense/features/auth/domain/models/models.dart';

void main() {
  group('UserModel', () {
    test('fromJson parses all fields correctly', () {
      final json = {
        'id': '123e4567-e89b-12d3-a456-426614174000',
        'email': 'test@example.com',
        'full_name': 'Test User',
        'role': 'patient',
        'is_active': true,
        'is_verified': true,
        'created_at': '2025-01-01T00:00:00Z',
      };

      final user = UserModel.fromJson(json);

      expect(user.id, '123e4567-e89b-12d3-a456-426614174000');
      expect(user.email, 'test@example.com');
      expect(user.fullName, 'Test User');
      expect(user.role, UserRole.patient);
      expect(user.isActive, true);
      expect(user.isVerified, true);
      expect(user.createdAt, isNotNull);
    });

    test('fromJson uses defaults for missing optional fields', () {
      final json = {
        'id': '123e4567-e89b-12d3-a456-426614174000',
        'email': 'test@example.com',
      };

      final user = UserModel.fromJson(json);

      expect(user.id, '123e4567-e89b-12d3-a456-426614174000');
      expect(user.email, 'test@example.com');
      expect(user.fullName, '');
      expect(user.role, UserRole.patient);
      expect(user.isActive, true);
      expect(user.isVerified, false);
      expect(user.createdAt, isNull);
    });

    test('fromJson parses admin role', () {
      final json = {
        'id': '123',
        'email': 'admin@example.com',
        'role': 'admin',
      };

      final user = UserModel.fromJson(json);

      expect(user.role, UserRole.admin);
    });

    test('toJson serializes correctly', () {
      const user = UserModel(
        id: '123',
        email: 'test@example.com',
        fullName: 'Test User',
        role: UserRole.patient,
        isActive: true,
        isVerified: true,
      );

      final json = user.toJson();

      expect(json['id'], '123');
      expect(json['email'], 'test@example.com');
      expect(json['full_name'], 'Test User');
      expect(json['role'], 'patient');
      expect(json['is_active'], true);
      expect(json['is_verified'], true);
    });

    test('equality works correctly', () {
      const user1 = UserModel(
        id: '123',
        email: 'test@example.com',
      );
      const user2 = UserModel(
        id: '123',
        email: 'test@example.com',
      );
      const user3 = UserModel(
        id: '456',
        email: 'other@example.com',
      );

      expect(user1, equals(user2));
      expect(user1, isNot(equals(user3)));
    });

    test('copyWith creates modified copy', () {
      const user = UserModel(
        id: '123',
        email: 'test@example.com',
        fullName: 'Original Name',
      );

      final modified = user.copyWith(fullName: 'New Name');

      expect(modified.id, '123');
      expect(modified.email, 'test@example.com');
      expect(modified.fullName, 'New Name');
    });
  });

  group('AuthTokens', () {
    test('fromJson parses access token', () {
      final json = {
        'access_token': 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...',
        'token_type': 'bearer',
      };

      final tokens = AuthTokens.fromJson(json);

      expect(tokens.accessToken, startsWith('eyJ'));
      expect(tokens.tokenType, 'bearer');
    });

    test('toJson serializes correctly', () {
      const tokens = AuthTokens(
        accessToken: 'test_token',
        tokenType: 'bearer',
      );

      final json = tokens.toJson();

      expect(json['access_token'], 'test_token');
      expect(json['token_type'], 'bearer');
    });
  });

  group('AuthState', () {
    test('initial state is AuthStateInitial', () {
      const state = AuthState.initial();

      expect(state, isA<AuthStateInitial>());
    });

    test('loading state is AuthStateLoading', () {
      const state = AuthState.loading();

      expect(state, isA<AuthStateLoading>());
    });

    test('authenticated state contains user and token', () {
      const user = UserModel(id: '123', email: 'test@example.com');
      const state = AuthState.authenticated(
        user: user,
        accessToken: 'token123',
      );

      expect(state, isA<AuthStateAuthenticated>());
      final authState = state as AuthStateAuthenticated;
      expect(authState.user.id, '123');
      expect(authState.accessToken, 'token123');
    });

    test('unauthenticated state can have optional message', () {
      const state1 = AuthState.unauthenticated();
      const state2 = AuthState.unauthenticated(message: 'Session expired');

      expect(state1, isA<AuthStateUnauthenticated>());
      expect((state1 as AuthStateUnauthenticated).message, isNull);
      expect((state2 as AuthStateUnauthenticated).message, 'Session expired');
    });

    test('error state contains message', () {
      const state = AuthState.error(message: 'Network error');

      expect(state, isA<AuthStateError>());
      expect((state as AuthStateError).message, 'Network error');
    });

    test('pattern matching works on sealed class', () {
      const state = AuthState.authenticated(
        user: UserModel(id: '123', email: 'test@example.com'),
        accessToken: 'token',
      );

      final result = switch (state) {
        AuthStateInitial() => 'initial',
        AuthStateLoading() => 'loading',
        AuthStateAuthenticated() => 'authenticated',
        AuthStateUnauthenticated() => 'unauthenticated',
        AuthStateError() => 'error',
      };

      expect(result, 'authenticated');
    });
  });
}
