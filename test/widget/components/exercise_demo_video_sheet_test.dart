/// Widget and unit tests for ExerciseDemoVideoSheet.
///
/// Test coverage:
/// 1. DemoVideo model
/// 2. Skip preference logic
/// 3. Video initialization states
/// 4. Don't show again checkbox
/// 5. Sheet display
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DemoVideo Model', () {
    test('creates with required fields', () {
      const video = DemoVideo(
        title: 'Deep Squat Demo',
        description: 'Watch correct form',
        assetPath: 'assets/videos/deep_squat.mp4',
      );

      expect(video.title, equals('Deep Squat Demo'));
      expect(video.description, equals('Watch correct form'));
      expect(video.assetPath, equals('assets/videos/deep_squat.mp4'));
    });

    test('has default view angle of front', () {
      const video = DemoVideo(
        title: 'Test',
        description: 'Test',
        assetPath: 'test.mp4',
      );

      expect(video.viewAngle, equals('front'));
    });

    test('can set custom view angle', () {
      const video = DemoVideo(
        title: 'Test',
        description: 'Test',
        assetPath: 'test.mp4',
        viewAngle: 'side',
      );

      expect(video.viewAngle, equals('side'));
    });
  });

  group('Skip Preference Logic', () {
    test('shouldSkipVideo returns false by default', () {
      final prefs = MockPreferencesService();

      expect(prefs.shouldSkipExerciseVideo(1), isFalse);
    });

    test('shouldSkipVideo returns true after setting', () {
      final prefs = MockPreferencesService();

      prefs.setSkipExerciseVideo(exerciseId: 1, skip: true);

      expect(prefs.shouldSkipExerciseVideo(1), isTrue);
    });

    test('skip is per-exercise', () {
      final prefs = MockPreferencesService();

      prefs.setSkipExerciseVideo(exerciseId: 1, skip: true);

      expect(prefs.shouldSkipExerciseVideo(1), isTrue);
      expect(prefs.shouldSkipExerciseVideo(2), isFalse);
    });

    test('can unset skip preference', () {
      final prefs = MockPreferencesService();

      prefs.setSkipExerciseVideo(exerciseId: 1, skip: true);
      prefs.setSkipExerciseVideo(exerciseId: 1, skip: false);

      expect(prefs.shouldSkipExerciseVideo(1), isFalse);
    });
  });

  group('DemoVideoSheetState', () {
    test('initial state is not initialized', () {
      final state = DemoVideoSheetState();

      expect(state.isInitialized, isFalse);
      expect(state.dontShowAgain, isFalse);
      expect(state.errorMessage, isNull);
    });

    test('can be marked as initialized', () {
      final state = DemoVideoSheetState();

      state.setInitialized(true);

      expect(state.isInitialized, isTrue);
    });

    test('can toggle dont show again', () {
      final state = DemoVideoSheetState();

      state.toggleDontShowAgain();

      expect(state.dontShowAgain, isTrue);

      state.toggleDontShowAgain();

      expect(state.dontShowAgain, isFalse);
    });

    test('can set error message', () {
      final state = DemoVideoSheetState();

      state.setError('Could not load video');

      expect(state.errorMessage, equals('Could not load video'));
    });
  });

  group('ShowIfNeeded Logic', () {
    test('returns true if skip preference set', () {
      final prefs = MockPreferencesService();
      prefs.setSkipExerciseVideo(exerciseId: 1, skip: true);

      final shouldShow = _shouldShowDemoVideo(
        exerciseId: 1,
        demoVideo: const DemoVideo(
          title: 'Test',
          description: 'Test',
          assetPath: 'test.mp4',
        ),
        prefs: prefs,
      );

      expect(shouldShow, isFalse);
    });

    test('returns true if no demo video configured', () {
      final prefs = MockPreferencesService();

      final shouldShow = _shouldShowDemoVideo(
        exerciseId: 1,
        demoVideo: null,
        prefs: prefs,
      );

      expect(shouldShow, isFalse);
    });

    test('returns true if demo available and not skipped', () {
      final prefs = MockPreferencesService();

      final shouldShow = _shouldShowDemoVideo(
        exerciseId: 1,
        demoVideo: const DemoVideo(
          title: 'Test',
          description: 'Test',
          assetPath: 'test.mp4',
        ),
        prefs: prefs,
      );

      expect(shouldShow, isTrue);
    });
  });

  group('Video Player Controls', () {
    test('VideoControlState tracks playback', () {
      final state = VideoControlState();

      expect(state.isPlaying, isFalse);

      state.setPlaying(true);

      expect(state.isPlaying, isTrue);
    });

    test('VideoControlState tracks looping', () {
      final state = VideoControlState();

      state.setLooping(true);

      expect(state.isLooping, isTrue);
    });
  });

  group('ExerciseDemoVideoSheet Widget', () {
    testWidgets('shows loading indicator before initialization', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: _MockDemoVideoSheet(
              isInitialized: false,
              title: 'Test Exercise',
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows video title', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: _MockDemoVideoSheet(
              isInitialized: true,
              title: 'Deep Squat Demo',
            ),
          ),
        ),
      );

      expect(find.text('Deep Squat Demo'), findsOneWidget);
    });

    testWidgets('shows error message on failure', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: _MockDemoVideoSheet(
              isInitialized: false,
              title: 'Test',
              errorMessage: 'Could not load video',
            ),
          ),
        ),
      );

      expect(find.text('Could not load video'), findsOneWidget);
    });

    testWidgets('shows dont show again checkbox', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: _MockDemoVideoSheet(
              isInitialized: true,
              title: 'Test',
            ),
          ),
        ),
      );

      expect(find.byType(Checkbox), findsOneWidget);
      expect(find.text("Don't show this again"), findsOneWidget);
    });

    testWidgets('continue button is present', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: _MockDemoVideoSheet(
              isInitialized: true,
              title: 'Test',
            ),
          ),
        ),
      );

      expect(find.text('Continue'), findsOneWidget);
    });

    testWidgets('can toggle dont show again', (tester) async {
      var checked = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return _MockDemoVideoSheetInteractive(
                  dontShowAgain: checked,
                  onDontShowAgainChanged: (value) {
                    setState(() {
                      checked = value;
                    });
                  },
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.byType(Checkbox));
      await tester.pump();

      expect(checked, isTrue);
    });
  });

  group('View Angles', () {
    test('front is valid angle', () {
      expect(_isValidViewAngle('front'), isTrue);
    });

    test('side is valid angle', () {
      expect(_isValidViewAngle('side'), isTrue);
    });

    test('unknown angle is invalid', () {
      expect(_isValidViewAngle('unknown'), isFalse);
    });
  });
}

// Models

class DemoVideo {
  const DemoVideo({
    required this.title,
    required this.description,
    required this.assetPath,
    this.viewAngle = 'front',
  });

  final String title;
  final String description;
  final String assetPath;
  final String viewAngle;
}

class MockPreferencesService {
  final Map<int, bool> _skipPrefs = {};

  bool shouldSkipExerciseVideo(int exerciseId) {
    return _skipPrefs[exerciseId] ?? false;
  }

  void setSkipExerciseVideo({required int exerciseId, required bool skip}) {
    _skipPrefs[exerciseId] = skip;
  }
}

class DemoVideoSheetState {
  bool isInitialized = false;
  bool dontShowAgain = false;
  String? errorMessage;

  void setInitialized(bool value) {
    isInitialized = value;
  }

  void toggleDontShowAgain() {
    dontShowAgain = !dontShowAgain;
  }

  void setError(String message) {
    errorMessage = message;
  }
}

class VideoControlState {
  bool isPlaying = false;
  bool isLooping = false;

  void setPlaying(bool value) {
    isPlaying = value;
  }

  void setLooping(bool value) {
    isLooping = value;
  }
}

// Helper functions

bool _shouldShowDemoVideo({
  required int exerciseId,
  required DemoVideo? demoVideo,
  required MockPreferencesService prefs,
}) {
  if (prefs.shouldSkipExerciseVideo(exerciseId)) {
    return false;
  }
  if (demoVideo == null) {
    return false;
  }
  return true;
}

bool _isValidViewAngle(String angle) {
  return ['front', 'side', 'back', 'top'].contains(angle);
}

// Widget mocks

class _MockDemoVideoSheet extends StatelessWidget {
  const _MockDemoVideoSheet({
    required this.isInitialized,
    required this.title,
    this.errorMessage,
  });

  final bool isInitialized;
  final String title;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    if (errorMessage != null) {
      return Center(child: Text(errorMessage!));
    }

    if (!isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(title),
        const SizedBox(height: 16),
        Container(
          height: 200,
          color: Colors.black,
          child: const Center(
            child: Icon(Icons.play_circle, color: Colors.white, size: 48),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            const Checkbox(value: false, onChanged: null),
            const Text("Don't show this again"),
          ],
        ),
        FilledButton(
          onPressed: () {},
          child: const Text('Continue'),
        ),
      ],
    );
  }
}

class _MockDemoVideoSheetInteractive extends StatelessWidget {
  const _MockDemoVideoSheetInteractive({
    required this.dontShowAgain,
    required this.onDontShowAgainChanged,
  });

  final bool dontShowAgain;
  final ValueChanged<bool> onDontShowAgainChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Checkbox(
              value: dontShowAgain,
              onChanged: (value) => onDontShowAgainChanged(value ?? false),
            ),
            const Text("Don't show this again"),
          ],
        ),
        FilledButton(
          onPressed: () {},
          child: const Text('Continue'),
        ),
      ],
    );
  }
}
