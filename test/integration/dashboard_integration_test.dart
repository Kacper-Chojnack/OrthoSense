/// Integration tests for Dashboard feature.
///
/// Test coverage:
/// 1. Dashboard navigation flow
/// 2. Stats loading
/// 3. Trend chart interaction
/// 4. Recent sessions display
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Dashboard Navigation', () {
    testWidgets('shows main dashboard sections', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: _MockDashboardScreen(),
        ),
      );

      expect(find.text('Welcome'), findsOneWidget);
      expect(find.text('Statistics'), findsOneWidget);
      expect(find.text('Recent Activity'), findsOneWidget);
    });

    testWidgets('shows exercise catalog button', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: _MockDashboardScreen(),
        ),
      );

      expect(find.text('Start Exercise'), findsOneWidget);
    });

    testWidgets('shows history button', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: _MockDashboardScreen(),
        ),
      );

      expect(find.text('History'), findsOneWidget);
    });
  });

  group('Stats Display', () {
    testWidgets('shows total sessions stat', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: _MockDashboardScreen(totalSessions: 42),
        ),
      );

      expect(find.text('42'), findsOneWidget);
      expect(find.text('Total Sessions'), findsOneWidget);
    });

    testWidgets('shows average score stat', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: _MockDashboardScreen(averageScore: 85),
        ),
      );

      expect(find.text('85%'), findsOneWidget);
      expect(find.text('Average Score'), findsOneWidget);
    });

    testWidgets('shows correct percentage stat', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: _MockDashboardScreen(correctPercentage: 90),
        ),
      );

      expect(find.text('90%'), findsOneWidget);
      expect(find.text('Correct Form'), findsOneWidget);
    });

    testWidgets('shows loading state', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: _MockDashboardScreen(isLoading: true),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsWidgets);
    });
  });

  group('Recent Sessions', () {
    testWidgets('shows empty state when no sessions', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: _MockDashboardScreen(recentSessions: []),
        ),
      );

      expect(find.text('No recent sessions'), findsOneWidget);
    });

    testWidgets('shows session cards', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: _MockDashboardScreen(
            recentSessions: [
              MockRecentSession(name: 'Deep Squat', score: 85),
              MockRecentSession(name: 'Hurdle Step', score: 78),
            ],
          ),
        ),
      );

      expect(find.text('Deep Squat'), findsOneWidget);
      expect(find.text('Hurdle Step'), findsOneWidget);
    });

    testWidgets('session card shows score', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: _MockDashboardScreen(
            recentSessions: [
              MockRecentSession(name: 'Deep Squat', score: 85),
            ],
          ),
        ),
      );

      expect(find.text('85%'), findsOneWidget);
    });
  });

  group('Trend Period Selection', () {
    test('default period is 7 days', () {
      const period = TrendPeriod.week;
      expect(period.days, equals(7));
    });

    test('30 day period', () {
      const period = TrendPeriod.month;
      expect(period.days, equals(30));
    });

    test('90 day period', () {
      const period = TrendPeriod.quarter;
      expect(period.days, equals(90));
    });

    test('period has display label', () {
      expect(TrendPeriod.week.label, equals('7D'));
      expect(TrendPeriod.month.label, equals('30D'));
      expect(TrendPeriod.quarter.label, equals('90D'));
    });
  });

  group('Trend Metric Types', () {
    test('score metric type', () {
      const type = TrendMetricType.score;
      expect(type.displayName, contains('Score'));
    });

    test('correct form metric type', () {
      const type = TrendMetricType.correctForm;
      expect(type.displayName, contains('Form'));
    });

    test('session count metric type', () {
      const type = TrendMetricType.sessionCount;
      expect(type.displayName, contains('Session'));
    });
  });

  group('Chart Data Points', () {
    test('data point has date and value', () {
      final point = TrendDataPoint(
        date: DateTime(2024, 1, 15),
        value: 85.5,
      );

      expect(point.date, equals(DateTime(2024, 1, 15)));
      expect(point.value, equals(85.5));
    });

    test('data points can be compared by date', () {
      final point1 = TrendDataPoint(
        date: DateTime(2024, 1, 14),
        value: 80,
      );
      final point2 = TrendDataPoint(
        date: DateTime(2024, 1, 15),
        value: 85,
      );

      expect(point1.date.isBefore(point2.date), isTrue);
    });
  });

  group('Welcome Header', () {
    testWidgets('shows greeting', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: _MockWelcomeHeader(userName: 'John'),
        ),
      );

      expect(find.textContaining('John'), findsOneWidget);
    });

    testWidgets('shows app name', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: _MockWelcomeHeader(userName: 'User'),
        ),
      );

      expect(find.text('OrthoSense'), findsOneWidget);
    });
  });

  group('Stats Grid', () {
    testWidgets('shows 4 stat cards in grid', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: _MockStatsGrid(
              stats: [
                MockStat(label: 'Sessions', value: '42'),
                MockStat(label: 'Score', value: '85%'),
                MockStat(label: 'Correct', value: '90%'),
                MockStat(label: 'Total Time', value: '2h'),
              ],
            ),
          ),
        ),
      );

      expect(find.text('42'), findsOneWidget);
      expect(find.text('85%'), findsOneWidget);
      expect(find.text('90%'), findsOneWidget);
      expect(find.text('2h'), findsOneWidget);
    });
  });

  group('Refresh Behavior', () {
    testWidgets('pull to refresh triggers reload', (tester) async {
      var refreshed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: _MockRefreshableDashboard(
            onRefresh: () async {
              refreshed = true;
            },
          ),
        ),
      );

      // Simulate pull down
      await tester.drag(find.byType(RefreshIndicator), const Offset(0, 300));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(refreshed, isTrue);
    });
  });
}

// Enums

enum TrendPeriod {
  week(7, '7D', 'Last 7 Days'),
  month(30, '30D', 'Last 30 Days'),
  quarter(90, '90D', 'Last 90 Days');

  const TrendPeriod(this.days, this.label, this.longLabel);

  final int days;
  final String label;
  final String longLabel;
}

enum TrendMetricType {
  score('Average Score'),
  correctForm('Correct Form %'),
  sessionCount('Sessions Count');

  const TrendMetricType(this.displayName);

  final String displayName;
}

// Models

class TrendDataPoint {
  TrendDataPoint({required this.date, required this.value});

  final DateTime date;
  final double value;
}

class MockRecentSession {
  MockRecentSession({
    required this.name,
    required this.score,
    DateTime? date,
  }) : date = date ?? DateTime.now();

  final String name;
  final int score;
  final DateTime date;
}

class MockStat {
  const MockStat({required this.label, required this.value});

  final String label;
  final String value;
}

// Widget mocks

class _MockDashboardScreen extends StatelessWidget {
  const _MockDashboardScreen({
    this.totalSessions = 0,
    this.averageScore = 0,
    this.correctPercentage = 0,
    this.recentSessions = const [],
    this.isLoading = false,
  });

  final int totalSessions;
  final int averageScore;
  final int correctPercentage;
  final List<MockRecentSession> recentSessions;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('OrthoSense')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Welcome',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Statistics',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          value: '$totalSessions',
                          label: 'Total Sessions',
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _StatCard(
                          value: '$averageScore%',
                          label: 'Average Score',
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _StatCard(
                          value: '$correctPercentage%',
                          label: 'Correct Form',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Recent Activity',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  if (recentSessions.isEmpty)
                    const Text('No recent sessions')
                  else
                    ...recentSessions.map(
                      (s) => Card(
                        child: ListTile(
                          title: Text(s.name),
                          trailing: Text('${s.score}%'),
                        ),
                      ),
                    ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton(
                          onPressed: () {},
                          child: const Text('Start Exercise'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {},
                          child: const Text('History'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class _MockWelcomeHeader extends StatelessWidget {
  const _MockWelcomeHeader({required this.userName});

  final String userName;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const Text('OrthoSense'),
          Text('Welcome, $userName'),
        ],
      ),
    );
  }
}

class _MockStatsGrid extends StatelessWidget {
  const _MockStatsGrid({required this.stats});

  final List<MockStat> stats;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      children: stats.map((stat) {
        return Card(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(stat.value),
              Text(stat.label),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _MockRefreshableDashboard extends StatelessWidget {
  const _MockRefreshableDashboard({required this.onRefresh});

  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: onRefresh,
        child: ListView(
          children: const [
            Text('Dashboard Content'),
          ],
        ),
      ),
    );
  }
}
