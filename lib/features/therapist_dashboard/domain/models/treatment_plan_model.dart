import 'package:freezed_annotation/freezed_annotation.dart';

part 'treatment_plan_model.freezed.dart';
part 'treatment_plan_model.g.dart';

/// Status of a treatment plan.
enum PlanStatus {
  @JsonValue('pending')
  pending,
  @JsonValue('active')
  active,
  @JsonValue('paused')
  paused,
  @JsonValue('completed')
  completed,
  @JsonValue('cancelled')
  cancelled,
}

/// Treatment plan model.
@freezed
abstract class TreatmentPlanModel with _$TreatmentPlanModel {
  const factory TreatmentPlanModel({
    required String id,
    required String name,
    @JsonKey(name: 'patient_id') required String patientId,
    @JsonKey(name: 'therapist_id') required String therapistId,
    @JsonKey(name: 'protocol_id') String? protocolId,
    @Default('') String notes,
    @JsonKey(name: 'start_date') required DateTime startDate,
    @JsonKey(name: 'end_date') DateTime? endDate,
    @Default(PlanStatus.pending) PlanStatus status,
    @JsonKey(name: 'frequency_per_week') @Default(3) int frequencyPerWeek,
    @JsonKey(name: 'custom_parameters') @Default({}) Map<String, dynamic> customParameters,
    @JsonKey(name: 'created_at') DateTime? createdAt,
  }) = _TreatmentPlanModel;

  factory TreatmentPlanModel.fromJson(Map<String, dynamic> json) =>
      _$TreatmentPlanModelFromJson(json);
}

/// Treatment plan with enriched details.
@freezed
abstract class TreatmentPlanDetails with _$TreatmentPlanDetails {
  const factory TreatmentPlanDetails({
    required String id,
    required String name,
    @JsonKey(name: 'patient_id') required String patientId,
    @JsonKey(name: 'therapist_id') required String therapistId,
    @JsonKey(name: 'protocol_id') String? protocolId,
    @Default('') String notes,
    @JsonKey(name: 'start_date') required DateTime startDate,
    @JsonKey(name: 'end_date') DateTime? endDate,
    @Default(PlanStatus.pending) PlanStatus status,
    @JsonKey(name: 'frequency_per_week') @Default(3) int frequencyPerWeek,
    @JsonKey(name: 'custom_parameters') @Default({}) Map<String, dynamic> customParameters,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'patient_name') @Default('') String patientName,
    @JsonKey(name: 'protocol_name') String? protocolName,
    @JsonKey(name: 'sessions_completed') @Default(0) int sessionsCompleted,
    @JsonKey(name: 'compliance_rate') @Default(0.0) double complianceRate,
  }) = _TreatmentPlanDetails;

  factory TreatmentPlanDetails.fromJson(Map<String, dynamic> json) =>
      _$TreatmentPlanDetailsFromJson(json);
}
