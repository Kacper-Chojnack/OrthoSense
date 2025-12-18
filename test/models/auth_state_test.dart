import 'package:flutter_test/flutter_test.dart';
import 'package:orthosense/features/auth/domain/models/auth_state.dart';
import 'package:orthosense/features/auth/domain/models/user_model.dart';

void main() {
  group('AuthState', () {
    group('initial', () {
      test('creates initial state', () {
        const state = AuthState.initial();

        expect(state, isA<AuthStateInitial>());
      });

      test('pattern matches correctly', () {
        const state = AuthState.initial();

        final result = switch (state) {
          AuthStateInitial() => 'initial',
          AuthStateLoading() => 'loading',
          AuthStateAuthenticated() => 'authenticated',
          AuthStateUnauthenticated() => 'unauthenticated',
          AuthStateError() => 'error',
        };

        expect(result, equals('initial'));
      });
    });

    group('loading', () {
      test('creates loading state', () {
        const state = AuthState.loading();

        expect(state, isA<AuthStateLoading>());
      });
    });

    group('authenticated', () {
      test('creates authenticated state with user and token', () {
        final user = UserModel(
          id: 'user-123',
          email: 'test@example.com',
        );

        final state = AuthState.authenticated(
          user: user,
          accessToken: 'jwt-token',
        );

        expect(state, isA<AuthStateAuthenticated>());
      });

      test('provides access to user and token', () {
        final user = UserModel(
          id: 'user-123',
          email: 'test@example.com',
        );

        final state = AuthState.authenticated(
          user: user,
          accessToken: 'jwt-token',
        );

        final authenticated = state as AuthStateAuthenticated;
        expect(authenticated.user.email, equals('test@example.com'));
        expect(authenticated.accessToken, equals('jwt-token'));
      });

      test('map extracts user correctly', () {
        final user = UserModel(
          id: 'user-123',
          email: 'test@example.com',
        );

        final state = AuthState.authenticated(
          user: user,
          accessToken: 'jwt-token',
        );

        final email = state.mapOrNull(
          authenticated: (s) => s.user.email,
        );

        expect(email, equals('test@example.com'));
      });
    });

    group('unauthenticated', () {
      test('creates unauthenticated state without message', () {
        const state = AuthState.unauthenticated();

        expect(state, isA<AuthStateUnauthenticated>());
        expect((state as AuthStateUnauthenticated).message, isNull);
      });

      test('creates unauthenticated state with message', () {
        const state = AuthState.unauthenticated(
          message: 'Session expired. Please login again.',
        );

        expect(state, isA<AuthStateUnauthenticated>());
        expect(
          (state as AuthStateUnauthenticated).message,
          equals('Session expired. Please login again.'),
        );
      });
    });

    group('error', () {
      test('creates error state with message', () {
        const state = AuthState.error(message: 'Network error occurred');

        expect(state, isA<AuthStateError>());
        expect(
          (state as AuthStateError).message,
          equals('Network error occurred'),
        );
      });
    });

    group('maybeWhen', () {
      test('executes correct callback for authenticated', () {
        final user = UserModel(
          id: 'user-123',
          email: 'test@example.com',
        );

        final state = AuthState.authenticated(
          user: user,
          accessToken: 'jwt-token',
        );

        final isAuthenticated = state.maybeWhen(
          authenticated: (_, __) => true,
          orElse: () => false,
        );

        expect(isAuthenticated, isTrue);
      });

      test('executes orElse for non-matching state', () {
        const state = AuthState.loading();

        final isAuthenticated = state.maybeWhen(
          authenticated: (_, __) => true,
          orElse: () => false,
        );

        expect(isAuthenticated, isFalse);
      });
    });

    group('when', () {
      test('handles all states', () {
        final states = [
          const AuthState.initial(),
          const AuthState.loading(),
          AuthState.authenticated(
            user: UserModel(id: '1', email: 'a@b.com'),
            accessToken: 'token',
          ),
          const AuthState.unauthenticated(),
          const AuthState.error(message: 'Error'),
        ];

        for (final state in states) {
          final result = state.when(
            initial: () => 'initial',
            loading: () => 'loading',
            authenticated: (_, __) => 'authenticated',
            unauthenticated: (_) => 'unauthenticated',
            error: (_) => 'error',
          );

          expect(result, isA<String>());
        }
      });
    });

    group('equality', () {
      test('initial states are equal', () {
        const state1 = AuthState.initial();
        const state2 = AuthState.initial();

        expect(state1, equals(state2));
      });

      test('loading states are equal', () {
        const state1 = AuthState.loading();
        const state2 = AuthState.loading();

        expect(state1, equals(state2));
      });

      test('authenticated states with same data are equal', () {
        final user = UserModel(id: 'user-1', email: 'test@example.com');

        final state1 = AuthState.authenticated(
          user: user,
          accessToken: 'token',
        );
        final state2 = AuthState.authenticated(
          user: user,
          accessToken: 'token',
        );

        expect(state1, equals(state2));
      });

      test('authenticated states with different tokens are not equal', () {
        final user = UserModel(id: 'user-1', email: 'test@example.com');

        final state1 = AuthState.authenticated(
          user: user,
          accessToken: 'token-1',
        );
        final state2 = AuthState.authenticated(
          user: user,
          accessToken: 'token-2',
        );

        expect(state1, isNot(equals(state2)));
      });
    });
  });
}
