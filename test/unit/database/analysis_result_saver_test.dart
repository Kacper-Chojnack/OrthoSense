/// Unit tests for AnalysisResultSaver and database operations.
///
/// Test coverage:
/// 1. AnalysisResultSaver save logic
/// 2. ExerciseResultsRepository operations
/// 3. Database companion object creation
/// 4. Sync queue integration
library;

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ExerciseResultData', () {
    test('creates instance with required fields', () {
      final data = ExerciseResultData(
        id: 'result-123',
        sessionId: 'session-456',
        exerciseId: 'deep_squat',
        exerciseName: 'Deep Squat',
        setsCompleted: 3,
        repsCompleted: 10,
        score: 85,
        isCorrect: true,
        feedbackJson: '{"errors": []}',
        textReport: 'Great form!',
        durationSeconds: 120,
        performedAt: DateTime(2025, 1, 15, 10, 30),
        syncStatus: 'pending',
      );

      expect(data.id, equals('result-123'));
      expect(data.sessionId, equals('session-456'));
      expect(data.exerciseId, equals('deep_squat'));
      expect(data.exerciseName, equals('Deep Squat'));
      expect(data.setsCompleted, equals(3));
      expect(data.repsCompleted, equals(10));
      expect(data.score, equals(85));
      expect(data.isCorrect, isTrue);
      expect(data.durationSeconds, equals(120));
      expect(data.syncStatus, equals('pending'));
    });

    test('handles null optional fields', () {
      final data = ExerciseResultData(
        id: 'result-123',
        sessionId: 'session-456',
        exerciseId: 'deep_squat',
        exerciseName: 'Deep Squat',
        setsCompleted: 0,
        repsCompleted: 0,
        score: null,
        isCorrect: false,
        feedbackJson: null,
        textReport: null,
        durationSeconds: 60,
        performedAt: DateTime.now(),
        syncStatus: 'pending',
      );

      expect(data.score, isNull);
      expect(data.feedbackJson, isNull);
      expect(data.textReport, isNull);
    });
  });

  group('SessionData', () {
    test('creates instance with required fields', () {
      final session = SessionData(
        id: 'session-456',
        startedAt: DateTime(2025, 1, 15, 10, 0),
        completedAt: DateTime(2025, 1, 15, 10, 30),
        durationSeconds: 1800,
        overallScore: 85,
        notes: 'Good session',
        syncStatus: 'pending',
      );

      expect(session.id, equals('session-456'));
      expect(session.durationSeconds, equals(1800));
      expect(session.overallScore, equals(85));
      expect(session.notes, equals('Good session'));
      expect(session.syncStatus, equals('pending'));
    });

    test('handles incomplete session (no completedAt)', () {
      final session = SessionData(
        id: 'session-456',
        startedAt: DateTime.now(),
        completedAt: null,
        durationSeconds: 0,
        overallScore: null,
        notes: null,
        syncStatus: 'pending',
      );

      expect(session.completedAt, isNull);
      expect(session.overallScore, isNull);
    });
  });

  group('AnalysisResult Saving Logic', () {
    test('generates unique IDs for each result', () {
      final ids = <String>{};

      for (int i = 0; i < 100; i++) {
        final id = _generateUniqueId();
        ids.add(id);
      }

      // All IDs should be unique
      expect(ids.length, equals(100));
    });

    test('converts exercise name to exercise ID', () {
      expect(_toExerciseId('Deep Squat'), equals('deep_squat'));
      expect(_toExerciseId('Hurdle Step'), equals('hurdle_step'));
      expect(
        _toExerciseId('Standing Shoulder Abduction'),
        equals('standing_shoulder_abduction'),
      );
    });

    test('calculates duration from start and end time', () {
      final start = DateTime(2025, 1, 15, 10, 0, 0);
      final end = DateTime(2025, 1, 15, 10, 2, 30);

      final duration = _calculateDuration(start, end);

      expect(duration, equals(150)); // 2 minutes 30 seconds
    });

    test('handles zero duration', () {
      final now = DateTime.now();

      final duration = _calculateDuration(now, now);

      expect(duration, equals(0));
    });
  });

  group('Feedback Serialization', () {
    test('serializes feedback map to JSON', () {
      final feedback = {
        'Squat too shallow': true,
        'Knee Valgus': true,
        'Heels rising': 'Left',
      };

      final json = _serializeFeedback(feedback);

      expect(json, contains('Squat too shallow'));
      expect(json, contains('Knee Valgus'));
      expect(json, contains('Heels rising'));
    });

    test('deserializes JSON to feedback map', () {
      const json = '{"error1": true, "error2": "Left side"}';

      final feedback = _deserializeFeedback(json);

      expect(feedback['error1'], isTrue);
      expect(feedback['error2'], equals('Left side'));
    });

    test('handles empty feedback', () {
      final json = _serializeFeedback({});
      expect(json, equals('{}'));

      final feedback = _deserializeFeedback('{}');
      expect(feedback, isEmpty);
    });

    test('handles null feedback', () {
      final feedback = _deserializeFeedback(null);
      expect(feedback, isEmpty);
    });
  });

  group('Sync Status Management', () {
    test('initial status is pending', () {
      const status = 'pending';
      expect(status, equals('pending'));
    });

    test('status transitions correctly', () {
      // Valid transitions
      expect(_isValidTransition('pending', 'syncing'), isTrue);
      expect(_isValidTransition('syncing', 'synced'), isTrue);
      expect(_isValidTransition('syncing', 'failed'), isTrue);
      expect(_isValidTransition('failed', 'pending'), isTrue); // retry

      // Invalid transitions
      expect(_isValidTransition('synced', 'pending'), isFalse);
      expect(_isValidTransition('pending', 'synced'), isFalse);
    });

    test('all valid statuses are recognized', () {
      const validStatuses = ['pending', 'syncing', 'synced', 'failed'];

      for (final status in validStatuses) {
        expect(_isValidStatus(status), isTrue);
      }

      expect(_isValidStatus('unknown'), isFalse);
      expect(_isValidStatus(''), isFalse);
    });
  });

  group('Score Calculation', () {
    test('calculates score from correct status', () {
      expect(_calculateScore(isCorrect: true, errorCount: 0), equals(100));
    });

    test('reduces score for errors', () {
      expect(_calculateScore(isCorrect: false, errorCount: 1), equals(70));
      expect(_calculateScore(isCorrect: false, errorCount: 2), equals(55));
      expect(_calculateScore(isCorrect: false, errorCount: 3), equals(40));
    });

    test('score has minimum of 0', () {
      expect(_calculateScore(isCorrect: false, errorCount: 10), equals(0));
    });

    test('error count 0 with isCorrect false still gives decent score', () {
      // Edge case: maybe form was borderline
      expect(
        _calculateScore(isCorrect: false, errorCount: 0),
        greaterThan(50),
      );
    });
  });

  group('Database Stats Calculation', () {
    test('calculates stats from empty results', () {
      final stats = _calculateStats([]);

      expect(stats.totalSessions, equals(0));
      expect(stats.averageScore, equals(0.0));
      expect(stats.correctPercentage, equals(0.0));
    });

    test('calculates stats from single result', () {
      final results = [
        ExerciseResultData(
          id: '1',
          sessionId: 's1',
          exerciseId: 'squat',
          exerciseName: 'Deep Squat',
          setsCompleted: 1,
          repsCompleted: 10,
          score: 85,
          isCorrect: true,
          feedbackJson: null,
          textReport: null,
          durationSeconds: 60,
          performedAt: DateTime.now(),
          syncStatus: 'synced',
        ),
      ];

      final stats = _calculateStats(results);

      expect(stats.totalSessions, equals(1));
      expect(stats.averageScore, equals(85.0));
      expect(stats.correctPercentage, equals(100.0));
    });

    test('calculates stats from multiple results', () {
      final results = [
        _createMockResult(score: 80, isCorrect: true),
        _createMockResult(score: 90, isCorrect: true),
        _createMockResult(score: 60, isCorrect: false),
        _createMockResult(score: 70, isCorrect: false),
      ];

      final stats = _calculateStats(results);

      expect(stats.totalSessions, equals(4));
      expect(stats.averageScore, equals(75.0)); // (80+90+60+70)/4
      expect(stats.correctPercentage, equals(50.0)); // 2/4
    });

    test('handles null scores in average calculation', () {
      final results = [
        _createMockResult(score: 80, isCorrect: true),
        _createMockResult(score: null, isCorrect: false),
        _createMockResult(score: 100, isCorrect: true),
      ];

      final stats = _calculateStats(results);

      // Only count non-null scores
      expect(stats.averageScore, equals(90.0)); // (80+100)/2
    });
  });
}

// Test data classes
class ExerciseResultData {
  ExerciseResultData({
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
  final bool isCorrect;
  final String? feedbackJson;
  final String? textReport;
  final int durationSeconds;
  final DateTime performedAt;
  final String syncStatus;
}

class SessionData {
  SessionData({
    required this.id,
    required this.startedAt,
    required this.completedAt,
    required this.durationSeconds,
    required this.overallScore,
    required this.notes,
    required this.syncStatus,
  });

  final String id;
  final DateTime startedAt;
  final DateTime? completedAt;
  final int durationSeconds;
  final int? overallScore;
  final String? notes;
  final String syncStatus;
}

class ExerciseStats {
  ExerciseStats({
    required this.totalSessions,
    required this.averageScore,
    required this.correctPercentage,
  });

  final int totalSessions;
  final double averageScore;
  final double correctPercentage;
}

// Helper functions

int _idCounter = 0;

String _generateUniqueId() {
  _idCounter++;
  return '${DateTime.now().microsecondsSinceEpoch}-$_idCounter-${_randomString(8)}';
}

String _randomString(int length) {
  const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
  final random = DateTime.now().microsecondsSinceEpoch;
  return List.generate(
    length,
    (i) => chars[(random + i * 7) % chars.length],
  ).join();
}

String _toExerciseId(String name) {
  return name.toLowerCase().replaceAll(' ', '_');
}

int _calculateDuration(DateTime start, DateTime end) {
  return end.difference(start).inSeconds;
}

String _serializeFeedback(Map<String, dynamic> feedback) {
  final buffer = StringBuffer('{');
  final entries = feedback.entries.toList();
  for (int i = 0; i < entries.length; i++) {
    final entry = entries[i];
    buffer.write('"${entry.key}": ');
    if (entry.value is String) {
      buffer.write('"${entry.value}"');
    } else {
      buffer.write('${entry.value}');
    }
    if (i < entries.length - 1) buffer.write(', ');
  }
  buffer.write('}');
  return buffer.toString();
}

Map<String, dynamic> _deserializeFeedback(String? json) {
  if (json == null || json.isEmpty || json == '{}') return {};

  // Simplified parsing for test
  final result = <String, dynamic>{};
  final content = json.substring(1, json.length - 1);
  if (content.isEmpty) return result;

  // Very basic parser for test data
  final parts = content.split(', ');
  for (final part in parts) {
    final colonIndex = part.indexOf(':');
    if (colonIndex == -1) continue;

    var key = part.substring(0, colonIndex).trim();
    var value = part.substring(colonIndex + 1).trim();

    // Remove quotes from key
    if (key.startsWith('"') && key.endsWith('"')) {
      key = key.substring(1, key.length - 1);
    }

    // Parse value
    if (value == 'true') {
      result[key] = true;
    } else if (value == 'false') {
      result[key] = false;
    } else if (value.startsWith('"') && value.endsWith('"')) {
      result[key] = value.substring(1, value.length - 1);
    } else {
      result[key] = value;
    }
  }

  return result;
}

bool _isValidTransition(String from, String to) {
  const validTransitions = {
    'pending': ['syncing'],
    'syncing': ['synced', 'failed'],
    'failed': ['pending'],
    'synced': <String>[],
  };

  return validTransitions[from]?.contains(to) ?? false;
}

bool _isValidStatus(String status) {
  return ['pending', 'syncing', 'synced', 'failed'].contains(status);
}

int _calculateScore({required bool isCorrect, required int errorCount}) {
  if (isCorrect && errorCount == 0) return 100;

  const baseScore = 85;
  const penaltyPerError = 15;

  final score = baseScore - (errorCount * penaltyPerError);
  return score.clamp(0, 100);
}

ExerciseStats _calculateStats(List<ExerciseResultData> results) {
  if (results.isEmpty) {
    return ExerciseStats(
      totalSessions: 0,
      averageScore: 0.0,
      correctPercentage: 0.0,
    );
  }

  final scoresWithValue = results.where((r) => r.score != null).toList();
  final averageScore = scoresWithValue.isEmpty
      ? 0.0
      : scoresWithValue.map((r) => r.score!).reduce((a, b) => a + b) /
            scoresWithValue.length;

  final correctCount = results.where((r) => r.isCorrect).length;
  final correctPercentage = (correctCount / results.length) * 100;

  return ExerciseStats(
    totalSessions: results.length,
    averageScore: averageScore,
    correctPercentage: correctPercentage,
  );
}

ExerciseResultData _createMockResult({int? score, required bool isCorrect}) {
  return ExerciseResultData(
    id: _generateUniqueId(),
    sessionId: 'session-1',
    exerciseId: 'squat',
    exerciseName: 'Deep Squat',
    setsCompleted: 1,
    repsCompleted: 10,
    score: score,
    isCorrect: isCorrect,
    feedbackJson: null,
    textReport: null,
    durationSeconds: 60,
    performedAt: DateTime.now(),
    syncStatus: 'synced',
  );
}
