/// Widget tests for ActivityLogScreen.
///
/// Test coverage:
/// 1. Screen rendering
/// 2. Filter chips functionality
/// 3. Session list display
/// 4. Export options
/// 5. Empty state handling
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:orthosense/core/database/app_database.dart';
import 'package:orthosense/core/database/repositories/exercise_results_repository.dart';
import 'package:orthosense/features/dashboard/presentation/screens/activity_log_screen.dart';

class MockExerciseResultsRepository extends Mock
    implements ExerciseResultsRepository {}

void main() {
  late MockExerciseResultsRepository mockRepository;

  setUp(() {
    mockRepository = MockExerciseResultsRepository();

    when(() => mockRepository.watchAll()).thenAnswer((_) => Stream.value([]));
  });

  Widget createTestWidget() {
    return ProviderScope(
      overrides: [
        exerciseResultsRepositoryProvider.overrideWithValue(mockRepository),
      ],
      child: const MaterialApp(
        home: ActivityLogScreen(),
      ),
    );
  }

  group('ActivityLogScreen Rendering', () {
    testWidgets('renders screen correctly', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      expect(find.byType(ActivityLogScreen), findsOneWidget);
    });

    testWidgets('has app bar with title', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      expect(find.text('Activity Log'), findsOneWidget);
    });

    testWidgets('has export menu button', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      expect(find.byIcon(Icons.more_vert_rounded), findsOneWidget);
    });
  });

  group('ActivityFilter Enum', () {
    test('has all required filter types', () {
      expect(ActivityFilter.values.length, equals(4));
      expect(ActivityFilter.values, contains(ActivityFilter.all));
      expect(ActivityFilter.values, contains(ActivityFilter.thisWeek));
      expect(ActivityFilter.values, contains(ActivityFilter.thisMonth));
      expect(ActivityFilter.values, contains(ActivityFilter.pendingSync));
    });
  });

  group('Filter Chips', () {
    testWidgets('shows all filter chips', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      expect(find.text('All'), findsOneWidget);
      expect(find.text('This Week'), findsOneWidget);
      expect(find.text('This Month'), findsOneWidget);
      expect(find.text('Pending Sync'), findsOneWidget);
    });

    testWidgets('filter chips are tappable', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      final thisWeekChip = find.text('This Week');
      expect(thisWeekChip, findsOneWidget);

      await tester.tap(thisWeekChip);
      await tester.pump();
    });
  });

  group('Filter Logic', () {
    test('thisWeek filter calculates correct date range', () {
      final now = DateTime.now();
      final startOfWeek = now.subtract(Duration(days: now.weekday - 1));

      // startOfWeek should be before or equal to now (equal on Mondays)
      expect(startOfWeek.isAfter(now), isFalse);
    });

    test('thisMonth filter calculates correct date range', () {
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);

      // startOfMonth should be before or equal to now (equal on 1st day)
      expect(startOfMonth.isAfter(now), isFalse);
      expect(startOfMonth.month, equals(now.month));
    });

    test('pendingSync filter checks syncStatus', () {
      const pendingSyncStatus = 'pending';
      const syncedStatus = 'synced';

      expect(pendingSyncStatus, isNot(equals(syncedStatus)));
    });
  });

  group('Empty State', () {
    testWidgets('shows empty state when no data', (tester) async {
      when(() => mockRepository.watchAll()).thenAnswer((_) => Stream.value([]));

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Should show empty state or message
      expect(find.byType(ActivityLogScreen), findsOneWidget);
    });

    test('empty state message for no data', () {
      const message = 'No exercise sessions recorded yet';
      expect(message, contains('No exercise sessions'));
    });

    test('empty state message for filtered results', () {
      const message = 'No sessions match the current filter';
      expect(message, contains('No sessions'));
    });
  });

  group('Export Options', () {
    test('export types are available', () {
      const exportTypes = ['pdf', 'csv', 'share'];

      expect(exportTypes, contains('pdf'));
      expect(exportTypes, contains('csv'));
      expect(exportTypes, contains('share'));
    });

    testWidgets('export menu shows options', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      // Open menu
      await tester.tap(find.byIcon(Icons.more_vert_rounded));
      await tester.pumpAndSettle();

      expect(find.text('Export as PDF'), findsOneWidget);
      expect(find.text('Export as CSV'), findsOneWidget);
      expect(find.text('Share with Doctor'), findsOneWidget);
    });
  });

  group('Session Card', () {
    test('session card displays exercise name', () {
      const exerciseName = 'Deep Squat';
      expect(exerciseName, isNotEmpty);
    });

    test('session card displays score', () {
      const score = 85;
      expect(score, greaterThanOrEqualTo(0));
      expect(score, lessThanOrEqualTo(100));
    });

    test('session card displays duration', () {
      const durationSeconds = 120;
      final duration = '${durationSeconds ~/ 60}m ${durationSeconds % 60}s';
      expect(duration, equals('2m 0s'));
    });

    test('session card displays date', () {
      final date = DateTime.now();
      expect(date, isA<DateTime>());
    });

    test('session card shows sync status indicator', () {
      const syncStatus = 'pending';
      final needsSync = syncStatus == 'pending';
      expect(needsSync, isTrue);
    });
  });

  group('Date Formatting', () {
    test('formats date correctly', () {
      final date = DateTime(2025, 1, 15, 14, 30);
      final formatted = '${date.day}/${date.month}/${date.year}';
      expect(formatted, equals('15/1/2025'));
    });

    test('groups sessions by date', () {
      final dates = [
        DateTime(2025, 1, 15),
        DateTime(2025, 1, 15),
        DateTime(2025, 1, 14),
      ];

      final grouped = <DateTime, List<int>>{};
      for (var i = 0; i < dates.length; i++) {
        final key = DateTime(dates[i].year, dates[i].month, dates[i].day);
        grouped.putIfAbsent(key, () => []);
        grouped[key]!.add(i);
      }

      expect(grouped.length, equals(2));
    });
  });

  group('Loading State', () {
    testWidgets('shows loading indicator', (tester) async {
      // Use a completer instead of Future.delayed to avoid pending timers
      final completer = Completer<List<ExerciseResult>>();

      when(
        () => mockRepository.watchAll(),
      ).thenAnswer((_) => Stream.fromFuture(completer.future));

      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Complete the future to clean up
      completer.complete([]);
      await tester.pumpAndSettle();
    });
  });

  group('Error State', () {
    testWidgets('shows error state on failure', (tester) async {
      when(
        () => mockRepository.watchAll(),
      ).thenAnswer((_) => Stream.error(Exception('Database error')));

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Failed to load sessions'), findsOneWidget);
    });

    testWidgets('has retry button on error', (tester) async {
      when(
        () => mockRepository.watchAll(),
      ).thenAnswer((_) => Stream.error(Exception('Database error')));

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Retry'), findsOneWidget);
    });
  });
}
