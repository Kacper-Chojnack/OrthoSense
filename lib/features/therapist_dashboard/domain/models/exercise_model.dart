import 'package:freezed_annotation/freezed_annotation.dart';

part 'exercise_model.freezed.dart';
part 'exercise_model.g.dart';

/// Categories for rehabilitation exercises.
enum ExerciseCategory {
  @JsonValue('mobility')
  mobility,
  @JsonValue('strength')
  strength,
  @JsonValue('balance')
  balance,
  @JsonValue('stretching')
  stretching,
  @JsonValue('coordination')
  coordination,
  @JsonValue('endurance')
  endurance,
}

/// Body parts targeted by exercises.
enum BodyPart {
  @JsonValue('knee')
  knee,
  @JsonValue('hip')
  hip,
  @JsonValue('shoulder')
  shoulder,
  @JsonValue('ankle')
  ankle,
  @JsonValue('spine')
  spine,
  @JsonValue('elbow')
  elbow,
  @JsonValue('wrist')
  wrist,
  @JsonValue('neck')
  neck,
  @JsonValue('full_body')
  fullBody,
}

/// Exercise model.
@freezed
abstract class ExerciseModel with _$ExerciseModel {
  const factory ExerciseModel({
    required String id,
    required String name,
    @Default('') String description,
    @Default('') String instructions,
    @Default(ExerciseCategory.mobility) ExerciseCategory category,
    @JsonKey(name: 'body_part') @Default(BodyPart.knee) BodyPart bodyPart,
    @JsonKey(name: 'difficulty_level') @Default(1) int difficultyLevel,
    @JsonKey(name: 'video_url') String? videoUrl,
    @JsonKey(name: 'thumbnail_url') String? thumbnailUrl,
    @JsonKey(name: 'duration_seconds') int? durationSeconds,
    @JsonKey(name: 'sensor_config')
    @Default({})
    Map<String, dynamic> sensorConfig,
    @JsonKey(name: 'metrics_config')
    @Default({})
    Map<String, dynamic> metricsConfig,
    @JsonKey(name: 'is_active') @Default(true) bool isActive,
    @JsonKey(name: 'created_at') DateTime? createdAt,
  }) = _ExerciseModel;

  factory ExerciseModel.fromJson(Map<String, dynamic> json) =>
      _$ExerciseModelFromJson(json);
}
