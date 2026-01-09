import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:orthosense/infrastructure/networking/auth_interceptor.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'dio_provider.g.dart';

/// Production API URL - set via --dart-define=API_URL=https://your-app.eu-central-1.awsapprunner.com
const String _productionApiUrl = String.fromEnvironment(
  'API_URL',
  defaultValue: '',
);

/// Returns appropriate base URL based on build mode and platform.
/// In release mode: uses API_URL from dart-define or throws if not set.
/// In debug mode: uses API_URL if set, otherwise localhost with platform-specific addresses.
String _getBaseUrl() {
  // If API_URL is set via dart-define, always use it (works in both debug and release)
  if (_productionApiUrl.isNotEmpty) {
    return _productionApiUrl;
  }

  // Release mode without API_URL - error
  if (kReleaseMode) {
    throw StateError(
      'API_URL not configured. Build with: '
      'flutter build apk --dart-define=API_URL=https://your-api.awsapprunner.com',
    );
  }

  // Debug mode without API_URL - use local development servers
  if (Platform.isAndroid) {
    return 'http://10.0.2.2:8000';
  }

  if (Platform.isMacOS) {
    return 'http://127.0.0.1:8000';
  }

  // iOS Simulator, Linux, Windows
  // Using local IP for physical device debugging
  // return 'http://192.168.0.27:8000'; // Zosia
  return 'http://192.168.0.17:8000'; // Kacper
}

/// Provides configured [Dio] instance for API calls.
/// Includes AuthInterceptor for automatic token injection.
@Riverpod(keepAlive: true)
Dio dio(Ref ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: _getBaseUrl(),
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  );

  // Add auth interceptor for automatic token handling
  dio.interceptors.add(
    AuthInterceptor(ref: ref),
  );

  if (kDebugMode) {
    dio.interceptors.add(_DebugLoggingInterceptor());
  }

  return dio;
}

/// Simple debug interceptor for development.
class _DebugLoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    debugPrint('┌── DIO REQUEST ──────────────────────────────────');
    debugPrint('│ ${options.method} ${options.uri}');
    if (options.data != null) {
      debugPrint('│ Body: ${options.data}');
    }
    debugPrint('└─────────────────────────────────────────────────');
    handler.next(options);
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    debugPrint('┌── DIO RESPONSE ─────────────────────────────────');
    debugPrint('│ ${response.statusCode} ${response.requestOptions.uri}');
    debugPrint('│ Data: ${response.data}');
    debugPrint('└─────────────────────────────────────────────────');
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    debugPrint('┌── DIO ERROR ────────────────────────────────────');
    debugPrint('│ ${err.type} ${err.requestOptions.uri}');
    debugPrint('│ Message: ${err.message}');
    if (err.response != null) {
      debugPrint('│ Response: ${err.response?.data}');
    }
    debugPrint('└─────────────────────────────────────────────────');
    handler.next(err);
  }
}
