import 'package:drift/drift.dart';
import 'package:orthosense/core/database/connection/connection.dart' as impl;
import 'package:orthosense/core/database/tables/exercise_results_table.dart';
import 'package:orthosense/core/database/tables/sessions_table.dart';
import 'package:orthosense/core/database/tables/settings_table.dart';

export 'package:orthosense/core/database/converters.dart';

part 'app_database.g.dart';

/// Central Drift database - Single Source of Truth for OrthoSense.
/// Offline-First: UI observes Streams from Drift, never reads directly from API.
@DriftDatabase(
  tables: [Settings, Sessions, ExerciseResults],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(impl.openConnection());

  /// Constructor for testing with custom executor.
  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (m) async {
        await m.createAll();
      },
      onUpgrade: (m, from, to) async {
        // Migration from v1 to v2: add sessions and exercise results tables
        if (from < 2) {
          await m.createTable(sessions);
          await m.createTable(exerciseResults);
        }

        // Migration to v3: Ensure settings table exists
        if (from < 3) {
          try {
            await m.createTable(settings);
          } catch (e) {
            // Ignore if table already exists (e.g. fresh install on v2)
          }
        }

        // Migration to v4: Add new columns to exercise_results for history
        if (from < 4) {
          await m.addColumn(exerciseResults, exerciseResults.isCorrect);
          await m.addColumn(exerciseResults, exerciseResults.feedbackJson);
          await m.addColumn(exerciseResults, exerciseResults.textReport);
          await m.addColumn(exerciseResults, exerciseResults.durationSeconds);
          await m.addColumn(exerciseResults, exerciseResults.performedAt);
          await m.addColumn(exerciseResults, exerciseResults.syncStatus);
        }
      },
    );
  }

  // ===== Settings Operations =====

  /// Get a setting value by key.
  Future<String?> getSetting(String key) async {
    final query = select(settings)..where((t) => t.key.equals(key));
    final result = await query.getSingleOrNull();
    return result?.value;
  }

  /// Set a setting value.
  Future<void> setSetting(String key, String value) async {
    await into(settings).insertOnConflictUpdate(
      SettingsCompanion(
        key: Value(key),
        value: Value(value),
      ),
    );
  }

  // ===== Session Operations =====

  /// Watch all sessions as a stream (for reactive UI).
  Stream<List<Session>> watchAllSessions() {
    return (select(
      sessions,
    )..orderBy([(t) => OrderingTerm.desc(t.startedAt)])).watch();
  }

  /// Get a session by ID.
  Future<Session?> getSession(String id) async {
    return (select(sessions)..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  /// Insert a new session.
  Future<void> insertSession(SessionsCompanion session) async {
    await into(sessions).insert(session);
  }

  /// Update a session.
  Future<void> updateSession(SessionsCompanion session) async {
    await (update(
      sessions,
    )..where((t) => t.id.equals(session.id.value))).write(session);
  }

  // ===== Exercise Results Operations =====

  /// Watch all exercise results as a stream ordered by date (newest first).
  Stream<List<ExerciseResult>> watchAllExerciseResults() {
    return (select(
      exerciseResults,
    )..orderBy([(t) => OrderingTerm.desc(t.performedAt)])).watch();
  }

  /// Watch exercise results for a specific session.
  Stream<List<ExerciseResult>> watchExerciseResultsForSession(
    String sessionId,
  ) {
    return (select(exerciseResults)
          ..where((t) => t.sessionId.equals(sessionId))
          ..orderBy([(t) => OrderingTerm.desc(t.performedAt)]))
        .watch();
  }

  /// Get recent exercise results (limited count).
  Future<List<ExerciseResult>> getRecentExerciseResults({
    int limit = 20,
  }) async {
    return (select(exerciseResults)
          ..orderBy([(t) => OrderingTerm.desc(t.performedAt)])
          ..limit(limit))
        .get();
  }

  /// Insert a new exercise result.
  Future<void> insertExerciseResult(ExerciseResultsCompanion result) async {
    await into(exerciseResults).insert(result);
  }

  /// Get exercise result by ID.
  Future<ExerciseResult?> getExerciseResult(String id) async {
    return (select(
      exerciseResults,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  /// Get statistics for dashboard.
  Future<ExerciseStats> getExerciseStats() async {
    final allResults = await select(exerciseResults).get();

    if (allResults.isEmpty) {
      return const ExerciseStats(
        totalSessions: 0,
        averageScore: 0,
        correctPercentage: 0,
        thisWeekSessions: 0,
      );
    }

    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));

    final thisWeekResults = allResults
        .where((r) => r.performedAt.isAfter(weekAgo))
        .toList();

    final scores = allResults
        .where((r) => r.score != null)
        .map((r) => r.score!);
    final avgScore = scores.isEmpty
        ? 0
        : scores.reduce((a, b) => a + b) ~/ scores.length;

    final correctCount = allResults.where((r) => r.isCorrect ?? false).length;
    final correctPct = allResults.isEmpty
        ? 0
        : (correctCount / allResults.length * 100).round();

    return ExerciseStats(
      totalSessions: allResults.length,
      averageScore: avgScore,
      correctPercentage: correctPct,
      thisWeekSessions: thisWeekResults.length,
    );
  }
}

/// Statistics model for dashboard display.
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
