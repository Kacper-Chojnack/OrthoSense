import 'package:freezed_annotation/freezed_annotation.dart';

part 'sync_item.freezed.dart';
part 'sync_item.g.dart';

/// Type of sync operation.
enum SyncOperationType {
  create,
  update,
  delete,
}

/// Priority for sync items.
enum SyncPriority {
  low,
  normal,
  high,
  critical,
}

/// Type of entity being synced.
enum SyncEntityType {
  session,
  exerciseResult,
}

/// Represents an item in the sync queue (Outbox Pattern).
@freezed
abstract class SyncItem with _$SyncItem {
  const factory SyncItem({
    required String id,
    required SyncEntityType entityType,
    required SyncOperationType operationType,
    required Map<String, dynamic> data,
    required DateTime createdAt,
    @Default(SyncPriority.normal) SyncPriority priority,
    @Default(0) int retryCount,
    String? lastError,
    DateTime? lastRetryAt,
  }) = _SyncItem;

  const SyncItem._();

  factory SyncItem.fromJson(Map<String, dynamic> json) =>
      _$SyncItemFromJson(json);

  /// Check if item should be retried.
  bool shouldRetry({int maxRetries = 5}) => retryCount < maxRetries;

  /// Create a copy with incremented retry count.
  SyncItem incrementRetry(String error) => copyWith(
    retryCount: retryCount + 1,
    lastError: error,
    lastRetryAt: DateTime.now(),
  );
}
