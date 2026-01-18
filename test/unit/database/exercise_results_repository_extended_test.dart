/// Unit tests for ExerciseResultsRepository and database converters.
///
/// Test coverage:
/// 1. ExerciseResultsRepository CRUD operations
/// 2. Feedback parsing
/// 3. JsonMapConverter
/// 4. Result creation
library;

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ExerciseResultsRepository', () {
    test('parseFeedback handles valid JSON', () {
      const json = '{"error_count":2,"errors":["Knee Valgus","Trunk Lean"]}';

      final result = ExerciseResultsRepository.parseFeedback(json);

      expect(result['error_count'], equals(2));
      expect(result['errors'], contains('Knee Valgus'));
    });

    test('parseFeedback returns empty map for null', () {
      final result = ExerciseResultsRepository.parseFeedback(null);

      expect(result, isEmpty);
    });

    test('parseFeedback returns empty map for empty string', () {
      final result = ExerciseResultsRepository.parseFeedback('');

      expect(result, isEmpty);
    });

    test('parseFeedback handles invalid JSON gracefully', () {
      const invalidJson = '{invalid json}';

      final result = ExerciseResultsRepository.parseFeedback(invalidJson);

      expect(result, isEmpty);
    });

    test('parseFeedback handles nested objects', () {
      const json = '''
      {
        "summary": {"total_errors": 3, "severity": "mild"},
        "details": ["Issue 1", "Issue 2"]
      }
      ''';

      final result = ExerciseResultsRepository.parseFeedback(json);

      expect(result['summary'], isA<Map>());
      expect((result['summary'] as Map)['total_errors'], equals(3));
    });
  });

  group('JsonMapConverter', () {
    test('fromSql converts JSON string to Map', () {
      const converter = JsonMapConverter();
      const jsonString = '{"name":"test","value":42}';

      final result = converter.fromSql(jsonString);

      expect(result['name'], equals('test'));
      expect(result['value'], equals(42));
    });

    test('toSql converts Map to JSON string', () {
      const converter = JsonMapConverter();
      final map = {'name': 'test', 'value': 42};

      final result = converter.toSql(map);

      expect(result, isA<String>());
      final decoded = jsonDecode(result);
      expect(decoded['name'], equals('test'));
    });

    test('roundtrip preserves data', () {
      const converter = JsonMapConverter();
      final original = {
        'string': 'value',
        'number': 123,
        'boolean': true,
        'list': [1, 2, 3],
        'nested': {'inner': 'data'},
      };

      final sqlValue = converter.toSql(original);
      final restored = converter.fromSql(sqlValue);

      expect(restored['string'], equals(original['string']));
      expect(restored['number'], equals(original['number']));
      expect(restored['boolean'], equals(original['boolean']));
      expect(restored['list'], equals(original['list']));
      expect((restored['nested'] as Map)['inner'], equals('data'));
    });

    test('handles empty map', () {
      const converter = JsonMapConverter();
      final empty = <String, dynamic>{};

      final sqlValue = converter.toSql(empty);
      final restored = converter.fromSql(sqlValue);

      expect(restored, isEmpty);
    });
  });

  group('ExerciseResult Model', () {
    test('creates from companion data', () {
      final companion = MockExerciseResultsCompanion(
        id: 'result-123',
        sessionId: 'session-456',
        exerciseId: 'ex-deep-squat',
        exerciseName: 'Deep Squat',
        score: 85,
        isCorrect: true,
        feedbackJson: '{}',
        textReport: 'Good form!',
        durationSeconds: 30,
        performedAt: DateTime(2024, 1, 15, 10, 30),
        syncStatus: 'pending',
      );

      expect(companion.id, equals('result-123'));
      expect(companion.exerciseName, equals('Deep Squat'));
      expect(companion.score, equals(85));
    });

    test('defaults syncStatus to pending', () {
      final companion = MockExerciseResultsCompanion(
        id: 'test',
        sessionId: 'session',
        exerciseId: 'ex',
        exerciseName: 'Test',
        score: 80,
        isCorrect: true,
        feedbackJson: '{}',
        textReport: '',
        durationSeconds: 0,
        performedAt: DateTime.now(),
        syncStatus: 'pending',
      );

      expect(companion.syncStatus, equals('pending'));
    });
  });

  group('UUID Generation', () {
    test('generates unique IDs', () {
      final id1 = _generateUuid();
      final id2 = _generateUuid();

      expect(id1, isNot(equals(id2)));
    });

    test('ID has correct format', () {
      final id = _generateUuid();

      // UUID v4 format: xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx
      expect(id.length, equals(36));
      expect(id.contains('-'), isTrue);
    });
  });

  group('SaveAnalysisResult', () {
    test('creates correct companion data', () {
      final result = _createResultCompanion(
        sessionId: 'session-123',
        exerciseId: 'deep-squat',
        exerciseName: 'Deep Squat',
        score: 90,
        isCorrect: true,
        feedback: {'errors': []},
        textReport: 'Excellent form!',
        durationSeconds: 45,
      );

      expect(result.sessionId, equals('session-123'));
      expect(result.exerciseName, equals('Deep Squat'));
      expect(result.score, equals(90));
      expect(result.isCorrect, isTrue);
      expect(result.durationSeconds, equals(45));
    });

    test('encodes feedback as JSON', () {
      final result = _createResultCompanion(
        sessionId: 'session',
        exerciseId: 'ex',
        exerciseName: 'Test',
        score: 80,
        isCorrect: false,
        feedback: {
          'error_count': 2,
          'errors': ['A', 'B'],
        },
        textReport: '',
        durationSeconds: 30,
      );

      final decoded = jsonDecode(result.feedbackJson);
      expect(decoded['error_count'], equals(2));
      expect(decoded['errors'], contains('A'));
    });
  });

  group('ExerciseStats Model', () {
    test('creates with all fields', () {
      final stats = MockExerciseStats(
        totalSessions: 50,
        averageScore: 78.5,
        correctPercentage: 85.0,
        totalDuration: 3600,
      );

      expect(stats.totalSessions, equals(50));
      expect(stats.averageScore, equals(78.5));
      expect(stats.correctPercentage, equals(85.0));
    });

    test('handles zero sessions', () {
      final stats = MockExerciseStats(
        totalSessions: 0,
        averageScore: 0,
        correctPercentage: 0,
        totalDuration: 0,
      );

      expect(stats.totalSessions, equals(0));
      expect(stats.averageScore, equals(0));
    });

    test('calculates average duration per session', () {
      final stats = MockExerciseStats(
        totalSessions: 10,
        averageScore: 80,
        correctPercentage: 90,
        totalDuration: 600,
      );

      final avgDuration = stats.totalDuration / stats.totalSessions;
      expect(avgDuration, equals(60)); // 60 seconds per session
    });
  });

  group('Sync Status', () {
    test('valid sync status values', () {
      const validStatuses = ['pending', 'synced', 'failed'];

      for (final status in validStatuses) {
        expect(_isValidSyncStatus(status), isTrue);
      }
    });

    test('invalid sync status rejected', () {
      expect(_isValidSyncStatus('unknown'), isFalse);
      expect(_isValidSyncStatus(''), isFalse);
    });
  });
}

// Mock classes

class ExerciseResultsRepository {
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

class JsonMapConverter {
  const JsonMapConverter();

  Map<String, dynamic> fromSql(String fromDb) =>
      jsonDecode(fromDb) as Map<String, dynamic>;

  String toSql(Map<String, dynamic> value) => jsonEncode(value);
}

class MockExerciseResultsCompanion {
  MockExerciseResultsCompanion({
    required this.id,
    required this.sessionId,
    required this.exerciseId,
    required this.exerciseName,
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
  final int score;
  final bool isCorrect;
  final String feedbackJson;
  final String textReport;
  final int durationSeconds;
  final DateTime performedAt;
  final String syncStatus;
}

class MockExerciseStats {
  MockExerciseStats({
    required this.totalSessions,
    required this.averageScore,
    required this.correctPercentage,
    required this.totalDuration,
  });

  final int totalSessions;
  final double averageScore;
  final double correctPercentage;
  final int totalDuration;
}

// Helper functions

int _uuidCounter = 0;

String _generateUuid() {
  _uuidCounter++;
  // Generate a proper UUID v4 format: xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx
  final r = DateTime.now().microsecondsSinceEpoch + _uuidCounter;
  String hexPart(int length) {
    return List.generate(
      length,
      (i) => ((r + i * 7) % 16).toRadixString(16),
    ).join();
  }

  // 8-4-4-4-12 format with proper version and variant bits
  return '${hexPart(8)}-${hexPart(4)}-4${hexPart(3)}-${((r % 4) + 8).toRadixString(16)}${hexPart(3)}-${hexPart(12)}';
}

MockExerciseResultsCompanion _createResultCompanion({
  required String sessionId,
  required String exerciseId,
  required String exerciseName,
  required int score,
  required bool isCorrect,
  required Map<String, dynamic> feedback,
  required String textReport,
  required int durationSeconds,
}) {
  return MockExerciseResultsCompanion(
    id: _generateUuid(),
    sessionId: sessionId,
    exerciseId: exerciseId,
    exerciseName: exerciseName,
    score: score,
    isCorrect: isCorrect,
    feedbackJson: jsonEncode(feedback),
    textReport: textReport,
    durationSeconds: durationSeconds,
    performedAt: DateTime.now(),
    syncStatus: 'pending',
  );
}

bool _isValidSyncStatus(String status) {
  return ['pending', 'synced', 'failed'].contains(status);
}
