// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'measurement_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

MeasurementModel _$MeasurementModelFromJson(Map<String, dynamic> json) {
  return _MeasurementModel.fromJson(json);
}

/// @nodoc
mixin _$MeasurementModel {
  String get id => throw _privateConstructorUsedError;
  String get userId => throw _privateConstructorUsedError;
  String get type => throw _privateConstructorUsedError;
  Map<String, dynamic> get data => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;
  DateTime? get updatedAt => throw _privateConstructorUsedError;

  /// Serializes this MeasurementModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of MeasurementModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $MeasurementModelCopyWith<MeasurementModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MeasurementModelCopyWith<$Res> {
  factory $MeasurementModelCopyWith(
          MeasurementModel value, $Res Function(MeasurementModel) then) =
      _$MeasurementModelCopyWithImpl<$Res, MeasurementModel>;
  @useResult
  $Res call(
      {String id,
      String userId,
      String type,
      Map<String, dynamic> data,
      DateTime createdAt,
      DateTime? updatedAt});
}

/// @nodoc
class _$MeasurementModelCopyWithImpl<$Res, $Val extends MeasurementModel>
    implements $MeasurementModelCopyWith<$Res> {
  _$MeasurementModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of MeasurementModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? type = null,
    Object? data = null,
    Object? createdAt = null,
    Object? updatedAt = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as String,
      data: null == data
          ? _value.data
          : data // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      updatedAt: freezed == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$MeasurementModelImplCopyWith<$Res>
    implements $MeasurementModelCopyWith<$Res> {
  factory _$$MeasurementModelImplCopyWith(_$MeasurementModelImpl value,
          $Res Function(_$MeasurementModelImpl) then) =
      __$$MeasurementModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String userId,
      String type,
      Map<String, dynamic> data,
      DateTime createdAt,
      DateTime? updatedAt});
}

/// @nodoc
class __$$MeasurementModelImplCopyWithImpl<$Res>
    extends _$MeasurementModelCopyWithImpl<$Res, _$MeasurementModelImpl>
    implements _$$MeasurementModelImplCopyWith<$Res> {
  __$$MeasurementModelImplCopyWithImpl(_$MeasurementModelImpl _value,
      $Res Function(_$MeasurementModelImpl) _then)
      : super(_value, _then);

  /// Create a copy of MeasurementModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? type = null,
    Object? data = null,
    Object? createdAt = null,
    Object? updatedAt = freezed,
  }) {
    return _then(_$MeasurementModelImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as String,
      data: null == data
          ? _value._data
          : data // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      updatedAt: freezed == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$MeasurementModelImpl implements _MeasurementModel {
  const _$MeasurementModelImpl(
      {required this.id,
      required this.userId,
      required this.type,
      required final Map<String, dynamic> data,
      required this.createdAt,
      this.updatedAt})
      : _data = data;

  factory _$MeasurementModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$MeasurementModelImplFromJson(json);

  @override
  final String id;
  @override
  final String userId;
  @override
  final String type;
  final Map<String, dynamic> _data;
  @override
  Map<String, dynamic> get data {
    if (_data is EqualUnmodifiableMapView) return _data;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_data);
  }

  @override
  final DateTime createdAt;
  @override
  final DateTime? updatedAt;

  @override
  String toString() {
    return 'MeasurementModel(id: $id, userId: $userId, type: $type, data: $data, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MeasurementModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.type, type) || other.type == type) &&
            const DeepCollectionEquality().equals(other._data, _data) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, userId, type,
      const DeepCollectionEquality().hash(_data), createdAt, updatedAt);

  /// Create a copy of MeasurementModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$MeasurementModelImplCopyWith<_$MeasurementModelImpl> get copyWith =>
      __$$MeasurementModelImplCopyWithImpl<_$MeasurementModelImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$MeasurementModelImplToJson(
      this,
    );
  }
}

abstract class _MeasurementModel implements MeasurementModel {
  const factory _MeasurementModel(
      {required final String id,
      required final String userId,
      required final String type,
      required final Map<String, dynamic> data,
      required final DateTime createdAt,
      final DateTime? updatedAt}) = _$MeasurementModelImpl;

  factory _MeasurementModel.fromJson(Map<String, dynamic> json) =
      _$MeasurementModelImpl.fromJson;

  @override
  String get id;
  @override
  String get userId;
  @override
  String get type;
  @override
  Map<String, dynamic> get data;
  @override
  DateTime get createdAt;
  @override
  DateTime? get updatedAt;

  /// Create a copy of MeasurementModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$MeasurementModelImplCopyWith<_$MeasurementModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

SyncResponse _$SyncResponseFromJson(Map<String, dynamic> json) {
  return _SyncResponse.fromJson(json);
}

/// @nodoc
mixin _$SyncResponse {
  bool get success => throw _privateConstructorUsedError;
  String get backendId => throw _privateConstructorUsedError;
  String? get errorMessage => throw _privateConstructorUsedError;

  /// Serializes this SyncResponse to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of SyncResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SyncResponseCopyWith<SyncResponse> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SyncResponseCopyWith<$Res> {
  factory $SyncResponseCopyWith(
          SyncResponse value, $Res Function(SyncResponse) then) =
      _$SyncResponseCopyWithImpl<$Res, SyncResponse>;
  @useResult
  $Res call({bool success, String backendId, String? errorMessage});
}

/// @nodoc
class _$SyncResponseCopyWithImpl<$Res, $Val extends SyncResponse>
    implements $SyncResponseCopyWith<$Res> {
  _$SyncResponseCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of SyncResponse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? success = null,
    Object? backendId = null,
    Object? errorMessage = freezed,
  }) {
    return _then(_value.copyWith(
      success: null == success
          ? _value.success
          : success // ignore: cast_nullable_to_non_nullable
              as bool,
      backendId: null == backendId
          ? _value.backendId
          : backendId // ignore: cast_nullable_to_non_nullable
              as String,
      errorMessage: freezed == errorMessage
          ? _value.errorMessage
          : errorMessage // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$SyncResponseImplCopyWith<$Res>
    implements $SyncResponseCopyWith<$Res> {
  factory _$$SyncResponseImplCopyWith(
          _$SyncResponseImpl value, $Res Function(_$SyncResponseImpl) then) =
      __$$SyncResponseImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({bool success, String backendId, String? errorMessage});
}

/// @nodoc
class __$$SyncResponseImplCopyWithImpl<$Res>
    extends _$SyncResponseCopyWithImpl<$Res, _$SyncResponseImpl>
    implements _$$SyncResponseImplCopyWith<$Res> {
  __$$SyncResponseImplCopyWithImpl(
      _$SyncResponseImpl _value, $Res Function(_$SyncResponseImpl) _then)
      : super(_value, _then);

  /// Create a copy of SyncResponse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? success = null,
    Object? backendId = null,
    Object? errorMessage = freezed,
  }) {
    return _then(_$SyncResponseImpl(
      success: null == success
          ? _value.success
          : success // ignore: cast_nullable_to_non_nullable
              as bool,
      backendId: null == backendId
          ? _value.backendId
          : backendId // ignore: cast_nullable_to_non_nullable
              as String,
      errorMessage: freezed == errorMessage
          ? _value.errorMessage
          : errorMessage // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$SyncResponseImpl implements _SyncResponse {
  const _$SyncResponseImpl(
      {required this.success, required this.backendId, this.errorMessage});

  factory _$SyncResponseImpl.fromJson(Map<String, dynamic> json) =>
      _$$SyncResponseImplFromJson(json);

  @override
  final bool success;
  @override
  final String backendId;
  @override
  final String? errorMessage;

  @override
  String toString() {
    return 'SyncResponse(success: $success, backendId: $backendId, errorMessage: $errorMessage)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SyncResponseImpl &&
            (identical(other.success, success) || other.success == success) &&
            (identical(other.backendId, backendId) ||
                other.backendId == backendId) &&
            (identical(other.errorMessage, errorMessage) ||
                other.errorMessage == errorMessage));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, success, backendId, errorMessage);

  /// Create a copy of SyncResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SyncResponseImplCopyWith<_$SyncResponseImpl> get copyWith =>
      __$$SyncResponseImplCopyWithImpl<_$SyncResponseImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$SyncResponseImplToJson(
      this,
    );
  }
}

abstract class _SyncResponse implements SyncResponse {
  const factory _SyncResponse(
      {required final bool success,
      required final String backendId,
      final String? errorMessage}) = _$SyncResponseImpl;

  factory _SyncResponse.fromJson(Map<String, dynamic> json) =
      _$SyncResponseImpl.fromJson;

  @override
  bool get success;
  @override
  String get backendId;
  @override
  String? get errorMessage;

  /// Create a copy of SyncResponse
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SyncResponseImplCopyWith<_$SyncResponseImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
