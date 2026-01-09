/// Unit tests for Dashboard Trend Provider.
///
/// Test coverage:
/// 1. SelectedTrendPeriod notifier state management
/// 2. TrendPeriod enum properties
/// 3. TrendMetricType enum properties
/// 4. DashboardStats model
/// 5. TrendDataPoint model
/// 6. TrendChartData model
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:orthosense/core/database/app_database.dart';
import 'package:orthosense/core/providers/database_provider.dart';
import 'package:orthosense/features/dashboard/domain/models/trend_data_model.dart';
import 'package:orthosense/features/dashboard/presentation/providers/trend_provider.dart';

// Mock classes
class MockAppDatabase extends Mock implements AppDatabase {}

void main() {
  late MockAppDatabase mockDatabase;
  late ProviderContainer container;

  setUp(() {
    mockDatabase = MockAppDatabase();

    container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(mockDatabase),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  group('SelectedTrendPeriod', () {
    test('initial state is 7 days', () {
      final period = container.read(selectedTrendPeriodProvider);
      expect(period, equals(TrendPeriod.days7));
    });

    test('setPeriod updates state to 30 days', () {
      container
          .read(selectedTrendPeriodProvider.notifier)
          .setPeriod(TrendPeriod.days30);

      final period = container.read(selectedTrendPeriodProvider);
      expect(period, equals(TrendPeriod.days30));
    });

    test('setPeriod updates state to 90 days', () {
      container
          .read(selectedTrendPeriodProvider.notifier)
          .setPeriod(TrendPeriod.days90);

      final period = container.read(selectedTrendPeriodProvider);
      expect(period, equals(TrendPeriod.days90));
    });

    test('state changes notify listeners', () {
      var callCount = 0;
      container.listen(
        selectedTrendPeriodProvider,
        (_, __) => callCount++,
        fireImmediately: false,
      );

      container
          .read(selectedTrendPeriodProvider.notifier)
          .setPeriod(TrendPeriod.days30);
      container
          .read(selectedTrendPeriodProvider.notifier)
          .setPeriod(TrendPeriod.days90);

      expect(callCount, equals(2));
    });
  });

  group('TrendPeriod enum', () {
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

    test('all periods are defined', () {
      expect(TrendPeriod.values.length, equals(3));
    });
  });

  group('TrendMetricType enum', () {
    test('rangeOfMotion has correct properties', () {
      expect(
        TrendMetricType.rangeOfMotion.displayName,
        equals('Range of Motion'),
      );
      expect(TrendMetricType.rangeOfMotion.unit, equals('°'));
    });

    test('sessionScore has correct properties', () {
      expect(TrendMetricType.sessionScore.displayName, equals('Session Score'));
      expect(TrendMetricType.sessionScore.unit, equals('%'));
    });

    test('exerciseDuration has correct properties', () {
      expect(
        TrendMetricType.exerciseDuration.displayName,
        equals('Exercise Duration'),
      );
      expect(TrendMetricType.exerciseDuration.unit, equals('min'));
    });

    test('completionRate has correct properties', () {
      expect(
        TrendMetricType.completionRate.displayName,
        equals('Completion Rate'),
      );
      expect(TrendMetricType.completionRate.unit, equals('%'));
    });

    test('painLevel has correct properties', () {
      expect(TrendMetricType.painLevel.displayName, equals('Pain Level'));
      expect(TrendMetricType.painLevel.unit, equals('/10'));
    });

    test('all metric types are defined', () {
      expect(TrendMetricType.values.length, equals(5));
    });
  });

  group('DashboardStats model', () {
    test('creates with all default values', () {
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
        scoreChange: 2.3,
        activeStreakDays: 7,
        totalTimeThisMonth: Duration(hours: 10),
        completionRate: 92.0,
      );

      expect(stats.totalSessions, equals(50));
      expect(stats.sessionsThisWeek, equals(5));
      expect(stats.averageScore, equals(85.5));
      expect(stats.scoreChange, equals(2.3));
      expect(stats.activeStreakDays, equals(7));
      expect(stats.totalTimeThisMonth, equals(const Duration(hours: 10)));
      expect(stats.completionRate, equals(92.0));
    });

    test('handles negative score change', () {
      const stats = DashboardStats(
        scoreChange: -5.5,
      );

      expect(stats.scoreChange, equals(-5.5));
    });

    test('copyWith creates new instance with updated values', () {
      const original = DashboardStats(
        totalSessions: 10,
        averageScore: 70.0,
      );

      final updated = original.copyWith(
        totalSessions: 20,
        activeStreakDays: 5,
      );

      expect(updated.totalSessions, equals(20));
      expect(updated.averageScore, equals(70.0)); // unchanged
      expect(updated.activeStreakDays, equals(5));
    });
  });

  group('TrendDataPoint model', () {
    test('creates with required fields', () {
      final point = TrendDataPoint(
        date: DateTime(2026, 1, 9),
        value: 87.5,
        label: 'Jan 9',
      );

      expect(point.date.year, equals(2026));
      expect(point.date.month, equals(1));
      expect(point.date.day, equals(9));
      expect(point.value, equals(87.5));
      expect(point.label, equals('Jan 9'));
      expect(point.isHighlighted, isFalse);
    });

    test('creates with isHighlighted', () {
      final point = TrendDataPoint(
        date: DateTime.now(),
        value: 90.0,
        label: 'Today',
        isHighlighted: true,
      );

      expect(point.isHighlighted, isTrue);
    });

    test('handles zero value', () {
      final point = TrendDataPoint(
        date: DateTime.now(),
        value: 0.0,
        label: 'Zero',
      );

      expect(point.value, equals(0.0));
    });

    test('handles negative value', () {
      final point = TrendDataPoint(
        date: DateTime.now(),
        value: -5.0,
        label: 'Negative',
      );

      expect(point.value, equals(-5.0));
    });
  });

  group('TrendChartData model', () {
    test('creates with data points', () {
      final dataPoints = [
        TrendDataPoint(date: DateTime(2026, 1, 1), value: 80.0, label: 'Jan 1'),
        TrendDataPoint(date: DateTime(2026, 1, 2), value: 85.0, label: 'Jan 2'),
        TrendDataPoint(date: DateTime(2026, 1, 3), value: 82.0, label: 'Jan 3'),
      ];

      final chartData = TrendChartData(
        dataPoints: dataPoints,
        metricType: TrendMetricType.sessionScore,
        period: TrendPeriod.days7,
        averageValue: 82.33,
      );

      expect(chartData.dataPoints.length, equals(3));
      expect(chartData.metricType, equals(TrendMetricType.sessionScore));
      expect(chartData.period, equals(TrendPeriod.days7));
      expect(chartData.averageValue, equals(82.33));
    });

    test('has default min and max values', () {
      final chartData = TrendChartData(
        dataPoints: [],
        metricType: TrendMetricType.sessionScore,
        period: TrendPeriod.days7,
      );

      expect(chartData.minValue, equals(0));
      expect(chartData.maxValue, equals(100));
    });

    test('handles empty data points', () {
      final chartData = TrendChartData(
        dataPoints: [],
        metricType: TrendMetricType.sessionScore,
        period: TrendPeriod.days7,
      );

      expect(chartData.dataPoints, isEmpty);
      expect(chartData.averageValue, isNull);
      expect(chartData.changePercent, isNull);
    });

    test('creates with change percent', () {
      final chartData = TrendChartData(
        dataPoints: [],
        metricType: TrendMetricType.sessionScore,
        period: TrendPeriod.days30,
        changePercent: 15.5,
      );

      expect(chartData.changePercent, equals(15.5));
    });

    test('creates with custom min/max', () {
      final chartData = TrendChartData(
        dataPoints: [],
        metricType: TrendMetricType.rangeOfMotion,
        period: TrendPeriod.days7,
        minValue: 0,
        maxValue: 180,
      );

      expect(chartData.minValue, equals(0));
      expect(chartData.maxValue, equals(180));
    });
  });
}
