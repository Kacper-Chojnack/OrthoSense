/// Unit tests for Dashboard Trend Models.
///
/// Test coverage:
/// 1. TrendDataPoint creation and JSON serialization
/// 2. TrendChartData creation and defaults
/// 3. TrendPeriod enum values and properties
/// 4. TrendMetricType enum values and properties
/// 5. DashboardStats creation and defaults
/// 6. copyWith functionality for all models
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:orthosense/features/dashboard/domain/models/trend_data_model.dart';

void main() {
  group('TrendDataPoint', () {
    test('creates with required fields', () {
      final now = DateTime.now();
      final dataPoint = TrendDataPoint(
        date: now,
        value: 85.5,
        label: 'Jan 9',
      );

      expect(dataPoint.date, equals(now));
      expect(dataPoint.value, equals(85.5));
      expect(dataPoint.label, equals('Jan 9'));
      expect(dataPoint.isHighlighted, isFalse); // default
    });

    test('creates with isHighlighted = true', () {
      final dataPoint = TrendDataPoint(
        date: DateTime.now(),
        value: 90.0,
        label: 'Today',
        isHighlighted: true,
      );

      expect(dataPoint.isHighlighted, isTrue);
    });

    test('copyWith creates new instance with updated values', () {
      final original = TrendDataPoint(
        date: DateTime(2026, 1, 1),
        value: 50.0,
        label: 'Original',
      );

      final updated = original.copyWith(value: 75.0, isHighlighted: true);

      expect(updated.value, equals(75.0));
      expect(updated.isHighlighted, isTrue);
      expect(updated.label, equals('Original')); // unchanged
      expect(updated.date, equals(DateTime(2026, 1, 1))); // unchanged
    });

    test('toJson and fromJson roundtrip', () {
      final original = TrendDataPoint(
        date: DateTime(2026, 1, 9, 12, 0, 0),
        value: 88.5,
        label: 'Test',
        isHighlighted: true,
      );

      final json = original.toJson();
      final restored = TrendDataPoint.fromJson(json);

      expect(restored.value, equals(original.value));
      expect(restored.label, equals(original.label));
      expect(restored.isHighlighted, equals(original.isHighlighted));
    });
  });

  group('TrendChartData', () {
    test('creates with required fields and defaults', () {
      final dataPoints = [
        TrendDataPoint(
          date: DateTime.now(),
          value: 80.0,
          label: 'Point 1',
        ),
      ];

      final chartData = TrendChartData(
        dataPoints: dataPoints,
        period: TrendPeriod.days7,
        metricType: TrendMetricType.sessionScore,
      );

      expect(chartData.dataPoints.length, equals(1));
      expect(chartData.period, equals(TrendPeriod.days7));
      expect(chartData.metricType, equals(TrendMetricType.sessionScore));
      expect(chartData.minValue, equals(0)); // default
      expect(chartData.maxValue, equals(100)); // default
      expect(chartData.averageValue, isNull);
      expect(chartData.changePercent, isNull);
    });

    test('creates with all fields', () {
      final chartData = TrendChartData(
        dataPoints: [],
        period: TrendPeriod.days30,
        metricType: TrendMetricType.rangeOfMotion,
        minValue: 10,
        maxValue: 180,
        averageValue: 95.5,
        changePercent: 12.3,
      );

      expect(chartData.minValue, equals(10));
      expect(chartData.maxValue, equals(180));
      expect(chartData.averageValue, equals(95.5));
      expect(chartData.changePercent, equals(12.3));
    });

    test('copyWith updates selected fields', () {
      final original = TrendChartData(
        dataPoints: [],
        period: TrendPeriod.days7,
        metricType: TrendMetricType.sessionScore,
      );

      final updated = original.copyWith(
        period: TrendPeriod.days90,
        averageValue: 85.0,
      );

      expect(updated.period, equals(TrendPeriod.days90));
      expect(updated.averageValue, equals(85.0));
      expect(updated.metricType, equals(TrendMetricType.sessionScore));
    });

    test('fromJson creates instance from map', () {
      final json = {
        'dataPoints': <Map<String, dynamic>>[],
        'period': 'days30',
        'metricType': 'sessionScore',
        'minValue': 0.0,
        'maxValue': 100.0,
      };

      final chartData = TrendChartData.fromJson(json);

      expect(chartData.period, equals(TrendPeriod.days30));
      expect(chartData.metricType, equals(TrendMetricType.sessionScore));
    });
  });

  group('TrendPeriod', () {
    test('days7 has correct properties', () {
      expect(TrendPeriod.days7.days, equals(7));
      expect(TrendPeriod.days7.shortLabel, equals('7D'));
      expect(TrendPeriod.days7.longLabel, equals('Last 7 days'));
    });

    test('days30 has correct properties', () {
      expect(TrendPeriod.days30.days, equals(30));
      expect(TrendPeriod.days30.shortLabel, equals('30D'));
      expect(TrendPeriod.days30.longLabel, equals('Last 30 days'));
    });

    test('days90 has correct properties', () {
      expect(TrendPeriod.days90.days, equals(90));
      expect(TrendPeriod.days90.shortLabel, equals('90D'));
      expect(TrendPeriod.days90.longLabel, equals('Last 90 days'));
    });

    test('all values are accessible', () {
      expect(TrendPeriod.values.length, equals(3));
      expect(TrendPeriod.values, contains(TrendPeriod.days7));
      expect(TrendPeriod.values, contains(TrendPeriod.days30));
      expect(TrendPeriod.values, contains(TrendPeriod.days90));
    });
  });

  group('TrendMetricType', () {
    test('rangeOfMotion has correct properties', () {
      expect(
        TrendMetricType.rangeOfMotion.displayName,
        equals('Range of Motion'),
      );
      expect(TrendMetricType.rangeOfMotion.unit, equals('°'));
      expect(TrendMetricType.rangeOfMotion.maxValue, equals(180));
    });

    test('sessionScore has correct properties', () {
      expect(TrendMetricType.sessionScore.displayName, equals('Session Score'));
      expect(TrendMetricType.sessionScore.unit, equals('%'));
      expect(TrendMetricType.sessionScore.maxValue, equals(100));
    });

    test('exerciseDuration has correct properties', () {
      expect(
        TrendMetricType.exerciseDuration.displayName,
        equals('Exercise Duration'),
      );
      expect(TrendMetricType.exerciseDuration.unit, equals('min'));
      expect(TrendMetricType.exerciseDuration.maxValue, equals(60));
    });

    test('completionRate has correct properties', () {
      expect(
        TrendMetricType.completionRate.displayName,
        equals('Completion Rate'),
      );
      expect(TrendMetricType.completionRate.unit, equals('%'));
      expect(TrendMetricType.completionRate.maxValue, equals(100));
    });

    test('painLevel has correct properties', () {
      expect(TrendMetricType.painLevel.displayName, equals('Pain Level'));
      expect(TrendMetricType.painLevel.unit, equals('/10'));
      expect(TrendMetricType.painLevel.maxValue, equals(10));
    });

    test('all values are accessible', () {
      expect(TrendMetricType.values.length, equals(5));
    });
  });

  group('DashboardStats', () {
    test('creates with defaults', () {
      const stats = DashboardStats();

      expect(stats.totalSessions, equals(0));
      expect(stats.sessionsThisWeek, equals(0));
      expect(stats.averageScore, equals(0.0));
      expect(stats.scoreChange, equals(0.0));
      expect(stats.activeStreakDays, equals(0));
      expect(stats.totalTimeThisMonth, equals(Duration.zero));
      expect(stats.completionRate, equals(0.0));
    });

    test('creates with all fields', () {
      const stats = DashboardStats(
        totalSessions: 50,
        sessionsThisWeek: 5,
        averageScore: 87.5,
        scoreChange: 3.2,
        activeStreakDays: 7,
        totalTimeThisMonth: Duration(hours: 8, minutes: 30),
        completionRate: 92.0,
      );

      expect(stats.totalSessions, equals(50));
      expect(stats.sessionsThisWeek, equals(5));
      expect(stats.averageScore, equals(87.5));
      expect(stats.scoreChange, equals(3.2));
      expect(stats.activeStreakDays, equals(7));
      expect(
        stats.totalTimeThisMonth,
        equals(const Duration(hours: 8, minutes: 30)),
      );
      expect(stats.completionRate, equals(92.0));
    });

    test('copyWith updates selected fields', () {
      const original = DashboardStats(
        totalSessions: 10,
        averageScore: 80.0,
      );

      final updated = original.copyWith(
        totalSessions: 15,
        activeStreakDays: 3,
      );

      expect(updated.totalSessions, equals(15));
      expect(updated.activeStreakDays, equals(3));
      expect(updated.averageScore, equals(80.0)); // unchanged
    });

    test('toJson and fromJson roundtrip', () {
      const original = DashboardStats(
        totalSessions: 25,
        sessionsThisWeek: 4,
        averageScore: 85.0,
        scoreChange: 5.0,
        activeStreakDays: 10,
        totalTimeThisMonth: Duration(hours: 5),
        completionRate: 88.0,
      );

      final json = original.toJson();
      final restored = DashboardStats.fromJson(json);

      expect(restored.totalSessions, equals(original.totalSessions));
      expect(restored.sessionsThisWeek, equals(original.sessionsThisWeek));
      expect(restored.averageScore, equals(original.averageScore));
      expect(restored.scoreChange, equals(original.scoreChange));
      expect(restored.activeStreakDays, equals(original.activeStreakDays));
      expect(restored.completionRate, equals(original.completionRate));
    });

    test('handles negative score change', () {
      const stats = DashboardStats(
        averageScore: 75.0,
        scoreChange: -5.5, // Score decreased
      );

      expect(stats.scoreChange, equals(-5.5));
    });
  });

  group('TrendDataPoint Edge Cases', () {
    test('handles zero value', () {
      final dataPoint = TrendDataPoint(
        date: DateTime.now(),
        value: 0,
        label: 'Zero',
      );

      expect(dataPoint.value, equals(0));
    });

    test('handles negative value', () {
      final dataPoint = TrendDataPoint(
        date: DateTime.now(),
        value: -10.5,
        label: 'Negative',
      );

      expect(dataPoint.value, equals(-10.5));
    });

    test('handles empty label', () {
      final dataPoint = TrendDataPoint(
        date: DateTime.now(),
        value: 50.0,
        label: '',
      );

      expect(dataPoint.label, isEmpty);
    });
  });

  group('TrendChartData Edge Cases', () {
    test('handles empty dataPoints list', () {
      final chartData = TrendChartData(
        dataPoints: [],
        period: TrendPeriod.days7,
        metricType: TrendMetricType.sessionScore,
      );

      expect(chartData.dataPoints, isEmpty);
    });

    test('handles large number of dataPoints', () {
      final dataPoints = List.generate(
        100,
        (i) => TrendDataPoint(
          date: DateTime.now().subtract(Duration(days: i)),
          value: i.toDouble(),
          label: 'Day $i',
        ),
      );

      final chartData = TrendChartData(
        dataPoints: dataPoints,
        period: TrendPeriod.days90,
        metricType: TrendMetricType.rangeOfMotion,
      );

      expect(chartData.dataPoints.length, equals(100));
    });
  });
}
