// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'exercise_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ExerciseModel _$ExerciseModelFromJson(Map<String, dynamic> json) =>
    _ExerciseModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      instructions: json['instructions'] as String? ?? '',
      category:
          $enumDecodeNullable(_$ExerciseCategoryEnumMap, json['category']) ??
          ExerciseCategory.mobility,
      bodyPart:
          $enumDecodeNullable(_$BodyPartEnumMap, json['body_part']) ??
          BodyPart.knee,
      difficultyLevel: (json['difficulty_level'] as num?)?.toInt() ?? 1,
      videoUrl: json['video_url'] as String?,
      thumbnailUrl: json['thumbnail_url'] as String?,
      durationSeconds: (json['duration_seconds'] as num?)?.toInt(),
      isActive: json['is_active'] as bool? ?? true,
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$ExerciseModelToJson(_ExerciseModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'instructions': instance.instructions,
      'category': _$ExerciseCategoryEnumMap[instance.category]!,
      'body_part': _$BodyPartEnumMap[instance.bodyPart]!,
      'difficulty_level': instance.difficultyLevel,
      'video_url': instance.videoUrl,
      'thumbnail_url': instance.thumbnailUrl,
      'duration_seconds': instance.durationSeconds,
      'is_active': instance.isActive,
      'created_at': instance.createdAt?.toIso8601String(),
    };

const _$ExerciseCategoryEnumMap = {
  ExerciseCategory.mobility: 'mobility',
  ExerciseCategory.strength: 'strength',
  ExerciseCategory.balance: 'balance',
  ExerciseCategory.stretching: 'stretching',
  ExerciseCategory.coordination: 'coordination',
  ExerciseCategory.endurance: 'endurance',
};

const _$BodyPartEnumMap = {
  BodyPart.knee: 'knee',
  BodyPart.hip: 'hip',
  BodyPart.shoulder: 'shoulder',
  BodyPart.ankle: 'ankle',
  BodyPart.spine: 'spine',
  BodyPart.elbow: 'elbow',
  BodyPart.wrist: 'wrist',
  BodyPart.neck: 'neck',
  BodyPart.fullBody: 'full_body',
};
