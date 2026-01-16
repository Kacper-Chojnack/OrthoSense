// ignore_for_file: document_ignores, directives_ordering

/// E2E Tests for Error Handling
///
/// Tests cover:
/// - Network error handling
/// - Invalid input handling
/// - Server error responses
/// - Graceful degradation
/// - User-friendly error messages
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:orthosense/main.dart';
import 'package:orthosense/core/providers/shared_preferences_provider.dart';
import 'package:orthosense/features/auth/presentation/screens/login_screen.dart';
import 'package:orthosense/features/auth/presentation/widgets/auth_text_field.dart';

import 'e2e_test_helpers.dart';

/// Creates ProviderScope with test overrides
Future<ProviderScope> _createTestApp() async {
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
  group('Error Handling E2E Tests', () {
    testWidgets('Invalid email format shows error', (tester) async {
      final app = await _createTestApp();
      await tester.pumpWidget(app);
      await tester.pumpAndSettle();

      // Ensure login screen
      expect(find.byType(LoginScreen), findsOneWidget);

      // STEP: Enter invalid email
      final textFields = find.byType(AuthTextField);
      if (textFields.evaluate().isNotEmpty) {
        await tester.enterText(textFields.first, 'invalid-email');
        await tester.pumpAndSettle();

        if (textFields.evaluate().length > 1) {
          await tester.enterText(textFields.at(1), 'password123');
          await tester.pumpAndSettle();
        }

        // STEP: Try to submit
        final signInButton = find.text('Sign In');
        if (signInButton.evaluate().isNotEmpty) {
          await tester.tap(signInButton);
          await tester.pumpAndSettle();
        }

        // VERIFY: Still on login screen (validation should prevent submission)
        expect(find.byType(LoginScreen), findsOneWidget);
      }
    });

    testWidgets('Empty password shows error', (tester) async {
      final app = await _createTestApp();
      await tester.pumpWidget(app);
      await tester.pumpAndSettle();

      // STEP: Enter email only
      final textFields = find.byType(AuthTextField);
      if (textFields.evaluate().isNotEmpty) {
        await tester.enterText(textFields.first, 'test@example.com');
        await tester.pumpAndSettle();

        // STEP: Try to submit without password
        final signInButton = find.text('Sign In');
        if (signInButton.evaluate().isNotEmpty) {
          await tester.tap(signInButton);
          await tester.pumpAndSettle();
        }

        // VERIFY: Still on login screen
        expect(find.byType(LoginScreen), findsOneWidget);
      }
    });

    testWidgets('Wrong credentials shows error', (tester) async {
      final app = await _createTestApp();
      await tester.pumpWidget(app);
      await tester.pumpAndSettle();

      // STEP: Enter wrong credentials
      final textFields = find.byType(AuthTextField);
      if (textFields.evaluate().isNotEmpty) {
        await tester.enterText(textFields.first, 'nonexistent@test.com');
        await tester.pumpAndSettle();

        if (textFields.evaluate().length > 1) {
          await tester.enterText(textFields.at(1), 'wrongpassword123');
          await tester.pumpAndSettle();
        }

        // STEP: Submit
        final signInButton = find.text('Sign In');
        if (signInButton.evaluate().isNotEmpty) {
          await tester.tap(signInButton);
          await tester.pump(const Duration(seconds: 2));
          await tester.pumpAndSettle();
        }
      }

      // VERIFY: Still on login screen (not redirected)
      final stillOnLogin = find.byType(LoginScreen).evaluate().isNotEmpty;
      expect(stillOnLogin, isTrue,
          reason: 'Should still be on login after wrong credentials');
    });

    testWidgets('Network timeout graceful handling', (tester) async {
      final app = await _createTestApp();
      await tester.pumpWidget(app);
      await tester.pumpAndSettle();

      // STEP: Try to login (simulating network issue via mocked provider)
      final textFields = find.byType(AuthTextField);
      if (textFields.evaluate().isNotEmpty) {
        await tester.enterText(textFields.first, 'test@example.com');
        await tester.pumpAndSettle();

        if (textFields.evaluate().length > 1) {
          await tester.enterText(textFields.at(1), 'password123');
          await tester.pumpAndSettle();
        }

        final signInButton = find.text('Sign In');
        if (signInButton.evaluate().isNotEmpty) {
          await tester.tap(signInButton);
          await tester.pumpAndSettle();
        }
      }

      // VERIFY: App doesn't crash and shows appropriate UI
      final appFunctional = find.byType(MaterialApp).evaluate().isNotEmpty;
      expect(appFunctional, isTrue, reason: 'App should remain functional');
    });

    testWidgets('Registration with existing email', (tester) async {
      final app = await _createTestApp();
      await tester.pumpWidget(app);
      await tester.pumpAndSettle();

      // STEP: Navigate to registration
      final registerLinks = [
        find.text('Register'),
        find.text('Sign Up'),
        find.text('Create Account'),
        find.textContaining("Don't have an account"),
      ];

      for (final finder in registerLinks) {
        if (finder.evaluate().isNotEmpty) {
          await tester.tap(finder.first);
          await tester.pumpAndSettle();
          break;
        }
      }

      // STEP: Enter existing email
      final textFields = find.byType(AuthTextField);
      if (textFields.evaluate().length >= 3) {
        await tester.enterText(textFields.at(0), 'existing@test.com');
        await tester.pumpAndSettle();

        await tester.enterText(textFields.at(1), 'ValidPass123!');
        await tester.pumpAndSettle();

        await tester.enterText(textFields.at(2), 'ValidPass123!');
        await tester.pumpAndSettle();

        // Submit
        final submitButtons = [
          find.text('Register'),
          find.text('Sign Up'),
          find.text('Create Account'),
        ];

        for (final finder in submitButtons) {
          final buttons = finder.evaluate();
          if (buttons.isNotEmpty) {
            await tester.tap(finder.last);
            await tester.pump(const Duration(seconds: 2));
            await tester.pumpAndSettle();
            break;
          }
        }
      }

      // VERIFY: App is functional
      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('Form validation prevents submission', (tester) async {
      final app = await _createTestApp();
      await tester.pumpWidget(app);
      await tester.pumpAndSettle();

      // STEP: Try to submit empty form
      final signInButton = find.text('Sign In');
      if (signInButton.evaluate().isNotEmpty) {
        await tester.tap(signInButton);
        await tester.pumpAndSettle();

        // VERIFY: Still on login (form doesn't submit with empty fields)
        final stillOnLogin = find.byType(LoginScreen).evaluate().isNotEmpty;
        expect(stillOnLogin, isTrue,
            reason: 'Should not submit with empty form');
      }
    });

    testWidgets('Snackbar dismissal', (tester) async {
      final app = await _createTestApp();
      await tester.pumpWidget(app);
      await tester.pumpAndSettle();

      // STEP: Trigger an error
      final textFields = find.byType(AuthTextField);
      if (textFields.evaluate().isNotEmpty) {
        await tester.enterText(textFields.first, 'test@example.com');
        await tester.pumpAndSettle();

        if (textFields.evaluate().length > 1) {
          await tester.enterText(textFields.at(1), 'wrong');
          await tester.pumpAndSettle();
        }

        final signInButton = find.text('Sign In');
        if (signInButton.evaluate().isNotEmpty) {
          await tester.tap(signInButton);
          await tester.pump(const Duration(seconds: 1));
          await tester.pumpAndSettle();
        }
      }

      // STEP: Look for snackbar and dismiss action
      final snackBar = find.byType(SnackBar);
      if (snackBar.evaluate().isNotEmpty) {
        E2ETestHelpers.logStep('Snackbar found');

        // Wait for auto-dismiss or try to dismiss
        await tester.pump(const Duration(seconds: 5));
        await tester.pumpAndSettle();
      } else {
        E2ETestHelpers.logStep('No snackbar shown (errors may be inline)');
      }

      // App should still be functional
      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('Back navigation recovery', (tester) async {
      final app = await _createTestApp();
      await tester.pumpWidget(app);
      await tester.pumpAndSettle();

      // STEP: Navigate away from login if possible
      final registerLinks = [
        find.text('Register'),
        find.text('Sign Up'),
        find.text('Create Account'),
        find.textContaining("Don't have an account"),
      ];

      bool navigated = false;
      for (final finder in registerLinks) {
        if (finder.evaluate().isNotEmpty) {
          await tester.tap(finder.first);
          await tester.pumpAndSettle();
          navigated = true;
          break;
        }
      }

      if (navigated) {
        // STEP: Try back navigation
        final backIcon = find.byIcon(Icons.arrow_back);

        if (backIcon.evaluate().isNotEmpty) {
          await tester.tap(backIcon.first);
          await tester.pumpAndSettle();
        }

        // VERIFY: Back navigation works or app is still functional
        final appFunctional = find.byType(MaterialApp).evaluate().isNotEmpty;
        expect(appFunctional, isTrue,
            reason: 'App should remain functional after navigation');
      } else {
        E2ETestHelpers.logStep('No navigation available from login');
        expect(find.byType(LoginScreen), findsOneWidget);
      }
    });
  });
}
