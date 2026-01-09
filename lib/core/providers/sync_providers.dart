import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orthosense/core/providers/database_provider.dart';
import 'package:orthosense/core/providers/shared_preferences_provider.dart';
import 'package:orthosense/core/services/sync/background_sync_worker.dart';
import 'package:orthosense/core/services/sync/connectivity_service.dart';
import 'package:orthosense/core/services/sync/sync_queue.dart';
import 'package:orthosense/core/services/sync/sync_service.dart';
import 'package:orthosense/core/services/sync/sync_state.dart';
import 'package:orthosense/infrastructure/networking/dio_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'sync_providers.g.dart';

/// Provider for ConnectivityService.
@Riverpod(keepAlive: true)
ConnectivityService connectivityService(Ref ref) {
  final service = ConnectivityService();
  ref.onDispose(service.dispose);
  return service;
}

/// Provider for SyncQueue.
@Riverpod(keepAlive: true)
SyncQueue syncQueue(Ref ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return SyncQueue(prefs);
}

/// Provider for SyncService.
@Riverpod(keepAlive: true)
SyncService syncService(Ref ref) {
  final database = ref.watch(appDatabaseProvider);
  final queue = ref.watch(syncQueueProvider);
  final connectivity = ref.watch(connectivityServiceProvider);
  final dio = ref.watch(dioProvider);

  final service = SyncService(
    database: database,
    queue: queue,
    connectivity: connectivity,
    dio: dio,
  );

  ref.onDispose(service.dispose);
  return service;
}

/// Provider for BackgroundSyncWorker.
@Riverpod(keepAlive: true)
BackgroundSyncWorker backgroundSyncWorker(Ref ref) {
  final syncService = ref.watch(syncServiceProvider);
  final connectivity = ref.watch(connectivityServiceProvider);

  final worker = BackgroundSyncWorker(
    syncService: syncService,
    connectivityService: connectivity,
  );

  ref.onDispose(worker.dispose);
  return worker;
}

/// Provider for current sync state as a stream.
@riverpod
Stream<SyncState> syncStateStream(Ref ref) {
  final service = ref.watch(syncServiceProvider);
  return service.stateStream;
}

/// Provider for current connectivity status.
@riverpod
Stream<bool> connectivityStream(Ref ref) {
  final service = ref.watch(connectivityServiceProvider);
  return service.onConnectivityChanged;
}

/// Notifier for sync operations with UI integration.
@riverpod
class Sync extends _$Sync {
  @override
  SyncState build() {
    final service = ref.watch(syncServiceProvider);

    // Listen to state changes
    final subscription = service.stateStream.listen((newState) {
      state = newState;
    });

    ref.onDispose(subscription.cancel);

    return service.state;
  }

  /// Trigger manual sync.
  Future<void> sync() async {
    final service = ref.read(syncServiceProvider);
    await service.syncPendingItems();
  }

  /// Force sync now (bypass debounce).
  Future<void> forceSyncNow() async {
    final service = ref.read(syncServiceProvider);
    await service.forceSyncNow();
  }

  /// Retry all failed items.
  Future<void> retryFailed() async {
    final service = ref.read(syncServiceProvider);
    await service.retryFailedItems();
  }

  /// Check if device is online.
  bool get isOnline {
    final connectivity = ref.read(connectivityServiceProvider);
    return connectivity.isOnline;
  }
}

/// Provider for pending sync count.
@riverpod
int pendingSyncCount(Ref ref) {
  final syncState = ref.watch(syncProvider);
  return syncState.pendingCount;
}

/// Provider for failed sync count.
@riverpod
int failedSyncCount(Ref ref) {
  final syncState = ref.watch(syncProvider);
  return syncState.failedCount;
}

/// Provider for online status.
@riverpod
bool isOnline(Ref ref) {
  final syncState = ref.watch(syncProvider);
  return syncState.isOnline;
}
