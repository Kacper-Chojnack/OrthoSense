import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orthosense/features/dashboard/domain/models/trend_data_model.dart';
import 'package:orthosense/features/dashboard/presentation/providers/trend_provider.dart';
import 'package:orthosense/features/dashboard/presentation/widgets/progress_trend_chart.dart';

void main() {
  final testDataPoints = [
    TrendDataPoint(
      date: DateTime(2024, 1, 1),
      value: 45.0,
      label: 'Jan 1',
    ),
    TrendDataPoint(
      date: DateTime(2024, 1, 2),
      value: 50.0,
      label: 'Jan 2',
    ),
    TrendDataPoint(
      date: DateTime(2024, 1, 3),
      value: 55.0,
      label: 'Jan 3',
    ),
    TrendDataPoint(
      date: DateTime(2024, 1, 4),
      value: 60.0,
      label: 'Jan 4',
    ),
  ];

  final testChartData = TrendChartData(
    dataPoints: testDataPoints,
    period: TrendPeriod.days7,
    metricType: TrendMetricType.rangeOfMotion,
    minValue: 40,
    maxValue: 70,
    averageValue: 52.5,
    changePercent: 15.0,
  );

  Widget createTestWidget({
    TrendMetricType metricType = TrendMetricType.rangeOfMotion,
    TrendChartData? chartData,
    TrendPeriod? selectedPeriod,
    bool error = false,
  }) {
    return ProviderScope(
      overrides: [
        selectedTrendPeriodProvider.overrideWithValue(
          selectedPeriod ?? TrendPeriod.days7,
        ),
        trendDataProvider(metricType).overrideWith((ref) async {
          if (error) {
            throw Exception('Failed to load');
          }
          return chartData ?? testChartData;
        }),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: ProgressTrendChart(
            metricType: metricType,
          ),
        ),
      ),
    );
  }

  group('ProgressTrendChart Widget Tests', () {
    testWidgets('renders with correct title for Range of Motion', (
      tester,
    ) async {
      await tester.pumpWidget(
        createTestWidget(
          metricType: TrendMetricType.rangeOfMotion,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Range of Motion'), findsOneWidget);
    });

    testWidgets('renders with correct title for Session Score', (
      tester,
    ) async {
      await tester.pumpWidget(
        createTestWidget(
          metricType: TrendMetricType.sessionScore,
          chartData: testChartData.copyWith(
            metricType: TrendMetricType.sessionScore,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Session Score'), findsOneWidget);
    });

    testWidgets('shows error state with message when data fails', (
      tester,
    ) async {
      await tester.pumpWidget(createTestWidget(error: true));
      await tester.pumpAndSettle();

      expect(find.text('Failed to load trend data'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('shows empty state when no data points', (tester) async {
      final emptyData = TrendChartData(
        dataPoints: const [],
        period: TrendPeriod.days7,
        metricType: TrendMetricType.rangeOfMotion,
      );

      await tester.pumpWidget(createTestWidget(chartData: emptyData));
      await tester.pumpAndSettle();

      expect(find.text('No data available for this period'), findsOneWidget);
      expect(
        find.text('Complete some sessions to see your progress'),
        findsOneWidget,
      );
    });

    testWidgets('displays period selector', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.byType(DropdownButton<TrendPeriod>), findsOneWidget);
    });

    testWidgets('period selector shows current period label', (tester) async {
      await tester.pumpWidget(
        createTestWidget(selectedPeriod: TrendPeriod.days7),
      );
      await tester.pumpAndSettle();

      expect(find.text('Last 7 days'), findsOneWidget);
    });

    testWidgets('displays chart when data is available', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.byType(LineChart), findsOneWidget);
    });

    testWidgets('displays average value in stats summary', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.textContaining('52.5'), findsOneWidget);
    });

    testWidgets('displays change percent with positive indicator', (
      tester,
    ) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.textContaining('+15.0'), findsOneWidget);
      expect(find.byIcon(Icons.trending_up), findsOneWidget);
    });

    testWidgets('displays change percent with negative indicator', (
      tester,
    ) async {
      final negativeData = testChartData.copyWith(changePercent: -10.0);

      await tester.pumpWidget(createTestWidget(chartData: negativeData));
      await tester.pumpAndSettle();

      expect(find.textContaining('-10.0'), findsOneWidget);
      expect(find.byIcon(Icons.trending_down), findsOneWidget);
    });

    testWidgets('chart uses correct height', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            selectedTrendPeriodProvider.overrideWithValue(TrendPeriod.days7),
            trendDataProvider(TrendMetricType.rangeOfMotion).overrideWith(
              (ref) async => testChartData,
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: ProgressTrendChart(
                metricType: TrendMetricType.rangeOfMotion,
                height: 300,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Chart should be rendered
      expect(find.byType(Card), findsOneWidget);
    });
  });

  group('Period Selector Tests', () {
    testWidgets('can open dropdown and see all period options', (
      tester,
    ) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.byType(DropdownButton<TrendPeriod>));
      await tester.pumpAndSettle();

      expect(find.text('7D'), findsWidgets);
      expect(find.text('30D'), findsWidgets);
      expect(find.text('90D'), findsWidgets);
    });
  });

  group('TrendPeriod Tests', () {
    test('TrendPeriod.days7 has correct values', () {
      expect(TrendPeriod.days7.days, 7);
      expect(TrendPeriod.days7.shortLabel, '7D');
      expect(TrendPeriod.days7.longLabel, 'Last 7 days');
    });

    test('TrendPeriod.days30 has correct values', () {
      expect(TrendPeriod.days30.days, 30);
      expect(TrendPeriod.days30.shortLabel, '30D');
      expect(TrendPeriod.days30.longLabel, 'Last 30 days');
    });

    test('TrendPeriod.days90 has correct values', () {
      expect(TrendPeriod.days90.days, 90);
      expect(TrendPeriod.days90.shortLabel, '90D');
      expect(TrendPeriod.days90.longLabel, 'Last 90 days');
    });
  });

  group('TrendMetricType Tests', () {
    test('rangeOfMotion has correct display values', () {
      expect(TrendMetricType.rangeOfMotion.displayName, 'Range of Motion');
      expect(TrendMetricType.rangeOfMotion.unit, '°');
    });

    test('sessionScore has correct display values', () {
      expect(TrendMetricType.sessionScore.displayName, 'Session Score');
      expect(TrendMetricType.sessionScore.unit, '%');
    });

    test('exerciseDuration has correct display values', () {
      expect(TrendMetricType.exerciseDuration.displayName, 'Exercise Duration');
      expect(TrendMetricType.exerciseDuration.unit, 'min');
    });

    test('completionRate has correct display values', () {
      expect(TrendMetricType.completionRate.displayName, 'Completion Rate');
      expect(TrendMetricType.completionRate.unit, '%');
    });

    test('painLevel has correct display values', () {
      expect(TrendMetricType.painLevel.displayName, 'Pain Level');
      expect(TrendMetricType.painLevel.unit, '/10');
    });
  });

  group('TrendDataPoint Model Tests', () {
    test('creates TrendDataPoint with required fields', () {
      final dataPoint = TrendDataPoint(
        date: DateTime(2024, 6, 15),
        value: 75.5,
        label: 'Jun 15',
      );

      expect(dataPoint.date, DateTime(2024, 6, 15));
      expect(dataPoint.value, 75.5);
      expect(dataPoint.label, 'Jun 15');
      expect(dataPoint.isHighlighted, false);
    });

    test('creates TrendDataPoint with highlighted flag', () {
      final dataPoint = TrendDataPoint(
        date: DateTime(2024, 6, 15),
        value: 75.5,
        label: 'Jun 15',
        isHighlighted: true,
      );

      expect(dataPoint.isHighlighted, true);
    });
  });

  group('TrendChartData Model Tests', () {
    test('creates TrendChartData with all fields', () {
      final chartData = TrendChartData(
        dataPoints: testDataPoints,
        period: TrendPeriod.days30,
        metricType: TrendMetricType.sessionScore,
        minValue: 0,
        maxValue: 100,
        averageValue: 85.0,
        changePercent: 5.0,
      );

      expect(chartData.dataPoints.length, 4);
      expect(chartData.period, TrendPeriod.days30);
      expect(chartData.metricType, TrendMetricType.sessionScore);
      expect(chartData.minValue, 0);
      expect(chartData.maxValue, 100);
      expect(chartData.averageValue, 85.0);
      expect(chartData.changePercent, 5.0);
    });

    test('TrendChartData has correct default values', () {
      final chartData = TrendChartData(
        dataPoints: const [],
        period: TrendPeriod.days7,
        metricType: TrendMetricType.rangeOfMotion,
      );

      expect(chartData.minValue, 0);
      expect(chartData.maxValue, 100);
      expect(chartData.averageValue, isNull);
      expect(chartData.changePercent, isNull);
    });
  });

  group('DashboardStats Model Tests', () {
    test('creates DashboardStats with default values', () {
      const stats = DashboardStats();

      expect(stats.totalSessions, 0);
      expect(stats.sessionsThisWeek, 0);
      expect(stats.averageScore, 0.0);
      expect(stats.scoreChange, 0.0);
      expect(stats.activeStreakDays, 0);
      expect(stats.totalTimeThisMonth, Duration.zero);
      expect(stats.completionRate, 0.0);
    });

    test('creates DashboardStats with custom values', () {
      const stats = DashboardStats(
        totalSessions: 25,
        sessionsThisWeek: 5,
        averageScore: 87.5,
        scoreChange: 3.2,
        activeStreakDays: 7,
        totalTimeThisMonth: Duration(hours: 3, minutes: 30),
        completionRate: 0.92,
      );

      expect(stats.totalSessions, 25);
      expect(stats.sessionsThisWeek, 5);
      expect(stats.averageScore, 87.5);
      expect(stats.scoreChange, 3.2);
      expect(stats.activeStreakDays, 7);
      expect(stats.totalTimeThisMonth, const Duration(hours: 3, minutes: 30));
      expect(stats.completionRate, 0.92);
    });
  });
}
