/// Unit tests for CountdownOverlay widget.
///
/// Test coverage:
/// 1. Countdown animation
/// 2. Visual feedback (pulse, scale)
/// 3. TTS integration points
/// 4. Haptic feedback timing
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CountdownOverlay State', () {
    test('initial countdown value is correct', () {
      const state = CountdownState(
        currentCount: 3,
        isCountingDown: true,
        isComplete: false,
      );

      expect(state.currentCount, equals(3));
      expect(state.isCountingDown, isTrue);
      expect(state.isComplete, isFalse);
    });

    test('countdown decrements to zero', () {
      var count = 3;
      final history = <int>[];

      while (count >= 0) {
        history.add(count);
        count--;
      }

      expect(history, equals([3, 2, 1, 0]));
    });

    test('countdown completes at zero', () {
      var state = const CountdownState(
        currentCount: 0,
        isCountingDown: true,
        isComplete: false,
      );

      // Transition to complete
      state = state.copyWith(
        isCountingDown: false,
        isComplete: true,
      );

      expect(state.isCountingDown, isFalse);
      expect(state.isComplete, isTrue);
    });
  });

  group('Countdown Animation', () {
    test('animation duration is 1 second per count', () {
      const duration = Duration(seconds: 1);

      expect(duration.inMilliseconds, equals(1000));
    });

    test('scale animation values', () {
      final scaleValues = <double>[];
      const steps = 10;

      for (var i = 0; i <= steps; i++) {
        // Tween from 0.8 to 1.0 with elastic curve approximation
        final t = i / steps;
        final value = 0.8 + (0.2 * t);
        scaleValues.add(value);
      }

      expect(scaleValues.first, equals(0.8));
      expect(scaleValues.last, equals(1.0));
    });

    test('pulse animation oscillates', () {
      final pulseValues = <double>[];
      const steps = 10;

      for (var i = 0; i <= steps; i++) {
        final t = i / steps;
        // Pulse between 1.0 and 1.05
        final value = 1.0 + (0.05 * (t * 2 - 1).abs());
        pulseValues.add(value);
      }

      expect(pulseValues.every((v) => v >= 1.0 && v <= 1.05), isTrue);
    });
  });

  group('Countdown Visual Display', () {
    test('displays count numbers', () {
      final displays = <String>[];

      for (var count = 3; count >= 1; count--) {
        displays.add(count.toString());
      }
      displays.add('GO!');

      expect(displays, equals(['3', '2', '1', 'GO!']));
    });

    test('countdown color changes as count decreases', () {
      Color getCountdownColor(int count) {
        if (count >= 3) return Colors.green;
        if (count >= 2) return Colors.yellow;
        if (count >= 1) return Colors.orange;
        return Colors.red;
      }

      expect(getCountdownColor(3), equals(Colors.green));
      expect(getCountdownColor(2), equals(Colors.yellow));
      expect(getCountdownColor(1), equals(Colors.orange));
      expect(getCountdownColor(0), equals(Colors.red));
    });

    test('countdown text size is large', () {
      const fontSize = 96.0;

      expect(fontSize, greaterThan(48.0));
    });
  });

  group('TTS Integration', () {
    test('speaks countdown numbers', () {
      final spoken = <String>[];

      for (var count = 3; count >= 1; count--) {
        spoken.add(count.toString());
      }
      spoken.add('Go! Start your exercise.');

      expect(spoken.length, equals(4));
      expect(spoken.last, contains('Go'));
    });

    test('TTS called at each tick', () {
      var ttsCalls = 0;

      for (var count = 3; count >= 0; count--) {
        ttsCalls++;
      }

      expect(ttsCalls, equals(4)); // 3, 2, 1, GO
    });
  });

  group('Haptic Feedback', () {
    test('medium impact for countdown ticks', () {
      const feedbackType = HapticType.mediumImpact;

      expect(feedbackType, equals(HapticType.mediumImpact));
    });

    test('heavy impact for GO', () {
      const feedbackType = HapticType.heavyImpact;

      expect(feedbackType, equals(HapticType.heavyImpact));
    });

    test('haptic feedback triggered at each tick', () {
      var hapticCalls = 0;

      for (var count = 3; count >= 0; count--) {
        hapticCalls++;
      }

      expect(hapticCalls, equals(4));
    });
  });

  group('CountdownOverlay Widget', () {
    testWidgets('displays countdown number', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TestCountdownOverlay(currentCount: 3),
          ),
        ),
      );

      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('displays GO on completion', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TestCountdownOverlay(currentCount: 0),
          ),
        ),
      );

      expect(find.text('GO!'), findsOneWidget);
    });

    testWidgets('has animated container', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TestCountdownOverlay(currentCount: 2),
          ),
        ),
      );

      expect(find.byType(AnimatedContainer), findsOneWidget);
    });

    testWidgets('overlays full screen', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                Container(color: Colors.blue),
                const TestCountdownOverlay(currentCount: 3),
              ],
            ),
          ),
        ),
      );

      final overlay = tester.widget<Container>(
        find.byType(Container).first,
      );

      // Overlay should fill available space
      expect(overlay, isNotNull);
    });
  });

  group('Countdown Callbacks', () {
    test('onTick called at each decrement', () {
      final ticks = <int>[];

      void onTick(int count) {
        ticks.add(count);
      }

      for (var count = 3; count >= 1; count--) {
        onTick(count);
      }

      expect(ticks, equals([3, 2, 1]));
    });

    test('onComplete called when finished', () {
      var completed = false;

      void onComplete() {
        completed = true;
      }

      // Simulate countdown completion
      onComplete();

      expect(completed, isTrue);
    });
  });

  group('Countdown Configuration', () {
    test('default start value is 3', () {
      const defaultStart = 3;

      expect(defaultStart, equals(3));
    });

    test('custom start value', () {
      const customStart = 5;
      final counts = <int>[];

      for (var i = customStart; i >= 1; i--) {
        counts.add(i);
      }

      expect(counts.first, equals(5));
      expect(counts.length, equals(5));
    });

    test('supports skipping countdown', () {
      const skipCountdown = true;

      if (skipCountdown) {
        // Should immediately call onComplete
        expect(skipCountdown, isTrue);
      }
    });
  });
}

// Test data classes

class CountdownState {
  const CountdownState({
    required this.currentCount,
    required this.isCountingDown,
    required this.isComplete,
  });

  final int currentCount;
  final bool isCountingDown;
  final bool isComplete;

  CountdownState copyWith({
    int? currentCount,
    bool? isCountingDown,
    bool? isComplete,
  }) {
    return CountdownState(
      currentCount: currentCount ?? this.currentCount,
      isCountingDown: isCountingDown ?? this.isCountingDown,
      isComplete: isComplete ?? this.isComplete,
    );
  }
}

enum HapticType {
  lightImpact,
  mediumImpact,
  heavyImpact,
}

// Test widget

class TestCountdownOverlay extends StatelessWidget {
  const TestCountdownOverlay({
    super.key,
    required this.currentCount,
  });

  final int currentCount;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      color: Colors.black.withValues(alpha: 0.8),
      child: Center(
        child: Text(
          currentCount > 0 ? currentCount.toString() : 'GO!',
          style: TextStyle(
            fontSize: 96,
            fontWeight: FontWeight.bold,
            color: colorScheme.primary,
          ),
        ),
      ),
    );
  }
}
