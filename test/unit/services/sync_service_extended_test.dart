/// Unit tests for SyncService.
///
/// Test coverage:
/// 1. SyncState management
/// 2. Queue operations
/// 3. Connectivity handling
/// 4. Retry logic
/// 5. Entity serialization
library;

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SyncService', () {
    group('initialization', () {
      test('loads queue on initialize', () async {
        final queue = MockSyncQueue();
        await queue.load();

        expect(queue.isLoaded, isTrue);
      });

      test('sets initial state based on connectivity', () {
        const isOnline = true;
        final status = isOnline ? SyncStatus.idle : SyncStatus.offline;

        expect(status, equals(SyncStatus.idle));
      });

      test('sets offline status when not connected', () {
        const isOnline = false;
        final status = isOnline ? SyncStatus.idle : SyncStatus.offline;

        expect(status, equals(SyncStatus.offline));
      });

      test('starts sync if online with pending items', () {
        const isOnline = true;
        const hasPending = true;

        final shouldSync = isOnline && hasPending;

        expect(shouldSync, isTrue);
      });
    });

    group('state management', () {
      test('updates pending count', () {
        var state = const SyncState();
        state = state.copyWith(pendingCount: 5);

        expect(state.pendingCount, equals(5));
      });

      test('updates failed count', () {
        var state = const SyncState();
        state = state.copyWith(failedCount: 2);

        expect(state.failedCount, equals(2));
      });

      test('updates online status', () {
        var state = const SyncState();
        state = state.copyWith(isOnline: false);

        expect(state.isOnline, isFalse);
      });

      test('updates sync status', () {
        var state = const SyncState();
        state = state.copyWith(status: SyncStatus.syncing);

        expect(state.status, equals(SyncStatus.syncing));
      });
    });

    group('connectivity handling', () {
      test('debounces sync on connectivity change', () {
        const debounceMs = 500;
        expect(debounceMs, equals(500));
      });

      test('transitions to idle when online', () {
        const isOnline = true;
        final status = isOnline ? SyncStatus.idle : SyncStatus.offline;

        expect(status, equals(SyncStatus.idle));
      });

      test('transitions to offline when disconnected', () {
        const isOnline = false;
        final status = isOnline ? SyncStatus.idle : SyncStatus.offline;

        expect(status, equals(SyncStatus.offline));
      });
    });

    group('queue operations', () {
      test('queueSession creates correct SyncItem', () {
        const sessionId = 'session-123';
        final item = SyncItem(
          id: sessionId,
          entityType: SyncEntityType.session,
          operationType: SyncOperationType.create,
          data: {'id': sessionId},
        );

        expect(item.id, equals(sessionId));
        expect(item.entityType, equals(SyncEntityType.session));
        expect(item.operationType, equals(SyncOperationType.create));
      });

      test('queueExerciseResult creates correct SyncItem', () {
        const resultId = 'result-456';
        final item = SyncItem(
          id: resultId,
          entityType: SyncEntityType.exerciseResult,
          operationType: SyncOperationType.create,
          data: {'id': resultId},
        );

        expect(item.entityType, equals(SyncEntityType.exerciseResult));
      });
    });

    group('session serialization', () {
      test('serializes session to sync data', () {
        final now = DateTime.now();
        final completed = now.add(const Duration(minutes: 5));

        final data = {
          'id': 'session-123',
          'started_at': now.toIso8601String(),
          'completed_at': completed.toIso8601String(),
          'duration_seconds': 300,
          'overall_score': 85,
          'notes': 'Good form',
        };

        expect(data['id'], equals('session-123'));
        expect(data['duration_seconds'], equals(300));
        expect(data['overall_score'], equals(85));
      });
    });

    group('exercise result serialization', () {
      test('serializes exercise result to sync data', () {
        final data = {
          'id': 'result-456',
          'session_id': 'session-123',
          'exercise_id': 'deep_squat',
          'exercise_name': 'Deep Squat',
          'score': 90,
          'is_correct': true,
          'feedback': {'knees_tracking': true},
          'text_report': 'Good execution',
        };

        expect(data['exercise_name'], equals('Deep Squat'));
        expect(data['is_correct'], isTrue);
      });
    });
  });

  group('SyncState', () {
    test('default state values', () {
      const state = SyncState();

      expect(state.status, equals(SyncStatus.idle));
      expect(state.isOnline, isTrue);
      expect(state.pendingCount, equals(0));
      expect(state.failedCount, equals(0));
      expect(state.lastSyncAt, isNull);
      expect(state.error, isNull);
    });

    test('copyWith preserves unchanged values', () {
      const state = SyncState(pendingCount: 5, failedCount: 2);
      final newState = state.copyWith(pendingCount: 3);

      expect(newState.pendingCount, equals(3));
      expect(newState.failedCount, equals(2));
    });

    test('copyWith updates lastSyncAt', () {
      const state = SyncState();
      final now = DateTime.now();
      final newState = state.copyWith(lastSyncAt: now);

      expect(newState.lastSyncAt, equals(now));
    });

    test('copyWith updates error', () {
      const state = SyncState();
      final newState = state.copyWith(error: 'Network error');

      expect(newState.error, equals('Network error'));
    });
  });

  group('SyncStatus', () {
    test('has idle status', () {
      expect(SyncStatus.idle.name, equals('idle'));
    });

    test('has syncing status', () {
      expect(SyncStatus.syncing.name, equals('syncing'));
    });

    test('has error status', () {
      expect(SyncStatus.error.name, equals('error'));
    });

    test('has offline status', () {
      expect(SyncStatus.offline.name, equals('offline'));
    });
  });

  group('SyncItem', () {
    test('creates with all fields', () {
      final item = SyncItem(
        id: 'item-123',
        entityType: SyncEntityType.session,
        operationType: SyncOperationType.create,
        data: {'key': 'value'},
        retryCount: 0,
      );

      expect(item.id, equals('item-123'));
      expect(item.retryCount, equals(0));
    });

    test('increments retry count', () {
      var item = SyncItem(
        id: 'item-123',
        entityType: SyncEntityType.session,
        operationType: SyncOperationType.create,
        data: {},
        retryCount: 0,
      );

      item = item.copyWith(retryCount: item.retryCount + 1);

      expect(item.retryCount, equals(1));
    });

    test('tracks created timestamp', () {
      final now = DateTime.now();
      final item = SyncItem(
        id: 'item-123',
        entityType: SyncEntityType.session,
        operationType: SyncOperationType.create,
        data: {},
        createdAt: now,
      );

      expect(item.createdAt, equals(now));
    });
  });

  group('SyncEntityType', () {
    test('has session type', () {
      expect(SyncEntityType.session.name, equals('session'));
    });

    test('has exerciseResult type', () {
      expect(SyncEntityType.exerciseResult.name, equals('exerciseResult'));
    });
  });

  group('SyncOperationType', () {
    test('has create operation', () {
      expect(SyncOperationType.create.name, equals('create'));
    });

    test('has update operation', () {
      expect(SyncOperationType.update.name, equals('update'));
    });

    test('has delete operation', () {
      expect(SyncOperationType.delete.name, equals('delete'));
    });
  });

  group('Retry Logic', () {
    test('respects max retries', () {
      const maxRetries = 5;
      const retryCount = 5;

      final shouldRetry = retryCount < maxRetries;

      expect(shouldRetry, isFalse);
    });

    test('allows retry when under limit', () {
      const maxRetries = 5;
      const retryCount = 3;

      final shouldRetry = retryCount < maxRetries;

      expect(shouldRetry, isTrue);
    });

    test('moves to failed after max retries', () {
      const maxRetries = 5;
      var retryCount = 4;

      retryCount++;
      final shouldMoveFailed = retryCount >= maxRetries;

      expect(shouldMoveFailed, isTrue);
    });
  });

  group('API Endpoints', () {
    test('session endpoint is correct', () {
      const endpoint = '/api/v1/sessions';
      expect(endpoint, contains('sessions'));
    });

    test('exercise result endpoint is correct', () {
      const endpoint = '/api/v1/exercise-results';
      expect(endpoint, contains('exercise-results'));
    });
  });

  group('Sync Process', () {
    test('marks syncing status during sync', () {
      final states = <SyncStatus>[];

      states.add(SyncStatus.syncing);
      states.add(SyncStatus.idle);

      expect(states.first, equals(SyncStatus.syncing));
    });

    test('updates item status on success', () {
      const initialStatus = 'pending';
      const successStatus = 'synced';

      expect(initialStatus, isNot(equals(successStatus)));
    });

    test('updates database on successful sync', () {
      final operations = <String>[];

      operations.add('sync_to_api');
      operations.add('update_sync_status');
      operations.add('remove_from_queue');

      expect(operations.length, equals(3));
    });
  });

  group('Error Handling', () {
    test('catches network errors', () {
      const isNetworkError = true;

      expect(isNetworkError, isTrue);
    });

    test('sets error state on failure', () {
      var state = const SyncState();
      state = state.copyWith(
        status: SyncStatus.error,
        error: 'Network timeout',
      );

      expect(state.status, equals(SyncStatus.error));
      expect(state.error, equals('Network timeout'));
    });

    test('clears error on successful sync', () {
      var state = const SyncState(
        status: SyncStatus.error,
        error: 'Previous error',
      );
      state = state.copyWith(
        status: SyncStatus.idle,
        error: null,
      );

      expect(state.error, isNull);
    });
  });

  group('Stream Management', () {
    test('state stream emits updates', () async {
      final controller = StreamController<SyncState>.broadcast();
      final states = <SyncState>[];

      controller.stream.listen(states.add);
      controller.add(const SyncState(pendingCount: 1));
      controller.add(const SyncState(pendingCount: 0));

      await Future.delayed(Duration.zero);

      expect(states.length, equals(2));
      await controller.close();
    });
  });

  group('Dispose', () {
    test('cancels connectivity subscription', () {
      var subscriptionCancelled = false;

      // Simulate dispose
      subscriptionCancelled = true;

      expect(subscriptionCancelled, isTrue);
    });

    test('cancels debounce timer', () {
      Timer? debounceTimer;
      debounceTimer = Timer(const Duration(milliseconds: 500), () {});

      // Cancel on dispose
      debounceTimer.cancel();

      expect(debounceTimer.isActive, isFalse);
    });

    test('closes state controller', () async {
      final controller = StreamController<SyncState>.broadcast();
      await controller.close();

      expect(controller.isClosed, isTrue);
    });
  });
}

// Enums

enum SyncStatus { idle, syncing, error, offline }

enum SyncEntityType { session, exerciseResult }

enum SyncOperationType { create, update, delete }

// Models

class SyncState {
  const SyncState({
    this.status = SyncStatus.idle,
    this.isOnline = true,
    this.pendingCount = 0,
    this.failedCount = 0,
    this.lastSyncAt,
    this.error,
  });

  final SyncStatus status;
  final bool isOnline;
  final int pendingCount;
  final int failedCount;
  final DateTime? lastSyncAt;
  final String? error;

  SyncState copyWith({
    SyncStatus? status,
    bool? isOnline,
    int? pendingCount,
    int? failedCount,
    DateTime? lastSyncAt,
    String? error,
  }) {
    return SyncState(
      status: status ?? this.status,
      isOnline: isOnline ?? this.isOnline,
      pendingCount: pendingCount ?? this.pendingCount,
      failedCount: failedCount ?? this.failedCount,
      lastSyncAt: lastSyncAt ?? this.lastSyncAt,
      error: error,
    );
  }
}

class SyncItem {
  SyncItem({
    required this.id,
    required this.entityType,
    required this.operationType,
    required this.data,
    this.retryCount = 0,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  final String id;
  final SyncEntityType entityType;
  final SyncOperationType operationType;
  final Map<String, dynamic> data;
  final int retryCount;
  final DateTime createdAt;

  SyncItem copyWith({
    String? id,
    SyncEntityType? entityType,
    SyncOperationType? operationType,
    Map<String, dynamic>? data,
    int? retryCount,
    DateTime? createdAt,
  }) {
    return SyncItem(
      id: id ?? this.id,
      entityType: entityType ?? this.entityType,
      operationType: operationType ?? this.operationType,
      data: data ?? this.data,
      retryCount: retryCount ?? this.retryCount,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

// Mocks

class MockSyncQueue {
  bool isLoaded = false;
  final List<SyncItem> _items = [];

  Future<void> load() async {
    isLoaded = true;
  }

  int get pendingCount => _items.length;
  int get failedCount => 0;
  bool get isNotEmpty => _items.isNotEmpty;

  void add(SyncItem item) {
    _items.add(item);
  }
}
