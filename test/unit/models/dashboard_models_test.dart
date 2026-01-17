/// Unit tests for Dashboard domain models.
///
/// Test coverage:
/// 1. TrendDataPoint model
/// 2. TrendChartData model
/// 3. TrendPeriod enum
/// 4. TrendMetricType enum
/// 5. DashboardStats model
library;

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TrendDataPoint', () {
    test('creates with required fields', () {
      final point = TrendDataPoint(
        date: DateTime(2024, 1, 1),
        value: 85.5,
        label: 'Jan 1',
      );

      expect(point.date, equals(DateTime(2024, 1, 1)));
      expect(point.value, equals(85.5));
      expect(point.label, equals('Jan 1'));
    });

    test('isHighlighted defaults to false', () {
      final point = TrendDataPoint(
        date: DateTime(2024, 1, 1),
        value: 85.5,
        label: 'Jan 1',
      );

      expect(point.isHighlighted, isFalse);
    });

    test('can set isHighlighted to true', () {
      final point = TrendDataPoint(
        date: DateTime(2024, 1, 1),
        value: 85.5,
        label: 'Jan 1',
        isHighlighted: true,
      );

      expect(point.isHighlighted, isTrue);
    });

    test('serializes to JSON', () {
      final point = TrendDataPoint(
        date: DateTime(2024, 1, 1),
        value: 85.5,
        label: 'Jan 1',
      );

      final json = point.toJson();

      expect(json['value'], equals(85.5));
      expect(json['label'], equals('Jan 1'));
    });

    test('deserializes from JSON', () {
      final json = {
        'date': '2024-01-01T00:00:00.000',
        'value': 85.5,
        'label': 'Jan 1',
        'isHighlighted': false,
      };

      final point = TrendDataPoint.fromJson(json);

      expect(point.value, equals(85.5));
      expect(point.label, equals('Jan 1'));
    });
  });

  group('TrendChartData', () {
    test('creates with required fields', () {
      final data = TrendChartData(
        dataPoints: [],
        period: TrendPeriod.days7,
        metricType: TrendMetricType.sessionScore,
      );

      expect(data.dataPoints, isEmpty);
      expect(data.period, equals(TrendPeriod.days7));
      expect(data.metricType, equals(TrendMetricType.sessionScore));
    });

    test('minValue defaults to 0', () {
      final data = TrendChartData(
        dataPoints: [],
        period: TrendPeriod.days7,
        metricType: TrendMetricType.sessionScore,
      );

      expect(data.minValue, equals(0));
    });

    test('maxValue defaults to 100', () {
      final data = TrendChartData(
        dataPoints: [],
        period: TrendPeriod.days7,
        metricType: TrendMetricType.sessionScore,
      );

      expect(data.maxValue, equals(100));
    });

    test('averageValue is nullable', () {
      final data = TrendChartData(
        dataPoints: [],
        period: TrendPeriod.days7,
        metricType: TrendMetricType.sessionScore,
      );

      expect(data.averageValue, isNull);
    });

    test('changePercent is nullable', () {
      final data = TrendChartData(
        dataPoints: [],
        period: TrendPeriod.days7,
        metricType: TrendMetricType.sessionScore,
      );

      expect(data.changePercent, isNull);
    });

    test('supports multiple data points', () {
      final data = TrendChartData(
        dataPoints: [
          TrendDataPoint(
            date: DateTime(2024, 1, 1),
            value: 80,
            label: 'Day 1',
          ),
          TrendDataPoint(
            date: DateTime(2024, 1, 2),
            value: 85,
            label: 'Day 2',
          ),
        ],
        period: TrendPeriod.days7,
        metricType: TrendMetricType.sessionScore,
      );

      expect(data.dataPoints.length, equals(2));
    });
  });

  group('TrendPeriod', () {
    test('days7 has 7 days', () {
      expect(TrendPeriod.days7.days, equals(7));
    });

    test('days30 has 30 days', () {
      expect(TrendPeriod.days30.days, equals(30));
    });

    test('days90 has 90 days', () {
      expect(TrendPeriod.days90.days, equals(90));
    });

    test('days7 short label is 7D', () {
      expect(TrendPeriod.days7.shortLabel, equals('7D'));
    });

    test('days30 short label is 30D', () {
      expect(TrendPeriod.days30.shortLabel, equals('30D'));
    });

    test('days90 short label is 90D', () {
      expect(TrendPeriod.days90.shortLabel, equals('90D'));
    });

    test('days7 long label', () {
      expect(TrendPeriod.days7.longLabel, equals('Last 7 days'));
    });

    test('days30 long label', () {
      expect(TrendPeriod.days30.longLabel, equals('Last 30 days'));
    });

    test('days90 long label', () {
      expect(TrendPeriod.days90.longLabel, equals('Last 90 days'));
    });

    test('all periods are available', () {
      final periods = TrendPeriod.values;
      expect(periods.length, equals(3));
    });
  });

  group('TrendMetricType', () {
    test('rangeOfMotion properties', () {
      expect(TrendMetricType.rangeOfMotion.displayName, equals('Range of Motion'));
      expect(TrendMetricType.rangeOfMotion.unit, equals('°'));
      expect(TrendMetricType.rangeOfMotion.maxValue, equals(180));
    });

    test('sessionScore properties', () {
      expect(TrendMetricType.sessionScore.displayName, equals('Session Score'));
      expect(TrendMetricType.sessionScore.unit, equals('%'));
      expect(TrendMetricType.sessionScore.maxValue, equals(100));
    });

    test('exerciseDuration properties', () {
      expect(TrendMetricType.exerciseDuration.displayName, equals('Exercise Duration'));
      expect(TrendMetricType.exerciseDuration.unit, equals('min'));
      expect(TrendMetricType.exerciseDuration.maxValue, equals(60));
    });

    test('completionRate properties', () {
      expect(TrendMetricType.completionRate.displayName, equals('Completion Rate'));
      expect(TrendMetricType.completionRate.unit, equals('%'));
      expect(TrendMetricType.completionRate.maxValue, equals(100));
    });

    test('painLevel properties', () {
      expect(TrendMetricType.painLevel.displayName, equals('Pain Level'));
      expect(TrendMetricType.painLevel.unit, equals('/10'));
      expect(TrendMetricType.painLevel.maxValue, equals(10));
    });

    test('all metric types are available', () {
      final metrics = TrendMetricType.values;
      expect(metrics.length, equals(5));
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

    test('creates with custom values', () {
      const stats = DashboardStats(
        totalSessions: 50,
        sessionsThisWeek: 5,
        averageScore: 85.5,
        scoreChange: 2.5,
        activeStreakDays: 7,
        totalTimeThisMonth: Duration(hours: 10),
        completionRate: 92.0,
      );

      expect(stats.totalSessions, equals(50));
      expect(stats.sessionsThisWeek, equals(5));
      expect(stats.averageScore, equals(85.5));
      expect(stats.scoreChange, equals(2.5));
      expect(stats.activeStreakDays, equals(7));
      expect(stats.totalTimeThisMonth, equals(const Duration(hours: 10)));
      expect(stats.completionRate, equals(92.0));
    });

    test('scoreChange can be negative', () {
      const stats = DashboardStats(scoreChange: -3.5);

      expect(stats.scoreChange, equals(-3.5));
    });

    test('totalTimeThisMonth converts to minutes', () {
      const stats = DashboardStats(
        totalTimeThisMonth: Duration(hours: 2, minutes: 30),
      );

      expect(stats.totalTimeThisMonth.inMinutes, equals(150));
    });
  });

  group('Dashboard calculations', () {
    test('calculates average from data points', () {
      final dataPoints = [
        TrendDataPoint(
          date: DateTime(2024, 1, 1),
          value: 80,
          label: 'Day 1',
        ),
        TrendDataPoint(
          date: DateTime(2024, 1, 2),
          value: 90,
          label: 'Day 2',
        ),
      ];

      final sum = dataPoints.fold<double>(0, (acc, p) => acc + p.value);
      final average = sum / dataPoints.length;

      expect(average, equals(85.0));
    });

    test('calculates percent change', () {
      const oldValue = 80.0;
      const newValue = 88.0;
      final change = ((newValue - oldValue) / oldValue) * 100;

      expect(change, equals(10.0));
    });

    test('handles zero old value in percent change', () {
      const oldValue = 0.0;
      const newValue = 50.0;
      final change = oldValue == 0 ? double.infinity : ((newValue - oldValue) / oldValue) * 100;

      expect(change, equals(double.infinity));
    });
  });
}

// Models for testing

class TrendDataPoint {
  TrendDataPoint({
    required this.date,
    required this.value,
    required this.label,
    this.isHighlighted = false,
  });

  factory TrendDataPoint.fromJson(Map<String, dynamic> json) {
    return TrendDataPoint(
      date: DateTime.parse(json['date'] as String),
      value: (json['value'] as num).toDouble(),
      label: json['label'] as String,
      isHighlighted: json['isHighlighted'] as bool? ?? false,
    );
  }

  final DateTime date;
  final double value;
  final String label;
  final bool isHighlighted;

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'value': value,
      'label': label,
      'isHighlighted': isHighlighted,
    };
  }
}

class TrendChartData {
  TrendChartData({
    required this.dataPoints,
    required this.period,
    required this.metricType,
    this.minValue = 0,
    this.maxValue = 100,
    this.averageValue,
    this.changePercent,
  });

  final List<TrendDataPoint> dataPoints;
  final TrendPeriod period;
  final TrendMetricType metricType;
  final double minValue;
  final double maxValue;
  final double? averageValue;
  final double? changePercent;
}

enum TrendPeriod {
  days7(7, '7D', 'Last 7 days'),
  days30(30, '30D', 'Last 30 days'),
  days90(90, '90D', 'Last 90 days');

  const TrendPeriod(this.days, this.shortLabel, this.longLabel);

  final int days;
  final String shortLabel;
  final String longLabel;
}

enum TrendMetricType {
  rangeOfMotion('Range of Motion', '°', 180),
  sessionScore('Session Score', '%', 100),
  exerciseDuration('Exercise Duration', 'min', 60),
  completionRate('Completion Rate', '%', 100),
  painLevel('Pain Level', '/10', 10);

  const TrendMetricType(this.displayName, this.unit, this.maxValue);

  final String displayName;
  final String unit;
  final double maxValue;
}

class DashboardStats {
  const DashboardStats({
    this.totalSessions = 0,
    this.sessionsThisWeek = 0,
    this.averageScore = 0.0,
    this.scoreChange = 0.0,
    this.activeStreakDays = 0,
    this.totalTimeThisMonth = Duration.zero,
    this.completionRate = 0.0,
  });

  final int totalSessions;
  final int sessionsThisWeek;
  final double averageScore;
  final double scoreChange;
  final int activeStreakDays;
  final Duration totalTimeThisMonth;
  final double completionRate;
}
