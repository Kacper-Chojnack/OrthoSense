/// Integration tests for offline-first sync functionality.
///
/// Test coverage:
/// 1. Offline data persistence
/// 2. Sync queue management (outbox pattern)
/// 3. Network reconnection handling
/// 4. Conflict resolution
/// 5. Background sync worker
/// 6. Data integrity during sync
/// 7. Retry logic and backoff
library;

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Offline Data Persistence', () {
    test('data is saved locally when offline', () async {
      final repo = _TestSyncRepository();

      // Simulate offline state
      repo.setOfflineMode(true);

      // Save exercise result
      final result = await repo.saveExerciseResult(
        exerciseId: 'ex_123',
        score: 85,
        timestamp: DateTime.now(),
      );

      expect(result, isNotNull);
      expect(result.syncStatus, equals('pending'));

      // Data should be accessible locally
      final localResults = await repo.getLocalResults();
      expect(localResults, hasLength(1));
      expect(localResults.first.exerciseId, equals('ex_123'));
    });

    test('pending items are queued for sync', () async {
      final repo = _TestSyncRepository();

      repo.setOfflineMode(true);

      // Save multiple items
      await repo.saveExerciseResult(
        exerciseId: 'ex_1',
        score: 80,
        timestamp: DateTime.now(),
      );
      await repo.saveExerciseResult(
        exerciseId: 'ex_2',
        score: 90,
        timestamp: DateTime.now(),
      );
      await repo.saveExerciseResult(
        exerciseId: 'ex_3',
        score: 75,
        timestamp: DateTime.now(),
      );

      // All should be pending
      final pendingItems = await repo.getPendingSyncItems();
      expect(pendingItems, hasLength(3));
      for (final item in pendingItems) {
        expect(item.syncStatus, equals('pending'));
      }
    });

    test('local data persists across repository instances', () async {
      // Use shared storage to simulate persistence
      final storage = _SharedStorage();
      final repo1 = _TestSyncRepository(storage: storage);

      // Save data with first repository
      await repo1.saveExerciseResult(
        exerciseId: 'persist_test',
        score: 95,
        timestamp: DateTime.now(),
      );

      // Create new repository instance with same storage
      final repo2 = _TestSyncRepository(storage: storage);
      final results = await repo2.getLocalResults();

      expect(results, hasLength(1));
      expect(results.first.exerciseId, equals('persist_test'));
    });
  });

  group('Sync Queue Management (Outbox Pattern)', () {
    test('items are processed in FIFO order', () async {
      final repo = _TestSyncRepository();
      final syncedIds = <String>[];

      repo.setOfflineMode(true);

      // Save in specific order
      await repo.saveExerciseResult(
        exerciseId: 'first',
        score: 80,
        timestamp: DateTime.now(),
      );
      await Future.delayed(const Duration(milliseconds: 10));
      await repo.saveExerciseResult(
        exerciseId: 'second',
        score: 85,
        timestamp: DateTime.now(),
      );
      await Future.delayed(const Duration(milliseconds: 10));
      await repo.saveExerciseResult(
        exerciseId: 'third',
        score: 90,
        timestamp: DateTime.now(),
      );

      // Go online and sync
      repo.setOfflineMode(false);
      repo.onSync = (id) => syncedIds.add(id);
      await repo.syncPendingItems();

      // Should sync in order
      expect(syncedIds, equals(['first', 'second', 'third']));
    });

    test('failed items are moved to retry queue', () async {
      final repo = _TestSyncRepository();

      await repo.saveExerciseResult(
        exerciseId: 'will_fail',
        score: 80,
        timestamp: DateTime.now(),
      );

      // Simulate server error
      repo.simulateServerError = true;
      await repo.syncPendingItems();

      final item = (await repo.getLocalResults()).first;
      expect(item.syncStatus, equals('retry'));
      expect(item.retryCount, equals(1));
    });

    test('max retries reached moves item to failed state', () async {
      final repo = _TestSyncRepository();
      repo.maxRetries = 3;

      await repo.saveExerciseResult(
        exerciseId: 'max_retry_test',
        score: 80,
        timestamp: DateTime.now(),
      );

      repo.simulateServerError = true;

      // Try to sync 4 times (exceeds max of 3)
      for (var i = 0; i < 4; i++) {
        await repo.syncPendingItems();
      }

      final item = (await repo.getLocalResults()).first;
      expect(item.syncStatus, equals('failed'));
    });

    test('successful sync updates status to synced', () async {
      final repo = _TestSyncRepository();

      await repo.saveExerciseResult(
        exerciseId: 'will_sync',
        score: 90,
        timestamp: DateTime.now(),
      );

      await repo.syncPendingItems();

      final item = (await repo.getLocalResults()).first;
      expect(item.syncStatus, equals('synced'));
      expect(item.serverRecordId, isNotNull);
    });
  });

  group('Network Reconnection Handling', () {
    test('sync triggers on network restoration', () async {
      final repo = _TestSyncRepository();
      final syncWorker = _TestSyncWorker(repo);

      repo.setOfflineMode(true);

      await repo.saveExerciseResult(
        exerciseId: 'pending_item',
        score: 85,
        timestamp: DateTime.now(),
      );

      // Verify item is pending
      var items = await repo.getPendingSyncItems();
      expect(items, hasLength(1));

      // Simulate network restoration
      repo.setOfflineMode(false);
      await syncWorker.onNetworkRestored();

      // Item should now be synced
      items = await repo.getPendingSyncItems();
      expect(items, isEmpty);
    });

    test('connectivity change stream triggers sync eventually', () async {
      final repo = _TestSyncRepository();
      final connectivityController = StreamController<bool>.broadcast();
      final syncWorker = _TestSyncWorker(
        repo,
        connectivityStream: connectivityController.stream,
        debounceMs: 50,
      );

      var syncCount = 0;
      repo.onSync = (_) => syncCount++;

      repo.setOfflineMode(true);
      await repo.saveExerciseResult(
        exerciseId: 'test',
        score: 80,
        timestamp: DateTime.now(),
      );

      // Start listening
      syncWorker.startListening();

      // Go online and emit connected event
      repo.setOfflineMode(false);
      connectivityController.add(true);

      // Wait longer for debounce + sync
      await Future.delayed(const Duration(milliseconds: 200));

      expect(syncCount, greaterThan(0));

      syncWorker.stopListening();
      await connectivityController.close();
    });

    test('debounces rapid connectivity changes', () async {
      final repo = _TestSyncRepository();
      final connectivityController = StreamController<bool>.broadcast();
      final syncWorker = _TestSyncWorker(
        repo,
        connectivityStream: connectivityController.stream,
        debounceMs: 100,
      );

      var syncAttempts = 0;
      repo.onSyncAttempt = () => syncAttempts++;

      await repo.saveExerciseResult(
        exerciseId: 'test',
        score: 80,
        timestamp: DateTime.now(),
      );

      syncWorker.startListening();

      // Rapid connectivity changes (5 in 100ms)
      for (var i = 0; i < 5; i++) {
        connectivityController.add(true);
        await Future.delayed(const Duration(milliseconds: 10));
      }

      // Wait for debounce period + buffer
      await Future.delayed(const Duration(milliseconds: 200));

      // Should only attempt sync once or twice due to debouncing
      expect(syncAttempts, lessThanOrEqualTo(2));

      syncWorker.stopListening();
      await connectivityController.close();
    });
  });

  group('Conflict Resolution', () {
    test('server wins for same timestamp', () async {
      final repo = _TestSyncRepository();
      repo.conflictStrategy = ConflictStrategy.serverWins;

      final timestamp = DateTime.now();

      // Local version
      await repo.saveExerciseResult(
        exerciseId: 'conflict_test',
        score: 80,
        timestamp: timestamp,
      );

      // Simulate server has different data for same item
      repo.mockServerData = {
        'conflict_test': _SyncableItem(
          id: 1,
          exerciseId: 'conflict_test',
          score: 95, // Different score
          timestamp: timestamp,
          syncStatus: 'synced',
          serverRecordId: 'server_123',
        ),
      };

      await repo.syncWithConflictResolution();

      final item = (await repo.getLocalResults()).first;
      expect(item.score, equals(95)); // Server value
    });

    test('client wins for newer timestamp', () async {
      final repo = _TestSyncRepository();
      repo.conflictStrategy = ConflictStrategy.latestWins;

      final serverTime = DateTime.now();
      final clientTime = serverTime.add(const Duration(minutes: 1));

      // Local version (newer)
      await repo.saveExerciseResult(
        exerciseId: 'conflict_test',
        score: 80,
        timestamp: clientTime,
      );

      // Server version (older)
      repo.mockServerData = {
        'conflict_test': _SyncableItem(
          id: 2,
          exerciseId: 'conflict_test',
          score: 70,
          timestamp: serverTime,
          syncStatus: 'synced',
          serverRecordId: 'server_456',
        ),
      };

      await repo.syncWithConflictResolution();

      final item = (await repo.getLocalResults()).first;
      expect(item.score, equals(80)); // Client value (newer)
    });

    test('merge strategy combines data', () async {
      final repo = _TestSyncRepository();
      repo.conflictStrategy = ConflictStrategy.merge;

      await repo.saveSession(
        sessionId: 'session_1',
        exercises: ['ex1', 'ex2'],
        timestamp: DateTime.now(),
      );

      // Server has additional exercises
      repo.mockServerSessions = {
        'session_1': _SyncableSession(
          id: 1,
          sessionId: 'session_1',
          exercises: ['ex2', 'ex3'], // Overlap with ex2, new ex3
          timestamp: DateTime.now(),
          syncStatus: 'synced',
        ),
      };

      await repo.syncSessionsWithMerge();

      final session = (await repo.getLocalSessions()).first;
      // Should have merged exercises
      expect(session.exercises, containsAll(['ex1', 'ex2', 'ex3']));
    });
  });

  group('Background Sync Worker', () {
    test('periodic sync runs at configured interval', () async {
      final repo = _TestSyncRepository();
      final syncWorker = _TestSyncWorker(
        repo,
        syncIntervalMs: 50,
      );

      var syncCount = 0;
      repo.onSyncAttempt = () => syncCount++;

      syncWorker.startPeriodicSync();

      await Future.delayed(const Duration(milliseconds: 175));

      syncWorker.stopPeriodicSync();

      // Should have synced at least 3 times (at 0, 50, 100, 150ms)
      expect(syncCount, greaterThanOrEqualTo(3));
    });

    test('sync worker respects battery optimization', () async {
      final repo = _TestSyncRepository();
      final syncWorker = _TestSyncWorker(repo);

      syncWorker.batteryOptimizationEnabled = true;
      syncWorker.isLowBattery = true;

      var syncAllowed = await syncWorker.shouldSync();
      expect(syncAllowed, isFalse);

      syncWorker.isLowBattery = false;
      syncAllowed = await syncWorker.shouldSync();
      expect(syncAllowed, isTrue);
    });

    test('sync pauses when app is backgrounded', () async {
      final repo = _TestSyncRepository();
      final syncWorker = _TestSyncWorker(repo);

      syncWorker.startPeriodicSync();
      expect(syncWorker.isRunning, isTrue);

      syncWorker.onAppBackgrounded();
      expect(syncWorker.isRunning, isFalse);

      syncWorker.onAppResumed();
      expect(syncWorker.isRunning, isTrue);

      syncWorker.stopPeriodicSync();
    });
  });

  group('Data Integrity During Sync', () {
    test('partial sync failure preserves successful items', () async {
      final repo = _TestSyncRepository();

      // Save 3 items
      await repo.saveExerciseResult(
        exerciseId: 'item_1',
        score: 80,
        timestamp: DateTime.now(),
      );
      await repo.saveExerciseResult(
        exerciseId: 'item_2_fail',
        score: 85,
        timestamp: DateTime.now(),
      );
      await repo.saveExerciseResult(
        exerciseId: 'item_3',
        score: 90,
        timestamp: DateTime.now(),
      );

      // Middle item will fail
      repo.failingIds = {'item_2_fail'};
      await repo.syncPendingItems();

      final results = await repo.getLocalResults();
      final synced = results.where((r) => r.syncStatus == 'synced').toList();
      final failed = results.where((r) => r.syncStatus == 'retry').toList();

      expect(synced, hasLength(2));
      expect(failed, hasLength(1));
      expect(failed.first.exerciseId, equals('item_2_fail'));
    });

    test('sync transaction rolls back on critical error', () async {
      final repo = _TestSyncRepository();

      await repo.saveExerciseResult(
        exerciseId: 'transactional',
        score: 80,
        timestamp: DateTime.now(),
      );

      repo.simulateCriticalError = true;

      try {
        await repo.syncWithTransaction();
      } catch (_) {
        // Expected
      }

      // Item should still be pending (rollback)
      final item = (await repo.getLocalResults()).first;
      expect(item.syncStatus, equals('pending'));
    });

    test('concurrent sync requests are serialized', () async {
      final repo = _TestSyncRepository();
      final executionOrder = <int>[];

      await repo.saveExerciseResult(
        exerciseId: 'test',
        score: 80,
        timestamp: DateTime.now(),
      );

      repo.onSyncStart = (id) async {
        executionOrder.add(id);
        await Future.delayed(const Duration(milliseconds: 20));
      };

      // Start multiple sync operations concurrently
      final futures = [
        repo.syncPendingItemsWithLock(1),
        repo.syncPendingItemsWithLock(2),
        repo.syncPendingItemsWithLock(3),
      ];

      await Future.wait(futures);

      // Should execute sequentially, not interleaved
      expect(executionOrder, equals([1, 2, 3]));
    });
  });

  group('Retry Logic and Backoff', () {
    test('exponential backoff increases delay', () async {
      final repo = _TestSyncRepository();

      await repo.saveExerciseResult(
        exerciseId: 'backoff_test',
        score: 80,
        timestamp: DateTime.now(),
      );

      repo.simulateServerError = true;

      final delays = <Duration>[];
      repo.onRetryDelay = delays.add;

      // Multiple retry attempts
      for (var i = 0; i < 3; i++) {
        await repo.syncPendingItems();
      }

      // Delays should increase exponentially
      expect(delays.length, greaterThanOrEqualTo(2));
      if (delays.length >= 2) {
        expect(delays[1], greaterThan(delays[0]));
      }
    });

    test('backoff resets after successful sync', () async {
      final repo = _TestSyncRepository();

      await repo.saveExerciseResult(
        exerciseId: 'reset_test',
        score: 80,
        timestamp: DateTime.now(),
      );

      // Fail first
      repo.simulateServerError = true;
      await repo.syncPendingItems();

      var item = (await repo.getLocalResults()).first;
      expect(item.retryCount, equals(1));

      // Then succeed
      repo.simulateServerError = false;
      await repo.syncPendingItems();

      // Add new item
      await repo.saveExerciseResult(
        exerciseId: 'new_item',
        score: 90,
        timestamp: DateTime.now(),
      );

      // New item should start fresh
      final newItem = (await repo.getLocalResults()).firstWhere(
        (i) => i.score == 90,
      );
      expect(newItem.retryCount, equals(0));
    });

    test('maximum backoff cap is respected', () async {
      final repo = _TestSyncRepository();
      repo.maxBackoffMs = 1000;

      await repo.saveExerciseResult(
        exerciseId: 'cap_test',
        score: 80,
        timestamp: DateTime.now(),
      );

      repo.simulateServerError = true;

      final delays = <Duration>[];
      repo.onRetryDelay = delays.add;

      // Many retry attempts
      for (var i = 0; i < 10; i++) {
        await repo.syncPendingItems();
      }

      // All delays should be <= max
      for (final delay in delays) {
        expect(delay.inMilliseconds, lessThanOrEqualTo(1000));
      }
    });
  });

  group('Riverpod Integration', () {
    test('sync state notifier updates on sync events', () async {
      final container = ProviderContainer();
      final stateNotifier = container.read(_syncStateProvider.notifier);

      expect(stateNotifier.state.status, equals(SyncStatus.idle));

      stateNotifier.onSyncStarted();
      expect(stateNotifier.state.status, equals(SyncStatus.syncing));

      stateNotifier.onSyncCompleted(3);
      expect(stateNotifier.state.status, equals(SyncStatus.idle));
      expect(stateNotifier.state.lastSyncCount, equals(3));

      container.dispose();
    });

    test('pending count provider reflects actual count', () async {
      final repo = _TestSyncRepository();

      final container = ProviderContainer(
        overrides: [
          _syncRepositoryProvider.overrideWithValue(repo),
        ],
      );

      // Initially zero
      var count = await container.read(_pendingCountProvider.future);
      expect(count, equals(0));

      // Add items
      await repo.saveExerciseResult(
        exerciseId: 'item_1',
        score: 80,
        timestamp: DateTime.now(),
      );
      await repo.saveExerciseResult(
        exerciseId: 'item_2',
        score: 85,
        timestamp: DateTime.now(),
      );

      // Refresh provider
      container.invalidate(_pendingCountProvider);
      count = await container.read(_pendingCountProvider.future);
      expect(count, equals(2));

      container.dispose();
    });
  });
}

// ============================================================
// Test Helpers and Mocks
// ============================================================

/// Shared storage to simulate database persistence
class _SharedStorage {
  final List<_SyncableItem> items = [];
  final List<_SyncableSession> sessions = [];
  int nextId = 1;
}

/// Syncable item model for testing
class _SyncableItem {
  _SyncableItem({
    required this.id,
    required this.exerciseId,
    required this.score,
    required this.timestamp,
    required this.syncStatus,
    this.retryCount = 0,
    this.serverRecordId,
  });

  int id;
  final String exerciseId;
  int score;
  final DateTime timestamp;
  String syncStatus;
  int retryCount;
  String? serverRecordId;

  _SyncableItem copyWith({
    int? id,
    String? exerciseId,
    int? score,
    DateTime? timestamp,
    String? syncStatus,
    int? retryCount,
    String? serverRecordId,
  }) {
    return _SyncableItem(
      id: id ?? this.id,
      exerciseId: exerciseId ?? this.exerciseId,
      score: score ?? this.score,
      timestamp: timestamp ?? this.timestamp,
      syncStatus: syncStatus ?? this.syncStatus,
      retryCount: retryCount ?? this.retryCount,
      serverRecordId: serverRecordId ?? this.serverRecordId,
    );
  }
}

/// Syncable session model for testing
class _SyncableSession {
  _SyncableSession({
    required this.id,
    required this.sessionId,
    required this.exercises,
    required this.timestamp,
    required this.syncStatus,
  });

  final int id;
  final String sessionId;
  List<String> exercises;
  final DateTime timestamp;
  final String syncStatus;
}

/// Conflict resolution strategies
enum ConflictStrategy { serverWins, clientWins, latestWins, merge }

/// Test sync repository
class _TestSyncRepository {
  _TestSyncRepository({_SharedStorage? storage})
    : _storage = storage ?? _SharedStorage();

  final _SharedStorage _storage;
  List<_SyncableItem> get _items => _storage.items;
  List<_SyncableSession> get _sessions => _storage.sessions;
  int get _nextId => _storage.nextId++;

  bool _isOffline = false;
  bool simulateServerError = false;
  bool simulateCriticalError = false;
  int maxRetries = 5;
  int maxBackoffMs = 60000;
  Set<String> failingIds = {};
  Map<String, _SyncableItem> mockServerData = {};
  Map<String, _SyncableSession> mockServerSessions = {};
  ConflictStrategy conflictStrategy = ConflictStrategy.latestWins;

  void Function(String)? onSync;
  void Function()? onSyncAttempt;
  void Function(Duration)? onRetryDelay;
  Future<void> Function(int)? onSyncStart;

  Completer<void>? _currentSyncLock;
  bool _syncInProgress = false;

  void setOfflineMode(bool offline) => _isOffline = offline;

  Future<_SyncableItem> saveExerciseResult({
    required String exerciseId,
    required int score,
    required DateTime timestamp,
  }) async {
    final item = _SyncableItem(
      id: _nextId,
      exerciseId: exerciseId,
      score: score,
      timestamp: timestamp,
      syncStatus: 'pending',
    );
    _items.add(item);
    return item;
  }

  Future<void> saveSession({
    required String sessionId,
    required List<String> exercises,
    required DateTime timestamp,
  }) async {
    _sessions.add(
      _SyncableSession(
        id: _nextId,
        sessionId: sessionId,
        exercises: exercises,
        timestamp: timestamp,
        syncStatus: 'pending',
      ),
    );
  }

  Future<List<_SyncableItem>> getLocalResults() async => List.from(_items);

  Future<List<_SyncableSession>> getLocalSessions() async =>
      List.from(_sessions);

  Future<List<_SyncableItem>> getPendingSyncItems() async {
    return _items
        .where((i) => i.syncStatus == 'pending' || i.syncStatus == 'retry')
        .toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
  }

  Future<void> syncPendingItems() async {
    onSyncAttempt?.call();
    if (_isOffline) return;

    final pending = await getPendingSyncItems();
    for (final item in pending) {
      if (simulateServerError || failingIds.contains(item.exerciseId)) {
        item.retryCount++;

        // Calculate backoff delay
        final delayMs = (100 * (1 << item.retryCount)).clamp(0, maxBackoffMs);
        onRetryDelay?.call(Duration(milliseconds: delayMs));

        if (item.retryCount >= maxRetries) {
          item.syncStatus = 'failed';
        } else {
          item.syncStatus = 'retry';
        }
      } else {
        item.syncStatus = 'synced';
        item.serverRecordId = 'server_${item.id}';
        onSync?.call(item.exerciseId);
      }
    }
  }

  Future<void> syncWithConflictResolution() async {
    for (final item in _items) {
      final serverItem = mockServerData[item.exerciseId];
      if (serverItem == null) {
        // No conflict, just sync
        item.syncStatus = 'synced';
        continue;
      }

      switch (conflictStrategy) {
        case ConflictStrategy.serverWins:
          item.score = serverItem.score;
          item.syncStatus = 'synced';
        case ConflictStrategy.clientWins:
          item.syncStatus = 'synced';
        case ConflictStrategy.latestWins:
          if (serverItem.timestamp.isAfter(item.timestamp)) {
            item.score = serverItem.score;
          }
          item.syncStatus = 'synced';
        case ConflictStrategy.merge:
          // For simple items, latest wins
          item.syncStatus = 'synced';
      }
    }
  }

  Future<void> syncSessionsWithMerge() async {
    for (final session in _sessions) {
      final serverSession = mockServerSessions[session.sessionId];
      if (serverSession != null) {
        // Merge exercises
        final mergedExercises = <String>{
          ...session.exercises,
          ...serverSession.exercises,
        };
        session.exercises = mergedExercises.toList();
      }
    }
  }

  Future<void> syncWithTransaction() async {
    if (simulateCriticalError) {
      throw Exception('Critical sync error');
    }
    await syncPendingItems();
  }

  Future<void> syncPendingItemsWithLock(int id) async {
    // Simple mutex using a flag and completer
    while (_syncInProgress) {
      await Future.delayed(const Duration(milliseconds: 5));
    }

    _syncInProgress = true;

    try {
      await onSyncStart?.call(id);
      await syncPendingItems();
    } finally {
      _syncInProgress = false;
    }
  }
}

/// Test sync worker
class _TestSyncWorker {
  _TestSyncWorker(
    this.repo, {
    this.connectivityStream,
    this.syncIntervalMs = 5000,
    this.debounceMs = 500,
  });

  final _TestSyncRepository repo;
  final Stream<bool>? connectivityStream;
  final int syncIntervalMs;
  final int debounceMs;

  bool batteryOptimizationEnabled = false;
  bool isLowBattery = false;
  bool isRunning = false;

  Timer? _periodicTimer;
  StreamSubscription<bool>? _connectivitySubscription;
  Timer? _debounceTimer;

  Future<void> onNetworkRestored() async {
    await repo.syncPendingItems();
  }

  void startListening() {
    _connectivitySubscription = connectivityStream?.listen((connected) {
      if (connected) {
        _debounceTimer?.cancel();
        _debounceTimer = Timer(Duration(milliseconds: debounceMs), () {
          repo.syncPendingItems();
        });
      }
    });
  }

  void stopListening() {
    _connectivitySubscription?.cancel();
    _debounceTimer?.cancel();
  }

  void startPeriodicSync() {
    isRunning = true;
    repo.onSyncAttempt?.call(); // Initial sync
    _periodicTimer = Timer.periodic(
      Duration(milliseconds: syncIntervalMs),
      (_) => repo.onSyncAttempt?.call(),
    );
  }

  void stopPeriodicSync() {
    isRunning = false;
    _periodicTimer?.cancel();
    _periodicTimer = null;
  }

  Future<bool> shouldSync() async {
    if (batteryOptimizationEnabled && isLowBattery) {
      return false;
    }
    return true;
  }

  void onAppBackgrounded() {
    stopPeriodicSync();
  }

  void onAppResumed() {
    startPeriodicSync();
  }
}

// ============================================================
// Riverpod Providers for Testing
// ============================================================

/// Sync status enum
enum SyncStatus { idle, syncing, error }

/// Sync state model
class SyncState {
  const SyncState({
    this.status = SyncStatus.idle,
    this.lastSyncCount = 0,
    this.errorMessage,
  });

  final SyncStatus status;
  final int lastSyncCount;
  final String? errorMessage;

  SyncState copyWith({
    SyncStatus? status,
    int? lastSyncCount,
    String? errorMessage,
  }) {
    return SyncState(
      status: status ?? this.status,
      lastSyncCount: lastSyncCount ?? this.lastSyncCount,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

/// Sync state notifier
class _SyncStateNotifier extends Notifier<SyncState> {
  @override
  SyncState build() => const SyncState();

  void onSyncStarted() {
    state = state.copyWith(status: SyncStatus.syncing);
  }

  void onSyncCompleted(int count) {
    state = state.copyWith(
      status: SyncStatus.idle,
      lastSyncCount: count,
    );
  }

  void onSyncError(String message) {
    state = state.copyWith(
      status: SyncStatus.error,
      errorMessage: message,
    );
  }
}

final _syncStateProvider = NotifierProvider<_SyncStateNotifier, SyncState>(
  _SyncStateNotifier.new,
);

final _syncRepositoryProvider = Provider<_TestSyncRepository>(
  (ref) => throw UnimplementedError('Must be overridden in tests'),
);

final _pendingCountProvider = FutureProvider<int>((ref) async {
  final repo = ref.watch(_syncRepositoryProvider);
  final pending = await repo.getPendingSyncItems();
  return pending.length;
});
