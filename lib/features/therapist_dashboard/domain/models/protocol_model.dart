import 'package:freezed_annotation/freezed_annotation.dart';

part 'protocol_model.freezed.dart';
part 'protocol_model.g.dart';

/// Status of a protocol.
enum ProtocolStatus {
  @JsonValue('draft')
  draft,
  @JsonValue('published')
  published,
  @JsonValue('archived')
  archived,
}

/// Rehabilitation protocol model.
@freezed
abstract class ProtocolModel with _$ProtocolModel {
  const factory ProtocolModel({
    required String id,
    required String name,
    @JsonKey(name: 'created_by') required String createdBy,
    @Default('') String description,
    @Default('') String condition,
    @Default('') String phase,
    @JsonKey(name: 'duration_weeks') int? durationWeeks,
    @JsonKey(name: 'frequency_per_week') @Default(3) int frequencyPerWeek,
    @Default(ProtocolStatus.draft) ProtocolStatus status,
    @JsonKey(name: 'is_template') @Default(true) bool isTemplate,
    @JsonKey(name: 'created_at') DateTime? createdAt,
  }) = _ProtocolModel;

  factory ProtocolModel.fromJson(Map<String, dynamic> json) =>
      _$ProtocolModelFromJson(json);
}

/// Protocol with exercises.
@freezed
abstract class ProtocolWithExercises with _$ProtocolWithExercises {
  const factory ProtocolWithExercises({
    required String id,
    required String name,
    @JsonKey(name: 'created_by') required String createdBy,
    @Default('') String description,
    @Default('') String condition,
    @Default('') String phase,
    @JsonKey(name: 'duration_weeks') int? durationWeeks,
    @JsonKey(name: 'frequency_per_week') @Default(3) int frequencyPerWeek,
    @Default(ProtocolStatus.draft) ProtocolStatus status,
    @JsonKey(name: 'is_template') @Default(true) bool isTemplate,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @Default([]) List<ProtocolExerciseModel> exercises,
  }) = _ProtocolWithExercises;

  factory ProtocolWithExercises.fromJson(Map<String, dynamic> json) =>
      _$ProtocolWithExercisesFromJson(json);
}

/// Exercise within a protocol.
@freezed
abstract class ProtocolExerciseModel with _$ProtocolExerciseModel {
  const factory ProtocolExerciseModel({
    required String id,
    @JsonKey(name: 'protocol_id') required String protocolId,
    @JsonKey(name: 'exercise_id') required String exerciseId,
    @Default(0) int order,
    @Default(3) int sets,
    int? reps,
    @JsonKey(name: 'hold_seconds') int? holdSeconds,
    @JsonKey(name: 'rest_seconds') @Default(60) int restSeconds,
    @Default('') String notes,
  }) = _ProtocolExerciseModel;

  factory ProtocolExerciseModel.fromJson(Map<String, dynamic> json) =>
      _$ProtocolExerciseModelFromJson(json);
}
