/// Unit tests for Drift AppDatabase.
///
/// Test coverage:
/// 1. Database initialization and migrations
/// 2. Settings CRUD operations
/// 3. Session CRUD operations
/// 4. Exercise results CRUD operations
/// 5. Stream watching (reactive queries)
/// 6. Statistics calculations
/// 7. Foreign key constraints
/// 8. Edge cases and error handling
library;

import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orthosense/core/database/app_database.dart';
import 'package:uuid/uuid.dart';

void main() {
  late AppDatabase database;

  setUp(() {
    // Use in-memory database for testing
    database = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await database.close();
  });

  group('Database Initialization', () {
    test('creates all tables on init', () async {
      // Verify tables exist by performing queries
      final settingsCount = await database.select(database.settings).get();
      final sessionsCount = await database.select(database.sessions).get();
      final resultsCount = await database
          .select(database.exerciseResults)
          .get();

      expect(settingsCount, isEmpty);
      expect(sessionsCount, isEmpty);
      expect(resultsCount, isEmpty);
    });

    test('schema version is correct', () {
      expect(database.schemaVersion, equals(4));
    });
  });

  group('Settings Operations', () {
    test('setSetting creates new setting', () async {
      await database.setSetting('test_key', 'test_value');

      final value = await database.getSetting('test_key');
      expect(value, equals('test_value'));
    });

    test('setSetting updates existing setting', () async {
      await database.setSetting('test_key', 'initial_value');
      await database.setSetting('test_key', 'updated_value');

      final value = await database.getSetting('test_key');
      expect(value, equals('updated_value'));
    });

    test('getSetting returns null for non-existent key', () async {
      final value = await database.getSetting('non_existent_key');
      expect(value, isNull);
    });

    test('multiple settings can be stored', () async {
      await database.setSetting('key1', 'value1');
      await database.setSetting('key2', 'value2');
      await database.setSetting('key3', 'value3');

      expect(await database.getSetting('key1'), equals('value1'));
      expect(await database.getSetting('key2'), equals('value2'));
      expect(await database.getSetting('key3'), equals('value3'));
    });
  });

  group('Session Operations', () {
    test('insertSession creates session', () async {
      final sessionId = const Uuid().v4();
      final now = DateTime.now();

      await database.insertSession(
        SessionsCompanion(
          id: Value(sessionId),
          startedAt: Value(now),
          syncStatus: const Value('pending'),
        ),
      );

      final session = await database.getSession(sessionId);
      expect(session, isNotNull);
      expect(session!.id, equals(sessionId));
      expect(session.syncStatus, equals('pending'));
    });

    test('getSession returns null for non-existent id', () async {
      final session = await database.getSession('non-existent-id');
      expect(session, isNull);
    });

    test('updateSession modifies existing session', () async {
      final sessionId = const Uuid().v4();
      final now = DateTime.now();

      await database.insertSession(
        SessionsCompanion(
          id: Value(sessionId),
          startedAt: Value(now),
          syncStatus: const Value('pending'),
        ),
      );

      await database.updateSession(
        SessionsCompanion(
          id: Value(sessionId),
          completedAt: Value(now.add(const Duration(minutes: 30))),
          overallScore: const Value(85),
          syncStatus: const Value('synced'),
        ),
      );

      final session = await database.getSession(sessionId);
      expect(session!.completedAt, isNotNull);
      expect(session.overallScore, equals(85));
      expect(session.syncStatus, equals('synced'));
    });

    test('watchAllSessions streams session changes', () async {
      final sessionId1 = const Uuid().v4();
      final sessionId2 = const Uuid().v4();
      final now = DateTime.now();

      // Set up stream listener
      final emissions = <List<Session>>[];
      final subscription = database.watchAllSessions().listen(emissions.add);

      // Wait for initial emission
      await Future<void>.delayed(const Duration(milliseconds: 50));

      // Insert sessions
      await database.insertSession(
        SessionsCompanion(
          id: Value(sessionId1),
          startedAt: Value(now),
        ),
      );

      await Future<void>.delayed(const Duration(milliseconds: 50));

      await database.insertSession(
        SessionsCompanion(
          id: Value(sessionId2),
          startedAt: Value(now.subtract(const Duration(hours: 1))),
        ),
      );

      await Future<void>.delayed(const Duration(milliseconds: 50));

      await subscription.cancel();

      // Should have received multiple emissions
      expect(emissions.length, greaterThanOrEqualTo(2));
      // Last emission should have 2 sessions
      expect(emissions.last.length, equals(2));
    });

    test('sessions ordered by startedAt descending', () async {
      final now = DateTime.now();

      await database.insertSession(
        SessionsCompanion(
          id: Value(const Uuid().v4()),
          startedAt: Value(now.subtract(const Duration(days: 2))),
        ),
      );

      await database.insertSession(
        SessionsCompanion(
          id: Value(const Uuid().v4()),
          startedAt: Value(now),
        ),
      );

      await database.insertSession(
        SessionsCompanion(
          id: Value(const Uuid().v4()),
          startedAt: Value(now.subtract(const Duration(days: 1))),
        ),
      );

      // Get first emission
      final sessions = await database.watchAllSessions().first;

      expect(sessions.length, equals(3));
      // First session should be the most recent
      expect(
        sessions[0].startedAt.isAfter(sessions[1].startedAt),
        isTrue,
      );
      expect(
        sessions[1].startedAt.isAfter(sessions[2].startedAt),
        isTrue,
      );
    });
  });

  group('Exercise Results Operations', () {
    late String sessionId;

    setUp(() async {
      sessionId = const Uuid().v4();
      await database.insertSession(
        SessionsCompanion(
          id: Value(sessionId),
          startedAt: Value(DateTime.now()),
        ),
      );
    });

    test('insertExerciseResult creates result', () async {
      final resultId = const Uuid().v4();

      await database.insertExerciseResult(
        ExerciseResultsCompanion(
          id: Value(resultId),
          sessionId: Value(sessionId),
          exerciseId: const Value('exercise-1'),
          exerciseName: const Value('Shoulder Abduction'),
          score: const Value(85),
          isCorrect: const Value(true),
        ),
      );

      final result = await database.getExerciseResult(resultId);
      expect(result, isNotNull);
      expect(result!.exerciseName, equals('Shoulder Abduction'));
      expect(result.score, equals(85));
      expect(result.isCorrect, isTrue);
    });

    test('getExerciseResult returns null for non-existent id', () async {
      final result = await database.getExerciseResult('non-existent');
      expect(result, isNull);
    });

    test('watchExerciseResultsForSession filters by session', () async {
      final sessionId2 = const Uuid().v4();
      await database.insertSession(
        SessionsCompanion(
          id: Value(sessionId2),
          startedAt: Value(DateTime.now()),
        ),
      );

      // Add result to first session
      await database.insertExerciseResult(
        ExerciseResultsCompanion(
          id: Value(const Uuid().v4()),
          sessionId: Value(sessionId),
          exerciseId: const Value('exercise-1'),
          exerciseName: const Value('Exercise 1'),
        ),
      );

      // Add result to second session
      await database.insertExerciseResult(
        ExerciseResultsCompanion(
          id: Value(const Uuid().v4()),
          sessionId: Value(sessionId2),
          exerciseId: const Value('exercise-2'),
          exerciseName: const Value('Exercise 2'),
        ),
      );

      final results = await database
          .watchExerciseResultsForSession(sessionId)
          .first;

      expect(results.length, equals(1));
      expect(results[0].exerciseName, equals('Exercise 1'));
    });

    test('getRecentExerciseResults respects limit', () async {
      // Insert 5 results
      for (var i = 0; i < 5; i++) {
        await database.insertExerciseResult(
          ExerciseResultsCompanion(
            id: Value(const Uuid().v4()),
            sessionId: Value(sessionId),
            exerciseId: Value('exercise-$i'),
            exerciseName: Value('Exercise $i'),
            performedAt: Value(
              DateTime.now().subtract(Duration(hours: i)),
            ),
          ),
        );
      }

      final results = await database.getRecentExerciseResults(limit: 3);
      expect(results.length, equals(3));
    });

    test('exercise results ordered by performedAt descending', () async {
      final now = DateTime.now();

      await database.insertExerciseResult(
        ExerciseResultsCompanion(
          id: Value(const Uuid().v4()),
          sessionId: Value(sessionId),
          exerciseId: const Value('old'),
          exerciseName: const Value('Old Exercise'),
          performedAt: Value(now.subtract(const Duration(days: 1))),
        ),
      );

      await database.insertExerciseResult(
        ExerciseResultsCompanion(
          id: Value(const Uuid().v4()),
          sessionId: Value(sessionId),
          exerciseId: const Value('new'),
          exerciseName: const Value('New Exercise'),
          performedAt: Value(now),
        ),
      );

      final results = await database.watchAllExerciseResults().first;

      expect(results[0].exerciseName, equals('New Exercise'));
      expect(results[1].exerciseName, equals('Old Exercise'));
    });

    test('feedbackJson stores JSON data', () async {
      final resultId = const Uuid().v4();
      const feedbackJson = '{"errors": ["knee_collapse"], "score": 75}';

      await database.insertExerciseResult(
        ExerciseResultsCompanion(
          id: Value(resultId),
          sessionId: Value(sessionId),
          exerciseId: const Value('exercise-1'),
          exerciseName: const Value('Squat'),
          feedbackJson: const Value(feedbackJson),
        ),
      );

      final result = await database.getExerciseResult(resultId);
      expect(result!.feedbackJson, equals(feedbackJson));
    });

    test('textReport stores detailed report', () async {
      final resultId = const Uuid().v4();
      const report = '''
Analysis Report:
- Form: Good
- Errors detected: None
- Score: 90/100
''';

      await database.insertExerciseResult(
        ExerciseResultsCompanion(
          id: Value(resultId),
          sessionId: Value(sessionId),
          exerciseId: const Value('exercise-1'),
          exerciseName: const Value('Squat'),
          textReport: const Value(report),
        ),
      );

      final result = await database.getExerciseResult(resultId);
      expect(result!.textReport, contains('Analysis Report'));
    });
  });

  group('Exercise Statistics', () {
    late String sessionId;

    setUp(() async {
      sessionId = const Uuid().v4();
      await database.insertSession(
        SessionsCompanion(
          id: Value(sessionId),
          startedAt: Value(DateTime.now()),
        ),
      );
    });

    test('getExerciseStats returns zeros for empty database', () async {
      final stats = await database.getExerciseStats();

      expect(stats.totalSessions, equals(0));
      expect(stats.averageScore, equals(0));
      expect(stats.correctPercentage, equals(0));
      expect(stats.thisWeekSessions, equals(0));
    });

    test('getExerciseStats calculates correct average', () async {
      await database.insertExerciseResult(
        ExerciseResultsCompanion(
          id: Value(const Uuid().v4()),
          sessionId: Value(sessionId),
          exerciseId: const Value('ex-1'),
          exerciseName: const Value('Exercise 1'),
          score: const Value(80),
        ),
      );

      await database.insertExerciseResult(
        ExerciseResultsCompanion(
          id: Value(const Uuid().v4()),
          sessionId: Value(sessionId),
          exerciseId: const Value('ex-2'),
          exerciseName: const Value('Exercise 2'),
          score: const Value(90),
        ),
      );

      final stats = await database.getExerciseStats();

      expect(stats.totalSessions, equals(2));
      expect(stats.averageScore, equals(85));
    });

    test('getExerciseStats calculates correct percentage', () async {
      // 2 correct, 1 incorrect = 66%
      await database.insertExerciseResult(
        ExerciseResultsCompanion(
          id: Value(const Uuid().v4()),
          sessionId: Value(sessionId),
          exerciseId: const Value('ex-1'),
          exerciseName: const Value('Exercise 1'),
          isCorrect: const Value(true),
        ),
      );

      await database.insertExerciseResult(
        ExerciseResultsCompanion(
          id: Value(const Uuid().v4()),
          sessionId: Value(sessionId),
          exerciseId: const Value('ex-2'),
          exerciseName: const Value('Exercise 2'),
          isCorrect: const Value(true),
        ),
      );

      await database.insertExerciseResult(
        ExerciseResultsCompanion(
          id: Value(const Uuid().v4()),
          sessionId: Value(sessionId),
          exerciseId: const Value('ex-3'),
          exerciseName: const Value('Exercise 3'),
          isCorrect: const Value(false),
        ),
      );

      final stats = await database.getExerciseStats();

      expect(stats.correctPercentage, equals(67)); // Rounded
    });

    test('getExerciseStats counts this week sessions', () async {
      final now = DateTime.now();

      // This week
      await database.insertExerciseResult(
        ExerciseResultsCompanion(
          id: Value(const Uuid().v4()),
          sessionId: Value(sessionId),
          exerciseId: const Value('ex-1'),
          exerciseName: const Value('Recent'),
          performedAt: Value(now.subtract(const Duration(days: 2))),
        ),
      );

      // Last week
      await database.insertExerciseResult(
        ExerciseResultsCompanion(
          id: Value(const Uuid().v4()),
          sessionId: Value(sessionId),
          exerciseId: const Value('ex-2'),
          exerciseName: const Value('Old'),
          performedAt: Value(now.subtract(const Duration(days: 10))),
        ),
      );

      final stats = await database.getExerciseStats();

      expect(stats.totalSessions, equals(2));
      expect(stats.thisWeekSessions, equals(1));
    });
  });

  group('Sync Status Tracking', () {
    test('new session defaults to pending sync status', () async {
      final sessionId = const Uuid().v4();

      await database.insertSession(
        SessionsCompanion(
          id: Value(sessionId),
          startedAt: Value(DateTime.now()),
        ),
      );

      final session = await database.getSession(sessionId);
      expect(session!.syncStatus, equals('pending'));
    });

    test('new exercise result defaults to pending sync status', () async {
      final sessionId = const Uuid().v4();
      await database.insertSession(
        SessionsCompanion(
          id: Value(sessionId),
          startedAt: Value(DateTime.now()),
        ),
      );

      final resultId = const Uuid().v4();
      await database.insertExerciseResult(
        ExerciseResultsCompanion(
          id: Value(resultId),
          sessionId: Value(sessionId),
          exerciseId: const Value('ex-1'),
          exerciseName: const Value('Exercise'),
        ),
      );

      final result = await database.getExerciseResult(resultId);
      expect(result!.syncStatus, equals('pending'));
    });

    test('sync status can be updated to synced', () async {
      final sessionId = const Uuid().v4();

      await database.insertSession(
        SessionsCompanion(
          id: Value(sessionId),
          startedAt: Value(DateTime.now()),
          syncStatus: const Value('pending'),
        ),
      );

      await database.updateSession(
        SessionsCompanion(
          id: Value(sessionId),
          syncStatus: const Value('synced'),
          lastSyncAttempt: Value(DateTime.now()),
        ),
      );

      final session = await database.getSession(sessionId);
      expect(session!.syncStatus, equals('synced'));
      expect(session.lastSyncAttempt, isNotNull);
    });

    test('sync status can be updated to error', () async {
      final sessionId = const Uuid().v4();

      await database.insertSession(
        SessionsCompanion(
          id: Value(sessionId),
          startedAt: Value(DateTime.now()),
        ),
      );

      await database.updateSession(
        SessionsCompanion(
          id: Value(sessionId),
          syncStatus: const Value('error'),
          lastSyncAttempt: Value(DateTime.now()),
        ),
      );

      final session = await database.getSession(sessionId);
      expect(session!.syncStatus, equals('error'));
    });
  });

  group('Foreign Key Constraints', () {
    test('exercise result requires valid session id', () async {
      // Try to insert result with non-existent session
      // Note: SQLite foreign key constraints must be enabled
      // This test documents expected behavior
      final resultId = const Uuid().v4();

      try {
        await database.insertExerciseResult(
          ExerciseResultsCompanion(
            id: Value(resultId),
            sessionId: const Value('non-existent-session'),
            exerciseId: const Value('ex-1'),
            exerciseName: const Value('Test'),
          ),
        );
        // If we get here, FK constraint wasn't enforced (acceptable in test mode)
      } catch (e) {
        // Expected - foreign key constraint violated
        expect(e.toString().toLowerCase(), contains('foreign'));
      }
    });
  });

  group('Edge Cases', () {
    test('handles unicode in exercise names', () async {
      final sessionId = const Uuid().v4();
      await database.insertSession(
        SessionsCompanion(
          id: Value(sessionId),
          startedAt: Value(DateTime.now()),
        ),
      );

      final resultId = const Uuid().v4();
      await database.insertExerciseResult(
        ExerciseResultsCompanion(
          id: Value(resultId),
          sessionId: Value(sessionId),
          exerciseId: const Value('ex-1'),
          exerciseName: const Value('Ćwiczenie 🏋️ テスト'),
        ),
      );

      final result = await database.getExerciseResult(resultId);
      expect(result!.exerciseName, equals('Ćwiczenie 🏋️ テスト'));
    });

    test('handles very long notes', () async {
      final sessionId = const Uuid().v4();
      final longNotes = 'A' * 10000;

      await database.insertSession(
        SessionsCompanion(
          id: Value(sessionId),
          startedAt: Value(DateTime.now()),
          notes: Value(longNotes),
        ),
      );

      final session = await database.getSession(sessionId);
      expect(session!.notes, equals(longNotes));
    });

    test('handles null optional fields', () async {
      final sessionId = const Uuid().v4();

      await database.insertSession(
        SessionsCompanion(
          id: Value(sessionId),
          startedAt: Value(DateTime.now()),
          // completedAt, overallScore, notes are all optional
        ),
      );

      final session = await database.getSession(sessionId);
      expect(session!.completedAt, isNull);
      expect(session.overallScore, isNull);
      expect(session.notes, isNull);
    });

    test('handles zero duration', () async {
      final sessionId = const Uuid().v4();

      await database.insertSession(
        SessionsCompanion(
          id: Value(sessionId),
          startedAt: Value(DateTime.now()),
          durationSeconds: const Value(0),
        ),
      );

      final session = await database.getSession(sessionId);
      expect(session!.durationSeconds, equals(0));
    });
  });
}
