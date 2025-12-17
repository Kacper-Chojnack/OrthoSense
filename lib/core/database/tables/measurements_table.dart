import 'package:drift/drift.dart';
import 'package:orthosense/core/database/converters.dart';
import 'package:orthosense/core/database/sync_status.dart';

/// Measurements table for offline-first storage.
/// Supports Outbox Pattern via [syncStatus] column.
@DataClassName('MeasurementEntry')
class Measurements extends Table {
  /// Primary key - UUID generated client-side.
  TextColumn get id => text()();

  /// Hashed user identifier (SHA-256 + salt per AGENTS.md).
  TextColumn get userId => text()();

  /// Measurement type (e.g., 'pose_analysis', 'rom_measurement').
  TextColumn get type => text()();

  /// Outbox Pattern: tracks sync state with backend.
  TextColumn get syncStatus => text()
      .map(const SyncStatusConverter())
      .withDefault(Constant(SyncStatus.pending.name))();

  /// Flexible JSON payload for measurement data.
  TextColumn get jsonData => text().map(const JsonMapConverter())();

  /// Client-side creation timestamp.
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  /// Last modification timestamp.
  DateTimeColumn get updatedAt => dateTime().nullable()();

  /// Retry count for failed sync attempts.
  IntColumn get syncRetryCount => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}
