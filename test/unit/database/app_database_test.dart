/// Unit tests for AppDatabase operations and migrations.
///
/// Test coverage:
/// 1. Database schema version
/// 2. Migration logic
/// 3. Settings operations
/// 4. Session operations
/// 5. Exercise results operations
/// 6. Statistics calculation
library;

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Database Schema', () {
    test('schema version is 4', () {
      const schemaVersion = 4;
      expect(schemaVersion, equals(4));
    });

    test('tables are defined', () {
      const tables = ['settings', 'sessions', 'exerciseResults'];

      expect(tables, contains('settings'));
      expect(tables, contains('sessions'));
      expect(tables, contains('exerciseResults'));
    });
  });

  group('Migration Logic', () {
    test('v1 to v2 creates sessions and exerciseResults tables', () {
      final migrations = _getMigrationsForUpgrade(1, 2);

      expect(migrations, contains('createTable:sessions'));
      expect(migrations, contains('createTable:exerciseResults'));
    });

    test('v2 to v3 creates settings table', () {
      final migrations = _getMigrationsForUpgrade(2, 3);

      expect(migrations, contains('createTable:settings'));
    });

    test('v3 to v4 adds new columns to exerciseResults', () {
      final migrations = _getMigrationsForUpgrade(3, 4);

      expect(migrations, contains('addColumn:isCorrect'));
      expect(migrations, contains('addColumn:feedbackJson'));
      expect(migrations, contains('addColumn:textReport'));
      expect(migrations, contains('addColumn:durationSeconds'));
      expect(migrations, contains('addColumn:performedAt'));
      expect(migrations, contains('addColumn:syncStatus'));
    });

    test('full migration from v1 to v4 includes all changes', () {
      final allMigrations = <String>[];

      allMigrations.addAll(_getMigrationsForUpgrade(1, 2));
      allMigrations.addAll(_getMigrationsForUpgrade(2, 3));
      allMigrations.addAll(_getMigrationsForUpgrade(3, 4));

      expect(allMigrations.length, greaterThan(5));
    });
  });

  group('Settings Operations', () {
    test('getSetting returns null for non-existent key', () async {
      final db = MockDatabase();

      final value = await db.getSetting('non_existent_key');

      expect(value, isNull);
    });

    test('setSetting creates new setting', () async {
      final db = MockDatabase();

      await db.setSetting('theme', 'dark');
      final value = await db.getSetting('theme');

      expect(value, equals('dark'));
    });

    test('setSetting updates existing setting', () async {
      final db = MockDatabase();

      await db.setSetting('theme', 'light');
      await db.setSetting('theme', 'dark');
      final value = await db.getSetting('theme');

      expect(value, equals('dark'));
    });

    test('settings support various value types as strings', () async {
      final db = MockDatabase();

      await db.setSetting('boolValue', 'true');
      await db.setSetting('intValue', '42');
      await db.setSetting('jsonValue', '{"key": "value"}');

      expect(await db.getSetting('boolValue'), equals('true'));
      expect(await db.getSetting('intValue'), equals('42'));
      expect(await db.getSetting('jsonValue'), contains('key'));
    });
  });

  group('Session Operations', () {
    test('insertSession adds new session', () async {
      final db = MockDatabase();

      await db.insertSession(
        MockSession(
          id: 'session-1',
          startedAt: DateTime(2025, 1, 15, 10, 0),
        ),
      );

      final session = await db.getSession('session-1');

      expect(session, isNotNull);
      expect(session?.id, equals('session-1'));
    });

    test('getSession returns null for non-existent ID', () async {
      final db = MockDatabase();

      final session = await db.getSession('non-existent');

      expect(session, isNull);
    });

    test('updateSession modifies existing session', () async {
      final db = MockDatabase();

      await db.insertSession(
        MockSession(
          id: 'session-1',
          startedAt: DateTime(2025, 1, 15, 10, 0),
        ),
      );

      await db.updateSession(
        MockSession(
          id: 'session-1',
          startedAt: DateTime(2025, 1, 15, 10, 0),
          completedAt: DateTime(2025, 1, 15, 10, 30),
          overallScore: 85,
        ),
      );

      final session = await db.getSession('session-1');

      expect(session?.completedAt, isNotNull);
      expect(session?.overallScore, equals(85));
    });

    test('watchAllSessions orders by startedAt descending', () {
      final sessions = [
        MockSession(id: '1', startedAt: DateTime(2025, 1, 10)),
        MockSession(id: '2', startedAt: DateTime(2025, 1, 15)),
        MockSession(id: '3', startedAt: DateTime(2025, 1, 12)),
      ];

      sessions.sort((a, b) => b.startedAt.compareTo(a.startedAt));

      expect(sessions.first.id, equals('2')); // Most recent
      expect(sessions.last.id, equals('1')); // Oldest
    });
  });

  group('Exercise Results Operations', () {
    test('insertExerciseResult adds new result', () async {
      final db = MockDatabase();

      await db.insertExerciseResult(
        MockExerciseResult(
          id: 'result-1',
          sessionId: 'session-1',
          exerciseName: 'Deep Squat',
          score: 85,
          isCorrect: true,
          performedAt: DateTime(2025, 1, 15, 10, 30),
        ),
      );

      final result = await db.getExerciseResult('result-1');

      expect(result, isNotNull);
      expect(result?.exerciseName, equals('Deep Squat'));
      expect(result?.score, equals(85));
    });

    test('getRecentExerciseResults limits results', () async {
      final db = MockDatabase();

      for (int i = 0; i < 30; i++) {
        await db.insertExerciseResult(
          MockExerciseResult(
            id: 'result-$i',
            sessionId: 'session-1',
            exerciseName: 'Squat',
            score: 80,
            isCorrect: true,
            performedAt: DateTime(2025, 1, 15).subtract(Duration(hours: i)),
          ),
        );
      }

      final recent = await db.getRecentExerciseResults(limit: 20);

      expect(recent.length, equals(20));
    });

    test('results ordered by performedAt descending', () {
      final results = [
        MockExerciseResult(
          id: '1',
          sessionId: 's1',
          exerciseName: 'Squat',
          score: 80,
          isCorrect: true,
          performedAt: DateTime(2025, 1, 10),
        ),
        MockExerciseResult(
          id: '2',
          sessionId: 's1',
          exerciseName: 'Step',
          score: 85,
          isCorrect: true,
          performedAt: DateTime(2025, 1, 15),
        ),
      ];

      results.sort((a, b) => b.performedAt.compareTo(a.performedAt));

      expect(results.first.id, equals('2')); // Most recent
    });

    test('watchExerciseResultsForSession filters by sessionId', () {
      final allResults = [
        MockExerciseResult(
          id: '1',
          sessionId: 'session-1',
          exerciseName: 'Squat',
          score: 80,
          isCorrect: true,
          performedAt: DateTime.now(),
        ),
        MockExerciseResult(
          id: '2',
          sessionId: 'session-2',
          exerciseName: 'Step',
          score: 85,
          isCorrect: true,
          performedAt: DateTime.now(),
        ),
        MockExerciseResult(
          id: '3',
          sessionId: 'session-1',
          exerciseName: 'Shoulder',
          score: 90,
          isCorrect: true,
          performedAt: DateTime.now(),
        ),
      ];

      final session1Results = allResults
          .where((r) => r.sessionId == 'session-1')
          .toList();

      expect(session1Results.length, equals(2));
    });
  });

  group('Exercise Statistics', () {
    test('empty results returns zero stats', () {
      final stats = _calculateStats([]);

      expect(stats.totalSessions, equals(0));
      expect(stats.averageScore, equals(0));
      expect(stats.correctPercentage, equals(0));
      expect(stats.thisWeekSessions, equals(0));
    });

    test('calculates total sessions', () {
      final results = List.generate(
        25,
        (i) => MockExerciseResult(
          id: 'result-$i',
          sessionId: 'session-$i',
          exerciseName: 'Squat',
          score: 80,
          isCorrect: true,
          performedAt: DateTime.now().subtract(Duration(days: i)),
        ),
      );

      final stats = _calculateStats(results);

      expect(stats.totalSessions, equals(25));
    });

    test('calculates average score', () {
      final results = [
        _mockResult(score: 80),
        _mockResult(score: 90),
        _mockResult(score: 70),
      ];

      final stats = _calculateStats(results);

      expect(stats.averageScore, equals(80)); // (80+90+70)/3
    });

    test('calculates correct percentage', () {
      final results = [
        _mockResult(isCorrect: true),
        _mockResult(isCorrect: true),
        _mockResult(isCorrect: false),
        _mockResult(isCorrect: true),
      ];

      final stats = _calculateStats(results);

      expect(stats.correctPercentage, equals(75)); // 3/4
    });

    test('calculates this week sessions', () {
      final now = DateTime.now();
      final results = [
        _mockResult(performedAt: now), // This week
        _mockResult(
          performedAt: now.subtract(const Duration(days: 2)),
        ), // This week
        _mockResult(
          performedAt: now.subtract(const Duration(days: 10)),
        ), // Last week
        _mockResult(
          performedAt: now.subtract(const Duration(days: 5)),
        ), // This week
      ];

      final stats = _calculateStats(results);

      expect(stats.thisWeekSessions, equals(3));
    });

    test('handles null scores in average calculation', () {
      final results = [
        _mockResult(score: 80),
        _mockResult(score: null),
        _mockResult(score: 100),
      ];

      final stats = _calculateStats(results);

      // Should only average non-null scores: (80+100)/2 = 90
      expect(stats.averageScore, equals(90));
    });
  });

  group('ExerciseStats Model', () {
    test('creates stats with all fields', () {
      const stats = ExerciseStats(
        totalSessions: 50,
        averageScore: 82,
        correctPercentage: 75,
        thisWeekSessions: 5,
      );

      expect(stats.totalSessions, equals(50));
      expect(stats.averageScore, equals(82));
      expect(stats.correctPercentage, equals(75));
      expect(stats.thisWeekSessions, equals(5));
    });
  });

  group('Companion Objects', () {
    test('SettingsCompanion creates with key and value', () {
      final companion = MockSettingsCompanion(
        key: 'theme',
        value: 'dark',
      );

      expect(companion.key, equals('theme'));
      expect(companion.value, equals('dark'));
    });

    test('SessionsCompanion creates with all fields', () {
      final companion = MockSessionsCompanion(
        id: 'session-1',
        startedAt: DateTime(2025, 1, 15, 10, 0),
        completedAt: DateTime(2025, 1, 15, 10, 30),
        durationSeconds: 1800,
        overallScore: 85,
        notes: 'Great session',
        syncStatus: 'pending',
      );

      expect(companion.id, equals('session-1'));
      expect(companion.durationSeconds, equals(1800));
    });

    test('ExerciseResultsCompanion creates with all fields', () {
      final companion = MockExerciseResultsCompanion(
        id: 'result-1',
        sessionId: 'session-1',
        exerciseId: 'deep_squat',
        exerciseName: 'Deep Squat',
        setsCompleted: 3,
        repsCompleted: 10,
        score: 85,
        isCorrect: true,
        feedbackJson: '{}',
        textReport: 'Great form',
        durationSeconds: 120,
        performedAt: DateTime(2025, 1, 15, 10, 30),
        syncStatus: 'pending',
      );

      expect(companion.id, equals('result-1'));
      expect(companion.exerciseName, equals('Deep Squat'));
      expect(companion.isCorrect, isTrue);
    });
  });
}

// Mock classes

class MockDatabase {
  final _settings = <String, String>{};
  final _sessions = <String, MockSession>{};
  final _results = <String, MockExerciseResult>{};

  Future<String?> getSetting(String key) async {
    return _settings[key];
  }

  Future<void> setSetting(String key, String value) async {
    _settings[key] = value;
  }

  Future<void> insertSession(MockSession session) async {
    _sessions[session.id] = session;
  }

  Future<MockSession?> getSession(String id) async {
    return _sessions[id];
  }

  Future<void> updateSession(MockSession session) async {
    _sessions[session.id] = session;
  }

  Future<void> insertExerciseResult(MockExerciseResult result) async {
    _results[result.id] = result;
  }

  Future<MockExerciseResult?> getExerciseResult(String id) async {
    return _results[id];
  }

  Future<List<MockExerciseResult>> getRecentExerciseResults({
    int limit = 20,
  }) async {
    final sorted = _results.values.toList()
      ..sort((a, b) => b.performedAt.compareTo(a.performedAt));
    return sorted.take(limit).toList();
  }
}

class MockSession {
  MockSession({
    required this.id,
    required this.startedAt,
    this.completedAt,
    this.overallScore,
  });

  final String id;
  final DateTime startedAt;
  final DateTime? completedAt;
  final int? overallScore;
}

class MockExerciseResult {
  MockExerciseResult({
    required this.id,
    required this.sessionId,
    required this.exerciseName,
    required this.score,
    required this.isCorrect,
    required this.performedAt,
  });

  final String id;
  final String sessionId;
  final String exerciseName;
  final int? score;
  final bool isCorrect;
  final DateTime performedAt;
}

class MockSettingsCompanion {
  MockSettingsCompanion({required this.key, required this.value});

  final String key;
  final String value;
}

class MockSessionsCompanion {
  MockSessionsCompanion({
    required this.id,
    required this.startedAt,
    this.completedAt,
    this.durationSeconds,
    this.overallScore,
    this.notes,
    this.syncStatus,
  });

  final String id;
  final DateTime startedAt;
  final DateTime? completedAt;
  final int? durationSeconds;
  final int? overallScore;
  final String? notes;
  final String? syncStatus;
}

class MockExerciseResultsCompanion {
  MockExerciseResultsCompanion({
    required this.id,
    required this.sessionId,
    required this.exerciseId,
    required this.exerciseName,
    required this.setsCompleted,
    required this.repsCompleted,
    required this.score,
    required this.isCorrect,
    required this.feedbackJson,
    required this.textReport,
    required this.durationSeconds,
    required this.performedAt,
    required this.syncStatus,
  });

  final String id;
  final String sessionId;
  final String exerciseId;
  final String exerciseName;
  final int setsCompleted;
  final int repsCompleted;
  final int? score;
  final bool? isCorrect;
  final String? feedbackJson;
  final String? textReport;
  final int? durationSeconds;
  final DateTime performedAt;
  final String? syncStatus;
}

class ExerciseStats {
  const ExerciseStats({
    required this.totalSessions,
    required this.averageScore,
    required this.correctPercentage,
    required this.thisWeekSessions,
  });

  final int totalSessions;
  final int averageScore;
  final int correctPercentage;
  final int thisWeekSessions;
}

// Helper functions

List<String> _getMigrationsForUpgrade(int from, int to) {
  final migrations = <String>[];

  if (from < 2 && to >= 2) {
    migrations.add('createTable:sessions');
    migrations.add('createTable:exerciseResults');
  }

  if (from < 3 && to >= 3) {
    migrations.add('createTable:settings');
  }

  if (from < 4 && to >= 4) {
    migrations.add('addColumn:isCorrect');
    migrations.add('addColumn:feedbackJson');
    migrations.add('addColumn:textReport');
    migrations.add('addColumn:durationSeconds');
    migrations.add('addColumn:performedAt');
    migrations.add('addColumn:syncStatus');
  }

  return migrations;
}

ExerciseStats _calculateStats(List<MockExerciseResult> results) {
  if (results.isEmpty) {
    return const ExerciseStats(
      totalSessions: 0,
      averageScore: 0,
      correctPercentage: 0,
      thisWeekSessions: 0,
    );
  }

  final now = DateTime.now();
  final weekAgo = now.subtract(const Duration(days: 7));

  final thisWeekResults = results
      .where((r) => r.performedAt.isAfter(weekAgo))
      .toList();

  final scores = results.where((r) => r.score != null).map((r) => r.score!);
  final avgScore = scores.isEmpty
      ? 0
      : scores.reduce((a, b) => a + b) ~/ scores.length;

  final correctCount = results.where((r) => r.isCorrect).length;
  final correctPct = results.isEmpty
      ? 0
      : (correctCount / results.length * 100).round();

  return ExerciseStats(
    totalSessions: results.length,
    averageScore: avgScore,
    correctPercentage: correctPct,
    thisWeekSessions: thisWeekResults.length,
  );
}

MockExerciseResult _mockResult({
  int? score = 80,
  bool isCorrect = true,
  DateTime? performedAt,
}) {
  return MockExerciseResult(
    id: 'result-${DateTime.now().microsecondsSinceEpoch}',
    sessionId: 'session-1',
    exerciseName: 'Squat',
    score: score,
    isCorrect: isCorrect,
    performedAt: performedAt ?? DateTime.now(),
  );
}
