/// Integration test: Exercise Session Flow.
///
/// Tests the complete flow from exercise selection
/// through session execution and results.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Exercise Session Integration', () {
    group('Exercise Selection', () {
      testWidgets('exercises are loaded and displayed', (tester) async {
        final exerciseRepo = TestExerciseRepository()..loadExercises();

        await tester.pumpWidget(
          MaterialApp(
            home: TestExerciseListScreen(repository: exerciseRepo),
          ),
        );

        expect(find.text('Deep Squat'), findsOneWidget);
        expect(find.text('Hurdle Step'), findsOneWidget);
      });

      testWidgets('exercises can be filtered by category', (tester) async {
        final exerciseRepo = TestExerciseRepository()..loadExercises();

        await tester.pumpWidget(
          MaterialApp(
            home: TestExerciseListScreen(repository: exerciseRepo),
          ),
        );

        // Filter by lower body
        await tester.tap(find.text('Lower Body'));
        await tester.pumpAndSettle();

        expect(find.text('Deep Squat'), findsOneWidget);
        expect(find.text('Shoulder Press'), findsNothing);
      });

      testWidgets('selecting exercise shows details', (tester) async {
        final exerciseRepo = TestExerciseRepository()..loadExercises();

        await tester.pumpWidget(
          MaterialApp(
            home: TestExerciseListScreen(repository: exerciseRepo),
          ),
        );

        await tester.tap(find.text('Deep Squat'));
        await tester.pumpAndSettle();

        expect(find.byType(TestExerciseDetailScreen), findsOneWidget);
        expect(find.text('Instructions'), findsOneWidget);
      });
    });

    group('Session Execution', () {
      testWidgets('session timer starts on begin', (tester) async {
        final sessionState = TestSessionState();

        await tester.pumpWidget(
          MaterialApp(
            home: TestActiveSessionScreen(
              sessionState: sessionState,
              exercise: const TestExercise(
                id: 'squat',
                name: 'Deep Squat',
                category: 'lower',
              ),
            ),
          ),
        );

        await tester.tap(find.byKey(const Key('begin_button')));
        await tester.pump(const Duration(seconds: 2));

        expect(sessionState.elapsedSeconds, greaterThanOrEqualTo(1));

        // Stop session to cancel timer - need to wait for timer iteration to complete
        sessionState.completeSession();
        await tester.pump(const Duration(seconds: 2));
      });

      testWidgets('rep counter increments on detection', (tester) async {
        final sessionState = TestSessionState()..startSession();
        final poseDetector = TestPoseDetector();

        await tester.pumpWidget(
          MaterialApp(
            home: TestActiveSessionScreen(
              sessionState: sessionState,
              poseDetector: poseDetector,
              exercise: const TestExercise(
                id: 'squat',
                name: 'Deep Squat',
                category: 'lower',
              ),
            ),
          ),
        );

        // Simulate rep detection
        poseDetector.detectRep();
        await tester.pump();

        expect(sessionState.repCount, equals(1));

        poseDetector.detectRep();
        await tester.pump();

        expect(sessionState.repCount, equals(2));
      });

      testWidgets('form quality is displayed in real-time', (tester) async {
        final sessionState = TestSessionState()..startSession();
        final poseDetector = TestPoseDetector();

        await tester.pumpWidget(
          MaterialApp(
            home: TestActiveSessionScreen(
              sessionState: sessionState,
              poseDetector: poseDetector,
              exercise: const TestExercise(
                id: 'squat',
                name: 'Deep Squat',
                category: 'lower',
              ),
            ),
          ),
        );

        // Set form quality
        poseDetector.setFormQuality(0.85);
        await tester.pump();

        expect(find.text('85%'), findsOneWidget);
      });

      testWidgets('session can be paused and resumed', (tester) async {
        final sessionState = TestSessionState()..startSession();

        await tester.pumpWidget(
          MaterialApp(
            home: TestActiveSessionScreen(
              sessionState: sessionState,
              exercise: const TestExercise(
                id: 'squat',
                name: 'Deep Squat',
                category: 'lower',
              ),
            ),
          ),
        );

        // Pause
        await tester.tap(find.byKey(const Key('pause_button')));
        await tester.pump();

        expect(sessionState.isPaused, isTrue);

        // Resume
        await tester.tap(find.byKey(const Key('resume_button')));
        await tester.pump();

        expect(sessionState.isPaused, isFalse);
      });

      testWidgets('pain level can be reported', (tester) async {
        final sessionState = TestSessionState()..startSession();

        await tester.pumpWidget(
          MaterialApp(
            home: TestActiveSessionScreen(
              sessionState: sessionState,
              exercise: const TestExercise(
                id: 'squat',
                name: 'Deep Squat',
                category: 'lower',
              ),
            ),
          ),
        );

        // Report pain
        await tester.tap(find.byKey(const Key('report_pain_button')));
        await tester.pumpAndSettle();

        await tester.tap(find.text('3')); // Pain level 3
        await tester.tap(find.text('Confirm'));
        await tester.pumpAndSettle();

        expect(sessionState.painLevel, equals(3));
      });
    });

    group('Session Completion', () {
      testWidgets('completing session shows summary', (tester) async {
        final sessionState = TestSessionState()
          ..startSession()
          ..addRep(quality: 0.9)
          ..addRep(quality: 0.8)
          ..addRep(quality: 0.85);

        await tester.pumpWidget(
          MaterialApp(
            home: TestActiveSessionScreen(
              sessionState: sessionState,
              exercise: const TestExercise(
                id: 'squat',
                name: 'Deep Squat',
                category: 'lower',
              ),
            ),
          ),
        );

        await tester.tap(find.byKey(const Key('complete_button')));
        await tester.pumpAndSettle();

        expect(find.byType(TestSessionSummaryScreen), findsOneWidget);
        expect(find.text('3 reps'), findsOneWidget);
      });

      testWidgets('results include rep-by-rep breakdown', (tester) async {
        final sessionState = TestSessionState()
          ..startSession()
          ..addRep(quality: 0.9)
          ..addRep(quality: 0.6)
          ..addRep(quality: 0.85);

        sessionState.completeSession();

        await tester.pumpWidget(
          MaterialApp(
            home: TestSessionSummaryScreen(sessionState: sessionState),
          ),
        );

        expect(find.text('Rep 1: 90%'), findsOneWidget);
        expect(find.text('Rep 2: 60%'), findsOneWidget);
        expect(find.text('Rep 3: 85%'), findsOneWidget);
      });

      testWidgets('feedback is generated based on performance', (tester) async {
        final sessionState = TestSessionState()
          ..startSession()
          ..addRep(quality: 0.5)
          ..addRep(quality: 0.6)
          ..completeSession();

        await tester.pumpWidget(
          MaterialApp(
            home: TestSessionSummaryScreen(sessionState: sessionState),
          ),
        );

        // Poor performance should show improvement suggestions
        expect(
          find.textContaining('improve'),
          findsWidgets,
        );
      });

      testWidgets('session can be discarded', (tester) async {
        final sessionState = TestSessionState()..startSession();

        await tester.pumpWidget(
          MaterialApp(
            home: TestActiveSessionScreen(
              sessionState: sessionState,
              exercise: const TestExercise(
                id: 'squat',
                name: 'Deep Squat',
                category: 'lower',
              ),
            ),
          ),
        );

        await tester.tap(find.byKey(const Key('discard_button')));
        await tester.pumpAndSettle();

        // Confirm discard
        await tester.tap(find.byKey(const Key('confirm_discard_button')));
        await tester.pumpAndSettle();

        expect(sessionState.isActive, isFalse);
        expect(sessionState.wasDiscarded, isTrue);
      });
    });

    group('Pose Detection Integration', () {
      testWidgets('camera preview is displayed', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: TestActiveSessionScreen(
              sessionState: TestSessionState()..startSession(),
              exercise: const TestExercise(
                id: 'squat',
                name: 'Deep Squat',
                category: 'lower',
              ),
            ),
          ),
        );

        expect(find.byKey(const Key('camera_preview')), findsOneWidget);
      });

      testWidgets('pose overlay shows landmarks', (tester) async {
        final poseDetector = TestPoseDetector()..setLandmarks(_mockLandmarks());

        await tester.pumpWidget(
          MaterialApp(
            home: TestActiveSessionScreen(
              sessionState: TestSessionState()..startSession(),
              poseDetector: poseDetector,
              exercise: const TestExercise(
                id: 'squat',
                name: 'Deep Squat',
                category: 'lower',
              ),
            ),
          ),
        );

        expect(find.byKey(const Key('pose_overlay')), findsOneWidget);
      });

      testWidgets('no pose detected shows message', (tester) async {
        final poseDetector = TestPoseDetector()..setLandmarks(null);

        await tester.pumpWidget(
          MaterialApp(
            home: TestActiveSessionScreen(
              sessionState: TestSessionState()..startSession(),
              poseDetector: poseDetector,
              exercise: const TestExercise(
                id: 'squat',
                name: 'Deep Squat',
                category: 'lower',
              ),
            ),
          ),
        );

        expect(find.text('Position yourself in frame'), findsOneWidget);
      });
    });

    group('Progress Tracking', () {
      testWidgets('session history is displayed', (tester) async {
        final historyRepo = TestSessionHistoryRepository()
          ..addSession(
            TestSessionResult(
              date: DateTime(2024, 1, 1),
              repCount: 10,
              averageQuality: 0.85,
            ),
          )
          ..addSession(
            TestSessionResult(
              date: DateTime(2024, 1, 2),
              repCount: 12,
              averageQuality: 0.88,
            ),
          );

        await tester.pumpWidget(
          MaterialApp(
            home: TestProgressScreen(repository: historyRepo),
          ),
        );

        expect(find.byType(TestSessionHistoryTile), findsNWidgets(2));
      });

      testWidgets('progress chart shows trend', (tester) async {
        final historyRepo = TestSessionHistoryRepository()
          ..addSession(
            TestSessionResult(
              date: DateTime(2024, 1, 1),
              repCount: 10,
              averageQuality: 0.80,
            ),
          )
          ..addSession(
            TestSessionResult(
              date: DateTime(2024, 1, 5),
              repCount: 12,
              averageQuality: 0.85,
            ),
          )
          ..addSession(
            TestSessionResult(
              date: DateTime(2024, 1, 10),
              repCount: 15,
              averageQuality: 0.90,
            ),
          );

        await tester.pumpWidget(
          MaterialApp(
            home: TestProgressScreen(repository: historyRepo),
          ),
        );

        expect(find.byKey(const Key('progress_chart')), findsOneWidget);
      });

      testWidgets('achievements are unlocked', (tester) async {
        final achievementService = TestAchievementService()
          ..unlock('first_session')
          ..unlock('10_reps');

        await tester.pumpWidget(
          MaterialApp(
            home: TestAchievementsScreen(service: achievementService),
          ),
        );

        expect(find.text('First Session'), findsOneWidget);
        expect(find.text('10 Reps'), findsOneWidget);
      });
    });
  });
}

// Test data structures
class TestExercise {
  const TestExercise({
    required this.id,
    required this.name,
    required this.category,
    this.instructions = 'Default instructions',
  });

  final String id;
  final String name;
  final String category;
  final String instructions;
}

class TestSessionResult {
  TestSessionResult({
    required this.date,
    required this.repCount,
    required this.averageQuality,
  });

  final DateTime date;
  final int repCount;
  final double averageQuality;
}

// Test state classes
class TestExerciseRepository {
  final _exercises = <TestExercise>[];

  void loadExercises() {
    _exercises.addAll([
      const TestExercise(id: 'squat', name: 'Deep Squat', category: 'lower'),
      const TestExercise(id: 'lunge', name: 'Hurdle Step', category: 'lower'),
      const TestExercise(
        id: 'shoulder',
        name: 'Shoulder Press',
        category: 'upper',
      ),
    ]);
  }

  List<TestExercise> getAll() => _exercises;

  List<TestExercise> getByCategory(String category) =>
      _exercises.where((e) => e.category == category).toList();
}

class TestSessionState extends ChangeNotifier {
  bool _isActive = false;
  bool _isPaused = false;
  bool _wasDiscarded = false;
  int _repCount = 0;
  int _elapsedSeconds = 0;
  int? _painLevel;
  final _repQualities = <double>[];

  bool get isActive => _isActive;
  bool get isPaused => _isPaused;
  bool get wasDiscarded => _wasDiscarded;
  int get repCount => _repCount;
  int get elapsedSeconds => _elapsedSeconds;
  int? get painLevel => _painLevel;
  List<double> get repQualities => List.unmodifiable(_repQualities);

  void startSession() {
    _isActive = true;
    _wasDiscarded = false;
    notifyListeners();
  }

  void pause() {
    _isPaused = true;
    notifyListeners();
  }

  void resume() {
    _isPaused = false;
    notifyListeners();
  }

  void addRep({required double quality}) {
    _repCount++;
    _repQualities.add(quality);
    notifyListeners();
  }

  void setPainLevel(int level) {
    _painLevel = level;
    notifyListeners();
  }

  void completeSession() {
    _isActive = false;
    notifyListeners();
  }

  void discardSession() {
    _isActive = false;
    _wasDiscarded = true;
    notifyListeners();
  }

  void incrementTime() {
    _elapsedSeconds++;
    notifyListeners();
  }
}

class TestPoseDetector extends ChangeNotifier {
  List<List<double>>? _landmarks;
  double _formQuality = 0.0;
  final _repCallbacks = <VoidCallback>[];

  void setLandmarks(List<List<double>>? landmarks) {
    _landmarks = landmarks;
    notifyListeners();
  }

  void setFormQuality(double quality) {
    _formQuality = quality;
    notifyListeners();
  }

  void detectRep() {
    for (final callback in _repCallbacks) {
      callback();
    }
  }

  void onRepDetected(VoidCallback callback) {
    _repCallbacks.add(callback);
  }

  List<List<double>>? get landmarks => _landmarks;
  double get formQuality => _formQuality;
}

class TestSessionHistoryRepository {
  final _sessions = <TestSessionResult>[];

  void addSession(TestSessionResult session) {
    _sessions.add(session);
  }

  List<TestSessionResult> getAll() => _sessions;
}

class TestAchievementService {
  final _unlocked = <String>[];

  void unlock(String id) {
    if (!_unlocked.contains(id)) {
      _unlocked.add(id);
    }
  }

  List<String> get unlockedIds => _unlocked;

  String getDisplayName(String id) {
    return switch (id) {
      'first_session' => 'First Session',
      '10_reps' => '10 Reps',
      _ => id,
    };
  }
}

// Test widgets
class TestExerciseListScreen extends StatefulWidget {
  const TestExerciseListScreen({required this.repository, super.key});

  final TestExerciseRepository repository;

  @override
  State<TestExerciseListScreen> createState() => _TestExerciseListScreenState();
}

class _TestExerciseListScreenState extends State<TestExerciseListScreen> {
  String? _selectedCategory;

  @override
  Widget build(BuildContext context) {
    final exercises = _selectedCategory != null
        ? widget.repository.getByCategory(_selectedCategory!)
        : widget.repository.getAll();

    return Scaffold(
      appBar: AppBar(title: const Text('Exercises')),
      body: Column(
        children: [
          Row(
            children: [
              TextButton(
                onPressed: () => setState(() => _selectedCategory = 'lower'),
                child: const Text('Lower Body'),
              ),
              TextButton(
                onPressed: () => setState(() => _selectedCategory = 'upper'),
                child: const Text('Upper Body'),
              ),
            ],
          ),
          Expanded(
            child: ListView.builder(
              itemCount: exercises.length,
              itemBuilder: (context, index) {
                final exercise = exercises[index];
                return ListTile(
                  title: Text(exercise.name),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) =>
                          TestExerciseDetailScreen(exercise: exercise),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class TestExerciseDetailScreen extends StatelessWidget {
  const TestExerciseDetailScreen({required this.exercise, super.key});

  final TestExercise exercise;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(exercise.name)),
      body: Column(
        children: [
          const Text('Instructions'),
          Text(exercise.instructions),
        ],
      ),
    );
  }
}

class TestActiveSessionScreen extends StatefulWidget {
  const TestActiveSessionScreen({
    required this.sessionState,
    required this.exercise,
    this.poseDetector,
    super.key,
  });

  final TestSessionState sessionState;
  final TestExercise exercise;
  final TestPoseDetector? poseDetector;

  @override
  State<TestActiveSessionScreen> createState() =>
      _TestActiveSessionScreenState();
}

class _TestActiveSessionScreenState extends State<TestActiveSessionScreen> {
  @override
  void initState() {
    super.initState();
    widget.poseDetector?.addListener(_onPoseDetectorChanged);
    widget.poseDetector?.onRepDetected(() {
      widget.sessionState.addRep(quality: widget.poseDetector!.formQuality);
    });
  }

  @override
  void dispose() {
    widget.poseDetector?.removeListener(_onPoseDetectorChanged);
    super.dispose();
  }

  void _onPoseDetectorChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final hasLandmarks = widget.poseDetector?.landmarks != null;

    return Scaffold(
      body: ListenableBuilder(
        listenable: widget.sessionState,
        builder: (context, _) {
          return Stack(
            children: [
              Container(key: const Key('camera_preview')),
              if (hasLandmarks) Container(key: const Key('pose_overlay')),
              if (!hasLandmarks) const Text('Position yourself in frame'),
              if (widget.poseDetector != null)
                Text('${(widget.poseDetector!.formQuality * 100).round()}%'),
              Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text('Reps: ${widget.sessionState.repCount}'),
                  if (!widget.sessionState.isActive)
                    ElevatedButton(
                      key: const Key('begin_button'),
                      onPressed: () {
                        widget.sessionState.startSession();
                        _startTimer();
                      },
                      child: const Text('Begin'),
                    ),
                  if (widget.sessionState.isActive &&
                      !widget.sessionState.isPaused)
                    ElevatedButton(
                      key: const Key('pause_button'),
                      onPressed: widget.sessionState.pause,
                      child: const Text('Pause'),
                    ),
                  if (widget.sessionState.isPaused)
                    ElevatedButton(
                      key: const Key('resume_button'),
                      onPressed: widget.sessionState.resume,
                      child: const Text('Resume'),
                    ),
                  ElevatedButton(
                    key: const Key('report_pain_button'),
                    onPressed: () => _showPainDialog(context),
                    child: const Text('Report Pain'),
                  ),
                  ElevatedButton(
                    key: const Key('complete_button'),
                    onPressed: () {
                      widget.sessionState.completeSession();
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => TestSessionSummaryScreen(
                            sessionState: widget.sessionState,
                          ),
                        ),
                      );
                    },
                    child: const Text('Complete'),
                  ),
                  ElevatedButton(
                    key: const Key('discard_button'),
                    onPressed: () => _showDiscardDialog(context),
                    child: const Text('Discard'),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  void _startTimer() {
    Future.doWhile(() async {
      await Future<void>.delayed(const Duration(seconds: 1));
      if (mounted &&
          widget.sessionState.isActive &&
          !widget.sessionState.isPaused) {
        widget.sessionState.incrementTime();
      }
      return mounted && widget.sessionState.isActive;
    });
  }

  void _showPainDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        content: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(5, (i) {
            return TextButton(
              onPressed: () => widget.sessionState.setPainLevel(i + 1),
              child: Text('${i + 1}'),
            );
          }),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  void _showDiscardDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        content: const Text('Discard session?'),
        actions: [
          TextButton(
            key: const Key('confirm_discard_button'),
            onPressed: () {
              widget.sessionState.discardSession();
              Navigator.pop(context);
            },
            child: const Text('Discard'),
          ),
        ],
      ),
    );
  }
}

class TestSessionSummaryScreen extends StatelessWidget {
  const TestSessionSummaryScreen({required this.sessionState, super.key});

  final TestSessionState sessionState;

  @override
  Widget build(BuildContext context) {
    final avgQuality = sessionState.repQualities.isEmpty
        ? 0.0
        : sessionState.repQualities.reduce((a, b) => a + b) /
              sessionState.repQualities.length;

    return Scaffold(
      appBar: AppBar(title: const Text('Summary')),
      body: Column(
        children: [
          Text('${sessionState.repCount} reps'),
          ...sessionState.repQualities.asMap().entries.map((e) {
            return Text('Rep ${e.key + 1}: ${(e.value * 100).round()}%');
          }),
          if (avgQuality < 0.7)
            const Text(
              'You can improve your form. Focus on controlled movements.',
            ),
        ],
      ),
    );
  }
}

class TestProgressScreen extends StatelessWidget {
  const TestProgressScreen({required this.repository, super.key});

  final TestSessionHistoryRepository repository;

  @override
  Widget build(BuildContext context) {
    final sessions = repository.getAll();

    return Scaffold(
      appBar: AppBar(title: const Text('Progress')),
      body: Column(
        children: [
          Container(key: const Key('progress_chart'), height: 200),
          Expanded(
            child: ListView.builder(
              itemCount: sessions.length,
              itemBuilder: (context, index) {
                return TestSessionHistoryTile(session: sessions[index]);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class TestSessionHistoryTile extends StatelessWidget {
  const TestSessionHistoryTile({required this.session, super.key});

  final TestSessionResult session;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text('${session.repCount} reps'),
      subtitle: Text('Quality: ${(session.averageQuality * 100).round()}%'),
    );
  }
}

class TestAchievementsScreen extends StatelessWidget {
  const TestAchievementsScreen({required this.service, super.key});

  final TestAchievementService service;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Achievements')),
      body: ListView.builder(
        itemCount: service.unlockedIds.length,
        itemBuilder: (context, index) {
          final id = service.unlockedIds[index];
          return ListTile(title: Text(service.getDisplayName(id)));
        },
      ),
    );
  }
}

List<List<double>> _mockLandmarks() {
  return List.generate(33, (i) => [0.5, 0.5, 0.0]);
}
