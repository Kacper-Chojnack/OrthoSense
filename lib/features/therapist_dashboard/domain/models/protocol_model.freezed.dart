// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'protocol_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ProtocolModel {

 String get id; String get name;@JsonKey(name: 'created_by') String get createdBy; String get description; String get condition; String get phase;@JsonKey(name: 'duration_weeks') int? get durationWeeks;@JsonKey(name: 'frequency_per_week') int get frequencyPerWeek; ProtocolStatus get status;@JsonKey(name: 'is_template') bool get isTemplate;@JsonKey(name: 'created_at') DateTime? get createdAt;
/// Create a copy of ProtocolModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProtocolModelCopyWith<ProtocolModel> get copyWith => _$ProtocolModelCopyWithImpl<ProtocolModel>(this as ProtocolModel, _$identity);

  /// Serializes this ProtocolModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProtocolModel&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy)&&(identical(other.description, description) || other.description == description)&&(identical(other.condition, condition) || other.condition == condition)&&(identical(other.phase, phase) || other.phase == phase)&&(identical(other.durationWeeks, durationWeeks) || other.durationWeeks == durationWeeks)&&(identical(other.frequencyPerWeek, frequencyPerWeek) || other.frequencyPerWeek == frequencyPerWeek)&&(identical(other.status, status) || other.status == status)&&(identical(other.isTemplate, isTemplate) || other.isTemplate == isTemplate)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,createdBy,description,condition,phase,durationWeeks,frequencyPerWeek,status,isTemplate,createdAt);

@override
String toString() {
  return 'ProtocolModel(id: $id, name: $name, createdBy: $createdBy, description: $description, condition: $condition, phase: $phase, durationWeeks: $durationWeeks, frequencyPerWeek: $frequencyPerWeek, status: $status, isTemplate: $isTemplate, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $ProtocolModelCopyWith<$Res>  {
  factory $ProtocolModelCopyWith(ProtocolModel value, $Res Function(ProtocolModel) _then) = _$ProtocolModelCopyWithImpl;
@useResult
$Res call({
 String id, String name,@JsonKey(name: 'created_by') String createdBy, String description, String condition, String phase,@JsonKey(name: 'duration_weeks') int? durationWeeks,@JsonKey(name: 'frequency_per_week') int frequencyPerWeek, ProtocolStatus status,@JsonKey(name: 'is_template') bool isTemplate,@JsonKey(name: 'created_at') DateTime? createdAt
});




}
/// @nodoc
class _$ProtocolModelCopyWithImpl<$Res>
    implements $ProtocolModelCopyWith<$Res> {
  _$ProtocolModelCopyWithImpl(this._self, this._then);

  final ProtocolModel _self;
  final $Res Function(ProtocolModel) _then;

/// Create a copy of ProtocolModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? createdBy = null,Object? description = null,Object? condition = null,Object? phase = null,Object? durationWeeks = freezed,Object? frequencyPerWeek = null,Object? status = null,Object? isTemplate = null,Object? createdAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,createdBy: null == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,condition: null == condition ? _self.condition : condition // ignore: cast_nullable_to_non_nullable
as String,phase: null == phase ? _self.phase : phase // ignore: cast_nullable_to_non_nullable
as String,durationWeeks: freezed == durationWeeks ? _self.durationWeeks : durationWeeks // ignore: cast_nullable_to_non_nullable
as int?,frequencyPerWeek: null == frequencyPerWeek ? _self.frequencyPerWeek : frequencyPerWeek // ignore: cast_nullable_to_non_nullable
as int,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as ProtocolStatus,isTemplate: null == isTemplate ? _self.isTemplate : isTemplate // ignore: cast_nullable_to_non_nullable
as bool,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [ProtocolModel].
extension ProtocolModelPatterns on ProtocolModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProtocolModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProtocolModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProtocolModel value)  $default,){
final _that = this;
switch (_that) {
case _ProtocolModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProtocolModel value)?  $default,){
final _that = this;
switch (_that) {
case _ProtocolModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name, @JsonKey(name: 'created_by')  String createdBy,  String description,  String condition,  String phase, @JsonKey(name: 'duration_weeks')  int? durationWeeks, @JsonKey(name: 'frequency_per_week')  int frequencyPerWeek,  ProtocolStatus status, @JsonKey(name: 'is_template')  bool isTemplate, @JsonKey(name: 'created_at')  DateTime? createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProtocolModel() when $default != null:
return $default(_that.id,_that.name,_that.createdBy,_that.description,_that.condition,_that.phase,_that.durationWeeks,_that.frequencyPerWeek,_that.status,_that.isTemplate,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name, @JsonKey(name: 'created_by')  String createdBy,  String description,  String condition,  String phase, @JsonKey(name: 'duration_weeks')  int? durationWeeks, @JsonKey(name: 'frequency_per_week')  int frequencyPerWeek,  ProtocolStatus status, @JsonKey(name: 'is_template')  bool isTemplate, @JsonKey(name: 'created_at')  DateTime? createdAt)  $default,) {final _that = this;
switch (_that) {
case _ProtocolModel():
return $default(_that.id,_that.name,_that.createdBy,_that.description,_that.condition,_that.phase,_that.durationWeeks,_that.frequencyPerWeek,_that.status,_that.isTemplate,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name, @JsonKey(name: 'created_by')  String createdBy,  String description,  String condition,  String phase, @JsonKey(name: 'duration_weeks')  int? durationWeeks, @JsonKey(name: 'frequency_per_week')  int frequencyPerWeek,  ProtocolStatus status, @JsonKey(name: 'is_template')  bool isTemplate, @JsonKey(name: 'created_at')  DateTime? createdAt)?  $default,) {final _that = this;
switch (_that) {
case _ProtocolModel() when $default != null:
return $default(_that.id,_that.name,_that.createdBy,_that.description,_that.condition,_that.phase,_that.durationWeeks,_that.frequencyPerWeek,_that.status,_that.isTemplate,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ProtocolModel implements ProtocolModel {
  const _ProtocolModel({required this.id, required this.name, @JsonKey(name: 'created_by') required this.createdBy, this.description = '', this.condition = '', this.phase = '', @JsonKey(name: 'duration_weeks') this.durationWeeks, @JsonKey(name: 'frequency_per_week') this.frequencyPerWeek = 3, this.status = ProtocolStatus.draft, @JsonKey(name: 'is_template') this.isTemplate = true, @JsonKey(name: 'created_at') this.createdAt});
  factory _ProtocolModel.fromJson(Map<String, dynamic> json) => _$ProtocolModelFromJson(json);

@override final  String id;
@override final  String name;
@override@JsonKey(name: 'created_by') final  String createdBy;
@override@JsonKey() final  String description;
@override@JsonKey() final  String condition;
@override@JsonKey() final  String phase;
@override@JsonKey(name: 'duration_weeks') final  int? durationWeeks;
@override@JsonKey(name: 'frequency_per_week') final  int frequencyPerWeek;
@override@JsonKey() final  ProtocolStatus status;
@override@JsonKey(name: 'is_template') final  bool isTemplate;
@override@JsonKey(name: 'created_at') final  DateTime? createdAt;

/// Create a copy of ProtocolModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProtocolModelCopyWith<_ProtocolModel> get copyWith => __$ProtocolModelCopyWithImpl<_ProtocolModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ProtocolModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProtocolModel&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy)&&(identical(other.description, description) || other.description == description)&&(identical(other.condition, condition) || other.condition == condition)&&(identical(other.phase, phase) || other.phase == phase)&&(identical(other.durationWeeks, durationWeeks) || other.durationWeeks == durationWeeks)&&(identical(other.frequencyPerWeek, frequencyPerWeek) || other.frequencyPerWeek == frequencyPerWeek)&&(identical(other.status, status) || other.status == status)&&(identical(other.isTemplate, isTemplate) || other.isTemplate == isTemplate)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,createdBy,description,condition,phase,durationWeeks,frequencyPerWeek,status,isTemplate,createdAt);

@override
String toString() {
  return 'ProtocolModel(id: $id, name: $name, createdBy: $createdBy, description: $description, condition: $condition, phase: $phase, durationWeeks: $durationWeeks, frequencyPerWeek: $frequencyPerWeek, status: $status, isTemplate: $isTemplate, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$ProtocolModelCopyWith<$Res> implements $ProtocolModelCopyWith<$Res> {
  factory _$ProtocolModelCopyWith(_ProtocolModel value, $Res Function(_ProtocolModel) _then) = __$ProtocolModelCopyWithImpl;
@override @useResult
$Res call({
 String id, String name,@JsonKey(name: 'created_by') String createdBy, String description, String condition, String phase,@JsonKey(name: 'duration_weeks') int? durationWeeks,@JsonKey(name: 'frequency_per_week') int frequencyPerWeek, ProtocolStatus status,@JsonKey(name: 'is_template') bool isTemplate,@JsonKey(name: 'created_at') DateTime? createdAt
});




}
/// @nodoc
class __$ProtocolModelCopyWithImpl<$Res>
    implements _$ProtocolModelCopyWith<$Res> {
  __$ProtocolModelCopyWithImpl(this._self, this._then);

  final _ProtocolModel _self;
  final $Res Function(_ProtocolModel) _then;

/// Create a copy of ProtocolModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? createdBy = null,Object? description = null,Object? condition = null,Object? phase = null,Object? durationWeeks = freezed,Object? frequencyPerWeek = null,Object? status = null,Object? isTemplate = null,Object? createdAt = freezed,}) {
  return _then(_ProtocolModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,createdBy: null == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,condition: null == condition ? _self.condition : condition // ignore: cast_nullable_to_non_nullable
as String,phase: null == phase ? _self.phase : phase // ignore: cast_nullable_to_non_nullable
as String,durationWeeks: freezed == durationWeeks ? _self.durationWeeks : durationWeeks // ignore: cast_nullable_to_non_nullable
as int?,frequencyPerWeek: null == frequencyPerWeek ? _self.frequencyPerWeek : frequencyPerWeek // ignore: cast_nullable_to_non_nullable
as int,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as ProtocolStatus,isTemplate: null == isTemplate ? _self.isTemplate : isTemplate // ignore: cast_nullable_to_non_nullable
as bool,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}


/// @nodoc
mixin _$ProtocolWithExercises {

 String get id; String get name;@JsonKey(name: 'created_by') String get createdBy; String get description; String get condition; String get phase;@JsonKey(name: 'duration_weeks') int? get durationWeeks;@JsonKey(name: 'frequency_per_week') int get frequencyPerWeek; ProtocolStatus get status;@JsonKey(name: 'is_template') bool get isTemplate;@JsonKey(name: 'created_at') DateTime? get createdAt; List<ProtocolExerciseModel> get exercises;
/// Create a copy of ProtocolWithExercises
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProtocolWithExercisesCopyWith<ProtocolWithExercises> get copyWith => _$ProtocolWithExercisesCopyWithImpl<ProtocolWithExercises>(this as ProtocolWithExercises, _$identity);

  /// Serializes this ProtocolWithExercises to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProtocolWithExercises&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy)&&(identical(other.description, description) || other.description == description)&&(identical(other.condition, condition) || other.condition == condition)&&(identical(other.phase, phase) || other.phase == phase)&&(identical(other.durationWeeks, durationWeeks) || other.durationWeeks == durationWeeks)&&(identical(other.frequencyPerWeek, frequencyPerWeek) || other.frequencyPerWeek == frequencyPerWeek)&&(identical(other.status, status) || other.status == status)&&(identical(other.isTemplate, isTemplate) || other.isTemplate == isTemplate)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&const DeepCollectionEquality().equals(other.exercises, exercises));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,createdBy,description,condition,phase,durationWeeks,frequencyPerWeek,status,isTemplate,createdAt,const DeepCollectionEquality().hash(exercises));

@override
String toString() {
  return 'ProtocolWithExercises(id: $id, name: $name, createdBy: $createdBy, description: $description, condition: $condition, phase: $phase, durationWeeks: $durationWeeks, frequencyPerWeek: $frequencyPerWeek, status: $status, isTemplate: $isTemplate, createdAt: $createdAt, exercises: $exercises)';
}


}

/// @nodoc
abstract mixin class $ProtocolWithExercisesCopyWith<$Res>  {
  factory $ProtocolWithExercisesCopyWith(ProtocolWithExercises value, $Res Function(ProtocolWithExercises) _then) = _$ProtocolWithExercisesCopyWithImpl;
@useResult
$Res call({
 String id, String name,@JsonKey(name: 'created_by') String createdBy, String description, String condition, String phase,@JsonKey(name: 'duration_weeks') int? durationWeeks,@JsonKey(name: 'frequency_per_week') int frequencyPerWeek, ProtocolStatus status,@JsonKey(name: 'is_template') bool isTemplate,@JsonKey(name: 'created_at') DateTime? createdAt, List<ProtocolExerciseModel> exercises
});




}
/// @nodoc
class _$ProtocolWithExercisesCopyWithImpl<$Res>
    implements $ProtocolWithExercisesCopyWith<$Res> {
  _$ProtocolWithExercisesCopyWithImpl(this._self, this._then);

  final ProtocolWithExercises _self;
  final $Res Function(ProtocolWithExercises) _then;

/// Create a copy of ProtocolWithExercises
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? createdBy = null,Object? description = null,Object? condition = null,Object? phase = null,Object? durationWeeks = freezed,Object? frequencyPerWeek = null,Object? status = null,Object? isTemplate = null,Object? createdAt = freezed,Object? exercises = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,createdBy: null == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,condition: null == condition ? _self.condition : condition // ignore: cast_nullable_to_non_nullable
as String,phase: null == phase ? _self.phase : phase // ignore: cast_nullable_to_non_nullable
as String,durationWeeks: freezed == durationWeeks ? _self.durationWeeks : durationWeeks // ignore: cast_nullable_to_non_nullable
as int?,frequencyPerWeek: null == frequencyPerWeek ? _self.frequencyPerWeek : frequencyPerWeek // ignore: cast_nullable_to_non_nullable
as int,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as ProtocolStatus,isTemplate: null == isTemplate ? _self.isTemplate : isTemplate // ignore: cast_nullable_to_non_nullable
as bool,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,exercises: null == exercises ? _self.exercises : exercises // ignore: cast_nullable_to_non_nullable
as List<ProtocolExerciseModel>,
  ));
}

}


/// Adds pattern-matching-related methods to [ProtocolWithExercises].
extension ProtocolWithExercisesPatterns on ProtocolWithExercises {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProtocolWithExercises value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProtocolWithExercises() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProtocolWithExercises value)  $default,){
final _that = this;
switch (_that) {
case _ProtocolWithExercises():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProtocolWithExercises value)?  $default,){
final _that = this;
switch (_that) {
case _ProtocolWithExercises() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name, @JsonKey(name: 'created_by')  String createdBy,  String description,  String condition,  String phase, @JsonKey(name: 'duration_weeks')  int? durationWeeks, @JsonKey(name: 'frequency_per_week')  int frequencyPerWeek,  ProtocolStatus status, @JsonKey(name: 'is_template')  bool isTemplate, @JsonKey(name: 'created_at')  DateTime? createdAt,  List<ProtocolExerciseModel> exercises)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProtocolWithExercises() when $default != null:
return $default(_that.id,_that.name,_that.createdBy,_that.description,_that.condition,_that.phase,_that.durationWeeks,_that.frequencyPerWeek,_that.status,_that.isTemplate,_that.createdAt,_that.exercises);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name, @JsonKey(name: 'created_by')  String createdBy,  String description,  String condition,  String phase, @JsonKey(name: 'duration_weeks')  int? durationWeeks, @JsonKey(name: 'frequency_per_week')  int frequencyPerWeek,  ProtocolStatus status, @JsonKey(name: 'is_template')  bool isTemplate, @JsonKey(name: 'created_at')  DateTime? createdAt,  List<ProtocolExerciseModel> exercises)  $default,) {final _that = this;
switch (_that) {
case _ProtocolWithExercises():
return $default(_that.id,_that.name,_that.createdBy,_that.description,_that.condition,_that.phase,_that.durationWeeks,_that.frequencyPerWeek,_that.status,_that.isTemplate,_that.createdAt,_that.exercises);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name, @JsonKey(name: 'created_by')  String createdBy,  String description,  String condition,  String phase, @JsonKey(name: 'duration_weeks')  int? durationWeeks, @JsonKey(name: 'frequency_per_week')  int frequencyPerWeek,  ProtocolStatus status, @JsonKey(name: 'is_template')  bool isTemplate, @JsonKey(name: 'created_at')  DateTime? createdAt,  List<ProtocolExerciseModel> exercises)?  $default,) {final _that = this;
switch (_that) {
case _ProtocolWithExercises() when $default != null:
return $default(_that.id,_that.name,_that.createdBy,_that.description,_that.condition,_that.phase,_that.durationWeeks,_that.frequencyPerWeek,_that.status,_that.isTemplate,_that.createdAt,_that.exercises);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ProtocolWithExercises implements ProtocolWithExercises {
  const _ProtocolWithExercises({required this.id, required this.name, @JsonKey(name: 'created_by') required this.createdBy, this.description = '', this.condition = '', this.phase = '', @JsonKey(name: 'duration_weeks') this.durationWeeks, @JsonKey(name: 'frequency_per_week') this.frequencyPerWeek = 3, this.status = ProtocolStatus.draft, @JsonKey(name: 'is_template') this.isTemplate = true, @JsonKey(name: 'created_at') this.createdAt, final  List<ProtocolExerciseModel> exercises = const []}): _exercises = exercises;
  factory _ProtocolWithExercises.fromJson(Map<String, dynamic> json) => _$ProtocolWithExercisesFromJson(json);

@override final  String id;
@override final  String name;
@override@JsonKey(name: 'created_by') final  String createdBy;
@override@JsonKey() final  String description;
@override@JsonKey() final  String condition;
@override@JsonKey() final  String phase;
@override@JsonKey(name: 'duration_weeks') final  int? durationWeeks;
@override@JsonKey(name: 'frequency_per_week') final  int frequencyPerWeek;
@override@JsonKey() final  ProtocolStatus status;
@override@JsonKey(name: 'is_template') final  bool isTemplate;
@override@JsonKey(name: 'created_at') final  DateTime? createdAt;
 final  List<ProtocolExerciseModel> _exercises;
@override@JsonKey() List<ProtocolExerciseModel> get exercises {
  if (_exercises is EqualUnmodifiableListView) return _exercises;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_exercises);
}


/// Create a copy of ProtocolWithExercises
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProtocolWithExercisesCopyWith<_ProtocolWithExercises> get copyWith => __$ProtocolWithExercisesCopyWithImpl<_ProtocolWithExercises>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ProtocolWithExercisesToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProtocolWithExercises&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy)&&(identical(other.description, description) || other.description == description)&&(identical(other.condition, condition) || other.condition == condition)&&(identical(other.phase, phase) || other.phase == phase)&&(identical(other.durationWeeks, durationWeeks) || other.durationWeeks == durationWeeks)&&(identical(other.frequencyPerWeek, frequencyPerWeek) || other.frequencyPerWeek == frequencyPerWeek)&&(identical(other.status, status) || other.status == status)&&(identical(other.isTemplate, isTemplate) || other.isTemplate == isTemplate)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&const DeepCollectionEquality().equals(other._exercises, _exercises));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,createdBy,description,condition,phase,durationWeeks,frequencyPerWeek,status,isTemplate,createdAt,const DeepCollectionEquality().hash(_exercises));

@override
String toString() {
  return 'ProtocolWithExercises(id: $id, name: $name, createdBy: $createdBy, description: $description, condition: $condition, phase: $phase, durationWeeks: $durationWeeks, frequencyPerWeek: $frequencyPerWeek, status: $status, isTemplate: $isTemplate, createdAt: $createdAt, exercises: $exercises)';
}


}

/// @nodoc
abstract mixin class _$ProtocolWithExercisesCopyWith<$Res> implements $ProtocolWithExercisesCopyWith<$Res> {
  factory _$ProtocolWithExercisesCopyWith(_ProtocolWithExercises value, $Res Function(_ProtocolWithExercises) _then) = __$ProtocolWithExercisesCopyWithImpl;
@override @useResult
$Res call({
 String id, String name,@JsonKey(name: 'created_by') String createdBy, String description, String condition, String phase,@JsonKey(name: 'duration_weeks') int? durationWeeks,@JsonKey(name: 'frequency_per_week') int frequencyPerWeek, ProtocolStatus status,@JsonKey(name: 'is_template') bool isTemplate,@JsonKey(name: 'created_at') DateTime? createdAt, List<ProtocolExerciseModel> exercises
});




}
/// @nodoc
class __$ProtocolWithExercisesCopyWithImpl<$Res>
    implements _$ProtocolWithExercisesCopyWith<$Res> {
  __$ProtocolWithExercisesCopyWithImpl(this._self, this._then);

  final _ProtocolWithExercises _self;
  final $Res Function(_ProtocolWithExercises) _then;

/// Create a copy of ProtocolWithExercises
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? createdBy = null,Object? description = null,Object? condition = null,Object? phase = null,Object? durationWeeks = freezed,Object? frequencyPerWeek = null,Object? status = null,Object? isTemplate = null,Object? createdAt = freezed,Object? exercises = null,}) {
  return _then(_ProtocolWithExercises(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,createdBy: null == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,condition: null == condition ? _self.condition : condition // ignore: cast_nullable_to_non_nullable
as String,phase: null == phase ? _self.phase : phase // ignore: cast_nullable_to_non_nullable
as String,durationWeeks: freezed == durationWeeks ? _self.durationWeeks : durationWeeks // ignore: cast_nullable_to_non_nullable
as int?,frequencyPerWeek: null == frequencyPerWeek ? _self.frequencyPerWeek : frequencyPerWeek // ignore: cast_nullable_to_non_nullable
as int,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as ProtocolStatus,isTemplate: null == isTemplate ? _self.isTemplate : isTemplate // ignore: cast_nullable_to_non_nullable
as bool,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,exercises: null == exercises ? _self._exercises : exercises // ignore: cast_nullable_to_non_nullable
as List<ProtocolExerciseModel>,
  ));
}


}


/// @nodoc
mixin _$ProtocolExerciseModel {

 String get id;@JsonKey(name: 'protocol_id') String get protocolId;@JsonKey(name: 'exercise_id') String get exerciseId; int get order; int get sets; int? get reps;@JsonKey(name: 'hold_seconds') int? get holdSeconds;@JsonKey(name: 'rest_seconds') int get restSeconds; String get notes;
/// Create a copy of ProtocolExerciseModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProtocolExerciseModelCopyWith<ProtocolExerciseModel> get copyWith => _$ProtocolExerciseModelCopyWithImpl<ProtocolExerciseModel>(this as ProtocolExerciseModel, _$identity);

  /// Serializes this ProtocolExerciseModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProtocolExerciseModel&&(identical(other.id, id) || other.id == id)&&(identical(other.protocolId, protocolId) || other.protocolId == protocolId)&&(identical(other.exerciseId, exerciseId) || other.exerciseId == exerciseId)&&(identical(other.order, order) || other.order == order)&&(identical(other.sets, sets) || other.sets == sets)&&(identical(other.reps, reps) || other.reps == reps)&&(identical(other.holdSeconds, holdSeconds) || other.holdSeconds == holdSeconds)&&(identical(other.restSeconds, restSeconds) || other.restSeconds == restSeconds)&&(identical(other.notes, notes) || other.notes == notes));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,protocolId,exerciseId,order,sets,reps,holdSeconds,restSeconds,notes);

@override
String toString() {
  return 'ProtocolExerciseModel(id: $id, protocolId: $protocolId, exerciseId: $exerciseId, order: $order, sets: $sets, reps: $reps, holdSeconds: $holdSeconds, restSeconds: $restSeconds, notes: $notes)';
}


}

/// @nodoc
abstract mixin class $ProtocolExerciseModelCopyWith<$Res>  {
  factory $ProtocolExerciseModelCopyWith(ProtocolExerciseModel value, $Res Function(ProtocolExerciseModel) _then) = _$ProtocolExerciseModelCopyWithImpl;
@useResult
$Res call({
 String id,@JsonKey(name: 'protocol_id') String protocolId,@JsonKey(name: 'exercise_id') String exerciseId, int order, int sets, int? reps,@JsonKey(name: 'hold_seconds') int? holdSeconds,@JsonKey(name: 'rest_seconds') int restSeconds, String notes
});




}
/// @nodoc
class _$ProtocolExerciseModelCopyWithImpl<$Res>
    implements $ProtocolExerciseModelCopyWith<$Res> {
  _$ProtocolExerciseModelCopyWithImpl(this._self, this._then);

  final ProtocolExerciseModel _self;
  final $Res Function(ProtocolExerciseModel) _then;

/// Create a copy of ProtocolExerciseModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? protocolId = null,Object? exerciseId = null,Object? order = null,Object? sets = null,Object? reps = freezed,Object? holdSeconds = freezed,Object? restSeconds = null,Object? notes = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,protocolId: null == protocolId ? _self.protocolId : protocolId // ignore: cast_nullable_to_non_nullable
as String,exerciseId: null == exerciseId ? _self.exerciseId : exerciseId // ignore: cast_nullable_to_non_nullable
as String,order: null == order ? _self.order : order // ignore: cast_nullable_to_non_nullable
as int,sets: null == sets ? _self.sets : sets // ignore: cast_nullable_to_non_nullable
as int,reps: freezed == reps ? _self.reps : reps // ignore: cast_nullable_to_non_nullable
as int?,holdSeconds: freezed == holdSeconds ? _self.holdSeconds : holdSeconds // ignore: cast_nullable_to_non_nullable
as int?,restSeconds: null == restSeconds ? _self.restSeconds : restSeconds // ignore: cast_nullable_to_non_nullable
as int,notes: null == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [ProtocolExerciseModel].
extension ProtocolExerciseModelPatterns on ProtocolExerciseModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProtocolExerciseModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProtocolExerciseModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProtocolExerciseModel value)  $default,){
final _that = this;
switch (_that) {
case _ProtocolExerciseModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProtocolExerciseModel value)?  $default,){
final _that = this;
switch (_that) {
case _ProtocolExerciseModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'protocol_id')  String protocolId, @JsonKey(name: 'exercise_id')  String exerciseId,  int order,  int sets,  int? reps, @JsonKey(name: 'hold_seconds')  int? holdSeconds, @JsonKey(name: 'rest_seconds')  int restSeconds,  String notes)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProtocolExerciseModel() when $default != null:
return $default(_that.id,_that.protocolId,_that.exerciseId,_that.order,_that.sets,_that.reps,_that.holdSeconds,_that.restSeconds,_that.notes);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'protocol_id')  String protocolId, @JsonKey(name: 'exercise_id')  String exerciseId,  int order,  int sets,  int? reps, @JsonKey(name: 'hold_seconds')  int? holdSeconds, @JsonKey(name: 'rest_seconds')  int restSeconds,  String notes)  $default,) {final _that = this;
switch (_that) {
case _ProtocolExerciseModel():
return $default(_that.id,_that.protocolId,_that.exerciseId,_that.order,_that.sets,_that.reps,_that.holdSeconds,_that.restSeconds,_that.notes);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id, @JsonKey(name: 'protocol_id')  String protocolId, @JsonKey(name: 'exercise_id')  String exerciseId,  int order,  int sets,  int? reps, @JsonKey(name: 'hold_seconds')  int? holdSeconds, @JsonKey(name: 'rest_seconds')  int restSeconds,  String notes)?  $default,) {final _that = this;
switch (_that) {
case _ProtocolExerciseModel() when $default != null:
return $default(_that.id,_that.protocolId,_that.exerciseId,_that.order,_that.sets,_that.reps,_that.holdSeconds,_that.restSeconds,_that.notes);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ProtocolExerciseModel implements ProtocolExerciseModel {
  const _ProtocolExerciseModel({required this.id, @JsonKey(name: 'protocol_id') required this.protocolId, @JsonKey(name: 'exercise_id') required this.exerciseId, this.order = 0, this.sets = 3, this.reps, @JsonKey(name: 'hold_seconds') this.holdSeconds, @JsonKey(name: 'rest_seconds') this.restSeconds = 60, this.notes = ''});
  factory _ProtocolExerciseModel.fromJson(Map<String, dynamic> json) => _$ProtocolExerciseModelFromJson(json);

@override final  String id;
@override@JsonKey(name: 'protocol_id') final  String protocolId;
@override@JsonKey(name: 'exercise_id') final  String exerciseId;
@override@JsonKey() final  int order;
@override@JsonKey() final  int sets;
@override final  int? reps;
@override@JsonKey(name: 'hold_seconds') final  int? holdSeconds;
@override@JsonKey(name: 'rest_seconds') final  int restSeconds;
@override@JsonKey() final  String notes;

/// Create a copy of ProtocolExerciseModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProtocolExerciseModelCopyWith<_ProtocolExerciseModel> get copyWith => __$ProtocolExerciseModelCopyWithImpl<_ProtocolExerciseModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ProtocolExerciseModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProtocolExerciseModel&&(identical(other.id, id) || other.id == id)&&(identical(other.protocolId, protocolId) || other.protocolId == protocolId)&&(identical(other.exerciseId, exerciseId) || other.exerciseId == exerciseId)&&(identical(other.order, order) || other.order == order)&&(identical(other.sets, sets) || other.sets == sets)&&(identical(other.reps, reps) || other.reps == reps)&&(identical(other.holdSeconds, holdSeconds) || other.holdSeconds == holdSeconds)&&(identical(other.restSeconds, restSeconds) || other.restSeconds == restSeconds)&&(identical(other.notes, notes) || other.notes == notes));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,protocolId,exerciseId,order,sets,reps,holdSeconds,restSeconds,notes);

@override
String toString() {
  return 'ProtocolExerciseModel(id: $id, protocolId: $protocolId, exerciseId: $exerciseId, order: $order, sets: $sets, reps: $reps, holdSeconds: $holdSeconds, restSeconds: $restSeconds, notes: $notes)';
}


}

/// @nodoc
abstract mixin class _$ProtocolExerciseModelCopyWith<$Res> implements $ProtocolExerciseModelCopyWith<$Res> {
  factory _$ProtocolExerciseModelCopyWith(_ProtocolExerciseModel value, $Res Function(_ProtocolExerciseModel) _then) = __$ProtocolExerciseModelCopyWithImpl;
@override @useResult
$Res call({
 String id,@JsonKey(name: 'protocol_id') String protocolId,@JsonKey(name: 'exercise_id') String exerciseId, int order, int sets, int? reps,@JsonKey(name: 'hold_seconds') int? holdSeconds,@JsonKey(name: 'rest_seconds') int restSeconds, String notes
});




}
/// @nodoc
class __$ProtocolExerciseModelCopyWithImpl<$Res>
    implements _$ProtocolExerciseModelCopyWith<$Res> {
  __$ProtocolExerciseModelCopyWithImpl(this._self, this._then);

  final _ProtocolExerciseModel _self;
  final $Res Function(_ProtocolExerciseModel) _then;

/// Create a copy of ProtocolExerciseModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? protocolId = null,Object? exerciseId = null,Object? order = null,Object? sets = null,Object? reps = freezed,Object? holdSeconds = freezed,Object? restSeconds = null,Object? notes = null,}) {
  return _then(_ProtocolExerciseModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,protocolId: null == protocolId ? _self.protocolId : protocolId // ignore: cast_nullable_to_non_nullable
as String,exerciseId: null == exerciseId ? _self.exerciseId : exerciseId // ignore: cast_nullable_to_non_nullable
as String,order: null == order ? _self.order : order // ignore: cast_nullable_to_non_nullable
as int,sets: null == sets ? _self.sets : sets // ignore: cast_nullable_to_non_nullable
as int,reps: freezed == reps ? _self.reps : reps // ignore: cast_nullable_to_non_nullable
as int?,holdSeconds: freezed == holdSeconds ? _self.holdSeconds : holdSeconds // ignore: cast_nullable_to_non_nullable
as int?,restSeconds: null == restSeconds ? _self.restSeconds : restSeconds // ignore: cast_nullable_to_non_nullable
as int,notes: null == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
