/// Unit tests for Exercise Results Repository.
///
/// Test coverage:
/// 1. Save analysis result
/// 2. Get recent results
/// 3. Get by ID
/// 4. Watch all results stream
/// 5. Get stats
/// 6. Parse feedback JSON
library;

import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:orthosense/core/database/app_database.dart';
import 'package:orthosense/core/database/repositories/exercise_results_repository.dart';
import 'package:orthosense/core/providers/database_provider.dart';

// Mock classes
class MockAppDatabase extends Mock implements AppDatabase {}

class MockExerciseResult extends Mock implements ExerciseResult {}

class MockExerciseStats extends Mock implements ExerciseStats {}

// Fake classes for fallback values
class FakeExerciseResultsCompanion extends Fake
    implements ExerciseResultsCompanion {}

void main() {
  late MockAppDatabase mockDatabase;
  late ExerciseResultsRepository repository;
  late ProviderContainer container;

  setUpAll(() {
    registerFallbackValue(FakeExerciseResultsCompanion());
  });

  setUp(() {
    mockDatabase = MockAppDatabase();
    repository = ExerciseResultsRepository(mockDatabase);

    container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(mockDatabase),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  group('ExerciseResultsRepository Provider', () {
    test('provider creates repository with database', () {
      final repo = container.read(exerciseResultsRepositoryProvider);
      expect(repo, isA<ExerciseResultsRepository>());
    });
  });

  group('saveAnalysisResult', () {
    test('saves result and returns ID', () async {
      when(
        () => mockDatabase.insertExerciseResult(any()),
      ).thenAnswer((_) async => 1);

      final resultId = await repository.saveAnalysisResult(
        sessionId: 'session-123',
        exerciseId: 'deep_squat',
        exerciseName: 'Deep Squat',
        score: 85,
        isCorrect: true,
        feedback: {'knees': true, 'back': false},
        textReport: 'Good form overall',
        durationSeconds: 120,
      );

      expect(resultId, isNotEmpty);
      verify(() => mockDatabase.insertExerciseResult(any())).called(1);
    });

    test('generates unique UUID for each save', () async {
      when(
        () => mockDatabase.insertExerciseResult(any()),
      ).thenAnswer((_) async => 1);

      final id1 = await repository.saveAnalysisResult(
        sessionId: 'session-1',
        exerciseId: 'squat',
        exerciseName: 'Squat',
        score: 80,
        isCorrect: true,
        feedback: {},
        textReport: '',
        durationSeconds: 60,
      );

      final id2 = await repository.saveAnalysisResult(
        sessionId: 'session-2',
        exerciseId: 'squat',
        exerciseName: 'Squat',
        score: 90,
        isCorrect: true,
        feedback: {},
        textReport: '',
        durationSeconds: 60,
      );

      expect(id1, isNot(equals(id2)));
    });

    test('encodes feedback as JSON', () async {
      ExerciseResultsCompanion? capturedCompanion;

      when(
        () => mockDatabase.insertExerciseResult(any()),
      ).thenAnswer((invocation) async {
        capturedCompanion =
            invocation.positionalArguments[0] as ExerciseResultsCompanion;
      });

      await repository.saveAnalysisResult(
        sessionId: 'session-1',
        exerciseId: 'squat',
        exerciseName: 'Squat',
        score: 85,
        isCorrect: true,
        feedback: {'kneeValgus': true, 'backArch': false},
        textReport: 'Test report',
        durationSeconds: 100,
      );

      expect(capturedCompanion, isNotNull);
      final feedbackJson = capturedCompanion!.feedbackJson.value;
      expect(feedbackJson, isNotNull);
      final decoded = jsonDecode(feedbackJson!);
      expect(decoded['kneeValgus'], isTrue);
      expect(decoded['backArch'], isFalse);
    });
  });

  group('getRecent', () {
    test('returns list of recent results', () async {
      final mockResults = <ExerciseResult>[
        _createMockResult('id1', 'Squat', 85),
        _createMockResult('id2', 'Hurdle Step', 90),
      ];

      when(
        () => mockDatabase.getRecentExerciseResults(limit: any(named: 'limit')),
      ).thenAnswer((_) async => mockResults);

      final results = await repository.getRecent(limit: 10);

      expect(results.length, equals(2));
      verify(
        () => mockDatabase.getRecentExerciseResults(limit: 10),
      ).called(1);
    });

    test('uses default limit of 20', () async {
      when(
        () => mockDatabase.getRecentExerciseResults(limit: any(named: 'limit')),
      ).thenAnswer((_) async => []);

      await repository.getRecent();

      verify(
        () => mockDatabase.getRecentExerciseResults(limit: 20),
      ).called(1);
    });

    test('returns empty list when no results', () async {
      when(
        () => mockDatabase.getRecentExerciseResults(limit: any(named: 'limit')),
      ).thenAnswer((_) async => []);

      final results = await repository.getRecent();

      expect(results, isEmpty);
    });
  });

  group('getById', () {
    test('returns result when found', () async {
      final mockResult = _createMockResult('id-123', 'Squat', 85);

      when(
        () => mockDatabase.getExerciseResult(any()),
      ).thenAnswer((_) async => mockResult);

      final result = await repository.getById('id-123');

      expect(result, isNotNull);
      verify(() => mockDatabase.getExerciseResult('id-123')).called(1);
    });

    test('returns null when not found', () async {
      when(
        () => mockDatabase.getExerciseResult(any()),
      ).thenAnswer((_) async => null);

      final result = await repository.getById('non-existent');

      expect(result, isNull);
    });
  });

  group('watchAll', () {
    test('returns stream from database', () async {
      when(() => mockDatabase.watchAllExerciseResults()).thenAnswer(
        (_) => Stream.value([]),
      );

      final stream = repository.watchAll();

      expect(stream, isA<Stream<List<ExerciseResult>>>());
      verify(() => mockDatabase.watchAllExerciseResults()).called(1);
    });

    test('stream emits updates', () async {
      final controller = Stream.value(<ExerciseResult>[
        _createMockResult('id1', 'Squat', 80),
      ]);

      when(() => mockDatabase.watchAllExerciseResults()).thenAnswer(
        (_) => controller,
      );

      final stream = repository.watchAll();
      final results = await stream.first;

      expect(results.length, equals(1));
    });
  });

  group('getStats', () {
    test('returns stats from database', () async {
      final mockStats = MockExerciseStats();
      when(() => mockStats.totalSessions).thenReturn(50);
      when(() => mockStats.thisWeekSessions).thenReturn(5);
      when(() => mockStats.averageScore).thenReturn(85);
      when(() => mockStats.correctPercentage).thenReturn(78);

      when(() => mockDatabase.getExerciseStats()).thenAnswer(
        (_) async => mockStats,
      );

      final stats = await repository.getStats();

      expect(stats.totalSessions, equals(50));
      expect(stats.thisWeekSessions, equals(5));
    });
  });

  group('parseFeedback', () {
    test('parses valid JSON string', () {
      final feedbackJson = '{"kneeValgus": true, "backArch": false}';

      final parsed = ExerciseResultsRepository.parseFeedback(feedbackJson);

      expect(parsed['kneeValgus'], isTrue);
      expect(parsed['backArch'], isFalse);
    });

    test('returns empty map for null', () {
      final parsed = ExerciseResultsRepository.parseFeedback(null);

      expect(parsed, isEmpty);
    });

    test('returns empty map for empty string', () {
      final parsed = ExerciseResultsRepository.parseFeedback('');

      expect(parsed, isEmpty);
    });

    test('returns empty map for invalid JSON', () {
      final parsed = ExerciseResultsRepository.parseFeedback('not valid json');

      expect(parsed, isEmpty);
    });

    test('handles nested JSON', () {
      final feedbackJson =
          '{"errors": {"kneeValgus": {"count": 3, "severity": "high"}}}';

      final parsed = ExerciseResultsRepository.parseFeedback(feedbackJson);

      expect(parsed['errors'], isA<Map<dynamic, dynamic>>());
      expect((parsed['errors'] as Map<dynamic, dynamic>)['kneeValgus'], isA<Map<dynamic, dynamic>>());
    });
  });

  group('Data Integrity', () {
    test('preserves score value exactly', () async {
      ExerciseResultsCompanion? capturedCompanion;

      when(
        () => mockDatabase.insertExerciseResult(any()),
      ).thenAnswer((invocation) async {
        capturedCompanion =
            invocation.positionalArguments[0] as ExerciseResultsCompanion;
      });

      const expectedScore = 87;
      await repository.saveAnalysisResult(
        sessionId: 'session-1',
        exerciseId: 'squat',
        exerciseName: 'Squat',
        score: expectedScore,
        isCorrect: true,
        feedback: {},
        textReport: '',
        durationSeconds: 60,
      );

      expect(capturedCompanion!.score.value, equals(expectedScore));
    });

    test('preserves isCorrect flag', () async {
      ExerciseResultsCompanion? capturedCompanion;

      when(
        () => mockDatabase.insertExerciseResult(any()),
      ).thenAnswer((invocation) async {
        capturedCompanion =
            invocation.positionalArguments[0] as ExerciseResultsCompanion;
      });

      await repository.saveAnalysisResult(
        sessionId: 'session-1',
        exerciseId: 'squat',
        exerciseName: 'Squat',
        score: 50,
        isCorrect: false, // Important: false
        feedback: {'error': true},
        textReport: 'Needs improvement',
        durationSeconds: 60,
      );

      expect(capturedCompanion!.isCorrect.value, isFalse);
    });

    test('sets syncStatus to pending', () async {
      ExerciseResultsCompanion? capturedCompanion;

      when(
        () => mockDatabase.insertExerciseResult(any()),
      ).thenAnswer((invocation) async {
        capturedCompanion =
            invocation.positionalArguments[0] as ExerciseResultsCompanion;
      });

      await repository.saveAnalysisResult(
        sessionId: 'session-1',
        exerciseId: 'squat',
        exerciseName: 'Squat',
        score: 80,
        isCorrect: true,
        feedback: {},
        textReport: '',
        durationSeconds: 60,
      );

      expect(capturedCompanion!.syncStatus.value, equals('pending'));
    });
  });
}

/// Helper to create mock ExerciseResult.
ExerciseResult _createMockResult(String id, String name, int score) {
  return ExerciseResult(
    id: id,
    sessionId: 'session-$id',
    exerciseId: name.toLowerCase().replaceAll(' ', '_'),
    exerciseName: name,
    setsCompleted: 3,
    repsCompleted: 10,
    score: score,
    isCorrect: score >= 70,
    feedbackJson: '{}',
    textReport: 'Test report',
    durationSeconds: 60,
    performedAt: DateTime.now(),
    syncStatus: 'synced',
  );
}
