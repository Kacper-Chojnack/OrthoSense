import 'dart:math';

import 'package:orthosense/features/measurements/data/api/measurement_service.dart';
import 'package:orthosense/features/measurements/domain/models/measurement_model.dart';

/// Mock implementation for prototyping phase.
/// Simulates network delays and returns fake backend IDs.
class MockMeasurementService implements MeasurementService {
  MockMeasurementService({
    this.simulatedDelayMs = 500,
    this.failureRate = 0.0,
  });

  final int simulatedDelayMs;
  final double failureRate;
  final _random = Random();

  @override
  Future<SyncResponse> postMeasurement(MeasurementModel data) async {
    await Future<void>.delayed(Duration(milliseconds: simulatedDelayMs));

    if (_random.nextDouble() < failureRate) {
      return const SyncResponse(
        success: false,
        backendId: '',
        errorMessage: 'Simulated network failure',
      );
    }

    final backendId = 'backend_${DateTime.now().millisecondsSinceEpoch}';
    return SyncResponse(
      success: true,
      backendId: backendId,
    );
  }

  @override
  Future<List<SyncResponse>> postMeasurementsBatch(
    List<MeasurementModel> data,
  ) async {
    final responses = <SyncResponse>[];
    for (final measurement in data) {
      responses.add(await postMeasurement(measurement));
    }
    return responses;
  }
}
