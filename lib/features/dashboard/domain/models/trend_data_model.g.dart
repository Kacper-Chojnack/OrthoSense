// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'trend_data_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_TrendDataPoint _$TrendDataPointFromJson(Map<String, dynamic> json) =>
    _TrendDataPoint(
      date: DateTime.parse(json['date'] as String),
      value: (json['value'] as num).toDouble(),
      label: json['label'] as String,
      isHighlighted: json['isHighlighted'] as bool? ?? false,
    );

Map<String, dynamic> _$TrendDataPointToJson(_TrendDataPoint instance) =>
    <String, dynamic>{
      'date': instance.date.toIso8601String(),
      'value': instance.value,
      'label': instance.label,
      'isHighlighted': instance.isHighlighted,
    };

_TrendChartData _$TrendChartDataFromJson(Map<String, dynamic> json) =>
    _TrendChartData(
      dataPoints: (json['dataPoints'] as List<dynamic>)
          .map((e) => TrendDataPoint.fromJson(e as Map<String, dynamic>))
          .toList(),
      period: $enumDecode(_$TrendPeriodEnumMap, json['period']),
      metricType: $enumDecode(_$TrendMetricTypeEnumMap, json['metricType']),
      minValue: (json['minValue'] as num?)?.toDouble() ?? 0,
      maxValue: (json['maxValue'] as num?)?.toDouble() ?? 100,
      averageValue: (json['averageValue'] as num?)?.toDouble(),
      changePercent: (json['changePercent'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$TrendChartDataToJson(_TrendChartData instance) =>
    <String, dynamic>{
      'dataPoints': instance.dataPoints,
      'period': _$TrendPeriodEnumMap[instance.period]!,
      'metricType': _$TrendMetricTypeEnumMap[instance.metricType]!,
      'minValue': instance.minValue,
      'maxValue': instance.maxValue,
      'averageValue': instance.averageValue,
      'changePercent': instance.changePercent,
    };

const _$TrendPeriodEnumMap = {
  TrendPeriod.days7: 'days7',
  TrendPeriod.days30: 'days30',
  TrendPeriod.days90: 'days90',
};

const _$TrendMetricTypeEnumMap = {
  TrendMetricType.rangeOfMotion: 'rangeOfMotion',
  TrendMetricType.sessionScore: 'sessionScore',
  TrendMetricType.exerciseDuration: 'exerciseDuration',
  TrendMetricType.completionRate: 'completionRate',
  TrendMetricType.painLevel: 'painLevel',
};

_DashboardStats _$DashboardStatsFromJson(Map<String, dynamic> json) =>
    _DashboardStats(
      totalSessions: (json['totalSessions'] as num?)?.toInt() ?? 0,
      sessionsThisWeek: (json['sessionsThisWeek'] as num?)?.toInt() ?? 0,
      averageScore: (json['averageScore'] as num?)?.toDouble() ?? 0.0,
      scoreChange: (json['scoreChange'] as num?)?.toDouble() ?? 0.0,
      activeStreakDays: (json['activeStreakDays'] as num?)?.toInt() ?? 0,
      totalTimeThisMonth: json['totalTimeThisMonth'] == null
          ? Duration.zero
          : Duration(microseconds: (json['totalTimeThisMonth'] as num).toInt()),
      completionRate: (json['completionRate'] as num?)?.toDouble() ?? 0.0,
    );

Map<String, dynamic> _$DashboardStatsToJson(_DashboardStats instance) =>
    <String, dynamic>{
      'totalSessions': instance.totalSessions,
      'sessionsThisWeek': instance.sessionsThisWeek,
      'averageScore': instance.averageScore,
      'scoreChange': instance.scoreChange,
      'activeStreakDays': instance.activeStreakDays,
      'totalTimeThisMonth': instance.totalTimeThisMonth.inMicroseconds,
      'completionRate': instance.completionRate,
    };
