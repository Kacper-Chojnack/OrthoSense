// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'patient_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PatientModel {

 String get id; String get email;@JsonKey(name: 'full_name') String get fullName;@JsonKey(name: 'is_active') bool get isActive;@JsonKey(name: 'is_verified') bool get isVerified;@JsonKey(name: 'created_at') DateTime? get createdAt;
/// Create a copy of PatientModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PatientModelCopyWith<PatientModel> get copyWith => _$PatientModelCopyWithImpl<PatientModel>(this as PatientModel, _$identity);

  /// Serializes this PatientModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PatientModel&&(identical(other.id, id) || other.id == id)&&(identical(other.email, email) || other.email == email)&&(identical(other.fullName, fullName) || other.fullName == fullName)&&(identical(other.isActive, isActive) || other.isActive == isActive)&&(identical(other.isVerified, isVerified) || other.isVerified == isVerified)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,email,fullName,isActive,isVerified,createdAt);

@override
String toString() {
  return 'PatientModel(id: $id, email: $email, fullName: $fullName, isActive: $isActive, isVerified: $isVerified, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $PatientModelCopyWith<$Res>  {
  factory $PatientModelCopyWith(PatientModel value, $Res Function(PatientModel) _then) = _$PatientModelCopyWithImpl;
@useResult
$Res call({
 String id, String email,@JsonKey(name: 'full_name') String fullName,@JsonKey(name: 'is_active') bool isActive,@JsonKey(name: 'is_verified') bool isVerified,@JsonKey(name: 'created_at') DateTime? createdAt
});




}
/// @nodoc
class _$PatientModelCopyWithImpl<$Res>
    implements $PatientModelCopyWith<$Res> {
  _$PatientModelCopyWithImpl(this._self, this._then);

  final PatientModel _self;
  final $Res Function(PatientModel) _then;

/// Create a copy of PatientModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? email = null,Object? fullName = null,Object? isActive = null,Object? isVerified = null,Object? createdAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,fullName: null == fullName ? _self.fullName : fullName // ignore: cast_nullable_to_non_nullable
as String,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,isVerified: null == isVerified ? _self.isVerified : isVerified // ignore: cast_nullable_to_non_nullable
as bool,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [PatientModel].
extension PatientModelPatterns on PatientModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PatientModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PatientModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PatientModel value)  $default,){
final _that = this;
switch (_that) {
case _PatientModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PatientModel value)?  $default,){
final _that = this;
switch (_that) {
case _PatientModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String email, @JsonKey(name: 'full_name')  String fullName, @JsonKey(name: 'is_active')  bool isActive, @JsonKey(name: 'is_verified')  bool isVerified, @JsonKey(name: 'created_at')  DateTime? createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PatientModel() when $default != null:
return $default(_that.id,_that.email,_that.fullName,_that.isActive,_that.isVerified,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String email, @JsonKey(name: 'full_name')  String fullName, @JsonKey(name: 'is_active')  bool isActive, @JsonKey(name: 'is_verified')  bool isVerified, @JsonKey(name: 'created_at')  DateTime? createdAt)  $default,) {final _that = this;
switch (_that) {
case _PatientModel():
return $default(_that.id,_that.email,_that.fullName,_that.isActive,_that.isVerified,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String email, @JsonKey(name: 'full_name')  String fullName, @JsonKey(name: 'is_active')  bool isActive, @JsonKey(name: 'is_verified')  bool isVerified, @JsonKey(name: 'created_at')  DateTime? createdAt)?  $default,) {final _that = this;
switch (_that) {
case _PatientModel() when $default != null:
return $default(_that.id,_that.email,_that.fullName,_that.isActive,_that.isVerified,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PatientModel implements PatientModel {
  const _PatientModel({required this.id, required this.email, @JsonKey(name: 'full_name') this.fullName = '', @JsonKey(name: 'is_active') this.isActive = true, @JsonKey(name: 'is_verified') this.isVerified = false, @JsonKey(name: 'created_at') this.createdAt});
  factory _PatientModel.fromJson(Map<String, dynamic> json) => _$PatientModelFromJson(json);

@override final  String id;
@override final  String email;
@override@JsonKey(name: 'full_name') final  String fullName;
@override@JsonKey(name: 'is_active') final  bool isActive;
@override@JsonKey(name: 'is_verified') final  bool isVerified;
@override@JsonKey(name: 'created_at') final  DateTime? createdAt;

/// Create a copy of PatientModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PatientModelCopyWith<_PatientModel> get copyWith => __$PatientModelCopyWithImpl<_PatientModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PatientModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PatientModel&&(identical(other.id, id) || other.id == id)&&(identical(other.email, email) || other.email == email)&&(identical(other.fullName, fullName) || other.fullName == fullName)&&(identical(other.isActive, isActive) || other.isActive == isActive)&&(identical(other.isVerified, isVerified) || other.isVerified == isVerified)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,email,fullName,isActive,isVerified,createdAt);

@override
String toString() {
  return 'PatientModel(id: $id, email: $email, fullName: $fullName, isActive: $isActive, isVerified: $isVerified, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$PatientModelCopyWith<$Res> implements $PatientModelCopyWith<$Res> {
  factory _$PatientModelCopyWith(_PatientModel value, $Res Function(_PatientModel) _then) = __$PatientModelCopyWithImpl;
@override @useResult
$Res call({
 String id, String email,@JsonKey(name: 'full_name') String fullName,@JsonKey(name: 'is_active') bool isActive,@JsonKey(name: 'is_verified') bool isVerified,@JsonKey(name: 'created_at') DateTime? createdAt
});




}
/// @nodoc
class __$PatientModelCopyWithImpl<$Res>
    implements _$PatientModelCopyWith<$Res> {
  __$PatientModelCopyWithImpl(this._self, this._then);

  final _PatientModel _self;
  final $Res Function(_PatientModel) _then;

/// Create a copy of PatientModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? email = null,Object? fullName = null,Object? isActive = null,Object? isVerified = null,Object? createdAt = freezed,}) {
  return _then(_PatientModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,fullName: null == fullName ? _self.fullName : fullName // ignore: cast_nullable_to_non_nullable
as String,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,isVerified: null == isVerified ? _self.isVerified : isVerified // ignore: cast_nullable_to_non_nullable
as bool,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}


/// @nodoc
mixin _$PatientStats {

@JsonKey(name: 'plan_id') String get planId;@JsonKey(name: 'total_sessions') int get totalSessions;@JsonKey(name: 'completed_sessions') int get completedSessions;@JsonKey(name: 'compliance_rate') double get complianceRate;@JsonKey(name: 'average_score') double? get averageScore;@JsonKey(name: 'last_session_date') DateTime? get lastSessionDate;@JsonKey(name: 'streak_days') int get streakDays;
/// Create a copy of PatientStats
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PatientStatsCopyWith<PatientStats> get copyWith => _$PatientStatsCopyWithImpl<PatientStats>(this as PatientStats, _$identity);

  /// Serializes this PatientStats to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PatientStats&&(identical(other.planId, planId) || other.planId == planId)&&(identical(other.totalSessions, totalSessions) || other.totalSessions == totalSessions)&&(identical(other.completedSessions, completedSessions) || other.completedSessions == completedSessions)&&(identical(other.complianceRate, complianceRate) || other.complianceRate == complianceRate)&&(identical(other.averageScore, averageScore) || other.averageScore == averageScore)&&(identical(other.lastSessionDate, lastSessionDate) || other.lastSessionDate == lastSessionDate)&&(identical(other.streakDays, streakDays) || other.streakDays == streakDays));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,planId,totalSessions,completedSessions,complianceRate,averageScore,lastSessionDate,streakDays);

@override
String toString() {
  return 'PatientStats(planId: $planId, totalSessions: $totalSessions, completedSessions: $completedSessions, complianceRate: $complianceRate, averageScore: $averageScore, lastSessionDate: $lastSessionDate, streakDays: $streakDays)';
}


}

/// @nodoc
abstract mixin class $PatientStatsCopyWith<$Res>  {
  factory $PatientStatsCopyWith(PatientStats value, $Res Function(PatientStats) _then) = _$PatientStatsCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'plan_id') String planId,@JsonKey(name: 'total_sessions') int totalSessions,@JsonKey(name: 'completed_sessions') int completedSessions,@JsonKey(name: 'compliance_rate') double complianceRate,@JsonKey(name: 'average_score') double? averageScore,@JsonKey(name: 'last_session_date') DateTime? lastSessionDate,@JsonKey(name: 'streak_days') int streakDays
});




}
/// @nodoc
class _$PatientStatsCopyWithImpl<$Res>
    implements $PatientStatsCopyWith<$Res> {
  _$PatientStatsCopyWithImpl(this._self, this._then);

  final PatientStats _self;
  final $Res Function(PatientStats) _then;

/// Create a copy of PatientStats
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? planId = null,Object? totalSessions = null,Object? completedSessions = null,Object? complianceRate = null,Object? averageScore = freezed,Object? lastSessionDate = freezed,Object? streakDays = null,}) {
  return _then(_self.copyWith(
planId: null == planId ? _self.planId : planId // ignore: cast_nullable_to_non_nullable
as String,totalSessions: null == totalSessions ? _self.totalSessions : totalSessions // ignore: cast_nullable_to_non_nullable
as int,completedSessions: null == completedSessions ? _self.completedSessions : completedSessions // ignore: cast_nullable_to_non_nullable
as int,complianceRate: null == complianceRate ? _self.complianceRate : complianceRate // ignore: cast_nullable_to_non_nullable
as double,averageScore: freezed == averageScore ? _self.averageScore : averageScore // ignore: cast_nullable_to_non_nullable
as double?,lastSessionDate: freezed == lastSessionDate ? _self.lastSessionDate : lastSessionDate // ignore: cast_nullable_to_non_nullable
as DateTime?,streakDays: null == streakDays ? _self.streakDays : streakDays // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [PatientStats].
extension PatientStatsPatterns on PatientStats {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PatientStats value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PatientStats() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PatientStats value)  $default,){
final _that = this;
switch (_that) {
case _PatientStats():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PatientStats value)?  $default,){
final _that = this;
switch (_that) {
case _PatientStats() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'plan_id')  String planId, @JsonKey(name: 'total_sessions')  int totalSessions, @JsonKey(name: 'completed_sessions')  int completedSessions, @JsonKey(name: 'compliance_rate')  double complianceRate, @JsonKey(name: 'average_score')  double? averageScore, @JsonKey(name: 'last_session_date')  DateTime? lastSessionDate, @JsonKey(name: 'streak_days')  int streakDays)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PatientStats() when $default != null:
return $default(_that.planId,_that.totalSessions,_that.completedSessions,_that.complianceRate,_that.averageScore,_that.lastSessionDate,_that.streakDays);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'plan_id')  String planId, @JsonKey(name: 'total_sessions')  int totalSessions, @JsonKey(name: 'completed_sessions')  int completedSessions, @JsonKey(name: 'compliance_rate')  double complianceRate, @JsonKey(name: 'average_score')  double? averageScore, @JsonKey(name: 'last_session_date')  DateTime? lastSessionDate, @JsonKey(name: 'streak_days')  int streakDays)  $default,) {final _that = this;
switch (_that) {
case _PatientStats():
return $default(_that.planId,_that.totalSessions,_that.completedSessions,_that.complianceRate,_that.averageScore,_that.lastSessionDate,_that.streakDays);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'plan_id')  String planId, @JsonKey(name: 'total_sessions')  int totalSessions, @JsonKey(name: 'completed_sessions')  int completedSessions, @JsonKey(name: 'compliance_rate')  double complianceRate, @JsonKey(name: 'average_score')  double? averageScore, @JsonKey(name: 'last_session_date')  DateTime? lastSessionDate, @JsonKey(name: 'streak_days')  int streakDays)?  $default,) {final _that = this;
switch (_that) {
case _PatientStats() when $default != null:
return $default(_that.planId,_that.totalSessions,_that.completedSessions,_that.complianceRate,_that.averageScore,_that.lastSessionDate,_that.streakDays);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PatientStats implements PatientStats {
  const _PatientStats({@JsonKey(name: 'plan_id') required this.planId, @JsonKey(name: 'total_sessions') this.totalSessions = 0, @JsonKey(name: 'completed_sessions') this.completedSessions = 0, @JsonKey(name: 'compliance_rate') this.complianceRate = 0.0, @JsonKey(name: 'average_score') this.averageScore, @JsonKey(name: 'last_session_date') this.lastSessionDate, @JsonKey(name: 'streak_days') this.streakDays = 0});
  factory _PatientStats.fromJson(Map<String, dynamic> json) => _$PatientStatsFromJson(json);

@override@JsonKey(name: 'plan_id') final  String planId;
@override@JsonKey(name: 'total_sessions') final  int totalSessions;
@override@JsonKey(name: 'completed_sessions') final  int completedSessions;
@override@JsonKey(name: 'compliance_rate') final  double complianceRate;
@override@JsonKey(name: 'average_score') final  double? averageScore;
@override@JsonKey(name: 'last_session_date') final  DateTime? lastSessionDate;
@override@JsonKey(name: 'streak_days') final  int streakDays;

/// Create a copy of PatientStats
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PatientStatsCopyWith<_PatientStats> get copyWith => __$PatientStatsCopyWithImpl<_PatientStats>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PatientStatsToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PatientStats&&(identical(other.planId, planId) || other.planId == planId)&&(identical(other.totalSessions, totalSessions) || other.totalSessions == totalSessions)&&(identical(other.completedSessions, completedSessions) || other.completedSessions == completedSessions)&&(identical(other.complianceRate, complianceRate) || other.complianceRate == complianceRate)&&(identical(other.averageScore, averageScore) || other.averageScore == averageScore)&&(identical(other.lastSessionDate, lastSessionDate) || other.lastSessionDate == lastSessionDate)&&(identical(other.streakDays, streakDays) || other.streakDays == streakDays));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,planId,totalSessions,completedSessions,complianceRate,averageScore,lastSessionDate,streakDays);

@override
String toString() {
  return 'PatientStats(planId: $planId, totalSessions: $totalSessions, completedSessions: $completedSessions, complianceRate: $complianceRate, averageScore: $averageScore, lastSessionDate: $lastSessionDate, streakDays: $streakDays)';
}


}

/// @nodoc
abstract mixin class _$PatientStatsCopyWith<$Res> implements $PatientStatsCopyWith<$Res> {
  factory _$PatientStatsCopyWith(_PatientStats value, $Res Function(_PatientStats) _then) = __$PatientStatsCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'plan_id') String planId,@JsonKey(name: 'total_sessions') int totalSessions,@JsonKey(name: 'completed_sessions') int completedSessions,@JsonKey(name: 'compliance_rate') double complianceRate,@JsonKey(name: 'average_score') double? averageScore,@JsonKey(name: 'last_session_date') DateTime? lastSessionDate,@JsonKey(name: 'streak_days') int streakDays
});




}
/// @nodoc
class __$PatientStatsCopyWithImpl<$Res>
    implements _$PatientStatsCopyWith<$Res> {
  __$PatientStatsCopyWithImpl(this._self, this._then);

  final _PatientStats _self;
  final $Res Function(_PatientStats) _then;

/// Create a copy of PatientStats
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? planId = null,Object? totalSessions = null,Object? completedSessions = null,Object? complianceRate = null,Object? averageScore = freezed,Object? lastSessionDate = freezed,Object? streakDays = null,}) {
  return _then(_PatientStats(
planId: null == planId ? _self.planId : planId // ignore: cast_nullable_to_non_nullable
as String,totalSessions: null == totalSessions ? _self.totalSessions : totalSessions // ignore: cast_nullable_to_non_nullable
as int,completedSessions: null == completedSessions ? _self.completedSessions : completedSessions // ignore: cast_nullable_to_non_nullable
as int,complianceRate: null == complianceRate ? _self.complianceRate : complianceRate // ignore: cast_nullable_to_non_nullable
as double,averageScore: freezed == averageScore ? _self.averageScore : averageScore // ignore: cast_nullable_to_non_nullable
as double?,lastSessionDate: freezed == lastSessionDate ? _self.lastSessionDate : lastSessionDate // ignore: cast_nullable_to_non_nullable
as DateTime?,streakDays: null == streakDays ? _self.streakDays : streakDays // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
