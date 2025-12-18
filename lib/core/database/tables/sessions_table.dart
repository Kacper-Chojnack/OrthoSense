import 'package:drift/drift.dart';

/// Local storage for exercise sessions (Offline-First).
/// Sync status follows the Outbox Pattern for background synchronization.
class Sessions extends Table {
  /// Unique session identifier (UUID).
  TextColumn get id => text()();

  /// When the session started.
  DateTimeColumn get startedAt => dateTime()();

  /// When the session was completed (null if in progress).
  DateTimeColumn get completedAt => dateTime().nullable()();

  /// Total duration in seconds.
  IntColumn get durationSeconds => integer().withDefault(const Constant(0))();

  /// Overall session score (0-100).
  IntColumn get overallScore => integer().nullable()();

  /// Optional notes from user or AI feedback.
  TextColumn get notes => text().nullable()();

  /// Sync status: 'pending', 'synced', 'error'.
  /// UI writes with 'pending', background worker syncs to cloud.
  TextColumn get syncStatus => text().withDefault(const Constant('pending'))();

  /// Timestamp of last sync attempt.
  DateTimeColumn get lastSyncAttempt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
