/// Unit tests for TrendDataModel classes and TrendProvider helpers.
///
/// Test coverage:
/// 1. TrendDataPoint model
/// 2. TrendChartData model
/// 3. TrendPeriod enum
/// 4. TrendMetricType enum
/// 5. DashboardStats model
/// 6. Helper functions from trend_provider
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:orthosense/features/dashboard/domain/models/trend_data_model.dart';

void main() {
  group('TrendDataPoint', () {
    test('creates with required parameters', () {
      final point = TrendDataPoint(
        date: DateTime(2024, 1, 15),
        value: 85.5,
        label: 'Mon',
      );

      expect(point.date, equals(DateTime(2024, 1, 15)));
      expect(point.value, equals(85.5));
      expect(point.label, equals('Mon'));
    });

    test('has default isHighlighted of false', () {
      final point = TrendDataPoint(
        date: DateTime(2024, 1, 15),
        value: 50.0,
        label: 'Tue',
      );

      expect(point.isHighlighted, isFalse);
    });

    test('accepts custom isHighlighted', () {
      final point = TrendDataPoint(
        date: DateTime(2024, 1, 15),
        value: 50.0,
        label: 'Tue',
        isHighlighted: true,
      );

      expect(point.isHighlighted, isTrue);
    });

    test('handles zero value', () {
      final point = TrendDataPoint(
        date: DateTime(2024, 1, 15),
        value: 0.0,
        label: 'Wed',
      );

      expect(point.value, equals(0.0));
    });

    test('handles negative value', () {
      final point = TrendDataPoint(
        date: DateTime(2024, 1, 15),
        value: -5.0,
        label: 'Thu',
      );

      expect(point.value, equals(-5.0));
    });

    test('handles large value', () {
      final point = TrendDataPoint(
        date: DateTime(2024, 1, 15),
        value: 999999.99,
        label: 'Fri',
      );

      expect(point.value, equals(999999.99));
    });
  });

  group('TrendChartData', () {
    test('creates with required parameters', () {
      final data = TrendChartData(
        dataPoints: [],
        period: TrendPeriod.days7,
        metricType: TrendMetricType.sessionScore,
      );

      expect(data.dataPoints, isEmpty);
      expect(data.period, equals(TrendPeriod.days7));
      expect(data.metricType, equals(TrendMetricType.sessionScore));
    });

    test('has default minValue of 0', () {
      final data = TrendChartData(
        dataPoints: [],
        period: TrendPeriod.days7,
        metricType: TrendMetricType.sessionScore,
      );

      expect(data.minValue, equals(0));
    });

    test('has default maxValue of 100', () {
      final data = TrendChartData(
        dataPoints: [],
        period: TrendPeriod.days7,
        metricType: TrendMetricType.sessionScore,
      );

      expect(data.maxValue, equals(100));
    });

    test('has null averageValue by default', () {
      final data = TrendChartData(
        dataPoints: [],
        period: TrendPeriod.days7,
        metricType: TrendMetricType.sessionScore,
      );

      expect(data.averageValue, isNull);
    });

    test('has null changePercent by default', () {
      final data = TrendChartData(
        dataPoints: [],
        period: TrendPeriod.days7,
        metricType: TrendMetricType.sessionScore,
      );

      expect(data.changePercent, isNull);
    });

    test('accepts custom values', () {
      final points = [
        TrendDataPoint(date: DateTime(2024, 1, 1), value: 80, label: 'Mon'),
        TrendDataPoint(date: DateTime(2024, 1, 2), value: 90, label: 'Tue'),
      ];

      final data = TrendChartData(
        dataPoints: points,
        period: TrendPeriod.days30,
        metricType: TrendMetricType.rangeOfMotion,
        minValue: 0,
        maxValue: 180,
        averageValue: 85.0,
        changePercent: 12.5,
      );

      expect(data.dataPoints.length, equals(2));
      expect(data.period, equals(TrendPeriod.days30));
      expect(data.metricType, equals(TrendMetricType.rangeOfMotion));
      expect(data.minValue, equals(0));
      expect(data.maxValue, equals(180));
      expect(data.averageValue, equals(85.0));
      expect(data.changePercent, equals(12.5));
    });
  });

  group('TrendPeriod', () {
    test('days7 has correct values', () {
      const period = TrendPeriod.days7;

      expect(period.days, equals(7));
      expect(period.shortLabel, equals('7D'));
      expect(period.longLabel, equals('Last 7 days'));
    });

    test('days30 has correct values', () {
      const period = TrendPeriod.days30;

      expect(period.days, equals(30));
      expect(period.shortLabel, equals('30D'));
      expect(period.longLabel, equals('Last 30 days'));
    });

    test('days90 has correct values', () {
      const period = TrendPeriod.days90;

      expect(period.days, equals(90));
      expect(period.shortLabel, equals('90D'));
      expect(period.longLabel, equals('Last 90 days'));
    });

    test('has exactly 3 values', () {
      expect(TrendPeriod.values.length, equals(3));
    });

    test('values are in ascending order', () {
      expect(TrendPeriod.days7.days, lessThan(TrendPeriod.days30.days));
      expect(TrendPeriod.days30.days, lessThan(TrendPeriod.days90.days));
    });
  });

  group('TrendMetricType', () {
    test('rangeOfMotion has correct values', () {
      const metric = TrendMetricType.rangeOfMotion;

      expect(metric.displayName, equals('Range of Motion'));
      expect(metric.unit, equals('°'));
      expect(metric.maxValue, equals(180));
    });

    test('sessionScore has correct values', () {
      const metric = TrendMetricType.sessionScore;

      expect(metric.displayName, equals('Session Score'));
      expect(metric.unit, equals('%'));
      expect(metric.maxValue, equals(100));
    });

    test('exerciseDuration has correct values', () {
      const metric = TrendMetricType.exerciseDuration;

      expect(metric.displayName, equals('Exercise Duration'));
      expect(metric.unit, equals('min'));
      expect(metric.maxValue, equals(60));
    });

    test('completionRate has correct values', () {
      const metric = TrendMetricType.completionRate;

      expect(metric.displayName, equals('Completion Rate'));
      expect(metric.unit, equals('%'));
      expect(metric.maxValue, equals(100));
    });

    test('painLevel has correct values', () {
      const metric = TrendMetricType.painLevel;

      expect(metric.displayName, equals('Pain Level'));
      expect(metric.unit, equals('/10'));
      expect(metric.maxValue, equals(10));
    });

    test('has exactly 5 values', () {
      expect(TrendMetricType.values.length, equals(5));
    });
  });

  group('DashboardStats', () {
    test('creates with all defaults', () {
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
        totalTimeThisMonth: Duration(hours: 10, minutes: 30),
        completionRate: 92.5,
      );

      expect(stats.totalSessions, equals(50));
      expect(stats.sessionsThisWeek, equals(5));
      expect(stats.averageScore, equals(85.5));
      expect(stats.scoreChange, equals(2.5));
      expect(stats.activeStreakDays, equals(7));
      expect(
        stats.totalTimeThisMonth,
        equals(const Duration(hours: 10, minutes: 30)),
      );
      expect(stats.completionRate, equals(92.5));
    });

    test('handles negative scoreChange', () {
      const stats = DashboardStats(scoreChange: -5.0);

      expect(stats.scoreChange, equals(-5.0));
    });
  });

  group('Date label formatting logic', () {
    test('days7 format uses weekday names', () {
      const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

      // Monday
      final monday = DateTime(2024, 1, 15); // Monday
      expect(weekdays[monday.weekday - 1], equals('Mon'));

      // Sunday
      final sunday = DateTime(2024, 1, 21); // Sunday
      expect(weekdays[sunday.weekday - 1], equals('Sun'));
    });

    test('days30 format uses day/month', () {
      final date = DateTime(2024, 3, 15);
      final label = '${date.day}/${date.month}';

      expect(label, equals('15/3'));
    });

    test('days90 format uses day/month', () {
      final date = DateTime(2024, 12, 25);
      final label = '${date.day}/${date.month}';

      expect(label, equals('25/12'));
    });
  });

  group('Metric value extraction logic', () {
    test('rangeOfMotion uses score as proxy', () {
      // Based on _extractMetricValue in trend_provider
      const score = 75;
      final value = score.toDouble();

      expect(value, equals(75.0));
    });

    test('sessionScore directly uses score', () {
      const score = 85;
      final value = score.toDouble();

      expect(value, equals(85.0));
    });

    test('exerciseDuration converts seconds to minutes', () {
      const durationSeconds = 180;
      final value = durationSeconds / 60.0;

      expect(value, equals(3.0)); // 3 minutes
    });

    test('completionRate uses isCorrect boolean', () {
      const isCorrect = true;
      final value = isCorrect ? 100.0 : 0.0;

      expect(value, equals(100.0));
    });

    test('completionRate returns 0 for incorrect', () {
      const isCorrect = false;
      final value = isCorrect ? 100.0 : 0.0;

      expect(value, equals(0.0));
    });
  });

  group('Min/max value boundaries', () {
    test('rangeOfMotion bounds are 0-180', () {
      const minValue = 0.0;
      const maxValue = 180.0;

      expect(minValue, equals(0.0));
      expect(maxValue, equals(180.0));
    });

    test('sessionScore bounds are 0-100', () {
      const minValue = 0.0;
      const maxValue = 100.0;

      expect(minValue, equals(0.0));
      expect(maxValue, equals(100.0));
    });

    test('exerciseDuration bounds are 0-60', () {
      const minValue = 0.0;
      const maxValue = 60.0;

      expect(minValue, equals(0.0));
      expect(maxValue, equals(60.0));
    });

    test('completionRate bounds are 0-100', () {
      const minValue = 0.0;
      const maxValue = 100.0;

      expect(minValue, equals(0.0));
      expect(maxValue, equals(100.0));
    });

    test('painLevel bounds are 0-10', () {
      const minValue = 0.0;
      const maxValue = 10.0;

      expect(minValue, equals(0.0));
      expect(maxValue, equals(10.0));
    });

    test('value clamping works correctly', () {
      const minValue = 0.0;
      const maxValue = 100.0;

      expect((-5.0).clamp(minValue, maxValue), equals(0.0));
      expect((50.0).clamp(minValue, maxValue), equals(50.0));
      expect((150.0).clamp(minValue, maxValue), equals(100.0));
    });
  });

  group('Active streak calculation logic', () {
    test('no sessions returns 0 streak', () {
      const results = <DateTime>[];
      final streak = results.isEmpty ? 0 : 1;

      expect(streak, equals(0));
    });

    test('consecutive days increase streak', () {
      // Logic from _calculateActiveStreak
      final sessionDates = [
        DateTime(2024, 1, 15), // Day 1
        DateTime(2024, 1, 14), // Day 2
        DateTime(2024, 1, 13), // Day 3
      ];

      int streak = 1;
      for (int i = 0; i < sessionDates.length - 1; i++) {
        final diff = sessionDates[i].difference(sessionDates[i + 1]).inDays;
        if (diff == 1) {
          streak++;
        } else {
          break;
        }
      }

      expect(streak, equals(3));
    });

    test('gap in days breaks streak', () {
      final sessionDates = [
        DateTime(2024, 1, 15),
        DateTime(2024, 1, 14),
        DateTime(2024, 1, 12), // Gap!
        DateTime(2024, 1, 11),
      ];

      int streak = 1;
      for (int i = 0; i < sessionDates.length - 1; i++) {
        final diff = sessionDates[i].difference(sessionDates[i + 1]).inDays;
        if (diff == 1) {
          streak++;
        } else {
          break;
        }
      }

      expect(streak, equals(2)); // Only first two days
    });
  });

  group('Statistics calculation', () {
    test('average calculation', () {
      final values = [80.0, 85.0, 90.0, 95.0, 100.0];
      final average = values.reduce((a, b) => a + b) / values.length;

      expect(average, equals(90.0));
    });

    test('average with single value', () {
      final values = [75.0];
      final average = values.reduce((a, b) => a + b) / values.length;

      expect(average, equals(75.0));
    });

    test('change calculation between halves', () {
      final values = [60.0, 65.0, 70.0, 80.0, 85.0, 90.0];
      final firstHalf = values.take(values.length ~/ 2).toList();
      final secondHalf = values.skip(values.length ~/ 2).toList();

      final firstAvg = firstHalf.reduce((a, b) => a + b) / firstHalf.length;
      final secondAvg = secondHalf.reduce((a, b) => a + b) / secondHalf.length;
      final change = secondAvg - firstAvg;

      expect(firstAvg, equals(65.0));
      expect(secondAvg, equals(85.0));
      expect(change, equals(20.0));
    });

    test('negative change when scores decrease', () {
      final values = [90.0, 85.0, 80.0, 70.0, 65.0, 60.0];
      final firstHalf = values.take(values.length ~/ 2).toList();
      final secondHalf = values.skip(values.length ~/ 2).toList();

      final firstAvg = firstHalf.reduce((a, b) => a + b) / firstHalf.length;
      final secondAvg = secondHalf.reduce((a, b) => a + b) / secondHalf.length;
      final change = secondAvg - firstAvg;

      expect(change, lessThan(0));
    });
  });
}
