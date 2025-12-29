// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pose_landmarks.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PoseLandmark _$PoseLandmarkFromJson(Map<String, dynamic> json) => PoseLandmark(
  x: (json['x'] as num).toDouble(),
  y: (json['y'] as num).toDouble(),
  z: (json['z'] as num).toDouble(),
  visibility: (json['visibility'] as num?)?.toDouble() ?? 1.0,
);

Map<String, dynamic> _$PoseLandmarkToJson(PoseLandmark instance) =>
    <String, dynamic>{
      'x': instance.x,
      'y': instance.y,
      'z': instance.z,
      'visibility': instance.visibility,
    };

PoseFrame _$PoseFrameFromJson(Map<String, dynamic> json) => PoseFrame(
  landmarks: (json['landmarks'] as List<dynamic>)
      .map((e) => PoseLandmark.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$PoseFrameToJson(PoseFrame instance) => <String, dynamic>{
  'landmarks': instance.landmarks,
};

PoseLandmarks _$PoseLandmarksFromJson(Map<String, dynamic> json) =>
    PoseLandmarks(
      frames: (json['frames'] as List<dynamic>)
          .map((e) => PoseFrame.fromJson(e as Map<String, dynamic>))
          .toList(),
      fps: (json['fps'] as num?)?.toDouble() ?? 30.0,
    );

Map<String, dynamic> _$PoseLandmarksToJson(PoseLandmarks instance) =>
    <String, dynamic>{'frames': instance.frames, 'fps': instance.fps};
