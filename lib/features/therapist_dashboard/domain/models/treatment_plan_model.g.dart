// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'treatment_plan_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_TreatmentPlanModel _$TreatmentPlanModelFromJson(Map<String, dynamic> json) =>
    _TreatmentPlanModel(
      id: json['id'] as String,
      name: json['name'] as String,
      patientId: json['patient_id'] as String,
      therapistId: json['therapist_id'] as String,
      protocolId: json['protocol_id'] as String?,
      notes: json['notes'] as String? ?? '',
      startDate: DateTime.parse(json['start_date'] as String),
      endDate: json['end_date'] == null
          ? null
          : DateTime.parse(json['end_date'] as String),
      status:
          $enumDecodeNullable(_$PlanStatusEnumMap, json['status']) ??
          PlanStatus.pending,
      frequencyPerWeek: (json['frequency_per_week'] as num?)?.toInt() ?? 3,
      customParameters:
          json['custom_parameters'] as Map<String, dynamic>? ?? const {},
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$TreatmentPlanModelToJson(_TreatmentPlanModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'patient_id': instance.patientId,
      'therapist_id': instance.therapistId,
      'protocol_id': instance.protocolId,
      'notes': instance.notes,
      'start_date': instance.startDate.toIso8601String(),
      'end_date': instance.endDate?.toIso8601String(),
      'status': _$PlanStatusEnumMap[instance.status]!,
      'frequency_per_week': instance.frequencyPerWeek,
      'custom_parameters': instance.customParameters,
      'created_at': instance.createdAt?.toIso8601String(),
    };

const _$PlanStatusEnumMap = {
  PlanStatus.pending: 'pending',
  PlanStatus.active: 'active',
  PlanStatus.paused: 'paused',
  PlanStatus.completed: 'completed',
  PlanStatus.cancelled: 'cancelled',
};

_TreatmentPlanDetails _$TreatmentPlanDetailsFromJson(
  Map<String, dynamic> json,
) => _TreatmentPlanDetails(
  id: json['id'] as String,
  name: json['name'] as String,
  patientId: json['patient_id'] as String,
  therapistId: json['therapist_id'] as String,
  protocolId: json['protocol_id'] as String?,
  notes: json['notes'] as String? ?? '',
  startDate: DateTime.parse(json['start_date'] as String),
  endDate: json['end_date'] == null
      ? null
      : DateTime.parse(json['end_date'] as String),
  status:
      $enumDecodeNullable(_$PlanStatusEnumMap, json['status']) ??
      PlanStatus.pending,
  frequencyPerWeek: (json['frequency_per_week'] as num?)?.toInt() ?? 3,
  customParameters:
      json['custom_parameters'] as Map<String, dynamic>? ?? const {},
  createdAt: json['created_at'] == null
      ? null
      : DateTime.parse(json['created_at'] as String),
  patientName: json['patient_name'] as String? ?? '',
  protocolName: json['protocol_name'] as String?,
  sessionsCompleted: (json['sessions_completed'] as num?)?.toInt() ?? 0,
  complianceRate: (json['compliance_rate'] as num?)?.toDouble() ?? 0.0,
);

Map<String, dynamic> _$TreatmentPlanDetailsToJson(
  _TreatmentPlanDetails instance,
) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'patient_id': instance.patientId,
  'therapist_id': instance.therapistId,
  'protocol_id': instance.protocolId,
  'notes': instance.notes,
  'start_date': instance.startDate.toIso8601String(),
  'end_date': instance.endDate?.toIso8601String(),
  'status': _$PlanStatusEnumMap[instance.status]!,
  'frequency_per_week': instance.frequencyPerWeek,
  'custom_parameters': instance.customParameters,
  'created_at': instance.createdAt?.toIso8601String(),
  'patient_name': instance.patientName,
  'protocol_name': instance.protocolName,
  'sessions_completed': instance.sessionsCompleted,
  'compliance_rate': instance.complianceRate,
};
