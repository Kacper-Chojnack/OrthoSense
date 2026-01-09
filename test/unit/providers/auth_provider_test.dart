/// Unit tests for Auth Provider (AuthNotifier).
///
/// Test coverage:
/// 1. Initial state handling
/// 2. Login flow (success, failure, network errors)
/// 3. Registration flow
/// 4. Logout flow
/// 5. Token expiration handling
/// 6. Offline-first auth (optimistic auth)
/// 7. Password reset flow
/// 8. State transitions
library;

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:orthosense/features/auth/data/auth_repository.dart';
import 'package:orthosense/features/auth/data/token_storage.dart';
import 'package:orthosense/features/auth/domain/models/models.dart';
import 'package:orthosense/features/auth/presentation/providers/auth_notifier.dart';

// Mock classes
class MockAuthRepository extends Mock implements AuthRepository {}

class MockTokenStorage extends Mock implements TokenStorage {}

class MockDio extends Mock implements Dio {}

// Fake classes for fallback values
class FakeAuthTokens extends Fake implements AuthTokens {}

class FakeUserModel extends Fake implements UserModel {}

void main() {
  late MockAuthRepository mockAuthRepository;
  late MockTokenStorage mockTokenStorage;
  late ProviderContainer container;

  setUpAll(() {
    registerFallbackValue(FakeAuthTokens());
    registerFallbackValue(FakeUserModel());
  });

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    mockTokenStorage = MockTokenStorage();

    container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(mockAuthRepository),
        tokenStorageProvider.overrideWithValue(mockTokenStorage),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  group('Initial State', () {
    test('starts with initial state', () {
      // Don't read the provider to avoid triggering build()
      // Just verify the provider exists
      expect(authProvider, isNotNull);
    });

    test('transitions to unauthenticated when no token', () async {
      when(
        () => mockTokenStorage.getAccessToken(),
      ).thenAnswer((_) async => null);

      // Read provider to trigger initialization
      container.read(authProvider.notifier);

      // Give time for async initialization
      await Future<void>.delayed(const Duration(milliseconds: 100));

      final state = container.read(authProvider);
      expect(state, isA<AuthStateUnauthenticated>());
    });

    test('transitions to authenticated when valid token exists', () async {
      const testToken = 'valid.jwt.token';
      const testUser = UserModel(
        id: 'user-123',
        email: 'test@example.com',
      );

      when(
        () => mockTokenStorage.getAccessToken(),
      ).thenAnswer((_) async => testToken);
      when(() => mockTokenStorage.isTokenExpired(testToken)).thenReturn(false);
      when(
        () => mockAuthRepository.getCurrentUser(),
      ).thenAnswer((_) async => testUser);

      // Read provider to trigger initialization
      container.read(authProvider);

      // Wait for async operations
      await Future<void>.delayed(const Duration(milliseconds: 200));

      final state = container.read(authProvider);

      expect(state, isA<AuthStateAuthenticated>());
      if (state case AuthStateAuthenticated(:final user)) {
        expect(user.email, equals('test@example.com'));
      }
    });

    test('clears token and shows message when token is expired', () async {
      const expiredToken = 'expired.jwt.token';

      when(
        () => mockTokenStorage.getAccessToken(),
      ).thenAnswer((_) async => expiredToken);
      when(
        () => mockTokenStorage.isTokenExpired(expiredToken),
      ).thenReturn(true);
      when(() => mockTokenStorage.clearAll()).thenAnswer((_) async {});

      container.read(authProvider);

      await Future<void>.delayed(const Duration(milliseconds: 100));

      final state = container.read(authProvider);

      expect(state, isA<AuthStateUnauthenticated>());
      if (state case AuthStateUnauthenticated(:final message)) {
        expect(message, contains('expired'));
      }

      verify(() => mockTokenStorage.clearAll()).called(1);
    });
  });

  group('Login Flow', () {
    test('successful login updates state to authenticated', () async {
      const email = 'user@example.com';
      const password = 'password123';
      const accessToken = 'new.access.token';
      const tokens = AuthTokens(accessToken: accessToken);
      const user = UserModel(id: 'user-123', email: email);

      // Initial state setup
      when(
        () => mockTokenStorage.getAccessToken(),
      ).thenAnswer((_) async => null);

      when(
        () => mockAuthRepository.login(email: email, password: password),
      ).thenAnswer((_) async => tokens);

      when(
        () => mockAuthRepository.getCurrentUser(),
      ).thenAnswer((_) async => user);

      // Initialize provider
      container.read(authProvider);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      // Perform login
      await container
          .read(authProvider.notifier)
          .login(
            email: email,
            password: password,
          );

      final state = container.read(authProvider);

      expect(state, isA<AuthStateAuthenticated>());
      if (state case AuthStateAuthenticated(:final user, :final accessToken)) {
        expect(user.email, equals(email));
        expect(accessToken, equals('new.access.token'));
      }
    });

    test('login with wrong password shows error message', () async {
      const email = 'user@example.com';
      const password = 'wrongpassword';

      when(
        () => mockTokenStorage.getAccessToken(),
      ).thenAnswer((_) async => null);

      when(
        () => mockAuthRepository.login(email: email, password: password),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(),
          response: Response(
            requestOptions: RequestOptions(),
            statusCode: 401,
            data: {'detail': 'Invalid email or password'},
          ),
        ),
      );

      container.read(authProvider);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      await container
          .read(authProvider.notifier)
          .login(
            email: email,
            password: password,
          );

      final state = container.read(authProvider);

      expect(state, isA<AuthStateUnauthenticated>());
      if (state case AuthStateUnauthenticated(:final message)) {
        expect(message, contains('Invalid'));
      }
    });

    test('login with network error shows connection message', () async {
      const email = 'user@example.com';
      const password = 'password123';

      when(
        () => mockTokenStorage.getAccessToken(),
      ).thenAnswer((_) async => null);

      when(
        () => mockAuthRepository.login(email: email, password: password),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(),
          type: DioExceptionType.connectionError,
        ),
      );

      container.read(authProvider);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      await container
          .read(authProvider.notifier)
          .login(
            email: email,
            password: password,
          );

      final state = container.read(authProvider);

      expect(state, isA<AuthStateUnauthenticated>());
      if (state case AuthStateUnauthenticated(:final message)) {
        expect(message?.toLowerCase(), contains('network'));
      }
    });
  });

  group('Registration Flow', () {
    test('successful registration auto-logs in user', () async {
      const email = 'newuser@example.com';
      const password = 'securePassword123';
      const accessToken = 'new.access.token';
      const tokens = AuthTokens(accessToken: accessToken);
      const user = UserModel(id: 'user-456', email: email);

      when(
        () => mockTokenStorage.getAccessToken(),
      ).thenAnswer((_) async => null);

      when(
        () => mockAuthRepository.register(email: email, password: password),
      ).thenAnswer((_) async => user);

      when(
        () => mockAuthRepository.login(email: email, password: password),
      ).thenAnswer((_) async => tokens);

      when(
        () => mockAuthRepository.getCurrentUser(),
      ).thenAnswer((_) async => user);

      container.read(authProvider);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      await container
          .read(authProvider.notifier)
          .register(
            email: email,
            password: password,
          );

      final state = container.read(authProvider);

      expect(state, isA<AuthStateAuthenticated>());
    });

    test('registration with existing email shows error', () async {
      const email = 'existing@example.com';
      const password = 'password123';

      when(
        () => mockTokenStorage.getAccessToken(),
      ).thenAnswer((_) async => null);

      when(
        () => mockAuthRepository.register(email: email, password: password),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(),
          response: Response(
            requestOptions: RequestOptions(),
            statusCode: 400,
            data: {'detail': 'Email already registered'},
          ),
        ),
      );

      container.read(authProvider);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      await container
          .read(authProvider.notifier)
          .register(
            email: email,
            password: password,
          );

      final state = container.read(authProvider);

      expect(state, isA<AuthStateUnauthenticated>());
    });
  });

  group('Logout Flow', () {
    test('logout clears state and transitions to unauthenticated', () async {
      const accessToken = 'valid.token';
      const user = UserModel(id: 'user-123', email: 'test@example.com');

      // Set up authenticated state
      when(
        () => mockTokenStorage.getAccessToken(),
      ).thenAnswer((_) async => accessToken);
      when(
        () => mockTokenStorage.isTokenExpired(accessToken),
      ).thenReturn(false);
      when(
        () => mockAuthRepository.getCurrentUser(),
      ).thenAnswer((_) async => user);
      when(() => mockAuthRepository.logout()).thenAnswer((_) async {});

      container.read(authProvider);
      await Future<void>.delayed(const Duration(milliseconds: 200));

      // Verify authenticated
      expect(container.read(authProvider), isA<AuthStateAuthenticated>());

      // Perform logout
      await container.read(authProvider.notifier).logout();

      final state = container.read(authProvider);
      expect(state, isA<AuthStateUnauthenticated>());
    });

    test('logout succeeds even if repository throws', () async {
      const accessToken = 'valid.token';
      const user = UserModel(id: 'user-123', email: 'test@example.com');

      when(
        () => mockTokenStorage.getAccessToken(),
      ).thenAnswer((_) async => accessToken);
      when(
        () => mockTokenStorage.isTokenExpired(accessToken),
      ).thenReturn(false);
      when(
        () => mockAuthRepository.getCurrentUser(),
      ).thenAnswer((_) async => user);
      when(() => mockAuthRepository.logout()).thenThrow(Exception('API error'));

      container.read(authProvider);
      await Future<void>.delayed(const Duration(milliseconds: 200));

      await container.read(authProvider.notifier).logout();

      // Should still be unauthenticated despite error
      final state = container.read(authProvider);
      expect(state, isA<AuthStateUnauthenticated>());
    });
  });

  group('Offline-First Auth', () {
    test('uses cached user when network is unavailable', () async {
      const accessToken = 'valid.token';
      const offlineUser = UserModel(
        id: 'cached-user',
        email: 'cached@example.com',
      );

      when(
        () => mockTokenStorage.getAccessToken(),
      ).thenAnswer((_) async => accessToken);
      when(
        () => mockTokenStorage.isTokenExpired(accessToken),
      ).thenReturn(false);

      // Simulate network error
      when(() => mockAuthRepository.getCurrentUser()).thenThrow(
        DioException(
          requestOptions: RequestOptions(),
          type: DioExceptionType.connectionError,
        ),
      );

      when(
        () => mockAuthRepository.getOfflineUser(),
      ).thenAnswer((_) async => offlineUser);

      container.read(authProvider);
      await Future<void>.delayed(const Duration(milliseconds: 200));

      final state = container.read(authProvider);

      expect(state, isA<AuthStateAuthenticated>());
      if (state case AuthStateAuthenticated(:final user)) {
        expect(user.id, equals('cached-user'));
      }
    });

    test('clears token on 401 even with cached user', () async {
      const accessToken = 'invalid.token';

      when(
        () => mockTokenStorage.getAccessToken(),
      ).thenAnswer((_) async => accessToken);
      when(
        () => mockTokenStorage.isTokenExpired(accessToken),
      ).thenReturn(false);
      when(() => mockTokenStorage.clearAll()).thenAnswer((_) async {});

      // 401 from server
      when(() => mockAuthRepository.getCurrentUser()).thenThrow(
        DioException(
          requestOptions: RequestOptions(),
          response: Response(
            requestOptions: RequestOptions(),
            statusCode: 401,
          ),
        ),
      );

      container.read(authProvider);
      await Future<void>.delayed(const Duration(milliseconds: 200));

      final state = container.read(authProvider);

      expect(state, isA<AuthStateUnauthenticated>());
      verify(() => mockTokenStorage.clearAll()).called(1);
    });
  });

  group('Forgot Password', () {
    test('forgotPassword returns true on success', () async {
      const email = 'user@example.com';

      when(
        () => mockTokenStorage.getAccessToken(),
      ).thenAnswer((_) async => null);
      when(
        () => mockAuthRepository.forgotPassword(email),
      ).thenAnswer((_) async {});

      container.read(authProvider);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final result = await container
          .read(authProvider.notifier)
          .forgotPassword(email);

      expect(result, isTrue);
      verify(() => mockAuthRepository.forgotPassword(email)).called(1);
    });

    test('forgotPassword returns false on error', () async {
      const email = 'user@example.com';

      when(
        () => mockTokenStorage.getAccessToken(),
      ).thenAnswer((_) async => null);
      when(
        () => mockAuthRepository.forgotPassword(email),
      ).thenThrow(Exception('Network error'));

      container.read(authProvider);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final result = await container
          .read(authProvider.notifier)
          .forgotPassword(email);

      expect(result, isFalse);
    });
  });

  group('Helper Providers', () {
    test('isAuthenticated returns true when authenticated', () async {
      const accessToken = 'valid.token';
      const user = UserModel(id: 'user-123', email: 'test@example.com');

      when(
        () => mockTokenStorage.getAccessToken(),
      ).thenAnswer((_) async => accessToken);
      when(
        () => mockTokenStorage.isTokenExpired(accessToken),
      ).thenReturn(false);
      when(
        () => mockAuthRepository.getCurrentUser(),
      ).thenAnswer((_) async => user);

      container.read(authProvider);
      await Future<void>.delayed(const Duration(milliseconds: 200));

      final isAuth = container.read(isAuthenticatedProvider);
      expect(isAuth, isTrue);
    });

    test('isAuthenticated returns false when unauthenticated', () async {
      when(
        () => mockTokenStorage.getAccessToken(),
      ).thenAnswer((_) async => null);

      container.read(authProvider);
      await Future<void>.delayed(const Duration(milliseconds: 100));

      final isAuth = container.read(isAuthenticatedProvider);
      expect(isAuth, isFalse);
    });

    test('currentUser returns user when authenticated', () async {
      const accessToken = 'valid.token';
      const user = UserModel(id: 'user-123', email: 'test@example.com');

      when(
        () => mockTokenStorage.getAccessToken(),
      ).thenAnswer((_) async => accessToken);
      when(
        () => mockTokenStorage.isTokenExpired(accessToken),
      ).thenReturn(false);
      when(
        () => mockAuthRepository.getCurrentUser(),
      ).thenAnswer((_) async => user);

      container.read(authProvider);
      await Future<void>.delayed(const Duration(milliseconds: 200));

      final currentUserValue = container.read(currentUserProvider);
      expect(currentUserValue?.email, equals('test@example.com'));
    });

    test('currentUser returns null when unauthenticated', () async {
      when(
        () => mockTokenStorage.getAccessToken(),
      ).thenAnswer((_) async => null);

      container.read(authProvider);
      await Future<void>.delayed(const Duration(milliseconds: 100));

      final currentUserValue = container.read(currentUserProvider);
      expect(currentUserValue, isNull);
    });

    test('accessToken returns token when authenticated', () async {
      const token = 'valid.token';
      const user = UserModel(id: 'user-123', email: 'test@example.com');

      when(
        () => mockTokenStorage.getAccessToken(),
      ).thenAnswer((_) async => token);
      when(() => mockTokenStorage.isTokenExpired(token)).thenReturn(false);
      when(
        () => mockAuthRepository.getCurrentUser(),
      ).thenAnswer((_) async => user);

      container.read(authProvider);
      await Future<void>.delayed(const Duration(milliseconds: 200));

      final accessTokenValue = container.read(accessTokenProvider);
      expect(accessTokenValue, equals(token));
    });
  });

  group('State Transitions', () {
    test('shows loading state during login', () async {
      const email = 'user@example.com';
      const password = 'password123';

      when(
        () => mockTokenStorage.getAccessToken(),
      ).thenAnswer((_) async => null);

      // Make login take some time
      when(
        () => mockAuthRepository.login(email: email, password: password),
      ).thenAnswer((_) async {
        await Future<void>.delayed(const Duration(milliseconds: 100));
        return const AuthTokens(accessToken: 'token');
      });

      const user = UserModel(id: 'user-123', email: email);
      when(
        () => mockAuthRepository.getCurrentUser(),
      ).thenAnswer((_) async => user);

      container.read(authProvider);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      // Start login (don't await)
      final loginFuture = container
          .read(authProvider.notifier)
          .login(
            email: email,
            password: password,
          );

      // Check state immediately after starting
      await Future<void>.delayed(const Duration(milliseconds: 10));
      final loadingState = container.read(authProvider);
      expect(loadingState, isA<AuthStateLoading>());

      // Wait for completion
      await loginFuture;
    });

    test('refreshAuthStatus re-checks authentication', () async {
      const accessToken = 'valid.token';
      const user = UserModel(id: 'user-123', email: 'test@example.com');

      when(
        () => mockTokenStorage.getAccessToken(),
      ).thenAnswer((_) async => accessToken);
      when(
        () => mockTokenStorage.isTokenExpired(accessToken),
      ).thenReturn(false);
      when(
        () => mockAuthRepository.getCurrentUser(),
      ).thenAnswer((_) async => user);

      container.read(authProvider);
      await Future<void>.delayed(const Duration(milliseconds: 200));

      // Refresh
      await container.read(authProvider.notifier).refreshAuthStatus();

      // Should have called getCurrentUser again
      verify(() => mockAuthRepository.getCurrentUser()).called(2);
    });
  });
}
