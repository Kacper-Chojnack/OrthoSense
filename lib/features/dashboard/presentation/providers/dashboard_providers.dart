import 'package:orthosense/core/database/sync_status.dart';
import 'package:orthosense/core/providers/database_provider.dart';
import 'package:orthosense/features/measurements/domain/models/measurement_model.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'dashboard_providers.g.dart';

/// Combined measurement data with sync status for UI display.
class MeasurementWithStatus {
  const MeasurementWithStatus({
    required this.measurement,
    required this.syncStatus,
  });

  final MeasurementModel measurement;
  final SyncStatus syncStatus;
}

/// Provides measurements with their sync status for dashboard display.
/// Uses Drift stream as Single Source of Truth (SSOT).
@riverpod
Stream<List<MeasurementWithStatus>> dashboardMeasurements(
  DashboardMeasurementsRef ref,
  String userId,
) {
  final dao = ref.watch(measurementsDaoProvider);

  return dao.watchByUserId(userId).map(
        (entries) => entries
            .map(
              (entry) => MeasurementWithStatus(
                measurement: MeasurementModel(
                  id: entry.id,
                  userId: entry.userId,
                  type: entry.type,
                  data: entry.jsonData,
                  createdAt: entry.createdAt,
                  updatedAt: entry.updatedAt,
                ),
                syncStatus: entry.syncStatus,
              ),
            )
            .toList(),
      );
}
