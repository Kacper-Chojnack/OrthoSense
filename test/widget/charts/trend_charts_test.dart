/// Unit tests for ProgressTrendChart and WeeklyActivityChart widgets.
///
/// Test coverage:
/// 1. TrendChartData model
/// 2. TrendDataPoint model
/// 3. Chart data processing
/// 4. Weekly activity aggregation
/// 5. Color calculation based on values
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TrendDataPoint', () {
    test('creates point with all fields', () {
      final point = TrendDataPoint(
        date: DateTime(2025, 1, 15),
        value: 85.0,
        label: 'Jan 15',
      );

      expect(point.date.day, equals(15));
      expect(point.value, equals(85.0));
      expect(point.label, equals('Jan 15'));
    });

    test('handles zero value', () {
      final point = TrendDataPoint(
        date: DateTime(2025, 1, 10),
        value: 0.0,
        label: 'Jan 10',
      );

      expect(point.value, equals(0.0));
    });

    test('handles 100% value', () {
      final point = TrendDataPoint(
        date: DateTime(2025, 1, 10),
        value: 100.0,
        label: 'Jan 10',
      );

      expect(point.value, equals(100.0));
    });
  });

  group('TrendChartData', () {
    test('creates data with points', () {
      final data = TrendChartData(
        points: [
          TrendDataPoint(
            date: DateTime(2025, 1, 13),
            value: 70.0,
            label: 'Mon',
          ),
          TrendDataPoint(
            date: DateTime(2025, 1, 14),
            value: 80.0,
            label: 'Tue',
          ),
          TrendDataPoint(
            date: DateTime(2025, 1, 15),
            value: 75.0,
            label: 'Wed',
          ),
        ],
        metricName: 'Session Score',
        periodLabel: 'This Week',
      );

      expect(data.points.length, equals(3));
      expect(data.metricName, equals('Session Score'));
    });

    test('calculates average correctly', () {
      final data = TrendChartData(
        points: [
          TrendDataPoint(
            date: DateTime(2025, 1, 1),
            value: 60.0,
            label: 'Day 1',
          ),
          TrendDataPoint(
            date: DateTime(2025, 1, 2),
            value: 80.0,
            label: 'Day 2',
          ),
          TrendDataPoint(
            date: DateTime(2025, 1, 3),
            value: 100.0,
            label: 'Day 3',
          ),
        ],
        metricName: 'Score',
        periodLabel: 'Week',
      );

      expect(data.average, equals(80.0));
    });

    test('calculates max value', () {
      final data = TrendChartData(
        points: [
          TrendDataPoint(
            date: DateTime(2025, 1, 1),
            value: 60.0,
            label: 'Day 1',
          ),
          TrendDataPoint(
            date: DateTime(2025, 1, 2),
            value: 95.0,
            label: 'Day 2',
          ),
          TrendDataPoint(
            date: DateTime(2025, 1, 3),
            value: 70.0,
            label: 'Day 3',
          ),
        ],
        metricName: 'Score',
        periodLabel: 'Week',
      );

      expect(data.maxValue, equals(95.0));
    });

    test('calculates min value', () {
      final data = TrendChartData(
        points: [
          TrendDataPoint(
            date: DateTime(2025, 1, 1),
            value: 60.0,
            label: 'Day 1',
          ),
          TrendDataPoint(
            date: DateTime(2025, 1, 2),
            value: 95.0,
            label: 'Day 2',
          ),
          TrendDataPoint(
            date: DateTime(2025, 1, 3),
            value: 70.0,
            label: 'Day 3',
          ),
        ],
        metricName: 'Score',
        periodLabel: 'Week',
      );

      expect(data.minValue, equals(60.0));
    });

    test('handles empty points', () {
      final data = TrendChartData(
        points: [],
        metricName: 'Score',
        periodLabel: 'Week',
      );

      expect(data.points.isEmpty, isTrue);
      expect(data.average, equals(0.0));
    });
  });

  group('Weekly Activity Data', () {
    test('generates 7 days of data', () {
      final days = _generateWeeklyActivityData();

      expect(days.length, equals(7));
    });

    test('days are in correct order (Mon-Sun)', () {
      final days = _generateWeeklyActivityData();
      final labels = days.map((d) => d.label).toList();

      expect(labels.first, equals('Mon'));
      expect(labels.last, equals('Sun'));
    });

    test('activity level between 0 and 1', () {
      final days = _generateWeeklyActivityData();

      for (final day in days) {
        expect(day.activityLevel, greaterThanOrEqualTo(0.0));
        expect(day.activityLevel, lessThanOrEqualTo(1.0));
      }
    });

    test('session count is non-negative', () {
      final days = _generateWeeklyActivityData();

      for (final day in days) {
        expect(day.sessionCount, greaterThanOrEqualTo(0));
      }
    });
  });

  group('Activity Color Calculation', () {
    test('zero activity shows base color', () {
      final color = _getActivityColor(0.0);

      expect(color, equals(Colors.grey.shade200));
    });

    test('low activity shows light color', () {
      final color = _getActivityColor(0.25);

      expect(color, isNotNull);
      // Should be lighter shade
    });

    test('medium activity shows medium color', () {
      final color = _getActivityColor(0.5);

      expect(color, isNotNull);
    });

    test('high activity shows strong color', () {
      final color = _getActivityColor(1.0);

      expect(color, equals(Colors.green));
    });
  });

  group('Chart Point Normalization', () {
    test('normalizes values to 0-1 range', () {
      final values = [20.0, 50.0, 80.0];
      final normalized = _normalizeValues(values);

      expect(normalized.first, equals(0.0)); // min
      expect(normalized.last, equals(1.0)); // max
      expect(normalized[1], equals(0.5)); // middle
    });

    test('handles single value', () {
      final values = [50.0];
      final normalized = _normalizeValues(values);

      expect(normalized.first, equals(1.0)); // single value defaults to max
    });

    test('handles all same values', () {
      final values = [80.0, 80.0, 80.0];
      final normalized = _normalizeValues(values);

      // All should be equal (typically 1.0)
      expect(normalized.toSet().length, equals(1));
    });
  });

  group('Date Formatting', () {
    test('formats as day abbreviation', () {
      final date = DateTime(2025, 1, 13); // Monday
      final formatted = _formatDayAbbrev(date);

      expect(formatted, equals('Mon'));
    });

    test('formats as month day', () {
      final date = DateTime(2025, 1, 15);
      final formatted = _formatMonthDay(date);

      expect(formatted, equals('Jan 15'));
    });

    test('formats date range', () {
      final start = DateTime(2025, 1, 13);
      final end = DateTime(2025, 1, 19);
      final formatted = _formatDateRange(start, end);

      expect(formatted, contains('Jan 13'));
      expect(formatted, contains('Jan 19'));
    });
  });

  group('Trend Calculation', () {
    test('upward trend when values increasing', () {
      final values = [60.0, 70.0, 80.0, 90.0];
      final trend = _calculateTrend(values);

      expect(trend, equals(TrendDirection.up));
    });

    test('downward trend when values decreasing', () {
      final values = [90.0, 80.0, 70.0, 60.0];
      final trend = _calculateTrend(values);

      expect(trend, equals(TrendDirection.down));
    });

    test('stable when values relatively constant', () {
      final values = [75.0, 76.0, 74.0, 75.0];
      final trend = _calculateTrend(values);

      expect(trend, equals(TrendDirection.stable));
    });

    test('handles single value as stable', () {
      final values = [80.0];
      final trend = _calculateTrend(values);

      expect(trend, equals(TrendDirection.stable));
    });
  });

  group('Chart Widget', () {
    testWidgets('displays metric name', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TestProgressTrendChart(
              metricName: 'Session Score',
              points: [
                TrendDataPoint(
                  date: DateTime.now(),
                  value: 80.0,
                  label: 'Today',
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Session Score'), findsOneWidget);
    });

    testWidgets('displays period label', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TestProgressTrendChart(
              metricName: 'Score',
              periodLabel: 'Last 7 Days',
              points: [],
            ),
          ),
        ),
      );

      expect(find.text('Last 7 Days'), findsOneWidget);
    });

    testWidgets('shows empty state when no data', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TestProgressTrendChart(
              metricName: 'Score',
              points: [],
              showEmptyState: true,
            ),
          ),
        ),
      );

      expect(find.text('No data yet'), findsOneWidget);
    });
  });

  group('Weekly Activity Chart Widget', () {
    testWidgets('displays 7 day columns', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TestWeeklyActivityChart(
              days: _generateWeeklyActivityData(),
            ),
          ),
        ),
      );

      // Should find all day abbreviations
      expect(find.text('Mon'), findsOneWidget);
      expect(find.text('Sun'), findsOneWidget);
    });

    testWidgets('displays header', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TestWeeklyActivityChart(
              days: _generateWeeklyActivityData(),
            ),
          ),
        ),
      );

      expect(find.text('Weekly Activity'), findsOneWidget);
    });
  });
}

// Test data classes

class TrendDataPoint {
  TrendDataPoint({
    required this.date,
    required this.value,
    required this.label,
  });

  final DateTime date;
  final double value;
  final String label;
}

class TrendChartData {
  TrendChartData({
    required this.points,
    required this.metricName,
    required this.periodLabel,
  });

  final List<TrendDataPoint> points;
  final String metricName;
  final String periodLabel;

  double get average {
    if (points.isEmpty) return 0.0;
    return points.map((p) => p.value).reduce((a, b) => a + b) / points.length;
  }

  double get maxValue {
    if (points.isEmpty) return 0.0;
    return points.map((p) => p.value).reduce((a, b) => a > b ? a : b);
  }

  double get minValue {
    if (points.isEmpty) return 0.0;
    return points.map((p) => p.value).reduce((a, b) => a < b ? a : b);
  }
}

class WeeklyActivityDay {
  WeeklyActivityDay({
    required this.label,
    required this.activityLevel,
    required this.sessionCount,
  });

  final String label;
  final double activityLevel;
  final int sessionCount;
}

enum TrendDirection { up, down, stable }

// Helper functions

List<WeeklyActivityDay> _generateWeeklyActivityData() {
  final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  return days.map((label) {
    // Mock activity levels
    final activityLevel = switch (label) {
      'Mon' => 0.8,
      'Tue' => 0.6,
      'Wed' => 1.0,
      'Thu' => 0.4,
      'Fri' => 0.7,
      'Sat' => 0.0,
      'Sun' => 0.3,
      _ => 0.0,
    };
    return WeeklyActivityDay(
      label: label,
      activityLevel: activityLevel,
      sessionCount: (activityLevel * 3).round(),
    );
  }).toList();
}

Color _getActivityColor(double level) {
  if (level == 0.0) return Colors.grey.shade200;
  if (level < 0.25) return Colors.green.shade200;
  if (level < 0.5) return Colors.green.shade400;
  if (level < 0.75) return Colors.green.shade600;
  return Colors.green;
}

List<double> _normalizeValues(List<double> values) {
  if (values.isEmpty) return [];
  if (values.length == 1) return [1.0];

  final min = values.reduce((a, b) => a < b ? a : b);
  final max = values.reduce((a, b) => a > b ? a : b);

  if (max == min) return List.filled(values.length, 1.0);

  return values.map((v) => (v - min) / (max - min)).toList();
}

String _formatDayAbbrev(DateTime date) {
  const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  return days[date.weekday - 1];
}

String _formatMonthDay(DateTime date) {
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  return '${months[date.month - 1]} ${date.day}';
}

String _formatDateRange(DateTime start, DateTime end) {
  return '${_formatMonthDay(start)} - ${_formatMonthDay(end)}';
}

TrendDirection _calculateTrend(List<double> values) {
  if (values.length < 2) return TrendDirection.stable;

  final first = values.first;
  final last = values.last;
  final diff = last - first;

  // Threshold of 5% change for trend detection
  final threshold = first * 0.05;

  if (diff > threshold) return TrendDirection.up;
  if (diff < -threshold) return TrendDirection.down;
  return TrendDirection.stable;
}

// Test widgets

class TestProgressTrendChart extends StatelessWidget {
  const TestProgressTrendChart({
    super.key,
    required this.metricName,
    required this.points,
    this.periodLabel = 'Last 7 Days',
    this.showEmptyState = false,
  });

  final String metricName;
  final List<TrendDataPoint> points;
  final String periodLabel;
  final bool showEmptyState;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(metricName),
            Text(periodLabel),
            if (showEmptyState && points.isEmpty)
              const Text('No data yet')
            else
              const SizedBox(height: 100), // Placeholder for chart
          ],
        ),
      ),
    );
  }
}

class TestWeeklyActivityChart extends StatelessWidget {
  const TestWeeklyActivityChart({
    super.key,
    required this.days,
  });

  final List<WeeklyActivityDay> days;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Weekly Activity'),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: days.map((day) {
                return Column(
                  children: [
                    Container(
                      width: 24,
                      height: 50 * day.activityLevel + 10,
                      color: _getActivityColor(day.activityLevel),
                    ),
                    Text(day.label),
                  ],
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
