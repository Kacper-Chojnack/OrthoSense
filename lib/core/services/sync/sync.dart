/// Sync service module for offline-first functionality.
///
/// This module implements the Outbox Pattern for reliable data synchronization:
/// 1. All data is written to local Drift database first
/// 2. Items are queued for background sync
/// 3. When online, items are synced to the backend
/// 4. Failed items are retried with exponential backoff
library;

export 'background_sync_worker.dart';
export 'connectivity_service.dart';
export 'exponential_backoff.dart';
export 'sync_initializer.dart';
export 'sync_item.dart';
export 'sync_queue.dart';
export 'sync_service.dart';
export 'sync_state.dart';
