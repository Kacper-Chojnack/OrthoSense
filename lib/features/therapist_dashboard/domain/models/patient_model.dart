import 'package:freezed_annotation/freezed_annotation.dart';

part 'patient_model.freezed.dart';
part 'patient_model.g.dart';

/// Patient model for therapist dashboard.
@freezed
abstract class PatientModel with _$PatientModel {
  const factory PatientModel({
    required String id,
    required String email,
    @JsonKey(name: 'full_name') @Default('') String fullName,
    @JsonKey(name: 'is_active') @Default(true) bool isActive,
    @JsonKey(name: 'is_verified') @Default(false) bool isVerified,
    @JsonKey(name: 'created_at') DateTime? createdAt,
  }) = _PatientModel;

  factory PatientModel.fromJson(Map<String, dynamic> json) =>
      _$PatientModelFromJson(json);
}

/// Patient statistics for monitoring.
@freezed
abstract class PatientStats with _$PatientStats {
  const factory PatientStats({
    @JsonKey(name: 'plan_id') required String planId,
    @JsonKey(name: 'total_sessions') @Default(0) int totalSessions,
    @JsonKey(name: 'completed_sessions') @Default(0) int completedSessions,
    @JsonKey(name: 'compliance_rate') @Default(0.0) double complianceRate,
    @JsonKey(name: 'average_score') double? averageScore,
    @JsonKey(name: 'last_session_date') DateTime? lastSessionDate,
    @JsonKey(name: 'streak_days') @Default(0) int streakDays,
  }) = _PatientStats;

  factory PatientStats.fromJson(Map<String, dynamic> json) =>
      _$PatientStatsFromJson(json);
}
