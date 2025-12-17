import 'package:orthosense/core/database/app_database.dart';
import 'package:orthosense/core/database/daos/measurements_dao.dart';
import 'package:orthosense/features/measurements/data/api/measurement_service.dart';
import 'package:orthosense/features/measurements/data/repositories/measurement_repository.dart';
import 'package:orthosense/features/measurements/domain/models/measurement_model.dart';
import 'package:uuid/uuid.dart';

/// Implementation of [MeasurementRepository] using Drift and
/// MeasurementService. Follows Offline-First pattern with Outbox sync.
class MeasurementRepositoryImpl implements MeasurementRepository {
  MeasurementRepositoryImpl({
    required MeasurementsDao dao,
    required MeasurementService service,
    Uuid? uuid,
  })  : _dao = dao,
        _service = service,
        _uuid = uuid ?? const Uuid();

  final MeasurementsDao _dao;
  final MeasurementService _service;
  final Uuid _uuid;

  @override
  Future<String> saveMeasurement({
    required String userId,
    required String type,
    required Map<String, dynamic> data,
  }) async {
    final id = _uuid.v4();

    await _dao.insertMeasurement(
      MeasurementsCompanion.insert(
        id: id,
        userId: userId,
        type: type,
        jsonData: data,
      ),
    );

    return id;
  }

  @override
  Stream<List<MeasurementModel>> watchMeasurements(String userId) {
    return _dao.watchByUserId(userId).map(_mapEntriesToModels);
  }

  @override
  Stream<List<MeasurementModel>> watchByStatus(SyncStatus status) {
    if (status == SyncStatus.pending) {
      return _dao.watchPending().map(_mapEntriesToModels);
    }
    // Extend for other statuses if needed
    return const Stream.empty();
  }

  @override
  Future<SyncResult> syncPendingMeasurements() async {
    final pendingStream = _dao.watchPending();
    final pending = await pendingStream.first;

    if (pending.isEmpty) {
      return const SyncResult(attempted: 0, succeeded: 0, failed: 0);
    }

    var succeeded = 0;
    var failed = 0;

    for (final entry in pending) {
      final success = await _syncSingleEntry(entry);
      if (success) {
        succeeded++;
      } else {
        failed++;
      }
    }

    return SyncResult(
      attempted: pending.length,
      succeeded: succeeded,
      failed: failed,
    );
  }

  @override
  Future<SyncResult> retryFailedMeasurements({int maxRetries = 3}) async {
    final retryable = await _dao.getRetryable(maxRetries: maxRetries);

    if (retryable.isEmpty) {
      return const SyncResult(attempted: 0, succeeded: 0, failed: 0);
    }

    var succeeded = 0;
    var failed = 0;

    for (final entry in retryable) {
      final success = await _syncSingleEntry(entry);
      if (success) {
        succeeded++;
      } else {
        failed++;
      }
    }

    return SyncResult(
      attempted: retryable.length,
      succeeded: succeeded,
      failed: failed,
    );
  }

  Future<bool> _syncSingleEntry(MeasurementEntry entry) async {
    try {
      await _dao.updateSyncStatus(entry.id, SyncStatus.syncing);

      final model = _mapEntryToModel(entry);
      final response = await _service.postMeasurement(model);

      if (response.success) {
        await _dao.markSynced(entry.id);
        return true;
      } else {
        await _dao.incrementRetryCount(entry.id);
        return false;
      }
    } catch (e) {
      await _dao.incrementRetryCount(entry.id);
      return false;
    }
  }

  List<MeasurementModel> _mapEntriesToModels(List<MeasurementEntry> entries) {
    return entries.map(_mapEntryToModel).toList();
  }

  MeasurementModel _mapEntryToModel(MeasurementEntry entry) {
    return MeasurementModel(
      id: entry.id,
      userId: entry.userId,
      type: entry.type,
      data: entry.jsonData,
      createdAt: entry.createdAt,
      updatedAt: entry.updatedAt,
    );
  }
}
