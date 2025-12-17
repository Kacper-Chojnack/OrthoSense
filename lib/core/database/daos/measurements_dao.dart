import 'package:drift/drift.dart';
import 'package:orthosense/core/database/app_database.dart';
import 'package:orthosense/core/database/tables/measurements_table.dart';

part 'measurements_dao.g.dart';

/// DAO for [Measurements] table operations.
/// Provides reactive streams for UI observation (Offline-First pattern).
@DriftAccessor(tables: [Measurements])
class MeasurementsDao extends DatabaseAccessor<AppDatabase>
    with _$MeasurementsDaoMixin {
  MeasurementsDao(super.db);

  /// Watches all measurements for a user as a reactive stream.
  /// UI observes this stream directly (SSOT pattern).
  Stream<List<MeasurementEntry>> watchByUserId(String userId) {
    return (select(measurements)
          ..where((m) => m.userId.equals(userId))
          ..orderBy([(m) => OrderingTerm.desc(m.createdAt)]))
        .watch();
  }

  /// Watches pending measurements for sync worker (Outbox Pattern).
  Stream<List<MeasurementEntry>> watchPending() {
    return (select(measurements)
          ..where((m) => m.syncStatus.equals(SyncStatus.pending.name))
          ..orderBy([(m) => OrderingTerm.asc(m.createdAt)]))
        .watch();
  }

  /// Gets all failed entries with retry count below threshold.
  Future<List<MeasurementEntry>> getRetryable({int maxRetries = 3}) {
    return (select(measurements)
          ..where(
            (m) =>
                m.syncStatus.equals(SyncStatus.failed.name) &
                m.syncRetryCount.isSmallerThanValue(maxRetries),
          ))
        .get();
  }

  /// Inserts new measurement with pending status.
  Future<void> insertMeasurement(MeasurementsCompanion entry) {
    return into(measurements).insert(entry);
  }

  /// Updates sync status (used by sync worker).
  Future<void> updateSyncStatus(String id, SyncStatus status) {
    return (update(measurements)..where((m) => m.id.equals(id))).write(
      MeasurementsCompanion(
        syncStatus: Value(status),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Increments retry count on sync failure.
  Future<void> incrementRetryCount(String id) async {
    final entry = await (select(measurements)
          ..where((m) => m.id.equals(id)))
        .getSingleOrNull();

    if (entry == null) return;

    await (update(measurements)..where((m) => m.id.equals(id))).write(
      MeasurementsCompanion(
        syncRetryCount: Value(entry.syncRetryCount + 1),
        syncStatus: const Value(SyncStatus.failed),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Marks entry as synced.
  Future<void> markSynced(String id) => updateSyncStatus(id, SyncStatus.synced);

  /// Deletes synced entries older than retention period.
  Future<int> pruneOldSynced({Duration retention = const Duration(days: 30)}) {
    final cutoff = DateTime.now().subtract(retention);
    return (delete(measurements)
          ..where(
            (m) =>
                m.syncStatus.equals(SyncStatus.synced.name) &
                m.createdAt.isSmallerThanValue(cutoff),
          ))
        .go();
  }
}
