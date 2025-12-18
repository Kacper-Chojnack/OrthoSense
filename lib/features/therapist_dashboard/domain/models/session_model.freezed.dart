// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'session_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$SessionModel {

 String get id;@JsonKey(name: 'patient_id') String get patientId;@JsonKey(name: 'treatment_plan_id') String get treatmentPlanId;@JsonKey(name: 'scheduled_date') DateTime get scheduledDate; SessionStatus get status; String get notes;@JsonKey(name: 'pain_level_before') int? get painLevelBefore;@JsonKey(name: 'pain_level_after') int? get painLevelAfter;@JsonKey(name: 'overall_score') double? get overallScore;@JsonKey(name: 'started_at') DateTime? get startedAt;@JsonKey(name: 'completed_at') DateTime? get completedAt;@JsonKey(name: 'duration_seconds') int? get durationSeconds;@JsonKey(name: 'created_at') DateTime? get createdAt;
/// Create a copy of SessionModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SessionModelCopyWith<SessionModel> get copyWith => _$SessionModelCopyWithImpl<SessionModel>(this as SessionModel, _$identity);

  /// Serializes this SessionModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SessionModel&&(identical(other.id, id) || other.id == id)&&(identical(other.patientId, patientId) || other.patientId == patientId)&&(identical(other.treatmentPlanId, treatmentPlanId) || other.treatmentPlanId == treatmentPlanId)&&(identical(other.scheduledDate, scheduledDate) || other.scheduledDate == scheduledDate)&&(identical(other.status, status) || other.status == status)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.painLevelBefore, painLevelBefore) || other.painLevelBefore == painLevelBefore)&&(identical(other.painLevelAfter, painLevelAfter) || other.painLevelAfter == painLevelAfter)&&(identical(other.overallScore, overallScore) || other.overallScore == overallScore)&&(identical(other.startedAt, startedAt) || other.startedAt == startedAt)&&(identical(other.completedAt, completedAt) || other.completedAt == completedAt)&&(identical(other.durationSeconds, durationSeconds) || other.durationSeconds == durationSeconds)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,patientId,treatmentPlanId,scheduledDate,status,notes,painLevelBefore,painLevelAfter,overallScore,startedAt,completedAt,durationSeconds,createdAt);

@override
String toString() {
  return 'SessionModel(id: $id, patientId: $patientId, treatmentPlanId: $treatmentPlanId, scheduledDate: $scheduledDate, status: $status, notes: $notes, painLevelBefore: $painLevelBefore, painLevelAfter: $painLevelAfter, overallScore: $overallScore, startedAt: $startedAt, completedAt: $completedAt, durationSeconds: $durationSeconds, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $SessionModelCopyWith<$Res>  {
  factory $SessionModelCopyWith(SessionModel value, $Res Function(SessionModel) _then) = _$SessionModelCopyWithImpl;
@useResult
$Res call({
 String id,@JsonKey(name: 'patient_id') String patientId,@JsonKey(name: 'treatment_plan_id') String treatmentPlanId,@JsonKey(name: 'scheduled_date') DateTime scheduledDate, SessionStatus status, String notes,@JsonKey(name: 'pain_level_before') int? painLevelBefore,@JsonKey(name: 'pain_level_after') int? painLevelAfter,@JsonKey(name: 'overall_score') double? overallScore,@JsonKey(name: 'started_at') DateTime? startedAt,@JsonKey(name: 'completed_at') DateTime? completedAt,@JsonKey(name: 'duration_seconds') int? durationSeconds,@JsonKey(name: 'created_at') DateTime? createdAt
});




}
/// @nodoc
class _$SessionModelCopyWithImpl<$Res>
    implements $SessionModelCopyWith<$Res> {
  _$SessionModelCopyWithImpl(this._self, this._then);

  final SessionModel _self;
  final $Res Function(SessionModel) _then;

/// Create a copy of SessionModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? patientId = null,Object? treatmentPlanId = null,Object? scheduledDate = null,Object? status = null,Object? notes = null,Object? painLevelBefore = freezed,Object? painLevelAfter = freezed,Object? overallScore = freezed,Object? startedAt = freezed,Object? completedAt = freezed,Object? durationSeconds = freezed,Object? createdAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,patientId: null == patientId ? _self.patientId : patientId // ignore: cast_nullable_to_non_nullable
as String,treatmentPlanId: null == treatmentPlanId ? _self.treatmentPlanId : treatmentPlanId // ignore: cast_nullable_to_non_nullable
as String,scheduledDate: null == scheduledDate ? _self.scheduledDate : scheduledDate // ignore: cast_nullable_to_non_nullable
as DateTime,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as SessionStatus,notes: null == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String,painLevelBefore: freezed == painLevelBefore ? _self.painLevelBefore : painLevelBefore // ignore: cast_nullable_to_non_nullable
as int?,painLevelAfter: freezed == painLevelAfter ? _self.painLevelAfter : painLevelAfter // ignore: cast_nullable_to_non_nullable
as int?,overallScore: freezed == overallScore ? _self.overallScore : overallScore // ignore: cast_nullable_to_non_nullable
as double?,startedAt: freezed == startedAt ? _self.startedAt : startedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,completedAt: freezed == completedAt ? _self.completedAt : completedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,durationSeconds: freezed == durationSeconds ? _self.durationSeconds : durationSeconds // ignore: cast_nullable_to_non_nullable
as int?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [SessionModel].
extension SessionModelPatterns on SessionModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SessionModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SessionModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SessionModel value)  $default,){
final _that = this;
switch (_that) {
case _SessionModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SessionModel value)?  $default,){
final _that = this;
switch (_that) {
case _SessionModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'patient_id')  String patientId, @JsonKey(name: 'treatment_plan_id')  String treatmentPlanId, @JsonKey(name: 'scheduled_date')  DateTime scheduledDate,  SessionStatus status,  String notes, @JsonKey(name: 'pain_level_before')  int? painLevelBefore, @JsonKey(name: 'pain_level_after')  int? painLevelAfter, @JsonKey(name: 'overall_score')  double? overallScore, @JsonKey(name: 'started_at')  DateTime? startedAt, @JsonKey(name: 'completed_at')  DateTime? completedAt, @JsonKey(name: 'duration_seconds')  int? durationSeconds, @JsonKey(name: 'created_at')  DateTime? createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SessionModel() when $default != null:
return $default(_that.id,_that.patientId,_that.treatmentPlanId,_that.scheduledDate,_that.status,_that.notes,_that.painLevelBefore,_that.painLevelAfter,_that.overallScore,_that.startedAt,_that.completedAt,_that.durationSeconds,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'patient_id')  String patientId, @JsonKey(name: 'treatment_plan_id')  String treatmentPlanId, @JsonKey(name: 'scheduled_date')  DateTime scheduledDate,  SessionStatus status,  String notes, @JsonKey(name: 'pain_level_before')  int? painLevelBefore, @JsonKey(name: 'pain_level_after')  int? painLevelAfter, @JsonKey(name: 'overall_score')  double? overallScore, @JsonKey(name: 'started_at')  DateTime? startedAt, @JsonKey(name: 'completed_at')  DateTime? completedAt, @JsonKey(name: 'duration_seconds')  int? durationSeconds, @JsonKey(name: 'created_at')  DateTime? createdAt)  $default,) {final _that = this;
switch (_that) {
case _SessionModel():
return $default(_that.id,_that.patientId,_that.treatmentPlanId,_that.scheduledDate,_that.status,_that.notes,_that.painLevelBefore,_that.painLevelAfter,_that.overallScore,_that.startedAt,_that.completedAt,_that.durationSeconds,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id, @JsonKey(name: 'patient_id')  String patientId, @JsonKey(name: 'treatment_plan_id')  String treatmentPlanId, @JsonKey(name: 'scheduled_date')  DateTime scheduledDate,  SessionStatus status,  String notes, @JsonKey(name: 'pain_level_before')  int? painLevelBefore, @JsonKey(name: 'pain_level_after')  int? painLevelAfter, @JsonKey(name: 'overall_score')  double? overallScore, @JsonKey(name: 'started_at')  DateTime? startedAt, @JsonKey(name: 'completed_at')  DateTime? completedAt, @JsonKey(name: 'duration_seconds')  int? durationSeconds, @JsonKey(name: 'created_at')  DateTime? createdAt)?  $default,) {final _that = this;
switch (_that) {
case _SessionModel() when $default != null:
return $default(_that.id,_that.patientId,_that.treatmentPlanId,_that.scheduledDate,_that.status,_that.notes,_that.painLevelBefore,_that.painLevelAfter,_that.overallScore,_that.startedAt,_that.completedAt,_that.durationSeconds,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SessionModel implements SessionModel {
  const _SessionModel({required this.id, @JsonKey(name: 'patient_id') required this.patientId, @JsonKey(name: 'treatment_plan_id') required this.treatmentPlanId, @JsonKey(name: 'scheduled_date') required this.scheduledDate, this.status = SessionStatus.inProgress, this.notes = '', @JsonKey(name: 'pain_level_before') this.painLevelBefore, @JsonKey(name: 'pain_level_after') this.painLevelAfter, @JsonKey(name: 'overall_score') this.overallScore, @JsonKey(name: 'started_at') this.startedAt, @JsonKey(name: 'completed_at') this.completedAt, @JsonKey(name: 'duration_seconds') this.durationSeconds, @JsonKey(name: 'created_at') this.createdAt});
  factory _SessionModel.fromJson(Map<String, dynamic> json) => _$SessionModelFromJson(json);

@override final  String id;
@override@JsonKey(name: 'patient_id') final  String patientId;
@override@JsonKey(name: 'treatment_plan_id') final  String treatmentPlanId;
@override@JsonKey(name: 'scheduled_date') final  DateTime scheduledDate;
@override@JsonKey() final  SessionStatus status;
@override@JsonKey() final  String notes;
@override@JsonKey(name: 'pain_level_before') final  int? painLevelBefore;
@override@JsonKey(name: 'pain_level_after') final  int? painLevelAfter;
@override@JsonKey(name: 'overall_score') final  double? overallScore;
@override@JsonKey(name: 'started_at') final  DateTime? startedAt;
@override@JsonKey(name: 'completed_at') final  DateTime? completedAt;
@override@JsonKey(name: 'duration_seconds') final  int? durationSeconds;
@override@JsonKey(name: 'created_at') final  DateTime? createdAt;

/// Create a copy of SessionModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SessionModelCopyWith<_SessionModel> get copyWith => __$SessionModelCopyWithImpl<_SessionModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SessionModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SessionModel&&(identical(other.id, id) || other.id == id)&&(identical(other.patientId, patientId) || other.patientId == patientId)&&(identical(other.treatmentPlanId, treatmentPlanId) || other.treatmentPlanId == treatmentPlanId)&&(identical(other.scheduledDate, scheduledDate) || other.scheduledDate == scheduledDate)&&(identical(other.status, status) || other.status == status)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.painLevelBefore, painLevelBefore) || other.painLevelBefore == painLevelBefore)&&(identical(other.painLevelAfter, painLevelAfter) || other.painLevelAfter == painLevelAfter)&&(identical(other.overallScore, overallScore) || other.overallScore == overallScore)&&(identical(other.startedAt, startedAt) || other.startedAt == startedAt)&&(identical(other.completedAt, completedAt) || other.completedAt == completedAt)&&(identical(other.durationSeconds, durationSeconds) || other.durationSeconds == durationSeconds)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,patientId,treatmentPlanId,scheduledDate,status,notes,painLevelBefore,painLevelAfter,overallScore,startedAt,completedAt,durationSeconds,createdAt);

@override
String toString() {
  return 'SessionModel(id: $id, patientId: $patientId, treatmentPlanId: $treatmentPlanId, scheduledDate: $scheduledDate, status: $status, notes: $notes, painLevelBefore: $painLevelBefore, painLevelAfter: $painLevelAfter, overallScore: $overallScore, startedAt: $startedAt, completedAt: $completedAt, durationSeconds: $durationSeconds, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$SessionModelCopyWith<$Res> implements $SessionModelCopyWith<$Res> {
  factory _$SessionModelCopyWith(_SessionModel value, $Res Function(_SessionModel) _then) = __$SessionModelCopyWithImpl;
@override @useResult
$Res call({
 String id,@JsonKey(name: 'patient_id') String patientId,@JsonKey(name: 'treatment_plan_id') String treatmentPlanId,@JsonKey(name: 'scheduled_date') DateTime scheduledDate, SessionStatus status, String notes,@JsonKey(name: 'pain_level_before') int? painLevelBefore,@JsonKey(name: 'pain_level_after') int? painLevelAfter,@JsonKey(name: 'overall_score') double? overallScore,@JsonKey(name: 'started_at') DateTime? startedAt,@JsonKey(name: 'completed_at') DateTime? completedAt,@JsonKey(name: 'duration_seconds') int? durationSeconds,@JsonKey(name: 'created_at') DateTime? createdAt
});




}
/// @nodoc
class __$SessionModelCopyWithImpl<$Res>
    implements _$SessionModelCopyWith<$Res> {
  __$SessionModelCopyWithImpl(this._self, this._then);

  final _SessionModel _self;
  final $Res Function(_SessionModel) _then;

/// Create a copy of SessionModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? patientId = null,Object? treatmentPlanId = null,Object? scheduledDate = null,Object? status = null,Object? notes = null,Object? painLevelBefore = freezed,Object? painLevelAfter = freezed,Object? overallScore = freezed,Object? startedAt = freezed,Object? completedAt = freezed,Object? durationSeconds = freezed,Object? createdAt = freezed,}) {
  return _then(_SessionModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,patientId: null == patientId ? _self.patientId : patientId // ignore: cast_nullable_to_non_nullable
as String,treatmentPlanId: null == treatmentPlanId ? _self.treatmentPlanId : treatmentPlanId // ignore: cast_nullable_to_non_nullable
as String,scheduledDate: null == scheduledDate ? _self.scheduledDate : scheduledDate // ignore: cast_nullable_to_non_nullable
as DateTime,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as SessionStatus,notes: null == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String,painLevelBefore: freezed == painLevelBefore ? _self.painLevelBefore : painLevelBefore // ignore: cast_nullable_to_non_nullable
as int?,painLevelAfter: freezed == painLevelAfter ? _self.painLevelAfter : painLevelAfter // ignore: cast_nullable_to_non_nullable
as int?,overallScore: freezed == overallScore ? _self.overallScore : overallScore // ignore: cast_nullable_to_non_nullable
as double?,startedAt: freezed == startedAt ? _self.startedAt : startedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,completedAt: freezed == completedAt ? _self.completedAt : completedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,durationSeconds: freezed == durationSeconds ? _self.durationSeconds : durationSeconds // ignore: cast_nullable_to_non_nullable
as int?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}


/// @nodoc
mixin _$SessionSummary {

@JsonKey(name: 'session_id') String get sessionId;@JsonKey(name: 'patient_id') String get patientId;@JsonKey(name: 'patient_name') String get patientName;@JsonKey(name: 'scheduled_date') DateTime get scheduledDate; SessionStatus get status;@JsonKey(name: 'overall_score') double? get overallScore;@JsonKey(name: 'exercises_completed') int get exercisesCompleted;@JsonKey(name: 'total_exercises') int get totalExercises;@JsonKey(name: 'duration_seconds') int? get durationSeconds;
/// Create a copy of SessionSummary
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SessionSummaryCopyWith<SessionSummary> get copyWith => _$SessionSummaryCopyWithImpl<SessionSummary>(this as SessionSummary, _$identity);

  /// Serializes this SessionSummary to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SessionSummary&&(identical(other.sessionId, sessionId) || other.sessionId == sessionId)&&(identical(other.patientId, patientId) || other.patientId == patientId)&&(identical(other.patientName, patientName) || other.patientName == patientName)&&(identical(other.scheduledDate, scheduledDate) || other.scheduledDate == scheduledDate)&&(identical(other.status, status) || other.status == status)&&(identical(other.overallScore, overallScore) || other.overallScore == overallScore)&&(identical(other.exercisesCompleted, exercisesCompleted) || other.exercisesCompleted == exercisesCompleted)&&(identical(other.totalExercises, totalExercises) || other.totalExercises == totalExercises)&&(identical(other.durationSeconds, durationSeconds) || other.durationSeconds == durationSeconds));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,sessionId,patientId,patientName,scheduledDate,status,overallScore,exercisesCompleted,totalExercises,durationSeconds);

@override
String toString() {
  return 'SessionSummary(sessionId: $sessionId, patientId: $patientId, patientName: $patientName, scheduledDate: $scheduledDate, status: $status, overallScore: $overallScore, exercisesCompleted: $exercisesCompleted, totalExercises: $totalExercises, durationSeconds: $durationSeconds)';
}


}

/// @nodoc
abstract mixin class $SessionSummaryCopyWith<$Res>  {
  factory $SessionSummaryCopyWith(SessionSummary value, $Res Function(SessionSummary) _then) = _$SessionSummaryCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'session_id') String sessionId,@JsonKey(name: 'patient_id') String patientId,@JsonKey(name: 'patient_name') String patientName,@JsonKey(name: 'scheduled_date') DateTime scheduledDate, SessionStatus status,@JsonKey(name: 'overall_score') double? overallScore,@JsonKey(name: 'exercises_completed') int exercisesCompleted,@JsonKey(name: 'total_exercises') int totalExercises,@JsonKey(name: 'duration_seconds') int? durationSeconds
});




}
/// @nodoc
class _$SessionSummaryCopyWithImpl<$Res>
    implements $SessionSummaryCopyWith<$Res> {
  _$SessionSummaryCopyWithImpl(this._self, this._then);

  final SessionSummary _self;
  final $Res Function(SessionSummary) _then;

/// Create a copy of SessionSummary
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? sessionId = null,Object? patientId = null,Object? patientName = null,Object? scheduledDate = null,Object? status = null,Object? overallScore = freezed,Object? exercisesCompleted = null,Object? totalExercises = null,Object? durationSeconds = freezed,}) {
  return _then(_self.copyWith(
sessionId: null == sessionId ? _self.sessionId : sessionId // ignore: cast_nullable_to_non_nullable
as String,patientId: null == patientId ? _self.patientId : patientId // ignore: cast_nullable_to_non_nullable
as String,patientName: null == patientName ? _self.patientName : patientName // ignore: cast_nullable_to_non_nullable
as String,scheduledDate: null == scheduledDate ? _self.scheduledDate : scheduledDate // ignore: cast_nullable_to_non_nullable
as DateTime,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as SessionStatus,overallScore: freezed == overallScore ? _self.overallScore : overallScore // ignore: cast_nullable_to_non_nullable
as double?,exercisesCompleted: null == exercisesCompleted ? _self.exercisesCompleted : exercisesCompleted // ignore: cast_nullable_to_non_nullable
as int,totalExercises: null == totalExercises ? _self.totalExercises : totalExercises // ignore: cast_nullable_to_non_nullable
as int,durationSeconds: freezed == durationSeconds ? _self.durationSeconds : durationSeconds // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [SessionSummary].
extension SessionSummaryPatterns on SessionSummary {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SessionSummary value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SessionSummary() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SessionSummary value)  $default,){
final _that = this;
switch (_that) {
case _SessionSummary():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SessionSummary value)?  $default,){
final _that = this;
switch (_that) {
case _SessionSummary() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'session_id')  String sessionId, @JsonKey(name: 'patient_id')  String patientId, @JsonKey(name: 'patient_name')  String patientName, @JsonKey(name: 'scheduled_date')  DateTime scheduledDate,  SessionStatus status, @JsonKey(name: 'overall_score')  double? overallScore, @JsonKey(name: 'exercises_completed')  int exercisesCompleted, @JsonKey(name: 'total_exercises')  int totalExercises, @JsonKey(name: 'duration_seconds')  int? durationSeconds)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SessionSummary() when $default != null:
return $default(_that.sessionId,_that.patientId,_that.patientName,_that.scheduledDate,_that.status,_that.overallScore,_that.exercisesCompleted,_that.totalExercises,_that.durationSeconds);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'session_id')  String sessionId, @JsonKey(name: 'patient_id')  String patientId, @JsonKey(name: 'patient_name')  String patientName, @JsonKey(name: 'scheduled_date')  DateTime scheduledDate,  SessionStatus status, @JsonKey(name: 'overall_score')  double? overallScore, @JsonKey(name: 'exercises_completed')  int exercisesCompleted, @JsonKey(name: 'total_exercises')  int totalExercises, @JsonKey(name: 'duration_seconds')  int? durationSeconds)  $default,) {final _that = this;
switch (_that) {
case _SessionSummary():
return $default(_that.sessionId,_that.patientId,_that.patientName,_that.scheduledDate,_that.status,_that.overallScore,_that.exercisesCompleted,_that.totalExercises,_that.durationSeconds);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'session_id')  String sessionId, @JsonKey(name: 'patient_id')  String patientId, @JsonKey(name: 'patient_name')  String patientName, @JsonKey(name: 'scheduled_date')  DateTime scheduledDate,  SessionStatus status, @JsonKey(name: 'overall_score')  double? overallScore, @JsonKey(name: 'exercises_completed')  int exercisesCompleted, @JsonKey(name: 'total_exercises')  int totalExercises, @JsonKey(name: 'duration_seconds')  int? durationSeconds)?  $default,) {final _that = this;
switch (_that) {
case _SessionSummary() when $default != null:
return $default(_that.sessionId,_that.patientId,_that.patientName,_that.scheduledDate,_that.status,_that.overallScore,_that.exercisesCompleted,_that.totalExercises,_that.durationSeconds);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SessionSummary implements SessionSummary {
  const _SessionSummary({@JsonKey(name: 'session_id') required this.sessionId, @JsonKey(name: 'patient_id') required this.patientId, @JsonKey(name: 'patient_name') this.patientName = '', @JsonKey(name: 'scheduled_date') required this.scheduledDate, this.status = SessionStatus.inProgress, @JsonKey(name: 'overall_score') this.overallScore, @JsonKey(name: 'exercises_completed') this.exercisesCompleted = 0, @JsonKey(name: 'total_exercises') this.totalExercises = 0, @JsonKey(name: 'duration_seconds') this.durationSeconds});
  factory _SessionSummary.fromJson(Map<String, dynamic> json) => _$SessionSummaryFromJson(json);

@override@JsonKey(name: 'session_id') final  String sessionId;
@override@JsonKey(name: 'patient_id') final  String patientId;
@override@JsonKey(name: 'patient_name') final  String patientName;
@override@JsonKey(name: 'scheduled_date') final  DateTime scheduledDate;
@override@JsonKey() final  SessionStatus status;
@override@JsonKey(name: 'overall_score') final  double? overallScore;
@override@JsonKey(name: 'exercises_completed') final  int exercisesCompleted;
@override@JsonKey(name: 'total_exercises') final  int totalExercises;
@override@JsonKey(name: 'duration_seconds') final  int? durationSeconds;

/// Create a copy of SessionSummary
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SessionSummaryCopyWith<_SessionSummary> get copyWith => __$SessionSummaryCopyWithImpl<_SessionSummary>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SessionSummaryToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SessionSummary&&(identical(other.sessionId, sessionId) || other.sessionId == sessionId)&&(identical(other.patientId, patientId) || other.patientId == patientId)&&(identical(other.patientName, patientName) || other.patientName == patientName)&&(identical(other.scheduledDate, scheduledDate) || other.scheduledDate == scheduledDate)&&(identical(other.status, status) || other.status == status)&&(identical(other.overallScore, overallScore) || other.overallScore == overallScore)&&(identical(other.exercisesCompleted, exercisesCompleted) || other.exercisesCompleted == exercisesCompleted)&&(identical(other.totalExercises, totalExercises) || other.totalExercises == totalExercises)&&(identical(other.durationSeconds, durationSeconds) || other.durationSeconds == durationSeconds));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,sessionId,patientId,patientName,scheduledDate,status,overallScore,exercisesCompleted,totalExercises,durationSeconds);

@override
String toString() {
  return 'SessionSummary(sessionId: $sessionId, patientId: $patientId, patientName: $patientName, scheduledDate: $scheduledDate, status: $status, overallScore: $overallScore, exercisesCompleted: $exercisesCompleted, totalExercises: $totalExercises, durationSeconds: $durationSeconds)';
}


}

/// @nodoc
abstract mixin class _$SessionSummaryCopyWith<$Res> implements $SessionSummaryCopyWith<$Res> {
  factory _$SessionSummaryCopyWith(_SessionSummary value, $Res Function(_SessionSummary) _then) = __$SessionSummaryCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'session_id') String sessionId,@JsonKey(name: 'patient_id') String patientId,@JsonKey(name: 'patient_name') String patientName,@JsonKey(name: 'scheduled_date') DateTime scheduledDate, SessionStatus status,@JsonKey(name: 'overall_score') double? overallScore,@JsonKey(name: 'exercises_completed') int exercisesCompleted,@JsonKey(name: 'total_exercises') int totalExercises,@JsonKey(name: 'duration_seconds') int? durationSeconds
});




}
/// @nodoc
class __$SessionSummaryCopyWithImpl<$Res>
    implements _$SessionSummaryCopyWith<$Res> {
  __$SessionSummaryCopyWithImpl(this._self, this._then);

  final _SessionSummary _self;
  final $Res Function(_SessionSummary) _then;

/// Create a copy of SessionSummary
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? sessionId = null,Object? patientId = null,Object? patientName = null,Object? scheduledDate = null,Object? status = null,Object? overallScore = freezed,Object? exercisesCompleted = null,Object? totalExercises = null,Object? durationSeconds = freezed,}) {
  return _then(_SessionSummary(
sessionId: null == sessionId ? _self.sessionId : sessionId // ignore: cast_nullable_to_non_nullable
as String,patientId: null == patientId ? _self.patientId : patientId // ignore: cast_nullable_to_non_nullable
as String,patientName: null == patientName ? _self.patientName : patientName // ignore: cast_nullable_to_non_nullable
as String,scheduledDate: null == scheduledDate ? _self.scheduledDate : scheduledDate // ignore: cast_nullable_to_non_nullable
as DateTime,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as SessionStatus,overallScore: freezed == overallScore ? _self.overallScore : overallScore // ignore: cast_nullable_to_non_nullable
as double?,exercisesCompleted: null == exercisesCompleted ? _self.exercisesCompleted : exercisesCompleted // ignore: cast_nullable_to_non_nullable
as int,totalExercises: null == totalExercises ? _self.totalExercises : totalExercises // ignore: cast_nullable_to_non_nullable
as int,durationSeconds: freezed == durationSeconds ? _self.durationSeconds : durationSeconds // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}

// dart format on
