import 'dart:collection';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:orthosense/core/services/sync/sync_item.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persistent queue for sync items (Outbox Pattern).
///
/// Items are persisted to SharedPreferences to survive app restarts.
/// Implements priority queue with FIFO ordering within same priority.
class SyncQueue {
  SyncQueue(this._prefs);

  static const _queueKey = 'orthosense_sync_queue';
  static const _failedKey = 'orthosense_sync_failed';

  final SharedPreferences _prefs;
  final Queue<SyncItem> _queue = Queue<SyncItem>();
  final Map<String, SyncItem> _failed = {};

  /// Number of pending items.
  int get pendingCount => _queue.length;

  /// Number of failed items (dead letter queue).
  int get failedCount => _failed.length;

  /// Check if queue is empty.
  bool get isEmpty => _queue.isEmpty;

  /// Check if queue has items.
  bool get isNotEmpty => _queue.isNotEmpty;

  /// Load queue from persistent storage.
  Future<void> load() async {
    try {
      // Load pending queue
      final queueJson = _prefs.getString(_queueKey);
      if (queueJson != null) {
        final items = jsonDecode(queueJson) as List<dynamic>;
        _queue.clear();
        for (final item in items) {
          _queue.add(SyncItem.fromJson(item as Map<String, dynamic>));
        }
      }

      // Load failed items
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

      debugPrint(
        'SyncQueue: Loaded ${_queue.length} pending, '
        '${_failed.length} failed items',
      );
    } catch (e) {
      debugPrint('SyncQueue: Failed to load: $e');
    }
  }

  /// Persist queue to storage.
  Future<void> _persist() async {
    try {
      final queueJson = jsonEncode(_queue.map((e) => e.toJson()).toList());
      await _prefs.setString(_queueKey, queueJson);

      final failedJson = jsonEncode(
        _failed.map((k, v) => MapEntry(k, v.toJson())),
      );
      await _prefs.setString(_failedKey, failedJson);
    } catch (e) {
      debugPrint('SyncQueue: Failed to persist: $e');
    }
  }

  /// Add item to queue with priority sorting.
  Future<void> enqueue(SyncItem item) async {
    // Check for duplicate
    if (_queue.any((i) => i.id == item.id)) {
      debugPrint('SyncQueue: Duplicate item ${item.id}, skipping');
      return;
    }

    // Remove from failed if re-enqueuing
    _failed.remove(item.id);

    // Insert based on priority (higher priority first)
    final list = _queue.toList();
    var insertIndex = list.length;

    for (var i = 0; i < list.length; i++) {
      if (item.priority.index > list[i].priority.index) {
        insertIndex = i;
        break;
      }
    }

    _queue.clear();
    list.insert(insertIndex, item);
    for (final i in list) {
      _queue.add(i);
    }

    await _persist();
    debugPrint('SyncQueue: Enqueued ${item.id} (${item.entityType.name})');
  }

  /// Get next item without removing.
  SyncItem? peek() => _queue.isNotEmpty ? _queue.first : null;

  /// Remove and return next item.
  Future<SyncItem?> dequeue() async {
    if (_queue.isEmpty) return null;

    final item = _queue.removeFirst();
    await _persist();
    return item;
  }

  /// Mark item as completed (remove from queue).
  Future<void> markCompleted(String id) async {
    _queue.removeWhere((item) => item.id == id);
    _failed.remove(id);
    await _persist();
    debugPrint('SyncQueue: Completed $id');
  }

  /// Mark item as failed and move to retry queue or dead letter queue.
  Future<void> markFailed(String id, String error, {int maxRetries = 5}) async {
    final index = _queue.toList().indexWhere((item) => item.id == id);
    if (index == -1) return;

    final list = _queue.toList();
    final item = list.removeAt(index);
    _queue.clear();
    for (final i in list) {
      _queue.add(i);
    }

    final updatedItem = item.incrementRetry(error);

    if (updatedItem.shouldRetry(maxRetries: maxRetries)) {
      // Re-enqueue with lower priority for retry
      await enqueue(updatedItem.copyWith(priority: SyncPriority.low));
      debugPrint(
        'SyncQueue: Retry scheduled for $id '
        '(attempt ${updatedItem.retryCount})',
      );
    } else {
      // Move to dead letter queue
      _failed[id] = updatedItem;
      await _persist();
      debugPrint('SyncQueue: Moved $id to failed (max retries reached)');
    }
  }

  /// Get all pending items.
  List<SyncItem> getPendingItems() => _queue.toList();

  /// Get all failed items.
  List<SyncItem> getFailedItems() => _failed.values.toList();

  /// Retry all failed items.
  Future<void> retryFailed() async {
    final failedItems = List<SyncItem>.from(_failed.values);
    _failed.clear();

    for (final item in failedItems) {
      await enqueue(item.copyWith(retryCount: 0, lastError: null));
    }

    debugPrint('SyncQueue: Retrying ${failedItems.length} failed items');
  }

  /// Clear all items from queue.
  Future<void> clear() async {
    _queue.clear();
    _failed.clear();
    await _persist();
    debugPrint('SyncQueue: Cleared');
  }

  /// Remove specific item by ID.
  Future<void> remove(String id) async {
    _queue.removeWhere((item) => item.id == id);
    _failed.remove(id);
    await _persist();
  }
}
