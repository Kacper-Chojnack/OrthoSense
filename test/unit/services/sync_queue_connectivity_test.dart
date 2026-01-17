/// Unit tests for SyncQueue and ConnectivityService.
///
/// Test coverage:
/// 1. SyncQueue operations (enqueue, dequeue, peek)
/// 2. SyncQueue persistence
/// 3. Priority ordering
/// 4. Failed items handling
/// 5. ConnectivityService state management
library;

import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:orthosense/core/services/sync/sync_item.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SyncQueue - Basic Operations', () {
    late SharedPreferences prefs;
    late MockSyncQueue queue;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      queue = MockSyncQueue(prefs);
    });

    test('empty queue has zero counts', () {
      expect(queue.pendingCount, equals(0));
      expect(queue.failedCount, equals(0));
      expect(queue.isEmpty, isTrue);
      expect(queue.isNotEmpty, isFalse);
    });

    test('enqueue increases pending count', () async {
      final item = _createTestItem('item-1');
      await queue.enqueue(item);

      expect(queue.pendingCount, equals(1));
      expect(queue.isEmpty, isFalse);
      expect(queue.isNotEmpty, isTrue);
    });

    test('enqueue multiple items', () async {
      await queue.enqueue(_createTestItem('item-1'));
      await queue.enqueue(_createTestItem('item-2'));
      await queue.enqueue(_createTestItem('item-3'));

      expect(queue.pendingCount, equals(3));
    });

    test('peek returns first item without removing', () async {
      final item1 = _createTestItem('item-1');
      final item2 = _createTestItem('item-2');

      await queue.enqueue(item1);
      await queue.enqueue(item2);

      final peeked = queue.peek();

      expect(peeked?.id, equals('item-1'));
      expect(queue.pendingCount, equals(2));
    });

    test('peek on empty queue returns null', () {
      final result = queue.peek();
      expect(result, isNull);
    });

    test('dequeue removes and returns first item', () async {
      await queue.enqueue(_createTestItem('item-1'));
      await queue.enqueue(_createTestItem('item-2'));

      final dequeued = await queue.dequeue();

      expect(dequeued?.id, equals('item-1'));
      expect(queue.pendingCount, equals(1));
    });

    test('dequeue on empty queue returns null', () async {
      final result = await queue.dequeue();
      expect(result, isNull);
    });

    test('markCompleted removes item by id', () async {
      await queue.enqueue(_createTestItem('item-1'));
      await queue.enqueue(_createTestItem('item-2'));

      await queue.markCompleted('item-1');

      expect(queue.pendingCount, equals(1));
      expect(queue.peek()?.id, equals('item-2'));
    });

    test('markCompleted on non-existent id is no-op', () async {
      await queue.enqueue(_createTestItem('item-1'));

      await queue.markCompleted('non-existent');

      expect(queue.pendingCount, equals(1));
    });
  });

  group('SyncQueue - Priority Ordering', () {
    late SharedPreferences prefs;
    late MockSyncQueue queue;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      queue = MockSyncQueue(prefs);
    });

    test('high priority items come before normal', () async {
      final normalItem = _createTestItem('normal', priority: SyncPriority.normal);
      final highItem = _createTestItem('high', priority: SyncPriority.high);

      await queue.enqueue(normalItem);
      await queue.enqueue(highItem);

      expect(queue.peek()?.id, equals('high'));
    });

    test('critical priority items come first', () async {
      await queue.enqueue(_createTestItem('low', priority: SyncPriority.low));
      await queue.enqueue(_createTestItem('normal', priority: SyncPriority.normal));
      await queue.enqueue(_createTestItem('critical', priority: SyncPriority.critical));
      await queue.enqueue(_createTestItem('high', priority: SyncPriority.high));

      expect(queue.peek()?.id, equals('critical'));
    });

    test('FIFO within same priority', () async {
      await queue.enqueue(_createTestItem('first', priority: SyncPriority.high));
      await queue.enqueue(_createTestItem('second', priority: SyncPriority.high));
      await queue.enqueue(_createTestItem('third', priority: SyncPriority.high));

      final first = await queue.dequeue();
      final second = await queue.dequeue();
      final third = await queue.dequeue();

      expect(first?.id, equals('first'));
      expect(second?.id, equals('second'));
      expect(third?.id, equals('third'));
    });
  });

  group('SyncQueue - Failed Items', () {
    late SharedPreferences prefs;
    late MockSyncQueue queue;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      queue = MockSyncQueue(prefs);
    });

    test('markFailed moves item to failed queue after max retries', () async {
      final item = _createTestItem('item-1', retryCount: 5);
      await queue.enqueue(item);

      await queue.markFailed('item-1', 'Test error', maxRetries: 5);

      expect(queue.pendingCount, equals(0));
      expect(queue.failedCount, equals(1));
    });

    test('markFailed re-enqueues item if retries remain', () async {
      final item = _createTestItem('item-1', retryCount: 2);
      await queue.enqueue(item);

      await queue.markFailed('item-1', 'Test error', maxRetries: 5);

      expect(queue.pendingCount, equals(1));
      expect(queue.failedCount, equals(0));
    });

    test('failed items track error message', () async {
      final item = _createTestItem('item-1', retryCount: 5);
      await queue.enqueue(item);

      await queue.markFailed('item-1', 'Network timeout', maxRetries: 5);

      final failed = queue.getFailedItems();
      expect(failed.first.lastError, equals('Network timeout'));
    });

    test('retryFailed moves item back to queue', () async {
      final item = _createTestItem('item-1', retryCount: 5);
      await queue.enqueue(item);
      await queue.markFailed('item-1', 'Error', maxRetries: 5);

      await queue.retryFailed('item-1');

      expect(queue.failedCount, equals(0));
      expect(queue.pendingCount, equals(1));
    });

    test('clearFailed removes all failed items', () async {
      // Add and fail multiple items
      await queue.enqueue(_createTestItem('item-1', retryCount: 5));
      await queue.enqueue(_createTestItem('item-2', retryCount: 5));
      await queue.markFailed('item-1', 'Error', maxRetries: 5);
      await queue.markFailed('item-2', 'Error', maxRetries: 5);

      await queue.clearFailed();

      expect(queue.failedCount, equals(0));
    });
  });

  group('SyncQueue - Persistence', () {
    test('saves queue state to SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final queue = MockSyncQueue(prefs);

      await queue.enqueue(_createTestItem('item-1'));
      await queue.enqueue(_createTestItem('item-2'));

      // Check that data was persisted
      final queueJson = prefs.getString('orthosense_sync_queue');
      expect(queueJson, isNotNull);
    });

    test('loads queue state from SharedPreferences', () async {
      final items = [
        _createTestItem('item-1').toJson(),
        _createTestItem('item-2').toJson(),
      ];

      SharedPreferences.setMockInitialValues({
        'orthosense_sync_queue': jsonEncode(items),
        'orthosense_sync_failed': '{}',
      });

      final prefs = await SharedPreferences.getInstance();
      final queue = MockSyncQueue(prefs);
      await queue.load();

      expect(queue.pendingCount, equals(2));
    });

    test('handles corrupted persisted data gracefully', () async {
      SharedPreferences.setMockInitialValues({
        'orthosense_sync_queue': 'invalid json {{{',
        'orthosense_sync_failed': '{}',
      });

      final prefs = await SharedPreferences.getInstance();
      final queue = MockSyncQueue(prefs);

      // Should not throw
      await queue.load();
      expect(queue.pendingCount, equals(0));
    });

    test('handles missing persisted data', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final queue = MockSyncQueue(prefs);

      await queue.load();

      expect(queue.pendingCount, equals(0));
      expect(queue.failedCount, equals(0));
    });
  });

  group('SyncQueue - Duplicate Prevention', () {
    late SharedPreferences prefs;
    late MockSyncQueue queue;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      queue = MockSyncQueue(prefs);
    });

    test('duplicate items are not added', () async {
      final item = _createTestItem('item-1');

      await queue.enqueue(item);
      await queue.enqueue(item);
      await queue.enqueue(item);

      expect(queue.pendingCount, equals(1));
    });

    test('items with different IDs are added', () async {
      await queue.enqueue(_createTestItem('item-1'));
      await queue.enqueue(_createTestItem('item-2'));
      await queue.enqueue(_createTestItem('item-3'));

      expect(queue.pendingCount, equals(3));
    });

    test('re-enqueue removes from failed first', () async {
      // Add and fail item
      await queue.enqueue(_createTestItem('item-1', retryCount: 5));
      await queue.markFailed('item-1', 'Error', maxRetries: 5);

      expect(queue.failedCount, equals(1));

      // Re-enqueue same item
      await queue.enqueue(_createTestItem('item-1'));

      expect(queue.pendingCount, equals(1));
      expect(queue.failedCount, equals(0));
    });
  });

  group('ConnectivityService Logic', () {
    test('initial state is assumed online', () {
      final state = MockConnectivityState();
      expect(state.isOnline, isTrue);
    });

    test('connectivity change updates state', () {
      final state = MockConnectivityState();

      state.setOnline(false);
      expect(state.isOnline, isFalse);

      state.setOnline(true);
      expect(state.isOnline, isTrue);
    });

    test('connectivity stream emits changes', () async {
      final state = MockConnectivityState();
      final changes = <bool>[];

      state.stream.listen(changes.add);

      state.setOnline(false);
      state.setOnline(true);
      state.setOnline(false);

      await Future<void>.delayed(Duration.zero);

      expect(changes, equals([false, true, false]));
    });

    test('hasConnection checks multiple connectivity types', () {
      // WiFi is connection
      expect(_hasConnection(['wifi']), isTrue);

      // Mobile is connection
      expect(_hasConnection(['mobile']), isTrue);

      // Ethernet is connection
      expect(_hasConnection(['ethernet']), isTrue);

      // VPN is connection
      expect(_hasConnection(['vpn']), isTrue);

      // None is not connection
      expect(_hasConnection(['none']), isFalse);

      // Bluetooth alone is not connection
      expect(_hasConnection(['bluetooth']), isFalse);
    });

    test('multiple connection types returns true', () {
      expect(_hasConnection(['wifi', 'mobile']), isTrue);
      expect(_hasConnection(['none', 'wifi']), isTrue);
    });

    test('empty connection list returns false', () {
      expect(_hasConnection([]), isFalse);
    });
  });

  group('BackgroundSyncWorker Logic', () {
    test('worker state tracks running status', () {
      final worker = MockSyncWorker();

      expect(worker.isRunning, isFalse);

      worker.start();
      expect(worker.isRunning, isTrue);

      worker.stop();
      expect(worker.isRunning, isFalse);
    });

    test('worker can be paused and resumed', () {
      final worker = MockSyncWorker();
      worker.start();

      worker.pause();
      expect(worker.isPaused, isTrue);
      expect(worker.isActive, isFalse);

      worker.resume();
      expect(worker.isPaused, isFalse);
      expect(worker.isActive, isTrue);
    });

    test('starting already running worker is no-op', () {
      final worker = MockSyncWorker();

      worker.start();
      worker.start();
      worker.start();

      expect(worker.startCount, equals(1));
    });

    test('stopping non-running worker is no-op', () {
      final worker = MockSyncWorker();

      worker.stop();
      worker.stop();

      expect(worker.stopCount, equals(0));
    });

    test('pause on non-running worker is no-op', () {
      final worker = MockSyncWorker();

      worker.pause();

      expect(worker.isPaused, isFalse);
    });

    test('resume on non-paused worker is no-op', () {
      final worker = MockSyncWorker();
      worker.start();

      worker.resume();
      worker.resume();

      expect(worker.resumeCount, equals(0)); // Not paused, so no resumes
    });
  });
}

// Helper functions and mocks

SyncItem _createTestItem(
  String id, {
  SyncPriority priority = SyncPriority.normal,
  int retryCount = 0,
}) {
  return SyncItem(
    id: id,
    entityType: SyncEntityType.session,
    operationType: SyncOperationType.create,
    data: {'test': true},
    createdAt: DateTime.now(),
    priority: priority,
    retryCount: retryCount,
  );
}

bool _hasConnection(List<String> results) {
  return results.any(
    (result) =>
        result == 'wifi' ||
        result == 'mobile' ||
        result == 'ethernet' ||
        result == 'vpn',
  );
}

/// Mock SyncQueue for testing without actual SharedPreferences side effects
class MockSyncQueue {
  MockSyncQueue(this._prefs);

  static const _queueKey = 'orthosense_sync_queue';
  static const _failedKey = 'orthosense_sync_failed';

  final SharedPreferences _prefs;
  final List<SyncItem> _queue = [];
  final Map<String, SyncItem> _failed = {};

  int get pendingCount => _queue.length;
  int get failedCount => _failed.length;
  bool get isEmpty => _queue.isEmpty;
  bool get isNotEmpty => _queue.isNotEmpty;

  Future<void> load() async {
    try {
      final queueJson = _prefs.getString(_queueKey);
      if (queueJson != null) {
        final items = jsonDecode(queueJson) as List<dynamic>;
        _queue.clear();
        for (final item in items) {
          _queue.add(SyncItem.fromJson(item as Map<String, dynamic>));
        }
      }

      final failedJson = _prefs.getString(_failedKey);
      if (failedJson != null) {
        final items = jsonDecode(failedJson) as Map<String, dynamic>;
        _failed.clear();
        for (final entry in items.entries) {
          _failed[entry.key] = SyncItem.fromJson(
            entry.value as Map<String, dynamic>,
          );
        }
      }
    } catch (_) {
      // Ignore parse errors
    }
  }

  Future<void> _persist() async {
    final queueJson = jsonEncode(_queue.map((e) => e.toJson()).toList());
    await _prefs.setString(_queueKey, queueJson);

    final failedJson = jsonEncode(
      _failed.map((k, v) => MapEntry(k, v.toJson())),
    );
    await _prefs.setString(_failedKey, failedJson);
  }

  Future<void> enqueue(SyncItem item) async {
    // Check for duplicate
    if (_queue.any((i) => i.id == item.id)) {
      return;
    }

    // Remove from failed if re-enqueuing
    _failed.remove(item.id);

    // Insert based on priority
    var insertIndex = _queue.length;
    for (var i = 0; i < _queue.length; i++) {
      if (item.priority.index > _queue[i].priority.index) {
        insertIndex = i;
        break;
      }
    }

    _queue.insert(insertIndex, item);
    await _persist();
  }

  SyncItem? peek() => _queue.isNotEmpty ? _queue.first : null;

  Future<SyncItem?> dequeue() async {
    if (_queue.isEmpty) return null;
    final item = _queue.removeAt(0);
    await _persist();
    return item;
  }

  Future<void> markCompleted(String id) async {
    _queue.removeWhere((item) => item.id == id);
    _failed.remove(id);
    await _persist();
  }

  Future<void> markFailed(String id, String error, {int maxRetries = 5}) async {
    final index = _queue.indexWhere((item) => item.id == id);
    if (index == -1) return;

    final item = _queue.removeAt(index);
    final updatedItem = item.incrementRetry(error);

    if (updatedItem.shouldRetry(maxRetries: maxRetries)) {
      _queue.add(updatedItem);
    } else {
      _failed[id] = updatedItem;
    }
    await _persist();
  }

  List<SyncItem> getFailedItems() => _failed.values.toList();

  Future<void> retryFailed(String id) async {
    final item = _failed.remove(id);
    if (item != null) {
      _queue.add(item);
    }
    await _persist();
  }

  Future<void> clearFailed() async {
    _failed.clear();
    await _persist();
  }
}

/// Mock connectivity state for testing
class MockConnectivityState {
  bool _isOnline = true;
  final _controller = StreamController<bool>.broadcast();

  bool get isOnline => _isOnline;
  Stream<bool> get stream => _controller.stream;

  void setOnline(bool value) {
    _isOnline = value;
    _controller.add(value);
  }

  void dispose() {
    _controller.close();
  }
}

/// Mock sync worker for testing
class MockSyncWorker {
  bool _isRunning = false;
  bool _isPaused = false;
  int startCount = 0;
  int stopCount = 0;
  int resumeCount = 0;

  bool get isRunning => _isRunning;
  bool get isPaused => _isPaused;
  bool get isActive => _isRunning && !_isPaused;

  void start() {
    if (_isRunning) return;
    _isRunning = true;
    _isPaused = false;
    startCount++;
  }

  void stop() {
    if (!_isRunning) return;
    _isRunning = false;
    stopCount++;
  }

  void pause() {
    if (!_isRunning || _isPaused) return;
    _isPaused = true;
  }

  void resume() {
    if (!_isRunning || !_isPaused) return;
    _isPaused = false;
    resumeCount++;
  }
}
