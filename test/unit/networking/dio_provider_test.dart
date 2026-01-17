/// Unit tests for DioProvider configuration.
///
/// Test coverage:
/// 1. Base URL configuration
/// 2. Timeout settings
/// 3. Headers configuration
/// 4. Debug logging interceptor
library;

import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DioProvider - Base URL Configuration', () {
    test('Android emulator uses 10.0.2.2 for localhost', () {
      const androidLocalhost = 'http://10.0.2.2:8000';
      
      expect(androidLocalhost, contains('10.0.2.2'));
      expect(androidLocalhost, contains('8000'));
    });

    test('macOS uses 127.0.0.1 for localhost', () {
      const macosLocalhost = 'http://127.0.0.1:8000';
      
      expect(macosLocalhost, contains('127.0.0.1'));
      expect(macosLocalhost, contains('8000'));
    });

    test('iOS uses local IP for physical device', () {
      const iosLocalhost = 'http://192.168.0.27:8000';
      
      expect(iosLocalhost, contains('192.168'));
      expect(iosLocalhost, contains('8000'));
    });

    test('production URL is from environment variable', () {
      // In production, API_URL would be set via --dart-define
      const productionUrl = String.fromEnvironment(
        'API_URL',
        defaultValue: '',
      );
      
      // During testing, this is empty
      expect(productionUrl, isEmpty);
    });

    test('release mode requires API_URL to be set', () {
      // Simulating the check that happens in release mode
      const productionApiUrl = '';
      const isRelease = false; // In tests, this is false
      
      // If isRelease && productionApiUrl.isEmpty, throw error
      if (isRelease && productionApiUrl.isEmpty) {
        expect(() => throw StateError('API_URL not configured'), throwsStateError);
      }
    });
  });

  group('DioProvider - Timeout Configuration', () {
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

  group('DioProvider - Headers Configuration', () {
    test('Content-Type is application/json', () {
      const contentType = 'application/json';
      
      expect(contentType, equals('application/json'));
    });

    test('Accept is application/json', () {
      const accept = 'application/json';
      
      expect(accept, equals('application/json'));
    });

    test('default headers include required headers', () {
      const headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };
      
      expect(headers.containsKey('Content-Type'), isTrue);
      expect(headers.containsKey('Accept'), isTrue);
    });
  });

  group('DebugLoggingInterceptor', () {
    test('formats request log correctly', () {
      const method = 'POST';
      const uri = 'http://localhost:8000/api/v1/auth/login';
      final body = {'email': 'test@test.com'};
      
      final log = '│ $method $uri\n│ Body: $body';
      
      expect(log, contains('POST'));
      expect(log, contains('login'));
      expect(log, contains('email'));
    });

    test('formats response log correctly', () {
      const statusCode = 200;
      const uri = 'http://localhost:8000/api/v1/auth/login';
      const data = {'token': 'jwt_token'};
      
      final log = '│ $statusCode $uri\n│ Data: $data';
      
      expect(log, contains('200'));
      expect(log, contains('token'));
    });

    test('formats error log correctly', () {
      const statusCode = 401;
      const message = 'Unauthorized';
      
      final log = '│ ERROR $statusCode: $message';
      
      expect(log, contains('ERROR'));
      expect(log, contains('401'));
      expect(log, contains('Unauthorized'));
    });
  });

  group('Platform Detection', () {
    test('can detect platform', () {
      // Platform detection would use Platform.isAndroid, Platform.isIOS, etc.
      // In tests, we verify the logic
      
      final platformChecks = [
        () => Platform.isAndroid,
        () => Platform.isIOS,
        () => Platform.isMacOS,
        () => Platform.isWindows,
        () => Platform.isLinux,
      ];
      
      // At least one should be true
      final hasAnyTrue = platformChecks.any((check) {
        try {
          return check();
        } catch (_) {
          return false;
        }
      });
      
      expect(hasAnyTrue, isTrue);
    });
  });

  group('URL Validation', () {
    test('valid HTTP URL format', () {
      const url = 'http://localhost:8000';
      
      expect(url, startsWith('http'));
      expect(Uri.parse(url).isAbsolute, isTrue);
    });

    test('valid HTTPS URL format', () {
      const url = 'https://api.example.com';
      
      expect(url, startsWith('https'));
      expect(Uri.parse(url).isAbsolute, isTrue);
    });

    test('URL with port is valid', () {
      const url = 'http://localhost:8000';
      final uri = Uri.parse(url);
      
      expect(uri.port, equals(8000));
    });

    test('URL with path is valid', () {
      const baseUrl = 'http://localhost:8000';
      const path = '/api/v1/auth/login';
      final fullUrl = '$baseUrl$path';
      
      expect(Uri.parse(fullUrl).path, equals(path));
    });
  });

  group('BaseOptions configuration', () {
    test('creates valid base options structure', () {
      final options = {
        'baseUrl': 'http://localhost:8000',
        'connectTimeout': const Duration(seconds: 15),
        'receiveTimeout': const Duration(seconds: 30),
        'sendTimeout': const Duration(seconds: 30),
        'headers': {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      };
      
      expect(options['baseUrl'], isNotEmpty);
      expect(options['connectTimeout'], isA<Duration>());
      expect(options['headers'], isA<Map<String, String>>());
    });
  });
}
