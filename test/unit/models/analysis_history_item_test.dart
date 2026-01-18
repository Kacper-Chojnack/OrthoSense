/// Unit tests for AnalysisHistoryItem model.
///
/// Test coverage:
/// 1. AnalysisHistoryItem construction
/// 2. Default values
/// 3. Factory methods
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:orthosense/features/exercise/presentation/screens/analysis_history_screen.dart';

void main() {
  group('AnalysisHistoryItem', () {
    group('constructor', () {
      test('creates instance with required parameters', () {
        final item = AnalysisHistoryItem(
          id: 'test-id-123',
          exerciseName: 'Squat',
          date: DateTime(2024, 1, 15, 10, 30),
          score: 85,
          isCorrect: true,
        );

        expect(item.id, equals('test-id-123'));
        expect(item.exerciseName, equals('Squat'));
        expect(item.date, equals(DateTime(2024, 1, 15, 10, 30)));
        expect(item.score, equals(85));
        expect(item.isCorrect, isTrue);
      });

      test('has default null feedbackText', () {
        final item = AnalysisHistoryItem(
          id: 'id',
          exerciseName: 'Exercise',
          date: DateTime.now(),
          score: 0,
          isCorrect: false,
        );

        expect(item.feedbackText, isNull);
      });

      test('has default empty feedback map', () {
        final item = AnalysisHistoryItem(
          id: 'id',
          exerciseName: 'Exercise',
          date: DateTime.now(),
          score: 0,
          isCorrect: false,
        );

        expect(item.feedback, isEmpty);
        expect(item.feedback, isA<Map<String, dynamic>>());
      });

      test('has default durationSeconds of 0', () {
        final item = AnalysisHistoryItem(
          id: 'id',
          exerciseName: 'Exercise',
          date: DateTime.now(),
          score: 0,
          isCorrect: false,
        );

        expect(item.durationSeconds, equals(0));
      });

      test('accepts custom feedbackText', () {
        final item = AnalysisHistoryItem(
          id: 'id',
          exerciseName: 'Exercise',
          date: DateTime.now(),
          score: 90,
          isCorrect: true,
          feedbackText: 'Great form! Keep your back straight.',
        );

        expect(
          item.feedbackText,
          equals('Great form! Keep your back straight.'),
        );
      });

      test('accepts custom feedback map', () {
        final item = AnalysisHistoryItem(
          id: 'id',
          exerciseName: 'Exercise',
          date: DateTime.now(),
          score: 75,
          isCorrect: true,
          feedback: {
            'posture': 'good',
            'depth': 'needs improvement',
          },
        );

        expect(item.feedback['posture'], equals('good'));
        expect(item.feedback['depth'], equals('needs improvement'));
      });

      test('accepts custom durationSeconds', () {
        final item = AnalysisHistoryItem(
          id: 'id',
          exerciseName: 'Exercise',
          date: DateTime.now(),
          score: 80,
          isCorrect: true,
          durationSeconds: 120,
        );

        expect(item.durationSeconds, equals(120));
      });
    });

    group('score values', () {
      test('handles score of 0', () {
        final item = AnalysisHistoryItem(
          id: 'id',
          exerciseName: 'Exercise',
          date: DateTime.now(),
          score: 0,
          isCorrect: false,
        );

        expect(item.score, equals(0));
      });

      test('handles perfect score of 100', () {
        final item = AnalysisHistoryItem(
          id: 'id',
          exerciseName: 'Exercise',
          date: DateTime.now(),
          score: 100,
          isCorrect: true,
        );

        expect(item.score, equals(100));
      });

      test('handles mid-range score', () {
        final item = AnalysisHistoryItem(
          id: 'id',
          exerciseName: 'Exercise',
          date: DateTime.now(),
          score: 50,
          isCorrect: true,
        );

        expect(item.score, equals(50));
      });
    });

    group('isCorrect values', () {
      test('handles true value', () {
        final item = AnalysisHistoryItem(
          id: 'id',
          exerciseName: 'Exercise',
          date: DateTime.now(),
          score: 80,
          isCorrect: true,
        );

        expect(item.isCorrect, isTrue);
      });

      test('handles false value', () {
        final item = AnalysisHistoryItem(
          id: 'id',
          exerciseName: 'Exercise',
          date: DateTime.now(),
          score: 30,
          isCorrect: false,
        );

        expect(item.isCorrect, isFalse);
      });
    });

    group('exerciseName variations', () {
      test('handles Squat exercise', () {
        final item = AnalysisHistoryItem(
          id: 'id',
          exerciseName: 'Squat',
          date: DateTime.now(),
          score: 85,
          isCorrect: true,
        );

        expect(item.exerciseName, equals('Squat'));
      });

      test('handles Deadlift exercise', () {
        final item = AnalysisHistoryItem(
          id: 'id',
          exerciseName: 'Deadlift',
          date: DateTime.now(),
          score: 75,
          isCorrect: true,
        );

        expect(item.exerciseName, equals('Deadlift'));
      });

      test('handles Bench Press exercise', () {
        final item = AnalysisHistoryItem(
          id: 'id',
          exerciseName: 'Bench Press',
          date: DateTime.now(),
          score: 90,
          isCorrect: true,
        );

        expect(item.exerciseName, equals('Bench Press'));
      });

      test('handles unknown exercise', () {
        final item = AnalysisHistoryItem(
          id: 'id',
          exerciseName: 'Unknown Exercise',
          date: DateTime.now(),
          score: 60,
          isCorrect: true,
        );

        expect(item.exerciseName, equals('Unknown Exercise'));
      });

      test('handles empty exercise name', () {
        final item = AnalysisHistoryItem(
          id: 'id',
          exerciseName: '',
          date: DateTime.now(),
          score: 0,
          isCorrect: false,
        );

        expect(item.exerciseName, isEmpty);
      });
    });

    group('date variations', () {
      test('handles past date', () {
        final pastDate = DateTime(2023, 6, 15);
        final item = AnalysisHistoryItem(
          id: 'id',
          exerciseName: 'Exercise',
          date: pastDate,
          score: 80,
          isCorrect: true,
        );

        expect(item.date, equals(pastDate));
        expect(item.date.isBefore(DateTime.now()), isTrue);
      });

      test('handles today', () {
        final today = DateTime.now();
        final item = AnalysisHistoryItem(
          id: 'id',
          exerciseName: 'Exercise',
          date: today,
          score: 80,
          isCorrect: true,
        );

        expect(item.date.year, equals(today.year));
        expect(item.date.month, equals(today.month));
        expect(item.date.day, equals(today.day));
      });

      test('handles specific time', () {
        final specificTime = DateTime(2024, 3, 20, 14, 30, 45);
        final item = AnalysisHistoryItem(
          id: 'id',
          exerciseName: 'Exercise',
          date: specificTime,
          score: 80,
          isCorrect: true,
        );

        expect(item.date.hour, equals(14));
        expect(item.date.minute, equals(30));
        expect(item.date.second, equals(45));
      });
    });

    group('durationSeconds', () {
      test('handles short duration', () {
        final item = AnalysisHistoryItem(
          id: 'id',
          exerciseName: 'Exercise',
          date: DateTime.now(),
          score: 80,
          isCorrect: true,
          durationSeconds: 30,
        );

        expect(item.durationSeconds, equals(30));
      });

      test('handles long duration', () {
        final item = AnalysisHistoryItem(
          id: 'id',
          exerciseName: 'Exercise',
          date: DateTime.now(),
          score: 80,
          isCorrect: true,
          durationSeconds: 3600, // 1 hour
        );

        expect(item.durationSeconds, equals(3600));
      });

      test('duration can be converted to minutes', () {
        final item = AnalysisHistoryItem(
          id: 'id',
          exerciseName: 'Exercise',
          date: DateTime.now(),
          score: 80,
          isCorrect: true,
          durationSeconds: 150,
        );

        final minutes = item.durationSeconds ~/ 60;
        final seconds = item.durationSeconds % 60;

        expect(minutes, equals(2));
        expect(seconds, equals(30));
      });
    });

    group('feedback map', () {
      test('handles empty feedback', () {
        final item = AnalysisHistoryItem(
          id: 'id',
          exerciseName: 'Exercise',
          date: DateTime.now(),
          score: 80,
          isCorrect: true,
          feedback: const {},
        );

        expect(item.feedback.isEmpty, isTrue);
      });

      test('handles single feedback entry', () {
        final item = AnalysisHistoryItem(
          id: 'id',
          exerciseName: 'Exercise',
          date: DateTime.now(),
          score: 80,
          isCorrect: true,
          feedback: const {'key': 'value'},
        );

        expect(item.feedback.length, equals(1));
        expect(item.feedback['key'], equals('value'));
      });

      test('handles multiple feedback entries', () {
        final item = AnalysisHistoryItem(
          id: 'id',
          exerciseName: 'Exercise',
          date: DateTime.now(),
          score: 80,
          isCorrect: true,
          feedback: const {
            'posture': 'good',
            'timing': 'excellent',
            'form': 'needs work',
          },
        );

        expect(item.feedback.length, equals(3));
      });

      test('handles nested feedback', () {
        final item = AnalysisHistoryItem(
          id: 'id',
          exerciseName: 'Exercise',
          date: DateTime.now(),
          score: 80,
          isCorrect: true,
          feedback: const {
            'details': {
              'angle': 90,
              'direction': 'up',
            },
          },
        );

        expect(item.feedback['details'], isA<Map>());
      });

      test('handles numeric feedback values', () {
        final item = AnalysisHistoryItem(
          id: 'id',
          exerciseName: 'Exercise',
          date: DateTime.now(),
          score: 80,
          isCorrect: true,
          feedback: const {
            'angle': 45.5,
            'repetitions': 10,
          },
        );

        expect(item.feedback['angle'], equals(45.5));
        expect(item.feedback['repetitions'], equals(10));
      });

      test('handles list feedback values', () {
        final item = AnalysisHistoryItem(
          id: 'id',
          exerciseName: 'Exercise',
          date: DateTime.now(),
          score: 80,
          isCorrect: true,
          feedback: const {
            'corrections': ['Keep back straight', 'Lower deeper'],
          },
        );

        expect(item.feedback['corrections'], isA<List>());
        expect((item.feedback['corrections'] as List).length, equals(2));
      });
    });

    group('id format', () {
      test('handles UUID format', () {
        final item = AnalysisHistoryItem(
          id: '550e8400-e29b-41d4-a716-446655440000',
          exerciseName: 'Exercise',
          date: DateTime.now(),
          score: 80,
          isCorrect: true,
        );

        expect(item.id.contains('-'), isTrue);
        expect(item.id.length, equals(36));
      });

      test('handles simple numeric id', () {
        final item = AnalysisHistoryItem(
          id: '12345',
          exerciseName: 'Exercise',
          date: DateTime.now(),
          score: 80,
          isCorrect: true,
        );

        expect(item.id, equals('12345'));
      });

      test('handles empty id', () {
        final item = AnalysisHistoryItem(
          id: '',
          exerciseName: 'Exercise',
          date: DateTime.now(),
          score: 80,
          isCorrect: true,
        );

        expect(item.id, isEmpty);
      });
    });
  });
}
