import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:orthosense/core/services/sync/connectivity_service.dart';
import 'package:orthosense/core/services/sync/sync_service.dart';

/// Background worker for automatic sync operations.
///
/// Handles:
/// - Periodic sync (every 5 minutes by default)
/// - Connectivity-triggered sync (when device goes online)
/// - App lifecycle management (pause/resume)
class BackgroundSyncWorker {
  BackgroundSyncWorker({
    required SyncService syncService,
    required ConnectivityService connectivityService,
    this.syncInterval = const Duration(minutes: 5),
    this.debounceDelay = const Duration(milliseconds: 500),
  }) : _syncService = syncService,
       _connectivityService = connectivityService;

  final SyncService _syncService;
  final ConnectivityService _connectivityService;

  /// Interval between periodic sync attempts.
  final Duration syncInterval;

  /// Delay before syncing after connectivity change.
  final Duration debounceDelay;

  Timer? _periodicTimer;
  Timer? _debounceTimer;
  StreamSubscription<bool>? _connectivitySubscription;
  bool _isRunning = false;
  bool _isPaused = false;

  /// Whether the worker is currently running.
  bool get isRunning => _isRunning;

  /// Whether the worker is paused.
  bool get isPaused => _isPaused;

  /// Whether the worker is actively processing.
  bool get isActive => _isRunning && !_isPaused;

  /// Start the background sync worker.
  void start() {
    if (_isRunning) {
      debugPrint('BackgroundSyncWorker: Already running');
      return;
    }

    _isRunning = true;
    _isPaused = false;

    debugPrint('BackgroundSyncWorker: Starting');

    // Listen for connectivity changes
    _connectivitySubscription = _connectivityService.onConnectivityChanged
        .listen(_onConnectivityChanged);

    // Start periodic sync
    _startPeriodicSync();

    // Initial sync if online and has pending items
    if (_connectivityService.isOnline && _syncService.state.hasPendingItems) {
      _syncService.syncPendingItems();
    }
  }

  /// Stop the background sync worker.
  void stop() {
    if (!_isRunning) return;

    _isRunning = false;

    debugPrint('BackgroundSyncWorker: Stopping');

    _stopTimers();
    _connectivitySubscription?.cancel();
    _connectivitySubscription = null;
  }

  /// Pause sync (e.g., when app goes to background).
  void pause() {
    if (!_isRunning || _isPaused) return;

    _isPaused = true;
    _stopTimers();

    debugPrint('BackgroundSyncWorker: Paused');
  }

  /// Resume sync (e.g., when app returns to foreground).
  void resume() {
    if (!_isRunning || !_isPaused) return;

    _isPaused = false;

    debugPrint('BackgroundSyncWorker: Resumed');

    // Restart periodic sync
    _startPeriodicSync();

    // Sync immediately if online and has pending items
    if (_connectivityService.isOnline && _syncService.state.hasPendingItems) {
      _syncService.syncPendingItems();
    }
  }

  void _startPeriodicSync() {
    _periodicTimer?.cancel();
    _periodicTimer = Timer.periodic(syncInterval, (_) {
      if (_connectivityService.isOnline && !_isPaused) {
        debugPrint('BackgroundSyncWorker: Periodic sync triggered');
        _syncService.syncPendingItems();
      }
    });
  }

  void _stopTimers() {
    _periodicTimer?.cancel();
    _periodicTimer = null;
    _debounceTimer?.cancel();
    _debounceTimer = null;
  }

  void _onConnectivityChanged(bool isOnline) {
    if (!_isRunning || _isPaused) return;

    if (isOnline) {
      // Debounce to avoid rapid sync attempts on flaky connections
      _debounceTimer?.cancel();
      _debounceTimer = Timer(debounceDelay, () {
        if (_syncService.state.hasPendingItems) {
          debugPrint('BackgroundSyncWorker: Network restored, syncing');
          _syncService.syncPendingItems();
        }
      });
    }
  }

  /// Dispose resources.
  void dispose() {
    stop();
  }
}
