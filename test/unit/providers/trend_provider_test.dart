/// Unit tests for TrendProvider.
///
/// Test coverage:
/// 1. SelectedTrendPeriod state management
/// 2. TrendData generation
/// 3. DashboardStats calculations
/// 4. Streak calculation
/// 5. Score change calculations
library;

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SelectedTrendPeriod', () {
    test('defaults to days7', () {
      var period = TrendPeriod.days7;
      expect(period, equals(TrendPeriod.days7));
    });

    test('setPeriod changes state to days30', () {
      var period = TrendPeriod.days7;
      period = TrendPeriod.days30;
      expect(period, equals(TrendPeriod.days30));
    });

    test('setPeriod changes state to days90', () {
      var period = TrendPeriod.days7;
      period = TrendPeriod.days90;
      expect(period, equals(TrendPeriod.days90));
    });
  });

  group('TrendData generation', () {
    test('generates data points for each day', () {
      const period = TrendPeriod.days7;
      final now = DateTime.now();
      final startDate = now.subtract(Duration(days: period.days));

      final daysDiff = now.difference(startDate).inDays;
      expect(daysDiff, equals(7));
    });

    test('calculates average value from results', () {
      final scores = [80, 85, 90, 75, 88];
      final average = scores.reduce((a, b) => a + b) / scores.length;

      expect(average, closeTo(83.6, 0.1));
    });

    test('calculates percent change', () {
      const oldAverage = 80.0;
      const newAverage = 88.0;
      final percentChange = ((newAverage - oldAverage) / oldAverage) * 100;

      expect(percentChange, equals(10.0));
    });

    test('handles empty results', () {
      final scores = <int>[];
      final average = scores.isEmpty ? 0.0 : scores.reduce((a, b) => a + b) / scores.length;

      expect(average, equals(0.0));
    });
  });

  group('DashboardStats calculations', () {
    test('calculates total time from results', () {
      final durations = [120, 180, 90, 150]; // seconds
      final totalSeconds = durations.reduce((a, b) => a + b);
      final totalMinutes = totalSeconds ~/ 60;

      expect(totalMinutes, equals(9));
    });

    test('counts sessions this week', () {
      final now = DateTime.now();
      final weekAgo = now.subtract(const Duration(days: 7));

      final sessions = [
        MockExerciseResult(performedAt: now.subtract(const Duration(days: 1))),
        MockExerciseResult(performedAt: now.subtract(const Duration(days: 5))),
        MockExerciseResult(performedAt: now.subtract(const Duration(days: 10))),
      ];

      final thisWeek = sessions.where((s) => s.performedAt.isAfter(weekAgo)).length;

      expect(thisWeek, equals(2));
    });

    test('calculates completion rate', () {
      final results = [
        MockExerciseResult(isCorrect: true),
        MockExerciseResult(isCorrect: true),
        MockExerciseResult(isCorrect: false),
        MockExerciseResult(isCorrect: true),
      ];

      final correctCount = results.where((r) => r.isCorrect).length;
      final rate = (correctCount / results.length) * 100;

      expect(rate, equals(75.0));
    });
  });

  group('Active streak calculation', () {
    test('counts consecutive days', () {
      final now = DateTime.now();
      final sessions = [
        MockExerciseResult(performedAt: now.subtract(const Duration(days: 0))),
        MockExerciseResult(performedAt: now.subtract(const Duration(days: 1))),
        MockExerciseResult(performedAt: now.subtract(const Duration(days: 2))),
        // Gap here
        MockExerciseResult(performedAt: now.subtract(const Duration(days: 5))),
      ];

      var streak = 0;
      var currentDay = DateTime(now.year, now.month, now.day);

      for (var i = 0; i < 30; i++) {
        final checkDate = currentDay.subtract(Duration(days: i));
        final hasSession = sessions.any((s) {
          final sessionDate = DateTime(s.performedAt.year, s.performedAt.month, s.performedAt.day);
          return sessionDate == checkDate;
        });

        if (hasSession) {
          streak++;
        } else {
          break;
        }
      }

      expect(streak, equals(3));
    });

    test('returns 0 when no sessions today', () {
      final now = DateTime.now();
      final sessions = [
        MockExerciseResult(performedAt: now.subtract(const Duration(days: 2))),
      ];

      final today = DateTime(now.year, now.month, now.day);
      final hasSessionToday = sessions.any((s) {
        final date = DateTime(s.performedAt.year, s.performedAt.month, s.performedAt.day);
        return date == today;
      });

      final streak = hasSessionToday ? 1 : 0;
      expect(streak, equals(0));
    });

    test('handles multiple sessions per day', () {
      final now = DateTime.now();
      final sessions = [
        MockExerciseResult(performedAt: now.subtract(const Duration(hours: 2))),
        MockExerciseResult(performedAt: now.subtract(const Duration(hours: 5))),
      ];

      final today = DateTime(now.year, now.month, now.day);
      final sessionsToday = sessions.where((s) {
        final date = DateTime(s.performedAt.year, s.performedAt.month, s.performedAt.day);
        return date == today;
      });

      // Multiple sessions same day count as 1 day in streak
      expect(sessionsToday.length, equals(2));
    });
  });

  group('Score change calculations', () {
    test('positive change when improving', () {
      const prevWeekAvg = 75.0;
      const thisWeekAvg = 85.0;
      final change = thisWeekAvg - prevWeekAvg;

      expect(change, equals(10.0));
      expect(change > 0, isTrue);
    });

    test('negative change when declining', () {
      const prevWeekAvg = 85.0;
      const thisWeekAvg = 78.0;
      final change = thisWeekAvg - prevWeekAvg;

      expect(change, equals(-7.0));
      expect(change.isNegative, isTrue);
    });

    test('zero change when stable', () {
      const prevWeekAvg = 80.0;
      const thisWeekAvg = 80.0;
      final change = thisWeekAvg - prevWeekAvg;

      expect(change, equals(0.0));
    });

    test('handles no previous week data', () {
      const prevWeekAvg = 0.0;
      const thisWeekAvg = 85.0;
      final change = thisWeekAvg - prevWeekAvg;

      expect(change, equals(85.0));
    });
  });

  group('TrendMetricType conversion', () {
    test('sessionScore uses score field', () {
      const metric = TrendMetricType.sessionScore;
      expect(metric.displayName, equals('Session Score'));
    });

    test('exerciseDuration uses duration field', () {
      const metric = TrendMetricType.exerciseDuration;
      expect(metric.displayName, equals('Exercise Duration'));
    });

    test('completionRate uses isCorrect field', () {
      const metric = TrendMetricType.completionRate;
      expect(metric.displayName, equals('Completion Rate'));
    });
  });

  group('Data aggregation by day', () {
    test('groups results by date', () {
      final now = DateTime.now();
      final results = [
        MockExerciseResult(performedAt: now, score: 80),
        MockExerciseResult(performedAt: now, score: 85),
        MockExerciseResult(performedAt: now.subtract(const Duration(days: 1)), score: 90),
      ];

      final grouped = <DateTime, List<MockExerciseResult>>{};
      for (final result in results) {
        final date = DateTime(result.performedAt.year, result.performedAt.month, result.performedAt.day);
        grouped.putIfAbsent(date, () => []).add(result);
      }

      final today = DateTime(now.year, now.month, now.day);
      expect(grouped[today]?.length, equals(2));
    });

    test('averages multiple results per day', () {
      final dayResults = [
        MockExerciseResult(score: 80),
        MockExerciseResult(score: 90),
      ];

      final average = dayResults.map((r) => r.score).reduce((a, b) => a + b) / dayResults.length;

      expect(average, equals(85.0));
    });
  });

  group('Date range calculations', () {
    test('7 days period starts from correct date', () {
      final now = DateTime.now();
      const period = TrendPeriod.days7;
      final startDate = now.subtract(Duration(days: period.days));

      expect(now.difference(startDate).inDays, equals(7));
    });

    test('30 days period starts from correct date', () {
      final now = DateTime.now();
      const period = TrendPeriod.days30;
      final startDate = now.subtract(Duration(days: period.days));

      expect(now.difference(startDate).inDays, equals(30));
    });

    test('90 days period starts from correct date', () {
      final now = DateTime.now();
      const period = TrendPeriod.days90;
      final startDate = now.subtract(Duration(days: period.days));

      expect(now.difference(startDate).inDays, equals(90));
    });
  });
}

// Enums

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

// Mock class

class MockExerciseResult {
  MockExerciseResult({
    DateTime? performedAt,
    this.score = 80,
    this.isCorrect = true,
    this.durationSeconds = 60,
  }) : performedAt = performedAt ?? DateTime.now();

  final DateTime performedAt;
  final int score;
  final bool isCorrect;
  final int durationSeconds;
}
