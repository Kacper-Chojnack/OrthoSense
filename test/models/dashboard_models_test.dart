/// Unit tests for Dashboard Domain Models.
///
/// Test coverage:
/// 1. TrendDataPoint model
/// 2. TrendChartData model
/// 3. DashboardStats model
/// 4. TrendPeriod enum
/// 5. TrendMetricType enum
/// 6. JSON serialization
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:orthosense/features/dashboard/domain/models/trend_data_model.dart';

void main() {
  group('TrendDataPoint', () {
    test('creates with required fields', () {
      final point = TrendDataPoint(
        date: DateTime(2024, 1, 15),
        value: 85.5,
        label: 'Mon',
      );

      expect(point.date, equals(DateTime(2024, 1, 15)));
      expect(point.value, equals(85.5));
      expect(point.label, equals('Mon'));
      expect(point.isHighlighted, isFalse);
    });

    test('creates with highlighted flag', () {
      final point = TrendDataPoint(
        date: DateTime(2024, 1, 15),
        value: 90.0,
        label: 'Best',
        isHighlighted: true,
      );

      expect(point.isHighlighted, isTrue);
    });

    test('serializes to JSON correctly', () {
      final point = TrendDataPoint(
        date: DateTime(2024, 6, 1),
        value: 75.0,
        label: 'Jun',
      );

      final json = point.toJson();

      expect(json['value'], equals(75.0));
      expect(json['label'], equals('Jun'));
      expect(json['is_highlighted'], isFalse);
    });

    test('deserializes from JSON correctly', () {
      final json = {
        'date': '2024-06-01T00:00:00.000',
        'value': 80.0,
        'label': 'Test',
        'is_highlighted': true,
      };

      final point = TrendDataPoint.fromJson(json);

      expect(point.value, equals(80.0));
      expect(point.label, equals('Test'));
      expect(point.isHighlighted, isTrue);
    });

    test('copyWith works correctly', () {
      final original = TrendDataPoint(
        date: DateTime(2024, 1, 1),
        value: 50.0,
        label: 'Original',
      );

      final updated = original.copyWith(value: 75.0, isHighlighted: true);

      expect(updated.date, equals(DateTime(2024, 1, 1)));
      expect(updated.value, equals(75.0));
      expect(updated.label, equals('Original'));
      expect(updated.isHighlighted, isTrue);
    });
  });

  group('TrendChartData', () {
    test('creates with required fields', () {
      final data = TrendChartData(
        dataPoints: [
          TrendDataPoint(
            date: DateTime(2024, 1, 1),
            value: 80.0,
            label: 'Day 1',
          ),
        ],
        period: TrendPeriod.days7,
        metricType: TrendMetricType.rangeOfMotion,
      );

      expect(data.dataPoints.length, equals(1));
      expect(data.period, equals(TrendPeriod.days7));
      expect(data.metricType, equals(TrendMetricType.rangeOfMotion));
      expect(data.minValue, equals(0));
      expect(data.maxValue, equals(100));
    });

    test('calculates average value when provided', () {
      final data = TrendChartData(
        dataPoints: [],
        period: TrendPeriod.days30,
        metricType: TrendMetricType.sessionScore,
        averageValue: 85.5,
      );

      expect(data.averageValue, equals(85.5));
    });

    test('tracks change percent', () {
      final data = TrendChartData(
        dataPoints: [],
        period: TrendPeriod.days90,
        metricType: TrendMetricType.completionRate,
        changePercent: 15.5,
      );

      expect(data.changePercent, equals(15.5));
    });

    test('serializes to JSON correctly', () {
      final data = TrendChartData(
        dataPoints: [],
        period: TrendPeriod.days7,
        metricType: TrendMetricType.exerciseDuration,
        averageValue: 25.0,
      );

      final json = data.toJson();

      expect(json['period'], equals('days7'));
      expect(json['metric_type'], equals('exerciseDuration'));
      expect(json['average_value'], equals(25.0));
    });
  });

  group('TrendPeriod', () {
    test('days7 has correct values', () {
      expect(TrendPeriod.days7.days, equals(7));
      expect(TrendPeriod.days7.shortLabel, equals('7D'));
      expect(TrendPeriod.days7.longLabel, equals('Last 7 days'));
    });

    test('days30 has correct values', () {
      expect(TrendPeriod.days30.days, equals(30));
      expect(TrendPeriod.days30.shortLabel, equals('30D'));
      expect(TrendPeriod.days30.longLabel, equals('Last 30 days'));
    });

    test('days90 has correct values', () {
      expect(TrendPeriod.days90.days, equals(90));
      expect(TrendPeriod.days90.shortLabel, equals('90D'));
      expect(TrendPeriod.days90.longLabel, equals('Last 90 days'));
    });

    test('all periods are available', () {
      expect(TrendPeriod.values.length, equals(3));
    });
  });

  group('TrendMetricType', () {
    test('rangeOfMotion has correct values', () {
      expect(
        TrendMetricType.rangeOfMotion.displayName,
        equals('Range of Motion'),
      );
      expect(TrendMetricType.rangeOfMotion.unit, equals('°'));
    });

    test('sessionScore has correct values', () {
      expect(TrendMetricType.sessionScore.displayName, equals('Session Score'));
      expect(TrendMetricType.sessionScore.unit, equals('%'));
    });

    test('exerciseDuration has correct values', () {
      expect(
        TrendMetricType.exerciseDuration.displayName,
        equals('Exercise Duration'),
      );
      expect(TrendMetricType.exerciseDuration.unit, equals('min'));
    });

    test('completionRate has correct values', () {
      expect(
        TrendMetricType.completionRate.displayName,
        equals('Completion Rate'),
      );
      expect(TrendMetricType.completionRate.unit, equals('%'));
    });

    test('painLevel has correct values', () {
      expect(TrendMetricType.painLevel.displayName, equals('Pain Level'));
      expect(TrendMetricType.painLevel.unit, equals('/10'));
    });

    test('all metric types are available', () {
      expect(TrendMetricType.values.length, equals(5));
    });
  });

  group('DashboardStats', () {
    test('creates with default values', () {
      const stats = DashboardStats();

      expect(stats.totalSessions, equals(0));
      expect(stats.sessionsThisWeek, equals(0));
      expect(stats.averageScore, equals(0.0));
      expect(stats.scoreChange, equals(0.0));
      expect(stats.activeStreakDays, equals(0));
      expect(stats.totalTimeThisMonth, equals(Duration.zero));
      expect(stats.completionRate, equals(0.0));
    });

    test('creates with all values', () {
      const stats = DashboardStats(
        totalSessions: 50,
        sessionsThisWeek: 5,
        averageScore: 85.5,
        scoreChange: 10.5,
        activeStreakDays: 7,
        totalTimeThisMonth: Duration(hours: 10),
        completionRate: 92.5,
      );

      expect(stats.totalSessions, equals(50));
      expect(stats.sessionsThisWeek, equals(5));
      expect(stats.averageScore, equals(85.5));
      expect(stats.scoreChange, equals(10.5));
      expect(stats.activeStreakDays, equals(7));
      expect(stats.totalTimeThisMonth, equals(const Duration(hours: 10)));
      expect(stats.completionRate, equals(92.5));
    });

    test('serializes to JSON correctly', () {
      const stats = DashboardStats(
        totalSessions: 25,
        averageScore: 75.0,
      );

      final json = stats.toJson();

      expect(json['total_sessions'], equals(25));
      expect(json['average_score'], equals(75.0));
    });

    test('copyWith works correctly', () {
      const original = DashboardStats(
        totalSessions: 10,
        averageScore: 70.0,
      );

      final updated = original.copyWith(
        sessionsThisWeek: 3,
        averageScore: 80.0,
      );

      expect(updated.totalSessions, equals(10));
      expect(updated.sessionsThisWeek, equals(3));
      expect(updated.averageScore, equals(80.0));
    });
  });
}
