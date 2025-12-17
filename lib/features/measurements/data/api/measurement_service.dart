import 'package:orthosense/features/measurements/domain/models/measurement_model.dart';

/// Abstract interface for measurement API operations.
/// Allows swapping Mock/Real implementations via DI.
abstract class MeasurementService {
  Future<SyncResponse> postMeasurement(MeasurementModel data);

  Future<List<SyncResponse>> postMeasurementsBatch(List<MeasurementModel> data);
}
