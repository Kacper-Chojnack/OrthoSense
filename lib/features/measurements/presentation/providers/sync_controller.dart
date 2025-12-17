import 'package:orthosense/features/measurements/data/repositories/measurement_repository.dart';
import 'package:orthosense/features/measurements/presentation/providers/measurement_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'sync_controller.g.dart';

/// Sync state for UI observation.
enum SyncState {
  idle,
  syncing,
  success,
  error,
}

/// Sync status with details.
class SyncStatusInfo {
  const SyncStatusInfo({
    required this.state,
    this.lastResult,
    this.errorMessage,
    this.lastSyncTime,
  });

  final SyncState state;
  final SyncResult? lastResult;
  final String? errorMessage;
  final DateTime? lastSyncTime;

  SyncStatusInfo copyWith({
    SyncState? state,
    SyncResult? lastResult,
    String? errorMessage,
    DateTime? lastSyncTime,
  }) {
    return SyncStatusInfo(
      state: state ?? this.state,
      lastResult: lastResult ?? this.lastResult,
      errorMessage: errorMessage,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
    );
  }
}

/// Controller for sync operations.
/// Exposes manual sync trigger and current sync state.
@Riverpod(keepAlive: true)
class SyncController extends _$SyncController {
  @override
  SyncStatusInfo build() {
    return const SyncStatusInfo(state: SyncState.idle);
  }

  MeasurementRepository get _repository =>
      ref.read(measurementRepositoryProvider);

  /// Triggers sync of all pending measurements.
  Future<void> syncNow() async {
    if (state.state == SyncState.syncing) return;

    state = state.copyWith(state: SyncState.syncing);

    try {
      final result = await _repository.syncPendingMeasurements();

      state = SyncStatusInfo(
        state: result.hasFailures ? SyncState.error : SyncState.success,
        lastResult: result,
        lastSyncTime: DateTime.now(),
        errorMessage: result.hasFailures
            ? '${result.failed} items failed to sync'
            : null,
      );
    } catch (e) {
      state = SyncStatusInfo(
        state: SyncState.error,
        errorMessage: e.toString(),
        lastSyncTime: DateTime.now(),
      );
    }
  }

  /// Retries failed measurements.
  Future<void> retryFailed({int maxRetries = 3}) async {
    if (state.state == SyncState.syncing) return;

    state = state.copyWith(state: SyncState.syncing);

    try {
      final result =
          await _repository.retryFailedMeasurements(maxRetries: maxRetries);

      state = SyncStatusInfo(
        state: result.hasFailures ? SyncState.error : SyncState.success,
        lastResult: result,
        lastSyncTime: DateTime.now(),
        errorMessage: result.hasFailures
            ? '${result.failed} items still failing'
            : null,
      );
    } catch (e) {
      state = SyncStatusInfo(
        state: SyncState.error,
        errorMessage: e.toString(),
        lastSyncTime: DateTime.now(),
      );
    }
  }

  /// Resets state to idle.
  void reset() {
    state = const SyncStatusInfo(state: SyncState.idle);
  }
}
