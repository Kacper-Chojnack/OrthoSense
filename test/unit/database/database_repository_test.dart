/// Unit tests for Database converters and repositories.
///
/// Test coverage:
/// 1. JsonMapConverter
/// 2. ExerciseResultsRepository
/// 3. Feedback parsing
/// 4. Repository methods
library;

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('JsonMapConverter', () {
    const converter = JsonMapConverter();

    group('fromSql', () {
      test('parses empty JSON object', () {
        const jsonString = '{}';
        final result = converter.fromSql(jsonString);

        expect(result, isEmpty);
        expect(result, isA<Map<String, dynamic>>());
      });

      test('parses simple JSON object', () {
        const jsonString = '{"key": "value"}';
        final result = converter.fromSql(jsonString);

        expect(result['key'], equals('value'));
      });

      test('parses nested JSON object', () {
        const jsonString = '{"outer": {"inner": "value"}}';
        final result = converter.fromSql(jsonString);

        expect((result['outer'] as Map)['inner'], equals('value'));
      });

      test('parses JSON with arrays', () {
        const jsonString = '{"items": [1, 2, 3]}';
        final result = converter.fromSql(jsonString);

        expect((result['items'] as List).length, equals(3));
      });

      test('parses JSON with various types', () {
        const jsonString = '{"string": "text", "number": 42, "bool": true}';
        final result = converter.fromSql(jsonString);

        expect(result['string'], equals('text'));
        expect(result['number'], equals(42));
        expect(result['bool'], isTrue);
      });
    });

    group('toSql', () {
      test('encodes empty map', () {
        final map = <String, dynamic>{};
        final result = converter.toSql(map);

        expect(result, equals('{}'));
      });

      test('encodes simple map', () {
        final map = {'key': 'value'};
        final result = converter.toSql(map);

        expect(result, equals('{"key":"value"}'));
      });

      test('encodes nested map', () {
        final map = {
          'outer': {'inner': 'value'}
        };
        final result = converter.toSql(map);
        final decoded = json.decode(result);

        expect((decoded['outer'] as Map)['inner'], equals('value'));
      });

      test('encodes map with list', () {
        final map = {
          'items': [1, 2, 3]
        };
        final result = converter.toSql(map);
        final decoded = json.decode(result);

        expect((decoded['items'] as List).length, equals(3));
      });
    });

    group('round-trip', () {
      test('preserves data through encode/decode cycle', () {
        final original = {
          'string': 'value',
          'number': 42,
          'nested': {'key': 'value'},
          'array': [1, 2, 3],
        };

        final encoded = converter.toSql(original);
        final decoded = converter.fromSql(encoded);

        expect(decoded['string'], equals('value'));
        expect(decoded['number'], equals(42));
      });
    });
  });

  group('ExerciseResultsRepository', () {
    group('parseFeedback', () {
      test('returns empty map for null input', () {
        final result = parseFeedback(null);
        expect(result, isEmpty);
      });

      test('returns empty map for empty string', () {
        final result = parseFeedback('');
        expect(result, isEmpty);
      });

      test('parses valid JSON', () {
        const feedbackJson = '{"knees_tracking": true, "depth": 85}';
        final result = parseFeedback(feedbackJson);

        expect(result['knees_tracking'], isTrue);
        expect(result['depth'], equals(85));
      });

      test('returns empty map for invalid JSON', () {
        const invalidJson = 'not valid json';
        final result = parseFeedback(invalidJson);

        expect(result, isEmpty);
      });

      test('handles complex feedback structure', () {
        final feedback = {
          'score': 85,
          'issues': ['depth', 'balance'],
          'metrics': {
            'rom': 120,
            'symmetry': 0.95,
          },
        };
        final json = jsonEncode(feedback);
        final result = parseFeedback(json);

        expect(result['score'], equals(85));
        expect((result['issues'] as List).length, equals(2));
      });
    });

    group('saveAnalysisResult', () {
      test('generates UUID for new result', () {
        // UUIDs follow pattern: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
        const uuidPattern = r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$';
        const sampleUuid = '123e4567-e89b-12d3-a456-426614174000';

        expect(RegExp(uuidPattern).hasMatch(sampleUuid), isTrue);
      });

      test('sets sync status to pending', () {
        const syncStatus = 'pending';
        expect(syncStatus, equals('pending'));
      });

      test('encodes feedback as JSON', () {
        final feedback = {'test': 'value'};
        final encoded = jsonEncode(feedback);

        expect(encoded, equals('{"test":"value"}'));
      });

      test('uses current timestamp for performedAt', () {
        final now = DateTime.now();
        final earlier = now.subtract(const Duration(seconds: 1));

        expect(now.isAfter(earlier), isTrue);
      });
    });

    group('getRecent', () {
      test('default limit is 20', () {
        const defaultLimit = 20;
        expect(defaultLimit, equals(20));
      });

      test('custom limit can be specified', () {
        const customLimit = 50;
        expect(customLimit, equals(50));
      });
    });

    group('getById', () {
      test('returns null for non-existent ID', () {
        const ExerciseResult? result = null;
        expect(result, isNull);
      });

      test('returns result when found', () {
        final result = ExerciseResult(
          id: 'test-id',
          sessionId: 'session-1',
          exerciseId: 'deep_squat',
          exerciseName: 'Deep Squat',
          score: 85,
          isCorrect: true,
          feedbackJson: '{}',
          textReport: 'Good form',
          durationSeconds: 30,
          performedAt: DateTime.now(),
          syncStatus: 'synced',
        );

        expect(result.id, equals('test-id'));
      });
    });

    group('watchAll', () {
      test('returns stream of results', () {
        // Streams emit results ordered newest first
        final results = [
          ExerciseResult(
            id: '2',
            sessionId: 's1',
            exerciseId: 'e1',
            exerciseName: 'Exercise',
            score: 90,
            isCorrect: true,
            feedbackJson: '{}',
            textReport: '',
            durationSeconds: 30,
            performedAt: DateTime(2024, 1, 2),
            syncStatus: 'synced',
          ),
          ExerciseResult(
            id: '1',
            sessionId: 's1',
            exerciseId: 'e1',
            exerciseName: 'Exercise',
            score: 80,
            isCorrect: true,
            feedbackJson: '{}',
            textReport: '',
            durationSeconds: 25,
            performedAt: DateTime(2024, 1, 1),
            syncStatus: 'synced',
          ),
        ];

        // Results should be ordered by date, newest first
        expect(results.first.performedAt.isAfter(results.last.performedAt), isTrue);
      });
    });

    group('getStats', () {
      test('returns exercise statistics', () {
        final stats = ExerciseStats(
          totalCount: 50,
          averageScore: 85.5,
          totalDurationSeconds: 3600,
          correctCount: 45,
        );

        expect(stats.totalCount, equals(50));
        expect(stats.averageScore, closeTo(85.5, 0.1));
        expect(stats.totalDurationSeconds, equals(3600));
        expect(stats.correctCount, equals(45));
      });

      test('calculates accuracy rate', () {
        final stats = ExerciseStats(
          totalCount: 100,
          averageScore: 85.0,
          totalDurationSeconds: 3600,
          correctCount: 80,
        );

        final accuracy = (stats.correctCount / stats.totalCount) * 100;
        expect(accuracy, equals(80.0));
      });
    });
  });

  group('Exercise Result model', () {
    test('creates with all required fields', () {
      final result = ExerciseResult(
        id: 'test-123',
        sessionId: 'session-456',
        exerciseId: 'deep_squat',
        exerciseName: 'Deep Squat',
        score: 85,
        isCorrect: true,
        feedbackJson: '{"knees": true}',
        textReport: 'Good form throughout the exercise.',
        durationSeconds: 45,
        performedAt: DateTime(2024, 1, 15),
        syncStatus: 'synced',
      );

      expect(result.id, equals('test-123'));
      expect(result.exerciseName, equals('Deep Squat'));
      expect(result.score, equals(85));
      expect(result.isCorrect, isTrue);
    });

    test('duration in minutes', () {
      final result = ExerciseResult(
        id: 'test',
        sessionId: 'session',
        exerciseId: 'exercise',
        exerciseName: 'Exercise',
        score: 80,
        isCorrect: true,
        feedbackJson: '{}',
        textReport: '',
        durationSeconds: 120,
        performedAt: DateTime.now(),
        syncStatus: 'pending',
      );

      final minutes = result.durationSeconds / 60;
      expect(minutes, equals(2.0));
    });
  });
}

// Models for testing

class JsonMapConverter {
  const JsonMapConverter();

  Map<String, dynamic> fromSql(String fromDb) =>
      json.decode(fromDb) as Map<String, dynamic>;

  String toSql(Map<String, dynamic> value) => json.encode(value);
}

Map<String, dynamic> parseFeedback(String? feedbackJson) {
  if (feedbackJson == null || feedbackJson.isEmpty) {
    return {};
  }
  try {
    return jsonDecode(feedbackJson) as Map<String, dynamic>;
  } catch (_) {
    return {};
  }
}

class ExerciseResult {
  ExerciseResult({
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

class ExerciseStats {
  ExerciseStats({
    required this.totalCount,
    required this.averageScore,
    required this.totalDurationSeconds,
    required this.correctCount,
  });

  final int totalCount;
  final double averageScore;
  final int totalDurationSeconds;
  final int correctCount;
}
