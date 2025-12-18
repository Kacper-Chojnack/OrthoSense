// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'patient_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_PatientModel _$PatientModelFromJson(Map<String, dynamic> json) =>
    _PatientModel(
      id: json['id'] as String,
      email: json['email'] as String,
      fullName: json['full_name'] as String? ?? '',
      isActive: json['is_active'] as bool? ?? true,
      isVerified: json['is_verified'] as bool? ?? false,
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$PatientModelToJson(_PatientModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'email': instance.email,
      'full_name': instance.fullName,
      'is_active': instance.isActive,
      'is_verified': instance.isVerified,
      'created_at': instance.createdAt?.toIso8601String(),
    };

_PatientStats _$PatientStatsFromJson(Map<String, dynamic> json) =>
    _PatientStats(
      planId: json['plan_id'] as String,
      totalSessions: (json['total_sessions'] as num?)?.toInt() ?? 0,
      completedSessions: (json['completed_sessions'] as num?)?.toInt() ?? 0,
      complianceRate: (json['compliance_rate'] as num?)?.toDouble() ?? 0.0,
      averageScore: (json['average_score'] as num?)?.toDouble(),
      lastSessionDate: json['last_session_date'] == null
          ? null
          : DateTime.parse(json['last_session_date'] as String),
      streakDays: (json['streak_days'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$PatientStatsToJson(_PatientStats instance) =>
    <String, dynamic>{
      'plan_id': instance.planId,
      'total_sessions': instance.totalSessions,
      'completed_sessions': instance.completedSessions,
      'compliance_rate': instance.complianceRate,
      'average_score': instance.averageScore,
      'last_session_date': instance.lastSessionDate?.toIso8601String(),
      'streak_days': instance.streakDays,
    };
