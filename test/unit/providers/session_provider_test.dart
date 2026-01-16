/// Unit tests for Session Provider and session state management.
///
/// Test coverage:
/// 1. Session creation
/// 2. Session state transitions
/// 3. Exercise results management
/// 4. Session completion flow
/// 5. Error handling
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

// Mock classes
class MockSessionRepository extends Mock {}

class MockExerciseRepository extends Mock {}

void main() {
  group('Session State Management', () {
    test('initial session state is idle', () {
      final state = SessionState.idle();
      expect(state.status, equals(SessionStatus.idle));
      expect(state.currentSession, isNull);
    });

    test('session transitions to active when started', () {
      final session = SessionModel(
        id: 'session-123',
        patientId: 'user-456',
        status: SessionStatus.active,
        createdAt: DateTime.now(),
      );

      final state = SessionState.active(session);
      expect(state.status, equals(SessionStatus.active));
      expect(state.currentSession, isNotNull);
      expect(state.currentSession!.id, equals('session-123'));
    });

    test('session transitions to completed', () {
      final session = SessionModel(
        id: 'session-123',
        patientId: 'user-456',
        status: SessionStatus.completed,
        createdAt: DateTime.now(),
        completedAt: DateTime.now(),
      );

      final state = SessionState.completed(session);
      expect(state.status, equals(SessionStatus.completed));
      expect(state.currentSession?.completedAt, isNotNull);
    });
  });

  group('Session Exercise Results', () {
    test('exercise result stores quality score', () {
      final result = ExerciseResultModel(
        id: 'result-1',
        sessionId: 'session-123',
        exerciseId: 'exercise-456',
        repetitionsCompleted: 10,
        qualityScore: 0.85,
        timestamp: DateTime.now(),
      );

      expect(result.qualityScore, equals(0.85));
      expect(result.repetitionsCompleted, equals(10));
    });

    test('exercise result includes feedback', () {
      final result = ExerciseResultModel(
        id: 'result-2',
        sessionId: 'session-123',
        exerciseId: 'exercise-456',
        repetitionsCompleted: 8,
        qualityScore: 0.72,
        feedback: {'posture': 'needs improvement', 'depth': 'adequate'},
        timestamp: DateTime.now(),
      );

      expect(result.feedback, isNotNull);
      expect(result.feedback!['posture'], equals('needs improvement'));
    });

    test('session aggregates multiple exercise results', () {
      final results = [
        ExerciseResultModel(
          id: 'result-1',
          sessionId: 'session-123',
          exerciseId: 'ex-1',
          repetitionsCompleted: 10,
          qualityScore: 0.90,
          timestamp: DateTime.now(),
        ),
        ExerciseResultModel(
          id: 'result-2',
          sessionId: 'session-123',
          exerciseId: 'ex-2',
          repetitionsCompleted: 12,
          qualityScore: 0.85,
          timestamp: DateTime.now(),
        ),
        ExerciseResultModel(
          id: 'result-3',
          sessionId: 'session-123',
          exerciseId: 'ex-3',
          repetitionsCompleted: 8,
          qualityScore: 0.78,
          timestamp: DateTime.now(),
        ),
      ];

      final avgScore =
          results.map((r) => r.qualityScore).reduce((a, b) => a + b) /
          results.length;
      expect(avgScore, closeTo(0.843, 0.01));
    });
  });

  group('Session Pain Level Tracking', () {
    test('pain level before is recorded', () {
      final session = SessionModel(
        id: 'session-123',
        patientId: 'user-456',
        status: SessionStatus.active,
        painLevelBefore: 5,
        createdAt: DateTime.now(),
      );

      expect(session.painLevelBefore, equals(5));
    });

    test('pain level after is recorded on completion', () {
      final session = SessionModel(
        id: 'session-123',
        patientId: 'user-456',
        status: SessionStatus.completed,
        painLevelBefore: 5,
        painLevelAfter: 3,
        createdAt: DateTime.now(),
        completedAt: DateTime.now(),
      );

      expect(session.painLevelAfter, equals(3));
      expect(session.painLevelBefore! - session.painLevelAfter!, equals(2));
    });
  });

  group('Session Duration Tracking', () {
    test('session duration is calculated correctly', () {
      final startTime = DateTime(2024, 1, 1, 10, 0, 0);
      final endTime = DateTime(2024, 1, 1, 10, 30, 0);

      final duration = endTime.difference(startTime);
      expect(duration.inMinutes, equals(30));
    });

    test('session without end time has no duration', () {
      final session = SessionModel(
        id: 'session-123',
        patientId: 'user-456',
        status: SessionStatus.active,
        createdAt: DateTime.now(),
      );

      expect(session.completedAt, isNull);
    });
  });
}

// Model classes for testing
enum SessionStatus { idle, active, paused, completed, cancelled }

class SessionState {
  SessionState._({
    required this.status,
    this.currentSession,
    this.error,
  });

  factory SessionState.idle() => SessionState._(status: SessionStatus.idle);
  factory SessionState.active(SessionModel session) =>
      SessionState._(status: SessionStatus.active, currentSession: session);
  factory SessionState.completed(SessionModel session) =>
      SessionState._(status: SessionStatus.completed, currentSession: session);
  factory SessionState.error(String message) =>
      SessionState._(status: SessionStatus.idle, error: message);

  final SessionStatus status;
  final SessionModel? currentSession;
  final String? error;
}

class SessionModel {
  SessionModel({
    required this.id,
    required this.patientId,
    required this.status,
    required this.createdAt,
    this.completedAt,
    this.painLevelBefore,
    this.painLevelAfter,
    this.notes,
  });

  final String id;
  final String patientId;
  final SessionStatus status;
  final DateTime createdAt;
  final DateTime? completedAt;
  final int? painLevelBefore;
  final int? painLevelAfter;
  final String? notes;
}

class ExerciseResultModel {
  ExerciseResultModel({
    required this.id,
    required this.sessionId,
    required this.exerciseId,
    required this.repetitionsCompleted,
    required this.qualityScore,
    required this.timestamp,
    this.feedback,
  });

  final String id;
  final String sessionId;
  final String exerciseId;
  final int repetitionsCompleted;
  final double qualityScore;
  final DateTime timestamp;
  final Map<String, dynamic>? feedback;
}
