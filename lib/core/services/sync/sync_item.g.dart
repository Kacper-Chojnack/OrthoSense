// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sync_item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_SyncItem _$SyncItemFromJson(Map<String, dynamic> json) => _SyncItem(
  id: json['id'] as String,
  entityType: $enumDecode(_$SyncEntityTypeEnumMap, json['entityType']),
  operationType: $enumDecode(_$SyncOperationTypeEnumMap, json['operationType']),
  data: json['data'] as Map<String, dynamic>,
  createdAt: DateTime.parse(json['createdAt'] as String),
  priority:
      $enumDecodeNullable(_$SyncPriorityEnumMap, json['priority']) ??
      SyncPriority.normal,
  retryCount: (json['retryCount'] as num?)?.toInt() ?? 0,
  lastError: json['lastError'] as String?,
  lastRetryAt: json['lastRetryAt'] == null
      ? null
      : DateTime.parse(json['lastRetryAt'] as String),
);

Map<String, dynamic> _$SyncItemToJson(_SyncItem instance) => <String, dynamic>{
  'id': instance.id,
  'entityType': _$SyncEntityTypeEnumMap[instance.entityType]!,
  'operationType': _$SyncOperationTypeEnumMap[instance.operationType]!,
  'data': instance.data,
  'createdAt': instance.createdAt.toIso8601String(),
  'priority': _$SyncPriorityEnumMap[instance.priority]!,
  'retryCount': instance.retryCount,
  'lastError': instance.lastError,
  'lastRetryAt': instance.lastRetryAt?.toIso8601String(),
};

const _$SyncEntityTypeEnumMap = {
  SyncEntityType.session: 'session',
  SyncEntityType.exerciseResult: 'exerciseResult',
};

const _$SyncOperationTypeEnumMap = {
  SyncOperationType.create: 'create',
  SyncOperationType.update: 'update',
  SyncOperationType.delete: 'delete',
};

const _$SyncPriorityEnumMap = {
  SyncPriority.low: 'low',
  SyncPriority.normal: 'normal',
  SyncPriority.high: 'high',
  SyncPriority.critical: 'critical',
};
