import 'package:freezed_annotation/freezed_annotation.dart';

part 'measurement_model.freezed.dart';
part 'measurement_model.g.dart';

/// Domain model for measurements.
/// Decoupled from Drift entity for clean architecture.
@freezed
class MeasurementModel with _$MeasurementModel {
  const factory MeasurementModel({
    required String id,
    required String userId,
    required String type,
    required Map<String, dynamic> data,
    required DateTime createdAt,
    DateTime? updatedAt,
  }) = _MeasurementModel;

  factory MeasurementModel.fromJson(Map<String, dynamic> json) =>
      _$MeasurementModelFromJson(json);
}

/// Response model from backend API.
@freezed
class SyncResponse with _$SyncResponse {
  const factory SyncResponse({
    required bool success,
    required String backendId,
    String? errorMessage,
  }) = _SyncResponse;

  factory SyncResponse.fromJson(Map<String, dynamic> json) =>
      _$SyncResponseFromJson(json);
}
