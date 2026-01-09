// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'sync_item.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$SyncItem {

 String get id; SyncEntityType get entityType; SyncOperationType get operationType; Map<String, dynamic> get data; DateTime get createdAt; SyncPriority get priority; int get retryCount; String? get lastError; DateTime? get lastRetryAt;
/// Create a copy of SyncItem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SyncItemCopyWith<SyncItem> get copyWith => _$SyncItemCopyWithImpl<SyncItem>(this as SyncItem, _$identity);

  /// Serializes this SyncItem to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SyncItem&&(identical(other.id, id) || other.id == id)&&(identical(other.entityType, entityType) || other.entityType == entityType)&&(identical(other.operationType, operationType) || other.operationType == operationType)&&const DeepCollectionEquality().equals(other.data, data)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.priority, priority) || other.priority == priority)&&(identical(other.retryCount, retryCount) || other.retryCount == retryCount)&&(identical(other.lastError, lastError) || other.lastError == lastError)&&(identical(other.lastRetryAt, lastRetryAt) || other.lastRetryAt == lastRetryAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,entityType,operationType,const DeepCollectionEquality().hash(data),createdAt,priority,retryCount,lastError,lastRetryAt);

@override
String toString() {
  return 'SyncItem(id: $id, entityType: $entityType, operationType: $operationType, data: $data, createdAt: $createdAt, priority: $priority, retryCount: $retryCount, lastError: $lastError, lastRetryAt: $lastRetryAt)';
}


}

/// @nodoc
abstract mixin class $SyncItemCopyWith<$Res>  {
  factory $SyncItemCopyWith(SyncItem value, $Res Function(SyncItem) _then) = _$SyncItemCopyWithImpl;
@useResult
$Res call({
 String id, SyncEntityType entityType, SyncOperationType operationType, Map<String, dynamic> data, DateTime createdAt, SyncPriority priority, int retryCount, String? lastError, DateTime? lastRetryAt
});




}
/// @nodoc
class _$SyncItemCopyWithImpl<$Res>
    implements $SyncItemCopyWith<$Res> {
  _$SyncItemCopyWithImpl(this._self, this._then);

  final SyncItem _self;
  final $Res Function(SyncItem) _then;

/// Create a copy of SyncItem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? entityType = null,Object? operationType = null,Object? data = null,Object? createdAt = null,Object? priority = null,Object? retryCount = null,Object? lastError = freezed,Object? lastRetryAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,entityType: null == entityType ? _self.entityType : entityType // ignore: cast_nullable_to_non_nullable
as SyncEntityType,operationType: null == operationType ? _self.operationType : operationType // ignore: cast_nullable_to_non_nullable
as SyncOperationType,data: null == data ? _self.data : data // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,priority: null == priority ? _self.priority : priority // ignore: cast_nullable_to_non_nullable
as SyncPriority,retryCount: null == retryCount ? _self.retryCount : retryCount // ignore: cast_nullable_to_non_nullable
as int,lastError: freezed == lastError ? _self.lastError : lastError // ignore: cast_nullable_to_non_nullable
as String?,lastRetryAt: freezed == lastRetryAt ? _self.lastRetryAt : lastRetryAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [SyncItem].
extension SyncItemPatterns on SyncItem {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SyncItem value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SyncItem() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SyncItem value)  $default,){
final _that = this;
switch (_that) {
case _SyncItem():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SyncItem value)?  $default,){
final _that = this;
switch (_that) {
case _SyncItem() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  SyncEntityType entityType,  SyncOperationType operationType,  Map<String, dynamic> data,  DateTime createdAt,  SyncPriority priority,  int retryCount,  String? lastError,  DateTime? lastRetryAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SyncItem() when $default != null:
return $default(_that.id,_that.entityType,_that.operationType,_that.data,_that.createdAt,_that.priority,_that.retryCount,_that.lastError,_that.lastRetryAt);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  SyncEntityType entityType,  SyncOperationType operationType,  Map<String, dynamic> data,  DateTime createdAt,  SyncPriority priority,  int retryCount,  String? lastError,  DateTime? lastRetryAt)  $default,) {final _that = this;
switch (_that) {
case _SyncItem():
return $default(_that.id,_that.entityType,_that.operationType,_that.data,_that.createdAt,_that.priority,_that.retryCount,_that.lastError,_that.lastRetryAt);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  SyncEntityType entityType,  SyncOperationType operationType,  Map<String, dynamic> data,  DateTime createdAt,  SyncPriority priority,  int retryCount,  String? lastError,  DateTime? lastRetryAt)?  $default,) {final _that = this;
switch (_that) {
case _SyncItem() when $default != null:
return $default(_that.id,_that.entityType,_that.operationType,_that.data,_that.createdAt,_that.priority,_that.retryCount,_that.lastError,_that.lastRetryAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SyncItem extends SyncItem {
  const _SyncItem({required this.id, required this.entityType, required this.operationType, required final  Map<String, dynamic> data, required this.createdAt, this.priority = SyncPriority.normal, this.retryCount = 0, this.lastError, this.lastRetryAt}): _data = data,super._();
  factory _SyncItem.fromJson(Map<String, dynamic> json) => _$SyncItemFromJson(json);

@override final  String id;
@override final  SyncEntityType entityType;
@override final  SyncOperationType operationType;
 final  Map<String, dynamic> _data;
@override Map<String, dynamic> get data {
  if (_data is EqualUnmodifiableMapView) return _data;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_data);
}

@override final  DateTime createdAt;
@override@JsonKey() final  SyncPriority priority;
@override@JsonKey() final  int retryCount;
@override final  String? lastError;
@override final  DateTime? lastRetryAt;

/// Create a copy of SyncItem
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SyncItemCopyWith<_SyncItem> get copyWith => __$SyncItemCopyWithImpl<_SyncItem>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SyncItemToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SyncItem&&(identical(other.id, id) || other.id == id)&&(identical(other.entityType, entityType) || other.entityType == entityType)&&(identical(other.operationType, operationType) || other.operationType == operationType)&&const DeepCollectionEquality().equals(other._data, _data)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.priority, priority) || other.priority == priority)&&(identical(other.retryCount, retryCount) || other.retryCount == retryCount)&&(identical(other.lastError, lastError) || other.lastError == lastError)&&(identical(other.lastRetryAt, lastRetryAt) || other.lastRetryAt == lastRetryAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,entityType,operationType,const DeepCollectionEquality().hash(_data),createdAt,priority,retryCount,lastError,lastRetryAt);

@override
String toString() {
  return 'SyncItem(id: $id, entityType: $entityType, operationType: $operationType, data: $data, createdAt: $createdAt, priority: $priority, retryCount: $retryCount, lastError: $lastError, lastRetryAt: $lastRetryAt)';
}


}

/// @nodoc
abstract mixin class _$SyncItemCopyWith<$Res> implements $SyncItemCopyWith<$Res> {
  factory _$SyncItemCopyWith(_SyncItem value, $Res Function(_SyncItem) _then) = __$SyncItemCopyWithImpl;
@override @useResult
$Res call({
 String id, SyncEntityType entityType, SyncOperationType operationType, Map<String, dynamic> data, DateTime createdAt, SyncPriority priority, int retryCount, String? lastError, DateTime? lastRetryAt
});




}
/// @nodoc
class __$SyncItemCopyWithImpl<$Res>
    implements _$SyncItemCopyWith<$Res> {
  __$SyncItemCopyWithImpl(this._self, this._then);

  final _SyncItem _self;
  final $Res Function(_SyncItem) _then;

/// Create a copy of SyncItem
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? entityType = null,Object? operationType = null,Object? data = null,Object? createdAt = null,Object? priority = null,Object? retryCount = null,Object? lastError = freezed,Object? lastRetryAt = freezed,}) {
  return _then(_SyncItem(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,entityType: null == entityType ? _self.entityType : entityType // ignore: cast_nullable_to_non_nullable
as SyncEntityType,operationType: null == operationType ? _self.operationType : operationType // ignore: cast_nullable_to_non_nullable
as SyncOperationType,data: null == data ? _self._data : data // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,priority: null == priority ? _self.priority : priority // ignore: cast_nullable_to_non_nullable
as SyncPriority,retryCount: null == retryCount ? _self.retryCount : retryCount // ignore: cast_nullable_to_non_nullable
as int,lastError: freezed == lastError ? _self.lastError : lastError // ignore: cast_nullable_to_non_nullable
as String?,lastRetryAt: freezed == lastRetryAt ? _self.lastRetryAt : lastRetryAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
