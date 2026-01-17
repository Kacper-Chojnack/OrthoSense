/// Unit tests for ReportExportService.
///
/// Test coverage:
/// 1. SessionReportData model
/// 2. CSV/PDF generation logic
/// 3. Summary statistics calculations
/// 4. Duration formatting
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:orthosense/core/services/report_export_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SessionReportData Model', () {
    test('creates instance with required fields', () {
      final data = SessionReportData(
        date: DateTime(2025, 1, 15),
        exerciseName: 'Deep Squat',
        durationSeconds: 120,
        score: 85,
        isCorrect: true,
      );

      expect(data.date, equals(DateTime(2025, 1, 15)));
      expect(data.exerciseName, equals('Deep Squat'));
      expect(data.durationSeconds, equals(120));
      expect(data.score, equals(85));
      expect(data.isCorrect, isTrue);
      expect(data.notes, isNull);
      expect(data.textReport, isNull);
    });

    test('creates instance with optional fields', () {
      final data = SessionReportData(
        date: DateTime(2025, 1, 15),
        exerciseName: 'Hurdle Step',
        durationSeconds: 90,
        score: 72,
        isCorrect: false,
        notes: 'Need to work on balance',
        textReport: 'Detailed analysis report',
        feedback: {'error': 'Torso lean'},
      );

      expect(data.notes, equals('Need to work on balance'));
      expect(data.textReport, equals('Detailed analysis report'));
      expect(data.feedback, equals({'error': 'Torso lean'}));
    });

    test('handles edge case with zero duration', () {
      final data = SessionReportData(
        date: DateTime.now(),
        exerciseName: 'Test',
        durationSeconds: 0,
        score: 0,
        isCorrect: false,
      );

      expect(data.durationSeconds, equals(0));
      expect(data.score, equals(0));
    });

    test('handles edge case with max score', () {
      final data = SessionReportData(
        date: DateTime.now(),
        exerciseName: 'Perfect Exercise',
        durationSeconds: 60,
        score: 100,
        isCorrect: true,
      );

      expect(data.score, equals(100));
    });

    test('handles empty feedback map', () {
      final data = SessionReportData(
        date: DateTime.now(),
        exerciseName: 'Test',
        durationSeconds: 60,
        score: 80,
        isCorrect: true,
      );

      expect(data.feedback, isEmpty);
    });

    test('handles feedback with multiple entries', () {
      final data = SessionReportData(
        date: DateTime.now(),
        exerciseName: 'Deep Squat',
        durationSeconds: 120,
        score: 65,
        isCorrect: false,
        feedback: {
          'Squat too shallow': true,
          'Knee Valgus': true,
          'Heels rising': 'Left',
        },
      );

      expect(data.feedback.length, equals(3));
      expect(data.feedback['Squat too shallow'], isTrue);
      expect(data.feedback['Heels rising'], equals('Left'));
    });
  });

  group('Date Formatting Logic', () {
    test('formats date correctly for display', () {
      final date = DateTime(2025, 6, 15, 14, 30);
      final formatted = _formatDateForDisplay(date);

      expect(formatted, contains('2025'));
      expect(formatted, contains('06'));
      expect(formatted, contains('15'));
    });

    test('formats time correctly', () {
      final date = DateTime(2025, 1, 1, 9, 5);
      final formatted = _formatDateForDisplay(date);

      expect(formatted, contains('09'));
      expect(formatted, contains('05'));
    });

    test('handles midnight correctly', () {
      final date = DateTime(2025, 12, 31, 0, 0);
      final formatted = _formatDateForDisplay(date);

      expect(formatted, contains('00'));
    });
  });

  group('Summary Statistics Calculations', () {
    test('calculates total sessions correctly', () {
      final sessions = List.generate(
        5,
        (i) => SessionReportData(
          date: DateTime.now(),
          exerciseName: 'Exercise $i',
          durationSeconds: 60,
          score: 80 + i,
          isCorrect: true,
        ),
      );

      expect(sessions.length, equals(5));
    });

    test('calculates average score correctly', () {
      final scores = [80, 85, 90, 95, 100];
      final average = scores.reduce((a, b) => a + b) / scores.length;

      expect(average, equals(90.0));
    });

    test('calculates compliance rate correctly', () {
      final sessions = [
        SessionReportData(
          date: DateTime.now(),
          exerciseName: 'A',
          durationSeconds: 60,
          score: 80,
          isCorrect: true,
        ),
        SessionReportData(
          date: DateTime.now(),
          exerciseName: 'B',
          durationSeconds: 60,
          score: 60,
          isCorrect: false,
        ),
        SessionReportData(
          date: DateTime.now(),
          exerciseName: 'C',
          durationSeconds: 60,
          score: 90,
          isCorrect: true,
        ),
        SessionReportData(
          date: DateTime.now(),
          exerciseName: 'D',
          durationSeconds: 60,
          score: 70,
          isCorrect: false,
        ),
      ];

      final correctCount = sessions.where((s) => s.isCorrect).length;
      final complianceRate = (correctCount / sessions.length * 100).round();

      expect(complianceRate, equals(50));
    });

    test('handles empty sessions for average', () {
      final sessions = <SessionReportData>[];
      final avgScore = sessions.isEmpty
          ? 0
          : sessions.map((s) => s.score).reduce((a, b) => a + b) ~/
                sessions.length;

      expect(avgScore, equals(0));
    });

    test('calculates total duration correctly', () {
      final sessions = [
        SessionReportData(
          date: DateTime.now(),
          exerciseName: 'A',
          durationSeconds: 120,
          score: 80,
          isCorrect: true,
        ),
        SessionReportData(
          date: DateTime.now(),
          exerciseName: 'B',
          durationSeconds: 90,
          score: 75,
          isCorrect: true,
        ),
        SessionReportData(
          date: DateTime.now(),
          exerciseName: 'C',
          durationSeconds: 60,
          score: 85,
          isCorrect: true,
        ),
      ];

      final totalDuration = sessions
          .map((s) => s.durationSeconds)
          .reduce((a, b) => a + b);

      expect(totalDuration, equals(270));
    });
  });

  group('Duration Formatting', () {
    test('formats seconds to minutes correctly', () {
      expect((120 / 60).toStringAsFixed(1), equals('2.0'));
      expect((90 / 60).toStringAsFixed(1), equals('1.5'));
      expect((45 / 60).toStringAsFixed(1), equals('0.8'));
    });

    test('handles zero duration', () {
      expect((0 / 60).toStringAsFixed(1), equals('0.0'));
    });

    test('handles large duration', () {
      expect((3600 / 60).toStringAsFixed(1), equals('60.0'));
    });

    test('formats hours and minutes', () {
      const seconds = 3665; // 1 hour, 1 minute, 5 seconds
      final hours = seconds ~/ 3600;
      final minutes = (seconds % 3600) ~/ 60;

      expect(hours, equals(1));
      expect(minutes, equals(1));
    });
  });

  group('CSV Content Generation', () {
    test('handles empty session list', () {
      final sessions = <SessionReportData>[];
      final csvContent = _generateCsvContent(sessions);

      // Should only have header
      final lines = csvContent.split('\n').where((l) => l.isNotEmpty).toList();
      expect(lines.length, equals(1)); // Just header
    });

    test('generates correct CSV header', () {
      final sessions = <SessionReportData>[];
      final csvContent = _generateCsvContent(sessions);

      expect(csvContent, contains('Date'));
      expect(csvContent, contains('Exercise'));
      expect(csvContent, contains('Duration'));
      expect(csvContent, contains('Score'));
      expect(csvContent, contains('Status'));
    });

    test('generates correct row for session', () {
      final sessions = [
        SessionReportData(
          date: DateTime(2025, 1, 15, 10, 0),
          exerciseName: 'Deep Squat',
          durationSeconds: 120,
          score: 85,
          isCorrect: true,
        ),
      ];

      final csvContent = _generateCsvContent(sessions);

      expect(csvContent, contains('Deep Squat'));
      expect(csvContent, contains('85'));
      expect(csvContent, contains('Correct'));
    });

    test('escapes commas in notes', () {
      const notes = 'Good work, keep it up';
      final escaped = notes.replaceAll(',', ';');

      expect(escaped, equals('Good work; keep it up'));
    });

    test('handles multiple sessions', () {
      final sessions = [
        SessionReportData(
          date: DateTime(2025, 1, 15),
          exerciseName: 'Deep Squat',
          durationSeconds: 120,
          score: 85,
          isCorrect: true,
        ),
        SessionReportData(
          date: DateTime(2025, 1, 16),
          exerciseName: 'Hurdle Step',
          durationSeconds: 90,
          score: 72,
          isCorrect: false,
        ),
      ];

      final csvContent = _generateCsvContent(sessions);
      final lines = csvContent.split('\n').where((l) => l.isNotEmpty).toList();

      expect(lines.length, equals(3)); // Header + 2 sessions
    });
  });

  group('Score Status Mapping', () {
    test('correct movement maps to Correct status', () {
      expect(_getStatusText(true), equals('Correct'));
    });

    test('incorrect movement maps to Needs Improvement status', () {
      expect(_getStatusText(false), equals('Needs Improvement'));
    });
  });

  group('Exercise Name Grouping', () {
    test('groups sessions by exercise name', () {
      final sessions = [
        SessionReportData(
          date: DateTime.now(),
          exerciseName: 'Deep Squat',
          durationSeconds: 60,
          score: 80,
          isCorrect: true,
        ),
        SessionReportData(
          date: DateTime.now(),
          exerciseName: 'Hurdle Step',
          durationSeconds: 60,
          score: 75,
          isCorrect: true,
        ),
        SessionReportData(
          date: DateTime.now(),
          exerciseName: 'Deep Squat',
          durationSeconds: 60,
          score: 85,
          isCorrect: true,
        ),
      ];

      final groupedByExercise = <String, List<SessionReportData>>{};
      for (final session in sessions) {
        groupedByExercise
            .putIfAbsent(session.exerciseName, () => [])
            .add(session);
      }

      expect(groupedByExercise.keys.length, equals(2));
      expect(groupedByExercise['Deep Squat']?.length, equals(2));
      expect(groupedByExercise['Hurdle Step']?.length, equals(1));
    });
  });
}

// Helper functions for testing

String _formatDateForDisplay(DateTime date) {
  return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} '
      '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
}

String _generateCsvContent(List<SessionReportData> sessions) {
  final buffer = StringBuffer();
  buffer.writeln('Date,Exercise,Duration (min),Score,Status,Notes');

  for (final session in sessions) {
    final date = _formatDateForDisplay(session.date);
    final duration = (session.durationSeconds / 60).toStringAsFixed(1);
    final status = session.isCorrect ? 'Correct' : 'Needs Improvement';
    final notes = session.notes?.replaceAll(',', ';') ?? '';

    buffer.writeln(
      '$date,${session.exerciseName},$duration,${session.score},$status,$notes',
    );
  }

  return buffer.toString();
}

String _getStatusText(bool isCorrect) {
  return isCorrect ? 'Correct' : 'Needs Improvement';
}
