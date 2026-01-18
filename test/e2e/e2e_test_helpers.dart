// ignore_for_file: avoid_print, document_ignores, directives_ordering

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Helper utilities for E2E tests
class E2ETestHelpers {
  E2ETestHelpers._();

  /// Test user credentials
  static const testEmail = 'e2e_test@example.com';
  static const testPassword = 'SecureTestPass123!';

  static late SharedPreferences testPrefs;

  /// Initialize test shared preferences (call in setUpAll)
  static Future<void> initializeTestPrefs() async {
    SharedPreferences.setMockInitialValues({
      'disclaimer_accepted': true,
      'privacy_policy_accepted': true,
      'biometric_consent_accepted': true,
      'voice_selected': true,
      'theme_mode': 'system',
    });
    testPrefs = await SharedPreferences.getInstance();
  }

  /// Pump app and wait for it to stabilize with timeout
  /// Use this instead of pumpAndSettle to avoid timeout issues with async init
  static Future<void> pumpApp(WidgetTester tester, {int iterations = 20}) async {
    for (var i = 0; i < iterations; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  /// Settle the app or return after timeout
  static Future<void> pumpAndSettleWithTimeout(
    WidgetTester tester, {
    Duration timeout = const Duration(seconds: 5),
  }) async {
    final endTime = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(endTime)) {
      await tester.pump(const Duration(milliseconds: 100));
      // Check if there are any pending frames
      if (!tester.hasRunningAnimations) {
        break;
      }
    }
  }

  /// Create a unique test email to avoid collisions
  static String createUniqueEmail() {
    return 'e2e_${DateTime.now().millisecondsSinceEpoch}@example.com';
  }

  /// Log test step for debugging
  static void logStep(String step) {
    print('[E2E TEST] $step');
  }

  /// Log test verification
  static void logVerification(String verification, bool passed) {
    final status = passed ? '✓' : '✗';
    print('[E2E TEST] $status VERIFY: $verification');
  }
}

/// Mock data generators for E2E tests
class E2EMockData {
  E2EMockData._();

  /// Generate fake pose landmarks for exercise tests
  static Map<String, dynamic> generateFakePoseLandmarks({int quality = 95}) {
    final landmarks = <Map<String, double>>[];

    for (var i = 0; i < 33; i++) {
      final noise = (100 - quality) / 100;
      landmarks.add({
        'x': 0.5 + (0.1 * (i % 3)) - noise * 0.05,
        'y': 0.3 + (0.02 * i) - noise * 0.05,
        'z': 0.0 + noise * 0.1,
        'visibility': quality / 100,
      });
    }

    return {'landmarks': landmarks};
  }

  /// Generate fake exercise session data
  static Map<String, dynamic> generateFakeSessionData() {
    return {
      'exercise_name': 'Squat',
      'target_reps': 10,
      'difficulty': 'medium',
      'scheduled_date': DateTime.now().toIso8601String(),
    };
  }

  /// Generate fake user registration data
  static Map<String, String> generateFakeUserData() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return {
      'email': 'e2e_$timestamp@example.com',
      'password': 'SecureTestPass123!',
      'first_name': 'E2E',
      'last_name': 'TestUser',
    };
  }
}

/// Test assertions specific to E2E testing
class E2EAssertions {
  E2EAssertions._();

  /// Assert that a screen transition occurred
  static void assertScreenTransition(
    Finder from,
    Finder to, {
    required String description,
  }) {
    expect(
      from,
      findsNothing,
      reason: 'Previous screen should not be visible: $description',
    );
    expect(
      to,
      findsOneWidget,
      reason: 'Target screen should be visible: $description',
    );
  }

  /// Assert that an error message is displayed
  static void assertErrorDisplayed(WidgetTester tester, {String? containing}) {
    if (containing != null) {
      expect(
        find.textContaining(containing),
        findsWidgets,
        reason: 'Error message containing "$containing" should be displayed',
      );
    } else {
      // Look for common error indicators
      final hasSnackBar = find.byType(SnackBar).evaluate().isNotEmpty;
      final hasErrorText =
          find.textContaining('error').evaluate().isNotEmpty ||
          find.textContaining('Error').evaluate().isNotEmpty ||
          find.textContaining('failed').evaluate().isNotEmpty ||
          find.textContaining('Failed').evaluate().isNotEmpty;

      expect(
        hasSnackBar || hasErrorText,
        isTrue,
        reason: 'Some error indication should be displayed',
      );
    }
  }

  /// Assert that loading state is shown
  static void assertLoadingState() {
    expect(
      find.byType(CircularProgressIndicator),
      findsWidgets,
      reason: 'Loading indicator should be visible',
    );
  }

  /// Assert that loading state has completed
  static void assertLoadingComplete() {
    expect(
      find.byType(CircularProgressIndicator),
      findsNothing,
      reason: 'Loading indicator should not be visible',
    );
  }
}
