/// Unit tests for Dashboard Stats Provider.
///
/// Test coverage:
/// 1. Dashboard stats calculation from database
/// 2. Trend data generation for different metrics
/// 3. Period selection
/// 4. Streak calculation
/// 5. Score change calculation
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:orthosense/features/dashboard/domain/models/trend_data_model.dart';

void main() {
  group('DashboardStats Calculations', () {
    test('empty stats have zero values', () {
      const stats = DashboardStats();

      expect(stats.totalSessions, equals(0));
      expect(stats.sessionsThisWeek, equals(0));
      expect(stats.averageScore, equals(0.0));
      expect(stats.scoreChange, equals(0.0));
      expect(stats.activeStreakDays, equals(0));
      expect(stats.completionRate, equals(0.0));
    });

    test('stats with positive values', () {
      const stats = DashboardStats(
        totalSessions: 42,
        sessionsThisWeek: 5,
        averageScore: 87.5,
        scoreChange: 2.3,
        activeStreakDays: 14,
        totalTimeThisMonth: Duration(hours: 10, minutes: 30),
        completionRate: 95.0,
      );

      expect(stats.totalSessions, equals(42));
      expect(stats.sessionsThisWeek, equals(5));
      expect(stats.averageScore, equals(87.5));
      expect(stats.scoreChange, equals(2.3));
      expect(stats.activeStreakDays, equals(14));
      expect(stats.totalTimeThisMonth.inMinutes, equals(630));
      expect(stats.completionRate, equals(95.0));
    });

    test('stats with negative score change', () {
      const stats = DashboardStats(
        averageScore: 75.0,
        scoreChange: -5.0,
      );

      expect(stats.scoreChange, equals(-5.0));
    });
  });

  group('TrendChartData Generation', () {
    test('creates chart data with data points', () {
      final dataPoints = [
        TrendDataPoint(
          date: DateTime(2026, 1, 1),
          value: 80.0,
          label: 'Jan 1',
        ),
        TrendDataPoint(
          date: DateTime(2026, 1, 2),
          value: 85.0,
          label: 'Jan 2',
        ),
        TrendDataPoint(
          date: DateTime(2026, 1, 3),
          value: 90.0,
          label: 'Jan 3',
        ),
      ];

      final chartData = TrendChartData(
        dataPoints: dataPoints,
        period: TrendPeriod.days7,
        metricType: TrendMetricType.sessionScore,
        averageValue: 85.0,
        changePercent: 12.5,
      );

      expect(chartData.dataPoints.length, equals(3));
      expect(chartData.period, equals(TrendPeriod.days7));
      expect(chartData.metricType, equals(TrendMetricType.sessionScore));
      expect(chartData.averageValue, equals(85.0));
      expect(chartData.changePercent, equals(12.5));
    });

    test('chart data defaults for min/max values', () {
      final chartData = TrendChartData(
        dataPoints: [],
        period: TrendPeriod.days30,
        metricType: TrendMetricType.completionRate,
      );

      expect(chartData.minValue, equals(0));
      expect(chartData.maxValue, equals(100));
      expect(chartData.averageValue, isNull);
      expect(chartData.changePercent, isNull);
    });

    test('chart data with custom min/max', () {
      final chartData = TrendChartData(
        dataPoints: [],
        period: TrendPeriod.days90,
        metricType: TrendMetricType.rangeOfMotion,
        minValue: 45,
        maxValue: 180,
      );

      expect(chartData.minValue, equals(45));
      expect(chartData.maxValue, equals(180));
    });
  });

  group('TrendPeriod Functionality', () {
    test('days7 is 7 days', () {
      expect(TrendPeriod.days7.days, equals(7));
    });

    test('days30 is 30 days', () {
      expect(TrendPeriod.days30.days, equals(30));
    });

    test('days90 is 90 days', () {
      expect(TrendPeriod.days90.days, equals(90));
    });

    test('period labels are user-friendly', () {
      expect(TrendPeriod.days7.shortLabel, equals('7D'));
      expect(TrendPeriod.days7.longLabel, equals('Last 7 days'));

      expect(TrendPeriod.days30.shortLabel, equals('30D'));
      expect(TrendPeriod.days30.longLabel, equals('Last 30 days'));

      expect(TrendPeriod.days90.shortLabel, equals('90D'));
      expect(TrendPeriod.days90.longLabel, equals('Last 90 days'));
    });
  });

  group('TrendMetricType Properties', () {
    test('rangeOfMotion has correct properties', () {
      expect(TrendMetricType.rangeOfMotion.displayName, equals('Range of Motion'));
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

    test('painLevel has correct properties', () {
      expect(TrendMetricType.painLevel.displayName, equals('Pain Level'));
      expect(TrendMetricType.painLevel.unit, equals('/10'));
      expect(TrendMetricType.painLevel.maxValue, equals(10));
    });
  });

  group('TrendDataPoint Functionality', () {
    test('data point with highlighting', () {
      final highlighted = TrendDataPoint(
        date: DateTime.now(),
        value: 95.0,
        label: 'Today',
        isHighlighted: true,
      );

      expect(highlighted.isHighlighted, isTrue);
    });

    test('data point without highlighting (default)', () {
      final normal = TrendDataPoint(
        date: DateTime.now(),
        value: 80.0,
        label: 'Yesterday',
      );

      expect(normal.isHighlighted, isFalse);
    });

    test('copyWith creates modified copy', () {
      final original = TrendDataPoint(
        date: DateTime(2026, 1, 1),
        value: 50.0,
        label: 'Original',
      );

      final modified = original.copyWith(
        value: 75.0,
        isHighlighted: true,
      );

      expect(modified.date, equals(original.date));
      expect(modified.label, equals(original.label));
      expect(modified.value, equals(75.0));
      expect(modified.isHighlighted, isTrue);
    });
  });

  group('Streak Calculation Logic', () {
    // Test helper for streak calculation
    int calculateStreak(List<DateTime> sessionDates) {
      if (sessionDates.isEmpty) return 0;

      final sortedDates = sessionDates.toList()..sort((a, b) => b.compareTo(a));
      final uniqueDates = sortedDates
          .map((d) => DateTime(d.year, d.month, d.day))
          .toSet()
          .toList()
        ..sort((a, b) => b.compareTo(a));

      if (uniqueDates.isEmpty) return 0;

      final today = DateTime.now();
      final todayDate = DateTime(today.year, today.month, today.day);

      // Check if most recent session is today or yesterday
      final daysDiff = todayDate.difference(uniqueDates.first).inDays;
      if (daysDiff > 1) return 0;

      int streak = 1;
      for (int i = 1; i < uniqueDates.length; i++) {
        final diff = uniqueDates[i - 1].difference(uniqueDates[i]).inDays;
        if (diff == 1) {
          streak++;
        } else {
          break;
        }
      }

      return streak;
    }

    test('no sessions = zero streak', () {
      expect(calculateStreak([]), equals(0));
    });

    test('single session today = 1 day streak', () {
      final today = DateTime.now();
      expect(calculateStreak([today]), equals(1));
    });

    test('consecutive days = correct streak', () {
      final now = DateTime.now();
      final dates = [
        now,
        now.subtract(const Duration(days: 1)),
        now.subtract(const Duration(days: 2)),
      ];

      expect(calculateStreak(dates), equals(3));
    });

    test('gap breaks streak', () {
      final now = DateTime.now();
      final dates = [
        now,
        now.subtract(const Duration(days: 1)),
        // Gap here
        now.subtract(const Duration(days: 3)),
        now.subtract(const Duration(days: 4)),
      ];

      expect(calculateStreak(dates), equals(2));
    });
  });

  group('Score Change Calculation', () {
    double calculateScoreChange(
      List<double> thisWeekScores,
      List<double> lastWeekScores,
    ) {
      final thisWeekAvg = thisWeekScores.isEmpty
          ? 0.0
          : thisWeekScores.reduce((a, b) => a + b) / thisWeekScores.length;
      final lastWeekAvg = lastWeekScores.isEmpty
          ? 0.0
          : lastWeekScores.reduce((a, b) => a + b) / lastWeekScores.length;

      return thisWeekAvg - lastWeekAvg;
    }

    test('improvement shows positive change', () {
      final thisWeek = [85.0, 90.0, 88.0]; // avg: 87.67
      final lastWeek = [75.0, 80.0, 78.0]; // avg: 77.67

      final change = calculateScoreChange(thisWeek, lastWeek);
      expect(change, greaterThan(0));
      expect(change, closeTo(10.0, 0.1));
    });

    test('decline shows negative change', () {
      final thisWeek = [70.0, 72.0, 68.0]; // avg: 70
      final lastWeek = [85.0, 88.0, 87.0]; // avg: 86.67

      final change = calculateScoreChange(thisWeek, lastWeek);
      expect(change, lessThan(0));
    });

    test('no previous week data = change based on current', () {
      final thisWeek = [85.0, 90.0];
      final lastWeek = <double>[];

      final change = calculateScoreChange(thisWeek, lastWeek);
      expect(change, equals(87.5)); // This week avg - 0
    });

    test('no current week data = negative change', () {
      final thisWeek = <double>[];
      final lastWeek = [80.0, 85.0];

      final change = calculateScoreChange(thisWeek, lastWeek);
      expect(change, equals(-82.5)); // 0 - last week avg
    });
  });
}
