import 'package:drift/drift.dart' show Value;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orthosense/core/database/app_database.dart';
import 'package:orthosense/core/database/repositories/exercise_results_repository.dart';
import 'package:orthosense/core/providers/database_provider.dart';
import 'package:orthosense/core/providers/movement_diagnostics_provider.dart';
import 'package:orthosense/core/services/movement_diagnostics_service.dart';
import 'package:uuid/uuid.dart';

/// Helper class for saving analysis results to Drift database.
class AnalysisResultSaver {
  AnalysisResultSaver(this._ref);

  final WidgetRef _ref;

  /// Save analysis result to local database after session completion.
  Future<String?> saveResult({
    required String exerciseName,
    required int score,
    required bool isCorrect,
    required Map<String, int> errorCounts,
    required int durationSeconds,
  }) async {
    try {
      final repository = _ref.read(exerciseResultsRepositoryProvider);
      final diagnostics = _ref.read(movementDiagnosticsServiceProvider);
      final db = _ref.read(appDatabaseProvider);

      // Convert error counts to boolean feedback
      final feedback = errorCounts.map((k, v) => MapEntry(k, v > 0));

      // Generate text report
      final result = DiagnosticsResult(
        isCorrect: isCorrect,
        feedback: feedback,
      );
      final textReport = diagnostics.generateReport(result, exerciseName);

      // Create session ID
      final sessionId = const Uuid().v4();
      final now = DateTime.now();

      // Insert parent session first
      await db.insertSession(
        SessionsCompanion(
          id: Value(sessionId),
          startedAt: Value(now.subtract(Duration(seconds: durationSeconds))),
          completedAt: Value(now),
          durationSeconds: Value(durationSeconds),
          overallScore: Value(score),
          notes: Value(isCorrect ? 'Correct form' : 'Needs improvement'),
          syncStatus: const Value('pending'),
        ),
      );

      // Insert exercise result
      final resultId = await repository.saveAnalysisResult(
        sessionId: sessionId,
        exerciseId: exerciseName.toLowerCase().replaceAll(' ', '_'),
        exerciseName: exerciseName,
        score: score,
        isCorrect: isCorrect,
        feedback: feedback,
        textReport: textReport,
        durationSeconds: durationSeconds,
      );

      debugPrint('Analysis result saved: $resultId');
      return resultId;
    } catch (e, stack) {
      debugPrint('Failed to save analysis result: $e\n$stack');
      return null;
    }
  }
}
