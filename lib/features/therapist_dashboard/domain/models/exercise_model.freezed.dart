// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'exercise_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ExerciseModel {

 String get id; String get name; String get description; String get instructions; ExerciseCategory get category;@JsonKey(name: 'body_part') BodyPart get bodyPart;@JsonKey(name: 'difficulty_level') int get difficultyLevel;@JsonKey(name: 'video_url') String? get videoUrl;@JsonKey(name: 'thumbnail_url') String? get thumbnailUrl;@JsonKey(name: 'duration_seconds') int? get durationSeconds;@JsonKey(name: 'is_active') bool get isActive;@JsonKey(name: 'created_at') DateTime? get createdAt;
/// Create a copy of ExerciseModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ExerciseModelCopyWith<ExerciseModel> get copyWith => _$ExerciseModelCopyWithImpl<ExerciseModel>(this as ExerciseModel, _$identity);

  /// Serializes this ExerciseModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ExerciseModel&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&(identical(other.instructions, instructions) || other.instructions == instructions)&&(identical(other.category, category) || other.category == category)&&(identical(other.bodyPart, bodyPart) || other.bodyPart == bodyPart)&&(identical(other.difficultyLevel, difficultyLevel) || other.difficultyLevel == difficultyLevel)&&(identical(other.videoUrl, videoUrl) || other.videoUrl == videoUrl)&&(identical(other.thumbnailUrl, thumbnailUrl) || other.thumbnailUrl == thumbnailUrl)&&(identical(other.durationSeconds, durationSeconds) || other.durationSeconds == durationSeconds)&&(identical(other.isActive, isActive) || other.isActive == isActive)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,description,instructions,category,bodyPart,difficultyLevel,videoUrl,thumbnailUrl,durationSeconds,isActive,createdAt);

@override
String toString() {
  return 'ExerciseModel(id: $id, name: $name, description: $description, instructions: $instructions, category: $category, bodyPart: $bodyPart, difficultyLevel: $difficultyLevel, videoUrl: $videoUrl, thumbnailUrl: $thumbnailUrl, durationSeconds: $durationSeconds, isActive: $isActive, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $ExerciseModelCopyWith<$Res>  {
  factory $ExerciseModelCopyWith(ExerciseModel value, $Res Function(ExerciseModel) _then) = _$ExerciseModelCopyWithImpl;
@useResult
$Res call({
 String id, String name, String description, String instructions, ExerciseCategory category,@JsonKey(name: 'body_part') BodyPart bodyPart,@JsonKey(name: 'difficulty_level') int difficultyLevel,@JsonKey(name: 'video_url') String? videoUrl,@JsonKey(name: 'thumbnail_url') String? thumbnailUrl,@JsonKey(name: 'duration_seconds') int? durationSeconds,@JsonKey(name: 'is_active') bool isActive,@JsonKey(name: 'created_at') DateTime? createdAt
});




}
/// @nodoc
class _$ExerciseModelCopyWithImpl<$Res>
    implements $ExerciseModelCopyWith<$Res> {
  _$ExerciseModelCopyWithImpl(this._self, this._then);

  final ExerciseModel _self;
  final $Res Function(ExerciseModel) _then;

/// Create a copy of ExerciseModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? description = null,Object? instructions = null,Object? category = null,Object? bodyPart = null,Object? difficultyLevel = null,Object? videoUrl = freezed,Object? thumbnailUrl = freezed,Object? durationSeconds = freezed,Object? isActive = null,Object? createdAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,instructions: null == instructions ? _self.instructions : instructions // ignore: cast_nullable_to_non_nullable
as String,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as ExerciseCategory,bodyPart: null == bodyPart ? _self.bodyPart : bodyPart // ignore: cast_nullable_to_non_nullable
as BodyPart,difficultyLevel: null == difficultyLevel ? _self.difficultyLevel : difficultyLevel // ignore: cast_nullable_to_non_nullable
as int,videoUrl: freezed == videoUrl ? _self.videoUrl : videoUrl // ignore: cast_nullable_to_non_nullable
as String?,thumbnailUrl: freezed == thumbnailUrl ? _self.thumbnailUrl : thumbnailUrl // ignore: cast_nullable_to_non_nullable
as String?,durationSeconds: freezed == durationSeconds ? _self.durationSeconds : durationSeconds // ignore: cast_nullable_to_non_nullable
as int?,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [ExerciseModel].
extension ExerciseModelPatterns on ExerciseModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ExerciseModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ExerciseModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ExerciseModel value)  $default,){
final _that = this;
switch (_that) {
case _ExerciseModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ExerciseModel value)?  $default,){
final _that = this;
switch (_that) {
case _ExerciseModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  String description,  String instructions,  ExerciseCategory category, @JsonKey(name: 'body_part')  BodyPart bodyPart, @JsonKey(name: 'difficulty_level')  int difficultyLevel, @JsonKey(name: 'video_url')  String? videoUrl, @JsonKey(name: 'thumbnail_url')  String? thumbnailUrl, @JsonKey(name: 'duration_seconds')  int? durationSeconds, @JsonKey(name: 'is_active')  bool isActive, @JsonKey(name: 'created_at')  DateTime? createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ExerciseModel() when $default != null:
return $default(_that.id,_that.name,_that.description,_that.instructions,_that.category,_that.bodyPart,_that.difficultyLevel,_that.videoUrl,_that.thumbnailUrl,_that.durationSeconds,_that.isActive,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  String description,  String instructions,  ExerciseCategory category, @JsonKey(name: 'body_part')  BodyPart bodyPart, @JsonKey(name: 'difficulty_level')  int difficultyLevel, @JsonKey(name: 'video_url')  String? videoUrl, @JsonKey(name: 'thumbnail_url')  String? thumbnailUrl, @JsonKey(name: 'duration_seconds')  int? durationSeconds, @JsonKey(name: 'is_active')  bool isActive, @JsonKey(name: 'created_at')  DateTime? createdAt)  $default,) {final _that = this;
switch (_that) {
case _ExerciseModel():
return $default(_that.id,_that.name,_that.description,_that.instructions,_that.category,_that.bodyPart,_that.difficultyLevel,_that.videoUrl,_that.thumbnailUrl,_that.durationSeconds,_that.isActive,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  String description,  String instructions,  ExerciseCategory category, @JsonKey(name: 'body_part')  BodyPart bodyPart, @JsonKey(name: 'difficulty_level')  int difficultyLevel, @JsonKey(name: 'video_url')  String? videoUrl, @JsonKey(name: 'thumbnail_url')  String? thumbnailUrl, @JsonKey(name: 'duration_seconds')  int? durationSeconds, @JsonKey(name: 'is_active')  bool isActive, @JsonKey(name: 'created_at')  DateTime? createdAt)?  $default,) {final _that = this;
switch (_that) {
case _ExerciseModel() when $default != null:
return $default(_that.id,_that.name,_that.description,_that.instructions,_that.category,_that.bodyPart,_that.difficultyLevel,_that.videoUrl,_that.thumbnailUrl,_that.durationSeconds,_that.isActive,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ExerciseModel implements ExerciseModel {
  const _ExerciseModel({required this.id, required this.name, this.description = '', this.instructions = '', this.category = ExerciseCategory.mobility, @JsonKey(name: 'body_part') this.bodyPart = BodyPart.knee, @JsonKey(name: 'difficulty_level') this.difficultyLevel = 1, @JsonKey(name: 'video_url') this.videoUrl, @JsonKey(name: 'thumbnail_url') this.thumbnailUrl, @JsonKey(name: 'duration_seconds') this.durationSeconds, @JsonKey(name: 'is_active') this.isActive = true, @JsonKey(name: 'created_at') this.createdAt});
  factory _ExerciseModel.fromJson(Map<String, dynamic> json) => _$ExerciseModelFromJson(json);

@override final  String id;
@override final  String name;
@override@JsonKey() final  String description;
@override@JsonKey() final  String instructions;
@override@JsonKey() final  ExerciseCategory category;
@override@JsonKey(name: 'body_part') final  BodyPart bodyPart;
@override@JsonKey(name: 'difficulty_level') final  int difficultyLevel;
@override@JsonKey(name: 'video_url') final  String? videoUrl;
@override@JsonKey(name: 'thumbnail_url') final  String? thumbnailUrl;
@override@JsonKey(name: 'duration_seconds') final  int? durationSeconds;
@override@JsonKey(name: 'is_active') final  bool isActive;
@override@JsonKey(name: 'created_at') final  DateTime? createdAt;

/// Create a copy of ExerciseModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ExerciseModelCopyWith<_ExerciseModel> get copyWith => __$ExerciseModelCopyWithImpl<_ExerciseModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ExerciseModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ExerciseModel&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&(identical(other.instructions, instructions) || other.instructions == instructions)&&(identical(other.category, category) || other.category == category)&&(identical(other.bodyPart, bodyPart) || other.bodyPart == bodyPart)&&(identical(other.difficultyLevel, difficultyLevel) || other.difficultyLevel == difficultyLevel)&&(identical(other.videoUrl, videoUrl) || other.videoUrl == videoUrl)&&(identical(other.thumbnailUrl, thumbnailUrl) || other.thumbnailUrl == thumbnailUrl)&&(identical(other.durationSeconds, durationSeconds) || other.durationSeconds == durationSeconds)&&(identical(other.isActive, isActive) || other.isActive == isActive)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,description,instructions,category,bodyPart,difficultyLevel,videoUrl,thumbnailUrl,durationSeconds,isActive,createdAt);

@override
String toString() {
  return 'ExerciseModel(id: $id, name: $name, description: $description, instructions: $instructions, category: $category, bodyPart: $bodyPart, difficultyLevel: $difficultyLevel, videoUrl: $videoUrl, thumbnailUrl: $thumbnailUrl, durationSeconds: $durationSeconds, isActive: $isActive, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$ExerciseModelCopyWith<$Res> implements $ExerciseModelCopyWith<$Res> {
  factory _$ExerciseModelCopyWith(_ExerciseModel value, $Res Function(_ExerciseModel) _then) = __$ExerciseModelCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String description, String instructions, ExerciseCategory category,@JsonKey(name: 'body_part') BodyPart bodyPart,@JsonKey(name: 'difficulty_level') int difficultyLevel,@JsonKey(name: 'video_url') String? videoUrl,@JsonKey(name: 'thumbnail_url') String? thumbnailUrl,@JsonKey(name: 'duration_seconds') int? durationSeconds,@JsonKey(name: 'is_active') bool isActive,@JsonKey(name: 'created_at') DateTime? createdAt
});




}
/// @nodoc
class __$ExerciseModelCopyWithImpl<$Res>
    implements _$ExerciseModelCopyWith<$Res> {
  __$ExerciseModelCopyWithImpl(this._self, this._then);

  final _ExerciseModel _self;
  final $Res Function(_ExerciseModel) _then;

/// Create a copy of ExerciseModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? description = null,Object? instructions = null,Object? category = null,Object? bodyPart = null,Object? difficultyLevel = null,Object? videoUrl = freezed,Object? thumbnailUrl = freezed,Object? durationSeconds = freezed,Object? isActive = null,Object? createdAt = freezed,}) {
  return _then(_ExerciseModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,instructions: null == instructions ? _self.instructions : instructions // ignore: cast_nullable_to_non_nullable
as String,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as ExerciseCategory,bodyPart: null == bodyPart ? _self.bodyPart : bodyPart // ignore: cast_nullable_to_non_nullable
as BodyPart,difficultyLevel: null == difficultyLevel ? _self.difficultyLevel : difficultyLevel // ignore: cast_nullable_to_non_nullable
as int,videoUrl: freezed == videoUrl ? _self.videoUrl : videoUrl // ignore: cast_nullable_to_non_nullable
as String?,thumbnailUrl: freezed == thumbnailUrl ? _self.thumbnailUrl : thumbnailUrl // ignore: cast_nullable_to_non_nullable
as String?,durationSeconds: freezed == durationSeconds ? _self.durationSeconds : durationSeconds // ignore: cast_nullable_to_non_nullable
as int?,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
