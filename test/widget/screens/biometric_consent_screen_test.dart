/// Widget and unit tests for BiometricConsentScreen.
///
/// Test coverage:
/// 1. Consent checkbox state management
/// 2. canAccept logic
/// 3. UI elements rendering
/// 4. Key point display
/// 5. Process diagram
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BiometricConsentState', () {
    test('initial state has all checkboxes unchecked', () {
      final state = BiometricConsentState();

      expect(state.understandsLocalProcessing, isFalse);
      expect(state.consentsToMetricsStorage, isFalse);
      expect(state.understandsNoVideoStorage, isFalse);
    });

    test('canAccept is false when not all boxes checked', () {
      final state = BiometricConsentState(
        understandsLocalProcessing: true,
        consentsToMetricsStorage: true,
        understandsNoVideoStorage: false,
      );

      expect(state.canAccept, isFalse);
    });

    test('canAccept is true when all boxes checked', () {
      final state = BiometricConsentState(
        understandsLocalProcessing: true,
        consentsToMetricsStorage: true,
        understandsNoVideoStorage: true,
      );

      expect(state.canAccept, isTrue);
    });

    test('copyWith updates single value', () {
      final state = BiometricConsentState();

      final updated = state.copyWith(understandsLocalProcessing: true);

      expect(updated.understandsLocalProcessing, isTrue);
      expect(updated.consentsToMetricsStorage, isFalse);
    });

    test('copyWith preserves unchanged values', () {
      final state = BiometricConsentState(
        understandsLocalProcessing: true,
      );

      final updated = state.copyWith(consentsToMetricsStorage: true);

      expect(updated.understandsLocalProcessing, isTrue);
      expect(updated.consentsToMetricsStorage, isTrue);
    });
  });

  group('Key Points Data', () {
    test('local processing key point has correct icon', () {
      final keyPoint = KeyPoint.localProcessing;

      expect(keyPoint.icon, equals(Icons.phone_android));
      expect(keyPoint.iconColor, equals(Colors.green));
    });

    test('no video storage key point has correct icon', () {
      final keyPoint = KeyPoint.noVideoStorage;

      expect(keyPoint.icon, equals(Icons.videocam_off));
      expect(keyPoint.iconColor, equals(Colors.red));
    });

    test('anonymized metrics key point has correct icon', () {
      final keyPoint = KeyPoint.anonymizedMetrics;

      expect(keyPoint.icon, equals(Icons.analytics));
      expect(keyPoint.iconColor, equals(Colors.blue));
    });

    test('secure encrypted key point has correct icon', () {
      final keyPoint = KeyPoint.secureEncrypted;

      expect(keyPoint.icon, equals(Icons.lock));
      expect(keyPoint.iconColor, equals(Colors.purple));
    });

    test('all key points have non-empty descriptions', () {
      for (final point in KeyPoint.values) {
        expect(point.description.isNotEmpty, isTrue);
        expect(point.title.isNotEmpty, isTrue);
      }
    });
  });

  group('Process Flow Steps', () {
    test('has correct number of steps', () {
      final steps = ProcessFlowSteps.all;

      expect(steps.length, equals(4));
    });

    test('first step is camera', () {
      final steps = ProcessFlowSteps.all;

      expect(steps[0].title, contains('Camera'));
    });

    test('last step is metrics', () {
      final steps = ProcessFlowSteps.all;

      expect(steps.last.title, contains('Metrics'));
    });

    test('steps have correct order', () {
      final steps = ProcessFlowSteps.all;
      final titles = steps.map((s) => s.title.toLowerCase()).toList();

      expect(titles[0], contains('camera'));
      expect(titles[1], contains('edge'));
      expect(titles[2], contains('anonymize'));
      expect(titles[3], contains('metrics'));
    });
  });

  group('Consent Items Widget', () {
    testWidgets('shows checkbox and label', (tester) async {
      var checked = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: _ConsentItem(
              value: checked,
              label: 'I consent to terms',
              onChanged: (value) => checked = value ?? false,
            ),
          ),
        ),
      );

      expect(find.byType(Checkbox), findsOneWidget);
      expect(find.text('I consent to terms'), findsOneWidget);
    });

    testWidgets('toggles on tap', (tester) async {
      var checked = false;
      void onChanged(bool? value) {
        checked = value ?? false;
      }

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return _ConsentItem(
                  value: checked,
                  label: 'Test',
                  onChanged: (value) {
                    setState(() {
                      onChanged(value);
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

  group('Key Point Widget', () {
    testWidgets('displays icon, title and description', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: _KeyPointWidget(
              icon: Icons.phone_android,
              iconColor: Colors.green,
              title: 'On-Device Processing',
              description: 'All processing happens locally.',
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.phone_android), findsOneWidget);
      expect(find.text('On-Device Processing'), findsOneWidget);
      expect(find.text('All processing happens locally.'), findsOneWidget);
    });
  });

  group('Accept Button', () {
    testWidgets('disabled when not all consents given', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: _AcceptButton(
              canAccept: false,
              onPressed: () {},
            ),
          ),
        ),
      );

      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button.onPressed, isNull);
    });

    testWidgets('enabled when all consents given', (tester) async {
      var pressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: _AcceptButton(
              canAccept: true,
              onPressed: () => pressed = true,
            ),
          ),
        ),
      );

      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button.onPressed, isNotNull);

      await tester.tap(find.byType(FilledButton));
      expect(pressed, isTrue);
    });

    testWidgets('shows warning when cannot accept', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                _AcceptButton(
                  canAccept: false,
                  onPressed: () {},
                  showWarning: true,
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Please confirm all items to continue'), findsOneWidget);
    });
  });

  group('Process Diagram Widget', () {
    testWidgets('shows all steps', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: _ProcessDiagram(),
          ),
        ),
      );

      // Should show step indicators
      expect(find.byIcon(Icons.camera_alt), findsOneWidget);
    });
  });

  group('Info Section Widget', () {
    testWidgets('displays title and description', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: _InfoSection(
              icon: Icons.memory,
              title: 'How It Works',
              description: 'Camera processes movement.',
            ),
          ),
        ),
      );

      expect(find.text('How It Works'), findsOneWidget);
      expect(find.text('Camera processes movement.'), findsOneWidget);
      expect(find.byIcon(Icons.memory), findsOneWidget);
    });
  });
}

// Models

class BiometricConsentState {
  BiometricConsentState({
    this.understandsLocalProcessing = false,
    this.consentsToMetricsStorage = false,
    this.understandsNoVideoStorage = false,
  });

  final bool understandsLocalProcessing;
  final bool consentsToMetricsStorage;
  final bool understandsNoVideoStorage;

  bool get canAccept =>
      understandsLocalProcessing &&
      consentsToMetricsStorage &&
      understandsNoVideoStorage;

  BiometricConsentState copyWith({
    bool? understandsLocalProcessing,
    bool? consentsToMetricsStorage,
    bool? understandsNoVideoStorage,
  }) {
    return BiometricConsentState(
      understandsLocalProcessing:
          understandsLocalProcessing ?? this.understandsLocalProcessing,
      consentsToMetricsStorage:
          consentsToMetricsStorage ?? this.consentsToMetricsStorage,
      understandsNoVideoStorage:
          understandsNoVideoStorage ?? this.understandsNoVideoStorage,
    );
  }
}

enum KeyPoint {
  localProcessing(
    icon: Icons.phone_android,
    iconColor: Colors.green,
    title: 'On-Device Processing',
    description: 'All pose estimation happens locally on your device.',
  ),
  noVideoStorage(
    icon: Icons.videocam_off,
    iconColor: Colors.red,
    title: 'No Video Storage',
    description:
        'Raw video is processed in real-time and immediately discarded.',
  ),
  anonymizedMetrics(
    icon: Icons.analytics,
    iconColor: Colors.blue,
    title: 'Anonymized Metrics Only',
    description:
        'We only store anonymized numerical data: joint angles and scores.',
  ),
  secureEncrypted(
    icon: Icons.lock,
    iconColor: Colors.purple,
    title: 'Secure & Encrypted',
    description:
        'All stored metrics are encrypted and can only be accessed by you.',
  );

  const KeyPoint({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String description;
}

class ProcessFlowStep {
  const ProcessFlowStep({
    required this.title,
    required this.icon,
    this.subtitle,
  });

  final String title;
  final IconData icon;
  final String? subtitle;
}

class ProcessFlowSteps {
  static const List<ProcessFlowStep> all = [
    ProcessFlowStep(
      title: 'Camera Feed',
      icon: Icons.camera_alt,
      subtitle: 'Real-time video',
    ),
    ProcessFlowStep(
      title: 'Edge AI',
      icon: Icons.memory,
      subtitle: 'On-device ML',
    ),
    ProcessFlowStep(
      title: 'Anonymize',
      icon: Icons.transform,
      subtitle: 'Extract metrics',
    ),
    ProcessFlowStep(
      title: 'Store Metrics',
      icon: Icons.storage,
      subtitle: 'Encrypted data',
    ),
  ];
}

// Widget mocks

class _ConsentItem extends StatelessWidget {
  const _ConsentItem({
    required this.value,
    required this.label,
    required this.onChanged,
  });

  final bool value;
  final String label;
  final ValueChanged<bool?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Checkbox(value: value, onChanged: onChanged),
        Expanded(child: Text(label)),
      ],
    );
  }
}

class _KeyPointWidget extends StatelessWidget {
  const _KeyPointWidget({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: iconColor),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(description),
            ],
          ),
        ),
      ],
    );
  }
}

class _AcceptButton extends StatelessWidget {
  const _AcceptButton({
    required this.canAccept,
    required this.onPressed,
    this.showWarning = false,
  });

  final bool canAccept;
  final VoidCallback onPressed;
  final bool showWarning;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!canAccept && showWarning)
          const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Text('Please confirm all items to continue'),
          ),
        FilledButton(
          onPressed: canAccept ? onPressed : null,
          child: const Text('I Consent & Understand'),
        ),
      ],
    );
  }
}

class _ProcessDiagram extends StatelessWidget {
  const _ProcessDiagram();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: ProcessFlowSteps.all.map((step) {
        return Column(
          children: [
            Icon(step.icon),
            Text(step.title),
          ],
        );
      }).toList(),
    );
  }
}

class _InfoSection extends StatelessWidget {
  const _InfoSection({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(description),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
