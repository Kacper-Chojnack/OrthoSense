/// Unit tests for SyncItem.
///
/// Test coverage:
/// 1. Constructor and defaults
/// 2. shouldRetry logic
/// 3. incrementRetry method
/// 4. Enums (SyncOperationType, SyncPriority, SyncEntityType)
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:orthosense/core/services/sync/sync_item.dart';

void main() {
  group('SyncOperationType', () {
    test('has create value', () {
      expect(SyncOperationType.create, isNotNull);
    });

    test('has update value', () {
      expect(SyncOperationType.update, isNotNull);
    });

    test('has delete value', () {
      expect(SyncOperationType.delete, isNotNull);
    });

    test('has exactly 3 values', () {
      expect(SyncOperationType.values.length, equals(3));
    });
  });

  group('SyncPriority', () {
    test('has low value', () {
      expect(SyncPriority.low, isNotNull);
    });

    test('has normal value', () {
      expect(SyncPriority.normal, isNotNull);
    });

    test('has high value', () {
      expect(SyncPriority.high, isNotNull);
    });

    test('has critical value', () {
      expect(SyncPriority.critical, isNotNull);
    });

    test('has exactly 4 values', () {
      expect(SyncPriority.values.length, equals(4));
    });

    test('priority ordering by index', () {
      expect(SyncPriority.low.index, equals(0));
      expect(SyncPriority.normal.index, equals(1));
      expect(SyncPriority.high.index, equals(2));
      expect(SyncPriority.critical.index, equals(3));
    });
  });

  group('SyncEntityType', () {
    test('has session value', () {
      expect(SyncEntityType.session, isNotNull);
    });

    test('has exerciseResult value', () {
      expect(SyncEntityType.exerciseResult, isNotNull);
    });

    test('has exactly 2 values', () {
      expect(SyncEntityType.values.length, equals(2));
    });
  });

  group('SyncItem', () {
    test('creates with required parameters', () {
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
    });

    test('has default priority of normal', () {
      final item = SyncItem(
        id: 'test-id',
        entityType: SyncEntityType.session,
        operationType: SyncOperationType.create,
        data: {},
        createdAt: DateTime.now(),
      );

      expect(item.priority, equals(SyncPriority.normal));
    });

    test('has default retryCount of 0', () {
      final item = SyncItem(
        id: 'test-id',
        entityType: SyncEntityType.session,
        operationType: SyncOperationType.create,
        data: {},
        createdAt: DateTime.now(),
      );

      expect(item.retryCount, equals(0));
    });

    test('has default null lastError', () {
      final item = SyncItem(
        id: 'test-id',
        entityType: SyncEntityType.session,
        operationType: SyncOperationType.create,
        data: {},
        createdAt: DateTime.now(),
      );

      expect(item.lastError, isNull);
    });

    test('has default null lastRetryAt', () {
      final item = SyncItem(
        id: 'test-id',
        entityType: SyncEntityType.session,
        operationType: SyncOperationType.create,
        data: {},
        createdAt: DateTime.now(),
      );

      expect(item.lastRetryAt, isNull);
    });

    test('accepts custom priority', () {
      final item = SyncItem(
        id: 'test-id',
        entityType: SyncEntityType.exerciseResult,
        operationType: SyncOperationType.create,
        data: {},
        createdAt: DateTime.now(),
        priority: SyncPriority.high,
      );

      expect(item.priority, equals(SyncPriority.high));
    });

    test('accepts all operation types', () {
      for (final opType in SyncOperationType.values) {
        final item = SyncItem(
          id: 'test-id',
          entityType: SyncEntityType.session,
          operationType: opType,
          data: {},
          createdAt: DateTime.now(),
        );

        expect(item.operationType, equals(opType));
      }
    });

    test('accepts all entity types', () {
      for (final entityType in SyncEntityType.values) {
        final item = SyncItem(
          id: 'test-id',
          entityType: entityType,
          operationType: SyncOperationType.create,
          data: {},
          createdAt: DateTime.now(),
        );

        expect(item.entityType, equals(entityType));
      }
    });
  });

  group('SyncItem.shouldRetry', () {
    test('returns true when retryCount is 0', () {
      final item = SyncItem(
        id: 'test-id',
        entityType: SyncEntityType.session,
        operationType: SyncOperationType.create,
        data: {},
        createdAt: DateTime.now(),
        retryCount: 0,
      );

      expect(item.shouldRetry(), isTrue);
    });

    test('returns true when retryCount less than maxRetries', () {
      final item = SyncItem(
        id: 'test-id',
        entityType: SyncEntityType.session,
        operationType: SyncOperationType.create,
        data: {},
        createdAt: DateTime.now(),
        retryCount: 3,
      );

      expect(item.shouldRetry(maxRetries: 5), isTrue);
    });

    test('returns false when retryCount equals maxRetries', () {
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

    test('returns false when retryCount exceeds maxRetries', () {
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

    test('uses default maxRetries of 5', () {
      final item = SyncItem(
        id: 'test-id',
        entityType: SyncEntityType.session,
        operationType: SyncOperationType.create,
        data: {},
        createdAt: DateTime.now(),
        retryCount: 4,
      );

      expect(item.shouldRetry(), isTrue);

      final item5 = item.copyWith(retryCount: 5);
      expect(item5.shouldRetry(), isFalse);
    });

    test('respects custom maxRetries', () {
      final item = SyncItem(
        id: 'test-id',
        entityType: SyncEntityType.session,
        operationType: SyncOperationType.create,
        data: {},
        createdAt: DateTime.now(),
        retryCount: 2,
      );

      expect(item.shouldRetry(maxRetries: 3), isTrue);
      expect(item.shouldRetry(maxRetries: 2), isFalse);
    });
  });

  group('SyncItem.incrementRetry', () {
    test('increments retryCount by 1', () {
      final item = SyncItem(
        id: 'test-id',
        entityType: SyncEntityType.session,
        operationType: SyncOperationType.create,
        data: {},
        createdAt: DateTime.now(),
        retryCount: 0,
      );

      final retried = item.incrementRetry('Test error');

      expect(retried.retryCount, equals(1));
    });

    test('sets lastError', () {
      final item = SyncItem(
        id: 'test-id',
        entityType: SyncEntityType.session,
        operationType: SyncOperationType.create,
        data: {},
        createdAt: DateTime.now(),
      );

      final retried = item.incrementRetry('Network error');

      expect(retried.lastError, equals('Network error'));
    });

    test('sets lastRetryAt to current time', () {
      final item = SyncItem(
        id: 'test-id',
        entityType: SyncEntityType.session,
        operationType: SyncOperationType.create,
        data: {},
        createdAt: DateTime.now(),
      );

      final before = DateTime.now();
      final retried = item.incrementRetry('Error');
      final after = DateTime.now();

      expect(retried.lastRetryAt, isNotNull);
      expect(
        retried.lastRetryAt!.isAfter(
          before.subtract(const Duration(seconds: 1)),
        ),
        isTrue,
      );
      expect(
        retried.lastRetryAt!.isBefore(after.add(const Duration(seconds: 1))),
        isTrue,
      );
    });

    test('preserves other fields', () {
      final originalTime = DateTime(2024, 1, 1);
      final item = SyncItem(
        id: 'test-id',
        entityType: SyncEntityType.exerciseResult,
        operationType: SyncOperationType.update,
        data: {'key': 'value'},
        createdAt: originalTime,
        priority: SyncPriority.high,
      );

      final retried = item.incrementRetry('Error');

      expect(retried.id, equals('test-id'));
      expect(retried.entityType, equals(SyncEntityType.exerciseResult));
      expect(retried.operationType, equals(SyncOperationType.update));
      expect(retried.data, equals({'key': 'value'}));
      expect(retried.createdAt, equals(originalTime));
      expect(retried.priority, equals(SyncPriority.high));
    });

    test('can be called multiple times', () {
      var item = SyncItem(
        id: 'test-id',
        entityType: SyncEntityType.session,
        operationType: SyncOperationType.create,
        data: {},
        createdAt: DateTime.now(),
      );

      item = item.incrementRetry('Error 1');
      expect(item.retryCount, equals(1));
      expect(item.lastError, equals('Error 1'));

      item = item.incrementRetry('Error 2');
      expect(item.retryCount, equals(2));
      expect(item.lastError, equals('Error 2'));

      item = item.incrementRetry('Error 3');
      expect(item.retryCount, equals(3));
      expect(item.lastError, equals('Error 3'));
    });
  });

  group('SyncItem.copyWith', () {
    test('creates copy with new id', () {
      final item = SyncItem(
        id: 'original',
        entityType: SyncEntityType.session,
        operationType: SyncOperationType.create,
        data: {},
        createdAt: DateTime.now(),
      );

      final copy = item.copyWith(id: 'new-id');

      expect(copy.id, equals('new-id'));
    });

    test('creates copy with new retryCount', () {
      final item = SyncItem(
        id: 'test',
        entityType: SyncEntityType.session,
        operationType: SyncOperationType.create,
        data: {},
        createdAt: DateTime.now(),
        retryCount: 0,
      );

      final copy = item.copyWith(retryCount: 5);

      expect(copy.retryCount, equals(5));
    });

    test('preserves unchanged fields', () {
      final item = SyncItem(
        id: 'test',
        entityType: SyncEntityType.exerciseResult,
        operationType: SyncOperationType.delete,
        data: {'a': 1},
        createdAt: DateTime(2024, 1, 1),
        priority: SyncPriority.critical,
      );

      final copy = item.copyWith(retryCount: 3);

      expect(copy.id, equals('test'));
      expect(copy.entityType, equals(SyncEntityType.exerciseResult));
      expect(copy.operationType, equals(SyncOperationType.delete));
      expect(copy.data, equals({'a': 1}));
      expect(copy.priority, equals(SyncPriority.critical));
    });
  });

  group('SyncItem data handling', () {
    test('handles empty data map', () {
      final item = SyncItem(
        id: 'test',
        entityType: SyncEntityType.session,
        operationType: SyncOperationType.create,
        data: const {},
        createdAt: DateTime.now(),
      );

      expect(item.data, isEmpty);
    });

    test('handles complex data map', () {
      final item = SyncItem(
        id: 'test',
        entityType: SyncEntityType.session,
        operationType: SyncOperationType.create,
        data: {
          'string': 'value',
          'int': 42,
          'double': 3.14,
          'bool': true,
          'list': [1, 2, 3],
          'nested': {'a': 'b'},
        },
        createdAt: DateTime.now(),
      );

      expect(item.data['string'], equals('value'));
      expect(item.data['int'], equals(42));
      expect(item.data['double'], equals(3.14));
      expect(item.data['bool'], isTrue);
      expect(item.data['list'], equals([1, 2, 3]));
      expect(item.data['nested'], equals({'a': 'b'}));
    });
  });
}
