import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orthosense/features/dashboard/domain/models/trend_data_model.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'trend_provider.g.dart';

/// Provider for the currently selected trend period (F08).
@riverpod
class SelectedTrendPeriod extends _$SelectedTrendPeriod {
  @override
  TrendPeriod build() => TrendPeriod.days7;

  void setPeriod(TrendPeriod period) {
    state = period;
  }
}

/// Provider for trend chart data based on metric type and selected period.
/// TODO(data): Replace mock data with actual Drift database queries.
@riverpod
Future<TrendChartData> trendData(
  Ref ref,
  TrendMetricType metricType,
) async {
  final period = ref.watch(selectedTrendPeriodProvider);

  // Simulate network delay for realistic UX
  await Future<void>.delayed(const Duration(milliseconds: 300));

  // Generate mock data based on period and metric type
  // In production, this will query Drift database
  return _generateMockTrendData(period, metricType);
}

/// Provider for dashboard statistics summary.
/// TODO(data): Replace mock data with actual Drift database queries.
@riverpod
Future<DashboardStats> dashboardStats(Ref ref) async {
  await Future<void>.delayed(const Duration(milliseconds: 200));

  // Mock stats - replace with Drift queries
  return const DashboardStats(
    totalSessions: 12,
    sessionsThisWeek: 3,
    averageScore: 87.5,
    scoreChange: 5.2,
    activeStreakDays: 3,
    totalTimeThisMonth: Duration(hours: 4, minutes: 20),
    completionRate: 92.0,
  );
}

/// Provider for mini trend data used in stat cards.
@riverpod
Future<List<double>> miniTrendData(
  Ref ref,
  TrendMetricType metricType,
) async {
  await Future<void>.delayed(const Duration(milliseconds: 100));

  // Return last 7 values for mini chart
  final random = Random(metricType.hashCode);
  return List.generate(7, (i) {
    switch (metricType) {
      case TrendMetricType.rangeOfMotion:
        return 100.0 + random.nextDouble() * 20 + i * 2;
      case TrendMetricType.sessionScore:
        return 75.0 + random.nextDouble() * 15 + i * 1.5;
      case TrendMetricType.exerciseDuration:
        return 15.0 + random.nextDouble() * 10;
      case TrendMetricType.completionRate:
        return 80.0 + random.nextDouble() * 15 + i;
      case TrendMetricType.painLevel:
        return 6.0 - random.nextDouble() * 2 - i * 0.3;
    }
  });
}

// --- Private Helpers ---

TrendChartData _generateMockTrendData(
  TrendPeriod period,
  TrendMetricType metricType,
) {
  final now = DateTime.now();
  final random = Random(period.days * metricType.hashCode);
  final dataPoints = <TrendDataPoint>[];

  // Generate data points for the selected period
  for (var i = period.days - 1; i >= 0; i--) {
    // Skip some days randomly to simulate missing sessions
    if (random.nextDouble() < 0.3 && i != 0 && i != period.days - 1) {
      continue;
    }

    final date = now.subtract(Duration(days: i));
    final baseValue = _getBaseValue(metricType);
    final trend = (period.days - i) * _getTrendFactor(metricType);
    final noise = (random.nextDouble() - 0.5) * _getNoiseFactor(metricType);
    final value = baseValue + trend + noise;

    dataPoints.add(
      TrendDataPoint(
        date: date,
        value: value.clamp(_getMinValue(metricType), _getMaxValue(metricType)),
        label: _formatDateLabel(date, period),
        isHighlighted: i == 0, // Highlight most recent
      ),
    );
  }

  // Calculate statistics
  final values = dataPoints.map((p) => p.value).toList();
  final average = values.isNotEmpty
      ? values.reduce((a, b) => a + b) / values.length
      : 0.0;

  final firstHalf = values.take(values.length ~/ 2).toList();
  final secondHalf = values.skip(values.length ~/ 2).toList();
  final firstAvg = firstHalf.isNotEmpty
      ? firstHalf.reduce((a, b) => a + b) / firstHalf.length
      : 0.0;
  final secondAvg = secondHalf.isNotEmpty
      ? secondHalf.reduce((a, b) => a + b) / secondHalf.length
      : 0.0;
  final change = secondAvg - firstAvg;

  return TrendChartData(
    dataPoints: dataPoints,
    period: period,
    metricType: metricType,
    minValue: _getMinValue(metricType),
    maxValue: _getMaxValue(metricType),
    averageValue: average,
    changePercent: change,
  );
}

double _getBaseValue(TrendMetricType type) {
  switch (type) {
    case TrendMetricType.rangeOfMotion:
      return 95;
    case TrendMetricType.sessionScore:
      return 75;
    case TrendMetricType.exerciseDuration:
      return 20;
    case TrendMetricType.completionRate:
      return 80;
    case TrendMetricType.painLevel:
      return 5;
  }
}

double _getTrendFactor(TrendMetricType type) {
  switch (type) {
    case TrendMetricType.rangeOfMotion:
      return 0.3;
    case TrendMetricType.sessionScore:
      return 0.2;
    case TrendMetricType.exerciseDuration:
      return 0.1;
    case TrendMetricType.completionRate:
      return 0.15;
    case TrendMetricType.painLevel:
      return -0.05; // Pain should decrease
  }
}

double _getNoiseFactor(TrendMetricType type) {
  switch (type) {
    case TrendMetricType.rangeOfMotion:
      return 8;
    case TrendMetricType.sessionScore:
      return 10;
    case TrendMetricType.exerciseDuration:
      return 5;
    case TrendMetricType.completionRate:
      return 8;
    case TrendMetricType.painLevel:
      return 1;
  }
}

double _getMinValue(TrendMetricType type) {
  switch (type) {
    case TrendMetricType.rangeOfMotion:
      return 0;
    case TrendMetricType.sessionScore:
      return 0;
    case TrendMetricType.exerciseDuration:
      return 0;
    case TrendMetricType.completionRate:
      return 0;
    case TrendMetricType.painLevel:
      return 0;
  }
}

double _getMaxValue(TrendMetricType type) {
  switch (type) {
    case TrendMetricType.rangeOfMotion:
      return 180;
    case TrendMetricType.sessionScore:
      return 100;
    case TrendMetricType.exerciseDuration:
      return 60;
    case TrendMetricType.completionRate:
      return 100;
    case TrendMetricType.painLevel:
      return 10;
  }
}

String _formatDateLabel(DateTime date, TrendPeriod period) {
  switch (period) {
    case TrendPeriod.days7:
      const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return weekdays[date.weekday - 1];
    case TrendPeriod.days30:
      return '${date.day}/${date.month}';
    case TrendPeriod.days90:
      return '${date.day}/${date.month}';
  }
}
