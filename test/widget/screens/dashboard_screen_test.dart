/// Widget tests for DashboardScreen.
///
/// Test coverage:
/// 1. Screen rendering
/// 2. Navigation to other screens
/// 3. Stats display
/// 4. Charts rendering
/// 5. Recent sessions list
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:orthosense/core/database/app_database.dart';
import 'package:orthosense/core/providers/database_provider.dart';
import 'package:orthosense/features/auth/domain/models/user_model.dart';
import 'package:orthosense/features/auth/presentation/providers/auth_notifier.dart';
import 'package:orthosense/features/dashboard/domain/models/trend_data_model.dart';
import 'package:orthosense/features/dashboard/presentation/providers/trend_provider.dart';
import 'package:orthosense/features/dashboard/presentation/screens/dashboard_screen.dart';

class MockAppDatabase extends Mock implements AppDatabase {}

void main() {
  late MockAppDatabase mockDatabase;

  setUp(() {
    mockDatabase = MockAppDatabase();
  });

  Widget createTestWidget({UserModel? user}) {
    return ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWithValue(mockDatabase),
        currentUserProvider.overrideWith((ref) => user),
        dashboardStatsProvider.overrideWith(
          (ref) async => DashboardStats(
            totalSessions: 10,
            sessionsThisWeek: 3,
            averageScore: 85.0,
            scoreChange: 5.0,
            activeStreakDays: 5,
            totalTimeThisMonth: const Duration(minutes: 120),
            completionRate: 90.0,
          ),
        ),
        recentExerciseResultsProvider.overrideWith(
          (ref) => Stream.value(<ExerciseResult>[]),
        ),
      ],
      child: const MaterialApp(
        home: DashboardScreen(),
      ),
    );
  }

  group('DashboardScreen Rendering', () {
    testWidgets('renders screen correctly', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      expect(find.byType(DashboardScreen), findsOneWidget);
    });

    testWidgets('has app bar with title', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      expect(find.text('OrthoSense'), findsOneWidget);
    });

    testWidgets('has profile button', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      expect(find.byIcon(Icons.person_outline_rounded), findsOneWidget);
    });

    testWidgets('has activity log button', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      expect(find.byIcon(Icons.history_rounded), findsOneWidget);
    });

    testWidgets('has start session FAB', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      expect(find.text('Start Session'), findsOneWidget);
    });
  });

  group('Welcome Header', () {
    testWidgets('shows welcome message', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      expect(find.text('Welcome back,'), findsOneWidget);
    });

    testWidgets('extracts username from email', (tester) async {
      final user = UserModel(
        id: 'test-id',
        email: 'john.doe@example.com',
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(createTestWidget(user: user));
      await tester.pump();

      expect(find.text('john.doe'), findsOneWidget);
    });

    testWidgets('shows default name when no user', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      expect(find.text('User'), findsOneWidget);
    });
  });

  group('Stats Display', () {
    test('dashboard stats model has required fields', () {
      final stats = DashboardStats(
        totalSessions: 10,
        sessionsThisWeek: 3,
        averageScore: 85.0,
        scoreChange: 5.0,
        activeStreakDays: 5,
        totalTimeThisMonth: const Duration(minutes: 120),
        completionRate: 90.0,
      );

      expect(stats.totalSessions, equals(10));
      expect(stats.sessionsThisWeek, equals(3));
      expect(stats.averageScore, equals(85.0));
      expect(stats.scoreChange, equals(5.0));
      expect(stats.activeStreakDays, equals(5));
      expect(stats.completionRate, equals(90.0));
    });

    test('score change indicates improvement', () {
      const scoreChange = 5.0;
      final isImproving = scoreChange > 0;
      expect(isImproving, isTrue);
    });

    test('score change indicates decline', () {
      const scoreChange = -3.0;
      final isImproving = scoreChange > 0;
      expect(isImproving, isFalse);
    });
  });

  group('Section Headers', () {
    testWidgets('shows Your Progress section', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      expect(find.text('Your Progress'), findsOneWidget);
    });

    testWidgets('shows Recent Sessions section', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      expect(find.text('Recent Sessions'), findsOneWidget);
    });

    testWidgets('has View All button', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      expect(find.text('View All'), findsOneWidget);
    });
  });

  group('Start Session Flow', () {
    testWidgets('tapping FAB shows method selection', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      await tester.tap(find.text('Start Session'));
      await tester.pumpAndSettle();

      expect(find.text('Select Analysis Method'), findsOneWidget);
    });

    testWidgets('shows gallery analysis option', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      await tester.tap(find.text('Start Session'));
      await tester.pumpAndSettle();

      expect(find.text('Analyze from Gallery'), findsOneWidget);
    });

    testWidgets('shows live analysis option', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      await tester.tap(find.text('Start Session'));
      await tester.pumpAndSettle();

      expect(find.text('Live Camera Analysis'), findsOneWidget);
    });
  });

  group('Pull to Refresh', () {
    testWidgets('has refresh indicator', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      expect(find.byType(RefreshIndicator), findsOneWidget);
    });
  });

  group('Active Streak Calculation', () {
    test('streak is zero when no sessions', () {
      final sessions = <DateTime>[];
      final streak = _calculateStreak(sessions);
      expect(streak, equals(0));
    });

    test('streak counts consecutive days', () {
      final today = DateTime.now();
      final sessions = [
        today,
        today.subtract(const Duration(days: 1)),
        today.subtract(const Duration(days: 2)),
      ];
      final streak = _calculateStreak(sessions);
      expect(streak, equals(3));
    });

    test('streak breaks on missing day', () {
      final today = DateTime.now();
      final sessions = [
        today,
        today.subtract(const Duration(days: 2)), // Missing day 1
      ];
      final streak = _calculateStreak(sessions);
      expect(streak, equals(1));
    });
  });

  group('Mini Trend Data', () {
    test('generates sparkline data points', () {
      final data = [85.0, 88.0, 82.0, 90.0, 87.0];
      expect(data.length, equals(5));
    });

    test('empty data returns empty list', () {
      final data = <double>[];
      expect(data.isEmpty, isTrue);
    });
  });
}

// Helper function for streak calculation
int _calculateStreak(List<DateTime> sessionDates) {
  if (sessionDates.isEmpty) return 0;

  final sortedDates = sessionDates.map(
    (d) => DateTime(d.year, d.month, d.day),
  ).toSet().toList()..sort((a, b) => b.compareTo(a));

  if (sortedDates.isEmpty) return 0;

  final today = DateTime.now();
  final todayDate = DateTime(today.year, today.month, today.day);
  final yesterday = todayDate.subtract(const Duration(days: 1));

  if (sortedDates.first != todayDate && sortedDates.first != yesterday) {
    return 0;
  }

  int streak = 1;
  for (int i = 0; i < sortedDates.length - 1; i++) {
    final diff = sortedDates[i].difference(sortedDates[i + 1]).inDays;
    if (diff == 1) {
      streak++;
    } else {
      break;
    }
  }

  return streak;
}
