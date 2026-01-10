import 'package:freezed_annotation/freezed_annotation.dart';

part 'sync_state.freezed.dart';

/// Status of sync operation.
enum SyncStatus {
  /// No sync in progress, all synced.
  idle,

  /// Sync is in progress.
  syncing,

  /// Sync encountered an error.
  error,

  /// Device is offline.
  offline,
}

/// State of the sync service.
@freezed
abstract class SyncState with _$SyncState {
  const factory SyncState({
    @Default(SyncStatus.idle) SyncStatus status,
    @Default(0) int pendingCount,
    @Default(0) int failedCount,
    DateTime? lastSyncAt,
    String? errorMessage,
    @Default(false) bool isOnline,
  }) = _SyncState;

  const SyncState._();

  /// Check if sync can be started.
  bool get canSync => isOnline && status != SyncStatus.syncing;

  /// Check if there are pending items.
  bool get hasPendingItems => pendingCount > 0;

  /// Check if there are failed items.
  bool get hasFailedItems => failedCount > 0;

  /// Get human-readable status message.
  String get statusMessage => switch (status) {
    SyncStatus.idle when hasPendingItems => '$pendingCount pending',
    SyncStatus.idle => 'All synced',
    SyncStatus.syncing => 'Syncing...',
    SyncStatus.error => errorMessage ?? 'Sync error',
    SyncStatus.offline => 'Offline',
  };
}
