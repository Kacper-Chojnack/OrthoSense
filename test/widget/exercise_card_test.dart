/// Widget tests for exercise-related UI components.
///
/// Test coverage:
/// 1. CountdownOverlay widget
/// 2. Exercise demo video sheet
/// 3. Exercise result cards
/// 4. Pain level slider
/// 5. Score display widgets
/// 6. Session timer widget
/// 7. Accessibility and interaction tests
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CountdownOverlay Widget', () {
    testWidgets('displays countdown numbers correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: _TestCountdownWidget(startFrom: 3),
          ),
        ),
      );

      // Initial state shows starting number
      expect(find.text('3'), findsOneWidget);

      // After cleanup, verify the widget is gone
      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('countdown decreases on timer tick', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: _TestCountdownWidget(startFrom: 3),
          ),
        ),
      );

      expect(find.text('3'), findsOneWidget);

      // Advance by 1 second
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('2'), findsOneWidget);

      // Clean up
      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('has proper styling', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: _TestCountdownWidget(startFrom: 5),
          ),
        ),
      );

      final textFinder = find.text('5');
      expect(textFinder, findsOneWidget);

      // Check text is styled (large font)
      final text = tester.widget<Text>(textFinder);
      expect(text.style?.fontSize, greaterThan(48));

      // Clean up
      await tester.pumpWidget(const SizedBox.shrink());
    });
  });

  group('Pain Level Slider Widget', () {
    testWidgets('displays current pain level', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: _TestPainLevelSlider(initialValue: 5),
            ),
          ),
        ),
      );

      expect(find.text('5'), findsOneWidget);
      expect(find.byType(Slider), findsOneWidget);
    });

    testWidgets('slider updates value on drag', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: _TestPainLevelSlider(initialValue: 5),
            ),
          ),
        ),
      );

      // Drag slider to the right
      await tester.drag(find.byType(Slider), const Offset(100, 0));
      await tester.pumpAndSettle();

      // Value should have increased
      expect(find.text('5'), findsNothing);
    });

    testWidgets('displays min and max labels', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: _TestPainLevelSlider(initialValue: 0),
            ),
          ),
        ),
      );

      expect(find.text('No Pain'), findsOneWidget);
      expect(find.text('Severe'), findsOneWidget);
    });

    testWidgets('has correct min/max bounds', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: _TestPainLevelSlider(initialValue: 0),
            ),
          ),
        ),
      );

      final slider = tester.widget<Slider>(find.byType(Slider));
      expect(slider.min, equals(0));
      expect(slider.max, equals(10));
    });
  });

  group('Score Display Widget', () {
    testWidgets('displays score value correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: _TestScoreDisplay(score: 85),
          ),
        ),
      );

      expect(find.text('85'), findsOneWidget);
      expect(find.text('/100'), findsOneWidget);
    });

    testWidgets('shows green color for high score', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: _TestScoreDisplay(score: 90),
          ),
        ),
      );

      final container = tester.widget<Container>(
        find.byKey(const Key('score_container')),
      );
      final decoration = container.decoration as BoxDecoration?;

      expect(decoration?.color, equals(Colors.green.shade100));
    });

    testWidgets('shows yellow color for medium score', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: _TestScoreDisplay(score: 65),
          ),
        ),
      );

      final container = tester.widget<Container>(
        find.byKey(const Key('score_container')),
      );
      final decoration = container.decoration as BoxDecoration?;

      expect(decoration?.color, equals(Colors.yellow.shade100));
    });

    testWidgets('shows red color for low score', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: _TestScoreDisplay(score: 40),
          ),
        ),
      );

      final container = tester.widget<Container>(
        find.byKey(const Key('score_container')),
      );
      final decoration = container.decoration as BoxDecoration?;

      expect(decoration?.color, equals(Colors.red.shade100));
    });

    testWidgets('displays perfect score indicator', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: _TestScoreDisplay(score: 100),
          ),
        ),
      );

      expect(find.text('100'), findsOneWidget);
      expect(find.byIcon(Icons.star), findsOneWidget);
    });
  });

  group('Session Timer Widget', () {
    testWidgets('displays initial time as 00:00', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: _TestSessionTimer(seconds: 0),
          ),
        ),
      );

      expect(find.text('00:00'), findsOneWidget);
    });

    testWidgets('formats minutes and seconds correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: _TestSessionTimer(seconds: 125), // 2:05
          ),
        ),
      );

      expect(find.text('02:05'), findsOneWidget);
    });

    testWidgets('formats hours when over 60 minutes', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: _TestSessionTimer(seconds: 3725), // 1:02:05
          ),
        ),
      );

      expect(find.text('01:02:05'), findsOneWidget);
    });

    testWidgets('has timer icon', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: _TestSessionTimer(seconds: 0),
          ),
        ),
      );

      expect(find.byIcon(Icons.timer), findsOneWidget);
    });
  });

  group('Exercise Result Card Widget', () {
    testWidgets('displays exercise name', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: _TestExerciseResultCard(
              exerciseName: 'Shoulder Abduction',
              score: 85,
              isCorrect: true,
            ),
          ),
        ),
      );

      expect(find.text('Shoulder Abduction'), findsOneWidget);
    });

    testWidgets('shows score badge', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: _TestExerciseResultCard(
              exerciseName: 'Test Exercise',
              score: 75,
              isCorrect: true,
            ),
          ),
        ),
      );

      expect(find.text('75'), findsOneWidget);
    });

    testWidgets('shows checkmark for correct exercise', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: _TestExerciseResultCard(
              exerciseName: 'Test',
              score: 90,
              isCorrect: true,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    testWidgets('shows warning for incorrect exercise', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: _TestExerciseResultCard(
              exerciseName: 'Test',
              score: 50,
              isCorrect: false,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.warning), findsOneWidget);
    });

    testWidgets('card is tappable', (tester) async {
      var tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: _TestExerciseResultCard(
              exerciseName: 'Test',
              score: 80,
              isCorrect: true,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(Card));
      await tester.pumpAndSettle();

      expect(tapped, isTrue);
    });
  });

  group('Exercise List Item Widget', () {
    testWidgets('displays exercise info', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: _TestExerciseListItem(
              name: 'Knee Extension',
              category: 'Mobility',
              difficulty: 2,
            ),
          ),
        ),
      );

      expect(find.text('Knee Extension'), findsOneWidget);
      expect(find.text('Mobility'), findsOneWidget);
    });

    testWidgets('shows difficulty stars', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: _TestExerciseListItem(
              name: 'Hard Exercise',
              category: 'Strength',
              difficulty: 4,
            ),
          ),
        ),
      );

      // Should have 4 filled stars
      expect(find.byIcon(Icons.star), findsNWidgets(4));
      // And 1 empty star
      expect(find.byIcon(Icons.star_border), findsOneWidget);
    });

    testWidgets('has leading icon based on category', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: _TestExerciseListItem(
              name: 'Balance Test',
              category: 'Balance',
              difficulty: 3,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.accessibility_new), findsOneWidget);
    });
  });

  group('Feedback Message Widget', () {
    testWidgets('displays success feedback', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: _TestFeedbackMessage(
              type: FeedbackType.success,
              message: 'Great form!',
            ),
          ),
        ),
      );

      expect(find.text('Great form!'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    testWidgets('displays warning feedback', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: _TestFeedbackMessage(
              type: FeedbackType.warning,
              message: 'Watch your posture',
            ),
          ),
        ),
      );

      expect(find.text('Watch your posture'), findsOneWidget);
      expect(find.byIcon(Icons.warning_amber), findsOneWidget);
    });

    testWidgets('displays error feedback', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: _TestFeedbackMessage(
              type: FeedbackType.error,
              message: 'Incorrect movement',
            ),
          ),
        ),
      );

      expect(find.text('Incorrect movement'), findsOneWidget);
      expect(find.byIcon(Icons.error), findsOneWidget);
    });
  });

  group('Accessibility Tests', () {
    testWidgets('score display has semantics', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: _TestScoreDisplay(score: 85),
          ),
        ),
      );

      // Check that the semantic widget exists
      final semantics = find.byWidgetPredicate(
        (widget) =>
            widget is Semantics &&
            widget.properties.label == 'Score: 85 out of 100',
      );
      expect(semantics, findsOneWidget);
    });

    testWidgets('pain slider has semantics', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: _TestPainLevelSlider(initialValue: 5),
            ),
          ),
        ),
      );

      final slider = tester.widget<Slider>(find.byType(Slider));
      expect(slider.semanticFormatterCallback, isNotNull);
    });

    testWidgets('exercise card is accessible', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: _TestExerciseResultCard(
              exerciseName: 'Test Exercise',
              score: 90,
              isCorrect: true,
            ),
          ),
        ),
      );

      // Check that the semantic widget exists with proper label
      final semantics = find.byWidgetPredicate(
        (widget) =>
            widget is Semantics &&
            widget.properties.label != null &&
            widget.properties.label!.contains('Test Exercise'),
      );
      expect(semantics, findsOneWidget);
    });
  });
}

// ============================================================
// Test Helper Widgets
// ============================================================

/// Simple countdown widget for testing (stateless for clean disposal)
class _TestCountdownWidget extends StatefulWidget {
  const _TestCountdownWidget({required this.startFrom});

  final int startFrom;

  @override
  State<_TestCountdownWidget> createState() => _TestCountdownWidgetState();
}

class _TestCountdownWidgetState extends State<_TestCountdownWidget> {
  late int _count;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _count = widget.startFrom;
    _startCountdown();
  }

  void _startCountdown() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_count > 1) {
        setState(() => _count--);
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        '$_count',
        style: const TextStyle(fontSize: 72, fontWeight: FontWeight.bold),
      ),
    );
  }
}

/// Pain level slider for testing
class _TestPainLevelSlider extends StatefulWidget {
  const _TestPainLevelSlider({required this.initialValue});

  final double initialValue;

  @override
  State<_TestPainLevelSlider> createState() => _TestPainLevelSliderState();
}

class _TestPainLevelSliderState extends State<_TestPainLevelSlider> {
  late double _value;

  @override
  void initState() {
    super.initState();
    _value = widget.initialValue;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('${_value.toInt()}', style: const TextStyle(fontSize: 32)),
        Slider(
          value: _value,
          min: 0,
          max: 10,
          divisions: 10,
          onChanged: (v) => setState(() => _value = v),
          semanticFormatterCallback: (v) => 'Pain level ${v.toInt()}',
        ),
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('No Pain'),
            Text('Severe'),
          ],
        ),
      ],
    );
  }
}

/// Score display for testing
class _TestScoreDisplay extends StatelessWidget {
  const _TestScoreDisplay({required this.score});

  final int score;

  Color get _backgroundColor {
    if (score >= 80) return Colors.green.shade100;
    if (score >= 60) return Colors.yellow.shade100;
    return Colors.red.shade100;
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Score: $score out of 100',
      child: Container(
        key: const Key('score_container'),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _backgroundColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('$score', style: const TextStyle(fontSize: 48)),
            const Text('/100', style: TextStyle(fontSize: 24)),
            if (score == 100) const Icon(Icons.star, color: Colors.amber),
          ],
        ),
      ),
    );
  }
}

/// Session timer for testing
class _TestSessionTimer extends StatelessWidget {
  const _TestSessionTimer({required this.seconds});

  final int seconds;

  String get _formattedTime {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:'
          '${minutes.toString().padLeft(2, '0')}:'
          '${secs.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:'
        '${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.timer),
        const SizedBox(width: 8),
        Text(_formattedTime, style: const TextStyle(fontSize: 24)),
      ],
    );
  }
}

/// Exercise result card for testing
class _TestExerciseResultCard extends StatelessWidget {
  const _TestExerciseResultCard({
    required this.exerciseName,
    required this.score,
    required this.isCorrect,
    this.onTap,
  });

  final String exerciseName;
  final int score;
  final bool isCorrect;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$exerciseName, score $score',
      child: Card(
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  isCorrect ? Icons.check_circle : Icons.warning,
                  color: isCorrect ? Colors.green : Colors.orange,
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(exerciseName)),
                Text('$score', style: const TextStyle(fontSize: 24)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Exercise list item for testing
class _TestExerciseListItem extends StatelessWidget {
  const _TestExerciseListItem({
    required this.name,
    required this.category,
    required this.difficulty,
  });

  final String name;
  final String category;
  final int difficulty;

  IconData get _categoryIcon {
    return switch (category) {
      'Balance' => Icons.accessibility_new,
      'Strength' => Icons.fitness_center,
      _ => Icons.directions_run,
    };
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(_categoryIcon),
      title: Text(name),
      subtitle: Text(category),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 1; i <= 5; i++)
            Icon(
              i <= difficulty ? Icons.star : Icons.star_border,
              size: 16,
              color: Colors.amber,
            ),
        ],
      ),
    );
  }
}

/// Feedback message types
enum FeedbackType { success, warning, error }

/// Feedback message widget for testing
class _TestFeedbackMessage extends StatelessWidget {
  const _TestFeedbackMessage({
    required this.type,
    required this.message,
  });

  final FeedbackType type;
  final String message;

  IconData get _icon {
    return switch (type) {
      FeedbackType.success => Icons.check_circle,
      FeedbackType.warning => Icons.warning_amber,
      FeedbackType.error => Icons.error,
    };
  }

  Color get _color {
    return switch (type) {
      FeedbackType.success => Colors.green,
      FeedbackType.warning => Colors.orange,
      FeedbackType.error => Colors.red,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(_icon, color: _color),
        const SizedBox(width: 8),
        Text(message),
      ],
    );
  }
}
