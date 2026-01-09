/// Unit tests for Sync Provider (Offline-First functionality).
///
/// Test coverage:
/// 1. Sync status tracking
/// 2. Pending items queue management
/// 3. Sync conflict resolution
/// 4. Retry logic
/// 5. Background sync state
library;

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Sync Status Tracking', () {
    test('initial sync status is idle', () {
      final state = SyncState.idle();
      expect(state.status, equals(SyncStatus.idle));
      expect(state.pendingCount, equals(0));
    });

    test('sync status transitions to syncing', () {
      final state = SyncState.syncing(pendingCount: 5);
      expect(state.status, equals(SyncStatus.syncing));
      expect(state.pendingCount, equals(5));
    });

    test('sync status transitions to completed', () {
      final state = SyncState.completed(lastSyncAt: DateTime.now());
      expect(state.status, equals(SyncStatus.completed));
      expect(state.lastSyncAt, isNotNull);
    });

    test('sync status tracks errors', () {
      final state = SyncState.error(
        message: 'Network unavailable',
        pendingCount: 3,
      );
      expect(state.status, equals(SyncStatus.error));
      expect(state.errorMessage, equals('Network unavailable'));
      expect(state.pendingCount, equals(3));
    });
  });

  group('Pending Items Queue', () {
    test('pending items are tracked by type', () {
      final queue = SyncQueue();
      queue.addItem(
        SyncItem(
          id: 'item-1',
          type: SyncItemType.exerciseResult,
          data: {'score': 85},
          createdAt: DateTime.now(),
        ),
      );
      queue.addItem(
        SyncItem(
          id: 'item-2',
          type: SyncItemType.session,
          data: {'status': 'completed'},
          createdAt: DateTime.now(),
        ),
      );

      expect(queue.pendingCount, equals(2));
      expect(
        queue.getItemsByType(SyncItemType.exerciseResult).length,
        equals(1),
      );
    });

    test('items are processed in FIFO order', () {
      final queue = SyncQueue();
      final now = DateTime.now();

      queue.addItem(
        SyncItem(
          id: 'first',
          type: SyncItemType.exerciseResult,
          data: {},
          createdAt: now,
        ),
      );
      queue.addItem(
        SyncItem(
          id: 'second',
          type: SyncItemType.exerciseResult,
          data: {},
          createdAt: now.add(const Duration(seconds: 1)),
        ),
      );
      queue.addItem(
        SyncItem(
          id: 'third',
          type: SyncItemType.exerciseResult,
          data: {},
          createdAt: now.add(const Duration(seconds: 2)),
        ),
      );

      final nextItem = queue.getNextItem();
      expect(nextItem?.id, equals('first'));
    });

    test('processed items are removed from queue', () {
      final queue = SyncQueue();
      queue.addItem(
        SyncItem(
          id: 'item-1',
          type: SyncItemType.exerciseResult,
          data: {},
          createdAt: DateTime.now(),
        ),
      );

      expect(queue.pendingCount, equals(1));

      queue.markCompleted('item-1');

      expect(queue.pendingCount, equals(0));
    });

    test('failed items increment retry count', () {
      final queue = SyncQueue();
      final item = SyncItem(
        id: 'fail-item',
        type: SyncItemType.exerciseResult,
        data: {},
        createdAt: DateTime.now(),
      );
      queue.addItem(item);

      queue.markFailed('fail-item');
      final updatedItem = queue.getItem('fail-item');

      expect(updatedItem?.retryCount, equals(1));
    });
  });

  group('Sync Conflict Resolution', () {
    test('server wins by default for conflicts', () {
      final localData = {'score': 80, 'updatedAt': DateTime(2024, 1, 1, 10, 0)};
      final serverData = {
        'score': 85,
        'updatedAt': DateTime(2024, 1, 1, 10, 5),
      };

      final resolved = resolveConflict(
        localData: localData,
        serverData: serverData,
        strategy: ConflictStrategy.serverWins,
      );

      expect(resolved['score'], equals(85));
    });

    test('local wins strategy preserves local data', () {
      final localData = {'score': 80, 'updatedAt': DateTime(2024, 1, 1, 10, 0)};
      final serverData = {
        'score': 85,
        'updatedAt': DateTime(2024, 1, 1, 10, 5),
      };

      final resolved = resolveConflict(
        localData: localData,
        serverData: serverData,
        strategy: ConflictStrategy.localWins,
      );

      expect(resolved['score'], equals(80));
    });

    test('newest wins uses timestamp', () {
      final localData = {
        'score': 80,
        'updatedAt': DateTime(2024, 1, 1, 10, 10),
      };
      final serverData = {
        'score': 85,
        'updatedAt': DateTime(2024, 1, 1, 10, 5),
      };

      final resolved = resolveConflict(
        localData: localData,
        serverData: serverData,
        strategy: ConflictStrategy.newestWins,
      );

      // Local is newer
      expect(resolved['score'], equals(80));
    });
  });

  group('Retry Logic', () {
    test('exponential backoff calculates delay correctly', () {
      expect(
        calculateBackoff(retryCount: 0),
        equals(const Duration(seconds: 1)),
      );
      expect(
        calculateBackoff(retryCount: 1),
        equals(const Duration(seconds: 2)),
      );
      expect(
        calculateBackoff(retryCount: 2),
        equals(const Duration(seconds: 4)),
      );
      expect(
        calculateBackoff(retryCount: 3),
        equals(const Duration(seconds: 8)),
      );
    });

    test('backoff has maximum limit', () {
      final maxBackoff = calculateBackoff(retryCount: 10);
      expect(maxBackoff.inSeconds, lessThanOrEqualTo(300)); // 5 minutes max
    });

    test('items exceeding max retries are marked failed permanently', () {
      final item = SyncItem(
        id: 'max-retry',
        type: SyncItemType.exerciseResult,
        data: {},
        createdAt: DateTime.now(),
        retryCount: 5,
      );

      expect(item.shouldRetry(maxRetries: 5), isFalse);
    });

    test('items under max retries can retry', () {
      final item = SyncItem(
        id: 'retry-ok',
        type: SyncItemType.exerciseResult,
        data: {},
        createdAt: DateTime.now(),
        retryCount: 2,
      );

      expect(item.shouldRetry(maxRetries: 5), isTrue);
    });
  });

  group('Network Connectivity', () {
    test('sync pauses when offline', () {
      final syncManager = SyncManager();
      syncManager.setConnectivity(isOnline: false);

      expect(syncManager.canSync, isFalse);
    });

    test('sync resumes when online', () {
      final syncManager = SyncManager();
      syncManager.setConnectivity(isOnline: false);
      syncManager.setConnectivity(isOnline: true);

      expect(syncManager.canSync, isTrue);
    });
  });

  group('Background Sync', () {
    test('background sync state is tracked', () {
      final state = BackgroundSyncState(
        isEnabled: true,
        lastSyncAt: DateTime.now().subtract(const Duration(hours: 1)),
        nextScheduledSync: DateTime.now().add(const Duration(minutes: 15)),
      );

      expect(state.isEnabled, isTrue);
      expect(state.lastSyncAt, isNotNull);
      expect(state.nextScheduledSync, isNotNull);
    });

    test('background sync can be disabled', () {
      final state = BackgroundSyncState(
        isEnabled: false,
        lastSyncAt: null,
        nextScheduledSync: null,
      );

      expect(state.isEnabled, isFalse);
    });
  });
}

// Enums and classes for testing
enum SyncStatus { idle, syncing, completed, error }

enum SyncItemType { exerciseResult, session, userProfile }

enum ConflictStrategy { serverWins, localWins, newestWins }

class SyncState {
  SyncState._({
    required this.status,
    this.pendingCount = 0,
    this.lastSyncAt,
    this.errorMessage,
  });

  factory SyncState.idle() => SyncState._(status: SyncStatus.idle);
  factory SyncState.syncing({required int pendingCount}) =>
      SyncState._(status: SyncStatus.syncing, pendingCount: pendingCount);
  factory SyncState.completed({required DateTime lastSyncAt}) =>
      SyncState._(status: SyncStatus.completed, lastSyncAt: lastSyncAt);
  factory SyncState.error({required String message, int pendingCount = 0}) =>
      SyncState._(
        status: SyncStatus.error,
        errorMessage: message,
        pendingCount: pendingCount,
      );

  final SyncStatus status;
  final int pendingCount;
  final DateTime? lastSyncAt;
  final String? errorMessage;
}

class SyncItem {
  SyncItem({
    required this.id,
    required this.type,
    required this.data,
    required this.createdAt,
    this.retryCount = 0,
  });

  final String id;
  final SyncItemType type;
  final Map<String, dynamic> data;
  final DateTime createdAt;
  final int retryCount;

  bool shouldRetry({required int maxRetries}) => retryCount < maxRetries;

  SyncItem copyWith({int? retryCount}) => SyncItem(
    id: id,
    type: type,
    data: data,
    createdAt: createdAt,
    retryCount: retryCount ?? this.retryCount,
  );
}

class SyncQueue {
  final List<SyncItem> _items = [];

  int get pendingCount => _items.length;

  void addItem(SyncItem item) {
    _items.add(item);
    _items.sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }

  SyncItem? getNextItem() => _items.isNotEmpty ? _items.first : null;

  SyncItem? getItem(String id) {
    try {
      return _items.firstWhere((item) => item.id == id);
    } catch (_) {
      return null;
    }
  }

  List<SyncItem> getItemsByType(SyncItemType type) =>
      _items.where((item) => item.type == type).toList();

  void markCompleted(String id) {
    _items.removeWhere((item) => item.id == id);
  }

  void markFailed(String id) {
    final index = _items.indexWhere((item) => item.id == id);
    if (index != -1) {
      _items[index] = _items[index].copyWith(
        retryCount: _items[index].retryCount + 1,
      );
    }
  }
}

Map<String, dynamic> resolveConflict({
  required Map<String, dynamic> localData,
  required Map<String, dynamic> serverData,
  required ConflictStrategy strategy,
}) {
  switch (strategy) {
    case ConflictStrategy.serverWins:
      return serverData;
    case ConflictStrategy.localWins:
      return localData;
    case ConflictStrategy.newestWins:
      final localTime = localData['updatedAt'] as DateTime?;
      final serverTime = serverData['updatedAt'] as DateTime?;
      if (localTime == null) return serverData;
      if (serverTime == null) return localData;
      return localTime.isAfter(serverTime) ? localData : serverData;
  }
}

Duration calculateBackoff({required int retryCount}) {
  const maxBackoffSeconds = 300; // 5 minutes
  final backoffSeconds = (1 << retryCount).clamp(1, maxBackoffSeconds);
  return Duration(seconds: backoffSeconds);
}

class SyncManager {
  bool _isOnline = true;

  bool get canSync => _isOnline;

  void setConnectivity({required bool isOnline}) {
    _isOnline = isOnline;
  }
}

class BackgroundSyncState {
  BackgroundSyncState({
    required this.isEnabled,
    this.lastSyncAt,
    this.nextScheduledSync,
  });

  final bool isEnabled;
  final DateTime? lastSyncAt;
  final DateTime? nextScheduledSync;
}
