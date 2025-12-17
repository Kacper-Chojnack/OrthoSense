// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'camera_frame.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$CameraFrame {
  /// Raw image bytes (platform-agnostic).
  Uint8List get bytes => throw _privateConstructorUsedError;

  /// Frame width in pixels.
  int get width => throw _privateConstructorUsedError;

  /// Frame height in pixels.
  int get height => throw _privateConstructorUsedError;

  /// Timestamp when frame was captured.
  DateTime get timestamp => throw _privateConstructorUsedError;

  /// Image format identifier (e.g., 'yuv420', 'bgra8888').
  String get format => throw _privateConstructorUsedError;

  /// Rotation in degrees (0, 90, 180, 270).
  int get rotation => throw _privateConstructorUsedError;

  /// Create a copy of CameraFrame
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CameraFrameCopyWith<CameraFrame> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CameraFrameCopyWith<$Res> {
  factory $CameraFrameCopyWith(
          CameraFrame value, $Res Function(CameraFrame) then) =
      _$CameraFrameCopyWithImpl<$Res, CameraFrame>;
  @useResult
  $Res call(
      {Uint8List bytes,
      int width,
      int height,
      DateTime timestamp,
      String format,
      int rotation});
}

/// @nodoc
class _$CameraFrameCopyWithImpl<$Res, $Val extends CameraFrame>
    implements $CameraFrameCopyWith<$Res> {
  _$CameraFrameCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of CameraFrame
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? bytes = null,
    Object? width = null,
    Object? height = null,
    Object? timestamp = null,
    Object? format = null,
    Object? rotation = null,
  }) {
    return _then(_value.copyWith(
      bytes: null == bytes
          ? _value.bytes
          : bytes // ignore: cast_nullable_to_non_nullable
              as Uint8List,
      width: null == width
          ? _value.width
          : width // ignore: cast_nullable_to_non_nullable
              as int,
      height: null == height
          ? _value.height
          : height // ignore: cast_nullable_to_non_nullable
              as int,
      timestamp: null == timestamp
          ? _value.timestamp
          : timestamp // ignore: cast_nullable_to_non_nullable
              as DateTime,
      format: null == format
          ? _value.format
          : format // ignore: cast_nullable_to_non_nullable
              as String,
      rotation: null == rotation
          ? _value.rotation
          : rotation // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$CameraFrameImplCopyWith<$Res>
    implements $CameraFrameCopyWith<$Res> {
  factory _$$CameraFrameImplCopyWith(
          _$CameraFrameImpl value, $Res Function(_$CameraFrameImpl) then) =
      __$$CameraFrameImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {Uint8List bytes,
      int width,
      int height,
      DateTime timestamp,
      String format,
      int rotation});
}

/// @nodoc
class __$$CameraFrameImplCopyWithImpl<$Res>
    extends _$CameraFrameCopyWithImpl<$Res, _$CameraFrameImpl>
    implements _$$CameraFrameImplCopyWith<$Res> {
  __$$CameraFrameImplCopyWithImpl(
      _$CameraFrameImpl _value, $Res Function(_$CameraFrameImpl) _then)
      : super(_value, _then);

  /// Create a copy of CameraFrame
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? bytes = null,
    Object? width = null,
    Object? height = null,
    Object? timestamp = null,
    Object? format = null,
    Object? rotation = null,
  }) {
    return _then(_$CameraFrameImpl(
      bytes: null == bytes
          ? _value.bytes
          : bytes // ignore: cast_nullable_to_non_nullable
              as Uint8List,
      width: null == width
          ? _value.width
          : width // ignore: cast_nullable_to_non_nullable
              as int,
      height: null == height
          ? _value.height
          : height // ignore: cast_nullable_to_non_nullable
              as int,
      timestamp: null == timestamp
          ? _value.timestamp
          : timestamp // ignore: cast_nullable_to_non_nullable
              as DateTime,
      format: null == format
          ? _value.format
          : format // ignore: cast_nullable_to_non_nullable
              as String,
      rotation: null == rotation
          ? _value.rotation
          : rotation // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc

class _$CameraFrameImpl extends _CameraFrame {
  const _$CameraFrameImpl(
      {required this.bytes,
      required this.width,
      required this.height,
      required this.timestamp,
      required this.format,
      this.rotation = 0})
      : super._();

  /// Raw image bytes (platform-agnostic).
  @override
  final Uint8List bytes;

  /// Frame width in pixels.
  @override
  final int width;

  /// Frame height in pixels.
  @override
  final int height;

  /// Timestamp when frame was captured.
  @override
  final DateTime timestamp;

  /// Image format identifier (e.g., 'yuv420', 'bgra8888').
  @override
  final String format;

  /// Rotation in degrees (0, 90, 180, 270).
  @override
  @JsonKey()
  final int rotation;

  @override
  String toString() {
    return 'CameraFrame(bytes: $bytes, width: $width, height: $height, timestamp: $timestamp, format: $format, rotation: $rotation)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CameraFrameImpl &&
            const DeepCollectionEquality().equals(other.bytes, bytes) &&
            (identical(other.width, width) || other.width == width) &&
            (identical(other.height, height) || other.height == height) &&
            (identical(other.timestamp, timestamp) ||
                other.timestamp == timestamp) &&
            (identical(other.format, format) || other.format == format) &&
            (identical(other.rotation, rotation) ||
                other.rotation == rotation));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      const DeepCollectionEquality().hash(bytes),
      width,
      height,
      timestamp,
      format,
      rotation);

  /// Create a copy of CameraFrame
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CameraFrameImplCopyWith<_$CameraFrameImpl> get copyWith =>
      __$$CameraFrameImplCopyWithImpl<_$CameraFrameImpl>(this, _$identity);
}

abstract class _CameraFrame extends CameraFrame {
  const factory _CameraFrame(
      {required final Uint8List bytes,
      required final int width,
      required final int height,
      required final DateTime timestamp,
      required final String format,
      final int rotation}) = _$CameraFrameImpl;
  const _CameraFrame._() : super._();

  /// Raw image bytes (platform-agnostic).
  @override
  Uint8List get bytes;

  /// Frame width in pixels.
  @override
  int get width;

  /// Frame height in pixels.
  @override
  int get height;

  /// Timestamp when frame was captured.
  @override
  DateTime get timestamp;

  /// Image format identifier (e.g., 'yuv420', 'bgra8888').
  @override
  String get format;

  /// Rotation in degrees (0, 90, 180, 270).
  @override
  int get rotation;

  /// Create a copy of CameraFrame
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CameraFrameImplCopyWith<_$CameraFrameImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
