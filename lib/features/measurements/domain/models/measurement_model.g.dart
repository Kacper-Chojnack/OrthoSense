// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'measurement_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$MeasurementModelImpl _$$MeasurementModelImplFromJson(
        Map<String, dynamic> json) =>
    _$MeasurementModelImpl(
      id: json['id'] as String,
      userId: json['userId'] as String,
      type: json['type'] as String,
      data: json['data'] as Map<String, dynamic>,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$$MeasurementModelImplToJson(
        _$MeasurementModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'type': instance.type,
      'data': instance.data,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
    };

_$SyncResponseImpl _$$SyncResponseImplFromJson(Map<String, dynamic> json) =>
    _$SyncResponseImpl(
      success: json['success'] as bool,
      backendId: json['backendId'] as String,
      errorMessage: json['errorMessage'] as String?,
    );

Map<String, dynamic> _$$SyncResponseImplToJson(_$SyncResponseImpl instance) =>
    <String, dynamic>{
      'success': instance.success,
      'backendId': instance.backendId,
      'errorMessage': instance.errorMessage,
    };
