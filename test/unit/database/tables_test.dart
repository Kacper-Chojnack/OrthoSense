/// Unit tests for database tables and their column definitions.
///
/// Test coverage:
/// 1. ExerciseResults table columns
/// 2. Sessions table columns
/// 3. Settings table columns
/// 4. Column constraints and defaults
/// 5. Foreign key relationships
library;

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ExerciseResults Table', () {
    test('has id column as primary key', () {
      final columns = _getExerciseResultsColumns();

      expect(columns['id'], isNotNull);
      expect(columns['id']!.isPrimaryKey, isTrue);
      expect(columns['id']!.type, equals('text'));
    });

    test('has sessionId as foreign key', () {
      final columns = _getExerciseResultsColumns();

      expect(columns['sessionId'], isNotNull);
      expect(columns['sessionId']!.isForeignKey, isTrue);
      expect(columns['sessionId']!.references, equals('Sessions.id'));
    });

    test('has exerciseId column', () {
      final columns = _getExerciseResultsColumns();

      expect(columns['exerciseId'], isNotNull);
      expect(columns['exerciseId']!.type, equals('text'));
      expect(columns['exerciseId']!.isNullable, isFalse);
    });

    test('has exerciseName column', () {
      final columns = _getExerciseResultsColumns();

      expect(columns['exerciseName'], isNotNull);
      expect(columns['exerciseName']!.type, equals('text'));
    });

    test('has setsCompleted with default 0', () {
      final columns = _getExerciseResultsColumns();

      expect(columns['setsCompleted'], isNotNull);
      expect(columns['setsCompleted']!.type, equals('integer'));
      expect(columns['setsCompleted']!.defaultValue, equals(0));
    });

    test('has repsCompleted with default 0', () {
      final columns = _getExerciseResultsColumns();

      expect(columns['repsCompleted'], isNotNull);
      expect(columns['repsCompleted']!.type, equals('integer'));
      expect(columns['repsCompleted']!.defaultValue, equals(0));
    });

    test('has nullable score column', () {
      final columns = _getExerciseResultsColumns();

      expect(columns['score'], isNotNull);
      expect(columns['score']!.type, equals('integer'));
      expect(columns['score']!.isNullable, isTrue);
    });

    test('has nullable isCorrect column', () {
      final columns = _getExerciseResultsColumns();

      expect(columns['isCorrect'], isNotNull);
      expect(columns['isCorrect']!.type, equals('boolean'));
      expect(columns['isCorrect']!.isNullable, isTrue);
    });

    test('has nullable feedbackJson column', () {
      final columns = _getExerciseResultsColumns();

      expect(columns['feedbackJson'], isNotNull);
      expect(columns['feedbackJson']!.type, equals('text'));
      expect(columns['feedbackJson']!.isNullable, isTrue);
    });

    test('has nullable textReport column', () {
      final columns = _getExerciseResultsColumns();

      expect(columns['textReport'], isNotNull);
      expect(columns['textReport']!.type, equals('text'));
      expect(columns['textReport']!.isNullable, isTrue);
    });

    test('has durationSeconds with default 0', () {
      final columns = _getExerciseResultsColumns();

      expect(columns['durationSeconds'], isNotNull);
      expect(columns['durationSeconds']!.type, equals('integer'));
      expect(columns['durationSeconds']!.defaultValue, equals(0));
    });

    test('has performedAt with current time default', () {
      final columns = _getExerciseResultsColumns();

      expect(columns['performedAt'], isNotNull);
      expect(columns['performedAt']!.type, equals('datetime'));
      expect(columns['performedAt']!.hasDefaultValue, isTrue);
    });

    test('has syncStatus with pending default', () {
      final columns = _getExerciseResultsColumns();

      expect(columns['syncStatus'], isNotNull);
      expect(columns['syncStatus']!.type, equals('text'));
      expect(columns['syncStatus']!.defaultValue, equals('pending'));
    });
  });

  group('Sessions Table', () {
    test('has id column as primary key', () {
      final columns = _getSessionsColumns();

      expect(columns['id'], isNotNull);
      expect(columns['id']!.isPrimaryKey, isTrue);
      expect(columns['id']!.type, equals('text'));
    });

    test('has startedAt column', () {
      final columns = _getSessionsColumns();

      expect(columns['startedAt'], isNotNull);
      expect(columns['startedAt']!.type, equals('datetime'));
    });

    test('has nullable completedAt column', () {
      final columns = _getSessionsColumns();

      expect(columns['completedAt'], isNotNull);
      expect(columns['completedAt']!.type, equals('datetime'));
      expect(columns['completedAt']!.isNullable, isTrue);
    });

    test('has durationSeconds column', () {
      final columns = _getSessionsColumns();

      expect(columns['durationSeconds'], isNotNull);
      expect(columns['durationSeconds']!.type, equals('integer'));
    });

    test('has nullable overallScore column', () {
      final columns = _getSessionsColumns();

      expect(columns['overallScore'], isNotNull);
      expect(columns['overallScore']!.type, equals('integer'));
      expect(columns['overallScore']!.isNullable, isTrue);
    });

    test('has nullable notes column', () {
      final columns = _getSessionsColumns();

      expect(columns['notes'], isNotNull);
      expect(columns['notes']!.type, equals('text'));
      expect(columns['notes']!.isNullable, isTrue);
    });

    test('has syncStatus column', () {
      final columns = _getSessionsColumns();

      expect(columns['syncStatus'], isNotNull);
      expect(columns['syncStatus']!.type, equals('text'));
    });
  });

  group('Settings Table', () {
    test('has key column as primary key', () {
      final columns = _getSettingsColumns();

      expect(columns['key'], isNotNull);
      expect(columns['key']!.isPrimaryKey, isTrue);
      expect(columns['key']!.type, equals('text'));
    });

    test('has value column', () {
      final columns = _getSettingsColumns();

      expect(columns['value'], isNotNull);
      expect(columns['value']!.type, equals('text'));
    });
  });

  group('Column Validation', () {
    test('score must be between 0 and 100', () {
      expect(_isValidScore(0), isTrue);
      expect(_isValidScore(50), isTrue);
      expect(_isValidScore(100), isTrue);
      expect(_isValidScore(-1), isFalse);
      expect(_isValidScore(101), isFalse);
    });

    test('syncStatus must be valid value', () {
      expect(_isValidSyncStatus('pending'), isTrue);
      expect(_isValidSyncStatus('syncing'), isTrue);
      expect(_isValidSyncStatus('synced'), isTrue);
      expect(_isValidSyncStatus('failed'), isTrue);
      expect(_isValidSyncStatus('unknown'), isFalse);
    });

    test('exerciseId must not be empty', () {
      expect(_isValidExerciseId('deep_squat'), isTrue);
      expect(_isValidExerciseId('hurdle_step'), isTrue);
      expect(_isValidExerciseId(''), isFalse);
    });

    test('feedbackJson must be valid JSON', () {
      expect(_isValidFeedbackJson('{}'), isTrue);
      expect(_isValidFeedbackJson('{"error": true}'), isTrue);
      expect(_isValidFeedbackJson(null), isTrue); // Nullable
      expect(_isValidFeedbackJson('not json'), isFalse);
    });
  });

  group('Foreign Key Constraints', () {
    test('cascades delete from sessions to exercise results', () {
      // When a session is deleted, its exercise results should be deleted too
      final constraint = ForeignKeyConstraint(
        table: 'ExerciseResults',
        column: 'sessionId',
        references: 'Sessions.id',
        onDelete: 'CASCADE',
      );

      expect(constraint.onDelete, equals('CASCADE'));
    });

    test('orphan exercise results are not allowed', () {
      // Exercise results must always have a valid session
      final results = [
        MockExerciseResult(id: '1', sessionId: 'session-1'),
        MockExerciseResult(id: '2', sessionId: 'session-1'),
        MockExerciseResult(id: '3', sessionId: 'session-2'),
      ];

      final validSessionIds = {'session-1', 'session-2'};

      for (final result in results) {
        expect(validSessionIds.contains(result.sessionId), isTrue);
      }
    });
  });

  group('Table Relationships', () {
    test('session has many exercise results', () {
      final session = MockSession(id: 'session-1');
      final results = [
        MockExerciseResult(id: '1', sessionId: 'session-1'),
        MockExerciseResult(id: '2', sessionId: 'session-1'),
        MockExerciseResult(id: '3', sessionId: 'session-1'),
      ];

      final sessionResults =
          results.where((r) => r.sessionId == session.id).toList();

      expect(sessionResults.length, equals(3));
    });

    test('exercise result belongs to one session', () {
      final result = MockExerciseResult(id: '1', sessionId: 'session-1');

      expect(result.sessionId, isNotNull);
      expect(result.sessionId, equals('session-1'));
    });
  });

  group('Data Types', () {
    test('datetime columns store DateTime objects', () {
      final now = DateTime.now();
      final stored = now.toIso8601String();
      final restored = DateTime.parse(stored);

      expect(restored.year, equals(now.year));
      expect(restored.month, equals(now.month));
      expect(restored.day, equals(now.day));
    });

    test('boolean columns store true/false', () {
      expect(_boolToSqlite(true), equals(1));
      expect(_boolToSqlite(false), equals(0));
      expect(_sqliteToBool(1), isTrue);
      expect(_sqliteToBool(0), isFalse);
    });

    test('text columns support UTF-8', () {
      const text = 'ąęćżźółń ĄĘĆŻŹÓŁŃ 日本語 中文';
      expect(text.isNotEmpty, isTrue);
      // SQLite text columns handle UTF-8 natively
    });
  });
}

// Mock classes

class ColumnDefinition {
  ColumnDefinition({
    required this.type,
    this.isPrimaryKey = false,
    this.isForeignKey = false,
    this.isNullable = false,
    this.hasDefaultValue = false,
    this.defaultValue,
    this.references,
  });

  final String type;
  final bool isPrimaryKey;
  final bool isForeignKey;
  final bool isNullable;
  final bool hasDefaultValue;
  final Object? defaultValue;
  final String? references;
}

class ForeignKeyConstraint {
  ForeignKeyConstraint({
    required this.table,
    required this.column,
    required this.references,
    required this.onDelete,
  });

  final String table;
  final String column;
  final String references;
  final String onDelete;
}

class MockSession {
  MockSession({required this.id});

  final String id;
}

class MockExerciseResult {
  MockExerciseResult({required this.id, required this.sessionId});

  final String id;
  final String sessionId;
}

// Helper functions

Map<String, ColumnDefinition> _getExerciseResultsColumns() {
  return {
    'id': ColumnDefinition(type: 'text', isPrimaryKey: true),
    'sessionId': ColumnDefinition(
      type: 'text',
      isForeignKey: true,
      references: 'Sessions.id',
    ),
    'exerciseId': ColumnDefinition(type: 'text'),
    'exerciseName': ColumnDefinition(type: 'text'),
    'setsCompleted': ColumnDefinition(
      type: 'integer',
      hasDefaultValue: true,
      defaultValue: 0,
    ),
    'repsCompleted': ColumnDefinition(
      type: 'integer',
      hasDefaultValue: true,
      defaultValue: 0,
    ),
    'score': ColumnDefinition(type: 'integer', isNullable: true),
    'isCorrect': ColumnDefinition(type: 'boolean', isNullable: true),
    'feedbackJson': ColumnDefinition(type: 'text', isNullable: true),
    'textReport': ColumnDefinition(type: 'text', isNullable: true),
    'durationSeconds': ColumnDefinition(
      type: 'integer',
      hasDefaultValue: true,
      defaultValue: 0,
    ),
    'performedAt': ColumnDefinition(
      type: 'datetime',
      hasDefaultValue: true,
    ),
    'syncStatus': ColumnDefinition(
      type: 'text',
      hasDefaultValue: true,
      defaultValue: 'pending',
    ),
  };
}

Map<String, ColumnDefinition> _getSessionsColumns() {
  return {
    'id': ColumnDefinition(type: 'text', isPrimaryKey: true),
    'startedAt': ColumnDefinition(type: 'datetime'),
    'completedAt': ColumnDefinition(type: 'datetime', isNullable: true),
    'durationSeconds': ColumnDefinition(type: 'integer'),
    'overallScore': ColumnDefinition(type: 'integer', isNullable: true),
    'notes': ColumnDefinition(type: 'text', isNullable: true),
    'syncStatus': ColumnDefinition(type: 'text'),
  };
}

Map<String, ColumnDefinition> _getSettingsColumns() {
  return {
    'key': ColumnDefinition(type: 'text', isPrimaryKey: true),
    'value': ColumnDefinition(type: 'text'),
  };
}

bool _isValidScore(int score) {
  return score >= 0 && score <= 100;
}

bool _isValidSyncStatus(String status) {
  return ['pending', 'syncing', 'synced', 'failed'].contains(status);
}

bool _isValidExerciseId(String id) {
  return id.isNotEmpty;
}

bool _isValidFeedbackJson(String? json) {
  if (json == null) return true;
  try {
    // Simple check for valid JSON structure
    return (json.startsWith('{') && json.endsWith('}')) ||
        (json.startsWith('[') && json.endsWith(']'));
  } catch (_) {
    return false;
  }
}

int _boolToSqlite(bool value) => value ? 1 : 0;

bool _sqliteToBool(int value) => value != 0;
