import 'package:orthosense/core/database/sync_status.dart' as db;
import 'package:orthosense/features/measurements/domain/models/measurement_model.dart';
import 'package:orthosense/features/measurements/presentation/providers/measurement_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'measurement_stream_providers.g.dart';

/// Provides reactive stream of measurements for a user.
/// UI should watch this provider for SSOT pattern.
@riverpod
Stream<List<MeasurementModel>> userMeasurements(
  UserMeasurementsRef ref,
  String userId,
) {
  final repository = ref.watch(measurementRepositoryProvider);
  return repository.watchMeasurements(userId);
}

/// Provides count of pending measurements for sync indicator.
@riverpod
Stream<int> pendingMeasurementsCount(PendingMeasurementsCountRef ref) {
  final repository = ref.watch(measurementRepositoryProvider);
  return repository
      .watchByStatus(db.SyncStatus.pending)
      .map((list) => list.length);
}
