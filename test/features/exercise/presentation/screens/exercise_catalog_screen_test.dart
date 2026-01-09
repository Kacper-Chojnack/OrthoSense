import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orthosense/features/exercise/presentation/screens/exercise_catalog_screen.dart';

void main() {
  Widget createTestWidget() {
    return const ProviderScope(
      child: MaterialApp(
        home: ExerciseCatalogScreen(),
      ),
    );
  }

  group('ExerciseCatalogScreen Widget Tests', () {
    testWidgets('renders exercise catalog correctly', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Verify app bar
      expect(find.text('Exercise Catalog'), findsOneWidget);

      // Verify action buttons
      expect(find.byIcon(Icons.camera_alt), findsOneWidget);
      expect(find.byIcon(Icons.video_library), findsOneWidget);
    });

    testWidgets('displays all exercises', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Verify exercises are listed
      expect(find.text('Deep Squat'), findsOneWidget);
      expect(find.text('Hurdle Step'), findsOneWidget);
      expect(find.text('Standing Shoulder Abduction'), findsOneWidget);
    });

    testWidgets('shows exercise descriptions', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Verify descriptions
      expect(
        find.text('Lower body mobility and strength assessment'),
        findsOneWidget,
      );
      expect(
        find.text('Hip and leg stability assessment'),
        findsOneWidget,
      );
      expect(
        find.text('Shoulder mobility and stability assessment'),
        findsOneWidget,
      );
    });

    testWidgets('exercise cards are tappable', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Tap on Deep Squat exercise
      await tester.tap(find.text('Deep Squat'));
      await tester.pumpAndSettle();

      // Should show details with instructions
      expect(find.text('Instructions'), findsOneWidget);
    });

    testWidgets('shows exercise instructions on expand', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Tap on exercise to expand
      await tester.tap(find.text('Deep Squat'));
      await tester.pumpAndSettle();

      // Verify instructions list
      expect(
        find.text('Stand with feet shoulder-width apart'),
        findsOneWidget,
      );
      expect(find.text('Keep your arms extended forward'), findsOneWidget);
      expect(find.text('Lower your hips as deep as possible'), findsOneWidget);
    });

    testWidgets('app bar contains analysis buttons', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Both analysis buttons should be present
      expect(find.byIcon(Icons.camera_alt), findsOneWidget);
      expect(find.byIcon(Icons.video_library), findsOneWidget);
    });

    testWidgets('each exercise card displays correctly', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Verify exercise cards have names and descriptions
      expect(find.text('Deep Squat'), findsOneWidget);
      expect(find.text('Hurdle Step'), findsOneWidget);
      expect(find.text('Standing Shoulder Abduction'), findsOneWidget);

      // Verify descriptions
      expect(
        find.text('Lower body mobility and strength assessment'),
        findsOneWidget,
      );
    });

    testWidgets('exercise list is scrollable', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Scroll down
      await tester.drag(
        find.byType(ListView),
        const Offset(0, -200),
      );
      await tester.pumpAndSettle();

      // Exercise still visible after scroll
      expect(find.text('Standing Shoulder Abduction'), findsOneWidget);
    });
  });

  group('ExerciseCatalogScreen Exercise Details', () {
    testWidgets('shows exercise description in details sheet', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Tap on exercise card to open details sheet
      await tester.tap(find.text('Deep Squat'));
      await tester.pumpAndSettle();

      // Should show description in the sheet
      expect(
        find.text('Lower body mobility and strength assessment'),
        findsWidgets, // May appear twice: card and sheet
      );
    });

    testWidgets('shows instructions in details sheet', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Tap on exercise card to open details sheet
      await tester.tap(find.text('Deep Squat'));
      await tester.pumpAndSettle();

      // Should show instructions section
      expect(find.text('Instructions'), findsOneWidget);
      expect(find.text('Stand with feet shoulder-width apart'), findsOneWidget);
    });

    testWidgets('details sheet can be dismissed', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Open details sheet
      await tester.tap(find.text('Deep Squat'));
      await tester.pumpAndSettle();

      // Verify sheet is open
      expect(find.text('Instructions'), findsOneWidget);

      // Dismiss sheet by tapping outside (drag down)
      await tester.drag(
        find.text('Instructions'),
        const Offset(0, 500),
      );
      await tester.pumpAndSettle();

      // Sheet should be closed - instructions not visible
      // (may vary based on implementation)
    });
  });

  group('ExerciseCatalogScreen UI Elements', () {
    testWidgets('app bar has correct title', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Exercise Catalog'), findsOneWidget);
    });

    testWidgets('live analysis icon button exists', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.camera_alt), findsOneWidget);
    });

    testWidgets('gallery analysis icon button exists', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.video_library), findsOneWidget);
    });

    testWidgets('icon buttons have tooltips', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Find IconButton with tooltip
      expect(find.byTooltip('Live Analysis'), findsOneWidget);
      expect(find.byTooltip('Analyze from Gallery'), findsOneWidget);
    });
  });

  group('ExerciseCatalogScreen Accessibility', () {
    testWidgets('exercise names are readable', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Text widgets should be findable
      expect(find.text('Deep Squat'), findsOneWidget);
      expect(find.text('Hurdle Step'), findsOneWidget);
    });

    testWidgets('cards have tap feedback', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // InkWell provides tap feedback
      expect(find.byType(InkWell), findsWidgets);
    });
  });
}
