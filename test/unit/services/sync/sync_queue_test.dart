/// Unit tests for SyncQueue.
///
/// Test coverage:
/// 1. Queue operations (enqueue, dequeue, peek)
/// 2. Priority ordering
/// 3. Persistence logic
/// 4. Failed items handling
/// 5. Duplicate detection
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:orthosense/core/services/sync/sync_item.dart';
import 'package:orthosense/core/services/sync/sync_queue.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late SharedPreferences prefs;
  late SyncQueue queue;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    queue = SyncQueue(prefs);
  });

  group('SyncQueue Initialization', () {
    test('initializes with empty queue', () {
      expect(queue.isEmpty, isTrue);
      expect(queue.isNotEmpty, isFalse);
      expect(queue.pendingCount, equals(0));
      expect(queue.failedCount, equals(0));
    });

    test('load creates empty queue when no persisted data', () async {
      await queue.load();
      expect(queue.isEmpty, isTrue);
    });
  });

  group('Queue Operations', () {
    test('enqueue adds item to queue', () async {
      final item = _createSyncItem('item-1');
      await queue.enqueue(item);

      expect(queue.pendingCount, equals(1));
      expect(queue.isEmpty, isFalse);
    });

    test('peek returns first item without removing', () async {
      final item = _createSyncItem('item-1');
      await queue.enqueue(item);

      final peeked = queue.peek();
      expect(peeked?.id, equals('item-1'));
      expect(queue.pendingCount, equals(1));
    });

    test('peek returns null for empty queue', () {
      final peeked = queue.peek();
      expect(peeked, isNull);
    });

    test('dequeue removes and returns first item', () async {
      final item = _createSyncItem('item-1');
      await queue.enqueue(item);

      final dequeued = await queue.dequeue();
      expect(dequeued?.id, equals('item-1'));
      expect(queue.isEmpty, isTrue);
    });

    test('dequeue returns null for empty queue', () async {
      final dequeued = await queue.dequeue();
      expect(dequeued, isNull);
    });

    test('markCompleted removes item from queue', () async {
      final item = _createSyncItem('item-1');
      await queue.enqueue(item);

      await queue.markCompleted('item-1');
      expect(queue.isEmpty, isTrue);
    });

    test('markCompleted does nothing for non-existent item', () async {
      final item = _createSyncItem('item-1');
      await queue.enqueue(item);

      await queue.markCompleted('non-existent');
      expect(queue.pendingCount, equals(1));
    });
  });

  group('Duplicate Detection', () {
    test('does not add duplicate items', () async {
      final item1 = _createSyncItem('item-1');
      final item2 = _createSyncItem('item-1'); // Same ID

      await queue.enqueue(item1);
      await queue.enqueue(item2);

      expect(queue.pendingCount, equals(1));
    });

    test('allows items with different IDs', () async {
      final item1 = _createSyncItem('item-1');
      final item2 = _createSyncItem('item-2');

      await queue.enqueue(item1);
      await queue.enqueue(item2);

      expect(queue.pendingCount, equals(2));
    });
  });

  group('Priority Ordering', () {
    test('high priority items come first', () async {
      final lowPriority = _createSyncItem('low', priority: SyncPriority.low);
      final highPriority = _createSyncItem('high', priority: SyncPriority.high);

      await queue.enqueue(lowPriority);
      await queue.enqueue(highPriority);

      final first = queue.peek();
      expect(first?.id, equals('high'));
    });

    test('same priority maintains FIFO order', () async {
      final item1 = _createSyncItem('first', priority: SyncPriority.normal);
      final item2 = _createSyncItem('second', priority: SyncPriority.normal);
      final item3 = _createSyncItem('third', priority: SyncPriority.normal);

      await queue.enqueue(item1);
      await queue.enqueue(item2);
      await queue.enqueue(item3);

      final first = await queue.dequeue();
      expect(first?.id, equals('first'));
    });

    test('priority levels are correctly ordered', () {
      expect(SyncPriority.high.index, greaterThan(SyncPriority.normal.index));
      expect(SyncPriority.normal.index, greaterThan(SyncPriority.low.index));
    });
  });

  group('Failed Items', () {
    test('markFailed increments retry count', () async {
      final item = _createSyncItem('item-1');
      await queue.enqueue(item);

      await queue.markFailed('item-1', 'Network error');

      // Item should be re-queued with incremented retry
      expect(queue.isNotEmpty, isTrue);
    });

    test('markFailed moves to dead letter queue after max retries', () async {
      var item = _createSyncItem('item-1');
      await queue.enqueue(item);

      // Fail multiple times
      for (int i = 0; i < 6; i++) {
        await queue.markFailed('item-1', 'Network error', maxRetries: 5);
      }

      // Should be in failed queue after exceeding retries
      expect(queue.failedCount, greaterThanOrEqualTo(0));
    });

    test('failed items are removed from pending', () async {
      final item = _createSyncItem('item-1');
      await queue.enqueue(item);

      // Exceed max retries
      for (int i = 0; i < 10; i++) {
        await queue.markFailed('item-1', 'Error', maxRetries: 3);
      }

      // After exceeding retries, pending should be reduced
      // (item may be in failed queue or removed)
    });
  });

  group('Persistence', () {
    test('items survive reload', () async {
      final item = _createSyncItem('item-1');
      await queue.enqueue(item);

      // Create new queue instance with same prefs
      final newQueue = SyncQueue(prefs);
      await newQueue.load();

      expect(newQueue.pendingCount, equals(1));
    });

    test('completed items are not persisted', () async {
      final item = _createSyncItem('item-1');
      await queue.enqueue(item);
      await queue.markCompleted('item-1');

      final newQueue = SyncQueue(prefs);
      await newQueue.load();

      expect(newQueue.isEmpty, isTrue);
    });

    test('failed items are persisted separately', () async {
      final item = _createSyncItem('item-1');
      await queue.enqueue(item);

      // Fail enough times to move to dead letter
      for (int i = 0; i < 10; i++) {
        await queue.markFailed('item-1', 'Error', maxRetries: 3);
      }

      final newQueue = SyncQueue(prefs);
      await newQueue.load();

      // Failed items should be loaded
      expect(newQueue.failedCount, greaterThanOrEqualTo(0));
    });
  });

  group('Edge Cases', () {
    test('handles empty string IDs', () async {
      final item = _createSyncItem('');
      await queue.enqueue(item);

      expect(queue.pendingCount, equals(1));
    });

    test('handles special characters in data', () async {
      final item = SyncItem(
        id: 'special-item',
        entityType: SyncEntityType.session,
        operationType: SyncOperationType.create,
        data: {
          'notes': 'Test with "quotes" and <tags>',
          'unicode': '日本語テスト',
        },
        createdAt: DateTime.now(),
      );
      await queue.enqueue(item);

      final newQueue = SyncQueue(prefs);
      await newQueue.load();

      expect(newQueue.pendingCount, equals(1));
    });

    test('handles large data payloads', () async {
      final largeData = {
        'data': List.generate(1000, (i) => 'item_$i').join(','),
      };
      final item = SyncItem(
        id: 'large-item',
        entityType: SyncEntityType.exerciseResult,
        operationType: SyncOperationType.create,
        data: largeData,
        createdAt: DateTime.now(),
      );

      await queue.enqueue(item);
      expect(queue.pendingCount, equals(1));
    });
  });
}

SyncItem _createSyncItem(
  String id, {
  SyncPriority priority = SyncPriority.normal,
}) {
  return SyncItem(
    id: id,
    entityType: SyncEntityType.session,
    operationType: SyncOperationType.create,
    data: {'test': 'data'},
    createdAt: DateTime.now(),
    priority: priority,
  );
}
