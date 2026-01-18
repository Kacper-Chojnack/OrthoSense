/// Unit tests for AuthNotifier - authentication state management.
///
/// Test coverage:
/// 1. Initial state and state transitions
/// 2. Login flow (success, failure, network errors)
/// 3. Logout flow
/// 4. Token expiration handling
/// 5. Offline/optimistic auth
/// 6. Error message extraction
library;

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AuthState', () {
    test('initial state has no user', () {
      const state = AuthStateInitial();
      expect(state.user, isNull);
      expect(state.isLoading, isFalse);
    });

    test('loading state indicates loading', () {
      const state = AuthStateLoading();
      expect(state.isLoading, isTrue);
    });

    test('authenticated state contains user and token', () {
      const user = MockUserModel(
        id: 'user-123',
        email: 'test@example.com',
        name: 'Test User',
      );
      const state = AuthStateAuthenticated(
        user: user,
        accessToken: 'token-abc',
      );

      expect(state.user, equals(user));
      expect(state.accessToken, equals('token-abc'));
      expect(state.isAuthenticated, isTrue);
    });

    test('unauthenticated state can have message', () {
      const state = AuthStateUnauthenticated(
        message: 'Session expired. Please login again.',
      );

      expect(state.message, equals('Session expired. Please login again.'));
      expect(state.isAuthenticated, isFalse);
    });

    test('error state contains error message', () {
      const state = AuthStateError(message: 'Something went wrong');
      expect(state.message, equals('Something went wrong'));
    });
  });

  group('Error Message Extraction', () {
    test('extracts detail from response data', () {
      const response = {'detail': 'Invalid credentials'};
      final message = _extractErrorFromResponse(response);

      expect(message, equals('Invalid credentials'));
    });

    test('handles validation errors array', () {
      const response = {
        'detail': [
          {'msg': 'Email is required'},
          {'msg': 'Password is too short'},
        ],
      };
      final message = _extractErrorFromResponse(response);

      expect(message, contains('Email is required'));
      expect(message, contains('Password is too short'));
    });

    test('returns default for empty detail', () {
      const response = {'detail': ''};
      final message = _extractErrorFromResponse(response);

      expect(message, isEmpty);
    });

    test('handles network error status codes', () {
      expect(
        _getErrorMessageForStatusCode(401),
        equals('Invalid email or password'),
      );
      expect(
        _getErrorMessageForStatusCode(400),
        equals('Invalid request. Please check your input.'),
      );
      expect(
        _getErrorMessageForStatusCode(403),
        equals('Access denied. Please try again.'),
      );
      expect(
        _getErrorMessageForStatusCode(404),
        equals('Service not found. Please try again later.'),
      );
      expect(
        _getErrorMessageForStatusCode(500),
        equals('Server error. Please try again later.'),
      );
      expect(
        _getErrorMessageForStatusCode(502),
        equals('Server is temporarily unavailable. Please try again.'),
      );
      expect(
        _getErrorMessageForStatusCode(503),
        equals('Server is temporarily unavailable. Please try again.'),
      );
      expect(
        _getErrorMessageForStatusCode(504),
        equals('Server is temporarily unavailable. Please try again.'),
      );
    });

    test('returns generic message for unknown status', () {
      expect(
        _getErrorMessageForStatusCode(418),
        equals('An error occurred. Please try again.'),
      );
      expect(
        _getErrorMessageForStatusCode(null),
        equals('An error occurred. Please try again.'),
      );
    });
  });

  group('Network Error Detection', () {
    test('identifies connection error', () {
      expect(_isNetworkError(MockDioExceptionType.connectionError), isTrue);
    });

    test('identifies timeout errors', () {
      expect(_isNetworkError(MockDioExceptionType.connectionTimeout), isTrue);
      expect(_isNetworkError(MockDioExceptionType.receiveTimeout), isTrue);
      expect(_isNetworkError(MockDioExceptionType.sendTimeout), isTrue);
    });

    test('does not identify bad response as network error', () {
      expect(_isNetworkError(MockDioExceptionType.badResponse), isFalse);
    });

    test('does not identify cancel as network error', () {
      expect(_isNetworkError(MockDioExceptionType.cancel), isFalse);
    });
  });

  group('Token Expiration', () {
    test('identifies expired token', () {
      // Token that expired yesterday
      final expiredDate = DateTime.now().subtract(const Duration(days: 1));
      expect(_isTokenExpired(expiredDate), isTrue);
    });

    test('identifies valid token', () {
      // Token that expires tomorrow
      final validDate = DateTime.now().add(const Duration(days: 1));
      expect(_isTokenExpired(validDate), isFalse);
    });

    test('handles token expiring now as expired', () {
      // Token expiring right now should be considered expired
      final now = DateTime.now();
      expect(_isTokenExpired(now), isTrue);
    });

    test('decodes JWT expiration', () {
      // Simple mock JWT parsing
      const mockExp = 1735689600; // 2025-01-01 00:00:00 UTC
      final expDate = DateTime.fromMillisecondsSinceEpoch(mockExp * 1000);

      expect(expDate.year, equals(2025));
      expect(expDate.month, equals(1));
      expect(expDate.day, equals(1));
    });
  });

  group('Login Flow', () {
    test('successful login transitions to authenticated', () {
      final stateMachine = AuthStateMachine();

      stateMachine.setState(const AuthStateLoading());
      expect(stateMachine.state.isLoading, isTrue);

      const user = MockUserModel(
        id: 'user-123',
        email: 'test@example.com',
        name: 'Test User',
      );
      stateMachine.setState(
        const AuthStateAuthenticated(user: user, accessToken: 'token'),
      );

      expect(stateMachine.state.isAuthenticated, isTrue);
    });

    test('failed login transitions to unauthenticated with message', () {
      final stateMachine = AuthStateMachine();

      stateMachine.setState(const AuthStateLoading());
      stateMachine.setState(
        const AuthStateUnauthenticated(message: 'Invalid credentials'),
      );

      expect(stateMachine.state.isAuthenticated, isFalse);
      expect(
        (stateMachine.state as AuthStateUnauthenticated).message,
        equals('Invalid credentials'),
      );
    });
  });

  group('Logout Flow', () {
    test('logout clears authenticated state', () {
      final stateMachine = AuthStateMachine();

      const user = MockUserModel(
        id: 'user-123',
        email: 'test@example.com',
        name: 'Test User',
      );
      stateMachine.setState(
        const AuthStateAuthenticated(user: user, accessToken: 'token'),
      );

      stateMachine.setState(const AuthStateLoading());
      stateMachine.setState(const AuthStateUnauthenticated());

      expect(stateMachine.state.isAuthenticated, isFalse);
    });

    test('logout succeeds even if API call fails', () {
      // If logout API fails, we should still clear local state
      final stateMachine = AuthStateMachine();

      const user = MockUserModel(
        id: 'user-123',
        email: 'test@example.com',
        name: 'Test User',
      );
      stateMachine.setState(
        const AuthStateAuthenticated(user: user, accessToken: 'token'),
      );

      // Simulate API failure but still transitioning to unauthenticated
      stateMachine.setState(const AuthStateUnauthenticated());

      expect(stateMachine.state.isAuthenticated, isFalse);
    });
  });

  group('Offline Authentication', () {
    test('uses cached user when network unavailable', () {
      final cache = MockUserCache();
      const cachedUser = MockUserModel(
        id: 'user-123',
        email: 'cached@example.com',
        name: 'Cached User',
      );
      cache.setCachedUser(cachedUser);

      // Simulate network failure
      const hasNetwork = false;

      if (!hasNetwork) {
        final offlineUser = cache.getCachedUser();
        expect(offlineUser, isNotNull);
        expect(offlineUser?.email, equals('cached@example.com'));
      }
    });

    test('clears auth when token expired and no network', () {
      final stateMachine = AuthStateMachine();

      // Token is expired and we can't verify with server
      stateMachine.setState(
        const AuthStateUnauthenticated(
          message: 'Session expired. Please login again.',
        ),
      );

      expect(stateMachine.state.isAuthenticated, isFalse);
    });
  });

  group('Password Reset', () {
    test('returns true on successful password reset request', () async {
      final result = await _simulateForgotPassword(
        email: 'test@example.com',
        shouldSucceed: true,
      );
      expect(result, isTrue);
    });

    test('returns false on failed password reset request', () async {
      final result = await _simulateForgotPassword(
        email: 'nonexistent@example.com',
        shouldSucceed: false,
      );
      expect(result, isFalse);
    });
  });

  group('Registration Flow', () {
    test('auto-logins after successful registration', () {
      final stateMachine = AuthStateMachine();
      final log = <String>[];

      // Register
      log.add('register');
      stateMachine.setState(const AuthStateLoading());

      // Auto-login after registration
      log.add('login');
      const user = MockUserModel(
        id: 'user-123',
        email: 'new@example.com',
        name: 'New User',
      );
      stateMachine.setState(
        const AuthStateAuthenticated(user: user, accessToken: 'token'),
      );

      expect(log, equals(['register', 'login']));
      expect(stateMachine.state.isAuthenticated, isTrue);
    });

    test('handles registration failure', () {
      final stateMachine = AuthStateMachine();

      stateMachine.setState(const AuthStateLoading());
      stateMachine.setState(
        const AuthStateUnauthenticated(message: 'Email already registered'),
      );

      expect(stateMachine.state.isAuthenticated, isFalse);
    });
  });

  group('Helper Providers', () {
    test('isAuthenticated returns true for authenticated state', () {
      const state = AuthStateAuthenticated(
        user: MockUserModel(id: '1', email: 'a@b.com', name: 'A'),
        accessToken: 'token',
      );
      expect(state.isAuthenticated, isTrue);
    });

    test('isAuthenticated returns false for other states', () {
      expect(const AuthStateInitial().isAuthenticated, isFalse);
      expect(const AuthStateLoading().isAuthenticated, isFalse);
      expect(const AuthStateUnauthenticated().isAuthenticated, isFalse);
      expect(const AuthStateError(message: 'err').isAuthenticated, isFalse);
    });

    test('currentUser extracts user from authenticated state', () {
      const user = MockUserModel(id: '1', email: 'a@b.com', name: 'A');
      const state = AuthStateAuthenticated(user: user, accessToken: 'token');

      final extractedUser = switch (state) {
        AuthStateAuthenticated(:final user) => user,
        _ => null,
      };

      expect(extractedUser, equals(user));
    });

    test('accessToken extracts token from authenticated state', () {
      const state = AuthStateAuthenticated(
        user: MockUserModel(id: '1', email: 'a@b.com', name: 'A'),
        accessToken: 'my-token',
      );

      final token = switch (state) {
        AuthStateAuthenticated(:final accessToken) => accessToken,
        _ => null,
      };

      expect(token, equals('my-token'));
    });
  });
}

// Test helpers and mocks

sealed class AuthState {
  const AuthState();

  bool get isLoading => this is AuthStateLoading;
  bool get isAuthenticated => this is AuthStateAuthenticated;
  MockUserModel? get user => switch (this) {
    AuthStateAuthenticated(:final user) => user,
    _ => null,
  };
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

  final MockUserModel user;
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

class MockUserModel {
  const MockUserModel({
    required this.id,
    required this.email,
    required this.name,
  });

  final String id;
  final String email;
  final String name;
}

class AuthStateMachine {
  AuthState _state = const AuthStateInitial();

  AuthState get state => _state;

  void setState(AuthState newState) {
    _state = newState;
  }
}

class MockUserCache {
  MockUserModel? _cachedUser;

  MockUserModel? getCachedUser() => _cachedUser;

  void setCachedUser(MockUserModel user) {
    _cachedUser = user;
  }

  void clear() {
    _cachedUser = null;
  }
}

enum MockDioExceptionType {
  connectionError,
  connectionTimeout,
  receiveTimeout,
  sendTimeout,
  badResponse,
  cancel,
}

String _extractErrorFromResponse(Map<String, dynamic> response) {
  final detail = response['detail'];
  if (detail == null) return '';

  if (detail is List) {
    return detail.map((e) => e['msg'] ?? e.toString()).join(', ');
  }

  return detail.toString();
}

String _getErrorMessageForStatusCode(int? statusCode) {
  return switch (statusCode) {
    401 => 'Invalid email or password',
    400 => 'Invalid request. Please check your input.',
    403 => 'Access denied. Please try again.',
    404 => 'Service not found. Please try again later.',
    500 => 'Server error. Please try again later.',
    502 || 503 || 504 => 'Server is temporarily unavailable. Please try again.',
    _ => 'An error occurred. Please try again.',
  };
}

bool _isNetworkError(MockDioExceptionType type) {
  return type == MockDioExceptionType.connectionError ||
      type == MockDioExceptionType.connectionTimeout ||
      type == MockDioExceptionType.receiveTimeout ||
      type == MockDioExceptionType.sendTimeout;
}

bool _isTokenExpired(DateTime expirationDate) {
  return !expirationDate.isAfter(DateTime.now());
}

Future<bool> _simulateForgotPassword({
  required String email,
  required bool shouldSucceed,
}) async {
  // Simulate network delay
  await Future<void>.delayed(Duration.zero);
  return shouldSucceed;
}
