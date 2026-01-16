import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:orthosense/features/auth/data/auth_repository.dart';
import 'package:orthosense/features/auth/data/token_storage.dart';

// Mocks
class MockDio extends Mock implements Dio {}

class MockTokenStorage extends Mock implements TokenStorage {}

class FakeRequestOptions extends Fake implements RequestOptions {}

void main() {
  late MockDio mockDio;
  late MockTokenStorage mockTokenStorage;
  late AuthRepository repository;

  setUpAll(() {
    registerFallbackValue(FakeRequestOptions());
  });

  setUp(() {
    mockDio = MockDio();
    mockTokenStorage = MockTokenStorage();
    repository = AuthRepository(
      dio: mockDio,
      tokenStorage: mockTokenStorage,
    );
  });

  group('AuthRepository.register', () {
    test('registers user successfully', () async {
      when(
        () => mockDio.post<Map<String, dynamic>>(
          '/api/v1/auth/register',
          data: any(named: 'data'),
        ),
      ).thenAnswer(
        (_) async => Response(
          data: {
            'id': '123e4567-e89b-12d3-a456-426614174000',
            'email': 'new@example.com',
            'is_active': true,
            'is_verified': false,
          },
          statusCode: 201,
          requestOptions: RequestOptions(path: '/api/v1/auth/register'),
        ),
      );

      final user = await repository.register(
        email: 'new@example.com',
        password: 'password123',
      );

      expect(user.email, 'new@example.com');
      expect(user.isVerified, false);

      verify(
        () => mockDio.post<Map<String, dynamic>>(
          '/api/v1/auth/register',
          data: {
            'email': 'new@example.com',
            'password': 'password123',
          },
        ),
      ).called(1);
    });

    test('throws DioException on duplicate email', () async {
      when(
        () => mockDio.post<Map<String, dynamic>>(
          '/api/v1/auth/register',
          data: any(named: 'data'),
        ),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/api/v1/auth/register'),
          response: Response(
            statusCode: 400,
            data: {'detail': 'Email already registered'},
            requestOptions: RequestOptions(path: '/api/v1/auth/register'),
          ),
        ),
      );

      expect(
        () => repository.register(
          email: 'existing@example.com',
          password: 'password123',
        ),
        throwsA(isA<DioException>()),
      );
    });
  });

  group('AuthRepository.login', () {
    test('logs in user and saves token', () async {
      when(
        () => mockDio.post<Map<String, dynamic>>(
          '/api/v1/auth/login',
          data: any(named: 'data'),
          options: any(named: 'options'),
        ),
      ).thenAnswer(
        (_) async => Response(
          data: {
            'access_token': 'jwt_token_here',
            'token_type': 'bearer',
          },
          statusCode: 200,
          requestOptions: RequestOptions(path: '/api/v1/auth/login'),
        ),
      );

      when(
        () => mockTokenStorage.saveAccessToken(any()),
      ).thenAnswer((_) async {});

      final tokens = await repository.login(
        email: 'user@example.com',
        password: 'password123',
      );

      expect(tokens.accessToken, 'jwt_token_here');
      expect(tokens.tokenType, 'bearer');

      verify(
        () => mockTokenStorage.saveAccessToken('jwt_token_here'),
      ).called(1);
    });

    test('throws DioException on invalid credentials', () async {
      when(
        () => mockDio.post<Map<String, dynamic>>(
          '/api/v1/auth/login',
          data: any(named: 'data'),
          options: any(named: 'options'),
        ),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/api/v1/auth/login'),
          response: Response(
            statusCode: 401,
            data: {'detail': 'Incorrect email or password'},
            requestOptions: RequestOptions(path: '/api/v1/auth/login'),
          ),
        ),
      );

      expect(
        () => repository.login(
          email: 'user@example.com',
          password: 'wrongpassword',
        ),
        throwsA(isA<DioException>()),
      );
    });
  });

  group('AuthRepository.getCurrentUser', () {
    test('fetches current user and caches info', () async {
      when(
        () => mockDio.get<Map<String, dynamic>>('/api/v1/auth/me'),
      ).thenAnswer(
        (_) async => Response(
          data: {
            'id': '123',
            'email': 'user@example.com',
            'full_name': 'Test User',
            'role': 'patient',
            'is_active': true,
            'is_verified': true,
          },
          statusCode: 200,
          requestOptions: RequestOptions(path: '/api/v1/auth/me'),
        ),
      );

      when(
        () => mockTokenStorage.saveUserInfo(
          userId: any(named: 'userId'),
          email: any(named: 'email'),
        ),
      ).thenAnswer((_) async {});

      final user = await repository.getCurrentUser();

      expect(user.id, '123');
      expect(user.email, 'user@example.com');
      expect(user.fullName, 'Test User');

      verify(
        () => mockTokenStorage.saveUserInfo(
          userId: '123',
          email: 'user@example.com',
        ),
      ).called(1);
    });

    test('throws DioException on 401', () async {
      when(
        () => mockDio.get<Map<String, dynamic>>('/api/v1/auth/me'),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/api/v1/auth/me'),
          response: Response(
            statusCode: 401,
            data: {'detail': 'Could not validate credentials'},
            requestOptions: RequestOptions(path: '/api/v1/auth/me'),
          ),
        ),
      );

      expect(
        () => repository.getCurrentUser(),
        throwsA(isA<DioException>()),
      );
    });
  });

  group('AuthRepository.forgotPassword', () {
    test('sends password reset request', () async {
      when(
        () => mockDio.post<void>(
          '/api/v1/auth/forgot-password',
          data: any(named: 'data'),
        ),
      ).thenAnswer(
        (_) async => Response(
          statusCode: 202,
          requestOptions: RequestOptions(path: '/api/v1/auth/forgot-password'),
        ),
      );

      await repository.forgotPassword('user@example.com');

      verify(
        () => mockDio.post<void>(
          '/api/v1/auth/forgot-password',
          data: {'email': 'user@example.com'},
        ),
      ).called(1);
    });
  });

  group('AuthRepository.resetPassword', () {
    test('resets password with token', () async {
      when(
        () => mockDio.post<void>(
          '/api/v1/auth/reset-password',
          data: any(named: 'data'),
        ),
      ).thenAnswer(
        (_) async => Response(
          statusCode: 200,
          requestOptions: RequestOptions(path: '/api/v1/auth/reset-password'),
        ),
      );

      await repository.resetPassword(
        token: 'reset_token',
        newPassword: 'newpassword123',
      );

      verify(
        () => mockDio.post<void>(
          '/api/v1/auth/reset-password',
          data: {
            'token': 'reset_token',
            'new_password': 'newpassword123',
          },
        ),
      ).called(1);
    });
  });
}
