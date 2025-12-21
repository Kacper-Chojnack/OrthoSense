// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'treatment_plan_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$TreatmentPlanModel {

 String get id; String get name;@JsonKey(name: 'patient_id') String get patientId;@JsonKey(name: 'therapist_id') String get therapistId;@JsonKey(name: 'start_date') DateTime get startDate;@JsonKey(name: 'protocol_id') String? get protocolId; String get notes;@JsonKey(name: 'end_date') DateTime? get endDate; PlanStatus get status;@JsonKey(name: 'frequency_per_week') int get frequencyPerWeek;@JsonKey(name: 'custom_parameters') Map<String, dynamic> get customParameters;@JsonKey(name: 'created_at') DateTime? get createdAt;
/// Create a copy of TreatmentPlanModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TreatmentPlanModelCopyWith<TreatmentPlanModel> get copyWith => _$TreatmentPlanModelCopyWithImpl<TreatmentPlanModel>(this as TreatmentPlanModel, _$identity);

  /// Serializes this TreatmentPlanModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TreatmentPlanModel&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.patientId, patientId) || other.patientId == patientId)&&(identical(other.therapistId, therapistId) || other.therapistId == therapistId)&&(identical(other.startDate, startDate) || other.startDate == startDate)&&(identical(other.protocolId, protocolId) || other.protocolId == protocolId)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.endDate, endDate) || other.endDate == endDate)&&(identical(other.status, status) || other.status == status)&&(identical(other.frequencyPerWeek, frequencyPerWeek) || other.frequencyPerWeek == frequencyPerWeek)&&const DeepCollectionEquality().equals(other.customParameters, customParameters)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,patientId,therapistId,startDate,protocolId,notes,endDate,status,frequencyPerWeek,const DeepCollectionEquality().hash(customParameters),createdAt);

@override
String toString() {
  return 'TreatmentPlanModel(id: $id, name: $name, patientId: $patientId, therapistId: $therapistId, startDate: $startDate, protocolId: $protocolId, notes: $notes, endDate: $endDate, status: $status, frequencyPerWeek: $frequencyPerWeek, customParameters: $customParameters, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $TreatmentPlanModelCopyWith<$Res>  {
  factory $TreatmentPlanModelCopyWith(TreatmentPlanModel value, $Res Function(TreatmentPlanModel) _then) = _$TreatmentPlanModelCopyWithImpl;
@useResult
$Res call({
 String id, String name,@JsonKey(name: 'patient_id') String patientId,@JsonKey(name: 'therapist_id') String therapistId,@JsonKey(name: 'start_date') DateTime startDate,@JsonKey(name: 'protocol_id') String? protocolId, String notes,@JsonKey(name: 'end_date') DateTime? endDate, PlanStatus status,@JsonKey(name: 'frequency_per_week') int frequencyPerWeek,@JsonKey(name: 'custom_parameters') Map<String, dynamic> customParameters,@JsonKey(name: 'created_at') DateTime? createdAt
});




}
/// @nodoc
class _$TreatmentPlanModelCopyWithImpl<$Res>
    implements $TreatmentPlanModelCopyWith<$Res> {
  _$TreatmentPlanModelCopyWithImpl(this._self, this._then);

  final TreatmentPlanModel _self;
  final $Res Function(TreatmentPlanModel) _then;

/// Create a copy of TreatmentPlanModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? patientId = null,Object? therapistId = null,Object? startDate = null,Object? protocolId = freezed,Object? notes = null,Object? endDate = freezed,Object? status = null,Object? frequencyPerWeek = null,Object? customParameters = null,Object? createdAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,patientId: null == patientId ? _self.patientId : patientId // ignore: cast_nullable_to_non_nullable
as String,therapistId: null == therapistId ? _self.therapistId : therapistId // ignore: cast_nullable_to_non_nullable
as String,startDate: null == startDate ? _self.startDate : startDate // ignore: cast_nullable_to_non_nullable
as DateTime,protocolId: freezed == protocolId ? _self.protocolId : protocolId // ignore: cast_nullable_to_non_nullable
as String?,notes: null == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String,endDate: freezed == endDate ? _self.endDate : endDate // ignore: cast_nullable_to_non_nullable
as DateTime?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as PlanStatus,frequencyPerWeek: null == frequencyPerWeek ? _self.frequencyPerWeek : frequencyPerWeek // ignore: cast_nullable_to_non_nullable
as int,customParameters: null == customParameters ? _self.customParameters : customParameters // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [TreatmentPlanModel].
extension TreatmentPlanModelPatterns on TreatmentPlanModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TreatmentPlanModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TreatmentPlanModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TreatmentPlanModel value)  $default,){
final _that = this;
switch (_that) {
case _TreatmentPlanModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TreatmentPlanModel value)?  $default,){
final _that = this;
switch (_that) {
case _TreatmentPlanModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name, @JsonKey(name: 'patient_id')  String patientId, @JsonKey(name: 'therapist_id')  String therapistId, @JsonKey(name: 'start_date')  DateTime startDate, @JsonKey(name: 'protocol_id')  String? protocolId,  String notes, @JsonKey(name: 'end_date')  DateTime? endDate,  PlanStatus status, @JsonKey(name: 'frequency_per_week')  int frequencyPerWeek, @JsonKey(name: 'custom_parameters')  Map<String, dynamic> customParameters, @JsonKey(name: 'created_at')  DateTime? createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TreatmentPlanModel() when $default != null:
return $default(_that.id,_that.name,_that.patientId,_that.therapistId,_that.startDate,_that.protocolId,_that.notes,_that.endDate,_that.status,_that.frequencyPerWeek,_that.customParameters,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name, @JsonKey(name: 'patient_id')  String patientId, @JsonKey(name: 'therapist_id')  String therapistId, @JsonKey(name: 'start_date')  DateTime startDate, @JsonKey(name: 'protocol_id')  String? protocolId,  String notes, @JsonKey(name: 'end_date')  DateTime? endDate,  PlanStatus status, @JsonKey(name: 'frequency_per_week')  int frequencyPerWeek, @JsonKey(name: 'custom_parameters')  Map<String, dynamic> customParameters, @JsonKey(name: 'created_at')  DateTime? createdAt)  $default,) {final _that = this;
switch (_that) {
case _TreatmentPlanModel():
return $default(_that.id,_that.name,_that.patientId,_that.therapistId,_that.startDate,_that.protocolId,_that.notes,_that.endDate,_that.status,_that.frequencyPerWeek,_that.customParameters,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name, @JsonKey(name: 'patient_id')  String patientId, @JsonKey(name: 'therapist_id')  String therapistId, @JsonKey(name: 'start_date')  DateTime startDate, @JsonKey(name: 'protocol_id')  String? protocolId,  String notes, @JsonKey(name: 'end_date')  DateTime? endDate,  PlanStatus status, @JsonKey(name: 'frequency_per_week')  int frequencyPerWeek, @JsonKey(name: 'custom_parameters')  Map<String, dynamic> customParameters, @JsonKey(name: 'created_at')  DateTime? createdAt)?  $default,) {final _that = this;
switch (_that) {
case _TreatmentPlanModel() when $default != null:
return $default(_that.id,_that.name,_that.patientId,_that.therapistId,_that.startDate,_that.protocolId,_that.notes,_that.endDate,_that.status,_that.frequencyPerWeek,_that.customParameters,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TreatmentPlanModel implements TreatmentPlanModel {
  const _TreatmentPlanModel({required this.id, required this.name, @JsonKey(name: 'patient_id') required this.patientId, @JsonKey(name: 'therapist_id') required this.therapistId, @JsonKey(name: 'start_date') required this.startDate, @JsonKey(name: 'protocol_id') this.protocolId, this.notes = '', @JsonKey(name: 'end_date') this.endDate, this.status = PlanStatus.pending, @JsonKey(name: 'frequency_per_week') this.frequencyPerWeek = 3, @JsonKey(name: 'custom_parameters') final  Map<String, dynamic> customParameters = const {}, @JsonKey(name: 'created_at') this.createdAt}): _customParameters = customParameters;
  factory _TreatmentPlanModel.fromJson(Map<String, dynamic> json) => _$TreatmentPlanModelFromJson(json);

@override final  String id;
@override final  String name;
@override@JsonKey(name: 'patient_id') final  String patientId;
@override@JsonKey(name: 'therapist_id') final  String therapistId;
@override@JsonKey(name: 'start_date') final  DateTime startDate;
@override@JsonKey(name: 'protocol_id') final  String? protocolId;
@override@JsonKey() final  String notes;
@override@JsonKey(name: 'end_date') final  DateTime? endDate;
@override@JsonKey() final  PlanStatus status;
@override@JsonKey(name: 'frequency_per_week') final  int frequencyPerWeek;
 final  Map<String, dynamic> _customParameters;
@override@JsonKey(name: 'custom_parameters') Map<String, dynamic> get customParameters {
  if (_customParameters is EqualUnmodifiableMapView) return _customParameters;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_customParameters);
}

@override@JsonKey(name: 'created_at') final  DateTime? createdAt;

/// Create a copy of TreatmentPlanModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TreatmentPlanModelCopyWith<_TreatmentPlanModel> get copyWith => __$TreatmentPlanModelCopyWithImpl<_TreatmentPlanModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TreatmentPlanModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TreatmentPlanModel&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.patientId, patientId) || other.patientId == patientId)&&(identical(other.therapistId, therapistId) || other.therapistId == therapistId)&&(identical(other.startDate, startDate) || other.startDate == startDate)&&(identical(other.protocolId, protocolId) || other.protocolId == protocolId)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.endDate, endDate) || other.endDate == endDate)&&(identical(other.status, status) || other.status == status)&&(identical(other.frequencyPerWeek, frequencyPerWeek) || other.frequencyPerWeek == frequencyPerWeek)&&const DeepCollectionEquality().equals(other._customParameters, _customParameters)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,patientId,therapistId,startDate,protocolId,notes,endDate,status,frequencyPerWeek,const DeepCollectionEquality().hash(_customParameters),createdAt);

@override
String toString() {
  return 'TreatmentPlanModel(id: $id, name: $name, patientId: $patientId, therapistId: $therapistId, startDate: $startDate, protocolId: $protocolId, notes: $notes, endDate: $endDate, status: $status, frequencyPerWeek: $frequencyPerWeek, customParameters: $customParameters, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$TreatmentPlanModelCopyWith<$Res> implements $TreatmentPlanModelCopyWith<$Res> {
  factory _$TreatmentPlanModelCopyWith(_TreatmentPlanModel value, $Res Function(_TreatmentPlanModel) _then) = __$TreatmentPlanModelCopyWithImpl;
@override @useResult
$Res call({
 String id, String name,@JsonKey(name: 'patient_id') String patientId,@JsonKey(name: 'therapist_id') String therapistId,@JsonKey(name: 'start_date') DateTime startDate,@JsonKey(name: 'protocol_id') String? protocolId, String notes,@JsonKey(name: 'end_date') DateTime? endDate, PlanStatus status,@JsonKey(name: 'frequency_per_week') int frequencyPerWeek,@JsonKey(name: 'custom_parameters') Map<String, dynamic> customParameters,@JsonKey(name: 'created_at') DateTime? createdAt
});




}
/// @nodoc
class __$TreatmentPlanModelCopyWithImpl<$Res>
    implements _$TreatmentPlanModelCopyWith<$Res> {
  __$TreatmentPlanModelCopyWithImpl(this._self, this._then);

  final _TreatmentPlanModel _self;
  final $Res Function(_TreatmentPlanModel) _then;

/// Create a copy of TreatmentPlanModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? patientId = null,Object? therapistId = null,Object? startDate = null,Object? protocolId = freezed,Object? notes = null,Object? endDate = freezed,Object? status = null,Object? frequencyPerWeek = null,Object? customParameters = null,Object? createdAt = freezed,}) {
  return _then(_TreatmentPlanModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,patientId: null == patientId ? _self.patientId : patientId // ignore: cast_nullable_to_non_nullable
as String,therapistId: null == therapistId ? _self.therapistId : therapistId // ignore: cast_nullable_to_non_nullable
as String,startDate: null == startDate ? _self.startDate : startDate // ignore: cast_nullable_to_non_nullable
as DateTime,protocolId: freezed == protocolId ? _self.protocolId : protocolId // ignore: cast_nullable_to_non_nullable
as String?,notes: null == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String,endDate: freezed == endDate ? _self.endDate : endDate // ignore: cast_nullable_to_non_nullable
as DateTime?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as PlanStatus,frequencyPerWeek: null == frequencyPerWeek ? _self.frequencyPerWeek : frequencyPerWeek // ignore: cast_nullable_to_non_nullable
as int,customParameters: null == customParameters ? _self._customParameters : customParameters // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}


/// @nodoc
mixin _$TreatmentPlanDetails {

 String get id; String get name;@JsonKey(name: 'patient_id') String get patientId;@JsonKey(name: 'therapist_id') String get therapistId;@JsonKey(name: 'start_date') DateTime get startDate;@JsonKey(name: 'protocol_id') String? get protocolId; String get notes;@JsonKey(name: 'end_date') DateTime? get endDate; PlanStatus get status;@JsonKey(name: 'frequency_per_week') int get frequencyPerWeek;@JsonKey(name: 'custom_parameters') Map<String, dynamic> get customParameters;@JsonKey(name: 'created_at') DateTime? get createdAt;@JsonKey(name: 'patient_name') String get patientName;@JsonKey(name: 'protocol_name') String? get protocolName;@JsonKey(name: 'sessions_completed') int get sessionsCompleted;@JsonKey(name: 'compliance_rate') double get complianceRate;
/// Create a copy of TreatmentPlanDetails
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TreatmentPlanDetailsCopyWith<TreatmentPlanDetails> get copyWith => _$TreatmentPlanDetailsCopyWithImpl<TreatmentPlanDetails>(this as TreatmentPlanDetails, _$identity);

  /// Serializes this TreatmentPlanDetails to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TreatmentPlanDetails&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.patientId, patientId) || other.patientId == patientId)&&(identical(other.therapistId, therapistId) || other.therapistId == therapistId)&&(identical(other.startDate, startDate) || other.startDate == startDate)&&(identical(other.protocolId, protocolId) || other.protocolId == protocolId)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.endDate, endDate) || other.endDate == endDate)&&(identical(other.status, status) || other.status == status)&&(identical(other.frequencyPerWeek, frequencyPerWeek) || other.frequencyPerWeek == frequencyPerWeek)&&const DeepCollectionEquality().equals(other.customParameters, customParameters)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.patientName, patientName) || other.patientName == patientName)&&(identical(other.protocolName, protocolName) || other.protocolName == protocolName)&&(identical(other.sessionsCompleted, sessionsCompleted) || other.sessionsCompleted == sessionsCompleted)&&(identical(other.complianceRate, complianceRate) || other.complianceRate == complianceRate));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,patientId,therapistId,startDate,protocolId,notes,endDate,status,frequencyPerWeek,const DeepCollectionEquality().hash(customParameters),createdAt,patientName,protocolName,sessionsCompleted,complianceRate);

@override
String toString() {
  return 'TreatmentPlanDetails(id: $id, name: $name, patientId: $patientId, therapistId: $therapistId, startDate: $startDate, protocolId: $protocolId, notes: $notes, endDate: $endDate, status: $status, frequencyPerWeek: $frequencyPerWeek, customParameters: $customParameters, createdAt: $createdAt, patientName: $patientName, protocolName: $protocolName, sessionsCompleted: $sessionsCompleted, complianceRate: $complianceRate)';
}


}

/// @nodoc
abstract mixin class $TreatmentPlanDetailsCopyWith<$Res>  {
  factory $TreatmentPlanDetailsCopyWith(TreatmentPlanDetails value, $Res Function(TreatmentPlanDetails) _then) = _$TreatmentPlanDetailsCopyWithImpl;
@useResult
$Res call({
 String id, String name,@JsonKey(name: 'patient_id') String patientId,@JsonKey(name: 'therapist_id') String therapistId,@JsonKey(name: 'start_date') DateTime startDate,@JsonKey(name: 'protocol_id') String? protocolId, String notes,@JsonKey(name: 'end_date') DateTime? endDate, PlanStatus status,@JsonKey(name: 'frequency_per_week') int frequencyPerWeek,@JsonKey(name: 'custom_parameters') Map<String, dynamic> customParameters,@JsonKey(name: 'created_at') DateTime? createdAt,@JsonKey(name: 'patient_name') String patientName,@JsonKey(name: 'protocol_name') String? protocolName,@JsonKey(name: 'sessions_completed') int sessionsCompleted,@JsonKey(name: 'compliance_rate') double complianceRate
});




}
/// @nodoc
class _$TreatmentPlanDetailsCopyWithImpl<$Res>
    implements $TreatmentPlanDetailsCopyWith<$Res> {
  _$TreatmentPlanDetailsCopyWithImpl(this._self, this._then);

  final TreatmentPlanDetails _self;
  final $Res Function(TreatmentPlanDetails) _then;

/// Create a copy of TreatmentPlanDetails
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? patientId = null,Object? therapistId = null,Object? startDate = null,Object? protocolId = freezed,Object? notes = null,Object? endDate = freezed,Object? status = null,Object? frequencyPerWeek = null,Object? customParameters = null,Object? createdAt = freezed,Object? patientName = null,Object? protocolName = freezed,Object? sessionsCompleted = null,Object? complianceRate = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,patientId: null == patientId ? _self.patientId : patientId // ignore: cast_nullable_to_non_nullable
as String,therapistId: null == therapistId ? _self.therapistId : therapistId // ignore: cast_nullable_to_non_nullable
as String,startDate: null == startDate ? _self.startDate : startDate // ignore: cast_nullable_to_non_nullable
as DateTime,protocolId: freezed == protocolId ? _self.protocolId : protocolId // ignore: cast_nullable_to_non_nullable
as String?,notes: null == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String,endDate: freezed == endDate ? _self.endDate : endDate // ignore: cast_nullable_to_non_nullable
as DateTime?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as PlanStatus,frequencyPerWeek: null == frequencyPerWeek ? _self.frequencyPerWeek : frequencyPerWeek // ignore: cast_nullable_to_non_nullable
as int,customParameters: null == customParameters ? _self.customParameters : customParameters // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,patientName: null == patientName ? _self.patientName : patientName // ignore: cast_nullable_to_non_nullable
as String,protocolName: freezed == protocolName ? _self.protocolName : protocolName // ignore: cast_nullable_to_non_nullable
as String?,sessionsCompleted: null == sessionsCompleted ? _self.sessionsCompleted : sessionsCompleted // ignore: cast_nullable_to_non_nullable
as int,complianceRate: null == complianceRate ? _self.complianceRate : complianceRate // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [TreatmentPlanDetails].
extension TreatmentPlanDetailsPatterns on TreatmentPlanDetails {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TreatmentPlanDetails value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TreatmentPlanDetails() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TreatmentPlanDetails value)  $default,){
final _that = this;
switch (_that) {
case _TreatmentPlanDetails():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TreatmentPlanDetails value)?  $default,){
final _that = this;
switch (_that) {
case _TreatmentPlanDetails() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name, @JsonKey(name: 'patient_id')  String patientId, @JsonKey(name: 'therapist_id')  String therapistId, @JsonKey(name: 'start_date')  DateTime startDate, @JsonKey(name: 'protocol_id')  String? protocolId,  String notes, @JsonKey(name: 'end_date')  DateTime? endDate,  PlanStatus status, @JsonKey(name: 'frequency_per_week')  int frequencyPerWeek, @JsonKey(name: 'custom_parameters')  Map<String, dynamic> customParameters, @JsonKey(name: 'created_at')  DateTime? createdAt, @JsonKey(name: 'patient_name')  String patientName, @JsonKey(name: 'protocol_name')  String? protocolName, @JsonKey(name: 'sessions_completed')  int sessionsCompleted, @JsonKey(name: 'compliance_rate')  double complianceRate)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TreatmentPlanDetails() when $default != null:
return $default(_that.id,_that.name,_that.patientId,_that.therapistId,_that.startDate,_that.protocolId,_that.notes,_that.endDate,_that.status,_that.frequencyPerWeek,_that.customParameters,_that.createdAt,_that.patientName,_that.protocolName,_that.sessionsCompleted,_that.complianceRate);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name, @JsonKey(name: 'patient_id')  String patientId, @JsonKey(name: 'therapist_id')  String therapistId, @JsonKey(name: 'start_date')  DateTime startDate, @JsonKey(name: 'protocol_id')  String? protocolId,  String notes, @JsonKey(name: 'end_date')  DateTime? endDate,  PlanStatus status, @JsonKey(name: 'frequency_per_week')  int frequencyPerWeek, @JsonKey(name: 'custom_parameters')  Map<String, dynamic> customParameters, @JsonKey(name: 'created_at')  DateTime? createdAt, @JsonKey(name: 'patient_name')  String patientName, @JsonKey(name: 'protocol_name')  String? protocolName, @JsonKey(name: 'sessions_completed')  int sessionsCompleted, @JsonKey(name: 'compliance_rate')  double complianceRate)  $default,) {final _that = this;
switch (_that) {
case _TreatmentPlanDetails():
return $default(_that.id,_that.name,_that.patientId,_that.therapistId,_that.startDate,_that.protocolId,_that.notes,_that.endDate,_that.status,_that.frequencyPerWeek,_that.customParameters,_that.createdAt,_that.patientName,_that.protocolName,_that.sessionsCompleted,_that.complianceRate);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name, @JsonKey(name: 'patient_id')  String patientId, @JsonKey(name: 'therapist_id')  String therapistId, @JsonKey(name: 'start_date')  DateTime startDate, @JsonKey(name: 'protocol_id')  String? protocolId,  String notes, @JsonKey(name: 'end_date')  DateTime? endDate,  PlanStatus status, @JsonKey(name: 'frequency_per_week')  int frequencyPerWeek, @JsonKey(name: 'custom_parameters')  Map<String, dynamic> customParameters, @JsonKey(name: 'created_at')  DateTime? createdAt, @JsonKey(name: 'patient_name')  String patientName, @JsonKey(name: 'protocol_name')  String? protocolName, @JsonKey(name: 'sessions_completed')  int sessionsCompleted, @JsonKey(name: 'compliance_rate')  double complianceRate)?  $default,) {final _that = this;
switch (_that) {
case _TreatmentPlanDetails() when $default != null:
return $default(_that.id,_that.name,_that.patientId,_that.therapistId,_that.startDate,_that.protocolId,_that.notes,_that.endDate,_that.status,_that.frequencyPerWeek,_that.customParameters,_that.createdAt,_that.patientName,_that.protocolName,_that.sessionsCompleted,_that.complianceRate);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TreatmentPlanDetails implements TreatmentPlanDetails {
  const _TreatmentPlanDetails({required this.id, required this.name, @JsonKey(name: 'patient_id') required this.patientId, @JsonKey(name: 'therapist_id') required this.therapistId, @JsonKey(name: 'start_date') required this.startDate, @JsonKey(name: 'protocol_id') this.protocolId, this.notes = '', @JsonKey(name: 'end_date') this.endDate, this.status = PlanStatus.pending, @JsonKey(name: 'frequency_per_week') this.frequencyPerWeek = 3, @JsonKey(name: 'custom_parameters') final  Map<String, dynamic> customParameters = const {}, @JsonKey(name: 'created_at') this.createdAt, @JsonKey(name: 'patient_name') this.patientName = '', @JsonKey(name: 'protocol_name') this.protocolName, @JsonKey(name: 'sessions_completed') this.sessionsCompleted = 0, @JsonKey(name: 'compliance_rate') this.complianceRate = 0.0}): _customParameters = customParameters;
  factory _TreatmentPlanDetails.fromJson(Map<String, dynamic> json) => _$TreatmentPlanDetailsFromJson(json);

@override final  String id;
@override final  String name;
@override@JsonKey(name: 'patient_id') final  String patientId;
@override@JsonKey(name: 'therapist_id') final  String therapistId;
@override@JsonKey(name: 'start_date') final  DateTime startDate;
@override@JsonKey(name: 'protocol_id') final  String? protocolId;
@override@JsonKey() final  String notes;
@override@JsonKey(name: 'end_date') final  DateTime? endDate;
@override@JsonKey() final  PlanStatus status;
@override@JsonKey(name: 'frequency_per_week') final  int frequencyPerWeek;
 final  Map<String, dynamic> _customParameters;
@override@JsonKey(name: 'custom_parameters') Map<String, dynamic> get customParameters {
  if (_customParameters is EqualUnmodifiableMapView) return _customParameters;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_customParameters);
}

@override@JsonKey(name: 'created_at') final  DateTime? createdAt;
@override@JsonKey(name: 'patient_name') final  String patientName;
@override@JsonKey(name: 'protocol_name') final  String? protocolName;
@override@JsonKey(name: 'sessions_completed') final  int sessionsCompleted;
@override@JsonKey(name: 'compliance_rate') final  double complianceRate;

/// Create a copy of TreatmentPlanDetails
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TreatmentPlanDetailsCopyWith<_TreatmentPlanDetails> get copyWith => __$TreatmentPlanDetailsCopyWithImpl<_TreatmentPlanDetails>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TreatmentPlanDetailsToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TreatmentPlanDetails&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.patientId, patientId) || other.patientId == patientId)&&(identical(other.therapistId, therapistId) || other.therapistId == therapistId)&&(identical(other.startDate, startDate) || other.startDate == startDate)&&(identical(other.protocolId, protocolId) || other.protocolId == protocolId)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.endDate, endDate) || other.endDate == endDate)&&(identical(other.status, status) || other.status == status)&&(identical(other.frequencyPerWeek, frequencyPerWeek) || other.frequencyPerWeek == frequencyPerWeek)&&const DeepCollectionEquality().equals(other._customParameters, _customParameters)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.patientName, patientName) || other.patientName == patientName)&&(identical(other.protocolName, protocolName) || other.protocolName == protocolName)&&(identical(other.sessionsCompleted, sessionsCompleted) || other.sessionsCompleted == sessionsCompleted)&&(identical(other.complianceRate, complianceRate) || other.complianceRate == complianceRate));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,patientId,therapistId,startDate,protocolId,notes,endDate,status,frequencyPerWeek,const DeepCollectionEquality().hash(_customParameters),createdAt,patientName,protocolName,sessionsCompleted,complianceRate);

@override
String toString() {
  return 'TreatmentPlanDetails(id: $id, name: $name, patientId: $patientId, therapistId: $therapistId, startDate: $startDate, protocolId: $protocolId, notes: $notes, endDate: $endDate, status: $status, frequencyPerWeek: $frequencyPerWeek, customParameters: $customParameters, createdAt: $createdAt, patientName: $patientName, protocolName: $protocolName, sessionsCompleted: $sessionsCompleted, complianceRate: $complianceRate)';
}


}

/// @nodoc
abstract mixin class _$TreatmentPlanDetailsCopyWith<$Res> implements $TreatmentPlanDetailsCopyWith<$Res> {
  factory _$TreatmentPlanDetailsCopyWith(_TreatmentPlanDetails value, $Res Function(_TreatmentPlanDetails) _then) = __$TreatmentPlanDetailsCopyWithImpl;
@override @useResult
$Res call({
 String id, String name,@JsonKey(name: 'patient_id') String patientId,@JsonKey(name: 'therapist_id') String therapistId,@JsonKey(name: 'start_date') DateTime startDate,@JsonKey(name: 'protocol_id') String? protocolId, String notes,@JsonKey(name: 'end_date') DateTime? endDate, PlanStatus status,@JsonKey(name: 'frequency_per_week') int frequencyPerWeek,@JsonKey(name: 'custom_parameters') Map<String, dynamic> customParameters,@JsonKey(name: 'created_at') DateTime? createdAt,@JsonKey(name: 'patient_name') String patientName,@JsonKey(name: 'protocol_name') String? protocolName,@JsonKey(name: 'sessions_completed') int sessionsCompleted,@JsonKey(name: 'compliance_rate') double complianceRate
});




}
/// @nodoc
class __$TreatmentPlanDetailsCopyWithImpl<$Res>
    implements _$TreatmentPlanDetailsCopyWith<$Res> {
  __$TreatmentPlanDetailsCopyWithImpl(this._self, this._then);

  final _TreatmentPlanDetails _self;
  final $Res Function(_TreatmentPlanDetails) _then;

/// Create a copy of TreatmentPlanDetails
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? patientId = null,Object? therapistId = null,Object? startDate = null,Object? protocolId = freezed,Object? notes = null,Object? endDate = freezed,Object? status = null,Object? frequencyPerWeek = null,Object? customParameters = null,Object? createdAt = freezed,Object? patientName = null,Object? protocolName = freezed,Object? sessionsCompleted = null,Object? complianceRate = null,}) {
  return _then(_TreatmentPlanDetails(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,patientId: null == patientId ? _self.patientId : patientId // ignore: cast_nullable_to_non_nullable
as String,therapistId: null == therapistId ? _self.therapistId : therapistId // ignore: cast_nullable_to_non_nullable
as String,startDate: null == startDate ? _self.startDate : startDate // ignore: cast_nullable_to_non_nullable
as DateTime,protocolId: freezed == protocolId ? _self.protocolId : protocolId // ignore: cast_nullable_to_non_nullable
as String?,notes: null == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String,endDate: freezed == endDate ? _self.endDate : endDate // ignore: cast_nullable_to_non_nullable
as DateTime?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as PlanStatus,frequencyPerWeek: null == frequencyPerWeek ? _self.frequencyPerWeek : frequencyPerWeek // ignore: cast_nullable_to_non_nullable
as int,customParameters: null == customParameters ? _self._customParameters : customParameters // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,patientName: null == patientName ? _self.patientName : patientName // ignore: cast_nullable_to_non_nullable
as String,protocolName: freezed == protocolName ? _self.protocolName : protocolName // ignore: cast_nullable_to_non_nullable
as String?,sessionsCompleted: null == sessionsCompleted ? _self.sessionsCompleted : sessionsCompleted // ignore: cast_nullable_to_non_nullable
as int,complianceRate: null == complianceRate ? _self.complianceRate : complianceRate // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}

// dart format on
