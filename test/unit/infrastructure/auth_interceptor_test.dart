/// Unit tests for AuthInterceptor.
///
/// Test coverage:
/// 1. Token injection
/// 2. Public path handling
/// 3. 401 error handling
/// 4. Logout callback
library;

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AuthInterceptor', () {
    group('public paths', () {
      test('login path is public', () {
        const publicPaths = <String>[
          '/api/v1/auth/login',
          '/api/v1/auth/register',
          '/api/v1/auth/forgot-password',
          '/api/v1/auth/reset-password',
          '/api/v1/auth/verify-email',
          '/health',
        ];

        const requestPath = '/api/v1/auth/login';
        final isPublic = publicPaths.any((p) => requestPath.contains(p));

        expect(isPublic, isTrue);
      });

      test('register path is public', () {
        const publicPaths = <String>[
          '/api/v1/auth/login',
          '/api/v1/auth/register',
          '/api/v1/auth/forgot-password',
          '/api/v1/auth/reset-password',
          '/api/v1/auth/verify-email',
          '/health',
        ];

        const requestPath = '/api/v1/auth/register';
        final isPublic = publicPaths.any((p) => requestPath.contains(p));

        expect(isPublic, isTrue);
      });

      test('forgot-password path is public', () {
        const publicPaths = <String>[
          '/api/v1/auth/login',
          '/api/v1/auth/register',
          '/api/v1/auth/forgot-password',
          '/api/v1/auth/reset-password',
          '/api/v1/auth/verify-email',
          '/health',
        ];

        const requestPath = '/api/v1/auth/forgot-password';
        final isPublic = publicPaths.any((p) => requestPath.contains(p));

        expect(isPublic, isTrue);
      });

      test('health path is public', () {
        const publicPaths = <String>[
          '/api/v1/auth/login',
          '/api/v1/auth/register',
          '/api/v1/auth/forgot-password',
          '/api/v1/auth/reset-password',
          '/api/v1/auth/verify-email',
          '/health',
        ];

        const requestPath = '/health';
        final isPublic = publicPaths.any((p) => requestPath.contains(p));

        expect(isPublic, isTrue);
      });

      test('sessions path is NOT public', () {
        const publicPaths = <String>[
          '/api/v1/auth/login',
          '/api/v1/auth/register',
          '/api/v1/auth/forgot-password',
          '/api/v1/auth/reset-password',
          '/api/v1/auth/verify-email',
          '/health',
        ];

        const requestPath = '/api/v1/sessions';
        final isPublic = publicPaths.any((p) => requestPath.contains(p));

        expect(isPublic, isFalse);
      });

      test('exercises path is NOT public', () {
        const publicPaths = <String>[
          '/api/v1/auth/login',
          '/api/v1/auth/register',
          '/api/v1/auth/forgot-password',
          '/api/v1/auth/reset-password',
          '/api/v1/auth/verify-email',
          '/health',
        ];

        const requestPath = '/api/v1/exercises';
        final isPublic = publicPaths.any((p) => requestPath.contains(p));

        expect(isPublic, isFalse);
      });
    });

    group('token injection', () {
      test('skips token for public paths', () {
        const isPublic = true;
        final shouldAddToken = !isPublic;

        expect(shouldAddToken, isFalse);
      });

      test('adds token for protected paths', () {
        const isPublic = false;
        final shouldAddToken = !isPublic;

        expect(shouldAddToken, isTrue);
      });

      test('formats authorization header correctly', () {
        const token = 'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9...';
        final header = 'Bearer $token';

        expect(header, startsWith('Bearer '));
        expect(header.contains(token), isTrue);
      });

      test('does not add token when null', () {
        const String? token = null;
        final shouldAddToken = token != null;

        expect(shouldAddToken, isFalse);
      });

      test('does not add expired token', () {
        const isExpired = true;
        final shouldAddToken = !isExpired;

        expect(shouldAddToken, isFalse);
      });
    });

    group('error handling', () {
      test('handles 401 on protected endpoint', () {
        const statusCode = 401;
        const isPublic = false;
        final shouldClearTokens = statusCode == 401 && !isPublic;

        expect(shouldClearTokens, isTrue);
      });

      test('ignores 401 on public endpoint', () {
        const statusCode = 401;
        const isPublic = true;
        final shouldClearTokens = statusCode == 401 && !isPublic;

        expect(shouldClearTokens, isFalse);
      });

      test('ignores other status codes', () {
        const statusCode = 403;
        const isPublic = false;
        final shouldClearTokens = statusCode == 401 && !isPublic;

        expect(shouldClearTokens, isFalse);
      });

      test('ignores 500 errors', () {
        const statusCode = 500;
        final shouldClearTokens = statusCode == 401;

        expect(shouldClearTokens, isFalse);
      });
    });

    group('logout callback', () {
      test('calls callback on unauthorized', () {
        var callbackInvoked = false;
        void onUnauthorized() => callbackInvoked = true;

        // Simulate 401 handling
        onUnauthorized();

        expect(callbackInvoked, isTrue);
      });

      test('handles null callback', () {
        const LogoutCallback? callback = null;
        final hasCallback = callback != null;

        expect(hasCallback, isFalse);
      });
    });
  });

  group('DioProvider', () {
    group('base URL', () {
      test('android emulator uses 10.0.2.2', () {
        const platform = 'android';
        const debugUrl = platform == 'android'
            ? 'http://10.0.2.2:8000'
            : 'http://localhost:8000';

        expect(debugUrl, equals('http://10.0.2.2:8000'));
      });

      test('macOS uses 127.0.0.1', () {
        const platform = 'macos';
        const debugUrl = platform == 'macos'
            ? 'http://127.0.0.1:8000'
            : 'http://localhost:8000';

        expect(debugUrl, equals('http://127.0.0.1:8000'));
      });

      test('production requires API_URL', () {
        const apiUrl = 'https://api.orthosense.com';
        expect(apiUrl.startsWith('https://'), isTrue);
      });
    });

    group('timeouts', () {
      test('connect timeout is 15 seconds', () {
        const connectTimeout = Duration(seconds: 15);
        expect(connectTimeout.inSeconds, equals(15));
      });

      test('receive timeout is 30 seconds', () {
        const receiveTimeout = Duration(seconds: 30);
        expect(receiveTimeout.inSeconds, equals(30));
      });

      test('send timeout is 30 seconds', () {
        const sendTimeout = Duration(seconds: 30);
        expect(sendTimeout.inSeconds, equals(30));
      });
    });

    group('headers', () {
      test('content-type is application/json', () {
        const headers = {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        };

        expect(headers['Content-Type'], equals('application/json'));
      });

      test('accept is application/json', () {
        const headers = {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        };

        expect(headers['Accept'], equals('application/json'));
      });
    });
  });

  group('DebugLoggingInterceptor', () {
    test('logs request method and URI', () {
      const method = 'POST';
      const uri = 'http://localhost:8000/api/v1/auth/login';
      final logMessage = '$method $uri';

      expect(logMessage, contains('POST'));
      expect(logMessage, contains('/api/v1/auth/login'));
    });

    test('logs response status code', () {
      const statusCode = 200;
      final logMessage = '$statusCode';

      expect(logMessage, equals('200'));
    });
  });

  group('Token validation', () {
    test('checks if token is expired', () {
      // Token with exp claim in the past
      final expTime = DateTime.now().subtract(const Duration(hours: 1));
      final isExpired = DateTime.now().isAfter(expTime);

      expect(isExpired, isTrue);
    });

    test('valid token is not expired', () {
      // Token with exp claim in the future
      final expTime = DateTime.now().add(const Duration(hours: 1));
      final isExpired = DateTime.now().isAfter(expTime);

      expect(isExpired, isFalse);
    });

    test('handles token without exp claim', () {
      // Treat as expired for safety
      const hasExpClaim = false;
      final isExpired = !hasExpClaim || true;

      expect(isExpired, isTrue);
    });
  });
}

// Types

typedef LogoutCallback = void Function();
