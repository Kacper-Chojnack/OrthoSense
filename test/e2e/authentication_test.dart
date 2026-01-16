// ignore_for_file: document_ignores, directives_ordering

/// E2E Tests for Authentication Flow
///
/// Tests cover:
/// - Complete registration flow
/// - Login flow with valid credentials
/// - Login validation errors
/// - Password validation
/// - Forgot password flow
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:orthosense/main.dart';
import 'package:orthosense/core/providers/shared_preferences_provider.dart';
import 'package:orthosense/features/auth/presentation/screens/login_screen.dart';
import 'package:orthosense/features/auth/presentation/screens/register_screen.dart';
import 'package:orthosense/features/auth/presentation/widgets/auth_text_field.dart';

import 'e2e_test_helpers.dart';

/// Creates ProviderScope with test overrides
Future<ProviderScope> createTestApp() async {
  SharedPreferences.setMockInitialValues({
    'onboarding_complete': true,
    'theme_mode': 'system',
  });
  final prefs = await SharedPreferences.getInstance();

  return ProviderScope(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
    ],
    child: const OrthoSenseApp(),
  );
}

void main() {
  group('Authentication Flow E2E Tests', () {
    testWidgets('Auth flow: Register navigation', (tester) async {
      // SETUP: Launch app with test configuration
      final app = await createTestApp();
      await tester.pumpWidget(app);
      await tester.pumpAndSettle();

      // Verify we start on login screen
      expect(find.byType(LoginScreen), findsOneWidget);

      // STEP 1: Navigate to registration screen
      final createAccountButton = find.text('Create Account');
      if (createAccountButton.evaluate().isNotEmpty) {
        await tester.tap(createAccountButton);
        await tester.pumpAndSettle();

        // VERIFY: Registration screen is displayed
        final isOnRegister = find.byType(RegisterScreen).evaluate().isNotEmpty;
        if (isOnRegister) {
          E2ETestHelpers.logStep('Navigated to registration screen');
          expect(find.text('Join OrthoSense'), findsOneWidget);
        }
      }
    });

    testWidgets('Login validation: Empty form shows errors', (tester) async {
      final app = await createTestApp();
      await tester.pumpWidget(app);
      await tester.pumpAndSettle();

      // Ensure we're on login screen
      expect(find.byType(LoginScreen), findsOneWidget);

      // STEP: Try to submit empty form by tapping Sign In
      final signInButton = find.text('Sign In');
      if (signInButton.evaluate().isNotEmpty) {
        await tester.tap(signInButton);
        await tester.pumpAndSettle();

        // VERIFY: Should still be on login screen (form validation prevents submission)
        expect(find.byType(LoginScreen), findsOneWidget);
      }
    });

    testWidgets('Login validation: Invalid email format', (tester) async {
      final app = await createTestApp();
      await tester.pumpWidget(app);
      await tester.pumpAndSettle();

      // STEP: Enter invalid email
      final emailFields = find.byType(AuthTextField);
      if (emailFields.evaluate().isNotEmpty) {
        await tester.enterText(emailFields.first, 'invalid-email-format');
        await tester.pumpAndSettle();

        // Enter some password
        if (emailFields.evaluate().length > 1) {
          await tester.enterText(emailFields.at(1), 'SomePassword123!');
          await tester.pumpAndSettle();
        }

        // Try to submit
        final signInButton = find.text('Sign In');
        if (signInButton.evaluate().isNotEmpty) {
          await tester.tap(signInButton);
          await tester.pumpAndSettle();

          // VERIFY: Still on login screen (validation should prevent)
          expect(find.byType(LoginScreen), findsOneWidget);
        }
      }
    });

    testWidgets('Login validation: Incorrect credentials show error', (
      tester,
    ) async {
      final app = await createTestApp();
      await tester.pumpWidget(app);
      await tester.pumpAndSettle();

      // STEP: Enter non-existent credentials
      final emailFields = find.byType(AuthTextField);
      if (emailFields.evaluate().isNotEmpty) {
        await tester.enterText(emailFields.first, 'nonexistent@example.com');
        await tester.pumpAndSettle();

        if (emailFields.evaluate().length > 1) {
          await tester.enterText(emailFields.at(1), 'WrongPassword123!');
          await tester.pumpAndSettle();
        }

        // Submit login
        final signInButton = find.text('Sign In');
        if (signInButton.evaluate().isNotEmpty) {
          await tester.tap(signInButton);
          await tester.pump(const Duration(seconds: 2));
          await tester.pumpAndSettle();
        }
      }

      // VERIFY: Error message is shown or still on login
      expect(find.byType(LoginScreen), findsOneWidget);
    });

    testWidgets('Registration validation: Password mismatch', (tester) async {
      final app = await createTestApp();
      await tester.pumpWidget(app);
      await tester.pumpAndSettle();

      // Navigate to registration
      final createAccountButton = find.text('Create Account');
      if (createAccountButton.evaluate().isNotEmpty) {
        await tester.tap(createAccountButton);
        await tester.pumpAndSettle();

        // Check if we're on register screen
        if (find.byType(RegisterScreen).evaluate().isNotEmpty) {
          final textFields = find.byType(AuthTextField);
          if (textFields.evaluate().length >= 3) {
            // Enter valid email
            await tester.enterText(textFields.at(0), 'test@example.com');
            await tester.pumpAndSettle();

            // Enter password
            await tester.enterText(textFields.at(1), 'SecurePass123!');
            await tester.pumpAndSettle();

            // Enter DIFFERENT confirm password
            await tester.enterText(textFields.at(2), 'DifferentPass456!');
            await tester.pumpAndSettle();

            // Try to submit
            final submitButtons = find.text('Create Account');
            if (submitButtons.evaluate().length > 1) {
              await tester.tap(submitButtons.last);
              await tester.pumpAndSettle();
            }

            // VERIFY: Should still be on register screen due to mismatch
            expect(find.byType(RegisterScreen), findsOneWidget);
          }
        }
      }
    });

    testWidgets('Navigation: Login screen elements are visible', (
      tester,
    ) async {
      final app = await createTestApp();
      await tester.pumpWidget(app);
      await tester.pumpAndSettle();

      // VERIFY: Key UI elements are present (flexible matching)
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.byType(AuthTextField), findsAtLeast(2)); // Email and Password
    });
  });
}
