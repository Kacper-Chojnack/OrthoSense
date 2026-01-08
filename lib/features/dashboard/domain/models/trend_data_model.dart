import 'package:freezed_annotation/freezed_annotation.dart';

part 'trend_data_model.freezed.dart';
part 'trend_data_model.g.dart';

/// Represents a single data point in the trend chart.
@freezed
abstract class TrendDataPoint with _$TrendDataPoint {
  const factory TrendDataPoint({
    required DateTime date,
    required double value,
    required String label,
    @Default(false) bool isHighlighted,
  }) = _TrendDataPoint;

  factory TrendDataPoint.fromJson(Map<String, dynamic> json) =>
      _$TrendDataPointFromJson(json);
}

/// Model for trend chart data with period selection.
@freezed
abstract class TrendChartData with _$TrendChartData {
  const factory TrendChartData({
    required List<TrendDataPoint> dataPoints,
    required TrendPeriod period,
    required TrendMetricType metricType,
    @Default(0) double minValue,
    @Default(100) double maxValue,
    double? averageValue,
    double? changePercent,
  }) = _TrendChartData;

  factory TrendChartData.fromJson(Map<String, dynamic> json) =>
      _$TrendChartDataFromJson(json);
}

/// Available time periods for trend analysis (F08 requirement).
enum TrendPeriod {
  days7(7, '7D', 'Last 7 days'),
  days30(30, '30D', 'Last 30 days'),
  days90(90, '90D', 'Last 90 days');

  const TrendPeriod(this.days, this.shortLabel, this.longLabel);

  final int days;
  final String shortLabel;
  final String longLabel;
}

/// Types of metrics that can be displayed in trend charts.
enum TrendMetricType {
  rangeOfMotion('Range of Motion', '°'),
  sessionScore('Session Score', '%'),
  exerciseDuration('Exercise Duration', 'min'),
  completionRate('Completion Rate', '%'),
  painLevel('Pain Level', '/10');

  const TrendMetricType(this.displayName, this.unit);

  final String displayName;
  final String unit;
}

/// Summary statistics for the dashboard.
@freezed
abstract class DashboardStats with _$DashboardStats {
  const factory DashboardStats({
    @Default(0) int totalSessions,
    @Default(0) int sessionsThisWeek,
    @Default(0.0) double averageScore,
    @Default(0.0) double scoreChange,
    @Default(0) int activeStreakDays,
    @Default(Duration.zero) Duration totalTimeThisMonth,
    @Default(0.0) double completionRate,
  }) = _DashboardStats;

  factory DashboardStats.fromJson(Map<String, dynamic> json) =>
      _$DashboardStatsFromJson(json);
}
