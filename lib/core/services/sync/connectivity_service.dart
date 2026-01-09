import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

/// Service to monitor network connectivity status.
///
/// Provides real-time connectivity updates and current status.
class ConnectivityService {
  ConnectivityService({Connectivity? connectivity})
    : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;

  final _controller = StreamController<bool>.broadcast();
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  bool _isOnline = true;
  bool _isInitialized = false;

  /// Stream of connectivity status changes.
  Stream<bool> get onConnectivityChanged => _controller.stream;

  /// Current connectivity status.
  bool get isOnline => _isOnline;

  /// Whether the service is initialized.
  bool get isInitialized => _isInitialized;

  /// Initialize and start listening to connectivity changes.
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Check current connectivity
      final results = await _connectivity.checkConnectivity();
      _isOnline = _hasConnection(results);
      debugPrint('ConnectivityService: Initial status - online: $_isOnline');

      // Listen for changes
      _subscription = _connectivity.onConnectivityChanged.listen(
        _onConnectivityChanged,
        onError: (Object error) {
          debugPrint('ConnectivityService: Error - $error');
        },
      );

      _isInitialized = true;
    } catch (e) {
      debugPrint('ConnectivityService: Failed to initialize - $e');
      // Assume online if we can't determine connectivity
      _isOnline = true;
      _isInitialized = true;
    }
  }

  void _onConnectivityChanged(List<ConnectivityResult> results) {
    final wasOnline = _isOnline;
    _isOnline = _hasConnection(results);

    if (wasOnline != _isOnline) {
      debugPrint('ConnectivityService: Status changed - online: $_isOnline');
      _controller.add(_isOnline);
    }
  }

  bool _hasConnection(List<ConnectivityResult> results) {
    return results.any(
      (result) =>
          result == ConnectivityResult.wifi ||
          result == ConnectivityResult.mobile ||
          result == ConnectivityResult.ethernet ||
          result == ConnectivityResult.vpn,
    );
  }

  /// Check connectivity once (useful for pull-to-refresh scenarios).
  Future<bool> checkConnectivity() async {
    try {
      final results = await _connectivity.checkConnectivity();
      final isOnline = _hasConnection(results);

      if (_isOnline != isOnline) {
        _isOnline = isOnline;
        _controller.add(_isOnline);
      }

      return _isOnline;
    } catch (e) {
      debugPrint('ConnectivityService: Check failed - $e');
      return _isOnline;
    }
  }

  /// Dispose resources.
  void dispose() {
    _subscription?.cancel();
    _subscription = null;
    _controller.close();
    _isInitialized = false;
  }
}
