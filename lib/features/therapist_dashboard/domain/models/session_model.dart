import 'package:freezed_annotation/freezed_annotation.dart';

part 'session_model.freezed.dart';
part 'session_model.g.dart';

/// Status of an exercise session.
enum SessionStatus {
  @JsonValue('in_progress')
  inProgress,
  @JsonValue('completed')
  completed,
  @JsonValue('abandoned')
  abandoned,
  @JsonValue('skipped')
  skipped,
}

/// Session model.
@freezed
abstract class SessionModel with _$SessionModel {
  const factory SessionModel({
    required String id,
    @JsonKey(name: 'patient_id') required String patientId,
    @JsonKey(name: 'treatment_plan_id') required String treatmentPlanId,
    @JsonKey(name: 'scheduled_date') required DateTime scheduledDate,
    @Default(SessionStatus.inProgress) SessionStatus status,
    @Default('') String notes,
    @JsonKey(name: 'pain_level_before') int? painLevelBefore,
    @JsonKey(name: 'pain_level_after') int? painLevelAfter,
    @JsonKey(name: 'overall_score') double? overallScore,
    @JsonKey(name: 'started_at') DateTime? startedAt,
    @JsonKey(name: 'completed_at') DateTime? completedAt,
    @JsonKey(name: 'duration_seconds') int? durationSeconds,
    @JsonKey(name: 'created_at') DateTime? createdAt,
  }) = _SessionModel;

  factory SessionModel.fromJson(Map<String, dynamic> json) =>
      _$SessionModelFromJson(json);
}

/// Session summary for dashboard.
@freezed
abstract class SessionSummary with _$SessionSummary {
  const factory SessionSummary({
    @JsonKey(name: 'session_id') required String sessionId,
    @JsonKey(name: 'patient_id') required String patientId,
    @JsonKey(name: 'patient_name') @Default('') String patientName,
    @JsonKey(name: 'scheduled_date') required DateTime scheduledDate,
    @Default(SessionStatus.inProgress) SessionStatus status,
    @JsonKey(name: 'overall_score') double? overallScore,
    @JsonKey(name: 'exercises_completed') @Default(0) int exercisesCompleted,
    @JsonKey(name: 'total_exercises') @Default(0) int totalExercises,
    @JsonKey(name: 'duration_seconds') int? durationSeconds,
  }) = _SessionSummary;

  factory SessionSummary.fromJson(Map<String, dynamic> json) =>
      _$SessionSummaryFromJson(json);
}
