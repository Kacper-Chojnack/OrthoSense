// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'session_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_SessionModel _$SessionModelFromJson(Map<String, dynamic> json) =>
    _SessionModel(
      id: json['id'] as String,
      patientId: json['patient_id'] as String,
      treatmentPlanId: json['treatment_plan_id'] as String,
      scheduledDate: DateTime.parse(json['scheduled_date'] as String),
      status:
          $enumDecodeNullable(_$SessionStatusEnumMap, json['status']) ??
          SessionStatus.inProgress,
      notes: json['notes'] as String? ?? '',
      painLevelBefore: (json['pain_level_before'] as num?)?.toInt(),
      painLevelAfter: (json['pain_level_after'] as num?)?.toInt(),
      overallScore: (json['overall_score'] as num?)?.toDouble(),
      startedAt: json['started_at'] == null
          ? null
          : DateTime.parse(json['started_at'] as String),
      completedAt: json['completed_at'] == null
          ? null
          : DateTime.parse(json['completed_at'] as String),
      durationSeconds: (json['duration_seconds'] as num?)?.toInt(),
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$SessionModelToJson(_SessionModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'patient_id': instance.patientId,
      'treatment_plan_id': instance.treatmentPlanId,
      'scheduled_date': instance.scheduledDate.toIso8601String(),
      'status': _$SessionStatusEnumMap[instance.status]!,
      'notes': instance.notes,
      'pain_level_before': instance.painLevelBefore,
      'pain_level_after': instance.painLevelAfter,
      'overall_score': instance.overallScore,
      'started_at': instance.startedAt?.toIso8601String(),
      'completed_at': instance.completedAt?.toIso8601String(),
      'duration_seconds': instance.durationSeconds,
      'created_at': instance.createdAt?.toIso8601String(),
    };

const _$SessionStatusEnumMap = {
  SessionStatus.inProgress: 'in_progress',
  SessionStatus.completed: 'completed',
  SessionStatus.abandoned: 'abandoned',
  SessionStatus.skipped: 'skipped',
};

_SessionSummary _$SessionSummaryFromJson(Map<String, dynamic> json) =>
    _SessionSummary(
      sessionId: json['session_id'] as String,
      patientId: json['patient_id'] as String,
      scheduledDate: DateTime.parse(json['scheduled_date'] as String),
      patientName: json['patient_name'] as String? ?? '',
      status:
          $enumDecodeNullable(_$SessionStatusEnumMap, json['status']) ??
          SessionStatus.inProgress,
      overallScore: (json['overall_score'] as num?)?.toDouble(),
      exercisesCompleted: (json['exercises_completed'] as num?)?.toInt() ?? 0,
      totalExercises: (json['total_exercises'] as num?)?.toInt() ?? 0,
      durationSeconds: (json['duration_seconds'] as num?)?.toInt(),
    );

Map<String, dynamic> _$SessionSummaryToJson(_SessionSummary instance) =>
    <String, dynamic>{
      'session_id': instance.sessionId,
      'patient_id': instance.patientId,
      'scheduled_date': instance.scheduledDate.toIso8601String(),
      'patient_name': instance.patientName,
      'status': _$SessionStatusEnumMap[instance.status]!,
      'overall_score': instance.overallScore,
      'exercises_completed': instance.exercisesCompleted,
      'total_exercises': instance.totalExercises,
      'duration_seconds': instance.durationSeconds,
    };
