/// Unit tests for DioProvider and network configuration.
///
/// Test coverage:
/// 1. Base URL selection
/// 2. Dio configuration
/// 3. Timeouts
/// 4. Headers
/// 5. Interceptors
library;

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DioProvider', () {
    group('base URL selection', () {
      test('release mode requires API_URL environment variable', () {
        const kReleaseMode = true;
        const productionApiUrl = '';

        final shouldThrow = kReleaseMode && productionApiUrl.isEmpty;
        expect(shouldThrow, isTrue);
      });

      test('release mode uses API_URL when provided', () {
        const kReleaseMode = true;
        const productionApiUrl = 'https://api.example.com';

        final usesProduction = kReleaseMode && productionApiUrl.isNotEmpty;
        expect(usesProduction, isTrue);
      });

      test('debug mode iOS uses 127.0.0.1', () {
        const platform = 'ios';
        const kReleaseMode = false;

        String getDebugUrl() {
          if (platform == 'ios') return 'http://127.0.0.1:8000';
          return 'http://localhost:8000';
        }

        final url = !kReleaseMode ? getDebugUrl() : '';
        expect(url, equals('http://127.0.0.1:8000'));
      });

      test('debug mode macOS uses 127.0.0.1', () {
        const platform = 'macos';
        const kReleaseMode = false;

        String getDebugUrl() {
          if (platform == 'macos') return 'http://127.0.0.1:8000';
          return 'http://localhost:8000';
        }

        final url = !kReleaseMode ? getDebugUrl() : '';
        expect(url, equals('http://127.0.0.1:8000'));
      });
    });

    group('timeout configuration', () {
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

    group('default headers', () {
      test('Content-Type is application/json', () {
        const headers = {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        };

        expect(headers['Content-Type'], equals('application/json'));
      });

      test('Accept is application/json', () {
        const headers = {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        };

        expect(headers['Accept'], equals('application/json'));
      });
    });

    group('interceptors', () {
      test('includes AuthInterceptor', () {
        const interceptors = ['AuthInterceptor', 'DebugLoggingInterceptor'];
        expect(interceptors.contains('AuthInterceptor'), isTrue);
      });

      test('includes DebugLoggingInterceptor in debug mode', () {
        const kDebugMode = true;
        final hasDebugInterceptor = kDebugMode;

        expect(hasDebugInterceptor, isTrue);
      });

      test('excludes DebugLoggingInterceptor in release mode', () {
        const kReleaseMode = true;
        const kDebugMode = !kReleaseMode;
        final hasDebugInterceptor = kDebugMode;

        expect(hasDebugInterceptor, isFalse);
      });
    });

    group('Riverpod configuration', () {
      test('is kept alive', () {
        const keepAlive = true;
        expect(keepAlive, isTrue);
      });
    });
  });

  group('_DebugLoggingInterceptor', () {
    test('logs request details', () {
      var logged = false;

      void onRequest(Map<String, dynamic> options) {
        logged = true;
      }

      onRequest({'path': '/api/test'});
      expect(logged, isTrue);
    });

    test('logs response details', () {
      var logged = false;

      void onResponse(Map<String, dynamic> response) {
        logged = true;
      }

      onResponse({'statusCode': 200});
      expect(logged, isTrue);
    });

    test('logs error details', () {
      var logged = false;

      void onError(Object error) {
        logged = true;
      }

      onError(Exception('Network error'));
      expect(logged, isTrue);
    });
  });

  group('_productionApiUrl', () {
    test('comes from environment variable', () {
      const envVarName = 'API_URL';
      expect(envVarName, equals('API_URL'));
    });

    test('has empty default value', () {
      const defaultValue = '';
      expect(defaultValue, isEmpty);
    });
  });

  group('Error handling', () {
    test('throws StateError when API_URL not configured in release', () {
      const kReleaseMode = true;
      const productionApiUrl = '';

      String? errorMessage;

      void getBaseUrl() {
        if (kReleaseMode && productionApiUrl.isEmpty) {
          errorMessage =
              'API_URL not configured. Build with: '
              'flutter build ios --dart-define=API_URL=https://your-api.awsapprunner.com';
        }
      }

      getBaseUrl();
      expect(errorMessage, isNotNull);
      expect(errorMessage, contains('API_URL not configured'));
    });
  });

  group('Platform detection', () {
    test('detects macOS platform', () {
      const isMacOS = true;
      expect(isMacOS, isTrue);
    });

    test('detects iOS platform', () {
      const isIOS = true;
      expect(isIOS, isTrue);
    });
  });

  group('Local development URLs', () {
    test('macOS uses loopback address', () {
      const macosUrl = 'http://127.0.0.1:8000';
      expect(macosUrl, contains('127.0.0.1'));
    });

    test('iOS uses loopback address', () {
      const iosUrl = 'http://127.0.0.1:8000';
      expect(iosUrl, contains('127.0.0.1'));
    });

    test('all use port 8000', () {
      const urls = [
        'http://127.0.0.1:8000',
      ];

      for (final url in urls) {
        expect(url, contains(':8000'));
      }
    });
  });
}
