/// Unit tests for SyncState.
///
/// Test coverage:
/// 1. Constructor and defaults
/// 2. SyncStatus enum
/// 3. Computed properties (canSync, hasPendingItems, etc.)
/// 4. statusMessage getter
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:orthosense/core/services/sync/sync_state.dart';

void main() {
  group('SyncStatus', () {
    test('has idle value', () {
      expect(SyncStatus.idle, isNotNull);
    });

    test('has syncing value', () {
      expect(SyncStatus.syncing, isNotNull);
    });

    test('has error value', () {
      expect(SyncStatus.error, isNotNull);
    });

    test('has offline value', () {
      expect(SyncStatus.offline, isNotNull);
    });

    test('has exactly 4 values', () {
      expect(SyncStatus.values.length, equals(4));
    });
  });

  group('SyncState', () {
    group('constructor', () {
      test('creates with all defaults', () {
        const state = SyncState();

        expect(state.status, equals(SyncStatus.idle));
        expect(state.pendingCount, equals(0));
        expect(state.failedCount, equals(0));
        expect(state.lastSyncAt, isNull);
        expect(state.errorMessage, isNull);
        expect(state.isOnline, isFalse);
      });

      test('creates with custom status', () {
        const state = SyncState(status: SyncStatus.syncing);

        expect(state.status, equals(SyncStatus.syncing));
      });

      test('creates with custom pendingCount', () {
        const state = SyncState(pendingCount: 5);

        expect(state.pendingCount, equals(5));
      });

      test('creates with custom failedCount', () {
        const state = SyncState(failedCount: 3);

        expect(state.failedCount, equals(3));
      });

      test('creates with custom lastSyncAt', () {
        final now = DateTime.now();
        final state = SyncState(lastSyncAt: now);

        expect(state.lastSyncAt, equals(now));
      });

      test('creates with custom errorMessage', () {
        const state = SyncState(errorMessage: 'Network error');

        expect(state.errorMessage, equals('Network error'));
      });

      test('creates with isOnline true', () {
        const state = SyncState(isOnline: true);

        expect(state.isOnline, isTrue);
      });
    });

    group('canSync', () {
      test('returns true when online and idle', () {
        const state = SyncState(
          isOnline: true,
          status: SyncStatus.idle,
        );

        expect(state.canSync, isTrue);
      });

      test('returns false when offline', () {
        const state = SyncState(
          isOnline: false,
          status: SyncStatus.idle,
        );

        expect(state.canSync, isFalse);
      });

      test('returns false when syncing', () {
        const state = SyncState(
          isOnline: true,
          status: SyncStatus.syncing,
        );

        expect(state.canSync, isFalse);
      });

      test('returns false when offline and syncing', () {
        const state = SyncState(
          isOnline: false,
          status: SyncStatus.syncing,
        );

        expect(state.canSync, isFalse);
      });

      test('returns true when online and error', () {
        const state = SyncState(
          isOnline: true,
          status: SyncStatus.error,
        );

        expect(state.canSync, isTrue);
      });

      test('returns true when online and offline status', () {
        const state = SyncState(
          isOnline: true,
          status: SyncStatus.offline,
        );

        expect(state.canSync, isTrue);
      });
    });

    group('hasPendingItems', () {
      test('returns false when pendingCount is 0', () {
        const state = SyncState(pendingCount: 0);

        expect(state.hasPendingItems, isFalse);
      });

      test('returns true when pendingCount is positive', () {
        const state = SyncState(pendingCount: 1);

        expect(state.hasPendingItems, isTrue);
      });

      test('returns true when pendingCount is large', () {
        const state = SyncState(pendingCount: 100);

        expect(state.hasPendingItems, isTrue);
      });
    });

    group('hasFailedItems', () {
      test('returns false when failedCount is 0', () {
        const state = SyncState(failedCount: 0);

        expect(state.hasFailedItems, isFalse);
      });

      test('returns true when failedCount is positive', () {
        const state = SyncState(failedCount: 1);

        expect(state.hasFailedItems, isTrue);
      });

      test('returns true when failedCount is large', () {
        const state = SyncState(failedCount: 50);

        expect(state.hasFailedItems, isTrue);
      });
    });

    group('statusMessage', () {
      test('returns "All synced" when idle with no pending', () {
        const state = SyncState(
          status: SyncStatus.idle,
          pendingCount: 0,
        );

        expect(state.statusMessage, equals('All synced'));
      });

      test('returns pending count when idle with pending items', () {
        const state = SyncState(
          status: SyncStatus.idle,
          pendingCount: 5,
        );

        expect(state.statusMessage, equals('5 pending'));
      });

      test('returns "1 pending" for single item', () {
        const state = SyncState(
          status: SyncStatus.idle,
          pendingCount: 1,
        );

        expect(state.statusMessage, equals('1 pending'));
      });

      test('returns "Syncing..." when syncing', () {
        const state = SyncState(status: SyncStatus.syncing);

        expect(state.statusMessage, equals('Syncing...'));
      });

      test('returns error message when error', () {
        const state = SyncState(
          status: SyncStatus.error,
          errorMessage: 'Connection failed',
        );

        expect(state.statusMessage, equals('Connection failed'));
      });

      test('returns "Sync error" when error with no message', () {
        const state = SyncState(
          status: SyncStatus.error,
          errorMessage: null,
        );

        expect(state.statusMessage, equals('Sync error'));
      });

      test('returns "Offline" when offline', () {
        const state = SyncState(status: SyncStatus.offline);

        expect(state.statusMessage, equals('Offline'));
      });
    });

    group('copyWith', () {
      test('creates copy with new status', () {
        const state = SyncState(status: SyncStatus.idle);

        final copy = state.copyWith(status: SyncStatus.syncing);

        expect(copy.status, equals(SyncStatus.syncing));
      });

      test('creates copy with new pendingCount', () {
        const state = SyncState(pendingCount: 0);

        final copy = state.copyWith(pendingCount: 10);

        expect(copy.pendingCount, equals(10));
      });

      test('creates copy with new isOnline', () {
        const state = SyncState(isOnline: false);

        final copy = state.copyWith(isOnline: true);

        expect(copy.isOnline, isTrue);
      });

      test('preserves unchanged fields', () {
        final state = SyncState(
          status: SyncStatus.idle,
          pendingCount: 5,
          failedCount: 2,
          lastSyncAt: DateTime(2024, 1, 1),
          errorMessage: 'old error',
          isOnline: true,
        );

        final copy = state.copyWith(pendingCount: 10);

        expect(copy.status, equals(SyncStatus.idle));
        expect(copy.failedCount, equals(2));
        expect(copy.lastSyncAt, equals(DateTime(2024, 1, 1)));
        expect(copy.errorMessage, equals('old error'));
        expect(copy.isOnline, isTrue);
      });

      test('can clear errorMessage', () {
        const state = SyncState(errorMessage: 'Some error');

        final copy = state.copyWith(errorMessage: null);

        expect(copy.errorMessage, isNull);
      });
    });
  });

  group('SyncState scenarios', () {
    test('initial state', () {
      const state = SyncState();

      expect(state.canSync, isFalse); // offline by default
      expect(state.hasPendingItems, isFalse);
      expect(state.hasFailedItems, isFalse);
      expect(state.statusMessage, equals('All synced'));
    });

    test('online with pending items', () {
      const state = SyncState(
        isOnline: true,
        pendingCount: 3,
      );

      expect(state.canSync, isTrue);
      expect(state.hasPendingItems, isTrue);
      expect(state.statusMessage, equals('3 pending'));
    });

    test('currently syncing', () {
      const state = SyncState(
        isOnline: true,
        status: SyncStatus.syncing,
        pendingCount: 5,
      );

      expect(state.canSync, isFalse);
      expect(state.statusMessage, equals('Syncing...'));
    });

    test('sync failed', () {
      const state = SyncState(
        isOnline: true,
        status: SyncStatus.error,
        errorMessage: 'Server unavailable',
        failedCount: 2,
      );

      expect(state.canSync, isTrue); // Can retry
      expect(state.hasFailedItems, isTrue);
      expect(state.statusMessage, equals('Server unavailable'));
    });

    test('went offline', () {
      const state = SyncState(
        isOnline: false,
        status: SyncStatus.offline,
        pendingCount: 3,
      );

      expect(state.canSync, isFalse);
      expect(state.hasPendingItems, isTrue);
      expect(state.statusMessage, equals('Offline'));
    });

    test('sync completed', () {
      final state = SyncState(
        isOnline: true,
        status: SyncStatus.idle,
        pendingCount: 0,
        lastSyncAt: DateTime.now(),
      );

      expect(state.canSync, isTrue);
      expect(state.hasPendingItems, isFalse);
      expect(state.statusMessage, equals('All synced'));
      expect(state.lastSyncAt, isNotNull);
    });
  });
}
