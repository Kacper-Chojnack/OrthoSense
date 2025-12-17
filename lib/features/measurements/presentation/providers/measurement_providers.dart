import 'package:orthosense/core/providers/database_provider.dart';
import 'package:orthosense/features/measurements/data/api/measurement_service.dart';
import 'package:orthosense/features/measurements/data/api/mock_measurement_service.dart';
import 'package:orthosense/features/measurements/data/repositories/measurement_repository.dart';
import 'package:orthosense/features/measurements/data/repositories/measurement_repository_impl.dart';
import 'package:orthosense/infrastructure/networking/dio_provider.dart';
import 'package:orthosense/infrastructure/services/remote_measurement_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'measurement_providers.g.dart';

/// Toggle between Mock and Remote service.
/// Set to false to use real backend.
const bool _useMockService = false;

/// Provides [MeasurementService] implementation.
/// Override in tests or for production API.
@Riverpod(keepAlive: true)
MeasurementService measurementService(MeasurementServiceRef ref) {
  if (_useMockService) {
    return MockMeasurementService();
  }
  return RemoteMeasurementService(dio: ref.watch(dioProvider));
}

/// Provides [MeasurementRepository] with injected dependencies.
@Riverpod(keepAlive: true)
MeasurementRepository measurementRepository(MeasurementRepositoryRef ref) {
  return MeasurementRepositoryImpl(
    dao: ref.watch(measurementsDaoProvider),
    service: ref.watch(measurementServiceProvider),
  );
}
