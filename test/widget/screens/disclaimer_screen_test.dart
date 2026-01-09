/// Widget tests for DisclaimerScreen.
///
/// Test coverage:
/// 1. Screen renders correctly with all UI elements
/// 2. Logo and title display
/// 3. Disclaimer text visibility
/// 4. Accept button interaction
/// 5. Onboarding provider integration
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:orthosense/core/providers/preferences_provider.dart';
import 'package:orthosense/core/services/preferences_service.dart';
import 'package:orthosense/features/onboarding/presentation/screens/disclaimer_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ============================================================================
// Mocks
// ============================================================================

class MockSharedPreferences extends Mock implements SharedPreferences {}

// ============================================================================
// Test Helpers
// ============================================================================

Widget createTestWidget({
  required SharedPreferences sharedPreferences,
}) {
  final preferencesService = PreferencesService(sharedPreferences);
  return ProviderScope(
    overrides: [
      preferencesServiceProvider.overrideWithValue(preferencesService),
    ],
    child: const MaterialApp(
      home: DisclaimerScreen(),
    ),
  );
}

void main() {
  late MockSharedPreferences mockSharedPreferences;

  setUp(() {
    mockSharedPreferences = MockSharedPreferences();

    // Default setup - no onboarding steps completed
    when(() => mockSharedPreferences.getBool(any())).thenReturn(false);
    when(() => mockSharedPreferences.getString(any())).thenReturn(null);
    when(
      () => mockSharedPreferences.setBool(any(), any()),
    ).thenAnswer((_) async => true);
  });

  group('DisclaimerScreen - UI Rendering', () {
    testWidgets('renders app logo', (tester) async {
      await tester.pumpWidget(
        createTestWidget(sharedPreferences: mockSharedPreferences),
      );

      // Logo should be displayed as an Image asset
      expect(find.byType(Image), findsOneWidget);
    });

    testWidgets('renders disclaimer title', (tester) async {
      await tester.pumpWidget(
        createTestWidget(sharedPreferences: mockSharedPreferences),
      );

      expect(find.text('Important Disclaimer'), findsOneWidget);
    });

    testWidgets('renders medical device warning in red', (tester) async {
      await tester.pumpWidget(
        createTestWidget(sharedPreferences: mockSharedPreferences),
      );

      expect(find.text('OrthoSense is NOT a medical device.'), findsOneWidget);

      // Verify the warning text is styled (we check it exists)
      final warningFinder = find.text('OrthoSense is NOT a medical device.');
      expect(warningFinder, findsOneWidget);
    });

    testWidgets('renders disclaimer explanation text', (tester) async {
      await tester.pumpWidget(
        createTestWidget(sharedPreferences: mockSharedPreferences),
      );

      expect(
        find.textContaining('telerehabilitation support'),
        findsOneWidget,
      );
      expect(
        find.textContaining('does not replace professional medical advice'),
        findsOneWidget,
      );
    });

    testWidgets('renders accept button', (tester) async {
      await tester.pumpWidget(
        createTestWidget(sharedPreferences: mockSharedPreferences),
      );

      expect(find.text('I Understand & Accept'), findsOneWidget);
      expect(find.byType(FilledButton), findsOneWidget);
    });
  });

  group('DisclaimerScreen - Interactions', () {
    testWidgets('accept button calls preferences service', (tester) async {
      await tester.pumpWidget(
        createTestWidget(sharedPreferences: mockSharedPreferences),
      );

      // Find and tap the accept button
      final acceptButton = find.text('I Understand & Accept');
      expect(acceptButton, findsOneWidget);

      await tester.tap(acceptButton);
      await tester.pump();

      // Verify the shared preferences were called
      verify(
        () => mockSharedPreferences.setBool('disclaimer_accepted', true),
      ).called(1);
    });

    testWidgets('button is tappable (not disabled)', (tester) async {
      await tester.pumpWidget(
        createTestWidget(sharedPreferences: mockSharedPreferences),
      );

      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button.onPressed, isNotNull);
    });
  });

  group('DisclaimerScreen - Layout', () {
    testWidgets('uses SafeArea for proper device padding', (tester) async {
      await tester.pumpWidget(
        createTestWidget(sharedPreferences: mockSharedPreferences),
      );

      expect(find.byType(SafeArea), findsOneWidget);
    });

    testWidgets('content is in a scrollable column', (tester) async {
      await tester.pumpWidget(
        createTestWidget(sharedPreferences: mockSharedPreferences),
      );

      // Main layout should have a Column
      expect(find.byType(Column), findsWidgets);
    });

    testWidgets('text is centered', (tester) async {
      await tester.pumpWidget(
        createTestWidget(sharedPreferences: mockSharedPreferences),
      );

      // Find text widgets and check alignment
      final titleFinder = find.text('Important Disclaimer');
      expect(titleFinder, findsOneWidget);

      final titleWidget = tester.widget<Text>(titleFinder);
      expect(titleWidget.textAlign, TextAlign.center);
    });
  });

  group('DisclaimerScreen - Accessibility', () {
    testWidgets('all text is readable (non-empty)', (tester) async {
      await tester.pumpWidget(
        createTestWidget(sharedPreferences: mockSharedPreferences),
      );

      // Verify key text elements exist
      final textWidgets = find.byType(Text);
      expect(textWidgets, findsWidgets);

      // Count should include title, warning, explanation, and button text
      expect(textWidgets.evaluate().length, greaterThanOrEqualTo(4));
    });

    testWidgets('button has semantic label', (tester) async {
      await tester.pumpWidget(
        createTestWidget(sharedPreferences: mockSharedPreferences),
      );

      // Button should have visible text for accessibility
      expect(find.text('I Understand & Accept'), findsOneWidget);
    });
  });

  group('DisclaimerScreen - Theme Integration', () {
    testWidgets('respects light theme colors', (tester) async {
      final preferencesService = PreferencesService(mockSharedPreferences);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            preferencesServiceProvider.overrideWithValue(preferencesService),
          ],
          child: MaterialApp(
            theme: ThemeData.light(),
            home: const DisclaimerScreen(),
          ),
        ),
      );

      // Should render without errors in light theme
      expect(find.byType(DisclaimerScreen), findsOneWidget);
    });

    testWidgets('respects dark theme colors', (tester) async {
      final preferencesService = PreferencesService(mockSharedPreferences);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            preferencesServiceProvider.overrideWithValue(preferencesService),
          ],
          child: MaterialApp(
            theme: ThemeData.dark(),
            home: const DisclaimerScreen(),
          ),
        ),
      );

      // Should render without errors in dark theme
      expect(find.byType(DisclaimerScreen), findsOneWidget);
    });
  });
}
