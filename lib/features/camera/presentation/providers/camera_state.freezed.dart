// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'camera_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$CameraState {
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function() requestingPermission,
    required TResult Function(CameraPermissionStatus status) permissionDenied,
    required TResult Function() initializing,
    required TResult Function(CameraLensDirection lensDirection) ready,
    required TResult Function(String message, String? code) error,
    required TResult Function() disposed,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initial,
    TResult? Function()? requestingPermission,
    TResult? Function(CameraPermissionStatus status)? permissionDenied,
    TResult? Function()? initializing,
    TResult? Function(CameraLensDirection lensDirection)? ready,
    TResult? Function(String message, String? code)? error,
    TResult? Function()? disposed,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function()? requestingPermission,
    TResult Function(CameraPermissionStatus status)? permissionDenied,
    TResult Function()? initializing,
    TResult Function(CameraLensDirection lensDirection)? ready,
    TResult Function(String message, String? code)? error,
    TResult Function()? disposed,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(CameraStateInitial value) initial,
    required TResult Function(CameraStateRequestingPermission value)
        requestingPermission,
    required TResult Function(CameraStatePermissionDenied value)
        permissionDenied,
    required TResult Function(CameraStateInitializing value) initializing,
    required TResult Function(CameraStateReady value) ready,
    required TResult Function(CameraStateError value) error,
    required TResult Function(CameraStateDisposed value) disposed,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(CameraStateInitial value)? initial,
    TResult? Function(CameraStateRequestingPermission value)?
        requestingPermission,
    TResult? Function(CameraStatePermissionDenied value)? permissionDenied,
    TResult? Function(CameraStateInitializing value)? initializing,
    TResult? Function(CameraStateReady value)? ready,
    TResult? Function(CameraStateError value)? error,
    TResult? Function(CameraStateDisposed value)? disposed,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(CameraStateInitial value)? initial,
    TResult Function(CameraStateRequestingPermission value)?
        requestingPermission,
    TResult Function(CameraStatePermissionDenied value)? permissionDenied,
    TResult Function(CameraStateInitializing value)? initializing,
    TResult Function(CameraStateReady value)? ready,
    TResult Function(CameraStateError value)? error,
    TResult Function(CameraStateDisposed value)? disposed,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CameraStateCopyWith<$Res> {
  factory $CameraStateCopyWith(
          CameraState value, $Res Function(CameraState) then) =
      _$CameraStateCopyWithImpl<$Res, CameraState>;
}

/// @nodoc
class _$CameraStateCopyWithImpl<$Res, $Val extends CameraState>
    implements $CameraStateCopyWith<$Res> {
  _$CameraStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of CameraState
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc
abstract class _$$CameraStateInitialImplCopyWith<$Res> {
  factory _$$CameraStateInitialImplCopyWith(_$CameraStateInitialImpl value,
          $Res Function(_$CameraStateInitialImpl) then) =
      __$$CameraStateInitialImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$CameraStateInitialImplCopyWithImpl<$Res>
    extends _$CameraStateCopyWithImpl<$Res, _$CameraStateInitialImpl>
    implements _$$CameraStateInitialImplCopyWith<$Res> {
  __$$CameraStateInitialImplCopyWithImpl(_$CameraStateInitialImpl _value,
      $Res Function(_$CameraStateInitialImpl) _then)
      : super(_value, _then);

  /// Create a copy of CameraState
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc

class _$CameraStateInitialImpl implements CameraStateInitial {
  const _$CameraStateInitialImpl();

  @override
  String toString() {
    return 'CameraState.initial()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is _$CameraStateInitialImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function() requestingPermission,
    required TResult Function(CameraPermissionStatus status) permissionDenied,
    required TResult Function() initializing,
    required TResult Function(CameraLensDirection lensDirection) ready,
    required TResult Function(String message, String? code) error,
    required TResult Function() disposed,
  }) {
    return initial();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initial,
    TResult? Function()? requestingPermission,
    TResult? Function(CameraPermissionStatus status)? permissionDenied,
    TResult? Function()? initializing,
    TResult? Function(CameraLensDirection lensDirection)? ready,
    TResult? Function(String message, String? code)? error,
    TResult? Function()? disposed,
  }) {
    return initial?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function()? requestingPermission,
    TResult Function(CameraPermissionStatus status)? permissionDenied,
    TResult Function()? initializing,
    TResult Function(CameraLensDirection lensDirection)? ready,
    TResult Function(String message, String? code)? error,
    TResult Function()? disposed,
    required TResult orElse(),
  }) {
    if (initial != null) {
      return initial();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(CameraStateInitial value) initial,
    required TResult Function(CameraStateRequestingPermission value)
        requestingPermission,
    required TResult Function(CameraStatePermissionDenied value)
        permissionDenied,
    required TResult Function(CameraStateInitializing value) initializing,
    required TResult Function(CameraStateReady value) ready,
    required TResult Function(CameraStateError value) error,
    required TResult Function(CameraStateDisposed value) disposed,
  }) {
    return initial(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(CameraStateInitial value)? initial,
    TResult? Function(CameraStateRequestingPermission value)?
        requestingPermission,
    TResult? Function(CameraStatePermissionDenied value)? permissionDenied,
    TResult? Function(CameraStateInitializing value)? initializing,
    TResult? Function(CameraStateReady value)? ready,
    TResult? Function(CameraStateError value)? error,
    TResult? Function(CameraStateDisposed value)? disposed,
  }) {
    return initial?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(CameraStateInitial value)? initial,
    TResult Function(CameraStateRequestingPermission value)?
        requestingPermission,
    TResult Function(CameraStatePermissionDenied value)? permissionDenied,
    TResult Function(CameraStateInitializing value)? initializing,
    TResult Function(CameraStateReady value)? ready,
    TResult Function(CameraStateError value)? error,
    TResult Function(CameraStateDisposed value)? disposed,
    required TResult orElse(),
  }) {
    if (initial != null) {
      return initial(this);
    }
    return orElse();
  }
}

abstract class CameraStateInitial implements CameraState {
  const factory CameraStateInitial() = _$CameraStateInitialImpl;
}

/// @nodoc
abstract class _$$CameraStateRequestingPermissionImplCopyWith<$Res> {
  factory _$$CameraStateRequestingPermissionImplCopyWith(
          _$CameraStateRequestingPermissionImpl value,
          $Res Function(_$CameraStateRequestingPermissionImpl) then) =
      __$$CameraStateRequestingPermissionImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$CameraStateRequestingPermissionImplCopyWithImpl<$Res>
    extends _$CameraStateCopyWithImpl<$Res,
        _$CameraStateRequestingPermissionImpl>
    implements _$$CameraStateRequestingPermissionImplCopyWith<$Res> {
  __$$CameraStateRequestingPermissionImplCopyWithImpl(
      _$CameraStateRequestingPermissionImpl _value,
      $Res Function(_$CameraStateRequestingPermissionImpl) _then)
      : super(_value, _then);

  /// Create a copy of CameraState
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc

class _$CameraStateRequestingPermissionImpl
    implements CameraStateRequestingPermission {
  const _$CameraStateRequestingPermissionImpl();

  @override
  String toString() {
    return 'CameraState.requestingPermission()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CameraStateRequestingPermissionImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function() requestingPermission,
    required TResult Function(CameraPermissionStatus status) permissionDenied,
    required TResult Function() initializing,
    required TResult Function(CameraLensDirection lensDirection) ready,
    required TResult Function(String message, String? code) error,
    required TResult Function() disposed,
  }) {
    return requestingPermission();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initial,
    TResult? Function()? requestingPermission,
    TResult? Function(CameraPermissionStatus status)? permissionDenied,
    TResult? Function()? initializing,
    TResult? Function(CameraLensDirection lensDirection)? ready,
    TResult? Function(String message, String? code)? error,
    TResult? Function()? disposed,
  }) {
    return requestingPermission?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function()? requestingPermission,
    TResult Function(CameraPermissionStatus status)? permissionDenied,
    TResult Function()? initializing,
    TResult Function(CameraLensDirection lensDirection)? ready,
    TResult Function(String message, String? code)? error,
    TResult Function()? disposed,
    required TResult orElse(),
  }) {
    if (requestingPermission != null) {
      return requestingPermission();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(CameraStateInitial value) initial,
    required TResult Function(CameraStateRequestingPermission value)
        requestingPermission,
    required TResult Function(CameraStatePermissionDenied value)
        permissionDenied,
    required TResult Function(CameraStateInitializing value) initializing,
    required TResult Function(CameraStateReady value) ready,
    required TResult Function(CameraStateError value) error,
    required TResult Function(CameraStateDisposed value) disposed,
  }) {
    return requestingPermission(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(CameraStateInitial value)? initial,
    TResult? Function(CameraStateRequestingPermission value)?
        requestingPermission,
    TResult? Function(CameraStatePermissionDenied value)? permissionDenied,
    TResult? Function(CameraStateInitializing value)? initializing,
    TResult? Function(CameraStateReady value)? ready,
    TResult? Function(CameraStateError value)? error,
    TResult? Function(CameraStateDisposed value)? disposed,
  }) {
    return requestingPermission?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(CameraStateInitial value)? initial,
    TResult Function(CameraStateRequestingPermission value)?
        requestingPermission,
    TResult Function(CameraStatePermissionDenied value)? permissionDenied,
    TResult Function(CameraStateInitializing value)? initializing,
    TResult Function(CameraStateReady value)? ready,
    TResult Function(CameraStateError value)? error,
    TResult Function(CameraStateDisposed value)? disposed,
    required TResult orElse(),
  }) {
    if (requestingPermission != null) {
      return requestingPermission(this);
    }
    return orElse();
  }
}

abstract class CameraStateRequestingPermission implements CameraState {
  const factory CameraStateRequestingPermission() =
      _$CameraStateRequestingPermissionImpl;
}

/// @nodoc
abstract class _$$CameraStatePermissionDeniedImplCopyWith<$Res> {
  factory _$$CameraStatePermissionDeniedImplCopyWith(
          _$CameraStatePermissionDeniedImpl value,
          $Res Function(_$CameraStatePermissionDeniedImpl) then) =
      __$$CameraStatePermissionDeniedImplCopyWithImpl<$Res>;
  @useResult
  $Res call({CameraPermissionStatus status});
}

/// @nodoc
class __$$CameraStatePermissionDeniedImplCopyWithImpl<$Res>
    extends _$CameraStateCopyWithImpl<$Res, _$CameraStatePermissionDeniedImpl>
    implements _$$CameraStatePermissionDeniedImplCopyWith<$Res> {
  __$$CameraStatePermissionDeniedImplCopyWithImpl(
      _$CameraStatePermissionDeniedImpl _value,
      $Res Function(_$CameraStatePermissionDeniedImpl) _then)
      : super(_value, _then);

  /// Create a copy of CameraState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? status = null,
  }) {
    return _then(_$CameraStatePermissionDeniedImpl(
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as CameraPermissionStatus,
    ));
  }
}

/// @nodoc

class _$CameraStatePermissionDeniedImpl implements CameraStatePermissionDenied {
  const _$CameraStatePermissionDeniedImpl({required this.status});

  @override
  final CameraPermissionStatus status;

  @override
  String toString() {
    return 'CameraState.permissionDenied(status: $status)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CameraStatePermissionDeniedImpl &&
            (identical(other.status, status) || other.status == status));
  }

  @override
  int get hashCode => Object.hash(runtimeType, status);

  /// Create a copy of CameraState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CameraStatePermissionDeniedImplCopyWith<_$CameraStatePermissionDeniedImpl>
      get copyWith => __$$CameraStatePermissionDeniedImplCopyWithImpl<
          _$CameraStatePermissionDeniedImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function() requestingPermission,
    required TResult Function(CameraPermissionStatus status) permissionDenied,
    required TResult Function() initializing,
    required TResult Function(CameraLensDirection lensDirection) ready,
    required TResult Function(String message, String? code) error,
    required TResult Function() disposed,
  }) {
    return permissionDenied(status);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initial,
    TResult? Function()? requestingPermission,
    TResult? Function(CameraPermissionStatus status)? permissionDenied,
    TResult? Function()? initializing,
    TResult? Function(CameraLensDirection lensDirection)? ready,
    TResult? Function(String message, String? code)? error,
    TResult? Function()? disposed,
  }) {
    return permissionDenied?.call(status);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function()? requestingPermission,
    TResult Function(CameraPermissionStatus status)? permissionDenied,
    TResult Function()? initializing,
    TResult Function(CameraLensDirection lensDirection)? ready,
    TResult Function(String message, String? code)? error,
    TResult Function()? disposed,
    required TResult orElse(),
  }) {
    if (permissionDenied != null) {
      return permissionDenied(status);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(CameraStateInitial value) initial,
    required TResult Function(CameraStateRequestingPermission value)
        requestingPermission,
    required TResult Function(CameraStatePermissionDenied value)
        permissionDenied,
    required TResult Function(CameraStateInitializing value) initializing,
    required TResult Function(CameraStateReady value) ready,
    required TResult Function(CameraStateError value) error,
    required TResult Function(CameraStateDisposed value) disposed,
  }) {
    return permissionDenied(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(CameraStateInitial value)? initial,
    TResult? Function(CameraStateRequestingPermission value)?
        requestingPermission,
    TResult? Function(CameraStatePermissionDenied value)? permissionDenied,
    TResult? Function(CameraStateInitializing value)? initializing,
    TResult? Function(CameraStateReady value)? ready,
    TResult? Function(CameraStateError value)? error,
    TResult? Function(CameraStateDisposed value)? disposed,
  }) {
    return permissionDenied?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(CameraStateInitial value)? initial,
    TResult Function(CameraStateRequestingPermission value)?
        requestingPermission,
    TResult Function(CameraStatePermissionDenied value)? permissionDenied,
    TResult Function(CameraStateInitializing value)? initializing,
    TResult Function(CameraStateReady value)? ready,
    TResult Function(CameraStateError value)? error,
    TResult Function(CameraStateDisposed value)? disposed,
    required TResult orElse(),
  }) {
    if (permissionDenied != null) {
      return permissionDenied(this);
    }
    return orElse();
  }
}

abstract class CameraStatePermissionDenied implements CameraState {
  const factory CameraStatePermissionDenied(
          {required final CameraPermissionStatus status}) =
      _$CameraStatePermissionDeniedImpl;

  CameraPermissionStatus get status;

  /// Create a copy of CameraState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CameraStatePermissionDeniedImplCopyWith<_$CameraStatePermissionDeniedImpl>
      get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$CameraStateInitializingImplCopyWith<$Res> {
  factory _$$CameraStateInitializingImplCopyWith(
          _$CameraStateInitializingImpl value,
          $Res Function(_$CameraStateInitializingImpl) then) =
      __$$CameraStateInitializingImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$CameraStateInitializingImplCopyWithImpl<$Res>
    extends _$CameraStateCopyWithImpl<$Res, _$CameraStateInitializingImpl>
    implements _$$CameraStateInitializingImplCopyWith<$Res> {
  __$$CameraStateInitializingImplCopyWithImpl(
      _$CameraStateInitializingImpl _value,
      $Res Function(_$CameraStateInitializingImpl) _then)
      : super(_value, _then);

  /// Create a copy of CameraState
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc

class _$CameraStateInitializingImpl implements CameraStateInitializing {
  const _$CameraStateInitializingImpl();

  @override
  String toString() {
    return 'CameraState.initializing()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CameraStateInitializingImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function() requestingPermission,
    required TResult Function(CameraPermissionStatus status) permissionDenied,
    required TResult Function() initializing,
    required TResult Function(CameraLensDirection lensDirection) ready,
    required TResult Function(String message, String? code) error,
    required TResult Function() disposed,
  }) {
    return initializing();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initial,
    TResult? Function()? requestingPermission,
    TResult? Function(CameraPermissionStatus status)? permissionDenied,
    TResult? Function()? initializing,
    TResult? Function(CameraLensDirection lensDirection)? ready,
    TResult? Function(String message, String? code)? error,
    TResult? Function()? disposed,
  }) {
    return initializing?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function()? requestingPermission,
    TResult Function(CameraPermissionStatus status)? permissionDenied,
    TResult Function()? initializing,
    TResult Function(CameraLensDirection lensDirection)? ready,
    TResult Function(String message, String? code)? error,
    TResult Function()? disposed,
    required TResult orElse(),
  }) {
    if (initializing != null) {
      return initializing();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(CameraStateInitial value) initial,
    required TResult Function(CameraStateRequestingPermission value)
        requestingPermission,
    required TResult Function(CameraStatePermissionDenied value)
        permissionDenied,
    required TResult Function(CameraStateInitializing value) initializing,
    required TResult Function(CameraStateReady value) ready,
    required TResult Function(CameraStateError value) error,
    required TResult Function(CameraStateDisposed value) disposed,
  }) {
    return initializing(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(CameraStateInitial value)? initial,
    TResult? Function(CameraStateRequestingPermission value)?
        requestingPermission,
    TResult? Function(CameraStatePermissionDenied value)? permissionDenied,
    TResult? Function(CameraStateInitializing value)? initializing,
    TResult? Function(CameraStateReady value)? ready,
    TResult? Function(CameraStateError value)? error,
    TResult? Function(CameraStateDisposed value)? disposed,
  }) {
    return initializing?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(CameraStateInitial value)? initial,
    TResult Function(CameraStateRequestingPermission value)?
        requestingPermission,
    TResult Function(CameraStatePermissionDenied value)? permissionDenied,
    TResult Function(CameraStateInitializing value)? initializing,
    TResult Function(CameraStateReady value)? ready,
    TResult Function(CameraStateError value)? error,
    TResult Function(CameraStateDisposed value)? disposed,
    required TResult orElse(),
  }) {
    if (initializing != null) {
      return initializing(this);
    }
    return orElse();
  }
}

abstract class CameraStateInitializing implements CameraState {
  const factory CameraStateInitializing() = _$CameraStateInitializingImpl;
}

/// @nodoc
abstract class _$$CameraStateReadyImplCopyWith<$Res> {
  factory _$$CameraStateReadyImplCopyWith(_$CameraStateReadyImpl value,
          $Res Function(_$CameraStateReadyImpl) then) =
      __$$CameraStateReadyImplCopyWithImpl<$Res>;
  @useResult
  $Res call({CameraLensDirection lensDirection});
}

/// @nodoc
class __$$CameraStateReadyImplCopyWithImpl<$Res>
    extends _$CameraStateCopyWithImpl<$Res, _$CameraStateReadyImpl>
    implements _$$CameraStateReadyImplCopyWith<$Res> {
  __$$CameraStateReadyImplCopyWithImpl(_$CameraStateReadyImpl _value,
      $Res Function(_$CameraStateReadyImpl) _then)
      : super(_value, _then);

  /// Create a copy of CameraState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? lensDirection = null,
  }) {
    return _then(_$CameraStateReadyImpl(
      lensDirection: null == lensDirection
          ? _value.lensDirection
          : lensDirection // ignore: cast_nullable_to_non_nullable
              as CameraLensDirection,
    ));
  }
}

/// @nodoc

class _$CameraStateReadyImpl implements CameraStateReady {
  const _$CameraStateReadyImpl({required this.lensDirection});

  @override
  final CameraLensDirection lensDirection;

  @override
  String toString() {
    return 'CameraState.ready(lensDirection: $lensDirection)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CameraStateReadyImpl &&
            (identical(other.lensDirection, lensDirection) ||
                other.lensDirection == lensDirection));
  }

  @override
  int get hashCode => Object.hash(runtimeType, lensDirection);

  /// Create a copy of CameraState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CameraStateReadyImplCopyWith<_$CameraStateReadyImpl> get copyWith =>
      __$$CameraStateReadyImplCopyWithImpl<_$CameraStateReadyImpl>(
          this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function() requestingPermission,
    required TResult Function(CameraPermissionStatus status) permissionDenied,
    required TResult Function() initializing,
    required TResult Function(CameraLensDirection lensDirection) ready,
    required TResult Function(String message, String? code) error,
    required TResult Function() disposed,
  }) {
    return ready(lensDirection);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initial,
    TResult? Function()? requestingPermission,
    TResult? Function(CameraPermissionStatus status)? permissionDenied,
    TResult? Function()? initializing,
    TResult? Function(CameraLensDirection lensDirection)? ready,
    TResult? Function(String message, String? code)? error,
    TResult? Function()? disposed,
  }) {
    return ready?.call(lensDirection);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function()? requestingPermission,
    TResult Function(CameraPermissionStatus status)? permissionDenied,
    TResult Function()? initializing,
    TResult Function(CameraLensDirection lensDirection)? ready,
    TResult Function(String message, String? code)? error,
    TResult Function()? disposed,
    required TResult orElse(),
  }) {
    if (ready != null) {
      return ready(lensDirection);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(CameraStateInitial value) initial,
    required TResult Function(CameraStateRequestingPermission value)
        requestingPermission,
    required TResult Function(CameraStatePermissionDenied value)
        permissionDenied,
    required TResult Function(CameraStateInitializing value) initializing,
    required TResult Function(CameraStateReady value) ready,
    required TResult Function(CameraStateError value) error,
    required TResult Function(CameraStateDisposed value) disposed,
  }) {
    return ready(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(CameraStateInitial value)? initial,
    TResult? Function(CameraStateRequestingPermission value)?
        requestingPermission,
    TResult? Function(CameraStatePermissionDenied value)? permissionDenied,
    TResult? Function(CameraStateInitializing value)? initializing,
    TResult? Function(CameraStateReady value)? ready,
    TResult? Function(CameraStateError value)? error,
    TResult? Function(CameraStateDisposed value)? disposed,
  }) {
    return ready?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(CameraStateInitial value)? initial,
    TResult Function(CameraStateRequestingPermission value)?
        requestingPermission,
    TResult Function(CameraStatePermissionDenied value)? permissionDenied,
    TResult Function(CameraStateInitializing value)? initializing,
    TResult Function(CameraStateReady value)? ready,
    TResult Function(CameraStateError value)? error,
    TResult Function(CameraStateDisposed value)? disposed,
    required TResult orElse(),
  }) {
    if (ready != null) {
      return ready(this);
    }
    return orElse();
  }
}

abstract class CameraStateReady implements CameraState {
  const factory CameraStateReady(
          {required final CameraLensDirection lensDirection}) =
      _$CameraStateReadyImpl;

  CameraLensDirection get lensDirection;

  /// Create a copy of CameraState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CameraStateReadyImplCopyWith<_$CameraStateReadyImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$CameraStateErrorImplCopyWith<$Res> {
  factory _$$CameraStateErrorImplCopyWith(_$CameraStateErrorImpl value,
          $Res Function(_$CameraStateErrorImpl) then) =
      __$$CameraStateErrorImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String message, String? code});
}

/// @nodoc
class __$$CameraStateErrorImplCopyWithImpl<$Res>
    extends _$CameraStateCopyWithImpl<$Res, _$CameraStateErrorImpl>
    implements _$$CameraStateErrorImplCopyWith<$Res> {
  __$$CameraStateErrorImplCopyWithImpl(_$CameraStateErrorImpl _value,
      $Res Function(_$CameraStateErrorImpl) _then)
      : super(_value, _then);

  /// Create a copy of CameraState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? message = null,
    Object? code = freezed,
  }) {
    return _then(_$CameraStateErrorImpl(
      message: null == message
          ? _value.message
          : message // ignore: cast_nullable_to_non_nullable
              as String,
      code: freezed == code
          ? _value.code
          : code // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc

class _$CameraStateErrorImpl implements CameraStateError {
  const _$CameraStateErrorImpl({required this.message, this.code});

  @override
  final String message;
  @override
  final String? code;

  @override
  String toString() {
    return 'CameraState.error(message: $message, code: $code)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CameraStateErrorImpl &&
            (identical(other.message, message) || other.message == message) &&
            (identical(other.code, code) || other.code == code));
  }

  @override
  int get hashCode => Object.hash(runtimeType, message, code);

  /// Create a copy of CameraState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CameraStateErrorImplCopyWith<_$CameraStateErrorImpl> get copyWith =>
      __$$CameraStateErrorImplCopyWithImpl<_$CameraStateErrorImpl>(
          this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function() requestingPermission,
    required TResult Function(CameraPermissionStatus status) permissionDenied,
    required TResult Function() initializing,
    required TResult Function(CameraLensDirection lensDirection) ready,
    required TResult Function(String message, String? code) error,
    required TResult Function() disposed,
  }) {
    return error(message, code);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initial,
    TResult? Function()? requestingPermission,
    TResult? Function(CameraPermissionStatus status)? permissionDenied,
    TResult? Function()? initializing,
    TResult? Function(CameraLensDirection lensDirection)? ready,
    TResult? Function(String message, String? code)? error,
    TResult? Function()? disposed,
  }) {
    return error?.call(message, code);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function()? requestingPermission,
    TResult Function(CameraPermissionStatus status)? permissionDenied,
    TResult Function()? initializing,
    TResult Function(CameraLensDirection lensDirection)? ready,
    TResult Function(String message, String? code)? error,
    TResult Function()? disposed,
    required TResult orElse(),
  }) {
    if (error != null) {
      return error(message, code);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(CameraStateInitial value) initial,
    required TResult Function(CameraStateRequestingPermission value)
        requestingPermission,
    required TResult Function(CameraStatePermissionDenied value)
        permissionDenied,
    required TResult Function(CameraStateInitializing value) initializing,
    required TResult Function(CameraStateReady value) ready,
    required TResult Function(CameraStateError value) error,
    required TResult Function(CameraStateDisposed value) disposed,
  }) {
    return error(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(CameraStateInitial value)? initial,
    TResult? Function(CameraStateRequestingPermission value)?
        requestingPermission,
    TResult? Function(CameraStatePermissionDenied value)? permissionDenied,
    TResult? Function(CameraStateInitializing value)? initializing,
    TResult? Function(CameraStateReady value)? ready,
    TResult? Function(CameraStateError value)? error,
    TResult? Function(CameraStateDisposed value)? disposed,
  }) {
    return error?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(CameraStateInitial value)? initial,
    TResult Function(CameraStateRequestingPermission value)?
        requestingPermission,
    TResult Function(CameraStatePermissionDenied value)? permissionDenied,
    TResult Function(CameraStateInitializing value)? initializing,
    TResult Function(CameraStateReady value)? ready,
    TResult Function(CameraStateError value)? error,
    TResult Function(CameraStateDisposed value)? disposed,
    required TResult orElse(),
  }) {
    if (error != null) {
      return error(this);
    }
    return orElse();
  }
}

abstract class CameraStateError implements CameraState {
  const factory CameraStateError(
      {required final String message,
      final String? code}) = _$CameraStateErrorImpl;

  String get message;
  String? get code;

  /// Create a copy of CameraState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CameraStateErrorImplCopyWith<_$CameraStateErrorImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$CameraStateDisposedImplCopyWith<$Res> {
  factory _$$CameraStateDisposedImplCopyWith(_$CameraStateDisposedImpl value,
          $Res Function(_$CameraStateDisposedImpl) then) =
      __$$CameraStateDisposedImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$CameraStateDisposedImplCopyWithImpl<$Res>
    extends _$CameraStateCopyWithImpl<$Res, _$CameraStateDisposedImpl>
    implements _$$CameraStateDisposedImplCopyWith<$Res> {
  __$$CameraStateDisposedImplCopyWithImpl(_$CameraStateDisposedImpl _value,
      $Res Function(_$CameraStateDisposedImpl) _then)
      : super(_value, _then);

  /// Create a copy of CameraState
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc

class _$CameraStateDisposedImpl implements CameraStateDisposed {
  const _$CameraStateDisposedImpl();

  @override
  String toString() {
    return 'CameraState.disposed()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CameraStateDisposedImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function() requestingPermission,
    required TResult Function(CameraPermissionStatus status) permissionDenied,
    required TResult Function() initializing,
    required TResult Function(CameraLensDirection lensDirection) ready,
    required TResult Function(String message, String? code) error,
    required TResult Function() disposed,
  }) {
    return disposed();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initial,
    TResult? Function()? requestingPermission,
    TResult? Function(CameraPermissionStatus status)? permissionDenied,
    TResult? Function()? initializing,
    TResult? Function(CameraLensDirection lensDirection)? ready,
    TResult? Function(String message, String? code)? error,
    TResult? Function()? disposed,
  }) {
    return disposed?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function()? requestingPermission,
    TResult Function(CameraPermissionStatus status)? permissionDenied,
    TResult Function()? initializing,
    TResult Function(CameraLensDirection lensDirection)? ready,
    TResult Function(String message, String? code)? error,
    TResult Function()? disposed,
    required TResult orElse(),
  }) {
    if (disposed != null) {
      return disposed();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(CameraStateInitial value) initial,
    required TResult Function(CameraStateRequestingPermission value)
        requestingPermission,
    required TResult Function(CameraStatePermissionDenied value)
        permissionDenied,
    required TResult Function(CameraStateInitializing value) initializing,
    required TResult Function(CameraStateReady value) ready,
    required TResult Function(CameraStateError value) error,
    required TResult Function(CameraStateDisposed value) disposed,
  }) {
    return disposed(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(CameraStateInitial value)? initial,
    TResult? Function(CameraStateRequestingPermission value)?
        requestingPermission,
    TResult? Function(CameraStatePermissionDenied value)? permissionDenied,
    TResult? Function(CameraStateInitializing value)? initializing,
    TResult? Function(CameraStateReady value)? ready,
    TResult? Function(CameraStateError value)? error,
    TResult? Function(CameraStateDisposed value)? disposed,
  }) {
    return disposed?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(CameraStateInitial value)? initial,
    TResult Function(CameraStateRequestingPermission value)?
        requestingPermission,
    TResult Function(CameraStatePermissionDenied value)? permissionDenied,
    TResult Function(CameraStateInitializing value)? initializing,
    TResult Function(CameraStateReady value)? ready,
    TResult Function(CameraStateError value)? error,
    TResult Function(CameraStateDisposed value)? disposed,
    required TResult orElse(),
  }) {
    if (disposed != null) {
      return disposed(this);
    }
    return orElse();
  }
}

abstract class CameraStateDisposed implements CameraState {
  const factory CameraStateDisposed() = _$CameraStateDisposedImpl;
}
