// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'protocol_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ProtocolModel _$ProtocolModelFromJson(Map<String, dynamic> json) =>
    _ProtocolModel(
      id: json['id'] as String,
      name: json['name'] as String,
      createdBy: json['created_by'] as String,
      description: json['description'] as String? ?? '',
      condition: json['condition'] as String? ?? '',
      phase: json['phase'] as String? ?? '',
      durationWeeks: (json['duration_weeks'] as num?)?.toInt(),
      frequencyPerWeek: (json['frequency_per_week'] as num?)?.toInt() ?? 3,
      status:
          $enumDecodeNullable(_$ProtocolStatusEnumMap, json['status']) ??
          ProtocolStatus.draft,
      isTemplate: json['is_template'] as bool? ?? true,
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$ProtocolModelToJson(_ProtocolModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'created_by': instance.createdBy,
      'description': instance.description,
      'condition': instance.condition,
      'phase': instance.phase,
      'duration_weeks': instance.durationWeeks,
      'frequency_per_week': instance.frequencyPerWeek,
      'status': _$ProtocolStatusEnumMap[instance.status]!,
      'is_template': instance.isTemplate,
      'created_at': instance.createdAt?.toIso8601String(),
    };

const _$ProtocolStatusEnumMap = {
  ProtocolStatus.draft: 'draft',
  ProtocolStatus.published: 'published',
  ProtocolStatus.archived: 'archived',
};

_ProtocolWithExercises _$ProtocolWithExercisesFromJson(
  Map<String, dynamic> json,
) => _ProtocolWithExercises(
  id: json['id'] as String,
  name: json['name'] as String,
  createdBy: json['created_by'] as String,
  description: json['description'] as String? ?? '',
  condition: json['condition'] as String? ?? '',
  phase: json['phase'] as String? ?? '',
  durationWeeks: (json['duration_weeks'] as num?)?.toInt(),
  frequencyPerWeek: (json['frequency_per_week'] as num?)?.toInt() ?? 3,
  status:
      $enumDecodeNullable(_$ProtocolStatusEnumMap, json['status']) ??
      ProtocolStatus.draft,
  isTemplate: json['is_template'] as bool? ?? true,
  createdAt: json['created_at'] == null
      ? null
      : DateTime.parse(json['created_at'] as String),
  exercises:
      (json['exercises'] as List<dynamic>?)
          ?.map(
            (e) => ProtocolExerciseModel.fromJson(e as Map<String, dynamic>),
          )
          .toList() ??
      const [],
);

Map<String, dynamic> _$ProtocolWithExercisesToJson(
  _ProtocolWithExercises instance,
) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'created_by': instance.createdBy,
  'description': instance.description,
  'condition': instance.condition,
  'phase': instance.phase,
  'duration_weeks': instance.durationWeeks,
  'frequency_per_week': instance.frequencyPerWeek,
  'status': _$ProtocolStatusEnumMap[instance.status]!,
  'is_template': instance.isTemplate,
  'created_at': instance.createdAt?.toIso8601String(),
  'exercises': instance.exercises,
};

_ProtocolExerciseModel _$ProtocolExerciseModelFromJson(
  Map<String, dynamic> json,
) => _ProtocolExerciseModel(
  id: json['id'] as String,
  protocolId: json['protocol_id'] as String,
  exerciseId: json['exercise_id'] as String,
  order: (json['order'] as num?)?.toInt() ?? 0,
  sets: (json['sets'] as num?)?.toInt() ?? 3,
  reps: (json['reps'] as num?)?.toInt(),
  holdSeconds: (json['hold_seconds'] as num?)?.toInt(),
  restSeconds: (json['rest_seconds'] as num?)?.toInt() ?? 60,
  notes: json['notes'] as String? ?? '',
);

Map<String, dynamic> _$ProtocolExerciseModelToJson(
  _ProtocolExerciseModel instance,
) => <String, dynamic>{
  'id': instance.id,
  'protocol_id': instance.protocolId,
  'exercise_id': instance.exerciseId,
  'order': instance.order,
  'sets': instance.sets,
  'reps': instance.reps,
  'hold_seconds': instance.holdSeconds,
  'rest_seconds': instance.restSeconds,
  'notes': instance.notes,
};
