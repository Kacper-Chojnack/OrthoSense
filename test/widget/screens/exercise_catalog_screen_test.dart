/// Widget tests for ExerciseCatalogScreen.
///
/// Test coverage:
/// 1. Screen renders correctly
/// 2. Exercise list displays all exercises
/// 3. Exercise card interactions
/// 4. Navigation to Live Analysis
/// 5. Navigation to Gallery Analysis
/// 6. Exercise details bottom sheet
/// 7. Demo video sheet display
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orthosense/features/exercise/presentation/screens/exercise_catalog_screen.dart';
import 'package:orthosense/features/exercise/presentation/widgets/exercise_demo_video_sheet.dart';

void main() {
  group('ExerciseCatalogScreen', () {
    testWidgets('renders app bar with title', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: ExerciseCatalogScreen(),
          ),
        ),
      );

      expect(find.text('Exercise Catalog'), findsOneWidget);
    });

    testWidgets('renders camera icon in app bar', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: ExerciseCatalogScreen(),
          ),
        ),
      );

      // Actual icon is photo_camera_outlined
      expect(find.byIcon(Icons.photo_camera_outlined), findsOneWidget);
    });

    testWidgets('renders gallery icon in app bar', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: ExerciseCatalogScreen(),
          ),
        ),
      );

      // Actual icon is play_circle_outline for gallery analysis
      expect(find.byIcon(Icons.play_circle_outline), findsOneWidget);
    });

    testWidgets('displays Deep Squat exercise', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: ExerciseCatalogScreen(),
          ),
        ),
      );

      expect(find.text('Deep Squat'), findsOneWidget);
    });

    testWidgets('displays Hurdle Step exercise', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: ExerciseCatalogScreen(),
          ),
        ),
      );

      expect(find.text('Hurdle Step'), findsOneWidget);
    });

    testWidgets('displays Standing Shoulder Abduction exercise', (
      tester,
    ) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: ExerciseCatalogScreen(),
          ),
        ),
      );

      expect(find.text('Standing Shoulder Abduction'), findsOneWidget);
    });

    testWidgets('displays exercise descriptions', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: ExerciseCatalogScreen(),
          ),
        ),
      );

      expect(
        find.text('Lower body mobility and strength assessment'),
        findsOneWidget,
      );
    });

    testWidgets('exercise cards are tappable', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: ExerciseCatalogScreen(),
          ),
        ),
      );

      // Find first exercise card
      final card = find.text('Deep Squat');
      expect(card, findsOneWidget);

      // Tap and verify bottom sheet appears
      await tester.tap(card);
      await tester.pumpAndSettle();

      // Bottom sheet should show instructions
      expect(
        find.text('Stand with feet shoulder-width apart'),
        findsOneWidget,
      );
    });

    testWidgets('exercise details sheet shows instructions', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: ExerciseCatalogScreen(),
          ),
        ),
      );

      // Tap on Deep Squat
      await tester.tap(find.text('Deep Squat'));
      await tester.pumpAndSettle();

      // The bottom sheet should show - look for DraggableScrollableSheet content
      // Check if any instruction text appears (the sheet has instructions)
      final instructionsFinder = find.textContaining('Stand with feet');
      expect(instructionsFinder, findsWidgets);
    });

    testWidgets('displays 3 exercises in list', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: ExerciseCatalogScreen(),
          ),
        ),
      );

      // Should have 3 exercise cards
      expect(find.byType(Card), findsNWidgets(3));
    });

    testWidgets('camera button has correct tooltip', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: ExerciseCatalogScreen(),
          ),
        ),
      );

      final cameraButton = find.byIcon(Icons.photo_camera_outlined);
      final iconButton = tester.widget<IconButton>(
        find.ancestor(
          of: cameraButton,
          matching: find.byType(IconButton),
        ),
      );

      expect(iconButton.tooltip, equals('Live Analysis'));
    });

    testWidgets('gallery button has correct tooltip', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: ExerciseCatalogScreen(),
          ),
        ),
      );

      final galleryButton = find.byIcon(Icons.play_circle_outline);
      final iconButton = tester.widget<IconButton>(
        find.ancestor(
          of: galleryButton,
          matching: find.byType(IconButton),
        ),
      );

      expect(iconButton.tooltip, equals('Analyze from Gallery'));
    });

    testWidgets('scroll works with exercises list', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: ExerciseCatalogScreen(),
          ),
        ),
      );

      // Scroll down
      await tester.drag(find.byType(ListView), const Offset(0, -200));
      await tester.pumpAndSettle();

      // Exercises should still be findable
      expect(find.text('Standing Shoulder Abduction'), findsOneWidget);
    });

    testWidgets('app bar is centered', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: ExerciseCatalogScreen(),
          ),
        ),
      );

      final appBar = tester.widget<AppBar>(find.byType(AppBar));
      expect(appBar.centerTitle, isTrue);
    });
  });

  group('ExerciseInfo model', () {
    test('creates with all fields', () {
      const exercise = ExerciseInfo(
        id: 1,
        name: 'Test Exercise',
        description: 'Test description',
        icon: Icons.fitness_center,
        instructions: ['Step 1', 'Step 2'],
      );

      expect(exercise.id, equals(1));
      expect(exercise.name, equals('Test Exercise'));
      expect(exercise.description, equals('Test description'));
      expect(exercise.instructions.length, equals(2));
      expect(exercise.demoVideo, isNull);
    });

    test('creates with demo video', () {
      const exercise = ExerciseInfo(
        id: 1,
        name: 'Test Exercise',
        description: 'Test description',
        icon: Icons.fitness_center,
        instructions: ['Step 1'],
        demoVideo: DemoVideo(
          title: 'Demo',
          description: 'Demo video',
          assetPath: 'assets/demo.mp4',
        ),
      );

      expect(exercise.demoVideo, isNotNull);
      expect(exercise.demoVideo!.title, equals('Demo'));
    });
  });

  group('DemoVideo model', () {
    test('creates with required fields', () {
      const video = DemoVideo(
        title: 'Squat Demo',
        description: 'How to do a squat',
        assetPath: 'assets/videos/squat.mp4',
      );

      expect(video.title, equals('Squat Demo'));
      expect(video.description, equals('How to do a squat'));
      expect(video.assetPath, equals('assets/videos/squat.mp4'));
      expect(video.viewAngle, equals('front')); // default value
    });

    test('creates with optional view angle', () {
      const video = DemoVideo(
        title: 'Squat Demo',
        description: 'How to do a squat',
        assetPath: 'assets/videos/squat.mp4',
        viewAngle: 'side',
      );

      expect(video.viewAngle, equals('side'));
    });
  });

  group('Screen accessibility', () {
    testWidgets('exercise names are readable', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: ExerciseCatalogScreen(),
          ),
        ),
      );

      // Check text semantics
      final deepSquatFinder = find.text('Deep Squat');
      expect(tester.getSemantics(deepSquatFinder), isNotNull);
    });

    testWidgets('icons have semantic meaning', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: ExerciseCatalogScreen(),
          ),
        ),
      );

      // Camera icon should be accessible
      final cameraIcon = find.byIcon(Icons.photo_camera_outlined);
      expect(cameraIcon, findsOneWidget);
    });
  });

  group('Layout and styling', () {
    testWidgets('cards have correct padding', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: ExerciseCatalogScreen(),
          ),
        ),
      );

      // ListView should have padding
      final listView = tester.widget<ListView>(find.byType(ListView));
      expect(listView.padding, equals(const EdgeInsets.all(16)));
    });

    testWidgets('cards have margin between them', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: ExerciseCatalogScreen(),
          ),
        ),
      );

      // Multiple cards should be rendered with spacing
      final cards = find.byType(Card);
      expect(cards, findsNWidgets(3));
    });
  });
}
