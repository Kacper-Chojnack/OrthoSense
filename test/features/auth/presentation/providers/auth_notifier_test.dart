import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:orthosense/features/auth/data/auth_repository.dart';
import 'package:orthosense/features/auth/data/token_storage.dart';
import 'package:orthosense/features/auth/domain/models/models.dart';
import 'package:orthosense/features/auth/presentation/providers/auth_notifier.dart';

// Mocks
class MockAuthRepository extends Mock implements AuthRepository {}

class MockTokenStorage extends Mock implements TokenStorage {}

class Listener<T> extends Mock {
  void call(T? previous, T next);
}

void main() {
  late MockAuthRepository mockAuthRepository;
  late MockTokenStorage mockTokenStorage;
  late ProviderContainer container;
  late Listener<AuthState> listener;

  /// Helper to create container after mocks are configured.
  ProviderContainer createContainer() {
    final cont = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(mockAuthRepository),
        tokenStorageProvider.overrideWithValue(mockTokenStorage),
      ],
    );
    cont.listen(
      authProvider,
      listener.call,
      fireImmediately: true,
    );
    return cont;
  }

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    mockTokenStorage = MockTokenStorage();
    listener = Listener<AuthState>();
  });

  tearDown(() {
    container.dispose();
  });

  group('AuthNotifier initialization', () {
    test('starts with initial state', () {
      // Setup default mock
      when(
        () => mockTokenStorage.getAccessToken(),
      ).thenAnswer((_) async => null);

      // Create container - will trigger auth check
      container = createContainer();

      // Before microtask runs, state should be initial
      verify(() => listener(null, const AuthState.initial())).called(1);
    });

    test('transitions to loading during auth check', () async {
      when(
        () => mockTokenStorage.getAccessToken(),
      ).thenAnswer((_) async => null);

      container = createContainer();

      // Wait for microtask to execute
      await Future.microtask(() {});

      verify(() => listener(any(), const AuthState.loading())).called(1);
    });

    test('transitions to unauthenticated when no token', () async {
      when(
        () => mockTokenStorage.getAccessToken(),
      ).thenAnswer((_) async => null);

      container = createContainer();

      // Wait for auth check to complete
      await Future<void>.delayed(const Duration(milliseconds: 100));

      verify(
        () => listener(any(), const AuthState.unauthenticated()),
      ).called(1);
    });

    test('transitions to unauthenticated when token is expired', () async {
      when(
        () => mockTokenStorage.getAccessToken(),
      ).thenAnswer((_) async => 'expired_token');
      when(
        () => mockTokenStorage.isTokenExpired('expired_token'),
      ).thenReturn(true);
      when(() => mockTokenStorage.clearAll()).thenAnswer((_) async {});

      container = createContainer();

      // Wait for auth check to complete
      await Future<void>.delayed(const Duration(milliseconds: 100));

      verify(() => mockTokenStorage.clearAll()).called(1);
      verify(
        () => listener(
          any(),
          const AuthState.unauthenticated(
            message: 'Session expired. Please login again.',
          ),
        ),
      ).called(1);
    });

    test(
      'transitions to authenticated when valid token and user fetched',
      () async {
        const user = UserModel(id: '123', email: 'test@example.com');

        when(
          () => mockTokenStorage.getAccessToken(),
        ).thenAnswer((_) async => 'valid_token');
        when(
          () => mockTokenStorage.isTokenExpired('valid_token'),
        ).thenReturn(false);
        when(
          () => mockAuthRepository.getCurrentUser(),
        ).thenAnswer((_) async => user);

        container = createContainer();

        // Wait for auth check to complete
        await Future<void>.delayed(const Duration(milliseconds: 100));

        verify(
          () => listener(
            any(),
            const AuthState.authenticated(
              user: user,
              accessToken: 'valid_token',
            ),
          ),
        ).called(1);
      },
    );

    test('uses offline user on network error', () async {
      const offlineUser = UserModel(id: '123', email: 'cached@example.com');

      when(
        () => mockTokenStorage.getAccessToken(),
      ).thenAnswer((_) async => 'valid_token');
      when(
        () => mockTokenStorage.isTokenExpired('valid_token'),
      ).thenReturn(false);
      when(() => mockAuthRepository.getCurrentUser()).thenThrow(
        DioException(
          type: DioExceptionType.connectionError,
          requestOptions: RequestOptions(),
        ),
      );
      when(
        () => mockAuthRepository.getOfflineUser(),
      ).thenAnswer((_) async => offlineUser);

      container = createContainer();

      // Wait for auth check to complete
      await Future<void>.delayed(const Duration(milliseconds: 100));

      verify(() => mockAuthRepository.getOfflineUser()).called(1);
    });
  });

  group('AuthNotifier.login', () {
    test('successful login transitions to authenticated', () async {
      const tokens = AuthTokens(accessToken: 'new_token', tokenType: 'bearer');
      const user = UserModel(id: '456', email: 'user@example.com');

      // Setup initial state - no token
      when(
        () => mockTokenStorage.getAccessToken(),
      ).thenAnswer((_) async => null);

      // Setup login mocks
      when(
        () => mockAuthRepository.login(
          email: 'user@example.com',
          password: 'password123',
        ),
      ).thenAnswer((_) async => tokens);
      when(
        () => mockAuthRepository.getCurrentUser(),
      ).thenAnswer((_) async => user);

      container = createContainer();

      // Wait for initial auth check
      await Future<void>.delayed(const Duration(milliseconds: 100));

      // Clear previous listener calls
      clearInteractions(listener);

      // Perform login
      final notifier = container.read(authProvider.notifier);
      await notifier.login(
        email: 'user@example.com',
        password: 'password123',
      );

      // Verify state transitions
      verifyInOrder([
        () => listener(any(), const AuthState.loading()),
        () => listener(
          any(),
          const AuthState.authenticated(
            user: user,
            accessToken: 'new_token',
          ),
        ),
      ]);
    });

    test('failed login transitions to unauthenticated with message', () async {
      // Setup initial state
      when(
        () => mockTokenStorage.getAccessToken(),
      ).thenAnswer((_) async => null);

      // Setup failed login
      when(
        () => mockAuthRepository.login(
          email: 'user@example.com',
          password: 'wrongpassword',
        ),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(),
          response: Response(
            statusCode: 401,
            data: {'detail': 'Incorrect email or password'},
            requestOptions: RequestOptions(),
          ),
        ),
      );

      container = createContainer();

      // Wait for initial auth check
      await Future<void>.delayed(const Duration(milliseconds: 100));

      // Clear previous listener calls
      clearInteractions(listener);

      // Perform login
      final notifier = container.read(authProvider.notifier);
      await notifier.login(
        email: 'user@example.com',
        password: 'wrongpassword',
      );

      // Verify unauthenticated state with error message
      // Note: API extracts 'detail' from response, not hardcoded 401 message
      verify(
        () => listener(
          any(),
          const AuthState.unauthenticated(
            message: 'Incorrect email or password',
          ),
        ),
      ).called(1);
    });

    test('network error during login shows appropriate message', () async {
      // Setup initial state
      when(
        () => mockTokenStorage.getAccessToken(),
      ).thenAnswer((_) async => null);

      // Setup network error
      when(
        () => mockAuthRepository.login(
          email: 'user@example.com',
          password: 'password123',
        ),
      ).thenThrow(
        DioException(
          type: DioExceptionType.connectionTimeout,
          requestOptions: RequestOptions(),
        ),
      );

      container = createContainer();

      // Wait for initial auth check
      await Future<void>.delayed(const Duration(milliseconds: 100));

      // Clear previous listener calls
      clearInteractions(listener);

      // Perform login
      final notifier = container.read(authProvider.notifier);
      await notifier.login(
        email: 'user@example.com',
        password: 'password123',
      );

      // Verify network error message
      verify(
        () => listener(
          any(),
          const AuthState.unauthenticated(
            message: 'Unable to connect to server. Please check your internet connection.',
          ),
        ),
      ).called(1);
    });
  });

  group('AuthNotifier.register', () {
    test('successful registration auto-logs in', () async {
      const tokens = AuthTokens(accessToken: 'new_token', tokenType: 'bearer');
      const user = UserModel(id: '789', email: 'new@example.com');

      // Setup initial state
      when(
        () => mockTokenStorage.getAccessToken(),
      ).thenAnswer((_) async => null);

      // Setup registration and auto-login mocks
      when(
        () => mockAuthRepository.register(
          email: 'new@example.com',
          password: 'password123',
        ),
      ).thenAnswer((_) async => user);
      when(
        () => mockAuthRepository.login(
          email: 'new@example.com',
          password: 'password123',
        ),
      ).thenAnswer((_) async => tokens);
      when(
        () => mockAuthRepository.getCurrentUser(),
      ).thenAnswer((_) async => user);

      container = createContainer();

      // Wait for initial auth check
      await Future<void>.delayed(const Duration(milliseconds: 100));

      // Clear previous listener calls
      clearInteractions(listener);

      // Perform registration
      final notifier = container.read(authProvider.notifier);
      await notifier.register(
        email: 'new@example.com',
        password: 'password123',
      );

      // Verify auto-login after registration
      verify(
        () => mockAuthRepository.register(
          email: 'new@example.com',
          password: 'password123',
        ),
      ).called(1);
      verify(
        () => mockAuthRepository.login(
          email: 'new@example.com',
          password: 'password123',
        ),
      ).called(1);
    });

    test('registration with existing email shows error', () async {
      // Setup initial state
      when(
        () => mockTokenStorage.getAccessToken(),
      ).thenAnswer((_) async => null);

      // Setup registration error
      when(
        () => mockAuthRepository.register(
          email: 'existing@example.com',
          password: 'password123',
        ),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(),
          response: Response(
            statusCode: 400,
            data: {'detail': 'Email already registered'},
            requestOptions: RequestOptions(),
          ),
        ),
      );

      container = createContainer();

      // Wait for initial auth check
      await Future<void>.delayed(const Duration(milliseconds: 100));

      // Clear previous listener calls
      clearInteractions(listener);

      // Perform registration
      final notifier = container.read(authProvider.notifier);
      await notifier.register(
        email: 'existing@example.com',
        password: 'password123',
      );

      // Verify error message - should extract 'detail' from response
      verify(
        () => listener(
          any(),
          const AuthState.unauthenticated(
            message: 'Email already registered',
          ),
        ),
      ).called(1);
    });
  });

  group('AuthNotifier.logout', () {
    test('logout clears state and transitions to unauthenticated', () async {
      const user = UserModel(id: '123', email: 'test@example.com');

      // Setup authenticated state
      when(
        () => mockTokenStorage.getAccessToken(),
      ).thenAnswer((_) async => 'valid_token');
      when(
        () => mockTokenStorage.isTokenExpired('valid_token'),
      ).thenReturn(false);
      when(
        () => mockAuthRepository.getCurrentUser(),
      ).thenAnswer((_) async => user);
      when(() => mockAuthRepository.logout()).thenAnswer((_) async {});

      container = createContainer();

      // Wait for initial auth (authenticated)
      await Future<void>.delayed(const Duration(milliseconds: 100));

      // Clear previous listener calls
      clearInteractions(listener);

      // Perform logout
      final notifier = container.read(authProvider.notifier);
      await notifier.logout();

      // Verify transitions
      verifyInOrder([
        () => listener(any(), const AuthState.loading()),
        () => listener(any(), const AuthState.unauthenticated()),
      ]);
    });

    test('logout succeeds even if repository throws', () async {
      const user = UserModel(id: '123', email: 'test@example.com');

      // Setup authenticated state
      when(
        () => mockTokenStorage.getAccessToken(),
      ).thenAnswer((_) async => 'valid_token');
      when(
        () => mockTokenStorage.isTokenExpired('valid_token'),
      ).thenReturn(false);
      when(
        () => mockAuthRepository.getCurrentUser(),
      ).thenAnswer((_) async => user);
      when(() => mockAuthRepository.logout()).thenThrow(Exception('API error'));

      container = createContainer();

      // Wait for initial auth
      await Future<void>.delayed(const Duration(milliseconds: 100));

      // Clear previous listener calls
      clearInteractions(listener);

      // Perform logout - should not throw
      final notifier = container.read(authProvider.notifier);
      await notifier.logout();

      // Should still transition to unauthenticated
      verify(
        () => listener(any(), const AuthState.unauthenticated()),
      ).called(1);
    });
  });

  group('AuthNotifier.forgotPassword', () {
    test('forgotPassword returns true on success', () async {
      // Setup initial state
      when(
        () => mockTokenStorage.getAccessToken(),
      ).thenAnswer((_) async => null);
      when(
        () => mockAuthRepository.forgotPassword('user@example.com'),
      ).thenAnswer((_) async {});

      container = createContainer();

      // Wait for initial auth check
      await Future<void>.delayed(const Duration(milliseconds: 100));

      final notifier = container.read(authProvider.notifier);
      final result = await notifier.forgotPassword('user@example.com');

      expect(result, true);
      verify(
        () => mockAuthRepository.forgotPassword('user@example.com'),
      ).called(1);
    });

    test('forgotPassword returns false on error', () async {
      // Setup initial state
      when(
        () => mockTokenStorage.getAccessToken(),
      ).thenAnswer((_) async => null);
      when(
        () => mockAuthRepository.forgotPassword('user@example.com'),
      ).thenThrow(Exception('Network error'));

      container = createContainer();

      // Wait for initial auth check
      await Future<void>.delayed(const Duration(milliseconds: 100));

      final notifier = container.read(authProvider.notifier);
      final result = await notifier.forgotPassword('user@example.com');

      expect(result, false);
    });
  });

  group('Helper providers', () {
    test('isAuthenticated returns true when authenticated', () async {
      const user = UserModel(id: '123', email: 'test@example.com');

      when(
        () => mockTokenStorage.getAccessToken(),
      ).thenAnswer((_) async => 'valid_token');
      when(
        () => mockTokenStorage.isTokenExpired('valid_token'),
      ).thenReturn(false);
      when(
        () => mockAuthRepository.getCurrentUser(),
      ).thenAnswer((_) async => user);

      container = createContainer();

      // Wait for auth check
      await Future<void>.delayed(const Duration(milliseconds: 200));

      final isAuth = container.read(isAuthenticatedProvider);
      expect(isAuth, true);
    });

    test('isAuthenticated returns false when unauthenticated', () async {
      when(
        () => mockTokenStorage.getAccessToken(),
      ).thenAnswer((_) async => null);

      container = createContainer();

      // Wait for auth check
      await Future<void>.delayed(const Duration(milliseconds: 200));

      final isAuth = container.read(isAuthenticatedProvider);
      expect(isAuth, false);
    });

    test('currentUser returns user when authenticated', () async {
      const user = UserModel(id: '123', email: 'test@example.com');

      when(
        () => mockTokenStorage.getAccessToken(),
      ).thenAnswer((_) async => 'valid_token');
      when(
        () => mockTokenStorage.isTokenExpired('valid_token'),
      ).thenReturn(false);
      when(
        () => mockAuthRepository.getCurrentUser(),
      ).thenAnswer((_) async => user);

      container = createContainer();

      // Wait for auth check
      await Future<void>.delayed(const Duration(milliseconds: 200));

      final currentUserValue = container.read(currentUserProvider);
      expect(currentUserValue, user);
    });

    test('currentUser returns null when unauthenticated', () async {
      when(
        () => mockTokenStorage.getAccessToken(),
      ).thenAnswer((_) async => null);

      container = createContainer();

      // Wait for auth check
      await Future<void>.delayed(const Duration(milliseconds: 200));

      final currentUserValue = container.read(currentUserProvider);
      expect(currentUserValue, isNull);
    });

    test('accessToken returns token when authenticated', () async {
      const user = UserModel(id: '123', email: 'test@example.com');

      when(
        () => mockTokenStorage.getAccessToken(),
      ).thenAnswer((_) async => 'valid_token');
      when(
        () => mockTokenStorage.isTokenExpired('valid_token'),
      ).thenReturn(false);
      when(
        () => mockAuthRepository.getCurrentUser(),
      ).thenAnswer((_) async => user);

      container = createContainer();

      // Wait for auth check
      await Future<void>.delayed(const Duration(milliseconds: 200));

      final token = container.read(accessTokenProvider);
      expect(token, 'valid_token');
    });
  });
}
