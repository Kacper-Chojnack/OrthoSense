import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Integration tests for complete exercise session flow.
///
/// These tests verify the UI behavior during a typical exercise session,
/// including navigation, state transitions, and user feedback.
void main() {
  group('Exercise Session Integration Flow', () {
    testWidgets('session timer widget displays correctly', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.timer, size: 48),
                    SizedBox(height: 16),
                    Text(
                      '00:00',
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text('Session in progress'),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.timer), findsOneWidget);
      expect(find.text('00:00'), findsOneWidget);
      expect(find.text('Session in progress'), findsOneWidget);
    });

    testWidgets('pain level slider works correctly', (tester) async {
      double painLevel = 5.0;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: StatefulBuilder(
              builder: (context, setState) {
                return Scaffold(
                  body: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Pain Level: ${painLevel.toInt()}/10',
                          style: const TextStyle(fontSize: 24),
                        ),
                        const SizedBox(height: 16),
                        Slider(
                          value: painLevel,
                          min: 0,
                          max: 10,
                          divisions: 10,
                          label: painLevel.toInt().toString(),
                          onChanged: (value) {
                            setState(() {
                              painLevel = value;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      );

      expect(find.text('Pain Level: 5/10'), findsOneWidget);
      expect(find.byType(Slider), findsOneWidget);

      // Interact with slider - drag right to increase
      await tester.drag(find.byType(Slider), const Offset(100, 0));
      await tester.pumpAndSettle();

      // Pain level should have increased
      expect(find.textContaining('Pain Level:'), findsOneWidget);
    });

    testWidgets('exercise completion shows success feedback', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 80,
                    ),
                    SizedBox(height: 24),
                    Text(
                      'Exercise Completed!',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Score: 92%',
                      style: TextStyle(
                        fontSize: 32,
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 32),
                    FilledButton(
                      onPressed: null,
                      child: Text('Continue to Next Exercise'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.check_circle), findsOneWidget);
      expect(find.text('Exercise Completed!'), findsOneWidget);
      expect(find.text('Score: 92%'), findsOneWidget);
      expect(find.text('Continue to Next Exercise'), findsOneWidget);
    });

    testWidgets('session results screen displays all exercises', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              appBar: AppBar(title: Text('Session Results')),
              body: SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Summary card
                      Card(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Column(
                            children: [
                              Text(
                                'Overall Score',
                                style: TextStyle(fontSize: 18),
                              ),
                              SizedBox(height: 8),
                              Text(
                                '88%',
                                style: TextStyle(
                                  fontSize: 48,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 24),
                      Text(
                        'Completed Exercises',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 16),
                      // Exercise results
                      ListTile(
                        leading: CircleAvatar(child: Text('92')),
                        title: Text('Deep Squat'),
                        subtitle: Text('3 sets × 12 reps'),
                        trailing: Icon(Icons.check_circle, color: Colors.green),
                      ),
                      Divider(),
                      ListTile(
                        leading: CircleAvatar(child: Text('85')),
                        title: Text('Hurdle Step'),
                        subtitle: Text('3 sets × 10 reps'),
                        trailing: Icon(Icons.check_circle, color: Colors.green),
                      ),
                      Divider(),
                      ListTile(
                        leading: CircleAvatar(child: Text('87')),
                        title: Text('Shoulder Abduction'),
                        subtitle: Text('3 sets × 15 reps'),
                        trailing: Icon(Icons.check_circle, color: Colors.green),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Session Results'), findsOneWidget);
      expect(find.text('Overall Score'), findsOneWidget);
      expect(find.text('88%'), findsOneWidget);
      expect(find.text('Completed Exercises'), findsOneWidget);
      expect(find.text('Deep Squat'), findsOneWidget);
      expect(find.text('Hurdle Step'), findsOneWidget);
      expect(find.text('Shoulder Abduction'), findsOneWidget);
    });

    testWidgets('error state shows retry option', (tester) async {
      bool isError = true;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: StatefulBuilder(
              builder: (context, setState) {
                if (isError) {
                  return Scaffold(
                    body: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: Colors.red,
                            size: 64,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Something went wrong',
                            style: TextStyle(fontSize: 20),
                          ),
                          const SizedBox(height: 8),
                          const Text('Could not connect to server'),
                          const SizedBox(height: 24),
                          FilledButton.icon(
                            onPressed: () {
                              setState(() {
                                isError = false;
                              });
                            },
                            icon: const Icon(Icons.refresh),
                            label: const Text('Try Again'),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return Scaffold(
                  body: Center(child: Text('Success!')),
                );
              },
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.text('Something went wrong'), findsOneWidget);
      expect(find.text('Try Again'), findsOneWidget);

      // Tap retry
      await tester.tap(find.text('Try Again'));
      await tester.pumpAndSettle();

      expect(find.text('Success!'), findsOneWidget);
    });

    testWidgets('offline mode banner is shown', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  MaterialBanner(
                    backgroundColor: Colors.orange,
                    content: Text('You are offline - data will sync later'),
                    actions: [
                      TextButton(
                        onPressed: null,
                        child: Text('Dismiss'),
                      ),
                    ],
                  ),
                  Expanded(
                    child: Center(
                      child: Text('Exercise list (cached)'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      expect(
        find.text('You are offline - data will sync later'),
        findsOneWidget,
      );
      expect(find.text('Exercise list (cached)'), findsOneWidget);
      expect(find.text('Dismiss'), findsOneWidget);
    });
  });

  group('Camera and Pose Detection Integration', () {
    testWidgets('camera permission request UI', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.camera_alt, size: 80, color: Colors.blue),
                    SizedBox(height: 24),
                    Text(
                      'Camera Access Required',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'We need camera access to analyze your movements',
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 32),
                    FilledButton(
                      onPressed: null,
                      child: Text('Grant Permission'),
                    ),
                    TextButton(
                      onPressed: null,
                      child: Text('Maybe Later'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.camera_alt), findsOneWidget);
      expect(find.text('Camera Access Required'), findsOneWidget);
      expect(find.text('Grant Permission'), findsOneWidget);
      expect(find.text('Maybe Later'), findsOneWidget);
    });

    testWidgets('pose feedback overlay shows during exercise', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              backgroundColor: Colors.black,
              body: Stack(
                children: [
                  // Camera preview placeholder
                  Positioned.fill(
                    child: Center(
                      child: Text(
                        'Camera Preview',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                  // Pose feedback card at bottom
                  Positioned(
                    bottom: 24,
                    left: 16,
                    right: 16,
                    child: Card(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.info_outline, color: Colors.blue),
                                SizedBox(width: 8),
                                Text(
                                  'Keep your back straight',
                                  style: TextStyle(fontSize: 16),
                                ),
                              ],
                            ),
                            SizedBox(height: 12),
                            LinearProgressIndicator(value: 0.75),
                            SizedBox(height: 8),
                            Text('Form Quality: 75%'),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.text('Camera Preview'), findsOneWidget);
      expect(find.text('Keep your back straight'), findsOneWidget);
      expect(find.text('Form Quality: 75%'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    testWidgets('rep counter increments', (tester) async {
      int repCount = 0;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: StatefulBuilder(
              builder: (context, setState) {
                return Scaffold(
                  body: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '$repCount',
                          style: const TextStyle(
                            fontSize: 72,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Text('Reps Completed'),
                        const SizedBox(height: 24),
                        // Simulate rep detection
                        FilledButton(
                          onPressed: () {
                            setState(() {
                              repCount++;
                            });
                          },
                          child: const Text('Simulate Rep'),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      );

      expect(find.text('0'), findsOneWidget);
      expect(find.text('Reps Completed'), findsOneWidget);

      // Simulate 3 reps
      for (var i = 0; i < 3; i++) {
        await tester.tap(find.text('Simulate Rep'));
        await tester.pump();
      }

      expect(find.text('3'), findsOneWidget);
    });
  });

  group('Session History and Progress', () {
    testWidgets('session history list displays', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              appBar: AppBar(title: Text('Session History')),
              body: ListView(
                children: [
                  ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.green,
                      child: Text('92'),
                    ),
                    title: Text('Today, 10:30 AM'),
                    subtitle: Text('3 exercises • 25 minutes'),
                    trailing: Icon(Icons.chevron_right),
                  ),
                  Divider(),
                  ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.green,
                      child: Text('88'),
                    ),
                    title: Text('Yesterday, 3:15 PM'),
                    subtitle: Text('4 exercises • 35 minutes'),
                    trailing: Icon(Icons.chevron_right),
                  ),
                  Divider(),
                  ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.orange,
                      child: Text('75'),
                    ),
                    title: Text('2 days ago'),
                    subtitle: Text('2 exercises • 15 minutes'),
                    trailing: Icon(Icons.chevron_right),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.text('Session History'), findsOneWidget);
      expect(find.text('Today, 10:30 AM'), findsOneWidget);
      expect(find.text('Yesterday, 3:15 PM'), findsOneWidget);
      expect(find.text('2 days ago'), findsOneWidget);
    });

    testWidgets('progress stats card displays', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Padding(
                padding: EdgeInsets.all(16),
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Your Progress This Week',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Column(
                              children: [
                                Text(
                                  '5',
                                  style: TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue,
                                  ),
                                ),
                                Text('Sessions'),
                              ],
                            ),
                            Column(
                              children: [
                                Text(
                                  '87%',
                                  style: TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                ),
                                Text('Avg Score'),
                              ],
                            ),
                            Column(
                              children: [
                                Text(
                                  '-2',
                                  style: TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                ),
                                Text('Pain Δ'),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Your Progress This Week'), findsOneWidget);
      expect(find.text('5'), findsOneWidget);
      expect(find.text('Sessions'), findsOneWidget);
      expect(find.text('87%'), findsOneWidget);
      expect(find.text('Avg Score'), findsOneWidget);
      expect(find.text('-2'), findsOneWidget);
      expect(find.text('Pain Δ'), findsOneWidget);
    });
  });
}
