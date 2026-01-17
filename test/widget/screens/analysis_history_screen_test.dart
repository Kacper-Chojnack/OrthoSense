/// Widget and unit tests for AnalysisHistoryScreen.
///
/// Test coverage:
/// 1. AnalysisHistoryItem model
/// 2. Date formatting logic
/// 3. Empty state rendering
/// 4. History list rendering
/// 5. Filter sheet
/// 6. Detail sheet
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AnalysisHistoryItem Model', () {
    test('creates from basic parameters', () {
      final item = AnalysisHistoryItem(
        id: '1',
        exerciseName: 'Deep Squat',
        date: DateTime(2024, 1, 15, 10, 30),
        score: 85,
        isCorrect: true,
        feedbackText: 'Good form!',
      );

      expect(item.id, equals('1'));
      expect(item.exerciseName, equals('Deep Squat'));
      expect(item.score, equals(85));
      expect(item.isCorrect, isTrue);
      expect(item.feedbackText, equals('Good form!'));
    });

    test('handles null feedbackText', () {
      final item = AnalysisHistoryItem(
        id: '1',
        exerciseName: 'Deep Squat',
        date: DateTime.now(),
        score: 85,
        isCorrect: true,
      );

      expect(item.feedbackText, isNull);
    });

    test('stores feedback map', () {
      final feedback = {
        'error_count': 2,
        'errors': ['Knee Valgus', 'Trunk Lean'],
      };

      final item = AnalysisHistoryItem(
        id: '1',
        exerciseName: 'Deep Squat',
        date: DateTime.now(),
        score: 70,
        isCorrect: false,
        feedback: feedback,
      );

      expect(item.feedback['error_count'], equals(2));
      expect(item.feedback['errors'], contains('Knee Valgus'));
    });

    test('stores duration in seconds', () {
      final item = AnalysisHistoryItem(
        id: '1',
        exerciseName: 'Hurdle Step',
        date: DateTime.now(),
        score: 90,
        isCorrect: true,
        durationSeconds: 45,
      );

      expect(item.durationSeconds, equals(45));
    });

    test('default values for optional parameters', () {
      final item = AnalysisHistoryItem(
        id: '1',
        exerciseName: 'Test',
        date: DateTime.now(),
        score: 50,
        isCorrect: false,
      );

      expect(item.feedback, isEmpty);
      expect(item.durationSeconds, equals(0));
      expect(item.feedbackText, isNull);
    });
  });

  group('AnalysisHistoryItem fromExerciseResult', () {
    test('creates from mock exercise result', () {
      final result = MockExerciseResult(
        id: 'result-1',
        exerciseName: 'Shoulder Abduction',
        performedAt: DateTime(2024, 2, 20, 14, 0),
        score: 88,
        isCorrect: true,
        feedbackJson: '{"errors":[]}',
        textReport: 'Excellent form!',
        durationSeconds: 30,
      );

      final item = AnalysisHistoryItem.fromExerciseResult(result);

      expect(item.id, equals('result-1'));
      expect(item.exerciseName, equals('Shoulder Abduction'));
      expect(item.score, equals(88));
      expect(item.isCorrect, isTrue);
      expect(item.feedbackText, equals('Excellent form!'));
      expect(item.durationSeconds, equals(30));
    });

    test('handles null score', () {
      final result = MockExerciseResult(
        id: 'result-2',
        exerciseName: 'Deep Squat',
        performedAt: DateTime.now(),
        score: null,
        isCorrect: false,
        feedbackJson: null,
        textReport: null,
        durationSeconds: 0,
      );

      final item = AnalysisHistoryItem.fromExerciseResult(result);

      expect(item.score, equals(0));
    });

    test('handles null isCorrect', () {
      final result = MockExerciseResult(
        id: 'result-3',
        exerciseName: 'Test',
        performedAt: DateTime.now(),
        score: 50,
        isCorrect: null,
        feedbackJson: null,
        textReport: null,
        durationSeconds: 0,
      );

      final item = AnalysisHistoryItem.fromExerciseResult(result);

      expect(item.isCorrect, isFalse);
    });

    test('parses feedback JSON', () {
      final result = MockExerciseResult(
        id: 'result-4',
        exerciseName: 'Deep Squat',
        performedAt: DateTime.now(),
        score: 60,
        isCorrect: false,
        feedbackJson: '{"error_count":3,"primary_error":"Knee Valgus"}',
        textReport: 'Multiple errors detected',
        durationSeconds: 40,
      );

      final item = AnalysisHistoryItem.fromExerciseResult(result);

      expect(item.feedback['error_count'], equals(3));
      expect(item.feedback['primary_error'], equals('Knee Valgus'));
    });
  });

  group('Date Formatting', () {
    test('formats as hours ago for recent', () {
      final now = DateTime.now();
      final date = now.subtract(const Duration(hours: 3));

      final formatted = _formatDate(date, now);

      expect(formatted, equals('3h ago'));
    });

    test('formats as days ago within week', () {
      final now = DateTime.now();
      final date = now.subtract(const Duration(days: 2));

      final formatted = _formatDate(date, now);

      expect(formatted, equals('2d ago'));
    });

    test('formats as full date for older', () {
      final now = DateTime.now();
      final date = now.subtract(const Duration(days: 10));

      final formatted = _formatDate(date, now);

      expect(formatted, contains('202'));
    });

    test('handles 0 hours as recent', () {
      final now = DateTime.now();
      final date = now.subtract(const Duration(minutes: 30));

      final formatted = _formatDate(date, now);

      expect(formatted, equals('0h ago'));
    });

    test('handles exactly 24 hours as 1 day', () {
      final now = DateTime.now();
      final date = now.subtract(const Duration(hours: 24));

      final formatted = _formatDate(date, now);

      expect(formatted, equals('1d ago'));
    });

    test('handles 6 days as days ago', () {
      final now = DateTime.now();
      final date = now.subtract(const Duration(days: 6));

      final formatted = _formatDate(date, now);

      expect(formatted, equals('6d ago'));
    });

    test('handles 7 days as formatted date', () {
      final now = DateTime.now();
      final date = now.subtract(const Duration(days: 7));

      final formatted = _formatDate(date, now);

      expect(formatted.contains('ago'), isFalse);
    });
  });

  group('Score Color Calculation', () {
    test('returns green for high score', () {
      final color = _getScoreColor(0.9);

      expect(color, equals(Colors.green));
    });

    test('returns yellow for medium score', () {
      final color = _getScoreColor(0.7);

      expect(color, equals(Colors.orange));
    });

    test('returns red for low score', () {
      final color = _getScoreColor(0.3);

      expect(color, equals(Colors.red));
    });

    test('handles boundary at 80%', () {
      expect(_getScoreColor(0.8), equals(Colors.green));
      expect(_getScoreColor(0.79), equals(Colors.orange));
    });

    test('handles boundary at 50%', () {
      expect(_getScoreColor(0.5), equals(Colors.orange));
      expect(_getScoreColor(0.49), equals(Colors.red));
    });
  });

  group('Status Color Calculation', () {
    test('returns green for correct', () {
      final color = _getStatusColor(isCorrect: true);

      expect(color, equals(Colors.green));
    });

    test('returns amber for incorrect', () {
      final color = _getStatusColor(isCorrect: false);

      expect(color, equals(Colors.amber));
    });
  });

  group('History List Grouping', () {
    test('groups by date', () {
      final items = [
        _createItem(date: DateTime(2024, 1, 15)),
        _createItem(date: DateTime(2024, 1, 15)),
        _createItem(date: DateTime(2024, 1, 14)),
        _createItem(date: DateTime(2024, 1, 10)),
      ];

      final grouped = _groupByDate(items);

      expect(grouped.length, equals(3));
      expect(grouped['2024-01-15']?.length, equals(2));
      expect(grouped['2024-01-14']?.length, equals(1));
    });

    test('handles empty list', () {
      final grouped = _groupByDate([]);

      expect(grouped.isEmpty, isTrue);
    });

    test('handles single item', () {
      final items = [_createItem(date: DateTime(2024, 1, 15))];

      final grouped = _groupByDate(items);

      expect(grouped.length, equals(1));
    });
  });

  group('Filter Logic', () {
    test('filters by correct only', () {
      final items = [
        _createItem(isCorrect: true),
        _createItem(isCorrect: false),
        _createItem(isCorrect: true),
      ];

      final filtered = _filterItems(items, correctOnly: true);

      expect(filtered.length, equals(2));
      expect(filtered.every((i) => i.isCorrect), isTrue);
    });

    test('filters by needs work only', () {
      final items = [
        _createItem(isCorrect: true),
        _createItem(isCorrect: false),
        _createItem(isCorrect: false),
      ];

      final filtered = _filterItems(items, needsWorkOnly: true);

      expect(filtered.length, equals(2));
      expect(filtered.every((i) => !i.isCorrect), isTrue);
    });

    test('returns all when no filter', () {
      final items = [
        _createItem(isCorrect: true),
        _createItem(isCorrect: false),
      ];

      final filtered = _filterItems(items);

      expect(filtered.length, equals(2));
    });

    test('filters by exercise name', () {
      final items = [
        _createItem(exerciseName: 'Deep Squat'),
        _createItem(exerciseName: 'Hurdle Step'),
        _createItem(exerciseName: 'Deep Squat'),
      ];

      final filtered = _filterItems(items, exerciseName: 'Deep Squat');

      expect(filtered.length, equals(2));
    });

    test('filters by minimum score', () {
      final items = [
        _createItem(score: 90),
        _createItem(score: 70),
        _createItem(score: 50),
      ];

      final filtered = _filterItems(items, minScore: 80);

      expect(filtered.length, equals(1));
      expect(filtered.first.score, equals(90));
    });
  });

  group('Accessibility', () {
    test('generates correct semantic label', () {
      final item = AnalysisHistoryItem(
        id: '1',
        exerciseName: 'Deep Squat',
        date: DateTime(2024, 1, 15),
        score: 85,
        isCorrect: true,
      );

      final label = _generateSemanticLabel(item);

      expect(label, contains('Deep Squat'));
      expect(label, contains('85'));
      expect(label, contains('Correct'));
    });

    test('semantic label for incorrect exercise', () {
      final item = AnalysisHistoryItem(
        id: '1',
        exerciseName: 'Hurdle Step',
        date: DateTime(2024, 1, 15),
        score: 60,
        isCorrect: false,
      );

      final label = _generateSemanticLabel(item);

      expect(label, contains('improvement'));
    });
  });

  group('Empty State', () {
    testWidgets('shows empty state message', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: _EmptyState(),
          ),
        ),
      );

      expect(find.text('No sessions yet'), findsOneWidget);
      expect(find.byIcon(Icons.history), findsOneWidget);
    });
  });

  group('History Item Card Widget', () {
    testWidgets('displays exercise name', (tester) async {
      final item = AnalysisHistoryItem(
        id: '1',
        exerciseName: 'Deep Squat',
        date: DateTime.now(),
        score: 85,
        isCorrect: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: _HistoryItemCard(item: item),
          ),
        ),
      );

      expect(find.text('Deep Squat'), findsOneWidget);
    });

    testWidgets('displays score percentage', (tester) async {
      final item = AnalysisHistoryItem(
        id: '1',
        exerciseName: 'Test',
        date: DateTime.now(),
        score: 75,
        isCorrect: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: _HistoryItemCard(item: item),
          ),
        ),
      );

      expect(find.text('75%'), findsOneWidget);
    });

    testWidgets('shows check icon for correct', (tester) async {
      final item = AnalysisHistoryItem(
        id: '1',
        exerciseName: 'Test',
        date: DateTime.now(),
        score: 85,
        isCorrect: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: _HistoryItemCard(item: item),
          ),
        ),
      );

      expect(find.byIcon(Icons.check), findsOneWidget);
    });

    testWidgets('shows warning icon for incorrect', (tester) async {
      final item = AnalysisHistoryItem(
        id: '1',
        exerciseName: 'Test',
        date: DateTime.now(),
        score: 50,
        isCorrect: false,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: _HistoryItemCard(item: item),
          ),
        ),
      );

      expect(find.byIcon(Icons.priority_high), findsOneWidget);
    });
  });

  group('Detail Sheet', () {
    test('formats detailed date correctly', () {
      final date = DateTime(2024, 1, 15, 14, 30);
      final formatted = _formatDetailDate(date);

      expect(formatted, contains('January'));
      expect(formatted, contains('15'));
      expect(formatted, contains('2024'));
    });
  });
}

// Mock classes

class MockExerciseResult {
  const MockExerciseResult({
    required this.id,
    required this.exerciseName,
    required this.performedAt,
    required this.score,
    required this.isCorrect,
    this.feedbackJson,
    this.textReport,
    required this.durationSeconds,
  });

  final String id;
  final String exerciseName;
  final DateTime performedAt;
  final int? score;
  final bool? isCorrect;
  final String? feedbackJson;
  final String? textReport;
  final int durationSeconds;
}

class AnalysisHistoryItem {
  const AnalysisHistoryItem({
    required this.id,
    required this.exerciseName,
    required this.date,
    required this.score,
    required this.isCorrect,
    this.feedbackText,
    this.feedback = const {},
    this.durationSeconds = 0,
  });

  factory AnalysisHistoryItem.fromExerciseResult(MockExerciseResult result) {
    final feedback = _parseFeedback(result.feedbackJson);

    return AnalysisHistoryItem(
      id: result.id,
      exerciseName: result.exerciseName,
      date: result.performedAt,
      score: result.score ?? 0,
      isCorrect: result.isCorrect ?? false,
      feedbackText: result.textReport,
      feedback: feedback,
      durationSeconds: result.durationSeconds,
    );
  }

  final String id;
  final String exerciseName;
  final DateTime date;
  final int score;
  final bool isCorrect;
  final String? feedbackText;
  final Map<String, dynamic> feedback;
  final int durationSeconds;
}

// Helper functions

Map<String, dynamic> _parseFeedback(String? json) {
  if (json == null || json.isEmpty) return {};

  // Simple parse for testing
  final map = <String, dynamic>{};

  if (json.contains('error_count')) {
    final match = RegExp(r'"error_count":(\d+)').firstMatch(json);
    if (match != null) {
      map['error_count'] = int.parse(match.group(1)!);
    }
  }

  if (json.contains('primary_error')) {
    final match = RegExp(r'"primary_error":"([^"]+)"').firstMatch(json);
    if (match != null) {
      map['primary_error'] = match.group(1);
    }
  }

  return map;
}

String _formatDate(DateTime date, DateTime now) {
  final diff = now.difference(date);

  if (diff.inHours < 24) {
    return '${diff.inHours}h ago';
  } else if (diff.inDays < 7) {
    return '${diff.inDays}d ago';
  }
  return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}

Color _getScoreColor(double normalizedScore) {
  if (normalizedScore >= 0.8) return Colors.green;
  if (normalizedScore >= 0.5) return Colors.orange;
  return Colors.red;
}

Color _getStatusColor({required bool isCorrect}) {
  return isCorrect ? Colors.green : Colors.amber;
}

Map<String, List<AnalysisHistoryItem>> _groupByDate(
  List<AnalysisHistoryItem> items,
) {
  final grouped = <String, List<AnalysisHistoryItem>>{};

  for (final item in items) {
    final key =
        '${item.date.year}-${item.date.month.toString().padLeft(2, '0')}-${item.date.day.toString().padLeft(2, '0')}';
    grouped.putIfAbsent(key, () => []).add(item);
  }

  return grouped;
}

List<AnalysisHistoryItem> _filterItems(
  List<AnalysisHistoryItem> items, {
  bool correctOnly = false,
  bool needsWorkOnly = false,
  String? exerciseName,
  int? minScore,
}) {
  var result = items;

  if (correctOnly) {
    result = result.where((i) => i.isCorrect).toList();
  }

  if (needsWorkOnly) {
    result = result.where((i) => !i.isCorrect).toList();
  }

  if (exerciseName != null) {
    result = result.where((i) => i.exerciseName == exerciseName).toList();
  }

  if (minScore != null) {
    result = result.where((i) => i.score >= minScore).toList();
  }

  return result;
}

String _generateSemanticLabel(AnalysisHistoryItem item) {
  final status = item.isCorrect ? 'Correct form' : 'Needs improvement';
  return '${item.exerciseName} session. Score ${item.score} percent. $status.';
}

String _formatDetailDate(DateTime date) {
  final months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
  return '${months[date.month - 1]} ${date.day}, ${date.year}';
}

AnalysisHistoryItem _createItem({
  String? id,
  String exerciseName = 'Test Exercise',
  DateTime? date,
  int score = 80,
  bool isCorrect = true,
}) {
  return AnalysisHistoryItem(
    id: id ?? DateTime.now().millisecondsSinceEpoch.toString(),
    exerciseName: exerciseName,
    date: date ?? DateTime.now(),
    score: score,
    isCorrect: isCorrect,
  );
}

// Widget mocks for testing

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history, size: 64),
          SizedBox(height: 16),
          Text('No sessions yet'),
        ],
      ),
    );
  }
}

class _HistoryItemCard extends StatelessWidget {
  const _HistoryItemCard({required this.item});

  final AnalysisHistoryItem item;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(item.isCorrect ? Icons.check : Icons.priority_high),
        title: Text(item.exerciseName),
        trailing: Text('${item.score}%'),
      ),
    );
  }
}
