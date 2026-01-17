/// Unit tests for Sync models (SyncItem, SyncState, ExponentialBackoff).
///
/// Test coverage:
/// 1. SyncItem model - creation, serialization, retry logic
/// 2. SyncState model - status, computed properties
/// 3. ExponentialBackoff - delay calculations
/// 4. SyncOperationType and SyncEntityType enums
/// 5. SyncPriority enum
/// 6. SyncStatus enum
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:orthosense/core/services/sync/exponential_backoff.dart';
import 'package:orthosense/core/services/sync/sync_item.dart';
import 'package:orthosense/core/services/sync/sync_state.dart';

void main() {
  group('SyncItem', () {
    test('creates instance with required fields', () {
      final now = DateTime.now();
      final item = SyncItem(
        id: 'test-id',
        entityType: SyncEntityType.session,
        operationType: SyncOperationType.create,
        data: {'key': 'value'},
        createdAt: now,
      );

      expect(item.id, equals('test-id'));
      expect(item.entityType, equals(SyncEntityType.session));
      expect(item.operationType, equals(SyncOperationType.create));
      expect(item.data, equals({'key': 'value'}));
      expect(item.createdAt, equals(now));
      expect(item.priority, equals(SyncPriority.normal));
      expect(item.retryCount, equals(0));
      expect(item.lastError, isNull);
      expect(item.lastRetryAt, isNull);
    });

    test('creates instance with custom priority', () {
      final item = SyncItem(
        id: 'test-id',
        entityType: SyncEntityType.exerciseResult,
        operationType: SyncOperationType.update,
        data: {},
        createdAt: DateTime.now(),
        priority: SyncPriority.high,
      );

      expect(item.priority, equals(SyncPriority.high));
    });

    test('creates instance with critical priority', () {
      final item = SyncItem(
        id: 'test-id',
        entityType: SyncEntityType.session,
        operationType: SyncOperationType.delete,
        data: {},
        createdAt: DateTime.now(),
        priority: SyncPriority.critical,
      );

      expect(item.priority, equals(SyncPriority.critical));
    });

    test('shouldRetry returns true when retryCount is below max', () {
      final item = SyncItem(
        id: 'test-id',
        entityType: SyncEntityType.session,
        operationType: SyncOperationType.create,
        data: {},
        createdAt: DateTime.now(),
        retryCount: 2,
      );

      expect(item.shouldRetry(maxRetries: 5), isTrue);
    });

    test('shouldRetry returns false when retryCount equals max', () {
      final item = SyncItem(
        id: 'test-id',
        entityType: SyncEntityType.session,
        operationType: SyncOperationType.create,
        data: {},
        createdAt: DateTime.now(),
        retryCount: 5,
      );

      expect(item.shouldRetry(maxRetries: 5), isFalse);
    });

    test('shouldRetry returns false when retryCount exceeds max', () {
      final item = SyncItem(
        id: 'test-id',
        entityType: SyncEntityType.session,
        operationType: SyncOperationType.create,
        data: {},
        createdAt: DateTime.now(),
        retryCount: 10,
      );

      expect(item.shouldRetry(maxRetries: 5), isFalse);
    });

    test('incrementRetry increases retryCount and sets error', () {
      final item = SyncItem(
        id: 'test-id',
        entityType: SyncEntityType.session,
        operationType: SyncOperationType.create,
        data: {},
        createdAt: DateTime.now(),
      );

      final updated = item.incrementRetry('Network error');

      expect(updated.retryCount, equals(1));
      expect(updated.lastError, equals('Network error'));
      expect(updated.lastRetryAt, isNotNull);
      expect(updated.id, equals(item.id)); // Other fields unchanged
    });

    test('incrementRetry can be called multiple times', () {
      var item = SyncItem(
        id: 'test-id',
        entityType: SyncEntityType.session,
        operationType: SyncOperationType.create,
        data: {},
        createdAt: DateTime.now(),
      );

      item = item.incrementRetry('Error 1');
      item = item.incrementRetry('Error 2');
      item = item.incrementRetry('Error 3');

      expect(item.retryCount, equals(3));
      expect(item.lastError, equals('Error 3'));
    });

    test('toJson and fromJson round-trip', () {
      final now = DateTime.now();
      final original = SyncItem(
        id: 'test-id-123',
        entityType: SyncEntityType.exerciseResult,
        operationType: SyncOperationType.update,
        data: {'exercise': 'squat', 'score': 85},
        createdAt: now,
        priority: SyncPriority.high,
        retryCount: 2,
        lastError: 'Previous error',
        lastRetryAt: now.subtract(const Duration(minutes: 5)),
      );

      final json = original.toJson();
      final restored = SyncItem.fromJson(json);

      expect(restored.id, equals(original.id));
      expect(restored.entityType, equals(original.entityType));
      expect(restored.operationType, equals(original.operationType));
      expect(restored.data, equals(original.data));
      expect(restored.priority, equals(original.priority));
      expect(restored.retryCount, equals(original.retryCount));
      expect(restored.lastError, equals(original.lastError));
    });

    test('handles empty data map', () {
      final item = SyncItem(
        id: 'test-id',
        entityType: SyncEntityType.session,
        operationType: SyncOperationType.delete,
        data: {},
        createdAt: DateTime.now(),
      );

      expect(item.data, isEmpty);
      final json = item.toJson();
      expect(json['data'], isEmpty);
    });

    test('handles complex nested data', () {
      final item = SyncItem(
        id: 'test-id',
        entityType: SyncEntityType.exerciseResult,
        operationType: SyncOperationType.create,
        data: {
          'nested': {
            'level1': {
              'level2': ['a', 'b', 'c'],
            },
          },
          'list': [1, 2, 3],
          'boolean': true,
        },
        createdAt: DateTime.now(),
      );

      final json = item.toJson();
      final restored = SyncItem.fromJson(json);

      expect(restored.data['nested']['level1']['level2'], equals(['a', 'b', 'c']));
      expect(restored.data['list'], equals([1, 2, 3]));
      expect(restored.data['boolean'], isTrue);
    });
  });

  group('SyncOperationType', () {
    test('has correct values', () {
      expect(SyncOperationType.values.length, equals(3));
      expect(SyncOperationType.create.name, equals('create'));
      expect(SyncOperationType.update.name, equals('update'));
      expect(SyncOperationType.delete.name, equals('delete'));
    });
  });

  group('SyncPriority', () {
    test('has correct values and order', () {
      expect(SyncPriority.values.length, equals(4));
      expect(SyncPriority.low.index, lessThan(SyncPriority.normal.index));
      expect(SyncPriority.normal.index, lessThan(SyncPriority.high.index));
      expect(SyncPriority.high.index, lessThan(SyncPriority.critical.index));
    });
  });

  group('SyncEntityType', () {
    test('has correct values', () {
      expect(SyncEntityType.values.length, equals(2));
      expect(SyncEntityType.session.name, equals('session'));
      expect(SyncEntityType.exerciseResult.name, equals('exerciseResult'));
    });
  });

  group('SyncState', () {
    test('creates default instance', () {
      const state = SyncState();

      expect(state.status, equals(SyncStatus.idle));
      expect(state.pendingCount, equals(0));
      expect(state.failedCount, equals(0));
      expect(state.lastSyncAt, isNull);
      expect(state.errorMessage, isNull);
      expect(state.isOnline, isFalse);
    });

    test('creates instance with custom values', () {
      final now = DateTime.now();
      final state = SyncState(
        status: SyncStatus.syncing,
        pendingCount: 5,
        failedCount: 2,
        lastSyncAt: now,
        errorMessage: 'Test error',
        isOnline: true,
      );

      expect(state.status, equals(SyncStatus.syncing));
      expect(state.pendingCount, equals(5));
      expect(state.failedCount, equals(2));
      expect(state.lastSyncAt, equals(now));
      expect(state.errorMessage, equals('Test error'));
      expect(state.isOnline, isTrue);
    });

    test('canSync returns true when online and not syncing', () {
      const state = SyncState(
        status: SyncStatus.idle,
        isOnline: true,
      );

      expect(state.canSync, isTrue);
    });

    test('canSync returns false when offline', () {
      const state = SyncState(
        status: SyncStatus.idle,
        isOnline: false,
      );

      expect(state.canSync, isFalse);
    });

    test('canSync returns false when already syncing', () {
      const state = SyncState(
        status: SyncStatus.syncing,
        isOnline: true,
      );

      expect(state.canSync, isFalse);
    });

    test('hasPendingItems returns correct value', () {
      const stateNoPending = SyncState(pendingCount: 0);
      const stateWithPending = SyncState(pendingCount: 3);

      expect(stateNoPending.hasPendingItems, isFalse);
      expect(stateWithPending.hasPendingItems, isTrue);
    });

    test('hasFailedItems returns correct value', () {
      const stateNoFailed = SyncState(failedCount: 0);
      const stateWithFailed = SyncState(failedCount: 2);

      expect(stateNoFailed.hasFailedItems, isFalse);
      expect(stateWithFailed.hasFailedItems, isTrue);
    });

    test('statusMessage returns correct message for idle with pending', () {
      const state = SyncState(
        status: SyncStatus.idle,
        pendingCount: 5,
      );

      expect(state.statusMessage, equals('5 pending'));
    });

    test('statusMessage returns "All synced" for idle without pending', () {
      const state = SyncState(
        status: SyncStatus.idle,
        pendingCount: 0,
      );

      expect(state.statusMessage, equals('All synced'));
    });

    test('statusMessage returns "Syncing..." when syncing', () {
      const state = SyncState(status: SyncStatus.syncing);

      expect(state.statusMessage, equals('Syncing...'));
    });

    test('statusMessage returns error message when in error state', () {
      const state = SyncState(
        status: SyncStatus.error,
        errorMessage: 'Connection failed',
      );

      expect(state.statusMessage, equals('Connection failed'));
    });

    test('statusMessage returns "Sync error" when error without message', () {
      const state = SyncState(status: SyncStatus.error);

      expect(state.statusMessage, equals('Sync error'));
    });

    test('statusMessage returns "Offline" when offline', () {
      const state = SyncState(status: SyncStatus.offline);

      expect(state.statusMessage, equals('Offline'));
    });

    test('copyWith creates new instance with updated values', () {
      const original = SyncState(
        status: SyncStatus.idle,
        pendingCount: 5,
        isOnline: true,
      );

      final updated = original.copyWith(
        status: SyncStatus.syncing,
        pendingCount: 4,
      );

      expect(updated.status, equals(SyncStatus.syncing));
      expect(updated.pendingCount, equals(4));
      expect(updated.isOnline, isTrue); // Unchanged
    });
  });

  group('SyncStatus', () {
    test('has correct values', () {
      expect(SyncStatus.values.length, equals(4));
      expect(SyncStatus.idle.name, equals('idle'));
      expect(SyncStatus.syncing.name, equals('syncing'));
      expect(SyncStatus.error.name, equals('error'));
      expect(SyncStatus.offline.name, equals('offline'));
    });
  });

  group('ExponentialBackoff', () {
    test('creates instance with default values', () {
      final backoff = ExponentialBackoff();

      expect(backoff.baseDelay, equals(const Duration(seconds: 1)));
      expect(backoff.maxDelay, equals(const Duration(minutes: 5)));
      expect(backoff.jitterFactor, equals(0.2));
    });

    test('creates instance with custom values', () {
      final backoff = ExponentialBackoff(
        baseDelay: const Duration(milliseconds: 500),
        maxDelay: const Duration(minutes: 10),
        jitterFactor: 0.3,
      );

      expect(backoff.baseDelay, equals(const Duration(milliseconds: 500)));
      expect(backoff.maxDelay, equals(const Duration(minutes: 10)));
      expect(backoff.jitterFactor, equals(0.3));
    });

    test('getDelay returns base delay for attempt 0', () {
      final backoff = ExponentialBackoff(
        baseDelay: const Duration(seconds: 1),
      );

      final delay = backoff.getDelay(attempt: 0);
      expect(delay, equals(const Duration(seconds: 1)));
    });

    test('getDelay doubles for each attempt', () {
      final backoff = ExponentialBackoff(
        baseDelay: const Duration(seconds: 1),
        maxDelay: const Duration(hours: 1),
      );

      expect(backoff.getDelay(attempt: 0), equals(const Duration(seconds: 1)));
      expect(backoff.getDelay(attempt: 1), equals(const Duration(seconds: 2)));
      expect(backoff.getDelay(attempt: 2), equals(const Duration(seconds: 4)));
      expect(backoff.getDelay(attempt: 3), equals(const Duration(seconds: 8)));
      expect(backoff.getDelay(attempt: 4), equals(const Duration(seconds: 16)));
    });

    test('getDelay caps at maxDelay', () {
      final backoff = ExponentialBackoff(
        baseDelay: const Duration(seconds: 1),
        maxDelay: const Duration(seconds: 10),
      );

      // Attempt 5 would be 32 seconds, but capped at 10
      final delay = backoff.getDelay(attempt: 5);
      expect(delay, equals(const Duration(seconds: 10)));
    });

    test('getDelayWithJitter returns delay within expected range', () {
      final backoff = ExponentialBackoff(
        baseDelay: const Duration(seconds: 1),
        jitterFactor: 0.2,
      );

      // Run multiple times to test randomness
      for (int i = 0; i < 100; i++) {
        final delay = backoff.getDelayWithJitter(attempt: 0);
        // Expected range: 1000ms ± 20% = 800ms to 1200ms
        expect(
          delay.inMilliseconds,
          greaterThanOrEqualTo(800),
        );
        expect(
          delay.inMilliseconds,
          lessThanOrEqualTo(1200),
        );
      }
    });

    test('getDelayWithJitter with zero jitter returns exact delay', () {
      final backoff = ExponentialBackoff(
        baseDelay: const Duration(seconds: 1),
        jitterFactor: 0.0,
      );

      final delay = backoff.getDelayWithJitter(attempt: 0);
      expect(delay, equals(const Duration(seconds: 1)));
    });

    test('getDelaySequence returns correct number of delays', () {
      final backoff = ExponentialBackoff();

      final sequence = backoff.getDelaySequence(5);
      expect(sequence.length, equals(5));
    });

    test('getDelaySequence delays increase exponentially', () {
      final backoff = ExponentialBackoff(
        jitterFactor: 0.0, // No jitter for predictable testing
      );

      final sequence = backoff.getDelaySequence(4);

      expect(sequence[0], equals(const Duration(seconds: 1)));
      expect(sequence[1], equals(const Duration(seconds: 2)));
      expect(sequence[2], equals(const Duration(seconds: 4)));
      expect(sequence[3], equals(const Duration(seconds: 8)));
    });

    test('getDelaySequence with empty attempts returns empty list', () {
      final backoff = ExponentialBackoff();

      final sequence = backoff.getDelaySequence(0);
      expect(sequence, isEmpty);
    });

    test('handles large attempt numbers', () {
      final backoff = ExponentialBackoff(
        baseDelay: const Duration(seconds: 1),
        maxDelay: const Duration(minutes: 5),
      );

      // Large attempt should cap at maxDelay
      final delay = backoff.getDelay(attempt: 100);
      expect(delay, equals(const Duration(minutes: 5)));
    });
  });
}
