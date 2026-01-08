// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'trend_data_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$TrendDataPoint {

 DateTime get date; double get value; String get label; bool get isHighlighted;
/// Create a copy of TrendDataPoint
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TrendDataPointCopyWith<TrendDataPoint> get copyWith => _$TrendDataPointCopyWithImpl<TrendDataPoint>(this as TrendDataPoint, _$identity);

  /// Serializes this TrendDataPoint to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TrendDataPoint&&(identical(other.date, date) || other.date == date)&&(identical(other.value, value) || other.value == value)&&(identical(other.label, label) || other.label == label)&&(identical(other.isHighlighted, isHighlighted) || other.isHighlighted == isHighlighted));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,date,value,label,isHighlighted);

@override
String toString() {
  return 'TrendDataPoint(date: $date, value: $value, label: $label, isHighlighted: $isHighlighted)';
}


}

/// @nodoc
abstract mixin class $TrendDataPointCopyWith<$Res>  {
  factory $TrendDataPointCopyWith(TrendDataPoint value, $Res Function(TrendDataPoint) _then) = _$TrendDataPointCopyWithImpl;
@useResult
$Res call({
 DateTime date, double value, String label, bool isHighlighted
});




}
/// @nodoc
class _$TrendDataPointCopyWithImpl<$Res>
    implements $TrendDataPointCopyWith<$Res> {
  _$TrendDataPointCopyWithImpl(this._self, this._then);

  final TrendDataPoint _self;
  final $Res Function(TrendDataPoint) _then;

/// Create a copy of TrendDataPoint
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? date = null,Object? value = null,Object? label = null,Object? isHighlighted = null,}) {
  return _then(_self.copyWith(
date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as DateTime,value: null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as double,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,isHighlighted: null == isHighlighted ? _self.isHighlighted : isHighlighted // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [TrendDataPoint].
extension TrendDataPointPatterns on TrendDataPoint {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TrendDataPoint value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TrendDataPoint() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TrendDataPoint value)  $default,){
final _that = this;
switch (_that) {
case _TrendDataPoint():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TrendDataPoint value)?  $default,){
final _that = this;
switch (_that) {
case _TrendDataPoint() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( DateTime date,  double value,  String label,  bool isHighlighted)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TrendDataPoint() when $default != null:
return $default(_that.date,_that.value,_that.label,_that.isHighlighted);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( DateTime date,  double value,  String label,  bool isHighlighted)  $default,) {final _that = this;
switch (_that) {
case _TrendDataPoint():
return $default(_that.date,_that.value,_that.label,_that.isHighlighted);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( DateTime date,  double value,  String label,  bool isHighlighted)?  $default,) {final _that = this;
switch (_that) {
case _TrendDataPoint() when $default != null:
return $default(_that.date,_that.value,_that.label,_that.isHighlighted);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TrendDataPoint implements TrendDataPoint {
  const _TrendDataPoint({required this.date, required this.value, required this.label, this.isHighlighted = false});
  factory _TrendDataPoint.fromJson(Map<String, dynamic> json) => _$TrendDataPointFromJson(json);

@override final  DateTime date;
@override final  double value;
@override final  String label;
@override@JsonKey() final  bool isHighlighted;

/// Create a copy of TrendDataPoint
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TrendDataPointCopyWith<_TrendDataPoint> get copyWith => __$TrendDataPointCopyWithImpl<_TrendDataPoint>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TrendDataPointToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TrendDataPoint&&(identical(other.date, date) || other.date == date)&&(identical(other.value, value) || other.value == value)&&(identical(other.label, label) || other.label == label)&&(identical(other.isHighlighted, isHighlighted) || other.isHighlighted == isHighlighted));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,date,value,label,isHighlighted);

@override
String toString() {
  return 'TrendDataPoint(date: $date, value: $value, label: $label, isHighlighted: $isHighlighted)';
}


}

/// @nodoc
abstract mixin class _$TrendDataPointCopyWith<$Res> implements $TrendDataPointCopyWith<$Res> {
  factory _$TrendDataPointCopyWith(_TrendDataPoint value, $Res Function(_TrendDataPoint) _then) = __$TrendDataPointCopyWithImpl;
@override @useResult
$Res call({
 DateTime date, double value, String label, bool isHighlighted
});




}
/// @nodoc
class __$TrendDataPointCopyWithImpl<$Res>
    implements _$TrendDataPointCopyWith<$Res> {
  __$TrendDataPointCopyWithImpl(this._self, this._then);

  final _TrendDataPoint _self;
  final $Res Function(_TrendDataPoint) _then;

/// Create a copy of TrendDataPoint
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? date = null,Object? value = null,Object? label = null,Object? isHighlighted = null,}) {
  return _then(_TrendDataPoint(
date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as DateTime,value: null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as double,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,isHighlighted: null == isHighlighted ? _self.isHighlighted : isHighlighted // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}


/// @nodoc
mixin _$TrendChartData {

 List<TrendDataPoint> get dataPoints; TrendPeriod get period; TrendMetricType get metricType; double get minValue; double get maxValue; double? get averageValue; double? get changePercent;
/// Create a copy of TrendChartData
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TrendChartDataCopyWith<TrendChartData> get copyWith => _$TrendChartDataCopyWithImpl<TrendChartData>(this as TrendChartData, _$identity);

  /// Serializes this TrendChartData to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TrendChartData&&const DeepCollectionEquality().equals(other.dataPoints, dataPoints)&&(identical(other.period, period) || other.period == period)&&(identical(other.metricType, metricType) || other.metricType == metricType)&&(identical(other.minValue, minValue) || other.minValue == minValue)&&(identical(other.maxValue, maxValue) || other.maxValue == maxValue)&&(identical(other.averageValue, averageValue) || other.averageValue == averageValue)&&(identical(other.changePercent, changePercent) || other.changePercent == changePercent));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(dataPoints),period,metricType,minValue,maxValue,averageValue,changePercent);

@override
String toString() {
  return 'TrendChartData(dataPoints: $dataPoints, period: $period, metricType: $metricType, minValue: $minValue, maxValue: $maxValue, averageValue: $averageValue, changePercent: $changePercent)';
}


}

/// @nodoc
abstract mixin class $TrendChartDataCopyWith<$Res>  {
  factory $TrendChartDataCopyWith(TrendChartData value, $Res Function(TrendChartData) _then) = _$TrendChartDataCopyWithImpl;
@useResult
$Res call({
 List<TrendDataPoint> dataPoints, TrendPeriod period, TrendMetricType metricType, double minValue, double maxValue, double? averageValue, double? changePercent
});




}
/// @nodoc
class _$TrendChartDataCopyWithImpl<$Res>
    implements $TrendChartDataCopyWith<$Res> {
  _$TrendChartDataCopyWithImpl(this._self, this._then);

  final TrendChartData _self;
  final $Res Function(TrendChartData) _then;

/// Create a copy of TrendChartData
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? dataPoints = null,Object? period = null,Object? metricType = null,Object? minValue = null,Object? maxValue = null,Object? averageValue = freezed,Object? changePercent = freezed,}) {
  return _then(_self.copyWith(
dataPoints: null == dataPoints ? _self.dataPoints : dataPoints // ignore: cast_nullable_to_non_nullable
as List<TrendDataPoint>,period: null == period ? _self.period : period // ignore: cast_nullable_to_non_nullable
as TrendPeriod,metricType: null == metricType ? _self.metricType : metricType // ignore: cast_nullable_to_non_nullable
as TrendMetricType,minValue: null == minValue ? _self.minValue : minValue // ignore: cast_nullable_to_non_nullable
as double,maxValue: null == maxValue ? _self.maxValue : maxValue // ignore: cast_nullable_to_non_nullable
as double,averageValue: freezed == averageValue ? _self.averageValue : averageValue // ignore: cast_nullable_to_non_nullable
as double?,changePercent: freezed == changePercent ? _self.changePercent : changePercent // ignore: cast_nullable_to_non_nullable
as double?,
  ));
}

}


/// Adds pattern-matching-related methods to [TrendChartData].
extension TrendChartDataPatterns on TrendChartData {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TrendChartData value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TrendChartData() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TrendChartData value)  $default,){
final _that = this;
switch (_that) {
case _TrendChartData():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TrendChartData value)?  $default,){
final _that = this;
switch (_that) {
case _TrendChartData() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<TrendDataPoint> dataPoints,  TrendPeriod period,  TrendMetricType metricType,  double minValue,  double maxValue,  double? averageValue,  double? changePercent)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TrendChartData() when $default != null:
return $default(_that.dataPoints,_that.period,_that.metricType,_that.minValue,_that.maxValue,_that.averageValue,_that.changePercent);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<TrendDataPoint> dataPoints,  TrendPeriod period,  TrendMetricType metricType,  double minValue,  double maxValue,  double? averageValue,  double? changePercent)  $default,) {final _that = this;
switch (_that) {
case _TrendChartData():
return $default(_that.dataPoints,_that.period,_that.metricType,_that.minValue,_that.maxValue,_that.averageValue,_that.changePercent);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<TrendDataPoint> dataPoints,  TrendPeriod period,  TrendMetricType metricType,  double minValue,  double maxValue,  double? averageValue,  double? changePercent)?  $default,) {final _that = this;
switch (_that) {
case _TrendChartData() when $default != null:
return $default(_that.dataPoints,_that.period,_that.metricType,_that.minValue,_that.maxValue,_that.averageValue,_that.changePercent);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TrendChartData implements TrendChartData {
  const _TrendChartData({required final  List<TrendDataPoint> dataPoints, required this.period, required this.metricType, this.minValue = 0, this.maxValue = 100, this.averageValue, this.changePercent}): _dataPoints = dataPoints;
  factory _TrendChartData.fromJson(Map<String, dynamic> json) => _$TrendChartDataFromJson(json);

 final  List<TrendDataPoint> _dataPoints;
@override List<TrendDataPoint> get dataPoints {
  if (_dataPoints is EqualUnmodifiableListView) return _dataPoints;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_dataPoints);
}

@override final  TrendPeriod period;
@override final  TrendMetricType metricType;
@override@JsonKey() final  double minValue;
@override@JsonKey() final  double maxValue;
@override final  double? averageValue;
@override final  double? changePercent;

/// Create a copy of TrendChartData
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TrendChartDataCopyWith<_TrendChartData> get copyWith => __$TrendChartDataCopyWithImpl<_TrendChartData>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TrendChartDataToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TrendChartData&&const DeepCollectionEquality().equals(other._dataPoints, _dataPoints)&&(identical(other.period, period) || other.period == period)&&(identical(other.metricType, metricType) || other.metricType == metricType)&&(identical(other.minValue, minValue) || other.minValue == minValue)&&(identical(other.maxValue, maxValue) || other.maxValue == maxValue)&&(identical(other.averageValue, averageValue) || other.averageValue == averageValue)&&(identical(other.changePercent, changePercent) || other.changePercent == changePercent));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_dataPoints),period,metricType,minValue,maxValue,averageValue,changePercent);

@override
String toString() {
  return 'TrendChartData(dataPoints: $dataPoints, period: $period, metricType: $metricType, minValue: $minValue, maxValue: $maxValue, averageValue: $averageValue, changePercent: $changePercent)';
}


}

/// @nodoc
abstract mixin class _$TrendChartDataCopyWith<$Res> implements $TrendChartDataCopyWith<$Res> {
  factory _$TrendChartDataCopyWith(_TrendChartData value, $Res Function(_TrendChartData) _then) = __$TrendChartDataCopyWithImpl;
@override @useResult
$Res call({
 List<TrendDataPoint> dataPoints, TrendPeriod period, TrendMetricType metricType, double minValue, double maxValue, double? averageValue, double? changePercent
});




}
/// @nodoc
class __$TrendChartDataCopyWithImpl<$Res>
    implements _$TrendChartDataCopyWith<$Res> {
  __$TrendChartDataCopyWithImpl(this._self, this._then);

  final _TrendChartData _self;
  final $Res Function(_TrendChartData) _then;

/// Create a copy of TrendChartData
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? dataPoints = null,Object? period = null,Object? metricType = null,Object? minValue = null,Object? maxValue = null,Object? averageValue = freezed,Object? changePercent = freezed,}) {
  return _then(_TrendChartData(
dataPoints: null == dataPoints ? _self._dataPoints : dataPoints // ignore: cast_nullable_to_non_nullable
as List<TrendDataPoint>,period: null == period ? _self.period : period // ignore: cast_nullable_to_non_nullable
as TrendPeriod,metricType: null == metricType ? _self.metricType : metricType // ignore: cast_nullable_to_non_nullable
as TrendMetricType,minValue: null == minValue ? _self.minValue : minValue // ignore: cast_nullable_to_non_nullable
as double,maxValue: null == maxValue ? _self.maxValue : maxValue // ignore: cast_nullable_to_non_nullable
as double,averageValue: freezed == averageValue ? _self.averageValue : averageValue // ignore: cast_nullable_to_non_nullable
as double?,changePercent: freezed == changePercent ? _self.changePercent : changePercent // ignore: cast_nullable_to_non_nullable
as double?,
  ));
}


}


/// @nodoc
mixin _$DashboardStats {

 int get totalSessions; int get sessionsThisWeek; double get averageScore; double get scoreChange; int get activeStreakDays; Duration get totalTimeThisMonth; double get completionRate;
/// Create a copy of DashboardStats
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DashboardStatsCopyWith<DashboardStats> get copyWith => _$DashboardStatsCopyWithImpl<DashboardStats>(this as DashboardStats, _$identity);

  /// Serializes this DashboardStats to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DashboardStats&&(identical(other.totalSessions, totalSessions) || other.totalSessions == totalSessions)&&(identical(other.sessionsThisWeek, sessionsThisWeek) || other.sessionsThisWeek == sessionsThisWeek)&&(identical(other.averageScore, averageScore) || other.averageScore == averageScore)&&(identical(other.scoreChange, scoreChange) || other.scoreChange == scoreChange)&&(identical(other.activeStreakDays, activeStreakDays) || other.activeStreakDays == activeStreakDays)&&(identical(other.totalTimeThisMonth, totalTimeThisMonth) || other.totalTimeThisMonth == totalTimeThisMonth)&&(identical(other.completionRate, completionRate) || other.completionRate == completionRate));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,totalSessions,sessionsThisWeek,averageScore,scoreChange,activeStreakDays,totalTimeThisMonth,completionRate);

@override
String toString() {
  return 'DashboardStats(totalSessions: $totalSessions, sessionsThisWeek: $sessionsThisWeek, averageScore: $averageScore, scoreChange: $scoreChange, activeStreakDays: $activeStreakDays, totalTimeThisMonth: $totalTimeThisMonth, completionRate: $completionRate)';
}


}

/// @nodoc
abstract mixin class $DashboardStatsCopyWith<$Res>  {
  factory $DashboardStatsCopyWith(DashboardStats value, $Res Function(DashboardStats) _then) = _$DashboardStatsCopyWithImpl;
@useResult
$Res call({
 int totalSessions, int sessionsThisWeek, double averageScore, double scoreChange, int activeStreakDays, Duration totalTimeThisMonth, double completionRate
});




}
/// @nodoc
class _$DashboardStatsCopyWithImpl<$Res>
    implements $DashboardStatsCopyWith<$Res> {
  _$DashboardStatsCopyWithImpl(this._self, this._then);

  final DashboardStats _self;
  final $Res Function(DashboardStats) _then;

/// Create a copy of DashboardStats
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? totalSessions = null,Object? sessionsThisWeek = null,Object? averageScore = null,Object? scoreChange = null,Object? activeStreakDays = null,Object? totalTimeThisMonth = null,Object? completionRate = null,}) {
  return _then(_self.copyWith(
totalSessions: null == totalSessions ? _self.totalSessions : totalSessions // ignore: cast_nullable_to_non_nullable
as int,sessionsThisWeek: null == sessionsThisWeek ? _self.sessionsThisWeek : sessionsThisWeek // ignore: cast_nullable_to_non_nullable
as int,averageScore: null == averageScore ? _self.averageScore : averageScore // ignore: cast_nullable_to_non_nullable
as double,scoreChange: null == scoreChange ? _self.scoreChange : scoreChange // ignore: cast_nullable_to_non_nullable
as double,activeStreakDays: null == activeStreakDays ? _self.activeStreakDays : activeStreakDays // ignore: cast_nullable_to_non_nullable
as int,totalTimeThisMonth: null == totalTimeThisMonth ? _self.totalTimeThisMonth : totalTimeThisMonth // ignore: cast_nullable_to_non_nullable
as Duration,completionRate: null == completionRate ? _self.completionRate : completionRate // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [DashboardStats].
extension DashboardStatsPatterns on DashboardStats {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DashboardStats value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DashboardStats() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DashboardStats value)  $default,){
final _that = this;
switch (_that) {
case _DashboardStats():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DashboardStats value)?  $default,){
final _that = this;
switch (_that) {
case _DashboardStats() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int totalSessions,  int sessionsThisWeek,  double averageScore,  double scoreChange,  int activeStreakDays,  Duration totalTimeThisMonth,  double completionRate)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DashboardStats() when $default != null:
return $default(_that.totalSessions,_that.sessionsThisWeek,_that.averageScore,_that.scoreChange,_that.activeStreakDays,_that.totalTimeThisMonth,_that.completionRate);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int totalSessions,  int sessionsThisWeek,  double averageScore,  double scoreChange,  int activeStreakDays,  Duration totalTimeThisMonth,  double completionRate)  $default,) {final _that = this;
switch (_that) {
case _DashboardStats():
return $default(_that.totalSessions,_that.sessionsThisWeek,_that.averageScore,_that.scoreChange,_that.activeStreakDays,_that.totalTimeThisMonth,_that.completionRate);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int totalSessions,  int sessionsThisWeek,  double averageScore,  double scoreChange,  int activeStreakDays,  Duration totalTimeThisMonth,  double completionRate)?  $default,) {final _that = this;
switch (_that) {
case _DashboardStats() when $default != null:
return $default(_that.totalSessions,_that.sessionsThisWeek,_that.averageScore,_that.scoreChange,_that.activeStreakDays,_that.totalTimeThisMonth,_that.completionRate);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DashboardStats implements DashboardStats {
  const _DashboardStats({this.totalSessions = 0, this.sessionsThisWeek = 0, this.averageScore = 0.0, this.scoreChange = 0.0, this.activeStreakDays = 0, this.totalTimeThisMonth = Duration.zero, this.completionRate = 0.0});
  factory _DashboardStats.fromJson(Map<String, dynamic> json) => _$DashboardStatsFromJson(json);

@override@JsonKey() final  int totalSessions;
@override@JsonKey() final  int sessionsThisWeek;
@override@JsonKey() final  double averageScore;
@override@JsonKey() final  double scoreChange;
@override@JsonKey() final  int activeStreakDays;
@override@JsonKey() final  Duration totalTimeThisMonth;
@override@JsonKey() final  double completionRate;

/// Create a copy of DashboardStats
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DashboardStatsCopyWith<_DashboardStats> get copyWith => __$DashboardStatsCopyWithImpl<_DashboardStats>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DashboardStatsToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DashboardStats&&(identical(other.totalSessions, totalSessions) || other.totalSessions == totalSessions)&&(identical(other.sessionsThisWeek, sessionsThisWeek) || other.sessionsThisWeek == sessionsThisWeek)&&(identical(other.averageScore, averageScore) || other.averageScore == averageScore)&&(identical(other.scoreChange, scoreChange) || other.scoreChange == scoreChange)&&(identical(other.activeStreakDays, activeStreakDays) || other.activeStreakDays == activeStreakDays)&&(identical(other.totalTimeThisMonth, totalTimeThisMonth) || other.totalTimeThisMonth == totalTimeThisMonth)&&(identical(other.completionRate, completionRate) || other.completionRate == completionRate));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,totalSessions,sessionsThisWeek,averageScore,scoreChange,activeStreakDays,totalTimeThisMonth,completionRate);

@override
String toString() {
  return 'DashboardStats(totalSessions: $totalSessions, sessionsThisWeek: $sessionsThisWeek, averageScore: $averageScore, scoreChange: $scoreChange, activeStreakDays: $activeStreakDays, totalTimeThisMonth: $totalTimeThisMonth, completionRate: $completionRate)';
}


}

/// @nodoc
abstract mixin class _$DashboardStatsCopyWith<$Res> implements $DashboardStatsCopyWith<$Res> {
  factory _$DashboardStatsCopyWith(_DashboardStats value, $Res Function(_DashboardStats) _then) = __$DashboardStatsCopyWithImpl;
@override @useResult
$Res call({
 int totalSessions, int sessionsThisWeek, double averageScore, double scoreChange, int activeStreakDays, Duration totalTimeThisMonth, double completionRate
});




}
/// @nodoc
class __$DashboardStatsCopyWithImpl<$Res>
    implements _$DashboardStatsCopyWith<$Res> {
  __$DashboardStatsCopyWithImpl(this._self, this._then);

  final _DashboardStats _self;
  final $Res Function(_DashboardStats) _then;

/// Create a copy of DashboardStats
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? totalSessions = null,Object? sessionsThisWeek = null,Object? averageScore = null,Object? scoreChange = null,Object? activeStreakDays = null,Object? totalTimeThisMonth = null,Object? completionRate = null,}) {
  return _then(_DashboardStats(
totalSessions: null == totalSessions ? _self.totalSessions : totalSessions // ignore: cast_nullable_to_non_nullable
as int,sessionsThisWeek: null == sessionsThisWeek ? _self.sessionsThisWeek : sessionsThisWeek // ignore: cast_nullable_to_non_nullable
as int,averageScore: null == averageScore ? _self.averageScore : averageScore // ignore: cast_nullable_to_non_nullable
as double,scoreChange: null == scoreChange ? _self.scoreChange : scoreChange // ignore: cast_nullable_to_non_nullable
as double,activeStreakDays: null == activeStreakDays ? _self.activeStreakDays : activeStreakDays // ignore: cast_nullable_to_non_nullable
as int,totalTimeThisMonth: null == totalTimeThisMonth ? _self.totalTimeThisMonth : totalTimeThisMonth // ignore: cast_nullable_to_non_nullable
as Duration,completionRate: null == completionRate ? _self.completionRate : completionRate // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}

// dart format on
