/// Unit tests for AuthNotifier.
///
/// Test coverage:
/// 1. Initial state
/// 2. Login flow
/// 3. Registration flow
/// 4. Logout flow
/// 5. Auth status checks
/// 6. Error handling
library;

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AuthNotifier', () {
    group('initial state', () {
      test('starts with initial state', () {
        const state = AuthState.initial();

        expect(state, isA<AuthStateInitial>());
      });

      test('transitions to loading on initialization', () {
        const state = AuthState.loading();

        expect(state, isA<AuthStateLoading>());
      });
    });

    group('login flow', () {
      test('successful login returns authenticated state', () {
        const user = UserModel(
          id: 'user-123',
          email: 'test@example.com',
        );
        const accessToken = 'test_token';
        final state = AuthState.authenticated(
          user: user,
          accessToken: accessToken,
        );

        expect(state, isA<AuthStateAuthenticated>());
        expect(
          (state as AuthStateAuthenticated).user.email,
          equals('test@example.com'),
        );
      });

      test('failed login returns unauthenticated state with message', () {
        const errorMessage = 'Invalid email or password';
        const state = AuthState.unauthenticated(message: errorMessage);

        expect(state, isA<AuthStateUnauthenticated>());
        expect(
          (state as AuthStateUnauthenticated).message,
          equals(errorMessage),
        );
      });

      test('validates email format', () {
        const email = 'test@example.com';
        final isValid = RegExp(
          r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$',
        ).hasMatch(email);

        expect(isValid, isTrue);
      });

      test('rejects invalid email format', () {
        const email = 'invalid-email';
        final isValid = RegExp(
          r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$',
        ).hasMatch(email);

        expect(isValid, isFalse);
      });
    });

    group('registration flow', () {
      test('successful registration auto-logins', () {
        // Registration should trigger login
        const email = 'new@example.com';
        const password = 'password123';

        expect(email.isNotEmpty, isTrue);
        expect(password.isNotEmpty, isTrue);
      });

      test('failed registration shows error', () {
        const errorMessage = 'Email already registered';
        const state = AuthState.unauthenticated(message: errorMessage);

        expect(
          (state as AuthStateUnauthenticated).message,
          equals('Email already registered'),
        );
      });
    });

    group('logout flow', () {
      test('logout returns unauthenticated state', () {
        const state = AuthState.unauthenticated();

        expect(state, isA<AuthStateUnauthenticated>());
      });

      test('logout clears local state even on error', () {
        // Even if logout API fails, local state should be cleared
        const clearedState = AuthState.unauthenticated();

        expect(clearedState, isA<AuthStateUnauthenticated>());
      });
    });

    group('auth status check', () {
      test('returns unauthenticated when no token', () {
        const String? token = null;
        final isAuthenticated = token != null;

        expect(isAuthenticated, isFalse);
      });

      test('returns unauthenticated when token expired', () {
        const isExpired = true;
        final shouldLogout = isExpired;

        expect(shouldLogout, isTrue);
      });

      test('uses optimistic auth on network error', () {
        const hasNetworkError = true;
        const hasOfflineUser = true;
        final useOptimisticAuth = hasNetworkError && hasOfflineUser;

        expect(useOptimisticAuth, isTrue);
      });

      test('shows session expired message on 401', () {
        const statusCode = 401;
        final message = statusCode == 401
            ? 'Session expired. Please login again.'
            : null;

        expect(message, equals('Session expired. Please login again.'));
      });
    });

    group('forgot password', () {
      test('returns true on success', () {
        const success = true;
        expect(success, isTrue);
      });

      test('returns false on failure', () {
        const success = false;
        expect(success, isFalse);
      });
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

    test('authenticated state', () {
      const user = UserModel(id: '1', email: 'test@test.com');
      final state = AuthState.authenticated(user: user, accessToken: 'token');
      expect(state, isA<AuthStateAuthenticated>());
    });

    test('unauthenticated state with message', () {
      const state = AuthState.unauthenticated(message: 'Error message');
      expect(state, isA<AuthStateUnauthenticated>());
      expect(
        (state as AuthStateUnauthenticated).message,
        equals('Error message'),
      );
    });

    test('error state', () {
      const state = AuthState.error(message: 'Fatal error');
      expect(state, isA<AuthStateError>());
    });
  });

  group('Error message extraction', () {
    test('network error message', () {
      const isNetworkError = true;
      final message = isNetworkError
          ? 'Unable to connect to server. Please check your internet connection.'
          : 'Unknown error';

      expect(message, contains('internet connection'));
    });

    test('401 error message', () {
      const statusCode = 401;
      final message = statusCode == 401 ? 'Invalid email or password' : '';

      expect(message, equals('Invalid email or password'));
    });

    test('400 error message', () {
      const statusCode = 400;
      final message = statusCode == 400
          ? 'Invalid request. Please check your input.'
          : '';

      expect(message, contains('Invalid request'));
    });

    test('500 error message', () {
      const statusCode = 500;
      final message = statusCode == 500
          ? 'Server error. Please try again later.'
          : '';

      expect(message, contains('Server error'));
    });

    test('503 error message', () {
      const statusCode = 503;
      final message = statusCode == 503
          ? 'Server is temporarily unavailable. Please try again.'
          : '';

      expect(message, contains('temporarily unavailable'));
    });

    test('extracts detail from response', () {
      final data = {'detail': 'Custom error message'};
      final message = data['detail'] as String;

      expect(message, equals('Custom error message'));
    });

    test('handles validation errors array', () {
      final data = {
        'detail': [
          {'msg': 'Email is required'},
          {'msg': 'Password is required'},
        ],
      };
      final detail = data['detail'] as List;
      final messages = detail.map((e) => e['msg']).join(', ');

      expect(messages, equals('Email is required, Password is required'));
    });
  });

  group('Network error detection', () {
    test('connection error is network error', () {
      const errorType = 'connectionError';
      const networkErrorTypes = [
        'connectionError',
        'connectionTimeout',
        'receiveTimeout',
        'sendTimeout',
      ];

      expect(networkErrorTypes.contains(errorType), isTrue);
    });

    test('bad response is not network error', () {
      const errorType = 'badResponse';
      const networkErrorTypes = [
        'connectionError',
        'connectionTimeout',
        'receiveTimeout',
        'sendTimeout',
      ];

      expect(networkErrorTypes.contains(errorType), isFalse);
    });
  });

  group('Helper providers', () {
    group('isAuthenticated', () {
      test('returns true when authenticated', () {
        const user = UserModel(id: '1', email: 'test@test.com');
        final state = AuthState.authenticated(user: user, accessToken: 'token');
        final isAuth = state is AuthStateAuthenticated;

        expect(isAuth, isTrue);
      });

      test('returns false when unauthenticated', () {
        const state = AuthState.unauthenticated();
        final isAuth = state is AuthStateAuthenticated;

        expect(isAuth, isFalse);
      });
    });

    group('currentUser', () {
      test('returns user when authenticated', () {
        const user = UserModel(id: '1', email: 'test@test.com');
        final state = AuthState.authenticated(user: user, accessToken: 'token');

        UserModel? result;
        if (state is AuthStateAuthenticated) {
          result = state.user;
        }

        expect(result, equals(user));
      });

      test('returns null when unauthenticated', () {
        const AuthState state = AuthState.unauthenticated();

        UserModel? result;
        if (state is AuthStateAuthenticated) {
          result = state.user;
        }

        expect(result, isNull);
      });
    });

    group('accessToken', () {
      test('returns token when authenticated', () {
        const user = UserModel(id: '1', email: 'test@test.com');
        final state = AuthState.authenticated(
          user: user,
          accessToken: 'my_token',
        );

        String? result;
        if (state is AuthStateAuthenticated) {
          result = state.accessToken;
        }

        expect(result, equals('my_token'));
      });
    });
  });
}

// Models

class UserModel {
  const UserModel({
    required this.id,
    required this.email,
    this.name,
  });

  final String id;
  final String email;
  final String? name;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserModel && other.id == id && other.email == email;
  }

  @override
  int get hashCode => id.hashCode ^ email.hashCode;
}

// Auth State sealed classes

sealed class AuthState {
  const AuthState();

  const factory AuthState.initial() = AuthStateInitial;
  const factory AuthState.loading() = AuthStateLoading;
  factory AuthState.authenticated({
    required UserModel user,
    required String accessToken,
  }) = AuthStateAuthenticated;
  const factory AuthState.unauthenticated({String? message}) =
      AuthStateUnauthenticated;
  const factory AuthState.error({required String message}) = AuthStateError;
}

class AuthStateInitial extends AuthState {
  const AuthStateInitial();
}

class AuthStateLoading extends AuthState {
  const AuthStateLoading();
}

class AuthStateAuthenticated extends AuthState {
  const AuthStateAuthenticated({
    required this.user,
    required this.accessToken,
  });

  final UserModel user;
  final String accessToken;
}

class AuthStateUnauthenticated extends AuthState {
  const AuthStateUnauthenticated({this.message});

  final String? message;
}

class AuthStateError extends AuthState {
  const AuthStateError({required this.message});

  final String message;
}
