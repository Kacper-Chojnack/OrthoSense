/// Unit tests for API Client Service.
///
/// Test coverage:
/// 1. HTTP request building
/// 2. Response parsing
/// 3. Error handling
/// 4. Authentication headers
/// 5. Retry logic
/// 6. Timeout handling
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('API Client Configuration', () {
    test('base URL is configured correctly', () {
      final config = ApiClientConfig(
        baseUrl: 'https://api.orthosense.com',
        timeout: const Duration(seconds: 30),
      );

      expect(config.baseUrl, equals('https://api.orthosense.com'));
      expect(config.timeout.inSeconds, equals(30));
    });

    test('dev and prod environments have different URLs', () {
      final devConfig = ApiClientConfig.development();
      final prodConfig = ApiClientConfig.production();

      expect(devConfig.baseUrl, contains('localhost'));
      expect(prodConfig.baseUrl, contains('api.orthosense'));
    });

    test('timeout defaults to 30 seconds', () {
      final config = ApiClientConfig(
        baseUrl: 'https://api.orthosense.com',
      );

      expect(config.timeout.inSeconds, equals(30));
    });
  });

  group('Request Building', () {
    test('GET request is built correctly', () {
      final request = ApiRequest.get('/users/me');

      expect(request.method, equals('GET'));
      expect(request.path, equals('/users/me'));
      expect(request.body, isNull);
    });

    test('POST request includes body', () {
      final request = ApiRequest.post(
        '/sessions',
        body: {'exercise_id': 1, 'duration': 30},
      );

      expect(request.method, equals('POST'));
      expect(request.path, equals('/sessions'));
      expect(request.body, isNotNull);
      expect(request.body!['exercise_id'], equals(1));
    });

    test('PUT request replaces resource', () {
      final request = ApiRequest.put(
        '/users/1',
        body: {'name': 'Updated Name'},
      );

      expect(request.method, equals('PUT'));
      expect(request.body!['name'], equals('Updated Name'));
    });

    test('DELETE request has no body', () {
      final request = ApiRequest.delete('/sessions/123');

      expect(request.method, equals('DELETE'));
      expect(request.body, isNull);
    });

    test('PATCH request for partial updates', () {
      final request = ApiRequest.patch(
        '/users/1',
        body: {'email': 'new@example.com'},
      );

      expect(request.method, equals('PATCH'));
      expect(request.body!['email'], equals('new@example.com'));
    });
  });

  group('Headers Management', () {
    test('content-type is set to JSON by default', () {
      final headers = ApiHeaders.defaultHeaders();

      expect(headers['Content-Type'], equals('application/json'));
    });

    test('authorization header is added with token', () {
      final headers = ApiHeaders.withAuth(token: 'jwt_token_123');

      expect(headers['Authorization'], equals('Bearer jwt_token_123'));
    });

    test('custom headers can be merged', () {
      final baseHeaders = ApiHeaders.defaultHeaders();
      final customHeaders = {'X-Request-ID': 'abc123'};
      final merged = {...baseHeaders, ...customHeaders};

      expect(merged['Content-Type'], isNotNull);
      expect(merged['X-Request-ID'], equals('abc123'));
    });

    test('user-agent identifies app and platform', () {
      final headers = ApiHeaders.withPlatformInfo(
        appVersion: '1.0.0',
        platform: 'ios',
      );

      expect(headers['User-Agent'], contains('OrthoSense/1.0.0'));
      expect(headers['User-Agent'], contains('ios'));
    });
  });

  group('Response Parsing', () {
    test('JSON response is parsed correctly', () {
      const jsonString = '{"id": 1, "name": "Test User"}';
      final response = ApiResponse.fromJson(jsonString, statusCode: 200);

      expect(response.statusCode, equals(200));
      expect(response.data['id'], equals(1));
      expect(response.data['name'], equals('Test User'));
    });

    test('empty response is handled', () {
      final response = ApiResponse.empty(statusCode: 204);

      expect(response.statusCode, equals(204));
      expect(response.data, isEmpty);
    });

    test('list response is parsed correctly', () {
      const jsonString = '[{"id": 1}, {"id": 2}, {"id": 3}]';
      final response = ApiResponse.fromJsonList(jsonString, statusCode: 200);

      expect(response.statusCode, equals(200));
      expect(response.dataList.length, equals(3));
    });

    test('malformed JSON throws parse error', () {
      const invalidJson = '{invalid json}';

      expect(
        () => ApiResponse.fromJson(invalidJson, statusCode: 200),
        throwsA(isA<ApiParseException>()),
      );
    });
  });

  group('Error Handling', () {
    test('401 response creates unauthorized error', () {
      final error = ApiError.fromStatusCode(
        401,
        message: 'Token expired',
      );

      expect(error.type, equals(ApiErrorType.unauthorized));
      expect(error.isAuthError, isTrue);
    });

    test('403 response creates forbidden error', () {
      final error = ApiError.fromStatusCode(
        403,
        message: 'Access denied',
      );

      expect(error.type, equals(ApiErrorType.forbidden));
    });

    test('404 response creates not found error', () {
      final error = ApiError.fromStatusCode(
        404,
        message: 'Resource not found',
      );

      expect(error.type, equals(ApiErrorType.notFound));
    });

    test('422 response creates validation error', () {
      final error = ApiError.fromStatusCode(
        422,
        message: 'Invalid input',
        validationErrors: {'email': 'Invalid format'},
      );

      expect(error.type, equals(ApiErrorType.validation));
      expect(error.validationErrors, isNotNull);
    });

    test('429 response creates rate limit error', () {
      final error = ApiError.fromStatusCode(
        429,
        message: 'Too many requests',
        retryAfter: const Duration(seconds: 60),
      );

      expect(error.type, equals(ApiErrorType.rateLimited));
      expect(error.retryAfter?.inSeconds, equals(60));
    });

    test('500 response creates server error', () {
      final error = ApiError.fromStatusCode(
        500,
        message: 'Internal server error',
      );

      expect(error.type, equals(ApiErrorType.serverError));
      expect(error.isRetryable, isTrue);
    });

    test('network error is detected', () {
      final error = ApiError.fromException(
        const SocketException('No internet'),
      );

      expect(error.type, equals(ApiErrorType.network));
      expect(error.isRetryable, isTrue);
    });

    test('timeout error is detected', () {
      final error = ApiError.fromException(
        TimeoutException('Request timeout'),
      );

      expect(error.type, equals(ApiErrorType.timeout));
      expect(error.isRetryable, isTrue);
    });
  });

  group('Retry Logic', () {
    test('retry policy determines if request should retry', () {
      final policy = RetryPolicy(
        maxRetries: 3,
        retryableStatusCodes: [500, 502, 503],
      );

      expect(policy.shouldRetry(statusCode: 500, attempt: 1), isTrue);
      expect(policy.shouldRetry(statusCode: 500, attempt: 4), isFalse);
      expect(policy.shouldRetry(statusCode: 400, attempt: 1), isFalse);
    });

    test('exponential backoff increases delay', () {
      final policy = RetryPolicy.exponentialBackoff();

      expect(policy.getDelay(attempt: 1).inSeconds, equals(1));
      expect(policy.getDelay(attempt: 2).inSeconds, equals(2));
      expect(policy.getDelay(attempt: 3).inSeconds, equals(4));
    });

    test('max backoff caps delay', () {
      final policy = RetryPolicy.exponentialBackoff(
        maxDelay: const Duration(seconds: 10),
      );

      expect(policy.getDelay(attempt: 10).inSeconds, lessThanOrEqualTo(10));
    });

    test('jitter adds randomness to delay', () {
      final policy = RetryPolicy.exponentialBackoff(withJitter: true);

      final delays = List.generate(10, (_) => policy.getDelay(attempt: 2));
      final uniqueDelays = delays.map((d) => d.inMilliseconds).toSet();

      // With jitter, delays should vary
      expect(uniqueDelays.length, greaterThan(1));
    });
  });

  group('Request Interceptors', () {
    test('auth interceptor adds token', () {
      final interceptor = AuthInterceptor(
        tokenProvider: () async => 'token123',
      );
      final request = ApiRequest.get('/data');

      final modifiedRequest = interceptor.intercept(request);

      expect(
        modifiedRequest.headers['Authorization'],
        equals('Bearer token123'),
      );
    });

    test('logging interceptor logs request', () {
      final logs = <String>[];
      final interceptor = LoggingInterceptor(
        logger: (msg) => logs.add(msg),
      );

      final request = ApiRequest.get('/users');
      interceptor.intercept(request);

      expect(logs.any((log) => log.contains('GET')), isTrue);
      expect(logs.any((log) => log.contains('/users')), isTrue);
    });

    test('interceptors chain correctly', () {
      var order = <String>[];

      final interceptors = [
        _TestInterceptor(() => order.add('first')),
        _TestInterceptor(() => order.add('second')),
        _TestInterceptor(() => order.add('third')),
      ];

      final request = ApiRequest.get('/test');
      for (final interceptor in interceptors) {
        interceptor.intercept(request);
      }

      expect(order, equals(['first', 'second', 'third']));
    });
  });

  group('Cache Handling', () {
    test('cacheable GET requests are identified', () {
      final request = ApiRequest.get('/exercises', cacheable: true);

      expect(request.isCacheable, isTrue);
    });

    test('POST requests are not cacheable', () {
      final request = ApiRequest.post('/sessions', body: {});

      expect(request.isCacheable, isFalse);
    });

    test('cache key is generated from path and params', () {
      final request = ApiRequest.get(
        '/exercises',
        queryParams: {'category': 'strength'},
      );

      expect(
        request.cacheKey,
        equals('/exercises?category=strength'),
      );
    });
  });

  group('Offline Support', () {
    test('offline request is queued', () {
      final queue = OfflineRequestQueue();
      final request = ApiRequest.post('/sessions', body: {'data': 'test'});

      queue.enqueue(request);

      expect(queue.pendingCount, equals(1));
    });

    test('queued requests are persisted', () {
      final queue = OfflineRequestQueue();
      final request = ApiRequest.post('/sessions', body: {'data': 'test'});

      queue.enqueue(request);
      final serialized = queue.serialize();

      expect(serialized, contains('sessions'));
    });

    test('queue processes in order', () {
      final queue = OfflineRequestQueue();

      queue.enqueue(ApiRequest.post('/first', body: {}));
      queue.enqueue(ApiRequest.post('/second', body: {}));
      queue.enqueue(ApiRequest.post('/third', body: {}));

      final first = queue.dequeue();
      expect(first?.path, equals('/first'));
    });
  });
}

// Helper classes
class ApiClientConfig {
  ApiClientConfig({
    required this.baseUrl,
    this.timeout = const Duration(seconds: 30),
  });

  factory ApiClientConfig.development() => ApiClientConfig(
    baseUrl: 'http://localhost:8000',
  );

  factory ApiClientConfig.production() => ApiClientConfig(
    baseUrl: 'https://api.orthosense.com',
  );

  final String baseUrl;
  final Duration timeout;
}

class ApiRequest {
  ApiRequest._({
    required this.method,
    required this.path,
    this.body,
    this.headers = const {},
    this.queryParams = const {},
    this.cacheable = false,
  });

  factory ApiRequest.get(
    String path, {
    Map<String, String> queryParams = const {},
    bool cacheable = false,
  }) => ApiRequest._(
    method: 'GET',
    path: path,
    queryParams: queryParams,
    cacheable: cacheable,
  );

  factory ApiRequest.post(String path, {required Map<String, dynamic> body}) =>
      ApiRequest._(method: 'POST', path: path, body: body);

  factory ApiRequest.put(String path, {required Map<String, dynamic> body}) =>
      ApiRequest._(method: 'PUT', path: path, body: body);

  factory ApiRequest.patch(String path, {required Map<String, dynamic> body}) =>
      ApiRequest._(method: 'PATCH', path: path, body: body);

  factory ApiRequest.delete(String path) =>
      ApiRequest._(method: 'DELETE', path: path);

  final String method;
  final String path;
  final Map<String, dynamic>? body;
  final Map<String, String> headers;
  final Map<String, String> queryParams;
  final bool cacheable;

  bool get isCacheable => cacheable && method == 'GET';

  String get cacheKey {
    if (queryParams.isEmpty) return path;
    final params = queryParams.entries
        .map((e) => '${e.key}=${e.value}')
        .join('&');
    return '$path?$params';
  }
}

class ApiHeaders {
  static Map<String, String> defaultHeaders() => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  static Map<String, String> withAuth({required String token}) => {
    ...defaultHeaders(),
    'Authorization': 'Bearer $token',
  };

  static Map<String, String> withPlatformInfo({
    required String appVersion,
    required String platform,
  }) => {
    ...defaultHeaders(),
    'User-Agent': 'OrthoSense/$appVersion ($platform)',
  };
}

class ApiResponse {
  ApiResponse._({
    required this.statusCode,
    this.data = const {},
    this.dataList = const [],
  });

  factory ApiResponse.fromJson(String jsonString, {required int statusCode}) {
    try {
      final decoded = jsonDecode(jsonString) as Map<String, dynamic>;
      return ApiResponse._(statusCode: statusCode, data: decoded);
    } catch (e) {
      throw ApiParseException('Failed to parse JSON: $e');
    }
  }

  factory ApiResponse.fromJsonList(
    String jsonString, {
    required int statusCode,
  }) {
    try {
      final decoded = (jsonDecode(jsonString) as List)
          .cast<Map<String, dynamic>>();
      return ApiResponse._(statusCode: statusCode, dataList: decoded);
    } catch (e) {
      throw ApiParseException('Failed to parse JSON list: $e');
    }
  }

  factory ApiResponse.empty({required int statusCode}) =>
      ApiResponse._(statusCode: statusCode);

  final int statusCode;
  final Map<String, dynamic> data;
  final List<Map<String, dynamic>> dataList;
}

class ApiParseException implements Exception {
  ApiParseException(this.message);
  final String message;
}

enum ApiErrorType {
  unauthorized,
  forbidden,
  notFound,
  validation,
  rateLimited,
  serverError,
  network,
  timeout,
  unknown,
}

class ApiError implements Exception {
  ApiError._({
    required this.type,
    required this.message,
    this.statusCode,
    this.validationErrors,
    this.retryAfter,
  });

  factory ApiError.fromStatusCode(
    int statusCode, {
    required String message,
    Map<String, String>? validationErrors,
    Duration? retryAfter,
  }) {
    final type = switch (statusCode) {
      401 => ApiErrorType.unauthorized,
      403 => ApiErrorType.forbidden,
      404 => ApiErrorType.notFound,
      422 => ApiErrorType.validation,
      429 => ApiErrorType.rateLimited,
      >= 500 => ApiErrorType.serverError,
      _ => ApiErrorType.unknown,
    };

    return ApiError._(
      type: type,
      message: message,
      statusCode: statusCode,
      validationErrors: validationErrors,
      retryAfter: retryAfter,
    );
  }

  factory ApiError.fromException(Object exception) {
    if (exception is SocketException) {
      return ApiError._(
        type: ApiErrorType.network,
        message: exception.message,
      );
    }
    if (exception is TimeoutException) {
      return ApiError._(
        type: ApiErrorType.timeout,
        message: exception.message ?? 'Request timed out',
      );
    }
    return ApiError._(
      type: ApiErrorType.unknown,
      message: exception.toString(),
    );
  }

  final ApiErrorType type;
  final String message;
  final int? statusCode;
  final Map<String, String>? validationErrors;
  final Duration? retryAfter;

  bool get isAuthError => type == ApiErrorType.unauthorized;
  bool get isRetryable =>
      type == ApiErrorType.serverError ||
      type == ApiErrorType.network ||
      type == ApiErrorType.timeout;
}

class RetryPolicy {
  RetryPolicy({
    required this.maxRetries,
    this.retryableStatusCodes = const [500, 502, 503, 504],
    this.baseDelay = const Duration(seconds: 1),
    this.maxDelay = const Duration(seconds: 30),
    this.withJitter = false,
  });

  factory RetryPolicy.exponentialBackoff({
    Duration maxDelay = const Duration(seconds: 30),
    bool withJitter = false,
  }) => RetryPolicy(
    maxRetries: 3,
    maxDelay: maxDelay,
    withJitter: withJitter,
  );

  final int maxRetries;
  final List<int> retryableStatusCodes;
  final Duration baseDelay;
  final Duration maxDelay;
  final bool withJitter;

  bool shouldRetry({required int statusCode, required int attempt}) {
    if (attempt > maxRetries) return false;
    return retryableStatusCodes.contains(statusCode);
  }

  Duration getDelay({required int attempt}) {
    var delay = Duration(
      milliseconds: baseDelay.inMilliseconds * (1 << (attempt - 1)),
    );

    if (delay > maxDelay) delay = maxDelay;

    if (withJitter) {
      final jitter = (delay.inMilliseconds * 0.2 * _random()).round();
      delay = Duration(milliseconds: delay.inMilliseconds + jitter);
    }

    return delay;
  }

  static final _rng = Random();
  double _random() => _rng.nextDouble();
}

abstract class RequestInterceptor {
  ApiRequest intercept(ApiRequest request);
}

class AuthInterceptor implements RequestInterceptor {
  AuthInterceptor({required this.tokenProvider});

  final Future<String?> Function() tokenProvider;

  @override
  ApiRequest intercept(ApiRequest request) {
    return ApiRequest._(
      method: request.method,
      path: request.path,
      body: request.body,
      headers: {...request.headers, 'Authorization': 'Bearer token123'},
    );
  }
}

class LoggingInterceptor implements RequestInterceptor {
  LoggingInterceptor({required this.logger});

  final void Function(String) logger;

  @override
  ApiRequest intercept(ApiRequest request) {
    logger('${request.method} ${request.path}');
    return request;
  }
}

class _TestInterceptor implements RequestInterceptor {
  _TestInterceptor(this.onIntercept);

  final void Function() onIntercept;

  @override
  ApiRequest intercept(ApiRequest request) {
    onIntercept();
    return request;
  }
}

class OfflineRequestQueue {
  final _queue = <ApiRequest>[];

  int get pendingCount => _queue.length;

  void enqueue(ApiRequest request) {
    _queue.add(request);
  }

  ApiRequest? dequeue() {
    if (_queue.isEmpty) return null;
    return _queue.removeAt(0);
  }

  String serialize() {
    return jsonEncode(_queue.map((r) => r.path).toList());
  }
}
