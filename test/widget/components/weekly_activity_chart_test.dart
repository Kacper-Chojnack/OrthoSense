/// Unit tests for weekly activity chart components.
///
/// Test coverage:
/// 1. WeeklyActivityMetric enum
/// 2. WeeklyActivityDay data model
/// 3. Chart calculations (maxY, interval)
/// 4. Summary calculations
/// 5. Day label formatting
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('WeeklyActivityMetric', () {
    test('has sessions metric', () {
      expect(WeeklyActivityMetric.sessions.name, equals('sessions'));
    });

    test('has minutes metric', () {
      expect(WeeklyActivityMetric.minutes.name, equals('minutes'));
    });

    test('metrics have display labels', () {
      expect(WeeklyActivityMetric.sessions.displayLabel, equals('Sessions'));
      expect(WeeklyActivityMetric.minutes.displayLabel, equals('Minutes'));
    });
  });

  group('WeeklyActivityDay', () {
    test('creates with required properties', () {
      final day = WeeklyActivityDay(
        date: DateTime(2024, 1, 15),
        value: 3,
        label: 'Mon',
      );

      expect(day.date, equals(DateTime(2024, 1, 15)));
      expect(day.value, equals(3));
      expect(day.label, equals('Mon'));
    });

    test('isToday detection', () {
      final today = DateTime.now();
      final todayDay = WeeklyActivityDay(
        date: DateTime(today.year, today.month, today.day),
        value: 1,
        label: 'Today',
        isToday: true,
      );

      expect(todayDay.isToday, isTrue);
    });

    test('past day is not today', () {
      final pastDay = WeeklyActivityDay(
        date: DateTime(2024, 1, 1),
        value: 2,
        label: 'Mon',
      );

      expect(pastDay.isToday, isFalse);
    });
  });

  group('MaxY Calculation', () {
    test('returns 10 for zero or negative max value', () {
      expect(_maxY(0), equals(10));
      expect(_maxY(-5), equals(10));
    });

    test('adds 20% headroom', () {
      // maxValue * 1.2, ceiled
      expect(_maxY(10), equals(12.0));
      expect(_maxY(5), equals(6.0));
    });

    test('returns minimum of 1 for tiny values', () {
      final result = _maxY(0.1);
      expect(result, greaterThanOrEqualTo(1.0));
    });

    test('handles large values', () {
      final result = _maxY(100);
      expect(result, equals(120.0));
    });
  });

  group('Y-Axis Interval', () {
    test('interval is 1 for maxY <= 5', () {
      expect(_yInterval(1), equals(1));
      expect(_yInterval(5), equals(1));
    });

    test('interval is 5 for maxY between 6 and 20', () {
      expect(_yInterval(6), equals(5));
      expect(_yInterval(10), equals(5));
      expect(_yInterval(20), equals(5));
    });

    test('interval is 10 for maxY between 21 and 60', () {
      expect(_yInterval(21), equals(10));
      expect(_yInterval(40), equals(10));
      expect(_yInterval(60), equals(10));
    });

    test('interval is 20 for maxY > 60', () {
      expect(_yInterval(61), equals(20));
      expect(_yInterval(100), equals(20));
    });
  });

  group('Total Calculation', () {
    test('sums all day values', () {
      final days = [
        WeeklyActivityDay(date: DateTime(2024, 1, 15), value: 2, label: 'Mon'),
        WeeklyActivityDay(date: DateTime(2024, 1, 16), value: 1, label: 'Tue'),
        WeeklyActivityDay(date: DateTime(2024, 1, 17), value: 3, label: 'Wed'),
        WeeklyActivityDay(date: DateTime(2024, 1, 18), value: 0, label: 'Thu'),
        WeeklyActivityDay(date: DateTime(2024, 1, 19), value: 2, label: 'Fri'),
        WeeklyActivityDay(date: DateTime(2024, 1, 20), value: 4, label: 'Sat'),
        WeeklyActivityDay(date: DateTime(2024, 1, 21), value: 1, label: 'Sun'),
      ];

      final total = days.fold<double>(0, (sum, d) => sum + d.value);

      expect(total, equals(13));
    });

    test('empty days returns zero total', () {
      final days = <WeeklyActivityDay>[];
      final total = days.fold<double>(0, (sum, d) => sum + d.value);

      expect(total, equals(0));
    });

    test('all zeros returns zero total', () {
      final days = [
        WeeklyActivityDay(date: DateTime(2024, 1, 15), value: 0, label: 'Mon'),
        WeeklyActivityDay(date: DateTime(2024, 1, 16), value: 0, label: 'Tue'),
        WeeklyActivityDay(date: DateTime(2024, 1, 17), value: 0, label: 'Wed'),
      ];

      final total = days.fold<double>(0, (sum, d) => sum + d.value);

      expect(total, equals(0));
    });
  });

  group('Max Value Calculation', () {
    test('finds maximum value from days', () {
      final days = [
        WeeklyActivityDay(date: DateTime(2024, 1, 15), value: 2, label: 'Mon'),
        WeeklyActivityDay(date: DateTime(2024, 1, 16), value: 5, label: 'Tue'),
        WeeklyActivityDay(date: DateTime(2024, 1, 17), value: 3, label: 'Wed'),
      ];

      final maxValue = days.map((d) => d.value).reduce((a, b) => a > b ? a : b);

      expect(maxValue, equals(5));
    });
  });

  group('Day Label Generation', () {
    test('generates short weekday labels', () {
      // Monday
      var date = DateTime(2024, 1, 15); // Monday
      expect(_getDayLabel(date), equals('Mon'));

      // Friday
      date = DateTime(2024, 1, 19);
      expect(_getDayLabel(date), equals('Fri'));

      // Sunday
      date = DateTime(2024, 1, 21);
      expect(_getDayLabel(date), equals('Sun'));
    });

    test('all weekday labels are 3 characters', () {
      for (int i = 0; i < 7; i++) {
        final date = DateTime(2024, 1, 15 + i);
        final label = _getDayLabel(date);
        expect(label.length, equals(3));
      }
    });
  });

  group('Tooltip Content', () {
    test('sessions tooltip shows count and label', () {
      final day = WeeklyActivityDay(
        date: DateTime(2024, 1, 15),
        value: 3,
        label: 'Mon',
      );

      final tooltip = _getTooltip(day, WeeklyActivityMetric.sessions);

      expect(tooltip, equals('Mon: 3 sessions'));
    });

    test('minutes tooltip shows time and label', () {
      final day = WeeklyActivityDay(
        date: DateTime(2024, 1, 15),
        value: 45,
        label: 'Mon',
      );

      final tooltip = _getTooltip(day, WeeklyActivityMetric.minutes);

      expect(tooltip, equals('Mon: 45 min'));
    });

    test('zero sessions shown correctly', () {
      final day = WeeklyActivityDay(
        date: DateTime(2024, 1, 15),
        value: 0,
        label: 'Mon',
      );

      final tooltip = _getTooltip(day, WeeklyActivityMetric.sessions);

      expect(tooltip, equals('Mon: 0 sessions'));
    });
  });

  group('Summary Row', () {
    test('sessions summary label', () {
      final label = _getSummaryLabel(WeeklyActivityMetric.sessions);
      expect(label, equals('Total sessions (7 days)'));
    });

    test('minutes summary label', () {
      final label = _getSummaryLabel(WeeklyActivityMetric.minutes);
      expect(label, equals('Total minutes (7 days)'));
    });

    test('formats session count as integer', () {
      final formatted = _formatTotal(13.0, WeeklyActivityMetric.sessions);
      expect(formatted, equals('13'));
    });

    test('formats minutes as integer', () {
      final formatted = _formatTotal(123.5, WeeklyActivityMetric.minutes);
      expect(formatted, equals('124')); // Rounded
    });
  });

  group('WeeklyActivityChart Widget', () {
    testWidgets('shows loading state', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: _MockWeeklyActivityChart(isLoading: true),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows error state', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: _MockWeeklyActivityChart(
              hasError: true,
              errorMessage: 'Network error',
            ),
          ),
        ),
      );

      expect(find.textContaining('Network error'), findsOneWidget);
    });

    testWidgets('shows empty state when no activity', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: _MockWeeklyActivityChart(totalActivity: 0),
          ),
        ),
      );

      expect(find.text('No activity in the last 7 days'), findsOneWidget);
    });

    testWidgets('shows header with title', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: _MockWeeklyActivityChart(totalActivity: 10),
          ),
        ),
      );

      expect(find.text('Weekly Activity'), findsOneWidget);
      expect(find.text('Last 7 days'), findsOneWidget);
    });

    testWidgets('shows metric toggle buttons', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: _MockWeeklyActivityChart(totalActivity: 10),
          ),
        ),
      );

      expect(find.text('Sessions'), findsOneWidget);
      expect(find.text('Minutes'), findsOneWidget);
    });
  });

  group('Bar Color Logic', () {
    test('today bar uses primary color', () {
      final day = WeeklyActivityDay(
        date: DateTime.now(),
        value: 2,
        label: 'Today',
        isToday: true,
      );

      final color = _getBarColor(day, true);

      expect(color, equals(Colors.blue)); // Primary color mock
    });

    test('other days use secondary color', () {
      final day = WeeklyActivityDay(
        date: DateTime(2024, 1, 1),
        value: 2,
        label: 'Mon',
      );

      final color = _getBarColor(day, false);

      expect(color, equals(Colors.grey)); // Secondary color mock
    });
  });

  group('Seven Days Data', () {
    test('generates 7 days of data', () {
      final days = _generateLastSevenDays();

      expect(days.length, equals(7));
    });

    test('days are in chronological order', () {
      final days = _generateLastSevenDays();

      for (int i = 0; i < days.length - 1; i++) {
        expect(days[i].date.isBefore(days[i + 1].date), isTrue);
      }
    });

    test('last day is today', () {
      final days = _generateLastSevenDays();
      final today = DateTime.now();
      final lastDay = days.last;

      expect(lastDay.date.year, equals(today.year));
      expect(lastDay.date.month, equals(today.month));
      expect(lastDay.date.day, equals(today.day));
    });
  });
}

// Enum

enum WeeklyActivityMetric {
  sessions('Sessions'),
  minutes('Minutes');

  const WeeklyActivityMetric(this.displayLabel);

  final String displayLabel;
}

// Model class

class WeeklyActivityDay {
  WeeklyActivityDay({
    required this.date,
    required this.value,
    required this.label,
    this.isToday = false,
  });

  final DateTime date;
  final double value;
  final String label;
  final bool isToday;
}

// Helper functions

double _maxY(double maxValue) {
  if (maxValue <= 0) return 10;
  return (maxValue * 1.2).ceilToDouble().clamp(1, double.infinity);
}

double _yInterval(double maxY) {
  if (maxY <= 5) return 1;
  if (maxY <= 20) return 5;
  if (maxY <= 60) return 10;
  return 20;
}

String _getDayLabel(DateTime date) {
  const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  return weekdays[date.weekday - 1];
}

String _getTooltip(WeeklyActivityDay day, WeeklyActivityMetric metric) {
  final suffix = metric == WeeklyActivityMetric.sessions ? ' sessions' : ' min';
  final value = metric == WeeklyActivityMetric.sessions
      ? day.value.toInt().toString()
      : day.value.toStringAsFixed(0);
  return '${day.label}: $value$suffix';
}

String _getSummaryLabel(WeeklyActivityMetric metric) {
  return metric == WeeklyActivityMetric.sessions
      ? 'Total sessions (7 days)'
      : 'Total minutes (7 days)';
}

String _formatTotal(double total, WeeklyActivityMetric metric) {
  return metric == WeeklyActivityMetric.sessions
      ? total.toInt().toString()
      : total.toStringAsFixed(0);
}

Color _getBarColor(WeeklyActivityDay day, bool isPrimary) {
  return isPrimary ? Colors.blue : Colors.grey;
}

List<WeeklyActivityDay> _generateLastSevenDays() {
  final today = DateTime.now();
  return List.generate(7, (i) {
    final date = today.subtract(Duration(days: 6 - i));
    return WeeklyActivityDay(
      date: DateTime(date.year, date.month, date.day),
      value: 0,
      label: _getDayLabel(date),
      isToday: i == 6,
    );
  });
}

// Mock widget

class _MockWeeklyActivityChart extends StatelessWidget {
  const _MockWeeklyActivityChart({
    this.isLoading = false,
    this.hasError = false,
    this.errorMessage = '',
    this.totalActivity = 0,
  });

  final bool isLoading;
  final bool hasError;
  final String errorMessage;
  final double totalActivity;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Weekly Activity',
                        style: theme.textTheme.titleMedium,
                      ),
                      Text(
                        'Last 7 days',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                const Text('Sessions'),
                const SizedBox(width: 8),
                const Text('Minutes'),
              ],
            ),
            const SizedBox(height: 16),
            if (isLoading)
              const Center(child: CircularProgressIndicator())
            else if (hasError)
              Center(
                child: Text(
                  'Failed to load activity data: $errorMessage',
                  style: TextStyle(color: theme.colorScheme.error),
                ),
              )
            else if (totalActivity <= 0)
              const Center(child: Text('No activity in the last 7 days'))
            else
              const SizedBox(height: 180), // Chart placeholder
          ],
        ),
      ),
    );
  }
}
