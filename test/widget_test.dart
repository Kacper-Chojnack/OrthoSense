import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orthosense/core/providers/shared_preferences_provider.dart';
import 'package:orthosense/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Mock SharedPreferences
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    // Build our app and trigger a frame.
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: const OrthoSenseApp(),
      ),
    );

    // Wait for all timers and animations (including the 100ms delay in _initializeSync)
    await tester.pumpAndSettle(const Duration(milliseconds: 200));

    // Verify that the app builds (e.g. finds a Material App or just doesn't crash)
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
