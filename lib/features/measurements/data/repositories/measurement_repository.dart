import 'package:orthosense/core/database/sync_status.dart';
import 'package:orthosense/features/measurements/domain/models/measurement_model.dart';

/// Repository interface for measurement operations.
/// Abstracts data source details from business logic.
abstract class MeasurementRepository {
  /// Saves measurement locally with 'pending' status.
  /// Returns the generated measurement ID.
  Future<String> saveMeasurement({
    required String userId,
    required String type,
    required Map<String, dynamic> data,
  });

  /// Watches all measurements for a user (SSOT pattern).
  /// UI should observe this stream directly.
  Stream<List<MeasurementModel>> watchMeasurements(String userId);

  /// Watches measurements by sync status.
  Stream<List<MeasurementModel>> watchByStatus(SyncStatus status);

  /// Syncs all pending measurements to backend.
  /// Returns count of successfully synced items.
  Future<SyncResult> syncPendingMeasurements();

  /// Retries failed measurements up to max retry count.
  Future<SyncResult> retryFailedMeasurements({int maxRetries = 3});
}

/// Result of a sync operation.
class SyncResult {
  const SyncResult({
    required this.attempted,
    required this.succeeded,
    required this.failed,
  });

  final int attempted;
  final int succeeded;
  final int failed;

  bool get hasFailures => failed > 0;
  bool get isComplete => attempted == succeeded;
}
