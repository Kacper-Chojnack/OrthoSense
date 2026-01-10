import 'dart:async';

import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:orthosense/core/database/app_database.dart';
import 'package:orthosense/core/services/sync/connectivity_service.dart';
import 'package:orthosense/core/services/sync/exponential_backoff.dart';
import 'package:orthosense/core/services/sync/sync_item.dart';
import 'package:orthosense/core/services/sync/sync_queue.dart';
import 'package:orthosense/core/services/sync/sync_state.dart';

/// Service handling offline-first sync with the backend.
///
/// Implements the Outbox Pattern:
/// 1. UI writes to local Drift database with syncStatus='pending'
/// 2. Items are queued for background sync
/// 3. When online, items are synced to backend
/// 4. On success, syncStatus is updated to 'synced'
/// 5. On failure, items are retried with exponential backoff
class SyncService {
  SyncService({
    required AppDatabase database,
    required SyncQueue queue,
    required ConnectivityService connectivity,
    required Dio dio,
    ExponentialBackoff? backoff,
    this.maxRetries = 5,
  }) : _database = database,
       _queue = queue,
       _connectivity = connectivity,
       _dio = dio,
       _backoff = backoff ?? ExponentialBackoff();

  final AppDatabase _database;
  final SyncQueue _queue;
  final ConnectivityService _connectivity;
  final Dio _dio;
  final ExponentialBackoff _backoff;
  final int maxRetries;

  final _stateController = StreamController<SyncState>.broadcast();
  StreamSubscription<bool>? _connectivitySubscription;
  Timer? _debounceTimer;

  SyncState _state = const SyncState();
  bool _isSyncing = false;
  bool _isInitialized = false;

  /// Current sync state.
  SyncState get state => _state;

  /// Stream of sync state changes.
  Stream<SyncState> get stateStream => _stateController.stream;

  /// Initialize sync service.
  Future<void> initialize() async {
    if (_isInitialized) return;

    await _queue.load();

    _state = _state.copyWith(
      isOnline: _connectivity.isOnline,
      pendingCount: _queue.pendingCount,
      failedCount: _queue.failedCount,
      status: _connectivity.isOnline ? SyncStatus.idle : SyncStatus.offline,
    );
    _emitState();

    // Listen to connectivity changes
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      _onConnectivityChanged,
    );

    _isInitialized = true;
    debugPrint(
      'SyncService: Initialized with ${_queue.pendingCount} pending, '
      '${_queue.failedCount} failed items',
    );

    // Sync pending items if online
    if (_connectivity.isOnline && _queue.isNotEmpty) {
      syncPendingItems();
    }
  }

  void _emitState() {
    if (!_stateController.isClosed) {
      _stateController.add(_state);
    }
  }

  void _onConnectivityChanged(bool isOnline) {
    _state = _state.copyWith(
      isOnline: isOnline,
      status: isOnline ? SyncStatus.idle : SyncStatus.offline,
    );
    _emitState();

    if (isOnline && _queue.isNotEmpty) {
      // Debounce to avoid rapid sync attempts on flaky connections
      _debounceTimer?.cancel();
      _debounceTimer = Timer(const Duration(milliseconds: 500), () {
        syncPendingItems();
      });
    }
  }

  /// Queue a session for sync.
  Future<void> queueSession(Session session) async {
    final item = SyncItem(
      id: session.id,
      entityType: SyncEntityType.session,
      operationType: SyncOperationType.create,
      data: {
        'id': session.id,
        'started_at': session.startedAt.toIso8601String(),
        'completed_at': session.completedAt?.toIso8601String(),
        'duration_seconds': session.durationSeconds,
        'overall_score': session.overallScore,
        'notes': session.notes,
      },
      createdAt: DateTime.now(),
    );

    await _queue.enqueue(item);
    _updatePendingCount();

    if (_connectivity.isOnline) {
      unawaited(syncPendingItems());
    }
  }

  /// Queue an exercise result for sync.
  Future<void> queueExerciseResult(ExerciseResult result) async {
    final item = SyncItem(
      id: result.id,
      entityType: SyncEntityType.exerciseResult,
      operationType: SyncOperationType.create,
      data: {
        'id': result.id,
        'session_id': result.sessionId,
        'exercise_id': result.exerciseId,
        'exercise_name': result.exerciseName,
        'sets_completed': result.setsCompleted,
        'reps_completed': result.repsCompleted,
        'score': result.score,
        'is_correct': result.isCorrect,
        'feedback_json': result.feedbackJson,
        'text_report': result.textReport,
        'duration_seconds': result.durationSeconds,
        'performed_at': result.performedAt.toIso8601String(),
      },
      createdAt: DateTime.now(),
      priority: SyncPriority.high,
    );

    await _queue.enqueue(item);
    _updatePendingCount();

    if (_connectivity.isOnline) {
      unawaited(syncPendingItems());
    }
  }

  void _updatePendingCount() {
    _state = _state.copyWith(
      pendingCount: _queue.pendingCount,
      failedCount: _queue.failedCount,
    );
    _emitState();
  }

  /// Sync all pending items to backend.
  Future<void> syncPendingItems() async {
    if (_isSyncing || !_connectivity.isOnline || _queue.isEmpty) {
      return;
    }

    _isSyncing = true;
    _state = _state.copyWith(status: SyncStatus.syncing);
    _emitState();

    debugPrint('SyncService: Starting sync of ${_queue.pendingCount} items');

    try {
      while (_queue.isNotEmpty && _connectivity.isOnline) {
        final item = _queue.peek();
        if (item == null) break;

        try {
          await _syncItem(item);
          await _queue.markCompleted(item.id);
          await _updateLocalSyncStatus(item, 'synced');

          debugPrint('SyncService: Synced ${item.id}');
        } on DioException catch (e) {
          final error = _getErrorMessage(e);
          debugPrint('SyncService: Sync failed for ${item.id}: $error');

          await _queue.markFailed(item.id, error, maxRetries: maxRetries);

          // Delay before next item if this one failed
          if (item.shouldRetry(maxRetries: maxRetries)) {
            final delay = _backoff.getDelayWithJitter(attempt: item.retryCount);
            await Future<void>.delayed(delay);
          }
        } catch (e) {
          debugPrint('SyncService: Unexpected error for ${item.id}: $e');
          await _queue.markFailed(
            item.id,
            e.toString(),
            maxRetries: maxRetries,
          );
        }

        _updatePendingCount();
      }

      _state = _state.copyWith(
        status: SyncStatus.idle,
        lastSyncAt: DateTime.now(),
        errorMessage: null,
      );
    } catch (e) {
      debugPrint('SyncService: Sync process error: $e');
      _state = _state.copyWith(
        status: SyncStatus.error,
        errorMessage: e.toString(),
      );
    } finally {
      _isSyncing = false;
      _emitState();
    }
  }

  String _getErrorMessage(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout) {
      return 'Connection timeout';
    }
    if (e.type == DioExceptionType.receiveTimeout) {
      return 'Server timeout';
    }
    if (e.response != null) {
      return 'Server error: ${e.response?.statusCode}';
    }
    return e.message ?? 'Network error';
  }

  Future<void> _syncItem(SyncItem item) async {
    final endpoint = switch (item.entityType) {
      SyncEntityType.session => '/api/v1/sessions',
      SyncEntityType.exerciseResult => '/api/v1/exercise-results',
    };

    final method = switch (item.operationType) {
      SyncOperationType.create => 'POST',
      SyncOperationType.update => 'PUT',
      SyncOperationType.delete => 'DELETE',
    };

    final path = item.operationType == SyncOperationType.create
        ? endpoint
        : '$endpoint/${item.id}';

    await _dio.request<dynamic>(
      path,
      data: item.operationType != SyncOperationType.delete ? item.data : null,
      options: Options(method: method),
    );
  }

  Future<void> _updateLocalSyncStatus(SyncItem item, String status) async {
    try {
      switch (item.entityType) {
        case SyncEntityType.session:
          await _database.updateSession(
            SessionsCompanion(
              id: Value(item.id),
              syncStatus: Value(status),
              lastSyncAttempt: Value(DateTime.now()),
            ),
          );
        case SyncEntityType.exerciseResult:
          await _database.updateExerciseResult(
            ExerciseResultsCompanion(
              id: Value(item.id),
              syncStatus: Value(status),
            ),
          );
      }
    } catch (e) {
      debugPrint('SyncService: Failed to update local status: $e');
    }
  }

  /// Retry all failed items.
  Future<void> retryFailedItems() async {
    await _queue.retryFailed();
    _updatePendingCount();

    if (_connectivity.isOnline) {
      unawaited(syncPendingItems());
    }
  }

  /// Force sync now (bypass debounce).
  Future<void> forceSyncNow() async {
    _debounceTimer?.cancel();
    await syncPendingItems();
  }

  /// Get pending items for inspection.
  List<SyncItem> getPendingItems() => _queue.getPendingItems();

  /// Get failed items for inspection.
  List<SyncItem> getFailedItems() => _queue.getFailedItems();

  /// Dispose resources.
  void dispose() {
    _connectivitySubscription?.cancel();
    _debounceTimer?.cancel();
    _stateController.close();
    _isInitialized = false;
  }
}
