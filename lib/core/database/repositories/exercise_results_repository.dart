import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:orthosense/core/database/app_database.dart';
import 'package:orthosense/core/providers/database_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

part 'exercise_results_repository.g.dart';

/// Repository for exercise results - handles DB operations and data mapping.
class ExerciseResultsRepository {
  ExerciseResultsRepository(this._db);

  final AppDatabase _db;

  /// Watch all exercise results as a stream (newest first).
  Stream<List<ExerciseResult>> watchAll() => _db.watchAllExerciseResults();

  /// Get recent results (for quick loading).
  Future<List<ExerciseResult>> getRecent({int limit = 20}) =>
      _db.getRecentExerciseResults(limit: limit);

  /// Get a single result by ID.
  Future<ExerciseResult?> getById(String id) => _db.getExerciseResult(id);

  /// Save a new exercise result after analysis completion.
  Future<String> saveAnalysisResult({
    required String sessionId,
    required String exerciseId,
    required String exerciseName,
    required int score,
    required bool isCorrect,
    required Map<String, dynamic> feedback,
    required String textReport,
    required int durationSeconds,
  }) async {
    final id = const Uuid().v4();

    await _db.insertExerciseResult(
      ExerciseResultsCompanion(
        id: Value(id),
        sessionId: Value(sessionId),
        exerciseId: Value(exerciseId),
        exerciseName: Value(exerciseName),
        score: Value(score),
        isCorrect: Value(isCorrect),
        feedbackJson: Value(jsonEncode(feedback)),
        textReport: Value(textReport),
        durationSeconds: Value(durationSeconds),
        performedAt: Value(DateTime.now()),
        syncStatus: const Value('pending'),
      ),
    );

    return id;
  }

  /// Get exercise statistics for dashboard.
  Future<ExerciseStats> getStats() => _db.getExerciseStats();

  /// Parse feedback JSON from database.
  static Map<String, dynamic> parseFeedback(String? feedbackJson) {
    if (feedbackJson == null || feedbackJson.isEmpty) {
      return {};
    }
    try {
      return jsonDecode(feedbackJson) as Map<String, dynamic>;
    } catch (_) {
      return {};
    }
  }
}

@Riverpod(keepAlive: true)
ExerciseResultsRepository exerciseResultsRepository(Ref ref) {
  final db = ref.watch(appDatabaseProvider);
  return ExerciseResultsRepository(db);
}
