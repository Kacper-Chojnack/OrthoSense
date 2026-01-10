import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orthosense/core/providers/sync_providers.dart';

/// Helper to initialize sync services on app startup.
///
/// Should be called early in app initialization to ensure
/// connectivity monitoring and sync queue are ready.
class SyncInitializer {
  SyncInitializer._();

  static bool _initialized = false;

  /// Check if sync services are initialized.
  static bool get isInitialized => _initialized;

  /// Initialize all sync-related services.
  ///
  /// Safe to call multiple times - will only initialize once.
  static Future<void> initialize(WidgetRef ref) async {
    if (_initialized) {
      debugPrint('SyncInitializer: Already initialized');
      return;
    }

    debugPrint('SyncInitializer: Starting initialization');

    try {
      // Initialize connectivity service first
      final connectivity = ref.read(connectivityServiceProvider);
      await connectivity.initialize();

      // Initialize sync service (loads queue from storage)
      final syncService = ref.read(syncServiceProvider);
      await syncService.initialize();

      // Start background sync worker
      final worker = ref.read(backgroundSyncWorkerProvider);
      worker.start();

      _initialized = true;
      debugPrint('SyncInitializer: Initialization complete');
    } catch (e, stack) {
      debugPrint('SyncInitializer: Initialization failed - $e\n$stack');
      // Don't prevent app from starting if sync init fails
      _initialized = true;
    }
  }

  /// Pause sync when app goes to background.
  static void onAppPaused(WidgetRef ref) {
    if (!_initialized) return;

    try {
      final worker = ref.read(backgroundSyncWorkerProvider);
      worker.pause();
    } catch (e) {
      debugPrint('SyncInitializer: Failed to pause - $e');
    }
  }

  /// Resume sync when app returns to foreground.
  static void onAppResumed(WidgetRef ref) {
    if (!_initialized) return;

    try {
      final worker = ref.read(backgroundSyncWorkerProvider);
      worker.resume();
    } catch (e) {
      debugPrint('SyncInitializer: Failed to resume - $e');
    }
  }

  /// Reset initialization state (for testing).
  @visibleForTesting
  static void reset() {
    _initialized = false;
  }
}
