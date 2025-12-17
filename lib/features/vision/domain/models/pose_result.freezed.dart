// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'pose_result.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$PoseResult {
  /// List of detected landmarks (33 for full body).
  List<PoseLandmark> get landmarks => throw _privateConstructorUsedError;

  /// Timestamp when this pose was detected.
  DateTime get timestamp => throw _privateConstructorUsedError;

  /// Overall confidence score for the detection.
  double get confidence => throw _privateConstructorUsedError;

  /// Create a copy of PoseResult
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PoseResultCopyWith<PoseResult> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PoseResultCopyWith<$Res> {
  factory $PoseResultCopyWith(
          PoseResult value, $Res Function(PoseResult) then) =
      _$PoseResultCopyWithImpl<$Res, PoseResult>;
  @useResult
  $Res call(
      {List<PoseLandmark> landmarks, DateTime timestamp, double confidence});
}

/// @nodoc
class _$PoseResultCopyWithImpl<$Res, $Val extends PoseResult>
    implements $PoseResultCopyWith<$Res> {
  _$PoseResultCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PoseResult
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? landmarks = null,
    Object? timestamp = null,
    Object? confidence = null,
  }) {
    return _then(_value.copyWith(
      landmarks: null == landmarks
          ? _value.landmarks
          : landmarks // ignore: cast_nullable_to_non_nullable
              as List<PoseLandmark>,
      timestamp: null == timestamp
          ? _value.timestamp
          : timestamp // ignore: cast_nullable_to_non_nullable
              as DateTime,
      confidence: null == confidence
          ? _value.confidence
          : confidence // ignore: cast_nullable_to_non_nullable
              as double,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$PoseResultImplCopyWith<$Res>
    implements $PoseResultCopyWith<$Res> {
  factory _$$PoseResultImplCopyWith(
          _$PoseResultImpl value, $Res Function(_$PoseResultImpl) then) =
      __$$PoseResultImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {List<PoseLandmark> landmarks, DateTime timestamp, double confidence});
}

/// @nodoc
class __$$PoseResultImplCopyWithImpl<$Res>
    extends _$PoseResultCopyWithImpl<$Res, _$PoseResultImpl>
    implements _$$PoseResultImplCopyWith<$Res> {
  __$$PoseResultImplCopyWithImpl(
      _$PoseResultImpl _value, $Res Function(_$PoseResultImpl) _then)
      : super(_value, _then);

  /// Create a copy of PoseResult
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? landmarks = null,
    Object? timestamp = null,
    Object? confidence = null,
  }) {
    return _then(_$PoseResultImpl(
      landmarks: null == landmarks
          ? _value._landmarks
          : landmarks // ignore: cast_nullable_to_non_nullable
              as List<PoseLandmark>,
      timestamp: null == timestamp
          ? _value.timestamp
          : timestamp // ignore: cast_nullable_to_non_nullable
              as DateTime,
      confidence: null == confidence
          ? _value.confidence
          : confidence // ignore: cast_nullable_to_non_nullable
              as double,
    ));
  }
}

/// @nodoc

class _$PoseResultImpl extends _PoseResult {
  const _$PoseResultImpl(
      {required final List<PoseLandmark> landmarks,
      required this.timestamp,
      this.confidence = 1.0})
      : _landmarks = landmarks,
        super._();

  /// List of detected landmarks (33 for full body).
  final List<PoseLandmark> _landmarks;

  /// List of detected landmarks (33 for full body).
  @override
  List<PoseLandmark> get landmarks {
    if (_landmarks is EqualUnmodifiableListView) return _landmarks;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_landmarks);
  }

  /// Timestamp when this pose was detected.
  @override
  final DateTime timestamp;

  /// Overall confidence score for the detection.
  @override
  @JsonKey()
  final double confidence;

  @override
  String toString() {
    return 'PoseResult(landmarks: $landmarks, timestamp: $timestamp, confidence: $confidence)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PoseResultImpl &&
            const DeepCollectionEquality()
                .equals(other._landmarks, _landmarks) &&
            (identical(other.timestamp, timestamp) ||
                other.timestamp == timestamp) &&
            (identical(other.confidence, confidence) ||
                other.confidence == confidence));
  }

  @override
  int get hashCode => Object.hash(runtimeType,
      const DeepCollectionEquality().hash(_landmarks), timestamp, confidence);

  /// Create a copy of PoseResult
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PoseResultImplCopyWith<_$PoseResultImpl> get copyWith =>
      __$$PoseResultImplCopyWithImpl<_$PoseResultImpl>(this, _$identity);
}

abstract class _PoseResult extends PoseResult {
  const factory _PoseResult(
      {required final List<PoseLandmark> landmarks,
      required final DateTime timestamp,
      final double confidence}) = _$PoseResultImpl;
  const _PoseResult._() : super._();

  /// List of detected landmarks (33 for full body).
  @override
  List<PoseLandmark> get landmarks;

  /// Timestamp when this pose was detected.
  @override
  DateTime get timestamp;

  /// Overall confidence score for the detection.
  @override
  double get confidence;

  /// Create a copy of PoseResult
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PoseResultImplCopyWith<_$PoseResultImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
