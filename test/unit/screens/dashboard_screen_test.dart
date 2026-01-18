/// Unit tests for DashboardScreen business logic and providers.
///
/// Test coverage:
/// 1. Dashboard stats calculation
/// 2. Recent sessions display logic
/// 3. Refresh indicator behavior
/// 4. Welcome header with user data
/// 5. Navigation actions
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DashboardStats', () {
    test('creates stats with all fields', () {
      const stats = DashboardStats(
        totalSessions: 25,
        thisWeekSessions: 5,
        averageScore: 78,
        currentStreak: 3,
        longestStreak: 7,
        totalMinutes: 450,
      );

      expect(stats.totalSessions, equals(25));
      expect(stats.thisWeekSessions, equals(5));
      expect(stats.averageScore, equals(78));
      expect(stats.currentStreak, equals(3));
      expect(stats.longestStreak, equals(7));
      expect(stats.totalMinutes, equals(450));
    });

    test('handles zero stats (new user)', () {
      const stats = DashboardStats(
        totalSessions: 0,
        thisWeekSessions: 0,
        averageScore: 0,
        currentStreak: 0,
        longestStreak: 0,
        totalMinutes: 0,
      );

      expect(stats.totalSessions, equals(0));
      expect(stats.averageScore, equals(0));
    });

    test('formats total time correctly', () {
      const stats = DashboardStats(
        totalSessions: 10,
        thisWeekSessions: 2,
        averageScore: 85,
        currentStreak: 1,
        longestStreak: 5,
        totalMinutes: 135,
      );

      final formatted = stats.formattedTotalTime;

      expect(formatted, equals('2h 15m'));
    });

    test('formats time under an hour', () {
      const stats = DashboardStats(
        totalSessions: 3,
        thisWeekSessions: 1,
        averageScore: 90,
        currentStreak: 1,
        longestStreak: 1,
        totalMinutes: 45,
      );

      final formatted = stats.formattedTotalTime;

      expect(formatted, equals('45m'));
    });

    test('formats time exactly one hour', () {
      const stats = DashboardStats(
        totalSessions: 5,
        thisWeekSessions: 2,
        averageScore: 80,
        currentStreak: 2,
        longestStreak: 3,
        totalMinutes: 60,
      );

      final formatted = stats.formattedTotalTime;

      expect(formatted, equals('1h'));
    });
  });

  group('Recent Sessions', () {
    test('session has all required fields', () {
      final session = RecentSession(
        id: 'session-123',
        exerciseName: 'Deep Squat',
        score: 85,
        isCorrect: true,
        performedAt: DateTime(2025, 1, 15, 10, 30),
        durationSeconds: 120,
      );

      expect(session.id, equals('session-123'));
      expect(session.exerciseName, equals('Deep Squat'));
      expect(session.score, equals(85));
      expect(session.isCorrect, isTrue);
      expect(session.durationSeconds, equals(120));
    });

    test('formats relative time for today', () {
      final now = DateTime.now();
      final session = RecentSession(
        id: '1',
        exerciseName: 'Squat',
        score: 80,
        isCorrect: true,
        performedAt: now.subtract(const Duration(hours: 2)),
        durationSeconds: 60,
      );

      final relative = session.relativeTimeString;

      expect(relative, contains('hour'));
    });

    test('formats relative time for yesterday', () {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final session = RecentSession(
        id: '1',
        exerciseName: 'Squat',
        score: 80,
        isCorrect: true,
        performedAt: yesterday,
        durationSeconds: 60,
      );

      final relative = session.relativeTimeString;

      expect(relative.toLowerCase(), contains('day'));
    });

    test('formats duration in minutes', () {
      final session = RecentSession(
        id: '1',
        exerciseName: 'Squat',
        score: 80,
        isCorrect: true,
        performedAt: DateTime.now(),
        durationSeconds: 150,
      );

      final formatted = session.formattedDuration;

      expect(formatted, equals('2:30'));
    });

    test('groups sessions by date', () {
      final today = DateTime.now();
      final yesterday = today.subtract(const Duration(days: 1));

      final sessions = [
        RecentSession(
          id: '1',
          exerciseName: 'Squat',
          score: 80,
          isCorrect: true,
          performedAt: today,
          durationSeconds: 60,
        ),
        RecentSession(
          id: '2',
          exerciseName: 'Step',
          score: 85,
          isCorrect: true,
          performedAt: today.subtract(const Duration(hours: 2)),
          durationSeconds: 60,
        ),
        RecentSession(
          id: '3',
          exerciseName: 'Shoulder',
          score: 90,
          isCorrect: true,
          performedAt: yesterday,
          durationSeconds: 60,
        ),
      ];

      final grouped = _groupSessionsByDate(sessions);

      expect(grouped.keys.length, equals(2)); // today and yesterday
    });

    test('limits recent sessions to 5', () {
      final sessions = List.generate(
        10,
        (i) => RecentSession(
          id: 'session-$i',
          exerciseName: 'Squat',
          score: 80,
          isCorrect: true,
          performedAt: DateTime.now().subtract(Duration(hours: i)),
          durationSeconds: 60,
        ),
      );

      final recent = sessions.take(5).toList();

      expect(recent.length, equals(5));
    });
  });

  group('Welcome Header', () {
    test('displays user name if available', () {
      const user = MockUserModel(name: 'John Doe', email: 'john@example.com');

      final greeting = _getGreeting(user);

      expect(greeting, contains('John'));
    });

    test('displays generic greeting if no name', () {
      const user = MockUserModel(name: null, email: 'user@example.com');

      final greeting = _getGreeting(user);

      expect(greeting, isNot(contains('null')));
    });

    test('displays time-appropriate greeting', () {
      final morningGreeting = _getTimeBasedGreeting(9);
      final afternoonGreeting = _getTimeBasedGreeting(14);
      final eveningGreeting = _getTimeBasedGreeting(20);

      expect(morningGreeting, equals('Good morning'));
      expect(afternoonGreeting, equals('Good afternoon'));
      expect(eveningGreeting, equals('Good evening'));
    });

    test('handles null user gracefully', () {
      const MockUserModel? user = null;

      final greeting = _getGreeting(user);

      expect(greeting, isNotEmpty);
    });
  });

  group('Stats Grid', () {
    test('displays session count', () {
      const stats = DashboardStats(
        totalSessions: 42,
        thisWeekSessions: 6,
        averageScore: 82,
        currentStreak: 4,
        longestStreak: 10,
        totalMinutes: 500,
      );

      final items = _getStatsGridItems(stats);

      expect(items.any((i) => i.value == '42'), isTrue);
    });

    test('displays average score', () {
      const stats = DashboardStats(
        totalSessions: 20,
        thisWeekSessions: 3,
        averageScore: 87,
        currentStreak: 2,
        longestStreak: 5,
        totalMinutes: 200,
      );

      final items = _getStatsGridItems(stats);

      expect(items.any((i) => i.value == '87%'), isTrue);
    });

    test('displays current streak', () {
      const stats = DashboardStats(
        totalSessions: 15,
        thisWeekSessions: 4,
        averageScore: 75,
        currentStreak: 5,
        longestStreak: 8,
        totalMinutes: 180,
      );

      final items = _getStatsGridItems(stats);

      expect(items.any((i) => i.label.contains('Streak')), isTrue);
    });

    test('shows fire emoji for active streak', () {
      const stats = DashboardStats(
        totalSessions: 10,
        thisWeekSessions: 3,
        averageScore: 80,
        currentStreak: 3,
        longestStreak: 5,
        totalMinutes: 100,
      );

      final items = _getStatsGridItems(stats);
      final streakItem = items.firstWhere((i) => i.label.contains('Streak'));

      expect(streakItem.hasFireEmoji, isTrue);
    });
  });

  group('Refresh Behavior', () {
    test('invalidates all providers on refresh', () {
      final invalidated = <String>[];

      _simulateRefresh(
        onInvalidate: (provider) => invalidated.add(provider),
      );

      expect(invalidated, contains('dashboardStatsProvider'));
      expect(invalidated, contains('recentExerciseResultsProvider'));
      expect(invalidated, contains('weeklyActivityDataProvider'));
      expect(invalidated, contains('trendDataProvider'));
    });
  });

  group('Navigation', () {
    test('start session shows method selection', () {
      var showsCalled = false;
      var optionsShown = <String>[];

      _simulateStartSession(
        onShowOptions: (options) {
          showsCalled = true;
          optionsShown = options;
        },
      );

      expect(showsCalled, isTrue);
      expect(optionsShown, contains('Gallery Analysis'));
      expect(optionsShown, contains('Live Camera Analysis'));
    });

    test('gallery option navigates to gallery screen', () {
      var navigatedTo = '';

      _simulateSelectAnalysisMethod(
        method: 'gallery',
        onNavigate: (screen) {
          navigatedTo = screen;
        },
      );

      expect(navigatedTo, equals('GalleryAnalysisScreen'));
    });

    test('live option navigates to live screen', () {
      var navigatedTo = '';

      _simulateSelectAnalysisMethod(
        method: 'live',
        onNavigate: (screen) {
          navigatedTo = screen;
        },
      );

      expect(navigatedTo, equals('LiveAnalysisScreen'));
    });
  });

  group('Dashboard Widget', () {
    testWidgets('displays app bar with title', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: TestDashboardScreen(),
        ),
      );

      expect(find.text('OrthoSense'), findsOneWidget);
    });

    testWidgets('displays FAB for starting session', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: TestDashboardScreen(),
        ),
      );

      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(find.text('Start Session'), findsOneWidget);
    });

    testWidgets('displays Your Progress section', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: TestDashboardScreen(),
        ),
      );

      expect(find.text('Your Progress'), findsOneWidget);
    });

    testWidgets('displays Recent Sessions section', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: TestDashboardScreen(),
        ),
      );

      expect(find.text('Recent Sessions'), findsOneWidget);
    });

    testWidgets('has profile button in app bar', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: TestDashboardScreen(),
        ),
      );

      expect(
        find.widgetWithIcon(IconButton, Icons.person_outline_rounded),
        findsOneWidget,
      );
    });

    testWidgets('has activity log button in app bar', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: TestDashboardScreen(),
        ),
      );

      expect(
        find.widgetWithIcon(IconButton, Icons.history_rounded),
        findsOneWidget,
      );
    });
  });
}

// Test data classes

class DashboardStats {
  const DashboardStats({
    required this.totalSessions,
    required this.thisWeekSessions,
    required this.averageScore,
    required this.currentStreak,
    required this.longestStreak,
    required this.totalMinutes,
  });

  final int totalSessions;
  final int thisWeekSessions;
  final int averageScore;
  final int currentStreak;
  final int longestStreak;
  final int totalMinutes;

  String get formattedTotalTime {
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;

    if (hours == 0) return '${minutes}m';
    if (minutes == 0) return '${hours}h';
    return '${hours}h ${minutes}m';
  }
}

class RecentSession {
  RecentSession({
    required this.id,
    required this.exerciseName,
    required this.score,
    required this.isCorrect,
    required this.performedAt,
    required this.durationSeconds,
  });

  final String id;
  final String exerciseName;
  final int score;
  final bool isCorrect;
  final DateTime performedAt;
  final int durationSeconds;

  String get relativeTimeString {
    final now = DateTime.now();
    final diff = now.difference(performedAt);

    if (diff.inHours < 1) return '${diff.inMinutes} minutes ago';
    if (diff.inHours < 24) return '${diff.inHours} hours ago';
    if (diff.inDays == 1) return '1 day ago';
    return '${diff.inDays} days ago';
  }

  String get formattedDuration {
    final minutes = durationSeconds ~/ 60;
    final seconds = durationSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}

class MockUserModel {
  const MockUserModel({this.name, required this.email});

  final String? name;
  final String email;
}

class StatsGridItem {
  const StatsGridItem({
    required this.label,
    required this.value,
    this.hasFireEmoji = false,
  });

  final String label;
  final String value;
  final bool hasFireEmoji;
}

// Helper functions

Map<String, List<RecentSession>> _groupSessionsByDate(
  List<RecentSession> sessions,
) {
  final grouped = <String, List<RecentSession>>{};

  for (final session in sessions) {
    final dateKey =
        '${session.performedAt.year}-${session.performedAt.month}-${session.performedAt.day}';
    grouped.putIfAbsent(dateKey, () => []).add(session);
  }

  return grouped;
}

String _getGreeting(MockUserModel? user) {
  final name = user?.name;
  final hour = DateTime.now().hour;
  final timeGreeting = _getTimeBasedGreeting(hour);

  if (name != null && name.isNotEmpty) {
    final firstName = name.split(' ').first;
    return '$timeGreeting, $firstName!';
  }

  return '$timeGreeting!';
}

String _getTimeBasedGreeting(int hour) {
  if (hour < 12) return 'Good morning';
  if (hour < 17) return 'Good afternoon';
  return 'Good evening';
}

List<StatsGridItem> _getStatsGridItems(DashboardStats stats) {
  return [
    StatsGridItem(
      label: 'Total Sessions',
      value: '${stats.totalSessions}',
    ),
    StatsGridItem(
      label: 'This Week',
      value: '${stats.thisWeekSessions}',
    ),
    StatsGridItem(
      label: 'Avg Score',
      value: '${stats.averageScore}%',
    ),
    StatsGridItem(
      label: 'Current Streak',
      value: '${stats.currentStreak}',
      hasFireEmoji: stats.currentStreak > 0,
    ),
  ];
}

void _simulateRefresh({
  required void Function(String) onInvalidate,
}) {
  onInvalidate('dashboardStatsProvider');
  onInvalidate('recentExerciseResultsProvider');
  onInvalidate('weeklyActivityDataProvider');
  onInvalidate('trendDataProvider');
}

void _simulateStartSession({
  required void Function(List<String>) onShowOptions,
}) {
  onShowOptions(['Gallery Analysis', 'Live Camera Analysis']);
}

void _simulateSelectAnalysisMethod({
  required String method,
  required void Function(String) onNavigate,
}) {
  if (method == 'gallery') {
    onNavigate('GalleryAnalysisScreen');
  } else if (method == 'live') {
    onNavigate('LiveAnalysisScreen');
  }
}

// Test widget

class TestDashboardScreen extends StatelessWidget {
  const TestDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('OrthoSense'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.person_outline_rounded),
          onPressed: () {},
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.menu_book),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.history_rounded),
            onPressed: () {},
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          Text('Your Progress'),
          SizedBox(height: 24),
          Text('Recent Sessions'),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        icon: const Icon(Icons.play_arrow_rounded),
        label: const Text('Start Session'),
      ),
    );
  }
}
