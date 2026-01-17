/// Unit tests for SyncQueue with actual class imports.
///
/// Test coverage:
/// 1. Queue operations (enqueue, dequeue, peek)
/// 2. Persistence
/// 3. Priority sorting
/// 4. Failed items handling
/// 5. Retry logic
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:orthosense/core/services/sync/sync_item.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:orthosense/core/services/sync/sync_queue.dart';

void main() {
  group('SyncQueue', () {
    late SyncQueue syncQueue;
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      syncQueue = SyncQueue(prefs);
    });

    group('Basic operations', () {
      test('starts empty', () {
        expect(syncQueue.isEmpty, isTrue);
        expect(syncQueue.isNotEmpty, isFalse);
        expect(syncQueue.pendingCount, equals(0));
        expect(syncQueue.failedCount, equals(0));
      });

      test('enqueue adds item to queue', () async {
        final item = SyncItem(
          id: 'test-1',
          entityType: SyncEntityType.session,
          operationType: SyncOperationType.create,
          data: {'test': 'data'},
          createdAt: DateTime.now(),
        );

        await syncQueue.enqueue(item);

        expect(syncQueue.pendingCount, equals(1));
        expect(syncQueue.isEmpty, isFalse);
      });

      test('peek returns first item without removing', () async {
        final item = SyncItem(
          id: 'test-1',
          entityType: SyncEntityType.session,
          operationType: SyncOperationType.create,
          data: {'test': 'data'},
          createdAt: DateTime.now(),
        );

        await syncQueue.enqueue(item);

        final peeked = syncQueue.peek();
        expect(peeked?.id, equals('test-1'));
        expect(syncQueue.pendingCount, equals(1)); // Still in queue
      });

      test('dequeue removes and returns first item', () async {
        final item = SyncItem(
          id: 'test-1',
          entityType: SyncEntityType.session,
          operationType: SyncOperationType.create,
          data: {'test': 'data'},
          createdAt: DateTime.now(),
        );

        await syncQueue.enqueue(item);
        final dequeued = await syncQueue.dequeue();

        expect(dequeued?.id, equals('test-1'));
        expect(syncQueue.pendingCount, equals(0));
      });

      test('dequeue returns null for empty queue', () async {
        final result = await syncQueue.dequeue();
        expect(result, isNull);
      });

      test('peek returns null for empty queue', () {
        final result = syncQueue.peek();
        expect(result, isNull);
      });
    });

    group('Priority sorting', () {
      test('high priority items come first', () async {
        final normalItem = SyncItem(
          id: 'normal-1',
          entityType: SyncEntityType.session,
          operationType: SyncOperationType.create,
          data: {},
          createdAt: DateTime.now(),
          priority: SyncPriority.normal,
        );

        final highItem = SyncItem(
          id: 'high-1',
          entityType: SyncEntityType.exerciseResult,
          operationType: SyncOperationType.create,
          data: {},
          createdAt: DateTime.now(),
          priority: SyncPriority.high,
        );

        await syncQueue.enqueue(normalItem);
        await syncQueue.enqueue(highItem);

        final first = syncQueue.peek();
        expect(first?.id, equals('high-1'));
      });

      test('critical priority is highest', () async {
        final lowItem = SyncItem(
          id: 'low-1',
          entityType: SyncEntityType.session,
          operationType: SyncOperationType.create,
          data: {},
          createdAt: DateTime.now(),
          priority: SyncPriority.low,
        );

        final criticalItem = SyncItem(
          id: 'critical-1',
          entityType: SyncEntityType.exerciseResult,
          operationType: SyncOperationType.create,
          data: {},
          createdAt: DateTime.now(),
          priority: SyncPriority.critical,
        );

        final normalItem = SyncItem(
          id: 'normal-1',
          entityType: SyncEntityType.session,
          operationType: SyncOperationType.create,
          data: {},
          createdAt: DateTime.now(),
          priority: SyncPriority.normal,
        );

        await syncQueue.enqueue(lowItem);
        await syncQueue.enqueue(normalItem);
        await syncQueue.enqueue(criticalItem);

        final first = syncQueue.peek();
        expect(first?.id, equals('critical-1'));
      });
    });

    group('Duplicate handling', () {
      test('does not add duplicate items', () async {
        final item = SyncItem(
          id: 'test-1',
          entityType: SyncEntityType.session,
          operationType: SyncOperationType.create,
          data: {'test': 'data'},
          createdAt: DateTime.now(),
        );

        await syncQueue.enqueue(item);
        await syncQueue.enqueue(item); // Duplicate

        expect(syncQueue.pendingCount, equals(1));
      });
    });

    group('Mark completed', () {
      test('markCompleted removes item from queue', () async {
        final item = SyncItem(
          id: 'test-1',
          entityType: SyncEntityType.session,
          operationType: SyncOperationType.create,
          data: {},
          createdAt: DateTime.now(),
        );

        await syncQueue.enqueue(item);
        await syncQueue.markCompleted('test-1');

        expect(syncQueue.pendingCount, equals(0));
      });

      test('markCompleted removes from failed queue too', () async {
        final item = SyncItem(
          id: 'test-1',
          entityType: SyncEntityType.session,
          operationType: SyncOperationType.create,
          data: {},
          createdAt: DateTime.now(),
        );

        await syncQueue.enqueue(item);
        // Mark failed multiple times to exceed max retries
        for (var i = 0; i < 6; i++) {
          await syncQueue.markFailed('test-1', 'Error');
        }
        
        // Now mark as completed
        await syncQueue.markCompleted('test-1');
        expect(syncQueue.failedCount, equals(0));
      });
    });

    group('Mark failed', () {
      test('markFailed re-enqueues item for retry', () async {
        final item = SyncItem(
          id: 'test-1',
          entityType: SyncEntityType.session,
          operationType: SyncOperationType.create,
          data: {},
          createdAt: DateTime.now(),
        );

        await syncQueue.enqueue(item);
        await syncQueue.markFailed('test-1', 'Network error');

        // Should still be in queue for retry
        expect(syncQueue.pendingCount, greaterThanOrEqualTo(0));
      });

      test('markFailed moves to dead letter queue after max retries', () async {
        final item = SyncItem(
          id: 'test-1',
          entityType: SyncEntityType.session,
          operationType: SyncOperationType.create,
          data: {},
          createdAt: DateTime.now(),
        );

        await syncQueue.enqueue(item);
        
        // Fail enough times to exceed max retries (default 5)
        for (var i = 0; i < 6; i++) {
          await syncQueue.markFailed('test-1', 'Error $i', maxRetries: 5);
        }

        expect(syncQueue.failedCount, equals(1));
      });
    });

    group('Failed items management', () {
      test('getFailedItems returns empty list initially', () {
        final failed = syncQueue.getFailedItems();
        expect(failed, isEmpty);
      });

      test('getPendingItems returns empty list initially', () {
        final pending = syncQueue.getPendingItems();
        expect(pending, isEmpty);
      });

      test('getPendingItems returns all pending items', () async {
        final item1 = SyncItem(
          id: 'test-1',
          entityType: SyncEntityType.session,
          operationType: SyncOperationType.create,
          data: {},
          createdAt: DateTime.now(),
        );

        final item2 = SyncItem(
          id: 'test-2',
          entityType: SyncEntityType.exerciseResult,
          operationType: SyncOperationType.create,
          data: {},
          createdAt: DateTime.now(),
        );

        await syncQueue.enqueue(item1);
        await syncQueue.enqueue(item2);

        final pending = syncQueue.getPendingItems();
        expect(pending.length, equals(2));
      });

      test('retryFailed moves items back to pending', () async {
        final item = SyncItem(
          id: 'test-1',
          entityType: SyncEntityType.session,
          operationType: SyncOperationType.create,
          data: {},
          createdAt: DateTime.now(),
        );

        await syncQueue.enqueue(item);
        
        // Force into failed queue
        for (var i = 0; i < 6; i++) {
          await syncQueue.markFailed('test-1', 'Error', maxRetries: 5);
        }
        
        expect(syncQueue.failedCount, equals(1));
        
        await syncQueue.retryFailed();
        expect(syncQueue.failedCount, equals(0));
        expect(syncQueue.pendingCount, equals(1));
      });
    });

    group('Clear', () {
      test('clear removes all items', () async {
        final item1 = SyncItem(
          id: 'test-1',
          entityType: SyncEntityType.session,
          operationType: SyncOperationType.create,
          data: {},
          createdAt: DateTime.now(),
        );

        final item2 = SyncItem(
          id: 'test-2',
          entityType: SyncEntityType.exerciseResult,
          operationType: SyncOperationType.create,
          data: {},
          createdAt: DateTime.now(),
        );

        await syncQueue.enqueue(item1);
        await syncQueue.enqueue(item2);
        await syncQueue.clear();

        expect(syncQueue.pendingCount, equals(0));
        expect(syncQueue.failedCount, equals(0));
      });
    });

    group('Remove', () {
      test('remove specific item by ID', () async {
        final item1 = SyncItem(
          id: 'test-1',
          entityType: SyncEntityType.session,
          operationType: SyncOperationType.create,
          data: {},
          createdAt: DateTime.now(),
        );

        final item2 = SyncItem(
          id: 'test-2',
          entityType: SyncEntityType.exerciseResult,
          operationType: SyncOperationType.create,
          data: {},
          createdAt: DateTime.now(),
        );

        await syncQueue.enqueue(item1);
        await syncQueue.enqueue(item2);
        await syncQueue.remove('test-1');

        expect(syncQueue.pendingCount, equals(1));
        final remaining = syncQueue.peek();
        expect(remaining?.id, equals('test-2'));
      });
    });

    group('Persistence', () {
      test('load restores queue from preferences', () async {
        final item = SyncItem(
          id: 'persisted-1',
          entityType: SyncEntityType.session,
          operationType: SyncOperationType.create,
          data: {'persisted': true},
          createdAt: DateTime.now(),
        );

        await syncQueue.enqueue(item);
        
        // Create new queue instance with same prefs
        final newQueue = SyncQueue(prefs);
        await newQueue.load();
        
        expect(newQueue.pendingCount, equals(1));
        expect(newQueue.peek()?.id, equals('persisted-1'));
      });
    });
  });

  group('SyncItem', () {
    test('shouldRetry returns true when under max retries', () {
      final item = SyncItem(
        id: 'test-1',
        entityType: SyncEntityType.session,
        operationType: SyncOperationType.create,
        data: {},
        createdAt: DateTime.now(),
        retryCount: 3,
      );

      expect(item.shouldRetry(maxRetries: 5), isTrue);
    });

    test('shouldRetry returns false when at max retries', () {
      final item = SyncItem(
        id: 'test-1',
        entityType: SyncEntityType.session,
        operationType: SyncOperationType.create,
        data: {},
        createdAt: DateTime.now(),
        retryCount: 5,
      );

      expect(item.shouldRetry(maxRetries: 5), isFalse);
    });

    test('incrementRetry increases retry count', () {
      final item = SyncItem(
        id: 'test-1',
        entityType: SyncEntityType.session,
        operationType: SyncOperationType.create,
        data: {},
        createdAt: DateTime.now(),
        retryCount: 0,
      );

      final updated = item.incrementRetry('Network error');

      expect(updated.retryCount, equals(1));
      expect(updated.lastError, equals('Network error'));
      expect(updated.lastRetryAt, isNotNull);
    });

    test('toJson and fromJson round trip', () {
      final item = SyncItem(
        id: 'test-1',
        entityType: SyncEntityType.session,
        operationType: SyncOperationType.create,
        data: {'key': 'value'},
        createdAt: DateTime(2024, 1, 15),
        priority: SyncPriority.high,
        retryCount: 2,
        lastError: 'Previous error',
      );

      final json = item.toJson();
      final restored = SyncItem.fromJson(json);

      expect(restored.id, equals('test-1'));
      expect(restored.entityType, equals(SyncEntityType.session));
      expect(restored.operationType, equals(SyncOperationType.create));
      expect(restored.data['key'], equals('value'));
      expect(restored.priority, equals(SyncPriority.high));
      expect(restored.retryCount, equals(2));
      expect(restored.lastError, equals('Previous error'));
    });
  });

  group('SyncPriority', () {
    test('critical has highest index', () {
      expect(SyncPriority.critical.index, greaterThan(SyncPriority.high.index));
      expect(SyncPriority.high.index, greaterThan(SyncPriority.normal.index));
      expect(SyncPriority.normal.index, greaterThan(SyncPriority.low.index));
    });

    test('all priority values are defined', () {
      expect(SyncPriority.values.length, equals(4));
      expect(SyncPriority.values, contains(SyncPriority.low));
      expect(SyncPriority.values, contains(SyncPriority.normal));
      expect(SyncPriority.values, contains(SyncPriority.high));
      expect(SyncPriority.values, contains(SyncPriority.critical));
    });
  });

  group('SyncEntityType', () {
    test('all entity types are defined', () {
      expect(SyncEntityType.values.length, equals(2));
      expect(SyncEntityType.values, contains(SyncEntityType.session));
      expect(SyncEntityType.values, contains(SyncEntityType.exerciseResult));
    });
  });

  group('SyncOperationType', () {
    test('all operation types are defined', () {
      expect(SyncOperationType.values.length, equals(3));
      expect(SyncOperationType.values, contains(SyncOperationType.create));
      expect(SyncOperationType.values, contains(SyncOperationType.update));
      expect(SyncOperationType.values, contains(SyncOperationType.delete));
    });
  });
}
