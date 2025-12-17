// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'pose_landmark.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$PoseLandmark {
  /// Normalized X coordinate (0.0 = left, 1.0 = right).
  double get x => throw _privateConstructorUsedError;

  /// Normalized Y coordinate (0.0 = top, 1.0 = bottom).
  double get y => throw _privateConstructorUsedError;

  /// Normalized Z coordinate (depth, negative = closer to camera).
  double get z => throw _privateConstructorUsedError;

  /// Confidence score (0.0 to 1.0).
  double get visibility => throw _privateConstructorUsedError;

  /// Create a copy of PoseLandmark
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PoseLandmarkCopyWith<PoseLandmark> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PoseLandmarkCopyWith<$Res> {
  factory $PoseLandmarkCopyWith(
          PoseLandmark value, $Res Function(PoseLandmark) then) =
      _$PoseLandmarkCopyWithImpl<$Res, PoseLandmark>;
  @useResult
  $Res call({double x, double y, double z, double visibility});
}

/// @nodoc
class _$PoseLandmarkCopyWithImpl<$Res, $Val extends PoseLandmark>
    implements $PoseLandmarkCopyWith<$Res> {
  _$PoseLandmarkCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PoseLandmark
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? x = null,
    Object? y = null,
    Object? z = null,
    Object? visibility = null,
  }) {
    return _then(_value.copyWith(
      x: null == x
          ? _value.x
          : x // ignore: cast_nullable_to_non_nullable
              as double,
      y: null == y
          ? _value.y
          : y // ignore: cast_nullable_to_non_nullable
              as double,
      z: null == z
          ? _value.z
          : z // ignore: cast_nullable_to_non_nullable
              as double,
      visibility: null == visibility
          ? _value.visibility
          : visibility // ignore: cast_nullable_to_non_nullable
              as double,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$PoseLandmarkImplCopyWith<$Res>
    implements $PoseLandmarkCopyWith<$Res> {
  factory _$$PoseLandmarkImplCopyWith(
          _$PoseLandmarkImpl value, $Res Function(_$PoseLandmarkImpl) then) =
      __$$PoseLandmarkImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({double x, double y, double z, double visibility});
}

/// @nodoc
class __$$PoseLandmarkImplCopyWithImpl<$Res>
    extends _$PoseLandmarkCopyWithImpl<$Res, _$PoseLandmarkImpl>
    implements _$$PoseLandmarkImplCopyWith<$Res> {
  __$$PoseLandmarkImplCopyWithImpl(
      _$PoseLandmarkImpl _value, $Res Function(_$PoseLandmarkImpl) _then)
      : super(_value, _then);

  /// Create a copy of PoseLandmark
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? x = null,
    Object? y = null,
    Object? z = null,
    Object? visibility = null,
  }) {
    return _then(_$PoseLandmarkImpl(
      x: null == x
          ? _value.x
          : x // ignore: cast_nullable_to_non_nullable
              as double,
      y: null == y
          ? _value.y
          : y // ignore: cast_nullable_to_non_nullable
              as double,
      z: null == z
          ? _value.z
          : z // ignore: cast_nullable_to_non_nullable
              as double,
      visibility: null == visibility
          ? _value.visibility
          : visibility // ignore: cast_nullable_to_non_nullable
              as double,
    ));
  }
}

/// @nodoc

class _$PoseLandmarkImpl extends _PoseLandmark {
  const _$PoseLandmarkImpl(
      {required this.x, required this.y, this.z = 0.0, this.visibility = 1.0})
      : super._();

  /// Normalized X coordinate (0.0 = left, 1.0 = right).
  @override
  final double x;

  /// Normalized Y coordinate (0.0 = top, 1.0 = bottom).
  @override
  final double y;

  /// Normalized Z coordinate (depth, negative = closer to camera).
  @override
  @JsonKey()
  final double z;

  /// Confidence score (0.0 to 1.0).
  @override
  @JsonKey()
  final double visibility;

  @override
  String toString() {
    return 'PoseLandmark(x: $x, y: $y, z: $z, visibility: $visibility)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PoseLandmarkImpl &&
            (identical(other.x, x) || other.x == x) &&
            (identical(other.y, y) || other.y == y) &&
            (identical(other.z, z) || other.z == z) &&
            (identical(other.visibility, visibility) ||
                other.visibility == visibility));
  }

  @override
  int get hashCode => Object.hash(runtimeType, x, y, z, visibility);

  /// Create a copy of PoseLandmark
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PoseLandmarkImplCopyWith<_$PoseLandmarkImpl> get copyWith =>
      __$$PoseLandmarkImplCopyWithImpl<_$PoseLandmarkImpl>(this, _$identity);
}

abstract class _PoseLandmark extends PoseLandmark {
  const factory _PoseLandmark(
      {required final double x,
      required final double y,
      final double z,
      final double visibility}) = _$PoseLandmarkImpl;
  const _PoseLandmark._() : super._();

  /// Normalized X coordinate (0.0 = left, 1.0 = right).
  @override
  double get x;

  /// Normalized Y coordinate (0.0 = top, 1.0 = bottom).
  @override
  double get y;

  /// Normalized Z coordinate (depth, negative = closer to camera).
  @override
  double get z;

  /// Confidence score (0.0 to 1.0).
  @override
  double get visibility;

  /// Create a copy of PoseLandmark
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PoseLandmarkImplCopyWith<_$PoseLandmarkImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
